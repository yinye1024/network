%%%-------------------------------------------------------------------
%%% @author yinye
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 十月 2021 16:35
%%%-------------------------------------------------------------------
-module(yynw_form_utils).
-author("yinye").

-include_lib("yyutils/include/yyu_comm.hrl").

%% API functions defined
-export([get_num/2, get_binary/2,get_string/2]).


%% ===================================================================================
%% API functions implements
%% ===================================================================================
%%  Str = "中国",
%%  io:format("Unicode list is: ~p~n", [Str]),
%%  Bin = unicode:characters_to_binary(Str),
%%  io:format("Unicode binary is: ~p~n", [Bin]),
%%  Str1 = unicode:characters_to_list(Bin, utf8),
%%  io:format("utf8 binary to list is: ~p~n", [Str1]).


get_num(Key,FormMap) when (is_atom(Key) and is_map(FormMap))->
  case get_string(Key,FormMap) of
    ?NOT_SET ->?NOT_SET;
    Value ->
      zmu_misc:string_to_num(Value)
  end.

get_binary(Key,FormMap) when (is_atom(Key) and is_map(FormMap))->
  case zmu_map:get_value(Key,FormMap) of
    ?NOT_SET ->?NOT_SET;
    Value when is_binary(Value)->
      Value
  end.

get_string(Key,FormMap) when (is_atom(Key) and is_map(FormMap))->
  case zmu_map:get_value(Key,FormMap) of
    ?NOT_SET ->?NOT_SET;
    Value when is_binary(Value) ->
      unicode:characters_to_list(Value, utf8)
  end.

	