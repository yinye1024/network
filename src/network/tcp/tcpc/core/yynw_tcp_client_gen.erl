%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_client_gen).
-author("yinye").

-behavior(gen_server).
-include("yyu_tcp.hrl").
-include_lib("yyutils/include/yyu_gs.hrl").
-include_lib("yyutils/include/yyu_comm.hrl").

-define(SERVER,?MODULE).
-define(TCP_OPTS,
  [binary,
    {active,false},
    {reuseaddr,true},
    {delay_send,true},
    {nodelay,true},
    {send_timeout,8000},
    {exit_on_close,false}
  ]
).
-record(state,{
  client_agent,                                  %% 关键的业务代理，包头长度，包体长度，授权校验等
  sock,                                          %% 对应的socket
  timeout_count = 0,                             %% sock消息处理timeout次数，超过5次关闭socket
  async_recv_state :: ?WAIT_HEAD | ?WAIT_BODY    %% wait_head | wait_body 异步接收数据的状态
}).
-define(LOOP_TICK_TIME,1000).

%% API functions defined
-export([get_mod/0,start_link/1]).
-export([do_stop/1, do_send/2,call_fun/2,cast_fun/2]).
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->
  ?MODULE.
start_link({Addr,Port,ClientAgent})->
  %% 不指定 进程 id
  gen_server:start_link(?MODULE,{Addr,Port,ClientAgent},[]).


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
init({Addr,Port,ClientAgent})->
  erlang:process_flag(trap_exit,true),
  case gen_tcp:connect(Addr,Port,?TCP_OPTS) of
    {?OK,ClientSock}->
      priv_do_active(self(),ClientSock),
      erlang:send_after(?LOOP_TICK_TIME,self(),{loop_tick}),
      {?OK,#state{client_agent = ClientAgent}};
    {?ERROR,Reason}->
      ?LOG_ERROR({"tcp connect error",?ERROR,Reason}),
      {?STOP,?NORMAL}
  end.
priv_do_active(Pid,ClientSock)->
  priv_cast(Pid,{active,ClientSock}).

terminate(Reason,_State=#state{sock = Sock})->
  ?LOG_INFO({"gen terminate",Reason}),
  yynw_tcp_helper:close_socket(Sock),
  ?OK.


code_change(_OldVsn,State,_Extra)->
  {?OK,State}.


handle_call({stop},_From, State)->
  {?STOP,?NORMAL,?OK,State};
handle_call(Req,_From, State)->
  Reply = priv_do_msg(Req),
  {?REPLY,Reply,State}.


handle_cast({active,ClientSock},State=#state{client_agent = ClientAgent})->

  HeadLength = yynw_tcp_client_agent:get_head_byte_length(ClientAgent),
  %% 异步，提前等待激活包的返回头
  case yynw_tcp_helper:async_recv_head(ClientSock,HeadLength) of
    {?OK,?WAIT_HEAD}->
      ActivePack = yynw_tcp_client_agent:get_active_pack(ClientAgent),
      gen_tcp:send(ClientSock,ActivePack), %% 发送包头，登陆包， 然后等待服务端响应
      {?NO_REPLY,State#state{async_recv_state = ?WAIT_HEAD,sock = ClientSock}};
    {?ERROR,Reason}->
      ?LOG_ERROR({"error on active connection",Reason}),
      {?STOP,?NORMAL,State}
  end;
handle_cast({send,BsData},State=#state{sock = ClientSocket,client_agent = ClientAgent})->
  try
    DataPack = yynw_tcp_client_agent:pack_send_data(BsData,ClientAgent),
    erlang:port_command(ClientSocket, DataPack,[force]),
    {?NO_REPLY,State}
  catch
    Error:Reason  ->
      ?LOG_ERROR({"error when send data",Error,Reason}),
      {?STOP,?NORMAL,State}
  end;
handle_cast(Req,State)->
  priv_do_msg(Req),
  {?NO_REPLY,State}.

%% 获取到包头
handle_info({?INET_ASYNC,ClientSocket,_Ref,{?OK,  HeadData}},State = #state{async_recv_state = ?WAIT_HEAD,client_agent = ClientAgent})->
  BodyLength = yynw_tcp_client_agent:get_body_byte_length(HeadData,ClientAgent),
  {?OK,?WAIT_BODY} = yynw_tcp_helper:async_recv_body(ClientSocket, BodyLength),
  {?NO_REPLY,State#state{async_recv_state = ?WAIT_BODY}};
%% 获取到包体，分发业务，等待下一个包头
handle_info({?INET_ASYNC,ClientSocket,_Ref,{?OK, BodyPack}},State = #state{async_recv_state = ?WAIT_BODY,client_agent = ClientAgent})->
  yynw_tcp_client_agent:route_s2c(BodyPack, ClientAgent),
  HeadLength = yynw_tcp_client_agent:get_head_byte_length(ClientAgent),
  {?OK,?WAIT_HEAD} =  yynw_tcp_helper:async_recv_head(ClientSocket,HeadLength),
  {?NO_REPLY,State#state{async_recv_state = ?WAIT_HEAD}};
%% 处理超时情况
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,timeout}},State = #state{timeout_count = TimeOutCount})->
  ?LOG_WARNING({"tcp timeout, Count",TimeOutCount+1}),
  case TimeOutCount + 1 > 5 of
    ?TRUE ->
      {?STOP,?NORMAL,State};
    ?FALSE ->
      {?NO_REPLY,State#state{timeout_count = TimeOutCount+1}}
  end;
%% 处理链接关闭情况
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,closed}},State=#state{client_agent = ClientAgent})->
  ?LOG_WARNING({"socket closed, [ClientAgent]",[ClientAgent]}),
  {?STOP,?NORMAL,State};
%% 处理别的异常
handle_info({?INET_ASYNC,_ClientSocket,_Ref,{error,Reason}},State=#state{client_agent = ClientAgent})->
  ?LOG_WARNING({"socket error, [ClientAgent,Reason]",[ClientAgent,Reason]}),
  {?STOP,?NORMAL,State};
handle_info({loop_tick},State)->
  erlang:send_after(?LOOP_TICK_TIME,self(),{loop_tick}),
  {?NO_REPLY,State};
handle_info({inet_reply,_sock,_},State)->
  {?NO_REPLY,State};
handle_info(Req,State)->
  ?LOG_WARNING({"unknown gen info",[req,Req]}),
  {?NO_REPLY,State}.

priv_do_msg(Msg)->
  Result =
  case Msg of
    {do_fun,Fun,Param} ->
      erlang:apply(Fun,Param);
    _->
      ?LOG_WARNING({"unknown msg",Msg}),
      {?FAIL,unknown}
  end,
  Result.

