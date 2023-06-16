%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 六月 2021 19:07
%%%-------------------------------------------------------------------
-module(yynw_test_http_suite).
-author("yinye").
%% yyu_comm.hrl 和 eunit.hrl 都定义了 IF 宏，eunit.hrl做了保护
-include_lib("yyutils/include/yyu_comm.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(Port,12001).
%% ===================================================================================
%% API functions implements
%% ===================================================================================
http_test_() ->
  yyu_logger:start(),
  ?LOG_INFO({"client test ==================="}),

  {foreach,
  fun start/0,
  fun stop/1,
  [
    fun test_Get/1,
    fun test_Post/1
  ]
  }.
%%  [].


start() ->
  yyu_logger:start(),

  %% 启动 http 服务。
  PoolSize = 16,
  yynw_test_httpd_starter:start(?Port,PoolSize),

  yyu_time:sleep(2000),
  Context = ?NOT_SET,
  {Context}.

stop({Context}) ->
  yyu_time:sleep(2000),
  ?LOG_INFO({"test end",Context}),
  ?OK.


test_Get({_Context})->
%%  http://127.0.0.1:12345/test",[{"uid","101"},{"ticket","tt101"}
  Url = yyu_string:format("http://~s:~w/~s",["127.0.0.1",?Port,"test"]),
  ?LOG_DEBUG({do_get,Url}),
  Params = [{"uid","101"},{"ticket","tt101"}],
  {Result,_Other} = yyu_httpc:do_http_get(Url,Params),
  ?LOG_DEBUG({Result,_Other}),
  [
    ?_assertMatch(?OK,Result)
  ].
test_Post({_Context})->
%%  http://127.0.0.1:12345/test",[{"uid","101"},{"ticket","tt101"}
  Url = yyu_string:format("http://~s:~w/~s",["127.0.0.1",?Port,"test"]),
  ?LOG_DEBUG({do_post,Url}),
%%  Params = [{"uid","101"},{"ticket","tt101"}
  PostMap = #{
    uid=>101,
    ticket=>"tt101"
  },
  {Result,_Other} = yyu_httpc:do_http_post_json(Url,PostMap),
  ?LOG_DEBUG({Result,_Other}),
  [
    ?_assertMatch(?OK,Result)
  ].





