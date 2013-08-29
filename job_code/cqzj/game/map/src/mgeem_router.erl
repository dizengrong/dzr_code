%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-16
%%% -------------------------------------------------------------------
-module(mgeem_router).

-behaviour(gen_server).

-include("mgeem.hrl").

%% --------------------------------------------------------------------
-export([
         start/0, 
         start_link/0,
         create_map_if_not_exist/1,
         do_start_map/2,
         kick_role/3,
         update_role_map_process_name/4,
         do_create_map_distribution2/5
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).
%% --------------------------------------------------------------------
start() ->
    supervisor:start_child(mgeem_sup, 
                           {?MODULE,
                            {?MODULE, start_link, []},
                            transient, 30000, worker, [?MODULE]}).


start_link() ->
    gen_server:start_link(?MODULE, [], []).
%% --------------------------------------------------------------------


%%用于分布式启动
do_start_map(MAPID, MAPProcessName) ->
    case supervisor:start_child(mgeem_map_sup, [{MAPProcessName, MAPID}]) of
        {ok, MapPID} ->
            {ok, MapPID};
        {error, {already_started, MapPID}} -> 
            {ok, MapPID};
        {error, Reason} ->
            ?ERROR_MSG("~ts ~w ~ts: ~w", ["创建地图", MAPID, "失败", Reason]),
            {error, Reason}
    end.

%% --------------------------------------------------------------------
init([]) ->
    case global:whereis_name(?MODULE) of
        undefined ->
            global:register_name(?MODULE, self()),
            %%用于保存玩家的一些映射信息，方面查找
            ets:new(?ETS_ROLEID_PID_MAP, [protected, set, named_table]),
            check_mission_data(),
            {ok, #state{}};
        %%该进程已经启动了，这个进程在分布式的环境中只能有一个
        _ ->
            {stop, alread_start}
    end.

check_mission_data()->
    case common_config_dyn:find(etc,check_mission_data) of
        [false]->
            ignore;
        _ ->
            mod_mission_check:check()
    end.
%% --------------------------------------------------------------------


%%请求创建家族地图：修改成异步方式
handle_call({family_map_init, FamilyID, BonfireBurnTime}, _, State) ->
    Reply = mod_map_copy:create_family_map_copy(FamilyID, BonfireBurnTime),
    {reply, Reply, State};


handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~w from ~w", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.

%%login进程注册成功发送过来的信息
handle_cast({register,RoleID,_Role},State) ->
    ?DEBUG("~ts:~w~n",["注册新玩家",RoleID]),
    %%hook_login_register:hook( RoleID ),
    {noreply, State};
handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~w", [Msg]),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.


terminate(Reason, State) ->
    ?ERROR_MSG("~w terminate : ~w, ~w", [self(), Reason, State]),
    %% TODO dump all the content of ets to mnesia 
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------

                                    
%%处理玩家不在线上的消息
do_handle_info({role_offline_msg, RoleID, Msg}) ->
    do_handle_role_offline_msg(RoleID, Msg);

%% 处理异步创建地图
do_handle_info({create_map_distribution, MapID, MapProcessName, Module, FromPID, Key}) ->
    do_create_map_distribution(MapID, MapProcessName, Module, FromPID, Key);

%%活动事件消息
do_handle_info({event_timer_info, {stop_personybc_faction, EventStateKey}, EventTimeData}) ->
    mod_ybc_person:stop_personybc_faction(EventStateKey, EventTimeData),
    ok;

%%管理后台调用
do_handle_info({admin_msg, Data}) ->
    mod_admin_api:do(Data);
%%异步调用的返回消息
do_handle_info({_PID,{promise_reply,ok}}) ->
    ok;
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知消息", Info]).

kick_role(RoleID, Line, Reason) ->
    Name = lists:concat(["unicast_server_", Line]),
    catch global:send(Name, {kick_role, RoleID, Reason}).

%%判断地图进程是否已经创建，没有则创建
create_map_if_not_exist(MAPID) ->
    MAPProcessName = common_map:get_common_map_name(MAPID),
    case global:whereis_name(MAPProcessName) of
        undefined ->
            ?DEBUG("~ts: ~w", ["尝试创建启动进程", MAPProcessName]),
			mgeem_router:do_start_map(MAPID, MAPProcessName),
            ok;
        _ ->
            ok
    end.

do_create_map_distribution(MapID, MapProcessName, Module, FromPID, Key) ->
    case global:whereis_name(MapProcessName) of
        undefined ->
            do_random_start(MapID, MapProcessName, Module, FromPID, Key),
            ok;
        _ ->
            ok
    end.

do_random_start(MapID, MapProcessName, Module, FromPID, Key) ->
	erlang:spawn(fun() ->
		mgeem_router:do_create_map_distribution2(MapID, MapProcessName, Module, FromPID, Key)
	end).

do_create_map_distribution2(MapID, MapProcessName, Module, FromPID, Key) ->
    case supervisor:start_child(mgeem_map_sup, [{MapProcessName, MapID}]) of
        {ok, _MAPNewPid} ->
            FromPID ! {mod,Module, {create_map_succ, Key}},
            ok;
        {error, {already_started, _}} -> 
            FromPID ! {mod,Module, {create_map_succ, Key}},
            ok;
        {error, aleady_registered_map_name} -> 
            FromPID ! {mod,Module, {create_map_succ, Key}},
            ok;
        {error, Reason} ->
            ?ERROR_MSG("~ts ~w ~ts: ~w", ["创建地图", MapID, "失败", Reason]),
            {error, Reason}
    end.

%% --------------------------------------------------------------------

update_role_map_process_name(RoleID, ProcessName, MapID, Pos) ->
    case erlang:is_record(Pos, p_pos) of
        true ->
            erlang:spawn(
              fun() ->
                      case db:transaction(
                             fun() -> 
                                     [#p_role_pos{map_process_name=OldMapName} = RolePos] = db:read(?DB_ROLE_POS, RoleID, write),
                                     db:write(?DB_ROLE_POS, RolePos#p_role_pos{map_process_name=ProcessName, old_map_process_name=OldMapName,
                                                                               role_id=RoleID, map_id=MapID, pos=Pos}, write)
                             end) of
                          {atomic, ok} ->
                              ok;
                          {aborted, Error} ->
                              ?ERROR_MSG("update_role_map_process_name, error: ~w", [Error]),
                              error
                      end
              end);
        false ->
            ?ERROR_MSG("~ts:~p ~p", ["抓到错误，pos类型传递错误", erlang:get_stacktrace(), ProcessName])
    end.

do_handle_role_offline_msg(RoleID, Msg) ->
    ?ERROR_MSG("~ts:~w ~w", ["未知的玩家离线处理消息", RoleID, Msg]).
