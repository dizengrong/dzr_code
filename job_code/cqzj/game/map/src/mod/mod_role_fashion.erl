%% Author: xierongfeng
%% Created: 2013-05-13
%% Description: 时装、翅膀
-module(mod_role_fashion).

-define(_common_error,		?DEFAULT_UNIQUE,	?COMMON,	?COMMON_ERROR,		#m_common_error_toc).%}
-define(_fashion_info,		?DEFAULT_UNIQUE,	?FASHION,	?FASHION_INFO,		#m_fashion_info_toc).%}
-define(_fashion_puton,		?DEFAULT_UNIQUE,	?FASHION,	?FASHION_PUTON,		#m_fashion_puton_toc).%}
-define(_fashion_rankup,	?DEFAULT_UNIQUE,	?FASHION,	?FASHION_RANKUP,	#m_fashion_rankup_toc).%}
-define(_fashion_addexp,	?DEFAULT_UNIQUE,	?FASHION,	?FASHION_ADDEXP,	#m_fashion_addexp_toc).%}
-define(_base_reload,		?DEFAULT_UNIQUE, 	?ROLE2, 	?ROLE2_BASE_RELOAD,	#m_role2_base_reload_toc).%}

-define(TYPE_FASHION, 1).
-define(TYPE_WINGS,   2).
-define(TYPE_MOUNTS,  3).

-define(TYPE_RANKUP_RANK_2,2).
-define(TYPE_RANKUP_RANK_5,5).
-define(TYPE_RANKUP_RANK_8,8).
-define(TYPE_RANKUP_RANK_9,9).
-define(TYPE_RANKUP_RANK_10,10).


-define(TYPE_ADDEXP_TIMES_2,2).
-define(TYPE_ADDEXP_TIMES_4,4).
-define(TYPE_ADDEXP_TIMES_100,100).


%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([init/2, fetch/1, delete/1, handle/1, recalc/2, get/3]).

%%
%% API Functions
%%
init(RoleID, Rec) when is_record(Rec, r_role_fashion) ->
	mod_role_tab:put({r_role_fashion, RoleID}, Rec);
init(RoleID, _) ->
	mod_role_tab:put({r_role_fashion, RoleID}, #r_role_fashion{}).

fetch(RoleID) -> 
	case mod_role_tab:get({r_role_fashion, RoleID}) of
		Rec when is_record(Rec, r_role_fashion) -> 
			Rec;
		_ ->
			#r_role_fashion{}
	end.

fetch(RoleID, FashionType) -> 
	Rec = mod_role_tab:get({r_role_fashion, RoleID}),
	case FashionType of
		?TYPE_FASHION -> Rec#r_role_fashion.fashion;
		?TYPE_WINGS   -> Rec#r_role_fashion.wings;
        ?TYPE_MOUNTS  -> Rec#r_role_fashion.mounts
	end.

update(RoleID, Fashion) ->
	Index = case Fashion#r_fashion.type of
		?TYPE_FASHION -> #r_role_fashion.fashion;
		?TYPE_WINGS   -> #r_role_fashion.wings;
        ?TYPE_MOUNTS   -> #r_role_fashion.mounts
	end,
    Index == #r_role_fashion.fashion
        andalso mod_qrhl:send_event(RoleID, fashion, Fashion#r_fashion.rank),
	mod_role_tab:update_element(RoleID, r_role_fashion, {Index, Fashion}).

delete(RoleID) ->
	mod_role_tab:get({r_role_fashion, RoleID}).

handle({_Unique, ?FASHION, ?FASHION_INFO, DataIn, RoleID, PID, _Line}) ->
	#m_fashion_info_tos{fashion_type = FashionType} = DataIn,
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	Category  = RoleAttr#p_role_attr.category,
	#r_fashion{
		rank     = CurrRank,
		star     = CurrStar,
		exp      = CurrExp,
		exp1_c	 = Exp1C,
		exp4_c   = Exp4C,
		addexp_d = ExpDate
	} = fetch(RoleID, FashionType),
	{RankList, ZhiShengRank} = cfg_fashion:rank_list(FashionType, CurrRank),
	NextRank = lists:last(RankList),
	common_misc:unicast2(PID, ?_fashion_info{
		fashion_type = FashionType,        
		list         = [{Rank, cfg_fashion:id(FashionType, Rank)}||Rank<-RankList],                
		rank         = CurrRank,                
		star         = CurrStar,                
		cur_exp      = CurrExp,             
		max_exp      = cfg_fashion:max_exp(FashionType, CurrRank, CurrStar),             
		curr_attrs   = cfg_fashion:attrs(FashionType, Category, CurrRank, CurrStar),          
		next_attrs   = cfg_fashion:attrs(FashionType, Category, NextRank, 0),          
		rankup_gold  = if 
			CurrRank == ZhiShengRank -> 0;
			true -> cfg_fashion:rankup_gold(FashionType, ZhiShengRank)
		end,
		rankup_rank  = if 
			CurrRank == ZhiShengRank -> 0;
			true -> ZhiShengRank
		end,
		skill_id     = cfg_fashion:skill_id(FashionType),
		skill_lv     = cfg_fashion:skill_lv(FashionType, CurrRank, CurrStar),
		exp_tips     = exp_tips(RoleAttr, FashionType, CurrRank, CurrStar, Exp1C, Exp4C, ExpDate)
	});

handle({_Unique, ?FASHION, ?FASHION_PUTON, DataIn, RoleID, PID, _Line}) ->
	#m_fashion_puton_tos{fashion_type = Type, fashion_rank = PutonRank} = DataIn,
	Fashion = #r_fashion{rank = CurrRank} = fetch(RoleID, Type),
	Type == ?TYPE_MOUNTS andalso mod_map_role:clear_role_spec_state(RoleID),
	if
		PutonRank =< CurrRank, PutonRank >= 0 ->
			{ok, RoleBase1} = mod_map_role:get_role_base(RoleID),
			{ok, RoleAttr1} = mod_map_role:get_role_attr(RoleID),
			OldFashionID    = fashion_id(Type, RoleAttr1),
			NewFashionID    = cfg_fashion:id(Type, PutonRank),
			RoleBase2       = if
				OldFashionID == 0, PutonRank > 0 ->
					do_change_fashion(RoleID, RoleBase1, RoleAttr1, #r_fashion{type = Type, rank = 0}, Fashion, NewFashionID);
				OldFashionID > 0, PutonRank == 0 ->
					do_change_fashion(RoleID, RoleBase1, RoleAttr1, Fashion, #r_fashion{type = Type, rank = 0}, NewFashionID);
				OldFashionID > 0, PutonRank > 0 ->
					do_change_fashion(RoleID, RoleBase1, RoleAttr1, Fashion, Fashion, NewFashionID);
				true ->
					RoleBase1
			end,
            mod_role_attr:reload_role_base(RoleBase2);
		true ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"参数错误">>})
	end;

handle({Unique, ?FASHION, ?FASHION_RANKUP, DataIn, RoleID, PID, Line}) ->
	#m_fashion_rankup_tos{rank = NeedRank,fashion_type = FashionType, need_puton = NeedPuton} = DataIn,
	OldFashion = #r_fashion{rank = OldRank, star = OldStar, exp = OldExp} = fetch(RoleID, FashionType),
	NewRank = case NeedRank > 0 of
		true ->
			NeedRank;
		_ ->
			{_RankList, ZhiShengRank} = cfg_fashion:rank_list(FashionType, OldRank),
			ZhiShengRank
	end,
	RankUpGold = cfg_fashion:rankup_gold(FashionType, NewRank),
	if
		NeedPuton andalso OldRank >= NewRank ->
            case FashionType of
                ?TYPE_FASHION ->
			         common_misc:unicast2(PID, ?_common_error{error_str = <<"你已经有这个时装了">>});
                ?TYPE_WINGS ->
                     common_misc:unicast2(PID, ?_common_error{error_str = <<"你已经有这个翅膀了">>});
                ?TYPE_MOUNTS ->
                     common_misc:unicast2(PID, ?_common_error{error_str = <<"你已经有这个法宝了">>})
            end;
		NewRank > OldRank, RankUpGold > 0 ->
			case common_bag2:use_money(RoleID, gold_unbind, RankUpGold, 
					{get_rankup_consume_type(FashionType,NewRank), 
						"特价购买直升" ++ common_tool:to_list(NewRank) ++ "阶" }) of
				{error, Reason} -> 
					common_misc:unicast2(PID, ?_common_error{error_str = Reason});
				true ->
					AddExp = lists:foldl(fun
						(R, Acc1) ->
							lists:foldl(fun
								(S, Acc2) ->
									cfg_fashion:max_exp(FashionType, R, S) + Acc2
							end, Acc1, lists:seq(0, 9))
					end, 0, lists:seq(OldRank, NewRank-1)),
					{NewRank2, NewStar, NewExp} = add_exp2(FashionType, OldRank, OldStar, OldExp, AddExp),
					NewFashion = OldFashion#r_fashion{
						type = FashionType, rank = NewRank2, star = NewStar, exp = NewExp},
					update(RoleID, NewFashion),
					{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
					{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
					OldFashionID = fashion_id(FashionType, RoleAttr),
					OldFashion2  = case OldFashionID > 0 of
						true -> OldFashion;
						false ->
							#r_fashion{type = FashionType, rank = 0}
					end,
					NewFashion2  = case OldFashionID > 0 orelse NeedPuton of
						true -> NewFashion;
						false ->
							#r_fashion{type = FashionType, rank = 0}
					end,
					RoleBase2 = if
						NeedPuton ->
							common_misc:unicast2(PID, ?_fashion_rankup{fashion_type = FashionType}),
							do_change_fashion(RoleID, RoleBase, RoleAttr, 
								OldFashion2, NewFashion2, cfg_fashion:id(FashionType, NewRank2));
						true ->
							calc(RoleBase, RoleAttr#p_role_attr.category, '-', OldFashion2, '+', NewFashion2)
					end,
					mod_role_attr:reload_role_base(RoleBase2),
					FashionType =:= ?TYPE_MOUNTS andalso ?TRY_CATCH(mod_open_activity:hook_fb_level_event(RoleID, (NewRank2-1)*10+NewStar)),
					common_misc:common_broadcast_other(RoleID, {FashionType, NewRank2}, ?MODULE),
					do_log_role_fashion(RoleAttr, OldRank, NewRank2, OldStar, NewStar, FashionType, 0),
					handle({Unique, ?FASHION, ?FASHION_INFO,
					    #m_fashion_info_tos{fashion_type = FashionType}, RoleID, PID, Line}),
					if
						FashionType == ?TYPE_FASHION, OldRank == 1 ->
							mod_consume_task:start(RoleID);
						true ->
							ignore
					end,
					mod_role_event:notify(RoleID, {?ROLE_EVENT_FASHION_GET, NewFashion}),
					ok
			end;
		true ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"已经最高阶位了">>})
	end;
	
handle({Unique, ?FASHION, ?FASHION_ADDEXP, DataIn, RoleID, PID, Line}) ->
	#m_fashion_addexp_tos{fashion_type = FashionType, add_type = AddType} = DataIn,
	OldFashion = #r_fashion{rank = OldRank, star = OldStar} = fetch(RoleID, FashionType),
	case add_exp(RoleID, OldFashion, AddType) of
		NewFashion = #r_fashion{type = Type, rank = NewRank, star = NewStar} ->
			{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			case fashion_id(FashionType, RoleAttr) > 0 andalso {NewRank, NewStar} > {OldRank, OldStar} of
				true ->
					{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
					Category       = RoleAttr#p_role_attr.category,
					NewRoleBase    = calc(RoleBase, Category, '-', OldFashion, '+', NewFashion),
					mod_role_attr:reload_role_base(NewRoleBase);
				_ ->
					ignore
			end,
			case {NewRank, NewStar} > {OldRank, OldStar} of
				true ->
                    ?TRY_CATCH(mod_open_activity:hook_fb_level_event(RoleID, (NewRank-1)*10+NewStar)),
					do_log_role_fashion(RoleAttr, OldRank, NewRank, OldStar, NewStar, FashionType, 0),
					handle({Unique, ?FASHION, ?FASHION_INFO, 
						#m_fashion_info_tos{fashion_type = FashionType}, RoleID, PID, Line});
				_ ->
					ignore
			end,
			case NewRank > OldRank of 
				true ->
					mod_role_event:notify(RoleID, {?ROLE_EVENT_FASHION_GET, NewFashion}),
					common_misc:common_broadcast_other(RoleID, {FashionType, NewRank}, ?MODULE);
				false -> ignore
			end,
			case Type of
				?TYPE_MOUNTS ->
					mod_random_mission:handle_event(RoleID, ?RAMDOM_MISSION_EVENT_17),
            		hook_mission_event:hook_special_event(RoleID, ?MISSION_EVENT_MOUNT_FORSTER);
            	_ ->
					hook_mission_event:hook_special_event(RoleID, ?MISSION_EVENT_FASHION_ADD_EXP)
			end;
		{error, Reason} ->
			common_misc:unicast2(PID, ?_common_error{error_str = Reason})
	end;

handle(Msg) ->
	?ERROR_MSG("unexpected msg: ~p~n", [Msg]).

get_rankup_consume_type(?TYPE_MOUNTS,Rank) ->
	case Rank of
		?TYPE_RANKUP_RANK_2 ->
			?CONSUME_TYPE_GOLD_MOUNTS_RANKUP_2;
		?TYPE_RANKUP_RANK_5 -> 
			?CONSUME_TYPE_GOLD_MOUNTS_RANKUP_5;
		?TYPE_RANKUP_RANK_8 ->
			?CONSUME_TYPE_GOLD_MOUNTS_RANKUP_8;
		?TYPE_RANKUP_RANK_9 ->
			?CONSUME_TYPE_GOLD_MOUNTS_RANKUP_9;
		?TYPE_RANKUP_RANK_10 ->
			?CONSUME_TYPE_GOLD_MOUNTS_RANKUP_10;
		_ ->
			?CONSUME_TYPE_GOLD_FASHION_RANKUP
	end;

get_rankup_consume_type(?TYPE_FASHION,Rank) ->
	case Rank of
		?TYPE_RANKUP_RANK_2 ->
			?CONSUME_TYPE_GOLD_FASHION_RANKUP_2;
		?TYPE_RANKUP_RANK_5 -> 
			?CONSUME_TYPE_GOLD_FASHION_RANKUP_5;
		?TYPE_RANKUP_RANK_8 ->
			?CONSUME_TYPE_GOLD_FASHION_RANKUP_8;
		?TYPE_RANKUP_RANK_9 ->
			?CONSUME_TYPE_GOLD_FASHION_RANKUP_9;
		?TYPE_RANKUP_RANK_10 ->
			?CONSUME_TYPE_GOLD_FASHION_RANKUP_10;
		_ ->
			?CONSUME_TYPE_GOLD_FASHION_RANKUP
	end;

get_rankup_consume_type(?TYPE_WINGS,Rank) ->
	case Rank of
		?TYPE_RANKUP_RANK_2 ->
			?CONSUME_TYPE_GOLD_WINGS_RANKUP_2;
		?TYPE_RANKUP_RANK_5 -> 
			?CONSUME_TYPE_GOLD_WINGS_RANKUP_5;
		?TYPE_RANKUP_RANK_8 ->
			?CONSUME_TYPE_GOLD_WINGS_RANKUP_8;
		?TYPE_RANKUP_RANK_9 ->
			?CONSUME_TYPE_GOLD_WINGS_RANKUP_9;
		?TYPE_RANKUP_RANK_10 ->
			?CONSUME_TYPE_GOLD_WINGS_RANKUP_10;
		_ ->
			?CONSUME_TYPE_GOLD_FASHION_RANKUP
	end;

get_rankup_consume_type(_,_) ->
	?CONSUME_TYPE_GOLD_FASHION_RANKUP.

do_change_fashion(RoleID, RoleBase1, RoleAttr1, OldFashion, NewFashion, NewFashionID) ->
	Category = RoleAttr1#p_role_attr.category,
    change_skill_ext(RoleID, Category, NewFashion),
	{ok, RoleAttr2} = update_skin(RoleID, RoleAttr1, NewFashion#r_fashion.type, NewFashionID),
	RoleBase2 = calc(RoleBase1, Category, '-', OldFashion, '+', NewFashion),
    case NewFashion#r_fashion.type of
        ?TYPE_MOUNTS ->
        	OldMountType = RoleAttr1#p_role_attr.skin#p_skin.mounts,
        	NewMountType = RoleAttr2#p_role_attr.skin#p_skin.mounts,
        	mod_role_mount:update_last_mount(RoleID, NewMountType),
        	mod_role_mount:calc(RoleBase2, '-', OldMountType, '+', NewMountType);
        _ -> 
            RoleBase2
    end.

change_skill_ext(RoleID, Category, Fashion) when Fashion#r_fashion.type == ?TYPE_FASHION ->
    SkillID = case Category of 1 -> 1; _ -> 3 end,
	#r_skill_ext{ext_list = OldExtList} = mod_skill_ext:fetch(RoleID),
	#r_fashion{rank = Rank, star = Star} = Fashion,
	NewExtList1 = mod_skill_ext:delete2(SkillID, OldExtList, {'_', fashion}),
	NewExtList2 = mod_skill_ext:store2(SkillID, 
		NewExtList1, [{{add_effect, fashion}, cfg_fashion:effects(?TYPE_FASHION, Rank, Star)}]),
	mod_role_tab:put({r_skill_ext, RoleID}, #r_skill_ext{ext_list = NewExtList2});
change_skill_ext(RoleID, _Category, Fashion) when Fashion#r_fashion.type == ?TYPE_MOUNTS ->
    SkillID = gu_yuan_shu,
	#r_skill_ext{ext_list = OldExtList}  = mod_skill_ext:fetch(RoleID),
	#r_fashion{rank = Rank, star = Star} = Fashion,
	NewExtList1 = mod_skill_ext:delete2(SkillID, OldExtList, {'_', mount}),
	NewExtList2 = mod_skill_ext:store2(SkillID, 
		NewExtList1, [{{add_effect, mount}, cfg_fashion:effects(?TYPE_MOUNTS, Rank, Star)}]),
	mod_role_tab:put({r_skill_ext, RoleID}, #r_skill_ext{ext_list = NewExtList2});
change_skill_ext(_RoleID, _RoleAttr, _NewFashion) -> ignore.

calc(RoleBase, Category, Op1, Fashion1, Op2, Fashion2) ->
	calc(calc(RoleBase, Category, Op1, Fashion1), Category, Op2, Fashion2).

calc(RoleBase, Category, Op, Fashion) ->
	mod_role_attr:calc(RoleBase, Op, fashion_attrs(Fashion, Category)).

fashion_attrs(#r_fashion{type = FashionType, rank = Rank, star = Star}, Category) when Rank > 0 ->
	cfg_fashion:attrs(FashionType, Category, Rank, Star);
fashion_attrs(_, _) -> [].

recalc(RoleBase, RoleAttr) ->
	RoleID   = RoleBase#p_role_base.role_id,
	Category = RoleAttr#p_role_attr.category,
	lists:foldl(fun
		(Fashion, RoleBaseAcc) when is_record(Fashion, r_fashion) ->
			case fashion_id(Fashion#r_fashion.type, RoleAttr) > 0 of
				true ->
					calc(RoleBaseAcc, Category, '+', Fashion);
				false ->
					RoleBaseAcc
			end;
		(_, RoleBaseAcc) -> RoleBaseAcc
	end, RoleBase, tuple_to_list(fetch(RoleID))).

%%
%% Local Functions
%%
update_skin(RoleID, RoleAttr, Type, NewID) ->
	OldSkin = RoleAttr#p_role_attr.skin,
	NewSkin = case Type of
		?TYPE_FASHION ->
			OldSkin#p_skin{fashion = NewID};
		?TYPE_WINGS ->
			OldSkin#p_skin{fashion_wing = NewID};
        ?TYPE_MOUNTS ->
            OldSkin#p_skin{mounts = NewID}
	end,
	NewRoleAttr = RoleAttr#p_role_attr{skin = NewSkin},
	mod_role_tab:put({?role_attr, RoleID}, NewRoleAttr),
	{ok, NewRoleAttr}.

fashion_id(?TYPE_FASHION, #p_role_attr{skin = Skin})      -> Skin#p_skin.fashion;
fashion_id(?TYPE_WINGS,   #p_role_attr{skin = Skin})      -> Skin#p_skin.fashion_wing;
fashion_id(?TYPE_MOUNTS,  #p_role_attr{role_id = RoleID}) -> mod_role_mount:get_last_mount(RoleID).

add_exp(RoleID, OldFashion, AddType) ->
	Date = date(),
	#r_fashion{type = FashionType, rank = OldRank, star = OldStar, exp = OldExp} = OldFashion,
	AddExp1     = cfg_fashion:add_exp(FashionType, OldRank, OldStar),
	RemChances1 = remain_chances(RoleID, Date, OldFashion, 1),
	RemChances2 = remain_chances(RoleID, Date, OldFashion, 2),
	ExpTimes1   = case AddType of
		1 -> 1;
		2 when RemChances2 >  0 -> 4;
		2 when RemChances2 =< 0 -> 2;
		3 -> 100
	end,
	ExpTimes2  = add_exp_lucky_bonus(FashionType, AddType),
	ExpTimes3  = ExpTimes1 + ExpTimes2,
	AddExp2    = AddExp1 * ExpTimes3,
	MaxRank    = cfg_fashion:max_rank(),
	Reuslt     = if
		OldRank >= MaxRank, OldStar >= 10 ->
			{error, <<"不需要再增加经验">>};
		AddExp2 > 0 ->
			case AddType of
				1 when RemChances1 =< 0 -> {error, <<"没有剩余次数了">>};
				_ ->
					Cost = cfg_fashion:add_exp_cost(FashionType, OldRank, OldStar, AddType),
					pay_cost(RoleID, Cost, {FashionType,ExpTimes1},
						fun() -> add_exp2(FashionType, OldRank, OldStar, OldExp, AddExp2) end)
			end;
		true ->
			{error, <<"不需要再增加经验">>}
	end,
	case Reuslt of
		{error, _Reason} -> Reuslt;
		{NewRank, NewStar, NewExp} ->
			common_misc:unicast({role, RoleID}, ?_fashion_addexp{
				fashion_type = OldFashion#r_fashion.type, 
				add_type     = AddType, 
				add_exp      = AddExp2, 
				exp_times    = ExpTimes3
			}),
			Reuslt2 = OldFashion#r_fashion{rank = NewRank, 
				star = NewStar, exp = NewExp, addexp_d = Date},
			Result3 = case AddType of
				1 -> Reuslt2#r_fashion{
					exp1_c = max(0, RemChances1 - 1), exp4_c = RemChances2};
				2 -> Reuslt2#r_fashion{
					exp4_c = max(0, RemChances2 - 1), exp1_c = RemChances1};
				_ -> Reuslt2#r_fashion{
					exp1_c = RemChances1, exp4_c = RemChances2}
			end,
			update(RoleID, Result3),
			Result3
	end.

add_exp2(FashionType, OldRank, OldStar, OldExp, AddExp) ->
	MaxExp = cfg_fashion:max_exp(FashionType, OldRank, OldStar),
	NewExp = OldExp + AddExp,
	if
		NewExp >= MaxExp ->
			NewRank = if
				OldStar >= 9 -> OldRank + 1;
				true         -> OldRank
			end,
			NewStar = if
				OldStar >= 9 -> 0;
				true         -> OldStar + 1
			end,
			case NewRank > cfg_fashion:max_rank() of
				true ->
					{cfg_fashion:max_rank(), 10, 0};
				_ ->
					add_exp2(FashionType, NewRank, NewStar, 0, AddExp - MaxExp + OldExp)
			end;
		true ->
			{OldRank, OldStar, NewExp}
	end.

remain_chances(_RoleID, Date, #r_fashion{exp1_c = Chances, addexp_d = Date}, 1) -> 
	Chances;
remain_chances(_RoleID, Date, #r_fashion{exp4_c = Chances, addexp_d = Date}, 2) -> 
	Chances;
remain_chances(RoleID, _Date, _, 1) -> 
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	cfg_fashion:max_1exp_chances(RoleAttr#p_role_attr.level, VipLevel);
remain_chances(RoleID, _Date, _, 2) -> 
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	cfg_fashion:max_4exp_chances(RoleAttr#p_role_attr.level, VipLevel);
remain_chances(_, _, _, _) -> undefined.

pay_cost(RoleID, {GoldType, Gold},{FashionType,ExpTimes1}, Fun) when GoldType == gold_any; GoldType == gold_unbind ->
	LogType = get_fashion_addexp_consume_type(FashionType,ExpTimes1),
	case common_bag2:use_money(RoleID, GoldType, Gold, LogType) of
		true -> Fun();
		{error, Reason} -> {error, Reason}
	end;

pay_cost(RoleID, {ItemType, ItemNum},_ExpTimes1, Fun) when is_integer(ItemType), ItemNum > 0 ->
	case common_transaction:transaction(fun() -> 
			mod_bag:decrease_goods_by_typeid(RoleID, ItemType, ItemNum)
		end) of
		{_, {ok, UpdateList, DelList}} ->
	        common_misc:update_goods_notify({role,RoleID}, UpdateList++DelList),
			common_item_logger:log(RoleID, ItemType, ItemNum, true, ?LOG_ITEM_TYPE_LOST_FASHION_ADDEXP),
			Fun();
		{_, {bag_error, num_not_enough}} ->
			{error, <<"道具个数不足">>};
		_ ->
			{error, <<"系统错误">>}
	end.


get_fashion_addexp_consume_type(?TYPE_FASHION,ExpTimes1) ->
	case ExpTimes1 of
		?TYPE_ADDEXP_TIMES_2 ->
			?CONSUME_TYPE_GOLD_FASHION_ADDEXP_2;
		?TYPE_ADDEXP_TIMES_4 ->
			?CONSUME_TYPE_GOLD_FASHION_ADDEXP_4;
		?TYPE_ADDEXP_TIMES_100 ->
			?CONSUME_TYPE_GOLD_FASHION_ADDEXP_50;
		_ ->
			?CONSUME_TYPE_GOLD_FASHION_ADDEXP
	end;

get_fashion_addexp_consume_type(?TYPE_MOUNTS,ExpTimes1) ->
	case ExpTimes1 of
		?TYPE_ADDEXP_TIMES_2 ->
			?CONSUME_TYPE_GOLD_MOUNTS_ADDEXP_2;
		?TYPE_ADDEXP_TIMES_4 ->
			?CONSUME_TYPE_GOLD_MOUNTS_ADDEXP_4;
		?TYPE_ADDEXP_TIMES_100 ->
			?CONSUME_TYPE_GOLD_MOUNTS_ADDEXP_50;
		_ ->
			?CONSUME_TYPE_GOLD_FASHION_ADDEXP
	end;

get_fashion_addexp_consume_type(?TYPE_WINGS,ExpTimes1) ->
	case ExpTimes1 of
		?TYPE_ADDEXP_TIMES_2 ->
			?CONSUME_TYPE_GOLD_WINGS_ADDEXP_2;
		?TYPE_ADDEXP_TIMES_4 ->
			?CONSUME_TYPE_GOLD_WINGS_ADDEXP_4;
		?TYPE_ADDEXP_TIMES_100 ->
			?CONSUME_TYPE_GOLD_WINGS_ADDEXP_50;
		_ ->
			?CONSUME_TYPE_GOLD_FASHION_ADDEXP
	end;

get_fashion_addexp_consume_type(_,_) ->
	?CONSUME_TYPE_GOLD_FASHION_ADDEXP.
	

add_exp_lucky_bonus(FashionType, AddType) ->
	WeightSum = lists:sum([W||{W, _B} <- cfg_fashion:exp_bonus(FashionType, AddType)]),
	if
		WeightSum > 0 ->
			Random      = random:uniform(WeightSum),
			{ok, Bonus} = lists:foldl(fun
				(_, {ok, B}) -> 
					{ok, B};
				({W, B}, Acc) when Acc + W >= Random -> 
					{ok, B};
				({W, _B}, Acc) -> 
					Acc + W
			end, 0, cfg_fashion:exp_bonus(FashionType, AddType)),
			Bonus;
		true ->
			0
	end.

%%[1倍经验, 需要升星令个数, 剩余使用升星令次数, 总共可使用升星次数, 2倍元宝，剩余4倍次数, 总共4倍次数, 100倍元宝].
exp_tips(RoleAttr, FashionType, Rank, Star, Exp1C, Exp4C, AddExpDate) ->
	Date       = date(),
	RoleID     = RoleAttr#p_role_attr.role_id,
	RoleLevel  = RoleAttr#p_role_attr.level,
	VipLevel   = mod_vip:get_role_vip_level(RoleID),
	Exp        = cfg_fashion:add_exp(FashionType, Rank, Star),
	{_, Cost1} = cfg_fashion:add_exp_cost(FashionType, Rank, Star, 1),
	{_, Cost2} = cfg_fashion:add_exp_cost(FashionType, Rank, Star, 2),
	{_, Cost3} = cfg_fashion:add_exp_cost(FashionType, Rank, Star, 3),
	MaxExp1C   = cfg_fashion:max_1exp_chances(RoleLevel, VipLevel),
	RemExp1C   = case Date == AddExpDate of true -> Exp1C; _ -> MaxExp1C end,
	MaxExp4C   = cfg_fashion:max_4exp_chances(RoleLevel, VipLevel),
	RemExp4C   = case Date == AddExpDate of true -> Exp4C; _ -> MaxExp4C end,
	[Exp, Cost1, RemExp1C, MaxExp1C, Cost2, RemExp4C, MaxExp4C, Cost3].


do_log_role_fashion(RoleAttr,OldRank,NewRank,OldStar,NewStar,FashionType,Optype)->
	#p_role_attr{role_id=RoleID,role_name=RoleName} = RoleAttr,
	FashionEvoleRecord = #r_fashion_evolve_log{
							role_id   = RoleID,
							role_name = RoleName,
							old_rank  = OldRank,
							rank      = NewRank,
							old_star  = OldStar,
							star      = NewStar,
							fashion_type = FashionType,
							time      = common_tool:now(),
							type      = Optype
						},
	common_general_log_server:log_fashion_evolve(FashionEvoleRecord).

get("/info" ++ _, Req, _) ->
	?TRY_CATCH(do_get(Req)).

gen_role_fashion_json(Type1,Rec1) ->
	#r_fashion{type     = Type1,
			   rank     = Rank1,
			   star     = Star1,
			   exp      = Exp1,
			   exp1_c   = Exp1_c1,
			   exp4_c   = Exp4_c1,
			   addexp_d = Addexp_d1_
			  } = Rec1,
	Addexp_d1 = 
		case Addexp_d1_ of
			undefined ->
				0;
			_ ->								
				common_time:date_to_time(Addexp_d1_)
		end,
	[
	 {type,Type1},{rank,Rank1},
	 {star,Star1},{exp,Exp1},
	 {exp1_c,Exp1_c1},{exp4_c,Exp4_c1},
	 {addexp_d,Addexp_d1},
	 {skin,cfg_fashion:id(Type1, Rank1)}
	].

gen_all_fashion_json(RoleAttr,FashionJson,WingesJson,RoleMoutJson) ->
	[
	 {result, succ},
	 {fashion,FashionJson},
	 {wings,WingesJson},
	 {mounts,RoleMoutJson},
	 {skin_fashion,RoleAttr#p_role_attr.skin#p_skin.fashion},
	 {skin_wings,RoleAttr#p_role_attr.skin#p_skin.fashion_wing},
	 {skin_mounts,RoleAttr#p_role_attr.skin#p_skin.mounts}
	].

do_get(Req) ->
	Get = Req:parse_qs(),
	RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
	case db:dirty_read(db_role_misc, RoleID) of
		[RoleMisc] ->
			case lists:keyfind(r_role_fashion, 1, RoleMisc#r_role_misc.tuples) of
				false ->
					mgeeweb_tool:return_json_error(Req);
				#r_role_fashion{fashion=Rec1,wings=Rec2,mounts=Rec3} ->
					case db:dirty_read(db_role_attr,RoleID) of
						[] ->
							mgeeweb_tool:return_json_error(Req);
						[RoleAttr] ->
							FashionJson = gen_role_fashion_json(1,Rec1),
							WingesJson = gen_role_fashion_json(2,Rec2),
							RoleMoutJson = gen_role_fashion_json(3,Rec3),
							AllFashionJson = gen_all_fashion_json(RoleAttr,FashionJson,WingesJson,RoleMoutJson),
							mgeeweb_tool:return_json(AllFashionJson,Req)
					end
			end;
		_ ->
			mgeeweb_tool:return_json_error(Req)
	end.
