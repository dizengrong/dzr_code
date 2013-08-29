%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-4-16
%%% -------------------------------------------------------------------
-module(mgeew_skill_server).

-behaviour(gen_server).
-include("mgeew.hrl").

-export([
         start/0,
         start_link/0,
         get_skill_info/1,
         get_skill_level_info/2,
         get_buff_func_by_id/1,
         get_buf_detail/1,
         get_buff_func_by_type/1
        ]).



-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


start() ->
    {ok, _} = supervisor:start_child(
                mgeew_sup, 
                {?MODULE, {?MODULE, start_link, []}, transient, 10000, worker, [?MODULE]}).


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


get_buf_detail(BuffID) ->
    case common_config_dyn:find(buffs, BuffID) of
        [Detail] ->
            {ok, Detail};
        _ ->
            ?ERROR_MSG("buf not found: ~w", [BuffID]),
            {error, not_found}
    end.


get_skill_info({SkillID,_}) ->
    get_skill_info(SkillID);
get_skill_info(SkillID) when is_integer(SkillID) ->
    case common_config_dyn:find(skill, SkillID) of
        [SkillBaseInfo] ->
            {ok, SkillBaseInfo};
        _ ->
            {error, not_found}
    end.


%%@doc 获得一个技能的某个等级的详细信息
get_skill_level_info({SkillID,_}, Level) ->
    get_skill_level_info(SkillID, Level);
get_skill_level_info(SkillID, Level) when is_integer(SkillID) ->
    case common_config_dyn:find(skill_level,SkillID) of
        []->
            {error, not_found};
        [SkillLevelList]->
            case lists:keyfind(Level,3,SkillLevelList) of
                false->
                    {error, not_found};
                SkillLevelInfo->
                    E = get_skill_level_effects(SkillLevelInfo#p_skill_level.effects),
                    B = get_skill_level_buffs(SkillLevelInfo#p_skill_level.buffs),
                    {ok, SkillLevelInfo#p_skill_level{effects=E, buffs=B}}
            end
    end.

get_skill_level_effects(EffectIDs) ->
    lists:foldl(
      fun(EffectID, Acc) ->
              [ EffectDetail ] = common_config_dyn:find(effects, EffectID),
              [EffectDetail | Acc]
      end, [], EffectIDs).


get_skill_level_buffs(BuffIDs) ->
    lists:foldl(
      fun(BuffID, Acc) ->
              [BuffDetail] = common_config_dyn:find(buffs, BuffID),
              [BuffDetail | Acc]
      end, [], BuffIDs).


%%根据buff的id获得buff回调函数
get_buff_func_by_id(BufID) ->
    case common_config_dyn:find(buffs, BufID) of
        [BufDetail] ->
            case common_config_dyn:find(buff_type, BufDetail#p_buf.buff_type) of
                [Func] ->
                    {ok, Func};
                _ ->
                    ?ERROR_MSG("buf type not found ~w", [BufDetail#p_buf.buff_type]),
                    {error, not_found}
            end;
        _ ->
            ?ERROR_MSG("buf id not found ~w", [BufID]),
            {error, not_found}
    end.


%%根据buff的type获得buff的回调函数名称
get_buff_func_by_type(Type) ->
    case common_config_dyn:find(buff_type, Type) of
        [Func] ->
            {ok, Func};
        _ ->
            {error, not_found}
    end.


init([]) ->
    loadSkillConfig(),
    {ok, none}.


handle_call(Request, From, State) ->
    ?DEBUG("~w handle_cal from ~w : ~w", [?MODULE, From, Request]),
    Reply = ok,
    {reply, Reply, State}.


handle_cast(Msg, State) ->
    ?DEBUG("unexpected msg ~w ~w", [Msg, State]),
    {noreply, State}.


handle_info(Info, State) ->
    ?DEBUG("unknow info ~w", [Info]),
    {noreply, State}.


terminate(Reason, State) ->
    ?INFO_MSG(" terminate : ~w , reason: ~w", [Reason, State]),
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

loadSkillConfig() ->
    %%读取技能列表

    %%读取技能等级信息
    
    %%读取effect类型列表
    
    %%读取effect列表

    %%读取buff列表

    %%读取buff类型列表
    ok.
