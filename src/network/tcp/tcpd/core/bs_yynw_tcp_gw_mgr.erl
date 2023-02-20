%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(bs_yynw_tcp_gw_mgr).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-export([init/0,terminate/0]).
-export([do_active/2,send/1,check_heartbeat/0,route_c2s/1,get_agent/0]).

init()->
  yynw_tcp_gw_pc_mgr:init(),
  ?OK.

terminate()->
  case yynw_tcp_gw_pc_mgr:get_agent() of
    ?NOT_SET ->?OK;
    GwAgent ->
      yynw_tcp_gw_agent:on_terminate(GwAgent),
      ?OK
  end,

  case yynw_tcp_gw_pc_mgr:get_sock() of
    ?NOT_SET ->?OK;
    Sock ->
      yynw_tcp_helper:close_socket(Sock),
      ?OK
  end,
  ?OK.

do_active({ClientSock,GwAgent},PackData)->
  yynw_tcp_gw_pc_mgr:set_sock(ClientSock),
  yynw_tcp_gw_pc_mgr:set_agent(GwAgent),
  {?OK,NewGwAgent} = yynw_tcp_gw_agent:handle_active_pack(PackData,GwAgent),
  yynw_tcp_gw_pc_mgr:set_agent(NewGwAgent),
  ?OK.
send(BsDataList) when is_list(BsDataList)->
  priv_send_list(BsDataList);
send(BsData)->
  GwAgent = yynw_tcp_gw_pc_mgr:get_agent(),
  ClientSocket = yynw_tcp_gw_pc_mgr:get_sock(),
  DataPack = yynw_tcp_gw_agent:pack_send_data(BsData,GwAgent),
  erlang:port_command(ClientSocket, DataPack,[force]),
  ?OK.
priv_send_list([BsData|Less])->
  send(BsData),
  priv_send_list(Less);
priv_send_list([])->
  ?OK.

check_heartbeat()->
  GwAgent = yynw_tcp_gw_pc_mgr:get_agent(),
  {?OK,NewGwAgent} = yynw_tcp_gw_agent:check_heartbeat(GwAgent),
  yynw_tcp_gw_pc_mgr:set_agent(NewGwAgent),
  ?OK.

route_c2s(BodyData)->
  GwAgent = get_agent(),
  {?OK,NewGwAgent} = yynw_tcp_gw_agent:route_c2s(BodyData,GwAgent),
  yynw_tcp_gw_pc_mgr:set_agent(NewGwAgent),
  ?OK.

get_agent()->
  GwAgent = yynw_tcp_gw_pc_mgr:get_agent(),
  GwAgent.