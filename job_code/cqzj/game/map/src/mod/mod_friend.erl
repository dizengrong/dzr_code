%% Author: ldk
%% Created: 2012-9-5
%% Description: TODO: Add description to mod_friend
-module(mod_friend).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-include("mgeem.hrl").

-export([
         handle/1,
         handle/2, 
		init_friend_visit/2, 
		delete_friend_visit/1
        ]).

%% 发送好友拜访次数字典
-define(DICT_SEND_FRIEND_VISIT, r_friend_visit).
%% 好友拜访类型
-define(VISIT_MONEY_EVENT, 1).
-define(VISIT_EXP_EVENT, 2).
-define(VISIT_PRESTIGE_EVENT, 3).

%%
%% API Functions
%%
handle(Info,_State) ->
    handle(Info).


handle({_, ?FRIEND, ?FRIEND_RECOMMEND,_,_,_,_}=Info) ->
    do_friend_recommend(Info);

handle({_, ?FRIEND, ?FRIEND_VISIT,_,_,_,_}=Info) ->
	do_friend_visit(Info);

handle({_, ?FRIEND, ?FRIEND_SEND_VISITED_LIST,_,_,_,_}=Info) ->
	do_friend_send_visited_list(Info);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg : ~w", [?MODULE,Info]).

%%
%% Local Functions
%%
do_friend_recommend({Unique, Module, Method, _DataIn, RoleID, _PID, Line}=Info) ->
	State = mgeem_map:get_state(),
	#map_state{offsetx = OffsetX, offsety = OffsetY} = State,
	#p_pos{tx=X, ty=Y} = mod_map_actor:get_actor_pos(RoleID, role), 
	SliceList = mgeem_map:get_9_slice_by_txty(X, Y, OffsetX, OffsetY),
	RoleList = mgeem_map:get_all_in_sence_user_by_slice_list(SliceList),
	RoleList2 = lists:sublist(lists:delete(RoleID, RoleList), 5),
	case RoleList2 of
		[] ->
			global:send(mod_friend_server, Info);
		_ ->
			RecommendList = 
				lists:foldl(fun(RecomRoleID,Acc) ->
									case {mod_map_role:get_role_base(RecomRoleID),mod_map_role:get_role_attr(RecomRoleID)} of
										{{ok,#p_role_base{family_name=FamilyName,faction_id=FactionID}},{ok,#p_role_attr{level=Level,role_name=RoleName}}} ->
											[#p_recommend_member_info{role_id=RecomRoleID,
																	  faction_id=FactionID,
																	  family_name=FamilyName,
																	  role_name=RoleName, level=Level}|Acc];
										_ ->
											Acc
									end
							end, [], RoleList2),
			DataRecord = #m_friend_recommend_toc{friend_info=RecommendList},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord)
	end.

%% 初始化好友拜访列表
init_friend_visit(RoleID, Rec) when is_record(Rec, ?DICT_SEND_FRIEND_VISIT) ->
	put({?DICT_SEND_FRIEND_VISIT, RoleID}, Rec);
init_friend_visit(_RoleID, _) ->
    ignore.

%% 删除好友拜访列表
delete_friend_visit(RoleID) ->
	erase({?DICT_SEND_FRIEND_VISIT, RoleID}).

%% 处理朋友拜访
do_friend_visit({Unique, Module, Method, DataIn, RoleID, _PID, _Line}) ->
	#m_friend_visit_tos{
		to_friend_id = ToFriendID, 
		visit_type = VisitType, 
		visit_event = VisitEvent
	} = DataIn, 
	EventList = case VisitType of
		?VISIT_MONEY_EVENT ->
			cfg_friend:money_events();
		?VISIT_EXP_EVENT ->
			cfg_friend:exp_events();
		?VISIT_PRESTIGE_EVENT ->
			cfg_friend:prestige_events()
	end,
	EventFlag = lists:member(VisitEvent, EventList), 

	if
		EventFlag ->
			VipLevel = mod_vip:get_role_vip_level(RoleID),
			MaxVisitCount = cfg_friend:visit_count(VipLevel),
			%% get the visited list
			case get({?DICT_SEND_FRIEND_VISIT, RoleID}) of
				undefined ->
					ListTime = date(),
					SendVisitList1 = [];
				#r_friend_visit{visit_list = SendVisitList1, date = ListTime} ->
					[]
			end, 
			NowTime = date(),
			SendVisitList = if
				NowTime == ListTime ->
					SendVisitList1;
				true ->
					[]
			end, 
			Counter = length(SendVisitList) + 1,
			if
				Counter =< MaxVisitCount ->
					case lists:keymember(ToFriendID,1, SendVisitList) == false andalso 
						RoleID =/= ToFriendID of 
						true ->
							%%获取玩家等级
							{ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),

							Toc1 = case VisitType of
								?VISIT_MONEY_EVENT ->
									Percent = mod_normal_skill:get_wealth_skill_effect_value(RoleID),
									EarnMoney = trunc(Percent * cfg_friend:money_event()), 
									visit_add_money(RoleID, EarnMoney), 
									#m_friend_visit_toc{money_add = EarnMoney};
								?VISIT_EXP_EVENT ->
									EarnExp = cfg_friend:exp_event(RoleLevel), 
									common_misc:add_exp_unicast(RoleID, EarnExp), 
									#m_friend_visit_toc{exp_add = EarnExp};
								?VISIT_PRESTIGE_EVENT ->
									EarnPrestige = cfg_friend:prestige_event(RoleLevel), 
									visit_add_prestige(RoleID, EarnPrestige),
									#m_friend_visit_toc{prestige_add = EarnPrestige}
							end,
							{ok, #p_role_base{role_name = SenderName}} =  common_misc:get_dirty_role_base(ToFriendID),
							Toc = Toc1#m_friend_visit_toc{
								visit_type = VisitType, 
								visit_event=VisitEvent, 
								% send_self = RoleID,
								send_name = SenderName
							}, 
							mod_friend_server:add_friendly(RoleID, ToFriendID, 1, 3),

							put({?DICT_SEND_FRIEND_VISIT, RoleID}, #r_friend_visit{visit_list = [{ToFriendID, VisitEvent}|SendVisitList], date = NowTime}),
							common_misc:unicast(_Line, RoleID, Unique, Module, Method, Toc), 

							case mod_role_tab:is_exist(ToFriendID) of
        						true ->
									{ok, #p_role_base{role_name = RoleName}} =  mod_map_role:get_role_base(RoleID), 
									Toc2 = #m_friend_visit_toc{
										visit_type = VisitType, 
										visit_event = VisitEvent, 
										send_self = ToFriendID,
										send_name = RoleName
									}, 
									common_misc:unicast(_Line, ToFriendID, Unique, Module, Method, Toc2);
								_ ->
									[]
							end, 
							do_friend_send_visited_list({Unique, Module, ?FRIEND_SEND_VISITED_LIST, [], RoleID, _PID, 0});
							%%common_misc:unicast2(PID, Unique, Module, Method, Toc);
						_ ->
							Reason = <<"该好友已经访问过了">>, 
							Toc = #m_friend_visit_toc{succ = false, reason = Reason},
							common_misc:unicast(_Line, RoleID, Unique, Module, Method, Toc)
							%%common_misc:unicast2(PID, Unique, Module, Method, Toc)
					end;
				true ->
					Reason = <<"今天的访问次数已经用尽!">>,
					Toc = #m_friend_visit_toc{succ = false, reason = Reason},
					common_misc:unicast(_Line, RoleID, Unique, Module, Method, Toc)
					%%common_misc:unicast2(PID, Unique, Module, Method, Toc)
			end
	end.
	
visit_add_money(RoleID, Bonus) ->
    case common_transaction:t(
           fun() ->
                   {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                   {ok,NewRoleAttr} = common_bag2:t_gain_money(silver_any, Bonus, RoleAttr, ?GAIN_TYPE_SILVER_FRIEND_VISIT),
                   mod_map_role:set_role_attr(RoleID,NewRoleAttr),
                   {ok,NewRoleAttr}
           end) of
        {atomic,{ok, NewRoleAttr}} ->
			ChangeList = [
				#p_role_attr_change{
					change_type=?ROLE_SILVER_BIND_CHANGE,
					new_value=NewRoleAttr#p_role_attr.silver
				}
			],

			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
            ok; 
        _ ->
            error
    end.

visit_add_prestige(RoleID, Bonus) ->
    case common_transaction:t(
           fun() ->
                   {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                   {ok,NewRoleAttr} = common_bag2:t_gain_prestige(Bonus, RoleAttr, ?GAIN_TYPE_PRESTIGE_FROM_VISIT),
                   mod_map_role:set_role_attr(RoleID,NewRoleAttr),
                   {ok,NewRoleAttr}
           end) of
        {atomic,{ok,NewRoleAttr}} ->

        	ChangeList = [
				#p_role_attr_change{
					change_type=?ROLE_SUM_PRESTIGE_CHANGE, 
					new_value=NewRoleAttr#p_role_attr.sum_prestige
					},
				#p_role_attr_change{
					change_type=?ROLE_CUR_PRESTIGE_CHANGE, 
					new_value=NewRoleAttr#p_role_attr.cur_prestige
				}
			],
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
            ok; 
        _ ->
            error
    end.

do_friend_send_visited_list({Unique, Module, Method, _DataIn, RoleID, _PID, Line}) ->
	case get({?DICT_SEND_FRIEND_VISIT, RoleID}) of
		undefined ->
			ListTime = date(),
			SendVisitList1 = [];
		#r_friend_visit{visit_list = SendVisitList1, date = ListTime} ->
			[]
	end, 
	NowTime = date(),
	Toc = if
		ListTime == NowTime ->
			List = lists:foldl(fun({H, VisitEvent}, Acc) ->
				[#p_friend_send_visited_info{id = H, visit_event = VisitEvent}|Acc]
			end, [], SendVisitList1), 
			#m_friend_send_visited_list_toc{
				friend_visited_list = List
			};
		true ->
			#m_friend_send_visited_list_toc{
				friend_visited_list = []
			}
	end,
	%%common_misc:unicast2(PID, Unique, Module, Method, Toc).
	common_misc:unicast(Line, RoleID, Unique, Module, Method, Toc).






