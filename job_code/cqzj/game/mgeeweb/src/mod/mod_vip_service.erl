%% Author: markycai
%% Created: 2011-3-26
%% Description: TODO: Add description to mod_vip_service
-module(mod_vip_service).

%%
%% Include files
%%
-include("mgeeweb.hrl").
%%
%% Exported Functions
%%
-export([get/1]).

%%
%% API Functions
%%
get(Req)->
    QueryString = Req:parse_qs(),
    try
        case handle(QueryString) of
        {ok,Rtn}->
            ?DEBUG("RTN~w~n",[Rtn]),
            mgeeweb_tool:return_json(Rtn, Req);
            
        {error,Error}->
            ?ERROR_MSG("~w error,QueryString=~w,Error=~w,stacktrace=~w",[?MODULE,QueryString,Error,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
        end
    catch
        _:Reason->
            ?ERROR_MSG("~w error,Reason=~w,stacktrace=~w",[?MODULE,Reason,elang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end.

handle(QueryString)->
    Fun = proplists:get_value("fun",QueryString),
    Arg0 = proplists:get_value("arg0",QueryString),
    ?DEBUG("fun:~w,arg0:~w~n",[Fun,Arg0]),
    case Fun of
        "getVipInfo"->
            catch getVipInfo(Arg0);
        _->
            {error,"你想干嘛,妹有这个功能啊！！"}
    end.

getVipInfo(RoleID)->
    case length(RoleID) of
        0->
            throw({ok,[]});
        _->
            next
    end,
    RoleID1 = 
    case catch common_tool:to_integer(RoleID) of
        other_value->throw({error,"没有这个玩家"});
        IntRoleID -> IntRoleID
    end,
    case db:dirty_read(?DB_ROLE_VIP_P,RoleID1) of
        [RoleVip] when is_record(RoleVip,r_role_vip) ->
            Res = mgeeweb_tool:transfer_to_json(RoleVip), 
            {ok,Res};
        _->
            ?DEBUG("找不到信息",[]),
            {ok,[]}
    end.

