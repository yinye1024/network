%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(bs_yynw_test_tcp_role_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-define(ACTIVE_S2CID,1).

%% API functions defined
-export([init/1, loop_tick/0,terminate/1]).
-export([handle_msg/1,send_msg/1]).
-export([switch_tcpGen/1,remove_tcpGen/1]).


%% ===================================================================================
%% API functions implements
%% ===================================================================================
init({RoleId,TcpGen} = _GenArgs)->
  yynw_test_tcp_role_mgr:init({RoleId,TcpGen}),
  yynw_test_tcp_role_gen_mgr:reg(RoleId,self()),
  send_msg({1,?ACTIVE_S2CID,<<"ok">>}),
  ?OK.

loop_tick()->
  ?OK.

terminate(RoleId)->
  yynw_test_tcp_role_gen_mgr:un_reg(RoleId),
  ?OK.

send_msg({MsgId,C2SId,BinData})->
  ?LOG_INFO({"role send msg:",{MsgId,C2SId,BinData}}),
  RoleGen = yynw_test_tcp_role_mgr:get_tcp_gen(),
  yynw_tcp_gw_api:send(RoleGen,{MsgId,C2SId,BinData}),
  ?OK.
remove_tcpGen({})->
  yynw_test_tcp_role_mgr:switch_tcp_gen(?NOT_SET),
  ?OK.

switch_tcpGen({TcpGen})->
  yynw_test_tcp_role_mgr:switch_tcp_gen(TcpGen),
  ?OK.


handle_msg({MsgId, C2SId, BinData})->
  ?LOG_INFO({"received msg from client:",{MsgId, C2SId, BinData}}),
  RoleGen = yynw_test_tcp_role_mgr:get_tcp_gen(),
  yynw_tcp_gw_api:send(RoleGen,{MsgId,C2SId,<<"ok, send next msg">>}),
  ?OK.
