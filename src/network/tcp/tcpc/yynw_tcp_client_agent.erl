%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_client_agent).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([new/2]).
-export([get_active_pack/1,get_head_byte_length/1,get_body_byte_length/2]).
-export([pack_send_data/2, route_s2c/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
new(ClientMod, ClientData)->
  Agent = #{
    client_mod => ClientMod,
    client_data => ClientData
    },
  Agent.
priv_get_mod(ItemMap) ->
  yyu_map:get_value(client_mod, ItemMap).
priv_get_data(ItemMap) ->
  yyu_map:get_value(client_data, ItemMap).


%%======================= 激活包 处理 开始 ===================================================
get_active_pack(ItemMap)->
  ClientMod = priv_get_mod(ItemMap),
  ClientData = priv_get_data(ItemMap),
  ClientMod:get_active_pack(ClientData).

%%======================= 激活包 处理 结束 ===================================================


%%======================= 数据包 处理 开始 ===================================================

%% 包头长度
get_head_byte_length(ItemMap)->
  ClientMod = priv_get_mod(ItemMap),
  ClientData = priv_get_data(ItemMap),
  ClientMod:get_head_byte_length(ClientData).

%% 包体长度
get_body_byte_length(HeadPack,ItemMap)->
  ClientMod = priv_get_mod(ItemMap),
  ClientData = priv_get_data(ItemMap),
  ClientMod:get_body_byte_length(HeadPack,ClientData).

%% 业务分发
route_s2c(BodyPack,ItemMap)->
  ClientMod = priv_get_mod(ItemMap),
  ClientData = priv_get_data(ItemMap),
  ClientMod:route_s2c(BodyPack,ClientData),
  ?OK.
%%======================= 数据包 处理 开始 ===================================================

pack_send_data(BsData,ItemMap)->
  ClientMod = priv_get_mod(ItemMap),
  ClientData = priv_get_data(ItemMap),
  ClientMod:pack_send_data(BsData,ClientData).





