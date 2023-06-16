%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(tpl_tcp_client_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([init/1]).
-export([get_tcp_client_gen/0, set_tcp_client_gen/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
init(RoleId)->
  tpl_tcp_client_dao:init(RoleId),
  ?OK.

get_tcp_client_gen()->
  Data = tpl_tcp_client_dao:get_data(),
  ClientGen = tpl_tcp_client_pojo:get_tcp_client_gen(Data),
  ClientGen.

set_tcp_client_gen(TcpClientGen)->
  Data = tpl_tcp_client_dao:get_data(),
  NewData = tpl_tcp_client_pojo:set_tcp_client_gen(TcpClientGen,Data),
  tpl_tcp_client_dao:put_data(NewData),
  ?OK.



