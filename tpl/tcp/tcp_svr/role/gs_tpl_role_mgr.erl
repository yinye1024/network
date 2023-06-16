%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(gs_tpl_role_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([init/0,new_child/1,close/1]).
-export([send_data/4, handle_msg/2]).
-export([remove_tcpGen/1,switch_tcpGen/2]).

-define(MAX_IDLE_TIME, 30).   %% 最大闲置时间30秒，超过就退出进程，回收cursor。

%% ===================================================================================
%% API functions implements
%% ===================================================================================
init()->
  tpl_role_sup:start_link(),
  tpl_role_gen_mgr:init(),
  ?OK.

new_child({RoleId,TcpGen})->
  case tpl_role_gen_mgr:get_pid(RoleId) of
    ?NOT_SET ->
      {?OK,Pid} = tpl_role_sup:new_child({RoleId,TcpGen}),
      Pid;
    Pid->
      switch_tcpGen(TcpGen,RoleId),
      Pid
  end.

close(RoleId)->
  case tpl_role_gen_mgr:get_pid(RoleId) of
    ?NOT_SET ->
      ?LOG_DEBUG({"role gen not found, id:",RoleId}),
      ?OK;
    RolePid->
      tpl_role_gen:do_stop(RolePid),
      ?OK
  end,
  ?OK.

remove_tcpGen(RoleId)->
  priv_cast_fun(RoleId,{fun bs_tpl_role_mgr:remove_tcpGen/1,[{}]}),
  ?OK.

switch_tcpGen(TcpGen,RoleId)->
  priv_cast_fun(RoleId,{fun bs_tpl_role_mgr:switch_tcpGen/1,[{TcpGen}]}),
  ?OK.

send_data(RoleIdOrRolePid,MsgId,C2SId,BinData)->
  priv_cast_fun(RoleIdOrRolePid,{fun bs_tpl_role_mgr:send_msg/1,[{MsgId,C2SId,BinData}]}),
  ?OK.

handle_msg(RoleId,{MsgId, S2CId,BinData})->
  priv_cast_fun(RoleId,{fun bs_tpl_role_mgr:handle_msg/1,[{MsgId, S2CId,BinData}]}),
  ?OK.

priv_cast_fun(RolePid,{CastFun,Param})when is_pid(RolePid)->
  tpl_role_gen:cast_fun(RolePid,{CastFun,Param}),
  ?OK;
priv_cast_fun(RoleId,{CastFun,Param})->
  case tpl_role_gen_mgr:get_pid(RoleId) of
    ?NOT_SET ->
      ?LOG_DEBUG({"role gen not found, id:",RoleId}),
      ?FAIL;
    RolePid->
      tpl_role_gen:cast_fun(RolePid,{CastFun,Param}),
      ?OK
  end.


