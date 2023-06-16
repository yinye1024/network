%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(bs_tpl_tcp_client_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-define(ACTIVE_S2CID,1).

%% API functions defined
-export([init/1, loop_tick/0,terminate/1]).
-export([handle_svr_msg/1,send_msg/1]).


%% ===================================================================================
%% API functions implements
%% ===================================================================================
init({RoleId,Ticket} = _GenArgs)->
  tpl_tcp_client_mgr:init(RoleId),
  priv_new_role(RoleId,Ticket),
  tpl_tcp_client_gen_mgr:reg(RoleId,self()),
  ?OK.

loop_tick()->
  ?OK.

terminate(RoleId)->
  tpl_tcp_client_gen_mgr:un_reg(RoleId),
  ?OK.

priv_new_role(RoleId,Ticket)->
  ClientAgent = yynw_tcp_client_agent:new(tpl_tcp_client:get_mod(), tpl_tcp_client:new(RoleId,Ticket)),
  {Addr,Port} = {"127.0.0.1",10090},
  ClientGen = yynw_tcp_client_api:new_client({Addr,Port,ClientAgent}),
  tpl_tcp_client_mgr:set_tcp_client_gen(ClientGen),
  ?OK.

send_msg({MsgId,C2SId,BinData})->
  ?LOG_INFO({"client send msg:",{MsgId,C2SId,BinData}}),
  ClientGen = tpl_tcp_client_mgr:get_tcp_client_gen(),
  yynw_tcp_client_api:send(ClientGen,{MsgId,C2SId,BinData}),
  ?OK.


handle_svr_msg({_MsgId,?ACTIVE_S2CID, BinData})->
  ?LOG_INFO({"tcp actived +++++++++++++++ resuldCode:", yyu_misc:to_integer(BinData)}),
  ?OK;
handle_svr_msg({MsgId,S2CId, BinData})->
  ?LOG_INFO({"received msg from svr:",{MsgId,S2CId, BinData}}),
  ?OK.
