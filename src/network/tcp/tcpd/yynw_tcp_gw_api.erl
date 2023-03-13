%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_gw_api).
-author("yinye").
-include_lib("yyutils/include/yyu_comm.hrl").
-include("yyu_tcp.hrl").

%% API functions defined
-export([start/2,send/2, call_stop/1,cast_stop/1]).
-export([inner_send/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
start(ListenPort,GwAgent)->
  yynw_tcp_gw_sup:start_link(),
  yynw_tcp_listener_sup:start_link(ListenPort,GwAgent),
  ?OK.

%% send bsData inside yynw_tcp_gw_gen
inner_send(BsData)->
  bs_yynw_tcp_gw_mgr:send(BsData).


send(GwPid,BsData)->
  yynw_tcp_gw_gen:do_send(GwPid,BsData),
  ?OK.

call_stop(GwPid)->
  ?LOG_INFO({"call stop ...",GwPid}),
  yynw_tcp_gw_gen:call_stop(GwPid),
  ?OK.
cast_stop(GwPid)->
  yynw_tcp_gw_gen:cast_stop(GwPid),
  ?OK.

