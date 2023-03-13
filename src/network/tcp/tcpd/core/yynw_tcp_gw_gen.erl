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
-include_lib("yyutils/include/yyu_gs.hrl").
-include("yyu_tcp.hrl").

-define(SERVER,?MODULE).

-record(state,{
  sock,                                         %% 对应的socket
  async_recv_state :: ?WAIT_HEAD | ?WAIT_BODY    %% wait_head | wait_body 异步接收数据的状态
}).

%% API functions defined
-export([start_link/0,get_mod/0]).
-export([active/2, call_stop/1, cast_stop/1,do_send/2,cast_fun/2,call_fun/2]).
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

call_stop(Pid)->
  priv_call(Pid,{stop}).
cast_stop(Pid)->
  priv_cast(Pid,{stop}).

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
  bs_yynw_tcp_gw_mgr:init(),
  {?OK,#state{}}.

terminate(Reason,_State)->
  ?LOG_INFO({"gen terminate",[reason,Reason]}),
  ?TRY_CATCH(bs_yynw_tcp_gw_mgr:terminate()),
  ?OK.

code_change(_OldVsn,State,_Extra)->
  {?OK,State}.

handle_call({stop},_From,State)->
  ?LOG_INFO({"yynw tcp gw gen stop...."}),
  {?STOP,?NORMAL,?OK,State};
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

      bs_yynw_tcp_gw_mgr:do_active({ClientSock,GwAgent},PackData),
      HeadLength = yynw_tcp_gw_agent:get_head_byte_length(GwAgent),
      {?OK,?WAIT_HEAD} = yynw_tcp_helper:async_recv_head(ClientSock,HeadLength),
      HbTimeSpan = yynw_tcp_gw_agent:get_heartbeat_check_time_span(GwAgent),
      erlang:send_after(HbTimeSpan,self(),{check_heartbeat}),
      {?NO_REPLY,StateWithSock#state{async_recv_state = ?WAIT_HEAD}}
  catch
      Error:Reason:STK  ->
        ?LOG_ERROR({"error when active socket",Error,Reason,{stk,STK}}),
        {?STOP,?NORMAL,State}
  end;
handle_cast({send,BsData},State)->
  try
    bs_yynw_tcp_gw_mgr:send(BsData),
    {?NO_REPLY,State}
  catch
    Error:Reason:STK  ->
      ?LOG_ERROR({"error when send data",Error,Reason,{stk,STK}}),
      {?STOP,?NORMAL,State}
  end;
handle_cast({stop},State)->
  {?STOP,?NORMAL,State};
handle_cast(Req,State)->
  ?LOG_WARNING({"unknown gen cast",[req,Req]}),
  {?NO_REPLY,State}.


handle_info({check_heartbeat},State)->
  try
    bs_yynw_tcp_gw_mgr:check_heartbeat(),
    GwAgent = bs_yynw_tcp_gw_mgr:get_agent(),
    HbTimeSpan = yynw_tcp_gw_agent:get_heartbeat_check_time_span(GwAgent),
    erlang:send_after(HbTimeSpan,self(),{check_heartbeat}),
    {?NO_REPLY,State}
  catch
    Error:Reason:STK  ->
      ?LOG_ERROR({"error when send data",Error,Reason,{stk,STK}}),
      {?STOP,?NORMAL,State}
  end;



%% 获取包头
handle_info({?INET_ASYNC,ClientSocket,_Ref,{?OK,  HeadPack}},State = #state{async_recv_state = ?WAIT_HEAD })->
  GwAgent = bs_yynw_tcp_gw_mgr:get_agent(),
  BodyLength = yynw_tcp_gw_agent:get_body_byte_length(HeadPack,GwAgent),
  {?OK,?WAIT_BODY} = yynw_tcp_helper:async_recv_body(ClientSocket, BodyLength),
  {?NO_REPLY,State#state{async_recv_state = ?WAIT_BODY}};
%% 获取包体，处理业务
handle_info({?INET_ASYNC,ClientSocket,_Ref,{?OK,  BodyData}},State = #state{async_recv_state = ?WAIT_BODY})->
  try
    bs_yynw_tcp_gw_mgr:route_c2s(BodyData),

    GwAgent = bs_yynw_tcp_gw_mgr:get_agent(),
    HeadLength = yynw_tcp_gw_agent:get_head_byte_length(GwAgent),
    {?OK,?WAIT_HEAD} =  yynw_tcp_helper:async_recv_head(ClientSocket,HeadLength),
    {?NO_REPLY,State#state{async_recv_state = ?WAIT_HEAD}}
  catch
    Error:Reason:STK  ->
      ?LOG_ERROR({"error when route_c2s",Error,Reason,{stk,STK}}),
      {?STOP,?NORMAL,State}
  end;
%% 处理超时情况
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,timeout}},State)->
  {?NO_REPLY,State};
%% 处理链接关闭情况
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,closed}},_State)->
  ?LOG_WARNING({"socket closed "}),
  {?STOP,?NORMAL,_State};
%% 处理别的异常
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,Reason}},State)->
  ?LOG_WARNING({"socket error",{Reason}}),
  {?STOP,?NORMAL,State};
handle_info({inet_reply,_sock,_},State)->
  {?NO_REPLY,State};
handle_info(Req,State)->
  ?LOG_WARNING({"unknown gen info",[req,Req]}),
  {?NO_REPLY,State}.




