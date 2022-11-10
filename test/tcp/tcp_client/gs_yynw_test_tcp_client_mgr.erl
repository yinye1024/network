%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(gs_yynw_test_tcp_client_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([init/0,new_child/2,close/1]).
-export([send_data/2,handle_svr_msg/2]).

-define(MAX_IDLE_TIME, 30).   %% 最大闲置时间30秒，超过就退出进程，回收cursor。

%% ===================================================================================
%% API functions implements
%% ===================================================================================
init()->
  yynw_test_tcp_client_sup:start_link(),
  yynw_test_tcp_client_gen_mgr:init(),
  ?OK.

new_child(RoleId,Ticket)->
  {?OK,Pid} = yynw_test_tcp_client_sup:new_child({RoleId,Ticket}),
  Pid.

close(RoleId)->
  case yynw_test_tcp_client_gen_mgr:get_pid(RoleId) of
    ?NOT_SET ->
      ?LOG_INFO({"role gen not found, id:",RoleId}),
      ?OK;
    RolePid->
      yynw_test_tcp_client_gen:do_stop(RolePid),
      ?OK
  end,
  ?OK.

send_data(RoleId,{MsgId,C2SId,BinData})->
  priv_cast_fun(RoleId,{fun bs_yynw_test_tcp_client_mgr:send_msg/1,[{MsgId,C2SId,BinData}]}),
  ?OK.

handle_svr_msg(RoleId,{MsgId, S2CId,BinData})->
  priv_cast_fun(RoleId,{fun bs_yynw_test_tcp_client_mgr:handle_svr_msg/1,[{MsgId, S2CId,BinData}]}),
  ?OK.

priv_cast_fun(RoleId,{CastFun,Param})->
  case yynw_test_tcp_client_gen_mgr:get_pid(RoleId) of
    ?NOT_SET ->
      ?LOG_INFO({"role gen not found, id:",RoleId}),
      ?FAIL;
    RolePid->
      yynw_test_tcp_client_gen:cast_fun(RolePid,{CastFun,Param}),
      ?OK
  end.

