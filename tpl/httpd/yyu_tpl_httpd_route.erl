%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     转发到业务handler 处理具体业务
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yyu_tpl_httpd_route).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-export([get_mod/0,route_request/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
get_mod()->?MODULE.

route_request(Req,DocRoot)->
  Method = mochiweb_request:get(method,Req),
  Path = "/"++Path0 = mochiweb_request:get(path,Req),
  {Main,Minor} = mochiweb_request:get(version,Req),
  ?LOG_DEBUG({debug,[Method,Path,Main,Minor]}),

  case priv_get_handler(Path0) of
    {?OK,Mod}->priv_do_handle(Mod,Req,Method);
    _->
      case Path0 of
        "file"->
          mochiweb_request:serve_file(Path0,DocRoot,Req);
        _->
          ?LOG_DEBUG({"no match handler for http request",Path0})
      end
  end,
  ?OK.
%% AA = yyu_json:tuple_to_json({"101","tk101"}),
priv_do_handle(Mod,Req,Method)->

  try
      case Mod:handle(Req,Method) of
        {?OK,Resp} ->
          mochiweb_request:respond({200,[],Resp},Req);
        Other ->
          mochiweb_request:respond({500,[],Other},Req)
      end
  catch
      Error:Reason  ->
        ?LOG_DEBUG({"Http handle error",[Error,Reason]}),
        mochiweb_request:respond({500,[],Reason},Req)
  end.

priv_get_handler("test")->
  {?OK,yyu_tpl_httpd_handler};
priv_get_handler(_Other)->
  {?FAIL,?NOT_SET}.
