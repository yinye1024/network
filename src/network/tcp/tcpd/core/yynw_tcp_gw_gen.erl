%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_gw_gen).
-author("yinye").

-behavior(gen_server).
-include_lib("yyutils/include/yyu_comm.hrl").
-include("yyu_tcp.hrl").

-define(SERVER,?MODULE).

-record(state,{
  gw_agent,                                     %% 关键的业务代理，包头长度，包体长度，授权校验等
  sock,                                         %% 对应的socket
  timeout_count =0,                             %% sock消息处理timeout次数，超过5次关闭socket
  async_recv_state :: ?WAIT_HEAD | ?WAIT_BODY    %% wait_head | wait_body 异步接收数据的状态
}).

%% API functions defined
-export([start_link/0,get_mod/0]).
-export([active/2,do_stop/1, do_send/2,cast_fun/2,call_fun/2]).
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->
  ?MODULE.

start_link()->
  Args = ?NOT_SET,
  %% 不指定 进程 id,用系统自动生成的进程id
  gen_server:start_link(?MODULE,Args,[]).

active(Pid,{ClientSock,GwAgent})->
  priv_cast(Pid,{active,{ClientSock,GwAgent}}).

do_stop(Pid)->
  priv_call(Pid,{stop}).

do_send(Pid,BsData)->
  priv_cast(Pid,{send,BsData}).

call_fun(Pid,{Fun,Param})->
  Req = ?DO_FUN(Fun,Param),
  priv_call(Pid,Req).

cast_fun(Pid,{Fun,Param})->
  Req = ?DO_FUN(Fun,Param),
  priv_cast(Pid,Req).

priv_call(Pid,Req)->
  gen_server:call(Pid,Req,?GEN_CALL_TIMEOUT).
priv_cast(Pid,Req)->
  gen_server:cast(Pid,Req).

%% ===================================================================================
%% Behavioural functions implements
%% ===================================================================================
init(_Args)->
  erlang:process_flag(trap_exit,true),
  {?OK,#state{}}.

terminate(Reason,_State=#state{sock = Sock,gw_agent = GwAgent})->
  ?LOG_INFO({"gen terminate",[reason,Reason]}),
  yynw_tcp_gw_agent:on_terminate(GwAgent),
  yynw_tcp_helper:close_socket(Sock),
  ?OK.

code_change(_OldVsn,State,_Extra)->
  {?OK,State}.

handle_call(Req,_From,State)->
  Reply = {"unknown gen call",[req,Req]},
  {?REPLY,Reply,State}.


handle_cast({active,{ClientSock,GwAgent}},State)->
  %% 进程激活的时候确保State 绑定了ClientSock，进程退出的时候会确保Sock关闭，避免泄露
  StateWithSock = State#state{sock = ClientSock},
  try
      ActivePackByteSize = yynw_tcp_gw_agent:get_active_pack_size(GwAgent),

      %% 阻塞30秒 获取激活包
      {?OK,PackData} = gen_tcp:recv(ClientSock, ActivePackByteSize,30000),
      {?OK,NewGwAgent} = yynw_tcp_gw_agent:handle_active_pack(PackData,GwAgent),
      HeadLength = yynw_tcp_gw_agent:get_head_byte_length(NewGwAgent),
      {?OK,?WAIT_HEAD} = yynw_tcp_helper:async_recv_head(ClientSock,HeadLength),
      {?NO_REPLY,StateWithSock#state{async_recv_state = ?WAIT_HEAD,gw_agent = NewGwAgent}}
  catch
      Error:Reason  ->
        ?LOG_ERROR({"error when active socket",Error,Reason}),
        {?STOP,?NORMAL,State}
  end;
handle_cast({send,BsData},State=#state{sock = ClientSocket,gw_agent = GwAgent})->
  try
    DataPack = yynw_tcp_gw_agent:pack_send_data(BsData,GwAgent),
    erlang:port_command(ClientSocket, DataPack,[force]),
    {?NO_REPLY,State}
  catch
    Error:Reason  ->
      ?LOG_ERROR({"error when send data",Error,Reason}),
      {?STOP,?NORMAL,State}
  end;
handle_cast(Req,State)->
  ?LOG_WARNING({"unknown gen cast",[req,Req]}),
  {?NO_REPLY,State}.



%% 获取包头
handle_info({?INET_ASYNC,ClientSocket,_Ref,{?OK,  HeadPack}},State = #state{async_recv_state = ?WAIT_HEAD })->
  GwAgent = State#state.gw_agent,
  BodyLength = yynw_tcp_gw_agent:get_body_byte_length(HeadPack,GwAgent),
  {?OK,?WAIT_BODY} = yynw_tcp_helper:async_recv_body(ClientSocket, BodyLength),
  {?NO_REPLY,State#state{async_recv_state = ?WAIT_BODY}};
%% 获取包体，处理业务
handle_info({?INET_ASYNC,ClientSocket,_Ref,{?OK,  BodyData}},State = #state{async_recv_state = ?WAIT_BODY})->
  GwAgent = State#state.gw_agent,
  yynw_tcp_gw_agent:route_c2s(BodyData,GwAgent),
  HeadLength = yynw_tcp_gw_agent:get_head_byte_length(GwAgent),
  {?OK,?WAIT_HEAD} =  yynw_tcp_helper:async_recv_head(ClientSocket,HeadLength),
  {?NO_REPLY,State#state{async_recv_state = ?WAIT_HEAD}};
%% 处理超时情况
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,timeout}},State = #state{gw_agent = GwAgent,timeout_count = TimeOutCount})->
  case yynw_tcp_gw_agent:handle_time_out(GwAgent)  of
    ?FAIL ->
      {?STOP,?NORMAL,State};
    {?OK,NewGwAgent} ->
      {?NO_REPLY,State#state{gw_agent = NewGwAgent}}
  end;
%% 处理链接关闭情况
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,closed}},State=#state{gw_agent = GwAgent})->
  ?LOG_WARNING({"socket closed, {GwAgent}",{GwAgent}}),
  {?STOP,?NORMAL,State};
%% 处理别的异常
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,Reason}},State=#state{gw_agent = GwAgent})->
  ?LOG_WARNING({"socket error, {GwAgent,Reason}",{GwAgent,Reason}}),
  {?STOP,?NORMAL,State};
handle_info({inet_reply,_sock,_},State)->
  {?NO_REPLY,State};
handle_info(Req,State)->
  ?LOG_WARNING({"unknown gen info",[req,Req]}),
  {?NO_REPLY,State}.




