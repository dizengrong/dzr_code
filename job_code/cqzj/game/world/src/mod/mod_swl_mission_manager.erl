%%% @author fsk 
%%% @doc
%%%     神王令任务的Manager-Server
%%% @end
%%% Created : 2012-12-3
%%%-------------------------------------------------------------------
-module(mod_swl_mission_manager).
-behaviour(gen_server).
-export([
			start/0,
			start_link/0
		]).

-export([
			refresh/0
		]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

-define(REFRESH_INTERVAL, 10 * 1000).
-define(MISSION_FETCH_LIST, mission_fetch_list).

-define(REWARD_LIST, reward_list).

%% ====================================================================
%% Macro
%% ====================================================================

%% ====================================================================
%% External functions
%% ====================================================================
start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, 30000, worker, [?MODULE]}).
    
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:process_flag(trap_exit, true),
    erlang:send_after(?REFRESH_INTERVAL, self(), refresh_swl_fetch_list),
    {ok, []}.

refresh() ->
	erlang:send({global,?MODULE},refresh_swl_fetch_list).

 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call(Call, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Call, State),
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_handle_call(_) ->
    error.
do_handle_info({mission_fetch_list,RoleLevel,PID}) ->
    do_mission_fetch_list(RoleLevel,PID);
do_handle_info(refresh_swl_fetch_list) ->
	refresh_swl_fetch_list(),
    erlang:send_after(?REFRESH_INTERVAL, self(), refresh_swl_fetch_list);
do_handle_info({publish_swl_mission,RoleID,SwlID,RewardExp,RoleLevel}) ->
	publish_swl_mission(RoleID,SwlID,RewardExp,RoleLevel);
do_handle_info({reward_publish_swl_mission,RoleID,SwlID,RewardExp}) ->
	case common_misc:is_role_on_gateway(RoleID) of
		true ->
			reward_publish_swl_mission(RoleID,SwlID,RewardExp);
		false ->
			common_misc:update_dict_queue(?REWARD_LIST, {{RoleID,SwlID},RewardExp})
	end;
do_handle_info({reduce_swl_fetch_num,RoleID,RoleLevel,SwlID}) ->
	reduce_swl_fetch_num(RoleID,RoleLevel,SwlID);
do_handle_info({check_swl_fetch_num,RoleID,RoleLevel,SwlID, From}) ->
    check_swl_fetch_num(RoleID,RoleLevel,SwlID, From);
do_handle_info({role_online,RoleID}) ->
	case get(?REWARD_LIST) of
		undefined -> ignore;
		List ->
			[SwlIds] = mod_swl_mission:find_config(swl_ids),
			lists:foreach(fun(SwlID) ->
								  case lists:keyfind({RoleID,SwlID}, 1, List) of
									  false -> ignore;
									  {_,RewardExp} ->
										  erlang:put(?REWARD_LIST,lists:keydelete({RoleID,SwlID}, 1, List)),
										  reward_publish_swl_mission(RoleID,SwlID,RewardExp)
								  end
						  end, SwlIds)
	end;

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

refresh_swl_fetch_list() ->
	erlang:erase(?MISSION_FETCH_LIST),
	SwlMissionList = mod_swl_mission:get_swl_mission_config(),
	MissionFetchList =
		lists:map(fun(#r_swl_mission{swls=Swls,level_section=LevelSection}) ->
						  {LevelSection,lists:map(fun({SwlID,CanFetchList,_,_}) ->
											WtList = [Wt||{Wt,_,_}<-CanFetchList],
											WtIdx = common_tool:random_from_weights(WtList, true),
											{_,Min,Max} = lists:nth(WtIdx, CanFetchList),
											CanFetchNum = common_tool:random(Min,Max),
											#p_swl_mission_fetch{swl_id=SwlID,can_fetch_num=CanFetchNum}
									end, Swls)}
				  end, SwlMissionList),
	erlang:put(?MISSION_FETCH_LIST,MissionFetchList),
	MissionFetchList.

do_mission_fetch_list(RoleLevel,PID)->
	case get(?MISSION_FETCH_LIST) of
		undefined -> MissionFetchList = refresh_swl_fetch_list();
		MissionFetchList -> next
	end,
	case common_tool:find_tuple_section(RoleLevel,MissionFetchList) of
		undefined -> SwlMissionFetch = [];
		{_,SwlMissionFetch} -> next
	end,
	R2 = #m_swl_mission_fetch_list_toc{fetch=SwlMissionFetch},
	common_misc:unicast2(PID,?DEFAULT_UNIQUE,?SWL_MISSION,?SWL_MISSION_FETCH_LIST,R2).

%% 随机加经验
publish_swl_mission(RoleID,SwlID,RewardExp,RoleLevel) ->
	[{MinRoleLevel,MinSeconds}] = mod_swl_mission:find_config(finish_publish_mission_seconds),
	Seconds = 
		case RoleLevel =< MinRoleLevel of
			true -> MinSeconds;
			_ -> 
				[SecondsTmp] = mod_swl_mission:find_config(finish_publish_mission_random_seconds),
				common_tool:random(1,SecondsTmp)
		end,
	erlang:send_after(Seconds*1000,self(),{reward_publish_swl_mission,RoleID,SwlID,RewardExp}).

reward_publish_swl_mission(RoleID,SwlID,RewardExp) ->
	%%common_misc:send_to_rolemap(RoleID, {mod_map_role, {add_exp, RoleID, RewardExp}}),
	mgeer_role:send(RoleID, {mod_map_role, {add_exp, RoleID, RewardExp}}),
	common_broadcast:bc_send_msg_role(RoleID,?BC_MSG_TYPE_POP,lists:concat(["你发布的神王令任务已被领取，获得经验：",RewardExp])),
	mgeer_role:send(RoleID, {mod_swl_mission, {finish_publish_swl_mission, RoleID, SwlID}}).
		
%% 领取的时候减少可领取神王令个数
reduce_swl_fetch_num(RoleID,RoleLevel,SwlID) ->
	AllMissionFetchList = erlang:erase(?MISSION_FETCH_LIST),
	case common_tool:find_tuple_section(RoleLevel,AllMissionFetchList) of
		undefined -> ignore;
		{RoleLevelKey,MissionFetchList} -> 
			NewMissionFetchList = 
				case lists:keyfind(SwlID,#p_swl_mission_fetch.swl_id,MissionFetchList) of
					false -> MissionFetchList;
					#p_swl_mission_fetch{can_fetch_num=CanFetchNum}=MissionFetch ->
						lists:keyreplace(SwlID,#p_swl_mission_fetch.swl_id,MissionFetchList,MissionFetch#p_swl_mission_fetch{can_fetch_num=erlang:max(0,CanFetchNum-1)})
				end,
			NewAllMissionFetchList = lists:keyreplace(RoleLevelKey,1,AllMissionFetchList,{RoleLevelKey,NewMissionFetchList}),
			erlang:put(?MISSION_FETCH_LIST,NewAllMissionFetchList),
			R2 = #m_swl_mission_fetch_list_toc{fetch=NewMissionFetchList},
			common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SWL_MISSION,?SWL_MISSION_FETCH_LIST,R2)
	end.

%% 检查神王令可领取个数
check_swl_fetch_num(RoleID, RoleLevel, SwlID, From) ->
    AllMissionFetchList = get(?MISSION_FETCH_LIST),
    case common_tool:find_tuple_section(RoleLevel, AllMissionFetchList) of
        undefined -> ignore;
        {_, MissionFetchList} -> 
            case lists:keyfind(SwlID, #p_swl_mission_fetch.swl_id, MissionFetchList) of
                false -> CanFetchNum=0;
                #p_swl_mission_fetch{can_fetch_num=CanFetchNum} ->
                    next
            end,
            case CanFetchNum > 0 of
                true -> 
                    mgeer_role:send(RoleID, {mod_swl_mission, {operate_fetch, RoleID, SwlID, From}});
                false ->
					?ROLE_OPERATE_BROADCAST(RoleID,"当前可领取神王令个数不够，请重新刷新"),
                    R = #m_swl_mission_fetch_list_toc{fetch=MissionFetchList},
                    common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SWL_MISSION,?SWL_MISSION_FETCH_LIST,R)
            end
    end.