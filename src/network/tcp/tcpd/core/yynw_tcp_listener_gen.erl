%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_listener_gen).
-author("yinye").

-behavior(gen_server).
-include_lib("yyutils/include/yyu_comm.hrl").
-include_lib("yyutils/include/yyu_gs.hrl").
-include("yyu_tcp.hrl").

-define(SERVER,?MODULE).

-record(state,{
  lsock, %% 对外端口监听socket
  gw_agent,
  max_connect=128,
  cur_connect=0
}).

%% API functions defined
-export([start_link/1,get_mod/0]).
-export([is_exist/0,get_cur_connect_count/0,get_max_connect_count/0,get_clients/0,set_max_connect/1]).
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->
  ?MODULE.
start_link({Port,GateWayAgent})->
  gen_server:start_link({local,?SERVER},?MODULE,{Port,GateWayAgent},[]).

is_exist()->
  erlang:whereis(?SERVER) =/= ?UNDEFINED.

get_cur_connect_count()->
  priv_call(cur_connect).

get_max_connect_count()->
  priv_call(max_connect).

%% 获取当前client 链接pid列表
get_clients()->
  priv_call(clients).

set_max_connect(Max)->
  priv_cast({set_max_connect,Max}).


%% ===================================================================================
%% Behavioural functions implements
%% ===================================================================================
init({Port,GateWayAgent})->
  erlang:process_flag(trap_exit,true),
  LSock = priv_do_listen(Port),
  priv_cast(async_accept),

  ?LOG_INFO({"init tcp,port:",Port}),
  {?OK,#state{lsock = LSock, gw_agent = GateWayAgent}}.


terminate(Reason,_State)->
  ?LOG_WARNING({"terminate reason:",Reason}),
  ?OK.

code_change(_OldVsn,State,_Extra)->
  {?OK,State}.


%% ===================================================================================
%% internal functions implements
%% ===================================================================================
priv_cast(Req)->
  gen_server:cast(?MODULE,Req).
priv_call(Req)->
  TimeOut = 5000, %% call 要设置超时
  gen_server:call(?MODULE,Req,TimeOut).

handle_call(cur_connect,_From,State = #state{cur_connect = CurConnect})->
  {?REPLY,CurConnect,State};
handle_call(max_connect,_From,State = #state{max_connect = MaxConnect})->
  {?REPLY,MaxConnect,State};
handle_call(clients,_From,State)->
  {monitors,List} = erlang:process_info(self(),monitors),
  Clients = [Pid || {process,Pid} <- List],
  {?REPLY,Clients,State};
handle_call(Req,_From,State)->
  Reply = {"unknown gen call",[req,Req]},
  {?REPLY,Reply,State}.


handle_cast({set_max_connect,Max},State)->
  {?NO_REPLY,State#state{max_connect = Max}};
handle_cast(async_accept,State)->
  priv_async_accept(State);
handle_cast(Req,State)->
  ?LOG_WARNING({"unknown gen cast",[req,Req]}),
  {?NO_REPLY,State}.

%% 判断是否达到最大链接数
handle_info({?INET_ASYNC,_LSock,_Ref,{?OK, ClientSocket}},State=#state{cur_connect = Cur,max_connect = Max }) when (Cur >= Max)->
  ?LOG_INFO({"not accept new connection,reach max.",[max,Max]}),
  yynw_tcp_helper:close_socket_no_delay(ClientSocket),
  priv_async_accept(State);
%% 接受链接
handle_info({?INET_ASYNC,_LSock,_Ref,{?OK, ClientSocket}},State=#state{gw_agent = GateWayAgent,cur_connect = CurConnect })->
  ?TRUE = inet_db:register_socket(ClientSocket,inet_tcp), %% 初始化socket
  case yynw_tcp_gw_sup:new_child() of
    {?OK,ClientPid}->
      erlang:monitor(process,ClientPid),
      NewState =
      case gen_tcp:controlling_process(ClientSocket,ClientPid) of %% 让 ClientPid 来控制 ClientSocket
        ?OK ->
          yynw_tcp_gw_gen:active(ClientPid,{ClientSocket,GateWayAgent}),
          State#state{cur_connect = CurConnect+1};
        {error,Reason}->
          ?LOG_ERROR({"gen_tcp:controlling_process error,reason",Reason}),
          yynw_tcp_helper:close_socket_no_delay(ClientSocket),
          State
      end,
      priv_async_accept(NewState);
    Error ->
      ?LOG_ERROR({"yyu_tcp_gw_agent:new_child  error,reason",Error}),
      yynw_tcp_helper:close_socket_no_delay(ClientSocket),
      priv_async_accept(State)
  end;

handle_info({'DOWN',_MRef,process,_Pid,_Info},State = #state{cur_connect = CurConnection})->
  {?NO_REPLY,State#state{cur_connect = CurConnection-1}};
handle_info(Req,State)->
  ?LOG_WARNING({"unknown gen info",[req,Req]}),
  {?NO_REPLY,State}.

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
priv_do_listen(Port)->
  case gen_tcp:listen(Port,?TCP_OPTS) of
    {?OK,LSock}->LSock;
    Error ->
      ?LOG_ERROR({"error on start tcp listener,reason:",Error}),
      exit(Error)
  end.

%% 异步等待客户端消息到达
priv_async_accept(State = #state{lsock = LSock})->
  case prim_inet:async_accept(LSock,-1) of
    {?OK,_Ref}->{?NO_REPLY,State};
    Error ->
      ?LOG_ERROR({"async_accept error,reason:",[reason,Error],[data,LSock]}),
      {?STOP,{cannot_accept,Error},State}
  end.
