%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_client_api).
-author("yinye").
-include_lib("yyutils/include/yyu_comm.hrl").
-include("yyu_tcp.hrl").

%% API functions defined
-export([new_client/1,stop/1,send/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
new_client({Addr,Port,ClientAgent})->
  {?OK,Pid} = yynw_tcp_client_gen:start_link({Addr,Port,ClientAgent}),
  Pid.


stop(Pid)->
  yynw_tcp_client_gen:do_stop(Pid),
  ?OK.

send(Pid,BsData)->
  yynw_tcp_client_gen:do_send(Pid,BsData),
  ?OK.


