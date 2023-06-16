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
-export([new/1]).
-export([get_active_pack_size/1,handle_active_pack/2,get_head_byte_length/1,get_body_byte_length/2]).
-export([pack_send_data/2,route_c2s/2]).
-export([on_terminate/1]).
-export([get_heartbeat_check_time_span/1,check_heartbeat/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
new(GateWayMod)->
  Agent = #{
    gw_mod => GateWayMod
    },
  Agent.
priv_get_gw_mod(ItemMap) ->
  yyu_map:get_value(gw_mod, ItemMap).


%%======================= 激活包 处理 开始 ===================================================
%% 激活包长度 单位byte
get_active_pack_size(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  Size = GwMod:get_active_pack_size(),
  Size.

%% 返回的 NewGwAgent 会被保存
handle_active_pack(PackData,ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwMod:handle_active_pack(PackData),
  ?OK.

%%======================= 激活包 处理 结束 ===================================================


%%======================= 数据包 处理 开始 ===================================================

%% 包头长度
get_head_byte_length(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  Len = GwMod:get_head_byte_length(),
  Len.

%% 包体长度
get_body_byte_length(HeadPack,ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  Len = GwMod:get_body_byte_length(HeadPack),
  Len.

%% 业务分发
route_c2s(BodyPack,ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwMod:route_c2s(BodyPack),
  ?OK.
%%======================= 数据包 处理 结束 ===================================================

%%======================= 心跳 相关 开始 ===================================================

get_heartbeat_check_time_span(ItemMap) ->
  GwMod = priv_get_gw_mod(ItemMap),
  TimeSpan = GwMod:get_heartbeat_check_time_span(),
  TimeSpan.

check_heartbeat(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwMod:check_heartbeat(),
  ?OK.

on_terminate(ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  GwMod:on_terminate(),
  ?OK.

pack_send_data(BsData,ItemMap)->
  GwMod = priv_get_gw_mod(ItemMap),
  DataPack = GwMod:pack_send_data(BsData),
  DataPack.




