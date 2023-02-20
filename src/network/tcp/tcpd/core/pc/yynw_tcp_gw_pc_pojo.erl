%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_gw_pc_pojo).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

%% API functions defined
-export([new_pojo/1,get_id/1]).
-export([get_sock/1,set_sock/2]).
-export([get_agent/1,set_agent/2]).
%% ===================================================================================
%% API functions implements
%% ===================================================================================
new_pojo(DataId)->
  #{
    id => DataId,
    sock => ?NOT_SET,
    agent => ?NOT_SET
  }.


get_id(ItemMap) ->
  yyu_map:get_value(id, ItemMap).


get_sock(ItemMap) ->
  yyu_map:get_value(sock, ItemMap).

set_sock(Value, ItemMap) ->
  yyu_map:put_value(sock, Value, ItemMap).


get_agent(ItemMap) ->
  yyu_map:get_value(agent, ItemMap).

set_agent(Value, ItemMap) ->
  yyu_map:put_value(agent, Value, ItemMap).


