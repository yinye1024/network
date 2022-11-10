%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%     转发到业务handler 处理具体业务
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yyu_exmp_httpd_route).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

-export([route_request/2]).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
route_request(Req,DocRoot)->
  Method = Req:get(method),
  Path = "/"++Path0 = Req:get(path),
  {Main,Minor} = Req:get(version),
  ?LOG_DEBUG({debug,[Method,Path,Main,Minor]}),

  case priv_get_handler(Path0) of
    {?OK,Mod}->priv_do_handle(Mod,Req,Method);
    _->
      case Path0 of
        "file"->
          Req:serve_file(Path0,DocRoot);
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
          Req:respond({200,[],Resp});
        Other ->
          Req:respond({500,[],Other})
      end
  catch
      Error:Reason  ->
        ?LOG_DEBUG({"Http handle error",[Error,Reason]}),
        Req:respond({500,[],Reason})
  end.

priv_get_handler("test")->
  {?OK,yyu_exmp_httpd_handler};
priv_get_handler(_Other)->
  {?FAIL,?NOT_SET}.
