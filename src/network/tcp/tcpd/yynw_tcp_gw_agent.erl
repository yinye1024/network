%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_gw_agent).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([new/2]).
-export([get_active_pack_size/1,handle_active_pack/2,get_head_byte_length/1,get_body_byte_length/2]).
-export([pack_send_data/2,route_c2s/2]).
-export([handle_time_out/1,on_terminate/1]).
-export([get_heartbeat_check_time_span/1,check_heartbeat/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
new(GateWayMod, GateWayData)->
  Agent = #{
    gw_mod => GateWayMod,
    gw_data => GateWayData
    },
  Agent.
priv_get_gw_mod(ItemMap) ->
  yyu_map:get_value(gw_mod, ItemMap).
priv_get_gw_data(ItemMap) ->
  yyu_map:get_value(gw_data, ItemMap).
priv_set_gw_data(GwData,ItemMap) ->
  yyu_map:put_value(gw_data,GwData, ItemMap).


%%======================= 激活包 处理 开始 ===================================================
%% 激活包长度 单位byte
get_active_pack_size(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  GwMod:get_active_pack_size(GwData).

%% 返回的 NewGwAgent 会被保存
handle_active_pack(PackData,ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  {?OK,NewGwData} = GwMod:handle_active_pack(PackData,GwData),
  NewGwAgent = priv_set_gw_data(NewGwData,ItemMap),
  {?OK,NewGwAgent}.

%%======================= 激活包 处理 结束 ===================================================


%%======================= 数据包 处理 开始 ===================================================

%% 包头长度
get_head_byte_length(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  GwMod:get_head_byte_length(GwData).

%% 包体长度
get_body_byte_length(HeadPack,ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  GwMod:get_body_byte_length(HeadPack,GwData).

%% 业务分发
route_c2s(BodyPack,ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  {?OK,NewGwData} = GwMod:route_c2s(BodyPack,GwData),
  NewGwAgent = priv_set_gw_data(NewGwData,ItemMap),
  {?OK,NewGwAgent}.
%%======================= 数据包 处理 结束 ===================================================

%%======================= 心跳 相关 开始 ===================================================

get_heartbeat_check_time_span(ItemMap) ->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  GwMod:get_heartbeat_check_time_span(GwData).

check_heartbeat(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  {?OK,NewGwData} = GwMod:check_heartbeat(GwData),
  NewGwAgent = priv_set_gw_data(NewGwData,ItemMap),
  {?OK,NewGwAgent}.
%%======================= 心跳 相关 结束 ===================================================





%% 返回 {?OK,NewGwAgent} 或者  ?FAIL
%% NewGwAgent 会保存，?FAIL 会关闭 yynw_tcp_gw_gen 进程
handle_time_out(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  case GwMod:handle_time_out(GwData) of
    {?OK,NewGwData} ->
      NewGwAgent = priv_set_gw_data(NewGwData,ItemMap),
      {?OK,NewGwAgent};
    ?FAIL ->
      ?FAIL
  end.

on_terminate(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  GwMod:on_terminate(GwData),
  ?OK.

pack_send_data(BsData,ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwData = priv_get_gw_data(ItemMap),
  GwMod:pack_send_data(BsData,GwData).




