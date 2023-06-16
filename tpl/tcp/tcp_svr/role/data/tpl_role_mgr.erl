%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(tpl_role_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([init/1]).
-export([get_tcp_gen/0, switch_tcp_gen/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
init({RoleId,TcpGen})->
  tpl_role_dao:init({RoleId,TcpGen}),
  ?OK.

get_tcp_gen()->
  Data = tpl_role_dao:get_data(),
  RoleGen = tpl_role_pojo:get_tcp_gen(Data),
  RoleGen.

switch_tcp_gen(TcpGen)->
  Data = tpl_role_dao:get_data(),
  RoleGen = tpl_role_pojo:set_tcp_gen(TcpGen,Data),
  RoleGen.



