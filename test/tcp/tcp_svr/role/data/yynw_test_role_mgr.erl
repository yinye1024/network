%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_test_role_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([init/1]).
-export([get_tcp_gen/0, switch_tcp_gen/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
init({RoleId,TcpGen})->
  yynw_test_role_dao:init({RoleId,TcpGen}),
  ?OK.

get_tcp_gen()->
  Data = yynw_test_role_dao:get_data(),
  RoleGen = yynw_test_role_pojo:get_tcp_gen(Data),
  RoleGen.

switch_tcp_gen(TcpGen)->
  Data = yynw_test_role_dao:get_data(),
  RoleGen = yynw_test_role_pojo:set_tcp_gen(TcpGen,Data),
  RoleGen.



