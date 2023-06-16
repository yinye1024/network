%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2023, yinye
%%% @doc
%%%
%%% @end
%%% Created : 10. 1月 2023 11:29
%%%-------------------------------------------------------------------
-module(tpl_gw_helper).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").


%% API
-export([send_connect_active_s2c/1]).
-export([call_stop/1,cast_stop/1]).

-define(Svr_Side_MID,1).
-define(ACTIVE_S2C_ID,1).

%% 通知客户端链接激活结果，
send_connect_active_s2c(ResultCode) when is_integer(ResultCode)->
  {MsgId,C2SId,BinData} = {?Svr_Side_MID,?ACTIVE_S2C_ID,yyu_misc:to_binary(ResultCode)},
  priv_send({MsgId,C2SId,BinData}).

priv_send(BsData = {_Mid,_S2CId,_PBufBin} )->
  yynw_tcp_gw_api:inner_send(BsData),
  ?OK.

call_stop(Reason)->
  ?LOG_ERROR({stop,Reason}),
  yynw_tcp_gw_api:call_stop(self()),
  ?OK.
cast_stop(Reason)->
  ?LOG_ERROR({stop,Reason}),
  yynw_tcp_gw_api:cast_stop(self()),
  ?OK.

