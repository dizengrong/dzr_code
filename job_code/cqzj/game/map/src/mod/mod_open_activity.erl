%% Author: lijianjun
%% Created: 2013-4-19
%% Description:  开服活动
-module(mod_open_activity).

%%
%% Include files
%%
-include("mgeem.hrl").
%%
%% Exported Functions
%%
-compile(export_all).
%%
%% API Functions
%%


-define(COLOR_PURPLE_WHOLE,4).
-define(COLOR_ORANGE_WHOLE,5).

-define(TYPE_ID_PURPLE_WHOLE,13).
-define(TYPE_ID_ORANGE_WHOLE,14).
-define(TYPE_ID_ACCGOLD,17).
-define(TYPE_ID_VIP_LEVEL,19).
-define(TYPE_ID_FB,20).
-define(TYPE_ID_PAY,21).
-define(TYPE_ID_GEMS_LV4,22).
-define(TYPE_ID_GEMS_LV6,23).

-define(TYPE_STATUS_NOT_REWARD,0).
-define(TYPE_STATUS_CAN_REWARD,1).
-define(TYPE_STATUS_FINISH_REWARD,2).


-define(_m_info_toc,?DEFAULT_UNIQUE,?OPEN_ACTIVITY,?OPEN_ACTIVITY_INFO,#m_open_activity_info_toc).
-define(_m_reward_toc,?DEFAULT_UNIQUE,?OPEN_ACTIVITY,?OPEN_ACTIVITY_REWARD,#m_open_activity_reward_toc).

-define(_p_info,#p_open_activity_info).
-define(_cfg_get_reward(Type,I),cfg_open_activity:get_activity_reward(Type,I)).
-define(_cfg_get_max_subid(Type),cfg_open_activity:get_max_subid(Type)).

-define(IS_VALID_DATE(Type),common_config:get_opened_days() =< cfg_open_activity:get_valid_date(Type)).
-define(ASSERT_AVALID_DATE(Fun,Type),assert_valid_date(Fun,Type)).

handle(Msg,_State)->
	handle(Msg).
handle({_,?OPEN_ACTIVITY,?OPEN_ACTIVITY_INFO,_,RoleID,_,_}=_Msg)->
	notify_activity_change(RoleID);
handle({_,?OPEN_ACTIVITY,?OPEN_ACTIVITY_REWARD,_,_,_,_}=Msg)->
	do_reward(Msg);
handle(Other) ->
	?ERROR_MSG("~ts:~w",["未知消息", Other]).

hook_role_online(RoleID) ->
	mod_role_event:add_handler(RoleID, ?ROLE_EVENT_EQUIP_PUT, {?MODULE, null}),
	do_hook_event(RoleID,0,?TYPE_ID_VIP_LEVEL,true).

hook_role_offline(RoleID) ->
	mod_role_event:delete_handler(RoleID, ?ROLE_EVENT_EQUIP_PUT, ?MODULE).	

handle_event(RoleID, {?ROLE_EVENT_EQUIP_PUT, _}, _)	->
	hook_whole_event(RoleID);
handle_event(_RoleID, _, _) -> ignore.

%% hook_role_online(RoleID) ->
%% 	notify_activity_change(RoleID).
%%集取装备
hook_whole_event(RoleID) ->
	?ASSERT_AVALID_DATE(fun() -> do_whole_event(RoleID) end,[?TYPE_ID_PURPLE_WHOLE,?TYPE_ID_ORANGE_WHOLE]).
%%累计消费
hook_accgold_event(RoleID,Num) ->
	do_hook_event(RoleID,Num,?TYPE_ID_ACCGOLD,true).
%%升级
hook_vip_level_event(RoleID,Num) ->
	do_hook_event(RoleID,Num,?TYPE_ID_VIP_LEVEL,true).
%%法宝升级
hook_fb_level_event(RoleID,Num) ->
	?ASSERT_AVALID_DATE(fun() -> do_hook_event(RoleID,Num,?TYPE_ID_FB,true) end,?TYPE_ID_FB).
%%单日累计消费
hook_day_accgold_event(RoleID,Num) ->
	?ASSERT_AVALID_DATE(fun() -> do_hook_event(RoleID,Num,?TYPE_ID_PAY,true) end,?TYPE_ID_PAY).
%%宝石
hook_gems_event(RoleID) ->
	?ASSERT_AVALID_DATE(fun() -> do_hook_gems_event(RoleID) end,[?TYPE_ID_GEMS_LV4,?TYPE_ID_GEMS_LV6]).

do_hook_gems_event(RoleID) ->
	case mod_role_tab:get({role_gems, RoleID}) of
		RoleGemsRec when is_record(RoleGemsRec,p_role_gems) ->
				AllHoles = RoleGemsRec#p_role_gems.head
				++ RoleGemsRec#p_role_gems.body
				++ RoleGemsRec#p_role_gems.wrist
				++ RoleGemsRec#p_role_gems.hand
				++ RoleGemsRec#p_role_gems.neck
				++ RoleGemsRec#p_role_gems.waist
				++ RoleGemsRec#p_role_gems.bracelet
				++ RoleGemsRec#p_role_gems.foot,
				{GemsLv6Num,GemsLv4Num} = 
					lists:foldl(fun(#p_gem_hole{gem_typeid = GemsTypeID},{AccIn0,AccIn1}) ->
										calc_gems_num(GemsTypeID,AccIn0,AccIn1) 
								end, {0,0}, AllHoles),
				do_hook_event(RoleID,GemsLv6Num,?TYPE_ID_GEMS_LV6,false),
				do_hook_event(RoleID,GemsLv4Num,?TYPE_ID_GEMS_LV4,true),
				ok;
		_ ->
			ignore
	end.

calc_gems_num(GemsTypeID,AccIn0,AccIn1) ->
	GemsTypeLv = GemsTypeID rem 10,
	NewAccIn0 = 
		case GemsTypeLv >= 6 of
			true ->
				AccIn0 +1;
			_ ->
				AccIn0
		end,
	
	NewAccIn1 = 
		case GemsTypeLv >= 4 of
			true ->
				AccIn1 + 1;
			_ ->
				AccIn1
		end,
	{NewAccIn0,NewAccIn1}.

do_whole_event(RoleID) ->
	case mod_map_role:get_role_attr(RoleID) of
		{ok,#p_role_attr{equips=Equips}} ->
			Fun =
				fun(#p_goods{current_colour = Color},{PurpleCount,OrangeCount}) ->
						if
							Color =:= ?COLOR_PURPLE_WHOLE ->
								NewPurpleCount = PurpleCount +1,
								do_hook_event(RoleID,NewPurpleCount,?TYPE_ID_PURPLE_WHOLE,true),
								{NewPurpleCount,OrangeCount};
							Color =:= ?COLOR_ORANGE_WHOLE ->
								NewOrangeCount = OrangeCount +1,
								do_hook_event(RoleID,NewOrangeCount,?TYPE_ID_ORANGE_WHOLE,true),
								{PurpleCount,NewOrangeCount};
							true ->
								{PurpleCount,OrangeCount}
						end
				
				end,
			lists:foldl(Fun, {0,0}, Equips);
		_ ->
			ignore
	end.

notify_activity_change(RoleID) ->
	case get_role_open_info(RoleID) of
		{ok,#r_open_server_activity{items = ActivityInfoList}} ->
			ValidDays = cfg_open_activity:get_valid_date(0),
			ValidIdList = cfg_open_activity:get_activty_id(),
			NewActivityInfoList = 
				lists:foldl(fun(Type,AccIn) ->
									case lists:filter(fun( #p_open_activity_info{typeid=TypeID}) ->
															  Type =:=TypeID 
													  end, ActivityInfoList) of
										[] ->
											ValidDate =cfg_open_activity:get_valid_date(Type),
											[#p_open_activity_info{typeid=Type,valid_date = ValidDate}|AccIn];
										List ->
											lists:append(List, AccIn)
									end
							end,[], ValidIdList),
			common_misc:unicast({role, RoleID},?_m_info_toc{
								open_days=ValidDays,
								activity_info = NewActivityInfoList
								});
		_ ->
			ignore
	
	end.

check_do_reward(RoleID,TypeId,SubId) ->
	case get_role_open_info(RoleID,TypeId,SubId) of
		{ok,ActivityInfo} ->
			case ActivityInfo#p_open_activity_info.status of
				?TYPE_STATUS_FINISH_REWARD ->
					?THROW_ERR_REASON(<<"你已经领取过该奖励！">>);
				?TYPE_STATUS_NOT_REWARD ->
					?THROW_ERR_REASON( <<"你还没有完成任务，不能领取奖励！">>);
				_ ->
					{ok,ActivityInfo}
			end;
		_ ->
			?THROW_ERR_REASON( <<"你还没有完成任务，不能领取奖励！">>)
	end.

add_vip_buff(RoleID,TypeId,SubId) ->
	case TypeId =:= ?TYPE_ID_VIP_LEVEL andalso SubId =:= 1 of
		true ->
			lists:foreach(fun(I) -> 
								  mod_vip:do_buy_buff_succ(RoleID, I)
						  end, [1,3]);
		_ ->
			ignore
	end.

do_reward({Unique,Module,Method,DataIn,RoleID,PID,_Line}) ->
	#m_open_activity_reward_tos{typeid=TypeId,subid=SubId} = DataIn,
	case catch check_do_reward(RoleID,TypeId,SubId) of
		{ok,ActivityInfo} ->
			case ActivityInfo#p_open_activity_info.status of
				?TYPE_STATUS_CAN_REWARD ->
					{_,Awards} = ?_cfg_get_reward(TypeId,SubId),
					LogType  = ?LOG_ITEM_OPEN_ACTIVITY_REWARD,
					case catch mod_bag:add_items(RoleID, Awards, LogType) of
						{error, ?_LANG_GOODS_BAG_NOT_ENOUGH} ->
							R = #m_open_activity_reward_toc{
								typeid   = TypeId,subid=SubId,
								err_code = ?ERR_POS_NOT_ENOUGH,
								reason   = ?_LANG_GOODS_BAG_NOT_ENOUGH
							};
						{error,Reason} ->
							R = #m_open_activity_reward_toc{
								typeid   = TypeId,
								subid    = SubId,
								err_code = ?ERR_OTHER_ERR,
								reason   = Reason
							};
						{true,_}->
							add_vip_buff(RoleID,TypeId,SubId),
							set_role_open_activity_status(
							  	RoleID,TypeId,SubId,
								?TYPE_STATUS_FINISH_REWARD
							),
							common_misc:common_broadcast_other(RoleID, {TypeId, SubId - 1}, ?MODULE),
							R = #m_open_activity_reward_toc{
								typeid = TypeId,
								subid  = SubId
							}
					end;
				_ ->
					R = #m_open_activity_reward_toc{
						typeid   = TypeId,
						subid    = SubId,
						err_code = ?ERR_SYS_ERR
					}
			end;
		{error,ErrCode,Reason} ->
			R = #m_open_activity_reward_toc{
				typeid   = TypeId,
				subid    = SubId,
				err_code = ErrCode,
				reason   = Reason
			};
		_ ->
			R = #m_open_activity_reward_toc{
				typeid=TypeId,
				subid=SubId,
				err_code=?ERR_SYS_ERR
			}
				
	end,
	?UNICAST_TOC(R).

do_hook_event(RoleID,Num,Type,IsNotity) ->
	case ?_cfg_get_max_subid(Type) of
		MaxSubId when erlang:is_integer(MaxSubId) ->
			Fun = fun(I)->
						  set_role_open_activity_info1(RoleID,Num,Type,I) 
				  end,
			catch lists:foreach( Fun, lists:reverse(lists:seq(1, MaxSubId))),
			IsNotity andalso notify_activity_change(RoleID);
		_ ->
			ignore
	end.

set_role_open_activity_info1(RoleID,Count,Type,I) ->
	{Num,_} = ?_cfg_get_reward(Type,I),
	case get_role_open_info(RoleID,Type,I) of
		{ok,PactivityInfo} ->
			Status = PactivityInfo#p_open_activity_info.status,
			IsWhole =  lists:member(Type, [13,14]),
			case  Count >= Num of
				true when Status =:= ?TYPE_STATUS_NOT_REWARD->
					set_role_open_activity_status(RoleID,Type,I,?TYPE_STATUS_CAN_REWARD),
					{true,?TYPE_STATUS_CAN_REWARD};
				false when IsWhole =:= true 
				  andalso Status =:= ?TYPE_STATUS_CAN_REWARD ->
					set_role_open_activity_status(RoleID,Type,I,?TYPE_STATUS_NOT_REWARD),
					{true,?TYPE_STATUS_NOT_REWARD};
				_ ->
					{false,0}
			end;
		_ ->
			case  Count >= Num of
				true ->
					set_role_open_activity_status(RoleID,Type,I,?TYPE_STATUS_CAN_REWARD),
					{true,?TYPE_STATUS_CAN_REWARD};
				_ ->
					{false,0}
			end
	
	end.	

set_role_open_activity_status(RoleID,Type,I,Status)->
	ActivityInfoItem = ?_p_info{
		typeid = Type,
		subid  = I,
		status = Status
	},
	set_role_open_activity_info(RoleID,Type,I,ActivityInfoItem).

init(RoleID, Rec) when is_record(Rec, r_open_server_activity) ->
	mod_role_tab:put({?open_server_activity, RoleID}, Rec);
init(RoleID, _Rec) ->
	mod_role_tab:put({?open_server_activity, RoleID}, #r_open_server_activity{}).
delete(RoleID) ->
	mod_role_tab:erase({?open_server_activity, RoleID}).

set_role_open_activity_info(RoleID,TypeID,SubType,ActivityInfoItem) ->
	case get_role_open_info(RoleID) of
		{ok,#r_open_server_activity{items = []}} ->
			mod_role_tab:put(
			  {?open_server_activity, RoleID},
			  #r_open_server_activity{
			  items = [ActivityInfoItem]}
			);
		{ok,#r_open_server_activity{items = ActivityInfoList}} ->
			NewActivityInfo = 
				store_role_open_activity_info(TypeID,SubType,ActivityInfoList,ActivityInfoItem),
			mod_role_tab:put({?open_server_activity, RoleID},#r_open_server_activity{items =  NewActivityInfo});
		_ ->
			ignore
	end.

store_role_open_activity_info(TypeID,SubType,ActivityInfoList,ActivityInfoItem) ->
	case lists:foldl(fun(E,{IsFound,AccIn}) ->
							 ?_p_info{ typeid=TypeID1,subid=SubID1} = E,
							 case TypeID =:= TypeID1 
									  andalso SubType =:= SubID1 of
								 true ->
									 {true,[ActivityInfoItem|AccIn]};
								 _ ->
									 {IsFound,[E|AccIn]}
							 end
					 end, {false,[]}, ActivityInfoList) of
		{true,NewActivityInfoList} ->
			NewActivityInfoList;
		{false,NewActivityInfoList} ->
			[ActivityInfoItem|NewActivityInfoList]
	end.

get_role_open_info(RoleID,TypeID,SubType) ->
	case get_role_open_info(RoleID) of
		{ok,#r_open_server_activity{items = RecList}} ->
			Fun = fun(?_p_info{typeid=TypeID1,subid=SubID1} = E) ->
						  case TypeID =:= TypeID1 
								   andalso SubType =:= SubID1 of
							  true ->
								  throw({ok,E});
							  _ ->
								  next
						  end
				  end,
			case catch lists:foreach(Fun,RecList) of
				{ok,E} ->
					{ok,E};
				_ ->
					{error,not_found}
			end
	end.

get_role_open_info(RoleID) ->
	case mod_role_tab:get({?open_server_activity,RoleID}) of
		undefined ->
			{error,not_found};
		Rec ->
			{ok,Rec}
	end.

is_valid_date(Types) ->
	case erlang:is_list(Types) of
		true ->
			RetList = lists:map(fun(Type) -> 
						?IS_VALID_DATE(Type) end, Types),
			lists:member(true, RetList);
		_ ->
			?IS_VALID_DATE(Types)
	end.

assert_valid_date(Fun,Type) ->
	case
		is_valid_date(Type) of
		true -> Fun();
		_ ->ignore 
	end.


