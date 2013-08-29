%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  1 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeew_system_buff).

-behaviour(gen_server).

-include("mgeew.hrl").

%% API
-export([start/0, start_link/0]).

-export([has_buff/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

-define(system_buff_family, 99001).
-define(system_buff_faction, 99002).
-define(system_buff_world, 99003).

%%%===================================================================
%%% API
%%%===================================================================

has_buff(RoleID) ->
    gen_server:call({global, ?MODULE}, {has_exp_buff, RoleID}).

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE, {?MODULE, start_link, []},
                                                 permanent, 30000, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%%--------------------------------------------------------------------
init([]) ->
    init_activity_monster_exp(false),
    {ok, #state{}}.

%%--------------------------------------------------------------------
handle_call(Request, _From, State) ->
    Reply = do_handle_call(Request),
    {reply, Reply, State}.

%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% 设置宗族多倍经验BUFF
do_handle_info({add_family_exp_buff, FamilyID, Multiple, Time}) ->
    put_family_exp_buff(FamilyID, Multiple, Time),
    erlang:send_after(Time * 1000, self(), {remove_family_exp_buff, FamilyID});
%% 取消宗族多部经验BUFF
do_handle_info({remove_family_exp_buff, FamilyID}) ->
    clear_family_exp_buff(FamilyID);
%% 设置国家多倍经验BUFF
do_handle_info({add_faction_exp_buff, FactionID, Multiple, Time}) ->
    put_faction_exp_buff(FactionID, Multiple, Time),
    erlang:send_after(Time*1000, self(), {remove_faction_exp_buff, FactionID});
%% 取消国家多部经验BUFF
do_handle_info({remove_faction_exp_buff, FactionID}) ->
    clear_faction_exp_buff(FactionID);
%% 世界多倍经验BUFF
do_handle_info({add_world_exp_buff, Multiple, LastTime}) ->
    put_world_exp_buff(Multiple, LastTime);
%% 取消国家多倍经验BUFF
do_handle_info({remove_world_exp_buff}) ->
    remvoe_world_exp_buff();
%% 某地图起来了
do_handle_info({map_init, MapPName}) ->
    do_map_init(MapPName);
%% 角色上线了，通知其有些啥BUFF
do_handle_info({role_online, RoleID, PID, FactionID, FamilyID}) ->
    do_role_online(RoleID, PID, FactionID, FamilyID);

do_handle_info({admin_open_world_exp_buff, StartTime, EndTime}) ->
    do_admin_open_world_exp_buff(StartTime, EndTime);

do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知的消息", Info]).

do_handle_call({has_exp_buff, RoleID}) ->
    do_has_buff(RoleID);

do_handle_call(Request) ->
    ?ERROR_MSG("~ts:~w", ["未知的call", Request]),
    error.

do_has_buff(RoleID) ->
    [#p_role_base{family_id=FamilyID, faction_id=_FactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    get_family_buff(FamilyID).

%%获取当前宗族是否有多倍经验的系统buff
get_family_buff(FamilyID) ->
    case get({family, FamilyID}) of
        undefined ->
            false;
        Multiple ->
            {true, Multiple}
    end.

%% @doc 设置宗族多倍经验buff
put_family_exp_buff(FamilyID, Multiple, Time) ->
    put({family, FamilyID}, Multiple),
    case get(family_multiple_exp_buff) of
        undefined ->
            put(family_multiple_exp_buff, [{FamilyID, Multiple, common_tool:now()+Time}]);
        List ->
            put(family_multiple_exp_buff, [{FamilyID, Multiple, common_tool:now()+Time}|List])
    end,
    common_map:send_to_all_map({mod_team_exp, {add_system_buff, [{family, FamilyID, Multiple}]}}),
    
    FamilyBuff = #p_sys_buff_info{buff_type=?system_buff_family, multiple=Multiple, remain_time=Time},
    DataRecord = #m_role2_system_buff_toc{sys_buff=[FamilyBuff]},
    common_misc:chat_broadcast_to_family(FamilyID, ?ROLE2, ?ROLE2_SYSTEM_BUFF, DataRecord).

%% @doc 取消宗族多倍经验
clear_family_exp_buff(FamilyID) ->
    erase({family, FamilyID}),
    case get(family_multiple_exp_buff) of
        undefined ->
            ignore;
        List ->
            put(family_multiple_exp_buff, lists:keydelete(FamilyID, 1, List))
    end,
    common_map:send_to_all_map({mod_team_exp, {remove_system_buff, family, FamilyID}}).

%% @doc 设置国家多倍经验buff
put_faction_exp_buff(FactionID, Multiple, Time) ->
    put({faction, FactionID}, Multiple),
    case get(faction_multiple_exp_buff) of
        undefined ->
            put(faction_multiple_exp_buff, [{FactionID, Multiple, common_tool:now()+Time}]);
        List ->
            put(faction_multiple_exp_buff, [{FactionID, Multiple, common_tool:now()+Time}|List])
    end,
    common_map:send_to_all_map({mod_team_exp, {add_system_buff, [{faction, FactionID, Multiple}]}}),
    
    FactionBuff = #p_sys_buff_info{buff_type=?system_buff_faction, multiple=Multiple, remain_time=Time},
    DataRecord = #m_role2_system_buff_toc{sys_buff=[FactionBuff]},
    common_misc:chat_broadcast_to_faction(FactionID, ?ROLE2, ?ROLE2_SYSTEM_BUFF, DataRecord). 

%% @doc 取消国家多倍经验
clear_faction_exp_buff(FactionID) ->
    erase({faction, FactionID}),
    case get(faction_multiple_exp_buff) of
        undefined ->
            ignore;
        List ->
            put(faction_multiple_exp_buff, lists:keydelete(FactionID, 1, List))
    end,
    common_map:send_to_all_map({mod_team_exp, {remove_system_buff, faction, FactionID}}).

%% @doc 通知地图有哪些系统buff
do_map_init(MapPName) ->
    case get(family_multiple_exp_buff) of
        undefined ->
            FamilyBuff = [];
        L ->
            FamilyBuff = lists:map(fun({FamilyID, Multiple, _EndTime}) -> {family, FamilyID, Multiple} end, L)
    end,
    
    case get(faction_multiple_exp_buff) of
        undefined ->
            FactionBuff = [];
        L2 ->
            FactionBuff = lists:map(fun({FactionID, Multiple, _EndTime}) -> {faction, FactionID, Multiple} end, L2)
    end,

    case get(world_multiple_exp_buff) of
        undefined ->
            WorldBuff = [];
        {Multiple, _} ->
            WorldBuff = [{world_multi_exp_buff, Multiple}]
    end,

    AllBuff = lists:append([FamilyBuff, FactionBuff, WorldBuff]),
    case global:whereis_name(MapPName) of
        undefined ->
            ignore;
        MPID ->
            MPID ! {mod_team_exp, {add_system_buff, AllBuff}}
    end.

%% @doc 增加世界经验BUFF
put_world_exp_buff(Multiple, LastTime) ->
    %% 进程字典标记，定时取消
    erlang:put(world_multiple_exp_buff, {Multiple, common_tool:now()+LastTime}),
    erlang:send_after(LastTime*1000, self(), {remove_world_exp_buff}),
    %% 发送至所有地图
    common_map:send_to_all_map({mod_team_exp, {add_world_system_buff, Multiple}}),
    %% 广播
    WorldBuff = #p_sys_buff_info{buff_type=?system_buff_world, multiple=Multiple, remain_time=LastTime},
    DataRecord = #m_role2_system_buff_toc{sys_buff=[WorldBuff]},
    common_misc:chat_broadcast_to_world(?ROLE2, ?ROLE2_SYSTEM_BUFF, DataRecord),
    %% 下次活动时间
    init_activity_monster_exp(true).

%% @doc 取消世界经验BUFF
remvoe_world_exp_buff() ->
    erlang:erase(world_multiple_exp_buff),
    common_map:send_to_all_map({mod_team_exp, {remove_world_system_buff}}).

%% @doc 角色上线
do_role_online(_RoleID, PID, FactionID, FamilyID) ->
    case get(family_multiple_exp_buff) of
        undefined ->
            FamilyBuff = [];
        L ->
            FamilyBuff = get_sys_buff(FamilyID, ?system_buff_family, L)
    end,
    
    case get(faction_multiple_exp_buff) of
        undefined ->
            FactionBuff = [];
        L2 ->
            FactionBuff = get_sys_buff(FactionID, ?system_buff_faction, L2)
    end,

    case get(world_multiple_exp_buff) of
        undefined ->
            WorldBuff = [];
        {Multiple, EndTime} ->
            WorldBuff = [#p_sys_buff_info{buff_type=?system_buff_world, multiple=Multiple, remain_time=EndTime-common_tool:now()}]
    end,
    AllBuff = lists:append([FamilyBuff, FactionBuff, WorldBuff]),
    
    case AllBuff of
        [] ->
            ignore;
        _ ->
            DataRecord = #m_role2_system_buff_toc{sys_buff=AllBuff},
            common_misc:unicast2(PID, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_SYSTEM_BUFF, DataRecord)
    end.

get_sys_buff(_CID, _BuffType, []) ->
    [];
get_sys_buff(CID, BuffType, [{ID, Multiple, EndTime}|T]) ->
    case ID =:= CID of
        true ->
            [#p_sys_buff_info{buff_type=BuffType, multiple=Multiple, remain_time=EndTime-common_tool:now()}];
        _ ->
            get_sys_buff(CID, BuffType, T)
    end.

init_activity_monster_exp(IsNext) ->
    case common_config_dyn:find(activity_define, activity_monster_exp) of
        [] ->
            ignore;
        [[ActKey|_]] ->
            case common_config_dyn:find(activity_define, ActKey) of
                [ConfigList] ->
                    init_activity_monster_exp2(ConfigList, IsNext);
                _ ->
                    ignore
            end
    end.

init_activity_monster_exp2([], _IsNext) ->
    ignore;
init_activity_monster_exp2([H|T], IsNext) ->
    {IsOpen, StartTime, EndTime, #r_activity_monster_exp_award{award_exp_times=Multiple,
                                                               award_exp_last_hour=AwardExpLastHour}} = H,
    case IsOpen of
        false ->
            init_activity_monster_exp2(T, IsNext);
        _ ->
            case common_activity:check_activity_time(IsOpen, StartTime, EndTime) of
                {true, RemainTime} ->
                    case IsNext of
                        true ->
                            init_activity_monster_exp2(T, IsNext);
                        _ ->
                            put_world_exp_buff(Multiple, RemainTime)
                    end;
                {false, no_activity} ->
                    init_activity_monster_exp2(T, IsNext);
                {false, RemainTime} ->
                    case RemainTime > 0 of
                        true ->
                            catch erlang:send_after(RemainTime*1000, self(), {add_world_exp_buff, Multiple, AwardExpLastHour*3600});
                        _ ->
                            init_activity_monster_exp2(T, IsNext)
                    end
            end
    end.

do_admin_open_world_exp_buff({StartH, StartM}, {EndH, EndM}) ->
    StartTimeStamp = common_tool:datetime_to_seconds({date(), {StartH, StartM, 0}}),
    EndTimeStamp = common_tool:datetime_to_seconds({date(), {EndH, EndM, 0}}),
    Now = common_tool:now(),
    case (EndTimeStamp > StartTimeStamp) andalso (EndTimeStamp > Now) of
        true ->
            Result = (Now>=StartTimeStamp) andalso (EndTimeStamp>=Now),
            case Result of
                true ->
                    put_world_exp_buff(2, EndTimeStamp-Now);
                _ ->
                    erlang:send_after((StartTimeStamp-Now)*1000, self(), {add_world_exp_buff, 2, EndTimeStamp - StartTimeStamp})
            end;
        _ ->
            ignore
    end.
