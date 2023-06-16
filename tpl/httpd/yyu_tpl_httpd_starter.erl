%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yyu_tpl_httpd_starter).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-export([start_svr/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
%% yyu_tpl_httpd_tester:test().
start_svr(Port,PoolSize)->
  yyu_logger:start(),
  RouteAgent = yynw_httpd_route_agent:new(yyu_tpl_httpd_route:get_mod()),
  yynw_httpd_sup:start_link({Port,RouteAgent,PoolSize}),
  ?OK.

