%%%-------------------------------------------------------------------
%%% @author sunbirdjob
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 十月 2021 16:04
%%%-------------------------------------------------------------------
-module(yynw_http_utils).
-author("sunbirdjob").

%% SRC_ROOT_FRW need to set by system env
-include_lib("yyutils/include/yyu_comm.hrl").

%% API functions defined
-export([get_method/1,get_client_ip/1]).
-export([get_raw_path/1,get_path/1]).
-export([get_url_params/1,get_url_int/2,get_url_text/2,get_url_map/2,get_url_list/2]).
-export([get_post_params/1, get_post_json/2]).
-export([get_cookies/1,get_cookie_value/2]).
-export([get_headers/1,get_header_value/2,get_header_int/2]).
-export([resp_ok/2, resp_ok_with_cookie/3,resp_file/3]).
-export([redirect_to/2]).


%% ===================================================================================
%% API functions implements
%% ===================================================================================/
%% Req example: {mochiweb_request,[#Port<0.56971>,[{recbuf,8192}],'GET',"/test/544?uid=101&ticket=tt101",{1,1},{4,{"content-length",{'Content-Length',"0"},{"connection",{'Connection',"keep-alive"},nil,nil},
%%    {"te",{"Te",[]},{"host",{'Host',"127.0.0.1:8090"},nil,nil},nil}}}]},

%% return ‘OPTIONS’ | ‘GET’ | ‘HEAD’ | ‘POST’ | ‘PUT’ | ‘DELETE’ | ‘TRACE’
get_method(Req) ->
  mochiweb_request:get(method,Req).

get_client_ip(Req)->
  mochiweb_request:get(peer,Req).

%% 获取raw_path.比如 http://www.XXX.cn/session/login?username=test#p,
%% 那/session/login?username=test#p就是这个raw_path.
get_raw_path(Req) ->
  mochiweb_request:get(raw_path,Req).


%% 获取path.比如 http://www.XXX.cn/session/login?username=test#p,
%% 那/session/login就是这个path.
get_path(Req) ->
  mochiweb_request:get(path,Req).

%% 获取get参数.比如 http://www.nextim.cn/session/login?username=test#p,
%% 则返回[{“username”,”test”}].
%%return [{strng(), string()}].
get_url_params(Req) ->
  mochiweb_request:parse_qs(Req).

get_url_text(Key,Req)->
  case priv_get_url_params(Key,Req) of
    ?NOT_SET -> ?NOT_SET;
    ReqData->
      erlang:iolist_to_binary(ReqData)
  end.

get_url_int(Key,Req)->
  case priv_get_url_params(Key,Req) of
    ?NOT_SET -> ?NOT_SET;
    ReqData->
      yyu_misc:to_integer(ReqData)
  end.

get_url_map(Key,Req)->
  case priv_get_url_params(Key,Req) of
    ?NOT_SET -> ?NOT_SET;
    ReqData->
      yyu_json:json_to_map(ReqData)
  end.

get_url_list(Key,Req)->
  case priv_get_url_params(Key,Req) of
    ?NOT_SET -> ?NOT_SET;
    ReqData->
      yyu_json:json_to_map(ReqData)
  end.

priv_get_url_params(Key,Req) ->
  ReqData = mochiweb_request:parse_qs(Req),
  ?LOG_INFO({reqData,ReqData}),
  case proplists:get_value(Key,ReqData) of
    ?UNDEFINED ->?NOT_SET;
    KeyData ->
      http_uri:decode(KeyData)
  end.


%%确保post数据类型为: application/x-www-form-urlencoded, 否则不要调用(其内部会调用mochiweb_request:recv_body),
%%return [{strng(), string()}...].
get_post_params(Req) ->
  mochiweb_request:parse_post(Req).

%% 客户端必须 encodeURIComponent(KeyData)
get_post_json(Key,Req) ->
  PostData = get_post_params(Req),
  JsonStr =
  case proplists:get_value(Key,PostData) of
    ?UNDEFINED ->?NOT_SET;
    KeyData ->
      http_uri:decode(KeyData)
  end,
  JsonStr.

%% return [{string, string}].
get_headers(Req)->
  HeaderDict = mochiweb_request:get(headers,Req),
  KvList =   mochiweb_headers:to_list(HeaderDict),
  KvList.


get_header_int(HeaderKey,Req)->
  case mochiweb_request:get_header_value(HeaderKey,Req) of
    ?UNDEFINED ->?NOT_SET;
    Value ->yyu_misc:to_integer(Value)
  end.

%% 获取某个header,比如Key为”User-Agent”时，返回”Mozila…….”
%% return  undefined | string
get_header_value(HeaderKey,Req)->
  case mochiweb_request:get_header_value(HeaderKey,Req) of
    ?UNDEFINED ->?NOT_SET;
    Value ->Value
  end.

%% return [{string, string}].
get_cookies(Req)->
  mochiweb_request:parse_cookie(Req).

%% return string
get_cookie_value(CookieKey,Req)->
  case mochiweb_request:get_cookie_value(CookieKey,Req) of
    ?UNDEFINED ->?NOT_SET;
    Value ->Value
  end.


%% CookieKvList = [{Key,Value}...]
resp_ok_with_cookie(CookieKvList,Resp,Req) ->
  JsonResp = yyu_json:map_to_json(Resp),
  HeadList = priv_get_cross_site_head_list(),
  NewHeaderList = priv_add_cookies(CookieKvList,HeadList),
  RespHeader = mochiweb_headers:make(NewHeaderList),
  mochiweb_request:respond({200, RespHeader, JsonResp},Req).

priv_add_cookies([{Key,Value}|Less],AccHeaderList) ->
%%  mochiweb_cookies:cookie(Key, Value, [{path, "/"}]),
  Cookie = mochiweb_cookies:cookie(Key, Value),
  priv_add_cookies(Less,[Cookie|AccHeaderList]);
priv_add_cookies([],AccHeaderList) ->
  AccHeaderList.

resp_ok(Resp,Req)->
  JsonResp = yyu_json:map_to_json(Resp),
  HeadList = priv_get_cross_site_head_list(),
  RespHeader = mochiweb_headers:make(HeadList),
  RespHeader,
  mochiweb_request:respond({200, RespHeader, JsonResp},Req).

priv_get_cross_site_head_list()->
  RespHeader = mochiweb_headers:make([
    {"Content-Type", "application/json;charset=utf-8"},
    {"Access-Control-Allow-Credentials", "true"},
    {"Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE"},
    {"Access-Control-Allow-Origin", "*"},
    {"Access-Control-Allow-Headers", "*"}]),
  RespHeader.

resp_file(Path,DocRoot,Req)->
    "/"++FilePath = Path,
  mochiweb_request:serve_file(FilePath,DocRoot,Req),
  ?OK.
%% 重定向到
redirect_to(NewPath,Req)->
  mochiweb_request:respond({302, [{"Location", NewPath}], ""},Req),
  ?OK.
