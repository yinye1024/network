%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     网关进程，每个用户一个
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_gw_sup).
-author("yinye").

-behavior(supervisor).
-include_lib("yyutils/include/yyu_comm.hrl").
-define(SERVER,?MODULE).


%% API functions defined
-export([start_link/0,get_mod/0,new_child/0,init/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->
  ?MODULE.

start_link()->
  supervisor:start_link({local,?SERVER},?MODULE,{}).

new_child()->
  supervisor:start_child(?MODULE,[]).


init({}) ->
  ChileSpec = #{
    id=> yynw_tcp_gw_gen:get_mod(),
    start => {yynw_tcp_gw_gen:get_mod(),start_link,[]},
    restart => temporary,  %% 挂了就重启
    shutdown => 2000,
    type => worker,
    modules => [yynw_tcp_gw_gen:get_mod()]
  },
  {?OK,{ {simple_one_for_one,10,10},[ChileSpec]} }.



