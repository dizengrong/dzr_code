%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     db接口的测试
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_db_api).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

test_suit()->
    test_delete_sure_ok(),
    test_delete_sure_fail(),
    test_delete_sure_fail(),
    test_delete_obj_sure_fail(),
    ok.
    

get_test_data2()->
    R1 = #r_role_achievement{role_id=1,achieve_group_id = 2,achieve_id=3},
    R2 = #r_role_achievement{role_id=2,achieve_group_id = 3,achieve_id=4},
    {R1,R2}.

test_delete_sure_ok()->
    {R1,R2} = get_test_data(),
    case db:transaction(
           fun() ->
                   db:write(?DB_ROLE_ACHIEVEMENT,R1,write),
                   db:write(?DB_ROLE_ACHIEVEMENT,R2,write),
                   db:delete_sure(?DB_ROLE_ACHIEVEMENT,1,write),
                   db:delete_sure(?DB_ROLE_ACHIEVEMENT,2,write)
           end)
        of
        {atomic, _} ->
            [] = db:dirty_read(?DB_ROLE_ACHIEVEMENT,1),
            [] = db:dirty_read(?DB_ROLE_ACHIEVEMENT,2),
            ok;
        {aborted, Error} ->
            ?INFO("Error=~w",[Error]),
            exit("Error")
    end.

test_delete_sure_fail()->
    {R1,R2} = get_test_data(),
    case db:transaction(
           fun() ->
                   db:write(?DB_ROLE_ACHIEVEMENT,R1,write),
                   db:write(?DB_ROLE_ACHIEVEMENT,R2,write),
                   db:delete_sure(?DB_ROLE_ACHIEVEMENT,3,write),
                   db:delete_sure(?DB_ROLE_ACHIEVEMENT,4,write)
           end)
        of
        {atomic, _} ->
            exit("Error");
        {aborted, key_not_found} ->
            [] = db:dirty_read(?DB_ROLE_ACHIEVEMENT,1),
            [] = db:dirty_read(?DB_ROLE_ACHIEVEMENT,2),
            ok
    end.



test_delete_obj_sure_ok()->
    {R1,R2} = get_test_data2(),
    case db:transaction(
           fun() ->
                   db:write(?DB_ROLE_ACHIEVEMENT,R1,write),
                   db:write(?DB_ROLE_ACHIEVEMENT,R2,write),
                   db:delete_object_sure(?DB_ROLE_ACHIEVEMENT,R1,write),
                   db:delete_object_sure(?DB_ROLE_ACHIEVEMENT,R2,write)
           end)
        of
        {atomic, _} ->
            [] = db:dirty_read(?DB_ROLE_ACHIEVEMENT,1),
            [] = db:dirty_read(?DB_ROLE_ACHIEVEMENT,2),
            ok;
        {aborted, Error} ->
            ?INFO("Error=~w",[Error]),
            exit("Error")
    end.

test_delete_obj_sure_fail()->
    {R1,R2} = get_test_data2(),
    R3 = #r_role_achievement{role_id=11,achieve_group_id = 22,achieve_id=33},
    case db:transaction(
           fun() ->
                   db:write(?DB_ROLE_ACHIEVEMENT,R1,write),
                   db:write(?DB_ROLE_ACHIEVEMENT,R2,write),
                   db:delete_object_sure(?DB_ROLE_ACHIEVEMENT,R3,write),
                   db:delete_object_sure(?DB_ROLE_ACHIEVEMENT,R2,write)
           end)
        of
        {atomic, _} ->
            exit("Error");
        {aborted, object_not_found} ->
            0 = mnesia:table_info(?DB_ROLE_ACHIEVEMENT,size),
            ok
    end.

