%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_test_tcp_role_pojo).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

%% API functions defined
-export([new_pojo/2,get_id/1]).
-export([get_tcp_gen/1,set_tcp_gen/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
new_pojo(DataId, {RoleId,TcpGen})->
  #{
    id => DataId,
    roleId => RoleId,
    tcp_gen => TcpGen
  }.

get_id(ItemMap) ->
  yyu_map:get_value(id, ItemMap).

get_tcp_gen(ItemMap) ->
  yyu_map:get_value(tcp_gen, ItemMap).
set_tcp_gen(TcpGen,ItemMap) ->
  yyu_map:put_value(tcp_gen,TcpGen, ItemMap).




