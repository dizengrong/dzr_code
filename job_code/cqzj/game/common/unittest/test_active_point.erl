%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_active_point).

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

%%@doc 检查活跃度太低的玩家的数量
check()->
    MatchHead = #p_role_attr{role_id='$1', _='_',active_points='$2'},
    Guard = [{'<','$2',80}],
    AllRoleIDList = db:dirty_select(db_role_attr, [{MatchHead, Guard, ['$1']}]),
    {OnlineList,OffLineList} = lists:foldl(fun(E,{OnlineAcc,OffLineAcc})-> 
                                                   case common_misc:is_role_online(E) of
                                                       true->
                                                           {[E|OnlineAcc],OffLineAcc};
                                                       _ ->
                                                           {OnlineAcc,[E|OffLineAcc]}
                                                   end
                                           end, {[],[]}, AllRoleIDList),
    ?INFO("AllRoleIDList,count=~p~n",[length(AllRoleIDList)]),
    ?INFO("OnlineList,count=~p~n",[length(OnlineList)]),
    ?INFO("OffLineList,count=~p~n",[length(OffLineList)]).

set_active_point()->
    MatchHead = #p_role_attr{role_id='$1', _='_',active_points='$2'},
    Guard = [{'<','$2',80}],
    AllRoleIDList = db:dirty_select(db_role_attr, [{MatchHead, Guard, ['$1']}]),
    {_OnlineList,OffLineList} = lists:foldl(fun(E,{OnlineAcc,OffLineAcc})-> 
                                                   case common_misc:is_role_online(E) of
                                                       true->
                                                           {[E|OnlineAcc],OffLineAcc};
                                                       _ ->
                                                           {OnlineAcc,[E|OffLineAcc]}
                                                   end
                                           end, {[],[]}, AllRoleIDList),
    
    
    %%离线的处理
    lists:foreach(
      fun(RoleID) -> 
              [R] = db:dirty_read(db_role_attr,RoleID),
              db:dirty_write(db_role_attr, R#p_role_attr{active_points=80})
      end, OffLineList),
    ok.


