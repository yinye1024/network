%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     只是单纯的启动一个进程，来管理启动的http服务
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_httpd_gen).
-author("yinye").

-behavior(gen_server).
-include_lib("yyutils/include/yyu_gs.hrl").
-include_lib("yyutils/include/yyu_comm.hrl").
-define(SERVER,?MODULE).

-record(state,{}).

%% API functions defined
-export([get_mod/0,start_link/1]).
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->
  ?MODULE.

start_link({Port, RouteAgent,PoolSize})->
  gen_server:start_link({local,?SERVER}, ?MODULE,{Port, RouteAgent,PoolSize},[]).

init({Port,RouteAgent,PoolSize})->
  erlang:process_flag(trap_exit,true),
  Opts = [{port,Port},{acceptor_pool_size,PoolSize}],
  DocRoot = "",
  Loop = fun(Req)-> yynw_httpd_route_agent:route_request({Req,DocRoot},RouteAgent) end,
  mochiweb_http:start([{loop,Loop}|Opts]),
  ?LOG_INFO({"init httpd,opts:",Opts}),
  {?OK,#state{}}.

handle_call(_Req,_From,State)->
  {?NO_REPLY,State}.

handle_cast(_Req,State)->

  {?NO_REPLY,State}.
handle_info(_Req,State)->
  {?NO_REPLY,State}.

terminate(_Reason,_State)->
  ?OK.

code_change(_OldVsn,State,_Extra)->
  {?OK,State}.


