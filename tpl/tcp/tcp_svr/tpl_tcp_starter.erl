%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2023, yinye
%%% @doc
%%%
%%% @end
%%% Created : 05. 1月 2023 15:13
%%%-------------------------------------------------------------------
-module(tpl_tcp_starter).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

%% API
-export([start_svr/1]).


start_svr(Port)->
  %% 启动服务端
  gs_tpl_role_mgr:init(),
  GwAgent = yynw_tcp_gw_agent:new(tpl_gw:get_mod()),
  yynw_tcp_gw_api:start(Port,GwAgent),
  ?OK.
