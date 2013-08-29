%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% Created : 10 Aug 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_map_copy).

-include("mgeem.hrl").

%% API
-export([
         create_family_map_copy/1,
         create_family_map_copy/2,
         %% 创建师门同心副本地图进程
         create_educate_map_copy/2,
         create_copy/2,
         async_create_copy/4
        ]).

%%创建地图副本
create_family_map_copy(FamilyID) ->
    create_family_map_copy(FamilyID, undefined).

create_family_map_copy(FamilyID, _BonfireBurnTime) ->
	MAPProcessName = common_map:get_family_map_name(FamilyID),
	case global:whereis_name(MAPProcessName) of
		undefined ->
			MAPID = 10300,
			{ok, Pid} = mgeem_router:do_start_map(MAPID, MAPProcessName),
%% 			case (BonfireBurnTime=:=undefined) of
%% 				true->
%% 					ignore;
%% 				_ ->
%% 					erlang:send(Pid,{mod_map_bonfire,{bonfire_start_time,FamilyID,BonfireBurnTime}})
%% 			end,
			{ok, Pid};
		PID ->
			{ok, PID}
	end.

%% 创建师门同心副本地图进程                               
create_educate_map_copy(MapID,MapProcessName) ->
    create_copy(MapID, MapProcessName).

%% @doc 同步(阻塞)方式创建副本
create_copy(MapID, MapProcessName) ->
    case global:whereis_name(MapProcessName) of
        undefined ->
            mgeem_router:do_start_map(MapID, MapProcessName);  
        _PID ->
            ok
    end.
%% @doc 异步方式创建副本
%% 模块必须接收{create_map_succ,Key}方法
async_create_copy(MapID, MapProcessName, Module, Key) ->
    global:send(mgeem_router, {create_map_distribution, MapID, MapProcessName, Module, erlang:self(), Key}).

