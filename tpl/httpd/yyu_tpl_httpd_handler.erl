%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     处理具体业务
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yyu_tpl_httpd_handler).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-export([handle/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
handle(Req,Method)->

  case priv_parse_http(Method,Req) of
    ?NOT_SET -> {?OK,yyu_json:map_to_json(#{fail=>"uid or ticket not correct"})};
    Qs ->
      Uid = proplists:get_value("uid",Qs),
      Ticket = proplists:get_value("ticket",Qs),
      {?OK,yyu_json:map_to_json(#{uid=>Uid,ticket=>Ticket})}
  end.

priv_parse_http('GET',Req)->
  mochiweb_request:parse_qs(Req);
priv_parse_http('POST',Req)->
  mochiweb_request:parse_post(Req);
priv_parse_http(_Other,_Req)->
  ?NOT_SET.
