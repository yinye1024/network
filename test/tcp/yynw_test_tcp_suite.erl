%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 六月 2021 19:07
%%%-------------------------------------------------------------------
-module(yynw_test_tcp_suite).
-author("yinye").
-include_lib("yyutils/include/yyu_comm.hrl").
-include_lib("eunit/include/eunit.hrl").


-define(Port,10090).
-define(RoleId,101).
-define(Ticket,10101).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
api_test_() ->
  yyu_logger:start(),
  [{setup,
    fun start_suite/0,
    fun stop_suite/1,
    fun (_SetupData) ->
      [
        {foreach,
          fun start_case/0,
          fun stop_case/1,
          [
            fun test_a/1,
            fun test_b/1
          ]
        }
      ]
    end}].


start_suite() ->
  ?LOG_INFO({"api test suite start ==================="}),
  %% 启动服务端
  gs_yynw_test_tcp_role_mgr:init(),
  GwAgent = yynw_tcp_gw_agent:new(yynw_test_tcp_gw_agent_impl:get_mod(),yynw_test_tcp_gw_agent_impl:new()),
  yynw_tcp_gw_api:start(?Port,GwAgent),
  yyu_time:sleep(2000),
  {}.

stop_suite({}) ->
  ?LOG_INFO({"api test suite end ======================"}),
  ?OK.

start_case()->
  %% 启动客户端
  gs_yynw_test_tcp_client_mgr:init(),
  gs_yynw_test_tcp_client_mgr:new_child(?RoleId,?Ticket),
  yyu_time:sleep(2000),
  {}.

stop_case({})->
  %% 清理数据
  ?LOG_INFO({"stop case ==================="}),
  gs_yynw_test_tcp_client_mgr:close(?RoleId),
  gs_yynw_test_tcp_role_mgr:close(?RoleId),
  yyu_time:sleep(2000),
  ?OK.

test_a({})->
  {MsgId,C2SId,BinData} = {2,2,<<"test_a">>},
  gs_yynw_test_tcp_client_mgr:send_data(?RoleId,{MsgId,C2SId,BinData}),
  yyu_time:sleep(10000),
  [
    ?_assertMatch(1,1)
  ].

test_b({})->
  {MsgId,C2SId,BinData} = {3,3,<<"test_b">>},
  gs_yynw_test_tcp_client_mgr:send_data(?RoleId,{MsgId,C2SId,BinData}),
  yyu_time:sleep(10000),
  [
    ?_assertMatch(1,1)
  ].

