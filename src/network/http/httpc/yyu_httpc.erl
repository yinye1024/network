%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 四月 2021 19:45
%%%-------------------------------------------------------------------
-module(yyu_httpc).
-author("yinye").
-include_lib("yyutils/include/yyu_comm.hrl").

%% API functions defined
-export([do_http_get/2, do_https_get/2]).
-export([do_http_delete/1,do_https_delete/1]).
-export([do_http_post_json/2,do_https_post_json/2]).
-export([do_http_put_json/2,do_https_put_json/2]).

-define(HTTP,http).
-define(HTTPS,https).
-define(HTTP_METHOD_GET,get).
-define(HTTP_METHOD_POST,post).
-define(HTTP_METHOD_PUT,put).
-define(HTTP_METHOD_DEL,delete).
-define(TIME_OUT_MS,2000).

%% ===================================================================================
%% API functions implements
%% ===================================================================================
do_http_get(Url,Params) when is_list(Params)->
  ParamsStr = priv_url_encode(Params),
  UrlAndParams = string:join([Url,ParamsStr],"?"),
  Result = httpc:request(?HTTP_METHOD_GET, {UrlAndParams,[]}, priv_get_http_options(), []),
  priv_handle_result(Result).

do_https_get(Url,Params) when is_list(Params)->
  ParamsStr = priv_url_encode(Params),
  UrlAndParams = string:join([Url,ParamsStr],"?"),
  Result = httpc:request(?HTTP_METHOD_GET, {UrlAndParams,[]}, priv_get_https_options(), []),
  priv_handle_result(Result).

do_http_delete(Url) ->
  Result = httpc:request(?HTTP_METHOD_DEL, {Url}, priv_get_http_options(), []),
  priv_handle_result(Result).

do_https_delete(Url)->
  Result = httpc:request(?HTTP_METHOD_DEL, {Url}, priv_get_https_options(), []),
  priv_handle_result(Result).


do_http_post_json(Url, PostMap) when is_map(PostMap)->
  PostJson = yyu_json:map_to_json(PostMap),
  BinJson = yyu_misc:to_binary(PostJson),
  Result = httpc:request(?HTTP_METHOD_POST, {Url,[], "application/json;charset=UTF-8",BinJson}, priv_get_http_options(), []),
  priv_handle_result(Result).
do_https_post_json(Url,PostMap) when is_map(PostMap)->
  PostJson = yyu_json:map_to_json(PostMap),
  BinJson = yyu_misc:to_binary(PostJson),
  Result = httpc:request(?HTTP_METHOD_POST, {Url,[], "application/json;charset=UTF-8",BinJson}, priv_get_https_options(), []),
  priv_handle_result(Result).

do_http_put_json(Url, PostMap) when is_map(PostMap)->
  PostJson = yyu_json:map_to_json(PostMap),
  BinJson = yyu_misc:to_binary(PostJson),
  Result = httpc:request(?HTTP_METHOD_PUT, {Url,[], "application/json;charset=UTF-8",BinJson}, priv_get_http_options(), []),
  priv_handle_result(Result).
do_https_put_json(Url,PostMap) when is_map(PostMap)->
  PostJson = yyu_json:map_to_json(PostMap),
  BinJson = yyu_misc:to_binary(PostJson),
  Result = httpc:request(?HTTP_METHOD_PUT, {Url,[], "application/json;charset=UTF-8",BinJson}, priv_get_https_options(), []),
  priv_handle_result(Result).




priv_get_http_options()->
  [{timeout,?TIME_OUT_MS}].
priv_get_https_options()->
  [{ssl,[{verify,0}]}, {timeout,?TIME_OUT_MS}].

priv_handle_result(Result)->
  case Result of
    {?OK,{{"HTTP/1.1",200,"OK"},_Header, Body} } -> {?OK,Body};
    {?OK,{{"HTTP/1.1",_,Msg},_Header, _Body} } -> {?FAIL,Msg};
    {error,Msg} -> yyu_error:throw_error(http_error,Msg)
  end.


priv_url_encode(Params) when is_list(Params) ->
  priv_url_encode(Params,"").
priv_url_encode([],Acc) ->
  Acc;
priv_url_encode([{Key,Value}|R],"") ->
  priv_url_encode(R, edoc_lib:escape_uri(Key) ++ "=" ++ edoc_lib:escape_uri(Value));
priv_url_encode([{Key,Value}|R],Acc) ->
  priv_url_encode(R, Acc ++ "&" ++ edoc_lib:escape_uri(Key) ++ "=" ++ edoc_lib:escape_uri(Value)).
