%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(tpl_gw).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API functions defined for gw_agent
-export([get_mod/0]).
-export([get_active_pack_size/0,handle_active_pack/1,get_head_byte_length/0]).
-export([get_body_byte_length/1,route_c2s/1]).
-export([pack_send_data/1]).
-export([on_terminate/0]).
-export([get_heartbeat_check_time_span/0,check_heartbeat/0]).



-define(ActivePackByteLength,8).
-define(UserIdBitSize,32).
-define(TicketBitSize,32).
-define(HeadByteLength,4).
-define(HeadBitSize,32).
-define(MsgIdBitSize,16).
-define(C2SIdBitSize,16).
-define(S2CIdBitSize,16).



-define(Logout_Normal,0). %% 正常登出
-define(Logout_Active_Auth_Fail,1). %% 激活包校验失败
-define(Logout_Heartbeat_Timeout_Reach_Max,7).        %% 心跳超时达到上限


%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->
  ?MODULE.

%%======================= 激活包 处理 开始 ===================================================
%% 激活包长度 单位byte
get_active_pack_size()->
  ?ActivePackByteLength.

%% return {ok,NewContextItem}
handle_active_pack(_PackData = <<UserId:?UserIdBitSize,Ticket:?TicketBitSize>>)->
  ?LOG_INFO({"recive packet head {userId,ticket}:",{UserId,Ticket}}),
  tpl_gw_pc_mgr:init(),
  ContextItem = tpl_gw_pc_mgr:get_context(),
  case priv_check_auth(UserId,Ticket) of
    ?TRUE ->
      ContextItem_1 = tpl_gw_context:on_active({UserId,Ticket},ContextItem),
      tpl_gw_pc_mgr:set_context(ContextItem_1),
      RolePid = gs_tpl_role_mgr:new_child({UserId,self()}),
      priv_set_self_monitor_by(RolePid),
      Success = 1,
      tpl_gw_helper:send_connect_active_s2c(Success),
      ?OK;
    ?FALSE ->
      Fail = 0,
      tpl_gw_helper:send_connect_active_s2c(Fail),
      tpl_gw_helper:cast_stop(?Logout_Active_Auth_Fail),
      ?OK
  end,
  ?OK.
priv_set_self_monitor_by(RolePid)->
  yyu_pid:set_self_monitor_by(RolePid),
  tpl_gw_pc_mgr:set_bs_gen(RolePid),
  ?OK.

priv_check_auth(_UserId,_Ticket)->
  ?TRUE.
%%======================= 激活包 处理 结束 ===================================================


%%======================= 数据包 处理 开始 ===================================================

%% 包头长度
get_head_byte_length()->
  ?HeadByteLength.

%% 包体长度
get_body_byte_length(HeadPack)->
  <<Length:?HeadBitSize>> = HeadPack,
  Length.

%% 业务分发
route_c2s(BodyPack)->
  <<MsgId:?MsgIdBitSize,C2SId:?C2SIdBitSize,C2SData/bits>> = BodyPack,
  ?LOG_INFO({"server recived data [C2sId,C2sData]",[C2SId,C2SData]}),
  RoleGen = tpl_gw_pc_mgr:get_bs_gen(),
  gs_tpl_role_mgr:handle_msg(RoleGen,{MsgId, C2SId,C2SData}),
  ?OK.


%%======================= 数据包 处理 开始 ===================================================


%%======================= 心跳 相关 开始 ===================================================
get_heartbeat_check_time_span() ->
  60*1000. %% 心跳检查间隔 60秒

check_heartbeat()->
  case tpl_gw_pc_mgr:is_max_heartbeat_time_out() of
    ?TRUE ->
      tpl_gw_helper:cast_stop(?Logout_Heartbeat_Timeout_Reach_Max),
      ?OK;
    ?FALSE ->
      tpl_gw_pc_mgr:check_heartbeat(),
      ?OK
  end,
  ?OK.
%%======================= 心跳 相关 结束 ===================================================

on_terminate()->
  ?OK.

pack_send_data(BsData)->
  {Mid, S2CId,BinData} = BsData,
  Data_Byte_Size = byte_size(BinData),
  Data_Bit_Size = Data_Byte_Size * 8,
  Data_Length = Data_Byte_Size + 4,
  BinToSend = <<Data_Length:?HeadBitSize,Mid:?MsgIdBitSize, S2CId:?S2CIdBitSize,BinData:Data_Bit_Size/bits>>,
  BinToSend.




