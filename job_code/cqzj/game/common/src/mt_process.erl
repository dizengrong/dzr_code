%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     运维瑞士军刀，for process
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mt_process).

%%
%% Include files
%%
-include("common.hrl").

-compile(export_all).
-define( DEBUG(F,D),io:format(F, D) ).

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%
info(PID) ->
    info(PID,all).


%% 例如: mt_process:func( mgeew_online,fun()-> mod_big_jingjie:hook_jingjie_mission_commit(4, 210) end )
func(PID,Fun) when erlang:is_pid(PID)->
    PID ! {func, Fun, []};
func(RegName,Fun) ->
    PID = pid(RegName),
    PID ! {func, Fun, []}.


%% @doc process_info
info(PID,Key) when erlang:is_pid(PID)->
    StrPID = pid_to_list(PID),
    case string:substr(StrPID, 1,3) of
        [60,48,46]->
            case Key of
                all->
                    erlang:process_info( PID );
                _ ->
                    erlang:process_info( PID,Key )
            end;
        _ ->
            io:format("~s is global pid",[PID])
    end;
info(RegName,Key) when is_list(RegName) andalso length(RegName)>3 ->
    case string:substr(RegName, 1,3) of
        [60,48,46]->
            info( list_to_pid(RegName),Key );
        _ ->
            info_name(RegName,Key)
    end;
info(RegName,Key) when is_list(RegName)  ->
    info_name(RegName,Key);
info(RegName,Key) when is_atom(RegName)->
    info_name(RegName,Key).

info_name(RegName,Key)->
    case pid(RegName) of
        undefined->
            undefined;
        PID ->
            info(PID,Key)
    end.

%%发送调试方法信息给进程
debug(RegName,F,A)->
    Msg = {debug,{F,A}},
    erlang:send( mt_process:pid(RegName), Msg).
   
%%杀死某进程
kill(RegName)->
    kill(RegName,kill).

%%杀死某进程
kill(RegName,Reason)->
    exit( mt_process:pid(RegName),Reason). 

%% @doc get node name
node(RegName)->
    erlang:node( pid(RegName) ).

%% @doc send message
send(RegName,Msg)->
    erlang:send( pid(RegName) , Msg).

%% @doc get pid
pid(RegName)->
    case global:whereis_name(RegName) of
        undefined->
            case erlang:whereis(RegName) of
                undefined->
                    undefined;
                LPID -> 
                    LPID
            end;    
        GPID->
            GPID
    end.

%% @doc messages
m(ProcessName)->
    info(ProcessName,messages).


db(RamTab) when is_atom(RamTab)->
    ignore.


%% @doc length of messages
mlength(ProcessName)->
    info(ProcessName,message_queue_len).


%% @doc map's dictionary
map_d(MapID)->
    MapName = common_misc:get_map_name(MapID),
    d(MapName).

map_d(MapID,Key)->
    MapName = common_misc:get_map_name(MapID),
    d(MapName,Key).

%% @doc role mission's dictionary
mission_d(RoleID)->
    role_d(RoleID,?MISSION_DATA_DICT_KEY(RoleID)).

%% @doc role bag's dictionary
bag_d(RoleID,BagID)->
    role_d(RoleID,{role_bag,RoleID,BagID}).

get_roleid(RoleName) when is_list(RoleName)->
    common_misc:get_roleid_by_accountname(RoleName).

%% @doc role map's dictionary
role_d(RoleName) when is_list(RoleName)->
    role_d( get_roleid(RoleName) );
role_d(RoleID)->
    {ok, MapName} = common_misc:get_role_map_process_name(RoleID) ,
    d(MapName).

%% @doc
role_d(RoleName,Key) when is_list(RoleName)->
    role_d( get_roleid(RoleName),Key );
role_d(RoleID,Key)->
    {ok, MapName} = common_misc:get_role_map_process_name(RoleID) ,
    d(MapName,Key).

%% @doc dictionary
d(ProcessName)->
    info(ProcessName,dictionary).


%% @doc length of dictionary
dlength(ProcessName)->
    case d(ProcessName) of
        false-> 
            false;
        {_K,Val}->
            length( Val )
    end.

%% @doc key in dictionary
d(ProcessName,Key)->
    DictVal = erlang:element(2, d(ProcessName) ) ,
    case lists:keyfind(Key, 1, DictVal) of
        false->
            false;
        Val->
            Val
    end.


%% @doc length of key in dictionary
dlength(ProcessName,Key)->
    case d(ProcessName,Key) of
        false->
            false;
        {_K,Val} ->
            length(Val)
    end.



