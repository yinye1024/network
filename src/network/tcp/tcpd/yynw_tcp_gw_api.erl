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
-export([start/2,send/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
start(ListenPort,GwAgent)->
  yynw_tcp_gw_sup:start_link(),
  yynw_tcp_listener_sup:start_link(ListenPort,GwAgent),
  ?OK.


send(GwPid,BsData)->
  yynw_tcp_gw_gen:do_send(GwPid,BsData),
  ?OK.

