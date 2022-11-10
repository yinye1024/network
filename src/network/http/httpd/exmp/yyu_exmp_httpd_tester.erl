%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     转发到业务handler 处理具体业务
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yyu_exmp_httpd_tester).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-export([test/0]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
%% yyu_exmp_httpd_tester:test().
test()->

  yyu_logger:start(),

  RouteAgent = yynw_httpd_route_agent:new(yyu_exmp_httpd_route),
  PoolSize = 16,
  yynw_httpd_sup:start_link({12345,RouteAgent,PoolSize}),

  yyu_time:sleep(2000),
  Return1 = yyu_es_restful:do_http_get("http://127.0.0.1:12345/test",[{"uid","101"},{"ticket","tt101"}]),
  Return1.

