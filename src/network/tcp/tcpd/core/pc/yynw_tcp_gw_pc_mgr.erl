%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_gw_pc_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([init/0]).
-export([get_sock/0,set_sock/1]).
-export([get_agent/0,set_agent/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
init()->
  yynw_tcp_gw_pc_dao:init(),
  ?OK.

get_sock()->
  Data = priv_get_data(),
  Sock = yynw_tcp_gw_pc_pojo:get_sock(Data),
  Sock.

set_sock(Sock)->
  Data = yynw_tcp_gw_pc_dao:get_data(),
  NewData = yynw_tcp_gw_pc_pojo:set_sock(Sock,Data),
  priv_update(NewData).

get_agent()->
  Data = priv_get_data(),
  Agent = yynw_tcp_gw_pc_pojo:get_agent(Data),
  Agent.

set_agent(Agent)->
  Data = yynw_tcp_gw_pc_dao:get_data(),
  NewData = yynw_tcp_gw_pc_pojo:set_agent(Agent,Data),
  priv_update(NewData).

priv_get_data()->
  Data = yynw_tcp_gw_pc_dao:get_data(),
  Data.

priv_update(Data)->
  yynw_tcp_gw_pc_dao:put_data(Data),
  ?OK.




