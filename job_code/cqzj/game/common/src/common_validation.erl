%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 11 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_validation).

%% API
-export([
         valid_username/1
        ]).


valid_username(UserName) ->    
    case re:run(unicode:characters_to_binary(UserName), "^[\\x{4e00}-\\x{9fa5}a-zA-Z0-9_]+\$", [unicode, notempty]) of
        nomatch ->
            false;
        _ ->
            true
    end.


-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

test() ->
    ok.

valid_username_test() ->
    ?assertEqual( true, valid_username(<<"99001">>)),
    ?assertEqual( true, valid_username(<<"Liangliang">>)),
    ?assertEqual( true, valid_username(<<"庆亮">>)),    
    ?assertEqual( false, valid_username(<<"庆亮+*&^&">>)),    
    ?assertEqual( true, valid_username(<<"Liangliang917363">>)),
    ?assertEqual( false, valid_username(<<"[]+*&^&">>)),
    ok.
    
-endif.


            
    
    
