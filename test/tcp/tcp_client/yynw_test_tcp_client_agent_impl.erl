%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_test_tcp_client_agent_impl).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined
-export([new/2,get_mod/0]).
-export([get_active_pack/1,get_head_byte_length/1,get_body_byte_length/2]).
-export([pack_send_data/2, route_s2c/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->
  ?MODULE.

new(RoleId,Ticket)->
  #{
    roleId=>RoleId,
    ticket=>Ticket
  }.
priv_get_roleId(ItemMap) ->
  yyu_map:get_value(roleId, ItemMap).

priv_get_ticket(ItemMap) ->
  yyu_map:get_value(ticket, ItemMap).



%%======================= 激活包 处理 开始 ===================================================
%% return ok or fail
get_active_pack(ItemMap)->
  {RoleId,Ticket} = {priv_get_roleId(ItemMap) ,priv_get_ticket(ItemMap)},
  <<RoleId:32,Ticket:32>>.

%%======================= 激活包 处理 结束 ===================================================


%%======================= 数据包 处理 开始 ===================================================

%% 包头长度
get_head_byte_length(_ItemMap)->
  4.
%% 包体长度
get_body_byte_length(HeadPack,_ItemMap)->
  <<Length:32>> = HeadPack,
  Length.

%% 业务分发
route_s2c(BodyPack,ItemMap)->
  <<MsgId:16, S2CId:16, S2CData/bits>> = BodyPack,
  RoleId = priv_get_roleId(ItemMap),
  gs_yynw_test_tcp_client_mgr:handle_svr_msg(RoleId,{MsgId, S2CId,S2CData}),
  ?OK.
%%======================= 数据包 处理 开始 ===================================================

pack_send_data(BsData,_ItemMap)->
  {Mid,C2SId,BinData} = BsData,
  Data_Byte_Size = byte_size(BinData),
  Data_Bit_Size = Data_Byte_Size * 8,
  Data_Length = Data_Byte_Size + 4,
  BinToSend = <<Data_Length:32,Mid:16,C2SId:16,BinData:Data_Bit_Size/bits>>,
  BinToSend.





