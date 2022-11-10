%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     只是单纯的启动一个监督进程，管理启动的http服务
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_httpd_sup).
-author("yinye").

-behavior(supervisor).
-include_lib("yyutils/include/yyu_comm.hrl").
-define(SERVER,?MODULE).


%% API functions defined
-export([start_link/1,init/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
start_link({Port,RouteAgent,PoolSize})->
  supervisor:start_link({local,?SERVER},?MODULE,{Port,RouteAgent,PoolSize}).

init({Port,RouteAgent,PoolSize})->
  GenMod = yynw_httpd_gen:get_mod(),
  ChileSpec = #{
    id=> GenMod,
    start => {GenMod,start_link,[{Port,RouteAgent,PoolSize}]},
    restart => permanent,  %% 挂了就重启
    shutdown => 2000,
    type => worker,
    modules => [GenMod]
  },
  {?OK,{ {one_for_one,0,1},[ChileSpec]} }.



