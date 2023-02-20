%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2023, yinye
%%% @doc
%%%
%%% @end
%%% Created : 05. 1月 2023 15:13
%%%-------------------------------------------------------------------
-module(yynw_test_tcp_role_starter).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

%% API
-export([start_svr/1]).


start_svr(Port)->
  %% 启动服务端
  %% 启动服务端
  gs_yynw_test_tcp_role_mgr:init(),
  GwAgent = yynw_tcp_gw_agent:new(yynw_test_tcp_gw_agent_impl:get_mod(),yynw_test_tcp_gw_agent_impl:new_empty()),
  yynw_tcp_gw_api:start(Port,GwAgent),
  ?OK.