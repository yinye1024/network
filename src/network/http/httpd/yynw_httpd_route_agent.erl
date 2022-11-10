%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     只是单纯的启动一个进程，来管理启动的http服务
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_httpd_route_agent).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([new/1, route_request/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
new(RouteMod)->
  #{
    route_mod => RouteMod
  }.

route_request({Req,DocRoot},ItemMap)->
  RouteMod = priv_get_route_mod(ItemMap),
  RouteMod:route_request(Req,DocRoot).


priv_get_route_mod(ItemMap) ->
  yyu_map:get_value(route_mod, ItemMap).
