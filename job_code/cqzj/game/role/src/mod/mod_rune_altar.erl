%% Author: lijianjun
%% Created: 2013-7-18
%% Description: 符坛模块
-module(mod_rune_altar).
-include("mgeer.hrl").
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([handle/1,handle/2]).
-export([init/2,delete/1,get_empty_bag_num/1,
		 recalc/2,change_rune_buff/3,pop_same_rune/1,
		 check_is_same_attr_rune/2,gen_new_rune/2,
		 set_role_rune_bag_info/2,do_notify_altar_info/1,
		 gm_clear_bag/1, gm_get_rune/3,get_loaded/1, get_rune_colour/1,
		 gm_get_rune/2
		]).

-define(ERR_RUNE_ALTAR_BAG_NUM_NOT_ENOUGH,10001).
-define(ERR_RUNE_ALTAR_DRAWING_FAILD,10002).
-define(ERR_RUNE_ALTAR_SWALLOW_NOT_SAME_RUNE,10003).
-define(ERR_RUNE_ALTAR_LOAD_POS_EMPTY,10004).
-define(ERR_RUNE_ALTAR_GOLD_NOT_ENOUGH,10005).
-define(ERR_RUNE_ALTAR_SILVER_NOT_ENOUGH,10006).
-define(ERR_RUNE_ALTAR_LOAD_ATTACK_NOT_ENOUGH,10007).
-define(ERR_RUNE_ALTAR_LOAD_HP_NOT_ENOUGH,10008).
-define(ERR_RUNE_ALTAR_LOAD_DEF_NOT_ENOUGH,10009).

-define(TYPE_RUNE_ATTACK,1).
-define(TYPE_RUNE_HP,2).
-define(TYPE_RUNE_DEF,3).

-define(TYPE_RUNE_SILVER_DRAWING,0).
-define(TYPE_RUNE_GOLD_DRAWING,1).

-define(TYPE_RUNE_LOAD,0).
-define(TYPE_RUNE_UNLOAD,1).
%%
%% API Functions
%%
handle(Msg,_State) ->
	handle(Msg).
handle({_,?RUNE_ALTAR,?RUNE_ALTAR_DRAWING,_,_,_,_}=Msg)->
	do_altar_drawing(Msg);

handle({_,?RUNE_ALTAR,?RUNE_ALTAR_SWALLOW,_,_,_,_}=Msg)->
	do_rule_swallow(Msg);	%% 吞噬或是移动符文

handle({_,?RUNE_ALTAR,?RUNE_ALTAR_ONEKEY_SWALLOW,_,_,_,_}=Msg)->
	do_rule_onkey_swallow(Msg);

handle({_,?RUNE_ALTAR,?RUNE_ALTAR_LOAD,_,_,_,_}=Msg)->
	do_rule_load(Msg);

handle({_,?RUNE_ALTAR,?RUNE_ALTAR_INFO,_,_,_,_}=Msg)->
	do_altar_info(Msg).



%%
%% Local Functions
%%


init(RoleID, Rec) when is_record(Rec, r_role_rune_altar) ->
	mod_role_tab:put({?role_rune_altar, RoleID}, Rec);
init(RoleID, _Rec) ->
	mod_role_tab:put({?role_rune_altar, RoleID}, #r_role_rune_altar{}).
delete(RoleID) ->
	mod_role_tab:erase({?role_rune_altar, RoleID}).
do_rule_load({Unique,Module,Method,DataIn,RoleID,PID,_Line}) ->
	case catch check_rule_load(RoleID,DataIn) of
		{ok,Optype,OldRoleRuneRec,BagRuneInfo,NotchRuneInfo,BagPos,NotchPos} ->
			case Optype of
				?TYPE_RUNE_LOAD ->
					R = do_rule_load2(RoleID,BagRuneInfo,NotchRuneInfo,BagPos,NotchPos);	
				?TYPE_RUNE_UNLOAD ->
					R = do_rule_unload(RoleID,BagRuneInfo,NotchRuneInfo,BagPos,NotchPos)
				end,
			{ok,NewRoleRuneRec} = get_role_altar_info(RoleID),
			change_rune_buff(RoleID,OldRoleRuneRec,NewRoleRuneRec),
			{ok,RoleBase} = mod_map_role:get_role_base(RoleID),
			NewRoleBase    = mod_role_attr:calc(RoleBase,'-', calc_rune_attr(RoleID,OldRoleRuneRec,unload), '+', calc_rune_attr(RoleID,NewRoleRuneRec,load)),
			mod_role_attr:reload_role_base(NewRoleBase);
		{error,ErrCode} ->
			R = #m_rune_altar_load_toc{err_code = ErrCode};
		{error,ErrCode,_} ->
			R = #m_rune_altar_load_toc{err_code = ErrCode}
	end,
	?UNICAST_TOC(R).


change_rune_buff(RoleID,OldRuneAltarRec,NewRuneAltarRec) ->
	Fun1 = fun(#p_rune{typeid=TypeID}) -> 
				   {ok, #p_role_attr{category= Category}} = mod_map_role:get_role_attr(RoleID),
				   case catch cfg_rune_altar:rune_skill_buff(Category, TypeID) of
					   {error,not_found} ->
						   ignore;
					   {SkillID,_} ->
						   mod_skill_ext:delete(RoleID, SkillID, {'_', rune})
				   end
		   end,
	lists:foreach(Fun1, OldRuneAltarRec#r_role_rune_altar.rune_notch),
	Fun2 = fun(#p_rune{typeid=TypeID}) -> 
				   {ok, #p_role_attr{category= Category}} = mod_map_role:get_role_attr(RoleID),
				  case cfg_rune_altar:rune_skill_effect(Category, TypeID) of
					   {error,not_found} ->
						   ignore;
					   SkillID1  ->
						   {_,_,RuneLevel,_,_,_,_} = cfg_rune_altar:get_rune_prop(TypeID),
						   case  cfg_rune_altar:rune_effect(TypeID, RuneLevel) of
							   {error,not_found} ->
								   ignore;
							   Effect ->
								   mod_skill_ext:store(RoleID, SkillID1, [{{add_effect, rune}, Effect}])
						   end
				   end,
				   case cfg_rune_altar:rune_skill_buff(Category, TypeID) of
					   {error,not_found} ->
						   ignore;
					   {SkillID,BuffID} ->
						   [Buff] = common_config_dyn:find(buffs, BuffID),
						   case mod_skill_ext:fetch(RoleID,SkillID) of
							   [] ->
								   mod_skill_ext:store(RoleID, SkillID, [{{add_buff, rune}, [Buff]}]);
							   [{{add_buff, rune}, OldBuff}] ->
								   mod_skill_ext:store(RoleID, SkillID, [{{add_buff, rune}, [Buff|OldBuff]}])
						   end
				   end
		   end,
	lists:foreach(Fun2, NewRuneAltarRec#r_role_rune_altar.rune_notch).

do_rule_load2(RoleID,BagRuneInfo,NotchRuneInfo,BagPos,NotchPos) ->
		case get_role_altar_info(RoleID) of
		{ok,RoleRuneRec} ->
			NewBagRuneInfo = BagRuneInfo#p_rune{pos = NotchPos},
			NewRuneNotch = lists:keystore(NotchPos,#p_rune.pos, RoleRuneRec#r_role_rune_altar.rune_notch, NewBagRuneInfo),
			case NotchRuneInfo of
				null ->
					NewNotchRuneInfo = #p_rune{typeid=-1,pos = BagPos},
					NewRuneBag = lists:keydelete(BagPos,#p_rune.pos, RoleRuneRec#r_role_rune_altar.rune_bag);
				_ ->
					NewNotchRuneInfo = NotchRuneInfo#p_rune{pos = BagPos},
					NewRuneBag = lists:keystore(BagPos,#p_rune.pos, RoleRuneRec#r_role_rune_altar.rune_bag, NewNotchRuneInfo)
			end,
			NewRoleRuneRec =  RoleRuneRec#r_role_rune_altar{rune_notch=NewRuneNotch,rune_bag=NewRuneBag},
			mod_role_tab:put({?role_rune_altar, RoleID}, NewRoleRuneRec),
			hook_load(RoleID, NewBagRuneInfo),
			#m_rune_altar_load_toc{bag_rune_info=gen_attr_rune(NewNotchRuneInfo),notch_rune_info=gen_attr_rune(NewBagRuneInfo)};
		_ ->
			#m_rune_altar_load_toc{err_code = ?ERR_SYS_ERR}
	end.

hook_load(RoleID, NewBagRuneInfo) ->
	ToRuneColor = get_rune_colour(NewBagRuneInfo#p_rune.typeid),
	catch mod_role_event:notify(RoleID, {?ROLE_EVENT_FU_WEN, {NewBagRuneInfo#p_rune.level, ToRuneColor}}).

get_rune_colour(RuneId) ->
	[#p_equip_base_info{colour = ToRuneColor}] = common_config_dyn:find_equip(RuneId),
	ToRuneColor.

get_loaded(RoleID) ->
	case get_role_altar_info(RoleID) of
		{ok,RoleRuneRec} ->
			RoleRuneRec#r_role_rune_altar.rune_notch;
		_ -> []
	end.

do_rule_unload(RoleID,_BagRuneInfo,NotchRuneInfo,BagPos,NotchPos) ->
	case get_role_altar_info(RoleID) of
		{ok,RoleRuneRec} ->
			NewNotchRuneInfo = NotchRuneInfo#p_rune{pos=BagPos},
			NewRuneBag = lists:keystore(BagPos,#p_rune.pos, RoleRuneRec#r_role_rune_altar.rune_bag, NewNotchRuneInfo),
			NewRuneNotch = lists:keydelete(NotchPos,#p_rune.pos,  RoleRuneRec#r_role_rune_altar.rune_notch),
			NewRoleRuneRec =  RoleRuneRec#r_role_rune_altar{rune_notch=NewRuneNotch,rune_bag=NewRuneBag},
			mod_role_tab:put({?role_rune_altar, RoleID}, NewRoleRuneRec),
			#m_rune_altar_load_toc{bag_rune_info=gen_attr_rune(NewNotchRuneInfo),notch_rune_info=gen_attr_rune(NotchRuneInfo#p_rune{typeid=-1})};
		_ ->
			#m_rune_altar_load_toc{err_code = ?ERR_SYS_ERR}
	end.

		
check_rule_load(RoleID,DataIn) ->
	#m_rune_altar_load_tos{op_type = Optype,bag_pos = BagPos ,notch_pos = NotchPos} = DataIn,
	case get_role_altar_info(RoleID) of
		{ok,RoleRuneRec} ->
			case lists:keyfind(NotchPos, #p_rune.pos, RoleRuneRec#r_role_rune_altar.rune_notch) of
				false ->
					if
						Optype =:= 1 ->
							?THROW_ERR(?ERR_SYS_ERR);
						true ->
							ignore
					end,
					NotchRuneInfo = null;
				NotchRuneInfo ->
					ignore
			end,
			case lists:keyfind(BagPos, #p_rune.pos, RoleRuneRec#r_role_rune_altar.rune_bag) of
				false ->
					if
						Optype =:= 0 ->
							?THROW_ERR(?ERR_SYS_ERR);
						true ->
							ignore
					end,
					BagRuneInfo = null;
				BagRuneInfo ->
					if
						Optype =:= 0 -> 
							
							case check_rune_attr(RoleID,BagRuneInfo#p_rune.typeid) of
								{error,?TYPE_RUNE_ATTACK,_} ->
									?THROW_ERR(?ERR_RUNE_ALTAR_LOAD_ATTACK_NOT_ENOUGH);
								{error,?TYPE_RUNE_HP,_} ->
									?THROW_ERR(?ERR_RUNE_ALTAR_LOAD_HP_NOT_ENOUGH);
								{error,?TYPE_RUNE_DEF,_} ->
									?THROW_ERR(?ERR_RUNE_ALTAR_LOAD_DEF_NOT_ENOUGH);
								ok ->
									ignore
							end;
						true ->
							ignore
					end
			end,
			{ok,Optype,RoleRuneRec,BagRuneInfo,NotchRuneInfo,BagPos,NotchPos};
		_ ->
			?THROW_ERR(?ERR_SYS_ERR)
	end.

pop_same_rune(RoleID) ->
	case get_role_altar_info(RoleID) of
		{ok,RoleAltarRec} ->
			NotchList = RoleAltarRec#r_role_rune_altar.rune_bag,
			Fun1 = fun(#p_rune{typeid=SrcTypeID,pos=SrcPos} = SrcRune) ->
						   RetList = lists:filter(fun(#p_rune{typeid=ToTypeID,pos=ToPos}) -> 
														  SrcPos =/= ToPos andalso 
															  check_is_same_attr_rune(SrcTypeID,ToTypeID)
												  end, NotchList),
						   case length(RetList) > 0 of
							   true ->
								   throw({ok,SrcRune,lists:last(RetList)});
							   _ ->
								   {error,not_found}
						   end
				   end,
			catch lists:foreach(Fun1, NotchList);
		
		_ ->
			{error,not_found}
	end.


do_rule_onkey_swallow({Unique,Module,Method,_DataIn,RoleID,PID,_Line}) ->
	GainExp = do_rule_onkey_swallow2(RoleID),
	do_notify_altar_info(RoleID),
	R = #m_rune_altar_onekey_swallow_toc{err_code=0,gain_exp=GainExp},
	?UNICAST_TOC(R).
do_rule_onkey_swallow2(RoleID) ->
	do_rule_onkey_swallow2(RoleID, 0).
do_rule_onkey_swallow2(RoleID, GainExp) ->
	case pop_same_rune(RoleID) of
		{ok,SrcRune,ToRune} ->
			do_rune_swallow3(RoleID,SrcRune,ToRune),
			case is_record(SrcRune, p_rune) of
				true  -> GainExp1 = GainExp + SrcRune#p_rune.exp;
				false -> GainExp1 = GainExp
			end,
			do_rule_onkey_swallow2(RoleID, GainExp1);
		_ ->
			GainExp
	end.	
do_rule_swallow({Unique,Module,Method,DataIn,RoleID,PID,_Line}) ->
	case catch check_rule_swallow(RoleID,DataIn) of
		{ok,SrcRune,ToRune,IsSameType,SrcPos,ToPos} ->
			R = do_rune_swallow2(RoleID,SrcRune,ToRune,IsSameType,SrcPos,ToPos);
		{error,ErrCode,_} ->
			R = #m_rune_altar_swallow_toc{err_code = ErrCode}
	end,
	?UNICAST_TOC(R).

add_rune_exp(CurrTypeID,SumExp) ->
	{_,CurrMaxExp,CurrLevel,_,NextTypeID,_,_} = cfg_rune_altar:get_rune_prop(CurrTypeID),
	case NextTypeID > 0 of
		true ->
			{_,NextMaxExp,NextLevel,_,_,_,_} = cfg_rune_altar:get_rune_prop(NextTypeID),
			if
				SumExp < CurrMaxExp ->
					{SumExp,CurrLevel,CurrTypeID};
				SumExp >=  CurrMaxExp andalso SumExp =< NextMaxExp ->
					{SumExp - CurrMaxExp ,NextLevel,NextTypeID};
				true ->
					add_rune_exp(NextTypeID,SumExp)
			end;
		_ ->
			CurrExp1 = CurrMaxExp - SumExp,
			{erlang:max(CurrMaxExp, CurrExp1),CurrLevel,CurrTypeID}
	end.

get_rune_acc_exp(BeSwallowTypeID,AccIn) ->
	{_,_,Level,PrevTypeID,_,_,_} = cfg_rune_altar:get_rune_prop(BeSwallowTypeID),
	if
		PrevTypeID > 0 andalso Level =:= 1 ->
			AccIn;
		PrevTypeID > 0 ->
			{_,PrevExp,_,_,_,_,_} = cfg_rune_altar:get_rune_prop(PrevTypeID),
			get_rune_acc_exp(PrevTypeID,AccIn + PrevExp);

		true ->
			AccIn
	end.
	
do_rune_swallow3(RoleID,SrcRune,ToRune) ->
			NewExp = SrcRune#p_rune.exp + ToRune#p_rune.exp,
			[#p_equip_base_info{typeid=SrcTypeID,colour = SrcRuneColor}] = 
								  common_config_dyn:find_equip(SrcRune#p_rune.typeid),
			[#p_equip_base_info{typeid=ToTypeID,colour = ToRuneColor}] = 
								  common_config_dyn:find_equip(ToRune#p_rune.typeid),
			
			if SrcRuneColor > ToRuneColor ->
				   BeSwallowExp = ToRune#p_rune.exp,
				   BeSwallowTypeID = ToTypeID,
				   NewTypeID = SrcTypeID;
			   SrcRuneColor =:= ToRuneColor ->
				   case SrcRune#p_rune.level > ToRune#p_rune.level of
					   true ->
						   BeSwallowExp = ToRune#p_rune.exp,
						   BeSwallowTypeID = ToTypeID,
						   NewTypeID = SrcTypeID;
					   _ ->
						   BeSwallowExp = SrcRune#p_rune.exp,
						   BeSwallowTypeID = SrcTypeID,
						   NewTypeID = ToTypeID
				   end;
			   true ->
				   BeSwallowExp = SrcRune#p_rune.exp,
				   BeSwallowTypeID = SrcTypeID,
				   NewTypeID = ToTypeID
			end,
			TotalExp = get_rune_acc_exp(BeSwallowTypeID,0),
				
			{NewExp1,NewLevel1,NewTypeID1} = add_rune_exp(NewTypeID,NewExp + TotalExp),
			NewRune = SrcRune#p_rune{pos = ToRune#p_rune.pos,typeid = NewTypeID1,exp = NewExp1,level = NewLevel1},
			
			{ok,RoleRuneRec} = get_role_altar_info(RoleID),
			NewRoleRuneBags = 
							lists:keydelete(
							  SrcRune#p_rune.pos, #p_rune.pos,
							  RoleRuneRec#r_role_rune_altar.rune_bag
						),
			NewRoleRuneRec = RoleRuneRec#r_role_rune_altar{rune_bag = NewRoleRuneBags},
			mod_role_tab:put({?role_rune_altar, RoleID}, NewRoleRuneRec),
			set_role_rune_bag_info(RoleID,NewRune),
			{ok,TotalExp,BeSwallowExp,NewRune,NewLevel1, ToRuneColor}.

do_rune_swallow2(RoleID,SrcRune,ToRune,IsSameType,_SrcPos,ToPos) ->
	case IsSameType of
		true ->
			{ok,TotalExp,BeSwallowExp,NewRune,_NewLevel1, _ToRuneColor} = do_rune_swallow3(RoleID,SrcRune,ToRune),
			
			R = #m_rune_altar_swallow_toc{
					add_exp = TotalExp + BeSwallowExp,
					src_rune_info = gen_attr_rune(NewRune),
					to_rune_info = #p_rune{pos=SrcRune#p_rune.pos,typeid=-1}
			};
		_ ->
			{ok,RoleRuneRec} = get_role_altar_info(RoleID),
			if
				ToRune =:= null ->
					NewRoleRuneBags = 
							lists:keydelete(
							  SrcRune#p_rune.pos, #p_rune.pos,
							  RoleRuneRec#r_role_rune_altar.rune_bag
						),
					NewRoleRuneBags1 = 
							lists:keystore(
							  ToPos, #p_rune.pos,
							  NewRoleRuneBags,
							  SrcRune#p_rune{pos = ToPos}
						),
					SrcRuneInfo = #p_rune{pos = SrcRune#p_rune.pos,typeid = -1};
				 true ->
					NewRoleRuneBags = 
							lists:keystore(
							  SrcRune#p_rune.pos, #p_rune.pos,
							  RoleRuneRec#r_role_rune_altar.rune_bag,
							  ToRune#p_rune{pos = SrcRune#p_rune.pos}
						),
					NewRoleRuneBags1 = 
							lists:keystore(
							  ToRune#p_rune.pos, #p_rune.pos,
							  NewRoleRuneBags,
							  SrcRune#p_rune{pos = ToRune#p_rune.pos}
						),
					SrcRuneInfo = gen_attr_rune(ToRune#p_rune{pos = SrcRune#p_rune.pos})
			end,
			NewRoleRuneRec = RoleRuneRec#r_role_rune_altar{rune_bag = NewRoleRuneBags1},
			mod_role_tab:put({?role_rune_altar, RoleID}, NewRoleRuneRec),
			R = #m_rune_altar_swallow_toc{
					src_rune_info = gen_attr_rune(SrcRuneInfo),
					to_rune_info  = gen_attr_rune(SrcRune#p_rune{pos = ToPos})	 
			}
	end,
	R.
	

			
check_rule_swallow(RoleID,DataIn) ->
	#m_rune_altar_swallow_tos{src_pos=SrcPos,to_pos=ToPos} = DataIn,
	case get_role_bag_pos_rune(RoleID,SrcPos) of
		{ok,SrcRune} ->
			ignore;
		_ ->
			SrcRune = null,
			?THROW_ERR(?ERR_SYS_ERR)
	end,
	case  get_role_bag_pos_rune(RoleID,ToPos) of
		{ok,ToRune} ->
			ingore;
		_ ->
			ToRune= null
	end,

	if
		ToRune =/= null ->
			IsSameType = true;
				% check_is_same_attr_rune(SrcRune#p_rune.typeid,ToRune#p_rune.typeid);
		true ->
			IsSameType = false
	end,
	
	{ok,SrcRune,ToRune,IsSameType,SrcPos,ToPos}.

check_is_same_attr_rune(SrcTypeID,ToTypeID) ->
	{_,_,_,_,_,SrcType,SrcAttrs} = 
		cfg_rune_altar:get_rune_prop(SrcTypeID),	
	{_,_,_,_,_,ToType,ToAttrs} = 
		cfg_rune_altar:get_rune_prop(ToTypeID),
	SrcTupSize = erlang:tuple_size(SrcAttrs),
	ToTupSize = erlang:tuple_size(ToAttrs),
	Fun = fun(I) -> element(I, SrcAttrs) > 0  andalso  element(I, ToAttrs) > 0 end,
	if
		SrcType =/= ToType ->
			false;
		SrcTupSize =:= ToTupSize ->
			L = lists:filter(Fun, lists:seq(1, ToTupSize)),
			length(L) > 0;
		true ->
			false
	end.



do_altar_info({_,?RUNE_ALTAR,?RUNE_ALTAR_INFO,_DataIn,RoleID,_,_Line}) ->
	do_notify_altar_info(RoleID).

do_notify_altar_info(RoleID) ->
	case get_role_altar_info(RoleID) of
		{ok,RuneAltarRec} ->
			case common_tool:check_if_same_day(common_tool:now(), RuneAltarRec#r_role_rune_altar.last_draw_time) of
				false ->
					DrawTimes = 0,
					NewRuneAltarRec = RuneAltarRec#r_role_rune_altar{
												draw_times = 0,
												last_draw_time = 0
										},
					mod_role_tab:put({?role_rune_altar, RoleID},NewRuneAltarRec);
				_ ->
					DrawTimes = RuneAltarRec#r_role_rune_altar.draw_times
			end,
			NewRuneBags = 
				lists:foldl(fun(R,AccIn) -> 
									[gen_attr_rune(R)|AccIn]
							end, [], RuneAltarRec#r_role_rune_altar.rune_bag),
			NewRuneNotch = 
				lists:foldl(fun(R,AccIn) -> 
									[gen_attr_rune(R)|AccIn]
							end, [], RuneAltarRec#r_role_rune_altar.rune_notch),	
			Notches = cfg_rune_altar:get_notch(get_nuqi_skill_shap(RoleID)),
			{NextExp} = cfg_rune_altar:get_altar(RuneAltarRec#r_role_rune_altar.level),
			PruneAltar = #p_rune_altar{
									   rune_bag = NewRuneBags,
									   rune_notch = NewRuneNotch,
									   level = RuneAltarRec#r_role_rune_altar.level,
									   exp = RuneAltarRec#r_role_rune_altar.exp,
									   next_exp = NextExp,
									   score = RuneAltarRec#r_role_rune_altar.score,
									   notches = Notches,
									   draw_times = DrawTimes
									  },
			R = #m_rune_altar_info_toc{rune_altar = PruneAltar};
		_ ->
			R = #m_rune_altar_info_toc{err_code = ?ERR_SYS_ERR}
	end,
	common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?RUNE_ALTAR, ?RUNE_ALTAR_INFO, R).

do_altar_drawing({Unique,Module,Method,DataIn,RoleID,PID,_Line}) ->
	#m_rune_altar_drawing_tos{draw_type = DrawType} = DataIn,
	case catch check_do_altar_drawing(RoleID,DrawType) of
		{ok,NewRune,RoleRuneRec} ->
			R = do_altar_drawing2(RoleID,NewRune,DrawType,RoleRuneRec),
			?UNICAST_TOC(R);
		{error,ErrCode,_} ->
			?UNICAST_TOC(#m_rune_altar_drawing_toc{err_code = ErrCode})
	end.

do_altar_drawing2(RoleID, NewRune,DrawType,RoleRuneRec) -> 
	Fun = 
		fun() ->
				case DrawType =:= ?TYPE_RUNE_SILVER_DRAWING of
					true ->
						if 
							RoleRuneRec#r_role_rune_altar.draw_times >= 3 ->
								
								{ok,#p_role_attr{level = RoleLevel}} = 
									mod_map_role:get_role_attr(RoleID),
								MoneyType = silver_unbind,
								DeductMoney = 
									cfg_rune_altar:get_drawing_cost_silver(RoleRuneRec#r_role_rune_altar.draw_times+1,RoleLevel),
								{ok,NewRoleAttr1} = common_bag2:t_deduct_money(
													  MoneyType, DeductMoney, RoleID,
													  ?CONSUME_TYPE_SILVER_RUNE_ALTAR_DRAW,
													  NewRune#p_rune.typeid,1
													);
							true ->
								NewRoleAttr1 = null,
								DeductMoney = 0
						end;
					_ ->
						{MoneyType,DeductMoney} = 
							cfg_rune_altar:get_gold_draw_money(),
						{ok,NewRoleAttr1} = common_bag2:t_deduct_money(
											  MoneyType, DeductMoney, RoleID,
											  ?CONSUME_TYPE_RUNE_ALTAR_DRAWING,
											  NewRune#p_rune.typeid,1
											)
				end,
				AddAltarExp = cfg_rune_altar:get_draw_exp(DrawType),
				case t_drawing_return(RoleID,DrawType) of
					{true,0} ->
						{ok,NewRoleAttr1,0,AddAltarExp,DeductMoney};
					{false,GainMoney,NewRoleAttr2} ->
						{ok,NewRoleAttr2,GainMoney,AddAltarExp,DeductMoney}
				end

		end,
	case catch common_transaction:t(Fun) of
		{atomic,{ok,NewRoleAttr,GainMoney,AddAltarExp,DeductMoney}} ->
			AddDrawTimes = 
				case DrawType =:= ?TYPE_RUNE_SILVER_DRAWING of
					true ->
						1;
					_ ->
						0
				end,
			{ok,IsLvUp,NewExp1,NewLevel,Score,MaxExp,Notches,DrawTimes} = 
				add_altar_exp(RoleID,AddAltarExp,AddDrawTimes),
			if NewRoleAttr =/= null ->
				   common_misc:send_role_gold_silver_change(RoleID, NewRoleAttr);
			   true ->
				   ignore
			end,
			if 
				DeductMoney > 0 ->
					if
						DrawType =:= ?TYPE_RUNE_SILVER_DRAWING ->
							Text = lists:concat(["画符消耗钱币",DeductMoney]);
						true ->
							Text = lists:concat(["画符消耗元宝",DeductMoney])
					end,
					?ROLE_SYSTEM_BROADCAST(RoleID,Text);
				true ->
					ignore
			end,
			case GainMoney > 0 of
				true ->
					?ROLE_SYSTEM_BROADCAST(RoleID,lists:concat(["画符失败返还钱币",GainMoney])),
					#m_rune_altar_drawing_toc{
						err_code = ?ERR_RUNE_ALTAR_DRAWING_FAILD,
						return_money = GainMoney,
						draw_times	= DrawTimes
					};
				_ ->
					set_role_rune_bag_info(RoleID,NewRune),
					#m_rune_altar_drawing_toc{
						rune_info = gen_attr_rune(NewRune),
						altar_level = NewLevel,
						altar_exp = NewExp1,
						altar_score = Score,
						altar_max_exp = MaxExp,
						altar_notches = Notches,
						altar_lv_up = IsLvUp,
						draw_times	= DrawTimes
					}
			end;
		{abort,_} ->
			#m_rune_altar_drawing_toc{err_code = ?ERR_SYS_ERR}
	end.

t_drawing_return(RoleID,DrawType) ->
	WeightList = cfg_rune_altar:get_draw_succ_rate(DrawType),
	case common_tool:random_from_tuple_weights(WeightList,2) of
		{true,_} ->
			{true,0};
		_ ->
			{MoneyType1,GainMoney} = cfg_rune_altar:get_draw_fail_return_silver(),
			{ok,NewRoleAttr2} = common_bag2:t_gain_money(
								  MoneyType1, GainMoney, RoleID,
								  ?GAIN_TYPE_SILVER_RUNE_ALTAR_DRAWING
														),
			{false,GainMoney,NewRoleAttr2}
	end.	

add_altar_exp(RoleID,AddAltarExp,DrawTimes) ->
	case get_role_altar_info(RoleID) of
		{ok,RuneAltarRec} ->
			NewAltarExp = RuneAltarRec#r_role_rune_altar.exp + AddAltarExp,
			{UpgradeExp}= cfg_rune_altar:get_altar(RuneAltarRec#r_role_rune_altar.level),
			
			if
				RuneAltarRec#r_role_rune_altar.level >= 10 ->
					IsLvUp = false,
					NewLevel = RuneAltarRec#r_role_rune_altar.level,
					NewExp1 = UpgradeExp;
				true ->
					case NewAltarExp >= UpgradeExp of
						true ->
							IsLvUp = true,
							NewLevel = min(RuneAltarRec#r_role_rune_altar.level + 1,10),
							NewExp1 = NewAltarExp - UpgradeExp;
						_ ->
							IsLvUp = false,
							NewLevel = RuneAltarRec#r_role_rune_altar.level,
							NewExp1 = NewAltarExp
					end
			end,
					
			NewDrawTimes = RuneAltarRec#r_role_rune_altar.draw_times+DrawTimes,
			NowTime = common_tool:now(),
			NewRuneAltarRec = RuneAltarRec#r_role_rune_altar{
								draw_times = NewDrawTimes,
								exp = NewExp1,
								level = NewLevel,
								last_draw_time = NowTime
							},
			mod_role_tab:put({?role_rune_altar, RoleID},NewRuneAltarRec),
			{MaxExp}= cfg_rune_altar:get_altar(NewLevel),
			Notches = cfg_rune_altar:get_notch(get_nuqi_skill_shap(RoleID)),
			{ok,IsLvUp,NewExp1,NewLevel,RuneAltarRec#r_role_rune_altar.score,MaxExp,Notches,NewDrawTimes};
		_ ->
			{error,not_found}
	end.

get_empty_bag(RoleID) ->
	case get_role_altar_info(RoleID) of
		{ok,RuneAltarRec} ->
			Fun = 
				fun(I,AccIn) -> 
					List = lists:filter(fun(#p_rune{pos=Pos}) ->
												Pos =:= I end, 
										RuneAltarRec#r_role_rune_altar.rune_bag),
					case erlang:length(List) of
						Len when Len =:= 0 ->
							[I|AccIn];
						_ ->
							AccIn
					end
				end,
			List = lists:foldl(Fun, [], lists:seq(1,12)),
			{ok,List};
		_ ->
			{error,not_found}
	end.

get_empty_bag_num(RoleID) ->
	case get_empty_bag(RoleID) of
		{ok,List} ->
			length(List);
		_ ->
			0
	end.
			

get_role_bag_pos_rune(RoleID,Pos) ->
	case get_role_altar_info(RoleID) of
		{ok,RuneAltarRec} ->
			case  lists:keyfind(Pos, #p_rune.pos,RuneAltarRec#r_role_rune_altar.rune_bag) of
				false ->
					{error,not_found};
				RuneInfo ->
					{ok,RuneInfo}
			end;
		_ ->
			{error,not_found}
	end.

gm_clear_bag(RoleID) ->
	{ok,RuneAltarRec} = get_role_altar_info(RoleID),
	RuneAltarRecq1    = RuneAltarRec#r_role_rune_altar{rune_bag = []},
	mod_role_tab:put({?role_rune_altar, RoleID}, RuneAltarRecq1),
	do_notify_altar_info(RoleID).

gm_get_rune(RoleID, TypeID, Level) ->
	case get_empty_bag(RoleID) of
		{ok,BagList} when length(BagList) =< 0 ->
			NewPos = 0,
			?THROW_ERR(?ERR_RUNE_ALTAR_BAG_NUM_NOT_ENOUGH);
		{ok,BagList} ->
			NewPos = lists:last(BagList);
		_ ->
			NewPos = 0,
			?THROW_ERR(?ERR_SYS_ERR)
	end,
	NewRune = #p_rune{typeid=TypeID,exp=0,level=Level,pos=NewPos},
	set_role_rune_bag_info(RoleID,NewRune),
	do_notify_altar_info(RoleID).

gm_get_rune(RoleID, TypeID) ->
	case get_empty_bag(RoleID) of
		{ok,BagList} when length(BagList) =< 0 ->
			NewPos = 0,
			?THROW_ERR(?ERR_RUNE_ALTAR_BAG_NUM_NOT_ENOUGH);
		{ok,BagList} ->
			NewPos = lists:last(BagList);
		_ ->
			NewPos = 0,
			?THROW_ERR(?ERR_SYS_ERR)
	end,

	{Exp,_,Level,_,_,_,_} = cfg_rune_altar:get_rune_prop(TypeID),
	NewRune = #p_rune{typeid=TypeID,exp=Exp,level=Level,pos=NewPos},
	set_role_rune_bag_info(RoleID,NewRune),
	do_notify_altar_info(RoleID).



get_role_altar_info(RoleID) ->
	case mod_role_tab:get({?role_rune_altar, RoleID}) of
		RuneAltarRec when is_record(RuneAltarRec,r_role_rune_altar) ->
			{ok,RuneAltarRec};
		_ ->
			{error,not_found}
	end.

set_role_rune_bag_info(RoleID,NewRune) ->
	case get_role_altar_info(RoleID) of
		{ok,RuneAltarRec} ->
			NewRuneBags = lists:keystore(
							NewRune#p_rune.pos, #p_rune.pos,
							RuneAltarRec#r_role_rune_altar.rune_bag,
							NewRune
						  ),
			mod_role_tab:put({?role_rune_altar, RoleID}, RuneAltarRec#r_role_rune_altar{rune_bag=NewRuneBags});
		_ ->
			ignore
	end.
	
check_do_altar_drawing(RoleID,DrawType) ->
	case get_empty_bag(RoleID) of
		{ok,BagList} when length(BagList) =< 0 ->
			NewPos = 0,
			?THROW_ERR(?ERR_RUNE_ALTAR_BAG_NUM_NOT_ENOUGH);
		{ok,BagList} ->
			NewPos = lists:last(BagList);
		_ ->
			NewPos = 0,
			?THROW_ERR(?ERR_SYS_ERR)
	end,
	{ok,RoleRuneRec} = get_role_altar_info(RoleID),
	assert_draw_cost(RoleID,DrawType,RoleRuneRec#r_role_rune_altar.draw_times),
	WeightList = cfg_rune_altar:get_draw_rune_rate(RoleRuneRec#r_role_rune_altar.level,DrawType),
	{SubWeightList,_} = common_tool:random_from_tuple_weights(WeightList,2),
	{TypeID,_} = common_tool:random_from_tuple_weights(SubWeightList,2),
	{Exp,_,Level,_,_,_,_} = cfg_rune_altar:get_rune_prop(TypeID),
	{ok,#p_rune{typeid=TypeID,exp=Exp,level=Level,pos=NewPos},RoleRuneRec}.

gen_new_rune(RoleID,TypeID) ->
	case get_empty_bag(RoleID) of
		{ok,BagList} when length(BagList) < 0 ->
			NewPos = 0;
		{ok,BagList} ->
			NewPos = lists:last(BagList);
		_ ->
			NewPos = 0
	end,
	{Exp,_,Level,_,_,_,_} = cfg_rune_altar:get_rune_prop(TypeID),
	{ok,#p_rune{typeid=TypeID,exp=Exp,level=Level,pos=NewPos}}.
assert_draw_cost(RoleID,DrawType,DrawTimes) ->
	case DrawType =:= ?TYPE_RUNE_SILVER_DRAWING of
		true ->
			if
				DrawTimes >= 3 ->
					{ok,#p_role_attr{level=RoleLevel}} = 
						mod_map_role:get_role_attr(RoleID),
					MoneyType = silver_any,
					DeductMoney = 
						cfg_rune_altar:get_drawing_cost_silver(DrawTimes+1,RoleLevel),
					assert_draw_cost1(RoleID,DrawType,MoneyType, DeductMoney);
				true ->
					ignore
			end;
		_ ->
			{MoneyType,DeductMoney} = 
				cfg_rune_altar:get_gold_draw_money(),
			assert_draw_cost1(RoleID,DrawType,MoneyType, DeductMoney)
	end.


assert_draw_cost1(RoleID,DrawType,MoneyType, DeductMoney) ->
	case common_bag2:check_money_enough(MoneyType, DeductMoney, RoleID) of
		false ->
			case DrawType =:= ?TYPE_RUNE_SILVER_DRAWING of
				true ->
					?THROW_ERR(?ERR_RUNE_ALTAR_SILVER_NOT_ENOUGH);
				_ ->
					?THROW_ERR(?ERR_RUNE_ALTAR_GOLD_NOT_ENOUGH)
			end;
		_ ->
			ignore
	end.

gen_attr_rune(RuneInfo) ->
	case RuneInfo#p_rune.typeid =/= -1 of
		true ->
			{_,_,_,_,_,AttCategory,Atts} = cfg_rune_altar:get_rune_prop(RuneInfo#p_rune.typeid),
			case AttCategory of
				?TYPE_RUNE_ATTACK ->
					Def = 0,
					BloodRecover = 0,
					Hp2Def = 0,
					Hurt2Hp = 0,
					Def2Att = 0,
					ReduceTargetDef = 0,
					Blood = 0,
					{Attack,Att2Hp,ReduceTargerAtt} = Atts;
				?TYPE_RUNE_HP ->
					Attack = 0,
					Def = 0,
					ReduceTargerAtt= 0,
					Def2Att = 0,
					ReduceTargetDef = 0,
					Att2Hp = 0,
					{Blood,BloodRecover,Hp2Def,Hurt2Hp} = Atts;
				?TYPE_RUNE_DEF ->
					ReduceTargerAtt = 0,
					Blood = 0,
					BloodRecover = 0,
					Hurt2Hp = 0,
					Hp2Def = 0,
					Attack = 0,
					Att2Hp = 0,
					{Def,Def2Att,ReduceTargetDef} = Atts
			end,
			RuneAttr =  #p_rune_attr{
							att = Attack,
							att2hp = Att2Hp,
							reduce_target_att = ReduceTargerAtt,
							hp = Blood,
							hp_recover = BloodRecover,
							hp2def = Hp2Def,
							hurt2hp = Hurt2Hp,
							def = Def,
							def2att = Def2Att,
							reduce_target_def = ReduceTargetDef
					},
			{_,NextExp,_,_,_,Category,_} = cfg_rune_altar:get_rune_prop(RuneInfo#p_rune.typeid),
			RuneInfo#p_rune{next_exp = NextExp,category = Category, rune_attr =RuneAttr};
		_ ->
			RuneInfo
	end.

check_rune_attr(RoleID,TypeID) ->
	{ok,#p_role_base{max_phy_attack = RoleAttack,max_hp = RoleHp,phy_defence = PhyDef,magic_defence=MagicDef}}
		= mod_map_role:get_role_base(RoleID),
	{_,_,_,_,_,AttCategory,Atts} = cfg_rune_altar:get_rune_prop(TypeID),
	case AttCategory of
		?TYPE_RUNE_ATTACK ->
			{Attack,Att2Hp,_} = Atts,
			Attack1 = Attack - Att2Hp/8,
			NewRoleAttack = RoleAttack + Attack1 ,
			if
				NewRoleAttack < 0 ->
					{error,?TYPE_RUNE_ATTACK,Att2Hp/8};
				true ->
					ok
			end;
		?TYPE_RUNE_HP ->
			{Blood1,_,Hp2Def,_} = Atts,
			Blood2 =RoleHp +  Blood1 - Hp2Def * 100,
			if
				Blood2 < 0 ->
					{error,?TYPE_RUNE_HP, Hp2Def * 100};
				true ->
					ok
			end;
		?TYPE_RUNE_DEF ->
			{Def1,Def2Att,_} = Atts,
			Def = Def1 - Def2Att *0.5,
			NewPhyDef = PhyDef + Def,
			NewMagicDef = MagicDef + Def,
			if
				NewPhyDef < 0 orelse NewMagicDef < 0 ->
					{error,?TYPE_RUNE_DEF,Def2Att *0.5};
				true ->
					ok
			end
	end.
	
calc_rune_attr(RoleID,RuneAltarRec,_Type) ->
	{ok,#p_role_base{max_phy_attack = RoleAttack,max_hp = RoleHp,phy_defence = PhyDef,magic_defence=MagicDef}}
		= mod_map_role:get_role_base(RoleID),
	Fun = fun(#p_rune{typeid=TypeID},AccIn) ->
				  {_,_,_,_,_,AttCategory,Atts} = cfg_rune_altar:get_rune_prop(TypeID),
				  case AttCategory of
					  ?TYPE_RUNE_ATTACK ->
						  Def = 0,
						  BloodRecover = 0,
						  {Attack,Att2Hp,_} = Atts,
						  if
							  Att2Hp > 0 ->
								  case mod_role_tab:get(RoleID,{rune_attr_base_blood,TypeID}) of
									  undefined ->
										  Blood = 
											  case erlang:is_float(Att2Hp) of
												  true ->
													  RoleAttack*Att2Hp;
												  _ ->
													  Att2Hp
											  end,
										  mod_role_tab:put(RoleID,{rune_attr_base_blood,TypeID},Blood);
									  Blood ->
										  ignore
								  end;
							  true ->
								  Blood = 0
						  end;
								  
					  ?TYPE_RUNE_HP ->
						  Attack = 0,
						  {Blood,BloodRecover,Hp2Def,_} = Atts,
						 %%很蛋疼需求很扯淡 ，生命都变成负数了，不就死了吗,不要问为什么，我也不知道为什么
%% 						  case mod_role_tab:get(RoleID,{rune_attr_base_blood,TypeID}) of
%% 							  undefined ->
%% 								  Blood2 = Blood1 - Hp2Def * 100,
%% 								  Blood =
%% 									  case RoleHp + Blood2 < 1 of
%% 										  true ->
%% 											  -RoleHp + 1;
%% 										  _ ->
%% 											  Blood2
%% 									  end,
%% 								  mod_role_tab:put(RoleID,{rune_attr_base_blood,TypeID},Blood);
%% 							  Blood ->
%% 								  ignore
%% 						  end,
						  if
							  Hp2Def > 0 ->
								  case mod_role_tab:get(RoleID,{rune_attr_base_def,TypeID}) of
									  undefined ->
										  Def = 
											  case erlang:is_float(Hp2Def) of
												  true ->
													  RoleHp*Hp2Def;
												  _ ->
													  Hp2Def
											  end,
										  mod_role_tab:put(RoleID,{rune_attr_base_def,TypeID},Def);
									  Def ->
										  ignore
								  end;
							  true ->
								  Def = 0
						  end;
					  ?TYPE_RUNE_DEF ->
						  Blood = 0,
						  BloodRecover = 0,
						  {Def,Def2Att,_} = Atts,
						  if
							  Def2Att > 0 ->
								  case mod_role_tab:get(RoleID,{rune_attr_base_att,TypeID}) of
									  undefined ->
										  Attack = 
											  case erlang:is_float(Def2Att) of
												  true ->
													  PhyDef*Def2Att+MagicDef*Def2Att;
												  _ ->
													  Def2Att
											  end,
										  mod_role_tab:put(RoleID,{rune_attr_base_att,TypeID},Attack);
									  Attack ->
										  ignore
								  end;
							  true ->
								  Attack = 0
						  end
				  end,
				  AccIn#p_property_add{
							min_physic_att = AccIn#p_property_add.min_physic_att + Attack,
							max_physic_att = AccIn#p_property_add.max_physic_att + Attack,
							max_magic_att = AccIn#p_property_add.max_magic_att + Attack,
							min_magic_att = AccIn#p_property_add.min_magic_att + Attack,
							blood_resume_speed = AccIn#p_property_add.blood_resume_speed + BloodRecover,   
							physic_def = AccIn#p_property_add.physic_def + Def,
							magic_def = AccIn#p_property_add.magic_def + Def,
							blood = AccIn#p_property_add.blood + Blood
					}
		  end,
	RunePropAttrs = lists:foldl(Fun, #p_property_add{_ = 0}, RuneAltarRec#r_role_rune_altar.rune_notch),
	mod_role_attr:transform(RunePropAttrs).
	
recalc(RoleBase,_) ->
	{ok,RuneAltarRec} = get_role_altar_info(RoleBase#p_role_base.role_id),
	RuneAddAttr = calc_rune_attr(RoleBase#p_role_base.role_id,RuneAltarRec,load),
	mod_role_attr:calc(RoleBase, '+', RuneAddAttr).
			
		
get_nuqi_skill_shap(RoleID) ->
	{ok,#p_role_attr{category=Category}} = mod_map_role:get_role_attr(RoleID),
	NuQiSkillList = cfg_skill_life:get_one_key_learn_nuqi_skill(Category),
	RoleSkillList = mod_role_skill:get_role_skill_list(RoleID),
	Fun = 
		fun(SkillID,AccIn) ->
				case lists:keyfind(SkillID, #r_role_skill_info.skill_id, RoleSkillList) of
					false ->
						AccIn + 1;
					_ ->
						throw({ok,length(NuQiSkillList)-AccIn})
				end						
		end,
	case catch lists:foldr(Fun, 0, NuQiSkillList) of
		{ok,ShapeNum} ->
			ShapeNum;
		_ ->
			0
	end.
