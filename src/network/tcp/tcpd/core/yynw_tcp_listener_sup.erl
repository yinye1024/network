%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     只是单纯的启动一个监督进程，管理启动的http服务
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_listener_sup).
-author("yinye").

-behavior(supervisor).
-include_lib("yyutils/include/yyu_comm.hrl").
-define(SERVER,?MODULE).


%% API functions defined
-export([start_link/2,init/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
start_link(Port,ClientMgr)->
  supervisor:start_link({local,?SERVER},?MODULE,{Port,ClientMgr}).


init({Port,ClientMgr})->
  ChileSpec = #{
    id=> yynw_tcp_listener_gen:get_mod(),
    start => {yynw_tcp_listener_gen:get_mod(),start_link,[{Port,ClientMgr}]},
    restart => permanent,  %% 挂了就重启
    shutdown => 2000,
    type => worker,
    modules => [yynw_tcp_listener_gen:get_mod()]
  },
  {?OK,{ {one_for_one,0,1},[ChileSpec]} }.



