%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yynw_tcp_helper).
-author("yinye").
-include_lib("yyutils/include/yyu_comm.hrl").
-include("yyu_tcp.hrl").

%% API functions defined
-export([close_socket_no_delay/1,close_socket/1]).
-export([async_recv_head/2,async_recv_body/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
%% 立刻关闭端口
close_socket_no_delay(Socket) when is_port(Socket)->
  %% 有关闭异常直接吃掉
  catch erlang:port_close(Socket),
  ?OK;
close_socket_no_delay(_Socket)->
  ?OK.
%% 会等到缓存区的发送完才关闭
close_socket(Socket) when is_port(Socket)->
  %% 有关闭异常直接吃掉
  catch gen_tcp:close(Socket),
  ?OK;
close_socket(_Socket)->
  ?OK.

%% 异步，等待获取包头
async_recv_head(ClientSock,HeadLength)->
  case prim_inet:async_recv(ClientSock,HeadLength,-1) of
    {?OK,_Ref}-> {?OK,?WAIT_HEAD};
    {error,Reason}->
      {error,Reason}
  end.

%% 异步，等待获取消包体
async_recv_body(ClientSock,Length)->
  case prim_inet:async_recv(ClientSock,Length,-1) of
    {?OK,_Ref}-> {?OK,?WAIT_BODY};
    {error,Reason}->
      {error,Reason}
  end.
