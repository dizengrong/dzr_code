%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright (C) www.gmail.com 2011, 
%%% @doc
%%% 组队进程
%%% @end
%%% Created :  6 Jul 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_team_server).

-behaviour(gen_server).

-include("mgeew.hrl").

%% API
-export([start/0, start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

-define(team_id_counter,team_id_counter).
%%%===================================================================
%%% API
%%%===================================================================
start() ->
    supervisor:start_child(
      mgeew_sup, 
      {mod_team_sup,
       {mod_team_sup, start_link, []},
       transient, infinity, supervisor, [mod_team_sup]}),
    supervisor:start_child(
      mgeew_sup, 
      {mod_team_server,
       {mod_team_server, start_link, []},
       transient, brutal_kill, worker, [mod_team_server]}),
    ok.
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).
init([]) ->
    init_team_id_counter(),
    {ok, #state{}}.
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.
handle_cast(_Msg, State) ->
    {noreply, State}.
handle_info(Info, State) ->
    try 
        do_handle_info(Info)
    catch
        T:R ->
            ?ERROR_MSG("module: ~w, line: ~w, Info:~w, type: ~w, reason: ~w,stactraceo: ~w",
                       [?MODULE, ?LINE, Info, T, R, erlang:get_stacktrace()])
    end,
    {noreply, State}.
terminate(_Reason, _State) ->
    ok.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
init_team_id_counter() ->
    erlang:put(?team_id_counter,1).
get_team_id_counter() ->
    case erlang:get(?team_id_counter) of
        undefined ->
            erlang:put(?team_id_counter,2),
            1;
        CurTeamId ->
            erlang:put(?team_id_counter,CurTeamId + 1),
            CurTeamId
    end.

do_handle_info({create_team_procces_by_accept,Msg}) ->
    do_create_team_procces_by_accept(Msg);

do_handle_info({create_team_procces_by_create,Msg}) ->
    do_create_team_procces_by_create(Msg);

do_handle_info({create_team_procces_by_recruitment_create,Msg}) ->
    do_create_team_procces_by_recruitment_create(Msg);

%% 添加外部操作本进程内部执行接口
do_handle_info({func, Fun, Args}) ->
    Ret =(catch apply(Fun,Args)),
    ?ERROR_MSG("~w",[Ret]);
do_handle_info(Info) ->
    ?ERROR_MSG("组队公共服务接口无法处理此消息 Info=~w",[Info]),
    ok.
%% 同意时创建队伍
do_create_team_procces_by_accept({RoleId,Unique,Module,Method,DataRecord,CreateTeamInfo,MemberTeamInfo}) ->
    NewTeamId = get_team_id_counter(),
    TeamProccessName = common_misc:get_team_proccess_name(NewTeamId),
    TeamState={accept,RoleId,Unique,Module,Method,DataRecord,
               NewTeamId,TeamProccessName,CreateTeamInfo,MemberTeamInfo},
    ChildSpec = {NewTeamId, {mod_team,start_link,[TeamState]},
                 temporary, 60000,worker,[mod_team]},
    ?DEBUG("TeamState=~w",[TeamState]),
    case supervisor:start_child({global,atom_to_list(mod_team_sup)}, ChildSpec) of
        {ok, _TeamPid} ->
            %% 加入队伍时创建队伍失败处理
            ok;
        Error ->
            ?ERROR_MSG("创建队伍进程失败 ~w",[Error]),
            %% 加入队伍时创建队伍失败处理
            case MemberTeamInfo of
                undefined ->
                    ignore;
                _ ->
                    common_misc:send_to_rolemap(MemberTeamInfo#p_team_role.role_id, 
                                                {mod_map_team,{admin_update_do_status,{MemberTeamInfo#p_team_role.role_id,?TEAM_DO_STATUS_NORMAL}}}),
                    SendSelf=#m_team_accept_toc{succ = false,reason = ?_LANG_TEAM_CREATE_FAIL},
                    ?DEBUG("~ts,SendSelf=~w",["组队模块Accept",SendSelf]),
                    Line = common_misc:get_role_line_by_id(RoleId),
                    common_misc:unicast(Line, RoleId, Unique, Module, Method, SendSelf)
            end,
            common_misc:send_to_rolemap(CreateTeamInfo#p_team_role.role_id,
                                        {mod_map_team,{admin_update_do_status,{CreateTeamInfo#p_team_role.role_id,?TEAM_DO_STATUS_NORMAL}}}),
            ok
    end.
%% 主动创建队伍
do_create_team_procces_by_create({RoleId,Unique,Module,Method,DataRecord,CreateTeamInfo}) ->
    NewTeamId = get_team_id_counter(),
    TeamProccessName = common_misc:get_team_proccess_name(NewTeamId),
    TeamState={create,RoleId,Unique,Module,Method,DataRecord,
               NewTeamId,TeamProccessName,CreateTeamInfo},
    ChildSpec = {NewTeamId, {mod_team,start_link,[TeamState]},
                 temporary, 60000,worker,[mod_team]},
    ?DEBUG("TeamState=~w",[TeamState]),
    case supervisor:start_child({global,atom_to_list(mod_team_sup)}, ChildSpec) of
        {ok, _TeamPid} ->
            ok;
        Error ->
            ?ERROR_MSG("创建队伍进程失败 ~w",[Error]),
            SendSelf = #m_team_create_toc{
              role_id = DataRecord#m_team_create_tos.role_id,
              succ = false,
              reason = ?_LANG_TEAM_CREATE_ERROR,
              reason_code = 0,
              role_list = [],
              team_id = 0,
              pick_type = 1},
            ?DEBUG("~ts,SendSelf=~w",["组队模块Create",SendSelf]),
            common_misc:unicast({role, RoleId}, Unique, Module, Method, SendSelf),
            common_misc:send_to_rolemap(CreateTeamInfo#p_team_role.role_id,
                                        {mod_map_team,{admin_update_do_status,{CreateTeamInfo#p_team_role.role_id,?TEAM_DO_STATUS_NORMAL}}}),
            ok
    end.

%% 队友招募中的队长主动创建队伍
do_create_team_procces_by_recruitment_create({RoleId,Unique,Module,Method,DataRecord,CreateTeamInfo,MemberRoleIdList}) ->
    NewTeamId = get_team_id_counter(),
    TeamProccessName = common_misc:get_team_proccess_name(NewTeamId),
    TeamState={create,RoleId,Unique,Module,Method,DataRecord,
               NewTeamId,TeamProccessName,CreateTeamInfo},
    ChildSpec = {NewTeamId, {mod_team,start_link,[TeamState]},
                 temporary, 60000,worker,[mod_team]},
    ?DEBUG("TeamState=~w",[TeamState]),
    case supervisor:start_child({global,atom_to_list(mod_team_sup)}, ChildSpec) of
        {ok, _TeamPid} ->
            lists:foreach(
              fun(MemberRoleId) -> 
                      common_misc:send_to_rolemap(MemberRoleId, {mod_map_team, {recruitment_join, {MemberRoleId, NewTeamId}}})   
              end, MemberRoleIdList),
            ok;
        Error ->
            ?ERROR_MSG("创建队伍进程失败 ~w",[Error]),
            SendSelf = #m_team_create_toc{
              role_id = DataRecord#m_team_create_tos.role_id,
              succ = false,
              reason = ?_LANG_TEAM_CREATE_ERROR,
              reason_code = 0,
              role_list = [],
              team_id = 0,
              pick_type = 1},
            ?DEBUG("~ts,SendSelf=~w",["组队模块Create",SendSelf]),
            common_misc:unicast({role, RoleId}, Unique, Module, Method, SendSelf),
            common_misc:send_to_rolemap(CreateTeamInfo#p_team_role.role_id,
                                        {mod_map_team,{admin_update_do_status,{CreateTeamInfo#p_team_role.role_id,?TEAM_DO_STATUS_NORMAL}}}),
            ok
    end.