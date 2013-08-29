%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  4 Aug 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeew_faction).

-behaviour(gen_server).

%% API
-export([start/0, start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

-include("mgeew.hrl").

%%%===================================================================
%%% API
%%%===================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE, {?MODULE, start_link, []},
                                                 permanent, 30000, worker, [?MODULE]}).

%%--------------------------------------------------------------------
%% @doc
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    erlang:send_after(30 * 1000, erlang:self(), init_data),    
    {ok, #state{}}.

%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

do_handle_info(init_data) ->
    init_data(),
    ok;

do_handle_info({get_faction_strength,Pid}) ->
	do_get_faction_strength(Pid),
    ok;

do_handle_info({Unique, Module, Method, DataRecord, RoleID, PID, _Line}) ->
	    case Method of
        ?FACTION_CHANGE ->
            do_change_faction(Unique, Module, Method, DataRecord, RoleID, PID);
        ?FACTION_STRENGTH_STATUS ->
            do_status(Unique, Module, Method, RoleID, PID);
		?FACTION_SALARY ->
            do_salary(Unique, Module, Method, RoleID, PID);
        _ ->
            ?ERROR_MSG("~ts:~w", ["未知的方法", Method])
    end,
    ok;

%% 每天凌晨3点30分重新计算国家势力分布
do_handle_info(recalc_faction_strength) ->
    Time = common_time:diff_next_daytime(3, 30),
    erlang:send_after(Time * 1000, erlang:self(), recalc_faction_strength),
    do_calc_faction_strength(),
	send_faction_strength_to_all_map().

%% 查询国家强弱状态
do_status(Unique, Module, Method, _RoleID, PID) ->
	Result=case erlang:get(faction_strength) of
			   undefined ->
				   [];
			   List ->
				   List
		   end,
    Result2 = lists:foldl(
                fun({FactionID, Strength}, Acc) ->
                        [#p_faction_strength{faction_id=FactionID, strength=Strength} | Acc]
                end, [], Result),
    R = #m_faction_strength_status_toc{lists=Result2, open_days= common_config:get_opened_days() > 7 },
    common_misc:unicast2(PID, Unique, Module, Method, R).
    

%% 玩家移民，这里验证是否符合强弱国家规则
do_change_faction(Unique, Module, Method, DataRecord, RoleID, PID) ->
    #m_faction_change_tos{faction_id=FactionID} = DataRecord,  
    case common_config:get_opened_days() > 7 of
        true ->
            case catch do_change_faction_check(RoleID, FactionID) of
                {ok, CurFactionID} ->
                    FactionStrengths = erlang:get(faction_strength),
                    {FactionID, FactionStength} = lists:keyfind(FactionID, 1, FactionStrengths),
                    {CurFactionID, CurFactionStrength} = lists:keyfind(CurFactionID, 1, FactionStrengths),
                    case FactionStength > CurFactionStrength of
                        true ->
                            ToStrength = true;
                        false ->
                            ToStrength = false
                    end,
                    mgeer_role:absend(RoleID, {mod_role2, {Unique, Module, Method, FactionID, ToStrength, RoleID, PID}}),
                    ok;
                {error, Reason} ->
                    do_change_faction_error(Unique, Module, Method, Reason, PID)
            end;
        false ->
            Reason = lists:flatten(io_lib:format(?_LANG_FACTION_CHANGE_TIME_NOT_ALLOW, [common_config:get_opened_days()])),
            do_change_faction_error(Unique, Module, Method, Reason, PID)
    end.

do_change_faction_error(Unique, Module, Method, Reason, PID) ->
    R = #m_faction_change_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).

do_change_faction_check(RoleID, FactionID) ->
    [#p_role_base{faction_id=CurFactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    case CurFactionID =:= FactionID of
        true ->
            erlang:throw({error, ?_LANG_FACTION_CANNT_CHANGE_SAME_FACTION});
        false ->
            ok
    end,
    case lists:member(FactionID, ?FACTIONID_LIST) of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FACTION_CHANGE_FACTION_PARAM_ERROR})
    end,
    {ok, CurFactionID}.


%% 领取官职工资
-define(faction_salary_info,faction_salary_info).
do_salary(Unique, Module, Method, RoleID, PID) ->
	case db:dirty_read(?DB_ROLE_ATTR, RoleID) of
		[] ->
			do_salary_error(Unique, Module, Method, ?_LANG_SYSTEM_ERROR, PID);
		[#p_role_attr{office_id=OffIceID}] ->
			case OffIceID =:= undefined orelse OffIceID =:= 0 of
				true  ->
					do_salary_error(Unique, Module, Method, ?_LANG_ONLY_OFFICE_CAN_GET_SALARY, PID);
				false ->
					{Hour,_,_} = erlang:time(),
					case Hour >= 2 andalso Hour =<21 of
						false ->
							do_salary_error(Unique, Module, Method, ?_LANG_GET_SALARY_TIME_WRONG, PID);
						true ->
							do_salary_2(RoleID,OffIceID,Unique, Module, Method, PID)
					end
			end
	end.


do_salary_2(RoleID,OfficeID,Unique, Module, Method, PID) ->
	{ok, SustainedTime} = mod_spec_activity:get_role_sustained_online_time(RoleID),
	[#p_role_base{faction_id=FactionID}] = db:dirty_read(?DB_ROLE_BASE,RoleID),
	NowDay = calendar:date_to_gregorian_days(date()),
	case get({?faction_salary_info,FactionID,OfficeID}) of
		undefined ->
			LastDay = NowDay - 1,
			Silver = 0;
		{LastDay,Silver} ->
			ignore
	end,
	case check_can_salary(NowDay,LastDay,Silver,OfficeID,FactionID,SustainedTime*10) of
		{false,Reason} ->
			do_salary_error(Unique, Module, Method, Reason, PID);
		{true,Silver2,MaxSilver} ->
			put({?faction_salary_info,FactionID,OfficeID},{NowDay,Silver2}),
			AddList =  [{silver, Silver2-Silver, ?GAIN_TYPE_SILVRE_FACTION_OFFICE_SALARY, ""}],
			mgeer_role:absend(RoleID, {mod_map_role,{add_money,{RoleID, self(), AddList, undefined, undefined,true}}}),
			R = #m_faction_salary_toc{succ=true,salary=Silver2-Silver,left_salary=MaxSilver-Silver2},
    		common_misc:unicast2(PID, Unique, Module, Method, R)
	end.


check_can_salary(NowDay,LastDay,Silver,OfficeID,FactionID,SustainedTime) ->
	MaxSilver = get_max_silver(OfficeID,FactionID),
	case LastDay =:= NowDay andalso Silver < MaxSilver of
		true ->
			H = trunc((SustainedTime - Silver/10000*60*60)/3600),
			case H =< 0 of
				true ->
					{false,?_LANG_GET_SALARY_TIME_NOT_ENOUGH};
				false ->
					Silver2 = erlang:min(Silver + H * 10000, MaxSilver),
					{true,Silver2,MaxSilver}
			end;
		false ->
			case LastDay < NowDay of
				true ->
					H = trunc(SustainedTime/3600),
					case H =< 0 of
						true ->
							{false,?_LANG_GET_SALARY_TIME_NOT_ENOUGH};
						false ->
							Silver2 = erlang:min( H * 10000, MaxSilver),
							{true,Silver2,MaxSilver}
					end;
				false ->
					{false,?_LANG_GET_SALARY_FULL}
			end
	end.
	

get_max_silver(OfficeID,FactionID) ->
	{_,List} = calc_strlength_rank(),
	case lists:member({FactionID,1}, List) of
		true ->
			get_week_faction_silver(OfficeID);
		false ->
			get_strong_faction_silver(OfficeID)
	end.

get_week_faction_silver(4) ->
	30000;
get_week_faction_silver(3) ->
	20000;
get_week_faction_silver(2) ->
	20000;
get_week_faction_silver(1) ->
	20000.

get_strong_faction_silver(4) ->
	20000;
get_strong_faction_silver(3) ->
	10000;
get_strong_faction_silver(2) ->
	10000;
get_strong_faction_silver(1) ->
	10000.

do_salary_error(Unique, Module, Method, Reason, PID) ->
    R = #m_faction_salary_toc{succ=false, err_reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).
    
    
%% 初始化数据
init_data() ->
    do_calc_faction_strength(),
    Time = common_time:diff_next_daytime(3, 30),
    erlang:send_after(Time * 1000, erlang:self(), recalc_faction_strength).
	
    
%% 查询sql获得国家势力分布
do_calc_faction_strength() ->
    {Date, _} = erlang:localtime(), 
    LastActiveTime = common_tool:datetime_to_seconds(common_time:add_days(Date, -3)),
    FactionStrengths = lists:foldl(
                         fun(FactionID, Acc) ->
                                 Sql = io_lib:format("select count(distinct(base.role_id)) as num from db_role_base_p base,t_stat_user_online stat,db_role_ext_p ext, db_role_attr_p attr where base.role_id = stat.user_id and base.role_id = ext.role_id and avg_online_time >= 10  and attr.level >= 60 and faction_id = ~p and last_login_time > ~p", [FactionID, LastActiveTime]),
                                 case mod_mysql:select(Sql, 90000) of                                     
                                     {ok, [[FactionStrength]]} ->
                                         ?ERROR_MSG("~ts:~p", ["活跃人数统计结果", FactionStrength]),
                                         [{FactionID, common_tool:to_integer(FactionStrength)} | Acc];
                                     {error, {mysql_result, _, _, _, Error}} ->
                                         ?ERROR_MSG("~ts:~p", ["统计活跃玩家人数出错", Error]),
                                         Acc;
                                     {_Ref, {data, {mysql_result, _FieldsDesc, [[FactionStrength]], _Unknow, _Unknow2}}}  ->
                                         ?ERROR_MSG("~ts:~p", ["活跃人数统计结果", FactionStrength]),
                                         [{FactionID, common_tool:to_integer(FactionStrength)} | Acc];
                                     {data, {mysql_result, _FieldsDesc, [[FactionStrength]], _Unknow, _Unknow2}} ->
                                         [{FactionID, common_tool:to_integer(FactionStrength)} | Acc]
                                 end
                         end, [], ?FACTIONID_LIST),
    erlang:put(faction_strength, FactionStrengths),
    ok.


send_faction_strength_to_all_map() ->
	{_,List} = calc_strlength_rank(),
	common_map:send_to_all_map({mod_map_faction,{set_faction_strength,List}}).

calc_strlength_rank() ->
	case erlang:get(faction_strength) of
			   undefined ->
				   List = [];
			   List ->
				   ignore
		   end,
	NewList = lists:sort(fun(E1,E2) -> cmp(E1,E2) end, List),
	lists:foldr(fun({FactionID,_},{N,Acc})-> {N-1,[{FactionID,N}|Acc]} end, {3,[]}, NewList).

cmp({_,Str1},{_,Str2}) ->
	Str1 < Str2.

do_get_faction_strength(Pid) ->
	{_,List} = calc_strlength_rank(),
	Pid ! {mod_map_faction,{set_faction_strength,List}}.
	

