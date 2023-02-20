%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_test_tcp_gw_agent_impl).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-define(ACTIVE_S2C_ID,1).

%% API functions defined
-export([new_empty/0,get_mod/0]).
-export([get_active_pack_size/1,handle_active_pack/2,get_head_byte_length/1,get_body_byte_length/2]).
-export([pack_send_data/2,route_c2s/2]).
-export([handle_time_out/1,on_terminate/1]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->
  ?MODULE.

new_empty()->
  #{
    roleId=>?NOT_SET,
    role_gen=>?NOT_SET,
    time_out_count=>0,
    last_time_out=>?NOT_SET
  }.

priv_on_actived_set(RoleId,RoleGen,ItemMap)->
  ItemMap#{
    roleId=>RoleId,
    role_gen=>RoleGen
  }.
priv_get_role_gen(ItemMap) ->
  yyu_map:get_value(role_gen, ItemMap).
priv_get_roleId(ItemMap)->
  yyu_map:get_value(roleId, ItemMap).


priv_on_time_out(NowTimeSecond,ItemMap)->
  LastTimeOut = priv_get_last_time_out(ItemMap),
  ResetTime = 60*5,
  ItemMap_1 =
  case LastTimeOut =/= ?NOT_SET andalso NowTimeSecond - LastTimeOut > ResetTime  of
    ?TRUE ->ItemMap#{
              time_out_count=>0,
              last_time_out=>?NOT_SET
            };
    ?FALSE ->
      ItemMapTmp_1 = priv_incr_time_out_count(ItemMap),
      ItemMapTmp_1#{last_time_out=>NowTimeSecond}
  end,
  ItemMap_1.


priv_incr_time_out_count(ItemMap) ->
  Cur = priv_get_time_out_count(ItemMap),
  priv_set_time_out_count(Cur+1, ItemMap).
priv_get_time_out_count(ItemMap) ->
  yyu_map:get_value(time_out_count, ItemMap).
priv_set_time_out_count(Value, ItemMap) ->
  yyu_map:put_value(time_out_count, Value, ItemMap).
priv_get_last_time_out(ItemMap) ->
  yyu_map:get_value(last_time_out, ItemMap).

%%======================= 激活包 处理 开始 ===================================================
%% 激活包长度 单位byte
get_active_pack_size(_ItemMap)->
  TotalByteSize = 8,
  TotalByteSize .

%% return ok or fail
handle_active_pack(PackData,ItemMap)->
  {UidBitSize,TicketBitSize} = {32,32},
  {?OK,NewItemMap} =
  case PackData of
    <<Uid:UidBitSize,Ticket:TicketBitSize>> ->
      ?LOG_INFO({"recive packet head [Uid,Ticket]",{Uid,Ticket}}),
      case priv_check_auth({Uid,Ticket},ItemMap) of
        ?TRUE ->
          {RoleId,TcpGen} = {Uid,self()},
          RoleGen = gs_yynw_test_tcp_role_mgr:new_child({RoleId,TcpGen}),
          {?OK,priv_on_actived_set(RoleId,RoleGen,ItemMap)};
        ?FALSE ->
          {MsgId,C2SId,BinData} = {1,?ACTIVE_S2C_ID,<<"Auth fail.">>},
          yynw_tcp_gw_api:send(self(),{MsgId,C2SId,BinData}),
          {?OK,ItemMap}
      end;
    _OtherPack->
      Reason = "packet head incorrect.",
      {MsgId,C2SId,BinData} = {1,?ACTIVE_S2C_ID,<<Reason>>},
      yynw_tcp_gw_api:send(self(),{MsgId,C2SId,BinData}),
      {?OK,ItemMap}
  end,
  ?LOG_INFO({"handle_active_pack finish"}),
  {?OK,NewItemMap}.

priv_check_auth({_Uid,_Ticket},_ItemMap)->
  ?TRUE.
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
route_c2s(BodyPack,ItemMap)->
  <<MsgId:16,C2SId:16,C2SData/bits>> = BodyPack,
  ?LOG_INFO({"server recived data [C2sId,C2sData]",[C2SId,C2SData]}),
  RoleGen = priv_get_role_gen(ItemMap),
  gs_yynw_test_tcp_role_mgr:handle_msg(RoleGen,{MsgId, C2SId,C2SData}),
  ?OK.
%%======================= 数据包 处理 开始 ===================================================

%% 返回fail的时候退出tcp进程
handle_time_out(ItemMap)->
  ItemMap_1 = priv_on_time_out(yyu_time:now_seconds(),ItemMap),
  case priv_get_time_out_count(ItemMap_1) > 5 of
    ?TRUE ->
      ?FAIL;
    ?FALSE->
      {?OK,ItemMap_1}
  end.
on_terminate(ItemMap)->
  RoleId = priv_get_roleId(ItemMap),
  gs_yynw_test_tcp_role_mgr:remove_tcpGen(RoleId),
  ?OK.


pack_send_data(BsData,_ItemMap)->
  {Mid,C2SId,BinData} = BsData,
  Data_Byte_Size = byte_size(BinData),
  Data_Bit_Size = Data_Byte_Size * 8,
  Data_Length = Data_Byte_Size + 4,
  BinToSend = <<Data_Length:32,Mid:16,C2SId:16,BinData:Data_Bit_Size/bits>>,
  BinToSend.




