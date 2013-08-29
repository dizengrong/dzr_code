-module(mod_item_effect).

-include("mgeem.hrl").

-export([
		 add_hp/11,add_mp/11,random_transform/11,return_home/11,add_exp_multiple_buff/11,
		 location_move/11,give_state/11,add_exp/11,add_skill_points/11,used_extend_bag/11,used_gift_bag/11,
		 add_big_hp/11,change_ybc_color/11,add_big_mp/11,reduce_pkpoint/11,add_money/11,member_gather/11,
		 show_newcomer_manual/11, gather_factionist/11, change_skin/11,
		 get_new_pet/11, add_pet_hp/11, add_pet_exp/11, add_drunk_buff/11,add_pet_refining_exp/11,
		 item_call_monster/11,show_client_effect/11,add_energy/11,add_noattack_buff/11, add_country_treasure_buff/11,use_cang_bao_tu/11,
		 bomb/11,add_jifen/11,add_tili/11,reduce_skill_cd/11,add_guard_fb_buff/11,add_gongxun/11,use_soap/11
		]).

-export([
		 add_hp_by_level/11,
         do_add_hp_by_level/4,
		 add_mp_by_level/11,
         do_add_mp_by_level/3,
         add_yueli/11,
         add_nuqi/11,
         use_huoling/11
		]).

%%目前只供内部调用
-export([gift_goods_log/2]).

%% 使用礼包累计充值不够错误码
-define(ERR_NOT_ENOUGH_PAY_GOLD,1001).

%%加血
add_hp(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
	RoleID = RoleAttr#p_role_attr.role_id,
	{NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
	case catch erlang:list_to_integer(Par) of
		{'EXIT',_Reason} ->
			TransModule:abort(?_LANG_ITEM_ADD_HP_SYSTEM_ERROR);
		AddHp ->
            AddHp1 = AddHp*UseNum,
			case mod_map_actor:get_actor_mapinfo(RoleAttr#p_role_attr.role_id, role) of
				#p_map_role{hp=HP, max_hp=MaxHP} ->
					case HP >= MaxHP of
						true ->
							TransModule:abort(?_LANG_ITEM_ADD_HP_MAX);
						_ ->
							next
					end;				
				undefined ->
					TransModule:abort(?_LANG_ITEM_ADD_HP_SYSTEM_ERROR)
			end,
			Vigour = RoleBase#p_role_base.vigour,
			Week = mod_buff:get_week(role, RoleID, common_tool:now()),
			AddHp2 = AddHp1*(1+Vigour/10000-Week/10000),
			mod_map_role:do_role_add_hp(RoleAttr#p_role_attr.role_id,AddHp2,RoleID),
			{NewItemInfo,RoleBase,RoleAttr,[Msg,MsgList],[?_LANG_ITEM_EFFECT_ADDHP_OK|PromptList]}
	end.

%%加灵气
add_mp(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
	{NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
	case catch erlang:list_to_integer(Par) of
		{'EXIT',_Reason} ->
			TransModule:abort(?_LANG_ITEM_ADD_MP_SYSTEM_ERROR);
		AddMp ->
			case mod_map_actor:get_actor_mapinfo(RoleAttr#p_role_attr.role_id, role) of
				#p_map_role{mp=MP, max_mp=MaxMP} ->
					case MP >= MaxMP of
						true ->
							TransModule:abort(?_LANG_ITEM_ADD_MP_MAX);
						_ ->
							next
					end;
				undefined ->
					TransModule:abort(?_LANG_ITEM_ADD_MP_SYSTEM_ERROR)
			end,
			mod_map_role:do_role_add_mp(RoleAttr#p_role_attr.role_id,AddMp,RoleAttr#p_role_attr.role_id),
			{NewItemInfo,RoleBase,RoleAttr,[Msg,MsgList],[?_LANG_ITEM_EFFECT_ADDMP_OK|PromptList]}
	end.

%%随机移动
random_transform(_ItemInfo,_ItemBaseInfo,_RoleBase,_RoleAttr,_MsgList,_PromptList,_Par,_EffectID,_UseNum,_State, TransModule) ->
    TransModule:abort(?_LANG_ITEM_EFFECT_NO_RANDOM_MOVE).

%%回城
return_home(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,_Par,_EffectID,UseNum,State, TransModule) ->
    %% 监狱不能使用回城卷
    #map_state{mapid=MapID} = State,
    case common_config_dyn:find(fb_map,MapID) of
        [#r_fb_map{can_use_item_return_home=false}]->
            TransModule:abort(?_LANG_ITEM_RETURN_HOME_IN_SPECIAL_FB);
        _ ->
            next
    end,
    %% 战斗状态不能使用回城
    case mod_map_role:is_role_fighting(RoleBase#p_role_base.role_id) andalso RoleAttr#p_role_attr.level >= 40 of
        true ->
            TransModule:abort(?_LANG_MAP_TRANSFER_ROLE_FIGHTING);
        _ ->
            ignore
    end,
    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),


    Fun = {func,fun() ->
                        %%catch mod_educate_fb:do_cancel_role_educate_fb(RoleAttr#p_role_attr.role_id),
                        % catch mod_scene_war_fb:do_cancel_role_sw_fb(RoleAttr#p_role_attr.role_id),
                        RoleID = RoleAttr#p_role_attr.role_id,
                        common_misc:send_to_rolemap(strict, RoleID, {mod_map_role, {return_home, RoleID}})
                        % mod_map_role:handle({return_home, RoleAttr#p_role_attr.role_id},State)
                end},
    {NewItemInfo,RoleBase,RoleAttr,[Fun,Msg|MsgList],[<<"成功回城">>|PromptList]}.

%%使用多倍经验符
add_exp_multiple_buff(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,_MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
    #p_role_base{role_id=RoleID} = RoleBase,
    {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            ?ERROR_MSG("~ts:~w ~w~n",["使用多倍经验符时配置文件出错，错误的配置是",_ItemBaseInfo,_Reason]),
            TransModule:abort(?_LANG_ITEM_ADD_EXP_MULTIPLE_BUFF_SYSTEM_ERROR);
        BuffID ->
            mod_role_buff:add_buff(RoleID, BuffID),
            {ok, RoleBase2} = mod_map_role:get_role_base(RoleID),
            {NewItemInfo,RoleBase2,RoleAttr,Msg,[?_LANG_ITEM_EFFECT_ADDEXP_OK|PromptList]}
    end. 

%%定位传送
location_move(_ItemInfo,_ItemBaseInfo,_RoleBase,_RoleAttr,_MsgList,_PromptList,_Par,_EffectID,_UseNum,_State, TransModule) ->
    TransModule:abort(?_LANG_ITEM_EFFECT_NO_LOCATION_MOVE).

%%赋予状态
give_state(_ItemInfo,_ItemBaseInfo,_RoleBase,_RoleAttr,_MsgList,_PromptList,_Par,_EffectID,_UseNum,_State, TransModule) ->
    TransModule:abort(?_LANG_ITEM_EFFECT_NO_GIVE_STATE).

%%加经验
add_exp(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
	assert_multi_use_item(ItemInfo,UseNum,TransModule),
    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_ITEM_ADD_EXP_SYSTEM_ERROR);
        AddExp ->
            #p_role_attr{exp=Exp, next_level_exp=NextLevelExp} = RoleAttr,
            case Exp >= NextLevelExp of
                true ->
                    TransModule:abort(?_LANG_ITEM_ADD_EXP_EXP_FULL);
                _ ->
                    ok
            end,
			MultiAddExp = AddExp * UseNum,
            mod_map_role:add_exp(RoleAttr#p_role_attr.role_id,MultiAddExp),
            {NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],[concat(["道具使用增加经验",erlang:integer_to_list(MultiAddExp)])|PromptList]}
    end. 

%%加技能点
add_skill_points(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_ITEM_ADD_SKILL_POINT_SYSTEM_ERROR);
        AddPoints ->
            AddPoints1 = AddPoints*UseNum,
            #p_role_attr{role_id=RoleID,remain_skill_points = OldPoints} = RoleAttr,
            NewRoleAttr = RoleAttr#p_role_attr{remain_skill_points=AddPoints1 + OldPoints},
            Change = #p_role_attr_change{change_type = ?ROLE_SKILL_POINT_CHANGE, 
                                         new_value = AddPoints1 + OldPoints},
            Data = #m_role2_attr_change_toc{roleid = RoleID, changes = [Change]},
            NewMsgList = [{RoleID, ?ROLE2, ?ROLE2_ATTR_CHANGE, Data},Msg|MsgList],
            {NewItemInfo,RoleBase,NewRoleAttr,NewMsgList,[concat(["道具使用增加技能点",erlang:integer_to_list(AddPoints)])|PromptList]}
    end. 

%%使用扩展背包
used_extend_bag(ItemInfo,_ItemBaseInfo,_RoleBase,RoleAttr,MsgList,PromptList,_Par,_EffectID,UseNum,_State, TransModule) ->
	db:abort("不可直接使用，可在兑换商城兑换金砖哦"),
    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    [BagBasicInfo]= db:read(?DB_ROLE_BAG_BASIC_P,RoleAttr#p_role_attr.role_id),
    {ok,{role_bag_list,_IDList},_} = mod_bag:get_role_bag_info(RoleAttr#p_role_attr.role_id),
    BagID =  
        case lists:keyfind(2,1,BagBasicInfo#r_role_bag_basic.bag_basic_list) of
            false ->
                2;
            _ ->
                case lists:keyfind(3,1,BagBasicInfo#r_role_bag_basic.bag_basic_list) of
                    false ->
                        3;
                    _ ->
                        db:abort(?_LANG_ITEM_EFFECT_NOT_EMPTY_BAG)
                end
        end,
    TimeOut = ItemInfo#p_goods.end_time,
    case check_in_use_time(ItemInfo) of
        true->
            [{r_bag_config,_,Rows,Columns,GridNumber}] = 
                common_config_dyn:find(extend_bag,ItemInfo#p_goods.typeid),
            mod_bag:create_bag(RoleAttr#p_role_attr.role_id,{BagID,ItemInfo#p_goods.typeid,TimeOut,Rows,Columns,GridNumber}),
            BagBasicList = [{BagID,ItemInfo#p_goods.typeid,TimeOut,Rows,Columns,GridNumber}|BagBasicInfo#r_role_bag_basic.bag_basic_list],
            {1,MainBagTypeID,MainOutUseTime,MainRows,MainClowns,MainGridNumber} 
                = mod_bag:get_bag_info_by_id(RoleAttr#p_role_attr.role_id,1),
            BagBasicList2 = lists:keydelete(1,1,BagBasicList),
            NewBagBasicInfo = BagBasicInfo#r_role_bag_basic{bag_basic_list=[{1,MainBagTypeID,MainOutUseTime,MainRows,MainClowns,MainGridNumber}|BagBasicList2]},
            TransModule:write(?DB_ROLE_BAG_BASIC_P,NewBagBasicInfo,write),
            Data =  #m_item_new_extend_bag_toc{ bagid = BagID,
                                                rows = Rows,
                                                columns = Columns,
                                                grid_number = GridNumber, 
                                                main_rows = MainRows,
                                                main_columns = MainClowns,
                                                main_grid_number = MainGridNumber,
                                                typeid = ItemInfo#p_goods.typeid}, 
            NewMsgList = [{RoleAttr#p_role_attr.role_id, ?ITEM, ?ITEM_NEW_EXTEND_BAG, Data},Msg,MsgList],
            {NewItemInfo,_RoleBase,RoleAttr,NewMsgList,[?_LANG_ITEM_EFFECT_USED_BAG_OK|PromptList]};
        false->
            {ItemInfo,_RoleBase,RoleAttr,MsgList,PromptList}
    end.

check_in_use_time(ItemInfo) ->
    #p_goods{start_time = StartTime,
             end_time = EndTime} = ItemInfo,
    Now = common_tool:now(),         
    if StartTime =:= 0  orelse 
           StartTime =< Now ->
           if EndTime =:= 0  orelse 
                  EndTime >= Now ->
                  true;
              true ->
                  false
           end;
       true ->
           false
    end.


%%使用礼包
used_gift_bag(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_ITEM_USE_GIFT_SYSTEM_ERROR);
        ID ->
            %%1全部产生礼品,2随机产生礼品
            [{r_gift,ID,Type,NeedPayGold,GiftList}] = common_config_dyn:find(gift,ID),
			AllRuneGiftList = cfg_rune_altar:get_all_rune_gift(),
			case lists:member(ItemInfo#p_goods.typeid, AllRuneGiftList) of
				true ->
					RoleID = RoleAttr#p_role_attr.role_id,
					BagEmptyNum = mod_rune_altar:get_empty_bag_num(RoleID) ,
					GiftNum = case  Type =:= 1 of
								  true ->
									  length(GiftList);
								  _ ->
									  1
							  end,
					if
						BagEmptyNum < GiftNum ->
							NewItemInfo = ItemInfo,
							Msg = [],
							FunBc = fun() -> ignore end,
							Text1 = "符文背包已满";
						true ->
							{NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
							if 
								Type =:= 1 ->
								   lists:foreach(fun(#p_gift_goods{typeid=TypeID}) -> 
														 {ok,NewRune} = mod_rune_altar:gen_new_rune(RoleID,TypeID),
														 mod_rune_altar:set_role_rune_bag_info(RoleID,NewRune)
												 end, GiftList);
							   true ->
								   #p_gift_goods{typeid=TypeID} = common_tool:random_from_tuple_weights(GiftList,#p_gift_goods.rate),
								   {ok,NewRune} = mod_rune_altar:gen_new_rune(RoleID,TypeID),
								   mod_rune_altar:set_role_rune_bag_info(RoleID,NewRune)
							end,
							
							mod_rune_altar:do_notify_altar_info(RoleID),
                            [ItemBaseInfo] = common_config_dyn:find(item, ItemInfo#p_goods.typeid),
                            Price = ItemBaseInfo#p_item_base_info.buy_price,
							GoodsName = common_misc:format_goods_name_colour(ItemInfo#p_goods.current_colour,ItemInfo#p_goods.name),
							Text = lists:flatten(io_lib:format(?_LANG_ITEM_USE_SHOU_CHONG_BCAST,
															   [common_tool:to_list(RoleBase#p_role_base.role_name),Price,GoodsName])),
							FunBc = fun()-> 
											common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,Text)
									end,
							Text1 = concat([?_LANG_ITEM_EFFECT_USED_GIFT_OK,"各种符文"])
					end,
					{NewItemInfo,RoleBase,RoleAttr,[{func,FunBc},Msg|MsgList],
					 [Text1|PromptList]};
				_ ->
					{NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
		            RoleID = RoleAttr#p_role_attr.role_id,
					RolePayGold = common_misc:role_total_pay_gold(RoleID),
					case RolePayGold >= NeedPayGold of
						true ->
							if ItemInfo#p_goods.typeid =:= 11400065 -> %%首充礼包世界广播
								   FunBc = fun()-> 
                                                   [ItemBaseInfo] = common_config_dyn:find(item, ItemInfo#p_goods.typeid),
                                                   Price = ItemBaseInfo#p_item_base_info.buy_price,
												   GoodsName = common_misc:format_goods_name_colour(ItemInfo#p_goods.current_colour,ItemInfo#p_goods.name),
												   Text = lists:flatten(io_lib:format(?_LANG_ITEM_USE_SHOU_CHONG_BCAST,
																					  [common_tool:to_list(RoleBase#p_role_base.role_name),Price,GoodsName])),
												   common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,Text)
										   end;
							   true ->
								   FunBc = fun()-> ignore end
							end,
							if Type =:= 1 ->
								   {ok,GoodsList,GoodsLBase,CreateInfoList} = all_produce_gift(RoleID,GiftList),
								   Names = format_goods_name(GoodsLBase),
								   F1 = fun() -> common_misc:update_goods_notify({role,RoleID}, GoodsList) end,
								   F2 = fun() -> ?MODULE:gift_goods_log(CreateInfoList,RoleID) end,
								   F3 = fun() -> 
												hook_prop:hook(open_gift, RoleID, GoodsList),
												hook_prop:hook(create, GoodsList)
										end,
								   
								   {NewItemInfo,RoleBase,RoleAttr,[{func,FunBc},{func, F3},{func,F2},{func,F1},Msg|MsgList],
									[concat([?_LANG_ITEM_EFFECT_USED_GIFT_OK,Names])|PromptList]};
							   Type =:= 2 ->
								   {ok,GoodsList,GoodsLBase,CreateInfoList} = random_produce_gift(RoleID,ItemInfo#p_goods.typeid,GiftList),
								   Names = format_goods_name(GoodsLBase),
								   F1 = fun() -> common_misc:update_goods_notify({role,RoleID}, GoodsList) end,
								   F2 = fun() -> ?MODULE:gift_goods_log(CreateInfoList,RoleID) end,
								   F3 = fun() -> 
												hook_prop:hook(open_gift, RoleID, GoodsList),
												hook_prop:hook(create, GoodsList)
										end,
								   
								   {NewItemInfo,RoleBase,RoleAttr,[{func,FunBc},{func, F3},{func,F2},{func,F1},Msg|MsgList],
									[concat([?_LANG_ITEM_EFFECT_USED_GIFT_OK,Names])|PromptList]};
							   true ->
								   TransModule:abort(?_LANG_ITEM_EFFECT_USED_GIFT_FAIL)
							end;
						false ->
							TransModule:abort({error,?ERR_NOT_ENOUGH_PAY_GOLD,lists:concat(["该礼包需要累计充值",NeedPayGold,"元宝才能打开，您还需再充值",NeedPayGold-RolePayGold,"元宝"])})
					end
			end
    end.

all_produce_gift(RoleID,GiftList) ->
    {CreateInfoList,BaseL} = lists:foldl(
                               fun(GiftBase,{C,B}) ->
                                       case GiftBase#p_gift_goods.type of
                                           ?TYPE_ITEM->
                                               Quality = 0,SubQuality = 0,
                                               [BaseInfo]=common_config_dyn:find_item(GiftBase#p_gift_goods.typeid),
                                               Color = BaseInfo#p_item_base_info.colour;
                                           ?TYPE_STONE->
                                               Quality = 0,SubQuality = 0,
                                               [BaseInfo]=common_config_dyn:find_stone(GiftBase#p_gift_goods.typeid),
                                               Color = BaseInfo#p_stone_base_info.colour;
                                           ?TYPE_EQUIP->
                                               {Quality,SubQuality} = mod_refining_tool:get_equip_quality_by_color(GiftBase#p_gift_goods.color),
                                               Color = GiftBase#p_gift_goods.color
                                       end,
                                       {[#r_goods_create_info{bind=GiftBase#p_gift_goods.bind, 
                                                              type=GiftBase#p_gift_goods.type, 
                                                              start_time=GiftBase#p_gift_goods.start_time,
                                                              end_time=GiftBase#p_gift_goods.end_time,
                                                              type_id=GiftBase#p_gift_goods.typeid,
                                                              num=GiftBase#p_gift_goods.num,
                                                              quality = Quality,sub_quality = SubQuality,
                                                              color=Color}|C],
                                        [{GiftBase#p_gift_goods.typeid,
                                          GiftBase#p_gift_goods.type,
                                          GiftBase#p_gift_goods.num}|B]}
                               end,{[],[]},GiftList),
    {ok,GoodsList} = mod_bag:create_goods(RoleID, CreateInfoList),
    {ok,GoodsList,BaseL,CreateInfoList}.

random_produce_gift(RoleID,ItemTypeID,GiftList) ->
	case mod_gift:get_role_gift_extend(RoleID,ItemTypeID) of
		0 ->
			Sum = lists:foldl(fun(GiftBase,Acc) -> Acc+GiftBase#p_gift_goods.rate end,0,GiftList),
			RandomR = common_tool:random(1,Sum);
		RandomR ->
			RandomR
	end,
    {ok,Re} = (catch lists:foldl(
                 fun(Result,AccR) ->
                         if AccR+Result#p_gift_goods.rate < RandomR ->
                                AccR+Result#p_gift_goods.rate;
                            true ->
                                throw({ok,Result})
                         end
                 end,0,GiftList)),
    Color = 
        case Re#p_gift_goods.type of
            ?TYPE_ITEM->
                [BaseInfo]=common_config_dyn:find_item(Re#p_gift_goods.typeid),
                BaseInfo#p_item_base_info.colour;
            ?TYPE_STONE->
                [BaseInfo]=common_config_dyn:find_stone(Re#p_gift_goods.typeid),
                BaseInfo#p_stone_base_info.colour;
            ?TYPE_EQUIP->
                Re#p_gift_goods.color
        end,
    CreateInfo = #r_goods_create_info{bind=Re#p_gift_goods.bind, 
                                      type=Re#p_gift_goods.type, 
                                      start_time=Re#p_gift_goods.start_time,
                                      end_time=Re#p_gift_goods.end_time,
                                      type_id=Re#p_gift_goods.typeid,
                                      num=Re#p_gift_goods.num,
                                      color=Color},
    case catch mod_bag:create_goods(RoleID, CreateInfo) of
		{ok,GoodsList} ->
			mod_gift:del_role_gift_extend(RoleID,ItemTypeID);
		Reason ->
			GoodsList = [],
			mod_gift:set_role_gift_extend(RoleID,{ItemTypeID,RandomR}),
			throw(Reason)
	end,
    CreateInfoList = [CreateInfo],
    {ok,GoodsList,[{Re#p_gift_goods.typeid,Re#p_gift_goods.type,Re#p_gift_goods.num}],CreateInfoList}.

format_goods_name(GoodsList) ->
    lists:foldl(
      fun({TypeID,Type,Num},Names) ->
              Name = 
                  case Type of
                      ?TYPE_EQUIP ->
                          [BaseInfo]=common_config_dyn:find_equip(TypeID),
                          BaseInfo#p_equip_base_info.equipname;
                      ?TYPE_ITEM ->
                          [BaseInfo]=common_config_dyn:find_item(TypeID),
                          BaseInfo#p_item_base_info.itemname;
                      ?TYPE_STONE ->
                          [BaseInfo]=common_config_dyn:find_stone(TypeID),
                          BaseInfo#p_stone_base_info.stonename
                  end,
              concat(["\n",binary_to_list(Name),"×",Num,Names])
      end,"",GoodsList).

gift_goods_log(CreateInfoList,RoleID) ->
    lists:foreach(
      fun(CreateInfo) ->
              common_item_logger:log(RoleID,CreateInfo,?LOG_ITEM_TYPE_LI_BAO_HUO_DE)
      end,CreateInfoList).

%%加血
add_hp_by_level(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
	RoleID = RoleAttr#p_role_attr.role_id,
	{NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
	case catch erlang:list_to_integer(Par) of
		{'EXIT',_Reason} ->
			TransModule:abort(?_LANG_ITEM_ADD_HP_SYSTEM_ERROR);
		HpType->
            Vigour = RoleBase#p_role_base.vigour,
            #p_role_attr{role_id = RoleID, level = Rolelevel} = RoleAttr,
            case mgeem_map:call({apply, ?MODULE, do_add_hp_by_level, [RoleID, Rolelevel, Vigour, {HpType, UseNum}]}) of
			    {ok, AddHpVal} ->
                    TipMsg = common_misc:format_lang(?_LANG_ITEM_EFFECT_ADDHP_BY_JINEJIE_OK, [AddHpVal]),
                    {NewItemInfo,RoleBase,RoleAttr,[Msg,MsgList],[TipMsg|PromptList]};
                {error, system_error} ->
                    TransModule:abort(?_LANG_ITEM_ADD_HP_SYSTEM_ERROR);
                {error, hp_is_max} ->
                    TransModule:abort(?_LANG_ITEM_ADD_HP_MAX)
            end
	end.

do_add_hp_by_level(RoleID, RoleLevel, Vigour, {HpType, UseNum}) ->
    case common_config_dyn:find(level_hp_mp, {hp,HpType}) of
        [AddHpList]->
            Week = mod_buff:get_week(role, RoleID, common_tool:now()),
            AddHpVal = UseNum*common_tool:to_integer(get_val_by_role(RoleLevel,AddHpList)*(1+Vigour/10000-Week/10000)),
            #p_map_role{hp=HP, max_hp=MaxHP} = mod_map_actor:get_actor_mapinfo(RoleID, role),
			case HP >= MaxHP of
				true ->
          common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MAP, ?MAP_UPDATE_ROLE, 
            #m_map_update_role_toc{role_id = RoleID, update_list = [{#p_map_role.hp, MaxHP}]}),
					{error, hp_is_max};
				_ ->
					mod_map_role:do_role_add_hp(RoleID,AddHpVal,RoleID),
					{ok, AddHpVal}
			end;
        _ ->
            {error, system_error}
    end.

get_val_by_role(_,[])->
    0;
get_val_by_role(RoleLevel,[H|T])->
    {MinRoleLevel,MaxRoleLevel,AddVal} = H,
    if
        RoleLevel>=MinRoleLevel andalso MaxRoleLevel>= RoleLevel ->
            AddVal;
        true->
            get_val_by_role(RoleLevel,T)
    end.

%%加灵气
add_mp_by_level(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
	{NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
	case catch erlang:list_to_integer(Par) of
		{'EXIT',_Reason} ->
			TransModule:abort(?_LANG_ITEM_ADD_MP_SYSTEM_ERROR);
		MpType->
            #p_role_attr{role_id = RoleID, level = Rolelevel} = RoleAttr,
            case mgeem_map:call({apply, ?MODULE, do_add_mp_by_level, [RoleID, Rolelevel, {MpType, UseNum}]}) of
    			{ok, AddMpVal} ->
                    TipMsg = common_misc:format_lang(?_LANG_ITEM_EFFECT_ADDMP_BY_JINEJIE_OK, [AddMpVal]),
                    {NewItemInfo,RoleBase,RoleAttr,[Msg,MsgList],[TipMsg|PromptList]};
                {error, system_error} ->
                    TransModule:abort(?_LANG_ITEM_ADD_MP_SYSTEM_ERROR);
                {error, mp_is_max} ->
                    TransModule:abort(?_LANG_ITEM_EFFECT_MP_MAX)
            end
	end.

do_add_mp_by_level(RoleID, RoleLevel, {MpType, UseNum}) ->
    #p_map_role{max_mp=MaxMp, mp=Mp} = mod_map_actor:get_actor_mapinfo(RoleID, role),
    case Mp >= MaxMp of
        false ->
            case common_config_dyn:find(level_hp_mp,{mp, MpType}) of
                [AddMpList]->
                    AddMpVal = get_val_by_role(RoleLevel, AddMpList)*UseNum,
                    mod_map_role:do_role_add_mp(RoleID, AddMpVal, RoleID),
                    {ok, AddMpVal};
                _ ->
                    {error, system_error}
            end;
        _ ->
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MAP, ?MAP_UPDATE_ROLE, 
              #m_map_update_role_toc{role_id = RoleID, update_list = [{#p_map_role.mp, MaxMp}]}),
            {error, mp_is_max}
    end.

%%使用大红药
add_big_hp(_ItemInfo,_ItemBaseInfo,_RoleBase,_RoleAttr,_MsgList,_PromptList,Par,_EffectID,_UseNum,_State, TransModule) ->
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_ITEM_USE_BIG_HP_SYSTEM_ERROR);
        Key ->
            [{r_big_hp_mp,Key,_,_,Share}] = common_config_dyn:find(bighpmp,Key),
            {NewItemInfo,AddHp,Msg} = 
                case _ItemInfo#p_goods.current_endurance-Share of
                    R when R =< 0 ->
                        NewItemInfoTmp = _ItemInfo#p_goods{current_num=0},
                        mod_bag:delete_goods(_RoleAttr#p_role_attr.role_id,_ItemInfo#p_goods.id),
                        {NewItemInfoTmp,Share+R,
                         {func,fun() -> undefined end}};
                    R ->
                        NewItemInfoTmp = _ItemInfo#p_goods{current_num=1,current_endurance=R},
                        mod_bag:update_goods(_RoleAttr#p_role_attr.role_id,NewItemInfoTmp),
                        {NewItemInfoTmp,Share,
                         {func,fun() -> common_misc:update_goods_notify({role,_RoleAttr#p_role_attr.role_id},NewItemInfoTmp) end}}
                end,
            mod_map_role:do_role_add_hp(_RoleAttr#p_role_attr.role_id, AddHp, _RoleAttr#p_role_attr.role_id),
            {NewItemInfo,_RoleBase,_RoleAttr,[Msg,_MsgList],[?_LANG_ITEM_EFFECT_ADDHP_OK|_PromptList]}
    end.

%%使用换车令
change_ybc_color(ItemInfo,_ItemBaseInfo,_RoleBase,RoleAttr,_MsgList,_PromptList,_Par,_EffectID,UseNum,_State, TransModule) ->
    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    case mod_ybc_person:change_ybc_color(RoleAttr#p_role_attr.role_id, prop) of
        {error, has_public} -> 
            TransModule:abort(?_LANG_PERSONYBC_HAS_PUBLIC_CAN_NOT_CHANGE_COLOR);
        {error, best_color} ->
            TransModule:abort(?_LANG_PERSONYBC_HAS_GOT_THE_BEST_COLOR);
        {ok, Color} ->
			ColorStr = 
				case Color of
					1 ->
						?_LANG_YBC_COLOR1;
					2 ->
						?_LANG_YBC_COLOR2;
					3 ->
						?_LANG_YBC_COLOR3;
					4 ->
						?_LANG_YBC_COLOR4;
					5 ->
						?_LANG_YBC_COLOR5
				end,
			Lang = lists:flatten(io_lib:format(?_LANG_CHANGE_YBC_COLOR_SUCC, [ColorStr])),
            {NewItemInfo,_RoleBase,RoleAttr,[Msg|_MsgList],[Lang|_PromptList]}
    end.



%%使用大蓝药
add_big_mp(_ItemInfo,_ItemBaseInfo,_RoleBase,_RoleAttr,_MsgList,_PromptList,Par,_EffectID,_UseNum,_State, TransModule) ->
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_ITEM_USE_BIG_MP_SYSTEM_ERROR);
        Key ->
            [{r_big_hp_mp,Key,_,_,Share}] = common_config_dyn:find(bighpmp,Key),
            {NewItemInfo,AddMp,Msg} = 
                case _ItemInfo#p_goods.current_endurance-Share of
                    R when R =< 0 ->
                        NewItemInfoTmp = _ItemInfo#p_goods{current_num=0},
                        mod_bag:delete_goods(_RoleAttr#p_role_attr.role_id,_ItemInfo#p_goods.id),
                        {NewItemInfoTmp,Share+R,
                         {func,fun() -> undefined end}};
                    R ->
                        NewItemInfoTmp = _ItemInfo#p_goods{current_num=1,current_endurance=R},
                        mod_bag:update_goods(_RoleAttr#p_role_attr.role_id,NewItemInfoTmp),
                        {NewItemInfoTmp,Share,
                         {func,fun() -> common_misc:update_goods_notify({role,_RoleAttr#p_role_attr.role_id},NewItemInfoTmp) end}}
                end,
            mod_map_role:do_role_add_mp(_RoleAttr#p_role_attr.role_id, AddMp, _RoleAttr#p_role_attr.role_id),
            {NewItemInfo,_RoleBase,_RoleAttr,[Msg,_MsgList],[?_LANG_ITEM_EFFECT_ADDMP_OK|_PromptList]}
    end.

%%减少pk点
reduce_pkpoint(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,_MsgList,_PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    #p_role_base{role_id=RoleID, pk_points=PKPoint} = RoleBase,
    case PKPoint =:= 0 of
        true ->
            TransModule:abort(?_LANG_ITEM_PKPOINT_ZERO);
        _ ->
            next
    end,
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_ITEM_USE_REDUCE_PKPOINT_SYSMTE_ERROR);
        ReducePoint ->
            ReducePoint1 = UseNum*ReducePoint,
            NewPKPoint =
                case PKPoint - ReducePoint1 < 0 of
                    true ->
                        0;
                    _ ->
                        PKPoint - ReducePoint1
                end,
            mod_map_role:update_map_role_info(RoleID, [{#p_map_role.pk_point, NewPKPoint}]),
            NewPromptList = [io_lib:format("使用【清心丸】成功，降低~w点PK值", [PKPoint-NewPKPoint])|_PromptList],
            {NewItemInfo,RoleBase#p_role_base{pk_points=NewPKPoint},RoleAttr,[Msg|_MsgList],NewPromptList}
    end.

concat(List) when is_list(List)->
    lists:concat(List).

%%使用银票
add_money(ItemInfo,_ItemBaseInfo,_RoleBase,RoleAttr,_MsgList,_PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
    #p_role_attr{role_id=RoleID,gold=Gold1,gold_bind=GoldBind1,
                 silver=Silver1,silver_bind=SilverBind1,yueli=Yueli,
                 sum_prestige = SumPrestige,cur_prestige = CurPrestige}=RoleAttr,
	assert_multi_use_item(ItemInfo,UseNum,TransModule),
    {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
    
    CardKey = common_tool:to_integer(Par),
    [#r_money{name=Name,deal_list=DealList}] = common_config_dyn:find(money,CardKey),
    
    %%目前只支持单个类型的兑换
    [{DealType,DealNumTmp}|_T] = DealList,
	DealNum = DealNumTmp * UseNum,
    IsBind = ItemInfo#p_goods.bind,
    {DealMsg,RoleAttr2,ChangeList} =
        case {DealType,IsBind} of
            {gold,true}->
                common_consume_logger:gain_gold({RoleID,DealNum,0,?GAIN_TYPE_GOLD_ITEM_USE,
                                                 "",ItemInfo#p_goods.typeid,1}),
                {concat(["，获得礼券 ",DealNum]),
                 RoleAttr#p_role_attr{gold_bind=GoldBind1+DealNum},
                 [#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=GoldBind1+DealNum}]};
            {gold,false}->
                common_consume_logger:gain_gold({RoleID,0,DealNum,?GAIN_TYPE_GOLD_ITEM_USE,
                                                 "",ItemInfo#p_goods.typeid,1}),
                {concat(["，获得元宝 ",DealNum]),
                 RoleAttr#p_role_attr{gold=Gold1+DealNum},
                 [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=Gold1+DealNum}]};
            {silver,true}->
                common_consume_logger:gain_silver({RoleID,DealNum,0,?GAIN_TYPE_SILVER_ITEM_USE,
                                                   "",ItemInfo#p_goods.typeid,1}),
                {concat(["，获得铜钱 ",common_misc:format_silver(DealNum)]),
                 RoleAttr#p_role_attr{silver_bind=SilverBind1+DealNum},
                 [#p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=SilverBind1+DealNum}]};
            {silver,false}->
                common_consume_logger:gain_silver({RoleID,0,DealNum,?GAIN_TYPE_SILVER_ITEM_USE,
                                                   "",ItemInfo#p_goods.typeid,1}),
                {concat(["，获得钱币 ",common_misc:format_silver(DealNum)]),
                 RoleAttr#p_role_attr{silver_bind=Silver1+DealNum},
                 [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=Silver1+DealNum}]};
            {prestige,_}->
                {ok,RoleAttr3} = common_bag2:t_gain_prestige(DealNum, RoleID, ?GAIN_TYPE_PRESTIGE_BY_ITEM_CARD),
                {concat(["，获得声望 ",DealNum]),
                 RoleAttr3,
                 [#p_role_attr_change{change_type=?ROLE_CUR_PRESTIGE_CHANGE,new_value=CurPrestige + DealNum},
                  #p_role_attr_change{change_type=?ROLE_SUM_PRESTIGE_CHANGE,new_value=SumPrestige + DealNum}]};
            {yueli,_}->
                {ok,RoleAttr3} = common_bag2:t_gain_yueli(DealNum, RoleID, ?GAIN_TYPE_YUELI_BY_ITEM_CARD),
                {concat(["，获得阅历 ",DealNum]),
                 RoleAttr3,
                 [#p_role_attr_change{change_type=?ROLE_YUELI_ATTR_CHANGE,new_value=Yueli + DealNum}]}
        end,
    DataRec = #m_role2_attr_change_toc{roleid=RoleID,changes=ChangeList},
    NewMsgList = [{RoleID,?ROLE2,?ROLE2_ATTR_CHANGE,DataRec},Msg|_MsgList],
    {NewItemInfo,_RoleBase,RoleAttr2,NewMsgList,[concat(["使用",Name,DealMsg])|_PromptList]}.

-define(member_gather_forbidden_map, [{?COUNTRY_TREASURE_MAP_ID, ?_LANG_ITEM_IN_10500}, {10400, ?_LANG_ITEM_IN_10400}, 
                                      {10600, ?_LANG_ITEM_IN_10600}, {10700, ?_LANG_ITEM_IN_10700}]).

%%使用宗族令
member_gather(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,_MsgList,_PromptList,_Par,_EffectID,UseNum,State, TransModule) ->
    #map_state{mapid=MapID} = State,
    case common_config_dyn:find(fb_map,MapID) of
        [#r_fb_map{can_use_item_call_family=false}]->
            TransModule:abort(?_LANG_ITEM_MEMBER_GATHER_IN_SPECIAL_FB);
        _ ->
            next
    end,  
    %% 非国战期间不能在敌国使用宗族令
    #p_role_base{faction_id=FactionID, family_id=FamilyID} = RoleBase,
    case (not common_misc:if_in_self_country(FactionID, MapID))
        andalso (not common_misc:if_in_neutral_area(MapID)) andalso MapID =/= 10300
    of
        true ->
            case TransModule:read(?DB_WAROFFACTION, 1, read) of
                [] ->
                    TransModule:abort(?_LANG_ITEM_MEMBER_GATHER_NOT_IN_WAROFFACTION);
                [WarOfFactionInfo] ->
                    #r_waroffaction{attack_faction_id=AFI, defence_faction_id=DFI} = WarOfFactionInfo,

                    case AFI =:= FactionID orelse DFI =:= FactionID of
                        true ->
                            ok;
                        _ ->
                            TransModule:abort(?_LANG_ITEM_MEMBER_GATHER_NOT_IN_WAROFFACTION)
                    end
            end;
        _ ->
            ok
    end,

    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    AccMsgList = [Msg|_MsgList],
    FamilyID = RoleBase#p_role_base.family_id,
    RoleID =RoleAttr#p_role_attr.role_id,
    if FamilyID > 0 -> 
           [FamilyInfo] = TransModule:read(?DB_FAMILY,FamilyID,read),
           if FamilyInfo#p_family_info.owner_role_id =:= RoleID->
                  next;
              true ->
                  TransModule:abort(?_LANG_ITEM_NOT_FAMILY_OWNER)
           end,
           
           [FamilyExtInfo] = TransModule:dirty_read(?DB_FAMILY_EXT,FamilyID),
           #p_map_role{pos=Pos} = mod_map_actor:get_actor_mapinfo(RoleID, role),
           MapID = mgeem_map:get_mapid(),
           DistMapPos = #p_role_pos{map_id=MapID, pos=Pos},
           case FamilyExtInfo#r_family_ext.last_card_use_day =:= erlang:date() of
               true ->
                   case FamilyExtInfo#r_family_ext.last_card_use_count < 5 of
                       true ->
                           AccMsgList2 =  family_member_gather_final(MapID,FamilyInfo,FamilyID,DistMapPos,AccMsgList),
                           {NewItemInfo,RoleBase,RoleAttr,AccMsgList2,["使用成功，请等待族员回应"|_PromptList]};
                       false ->
                           TransModule:abort(?_LANG_ITEM_COUNT_EXCEED)
                   end;
               false ->
                   AccMsgList2 =  family_member_gather_final(MapID,FamilyInfo,FamilyID,DistMapPos,AccMsgList),
                   {NewItemInfo,RoleBase,RoleAttr,AccMsgList2,["使用成功，请等待族员回应"|_PromptList]}
           end;
       true  ->
           TransModule:abort(?_LANG_ITEM_NO_FAMILY)
    end.

%% 排除掉特殊状态（包括摆摊、死亡、商贸状态，在线挂机状态）
family_member_gather_final(DestMapID, _FamilyInfo, FamilyID, DistMapPos, AccMsgList)->    
    FuncGatherMember = {func, fun() -> common_family:info(FamilyID, {gather_members, DestMapID, DistMapPos}) end},
    [ FuncGatherMember | AccMsgList].

-define(king_token_used_limited, 3).
-define(general_token_used_limited, 2).

%%{25,使用国王令，召集国民
gather_factionist(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,_PromptList,_Par,_EffectID,UseNum, State, TransModule) ->
    #p_role_base{role_id=RoleID, role_name=RoleName, faction_id=FactionID} = RoleBase,
    #map_state{mapid=MapID} = State,
    %% 更新物品数量
    {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
    AccMsgList = [Msg|MsgList],
    %% 只有国战期间才能使用国王令
    WarOfFaction = case TransModule:read(?DB_WAROFFACTION, 1, read) of
                       [] ->
                           TransModule:abort(?_LANG_ITEM_GATHER_FACTIONIST_NOT_IN_WAR);
                       [WOF] ->
                           WOF
                   end,
    %% 进攻方只能在防守方平江跟本国普通地图，以及第二阶段防守方京城使用，防守方只能在本国普通地图使用
    InSelfCountry = common_misc:if_in_self_country(FactionID, MapID),
    #r_waroffaction{attack_faction_id=AttackFaction, defence_faction_id=DefenFaction, war_status=WarStatus} = WarOfFaction,
    if
        FactionID =:= AttackFaction andalso (MapID =/= 1*10000+DefenFaction*1000+102 andalso MapID =/= 1*10000+DefenFaction*1000+100) andalso (not InSelfCountry) ->
            TransModule:abort(?_LANG_ITEM_GATHER_FACTIONIST_ATTACK_CANNT_USED_THIS_MAP);

        FactionID =:= AttackFaction andalso 
        (MapID =/= 1*10000+DefenFaction*1000+102 andalso (MapID =/= 1*10000+DefenFaction*1000+100 orelse WarStatus =/= waroffaction_second_stage)) andalso 
        (not InSelfCountry) ->
            TransModule:abort(?_LANG_ITEM_GATHER_FACTIONIST_ATTACK_CANNT_USED_THIS_MAP_JINGCHENG);

        FactionID =:= DefenFaction andalso (not InSelfCountry) -> 
            TransModule:abort(?_LANG_ITEM_GAHTER_FACTIONIST_DEFEN_CANNT_USED_THIS_MAP);

        FactionID =:= AttackFaction orelse FactionID =:= DefenFaction ->
            AccMsgList2 = gather_factionist_2(RoleID, RoleName, MapID, FactionID, AccMsgList, TransModule),
            {NewItemInfo,RoleBase,RoleAttr,AccMsgList2,[?_LANG_ITEM_GATHER_FACTIONIST_SUCC|_PromptList]};

        true ->
            TransModule:abort(?_LANG_ITEM_GAHTER_FACTIONIST_NOT_IN_WAR)
    end.

gather_factionist_2(RoleID, RoleName, MapID, FactionID, AccMsgList, TransModule) ->
    [FactionInfo] = TransModule:read(?DB_FACTION, FactionID, write),
    Now = common_tool:now(),
    {{Y, M, D}, _} = calendar:gregorian_seconds_to_datetime(Now),
    NowDate = (Y+1970)*10000+M*100+D,
    #p_faction{office_info=OfficeInfo, king_token_used_log=UsedLog} = FactionInfo,
    case UsedLog of
        undefined ->
            UsedLog2 = #p_king_token_used_log{king_last_used_time=0, king_used_counter=0,
                                              general_last_used_time=0, general_used_counter=0};
        _ ->
            UsedLog2 = UsedLog
    end,
    #p_king_token_used_log{king_last_used_time=KingUsedTime, king_used_counter=KingCounter,
                           general_last_used_time=GeneralUsedTime, general_used_counter=GeneralCounter} = UsedLog2,
    {{Y2, M2, D2}, _} = calendar:gregorian_seconds_to_datetime(KingUsedTime),
    {{Y3, M3, D3}, _} = calendar:gregorian_seconds_to_datetime(GeneralUsedTime),
    KingUsedTimeT = (Y2+1970)*10000+M2*100+D2,
    GeneralUsedTimeT = (Y3+1970)*10000+M3*100+D3,
    %% 天纵神将ID
    GeneralRoleID = common_office:get_general_roleid(OfficeInfo#p_office.offices),
    %%判断宣战的玩家是否是国王或者天纵神将
    if
        OfficeInfo#p_office.king_role_id =:= RoleID ->
            %% 是否达到次数限制
            case KingUsedTimeT =:= NowDate andalso KingCounter >= ?king_token_used_limited of
                true ->
                    TransModule:abort(?_LANG_ITEM_GATHER_FACTIONIST_KING_LIMITED);
                _ ->
                    %% 更新国王令使用纪录
                    KingCounter2 = if KingUsedTimeT =:= NowDate -> KingCounter+1; true -> 1 end,
                    UsedLog3 = UsedLog2#p_king_token_used_log{king_last_used_time=Now, king_used_counter=KingCounter2},
                    FactionInfo2 = FactionInfo#p_faction{king_token_used_log=UsedLog3},
                    TransModule:write(?DB_FACTION, FactionInfo2, write),

                    gather_factionist_3(RoleID, RoleName, MapID, FactionID, AccMsgList, king, TransModule)
            end; 

        GeneralRoleID =:= RoleID ->
            case GeneralUsedTimeT =:= NowDate andalso GeneralCounter >= ?general_token_used_limited of
                true ->
                    TransModule:abort(?_LANG_ITEM_GATHER_FACTIONIST_GENERAL_LIMITED);
                _ ->
                    GeneralCounter2 = if GeneralUsedTimeT =:= NowDate -> GeneralCounter+1; true -> 1 end,
                    UsedLog3 = UsedLog2#p_king_token_used_log{general_last_used_time=Now, general_used_counter=GeneralCounter2},
                    FactionInfo2 = FactionInfo#p_faction{king_token_used_log=UsedLog3},
                    TransModule:write(?DB_FACTION, FactionInfo2, write),

                    gather_factionist_3(RoleID, RoleName, MapID, FactionID, AccMsgList, general, TransModule)
            end;

        true ->
            TransModule:abort(?_LANG_ITEM_GATHER_FACTIONIST_NO_RIGHT)
    end.

gather_factionist_3(FactionCallerID, RoleName, MapID, FactionID, AccMsgList, RoleType, TransModule)->
    case RoleType of
        king ->
            Msg = lists:flatten(io_lib:format(?_LANG_WAROFFACTION_GATHER_FACTIONIST_KING, [RoleName]));
        _ ->
            Msg = lists:flatten(io_lib:format(?_LANG_WAROFFACTION_GATHER_FACTIONIST_GENERAL, [RoleName]))
    end,

    {TX, TY} = mod_map_actor:get_actor_txty_by_id(FactionCallerID, role),
    %%使用后向本国国民（≥50级）发出召集
    Pattern = #r_role_online{faction_id=FactionID, _='_'},
    case TransModule:dirty_match_object(?DB_USER_ONLINE,Pattern) of
        []->
            AccMsgList;
        RoleOnlieList ->
            OnlineFactionist = lists:filter(fun(E)-> 
                                                    #r_role_online{role_id=RoleID} = E,
                                                    {ok, #p_role_attr{level=Level}} = common_misc:get_dirty_role_attr(RoleID),
                                                    Level>=40 andalso RoleID =/= FactionCallerID
                                            end, RoleOnlieList),
            FuncDoMemberGather = {func,fun() -> do_factionist_gather_toc(OnlineFactionist, Msg, MapID, TX, TY) end},
            [ FuncDoMemberGather |AccMsgList]
    end.


%%执行召集国民（≥50级）的命令
do_factionist_gather_toc(RoleIDList, Msg, MapID, TX, TY)->
    %%TODO:修改国王召集的广播词
    R_toc = #m_waroffaction_gather_factionist_toc{message=Msg, mapid=MapID, tx=TX, ty=TY},
    lists:foreach(fun(#r_role_online{role_id=T})->
                          common_misc:unicast({role,T},?DEFAULT_UNIQUE,?WAROFFACTION,?WAROFFACTION_GATHER_FACTIONIST,R_toc)
                  end,RoleIDList).

-define(spec_role_state, [{?ROLE_STATE_DEAD, "死亡"}, {?ROLE_STATE_STALL, "摆摊"}, {?ROLE_STATE_COLLECT, "采集"}, {?ROLE_STATE_ZAZEN, "打坐"}, {?ROLE_STATE_EAT, "点餐"}]).
-define(spec_buff_state, [{dizzy, "晕迷"}, {stop_body, "定身"}, {paralysis, "麻痹"}, {reduce_move_speed, "减速"}]).
-define(change_skin_buff_id, 10569).

%% @doc 变身符
change_skin(ItemInfo, ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, EffectID, UseNum, _State, TransModule) ->
    %% 更新物品数量
    #p_role_attr{role_id=RoleID} = RoleAttr,
    IsInSpecialFb = mod_hero_fb:is_in_hero_fb(RoleID) orelse mod_examine_fb:is_in_examine_fb(RoleID),
    if
        IsInSpecialFb =:= true->
            TransModule:abort(?_LANG_ITEM_CHANGE_SKIN_CAN_NOT_USE_IN_HERO_FB);
        true->
            ignore
    end,
    case RoleID =:= EffectID of
        true->
            %% 随机变成一种动物
            Rate = random:uniform(100),
            [{WeightList, LastTime}] = common_config_dyn:find(item_change_skin, {change_skin, common_tool:to_integer(Par)}),
            ToAnimalID = get_change_skin_id(Rate, WeightList, 0),
            {ok, BuffDetail} = mod_skill_manager:get_buf_detail(?change_skin_buff_id),
            BuffDetail2 = BuffDetail#p_buf{value=ToAnimalID, last_value=LastTime},
            ExtraBuffDetailList = get_extra_buff_list(ItemBaseInfo#p_item_base_info.typeid),
            AddChangeSkinBuff = {func, 
                                 fun() -> 
                                         [RemoveBuffTypeList] = common_config_dyn:find(item_change_skin, buff_type_list),
                                         mod_role_buff:del_buff_by_type(RoleID, RemoveBuffTypeList),
                                         mod_role_buff:add_buff(EffectID, [BuffDetail2 | ExtraBuffDetailList], {role, RoleID}) 
                                 end},
            {NewItemInfo, NoticeFunc} = update_item(RoleID, ItemInfo, UseNum),
            {NewItemInfo, RoleBase, RoleAttr, [AddChangeSkinBuff,NoticeFunc|MsgList], [?_LANG_ITEM_CHANGE_SKIN_SUCC|PromptList]};
        false->
            TransModule:abort(?_LANG_ITEM_CHANGE_SKIN_ONLY_ON_SELF)
    end.

%% @doc 获取变成动物的ID
get_change_skin_id(_Rate, [{AnimalID, _Weight}], _Sum) ->
    AnimalID;
get_change_skin_id(Rate, [{AnimalID, Weight}|T], Sum) ->
    case Weight+Sum >= Rate of
        true ->
            AnimalID;
        _ ->
            get_change_skin_id(Rate, T, Sum+Weight)
    end.

%% 获取变身符额外buff列表
get_extra_buff_list(TypeID) ->
    [BuffIdList] = common_config_dyn:find(item_change_skin, {buffs, TypeID}),
    lists:map(
      fun(BuffId) ->
              {ok, BuffDetail} = mod_skill_manager:get_buf_detail(BuffId),
              BuffDetail
      end, BuffIdList).

%%doc 打开新手卡宝典
show_newcomer_manual(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, _Par, _EffectID, _UseNum, _State, _TransModule) ->
    %%空实现，前端目前不会发消息到后端
    {ItemInfo,RoleBase,RoleAttr,MsgList,PromptList}.


%%doc 更新道具的个数，可能是删除、也可能是更新个数
update_item(RoleID,ItemInfo,UseNum) ->
    case ItemInfo#p_goods.current_num - UseNum of
        R when R > 0 ->
            NewItemInfo = ItemInfo#p_goods{current_num=R},
            {ok,[_OldItemInfo]} = mod_bag:update_goods(RoleID,ItemInfo#p_goods{current_num = R}),
            {NewItemInfo,{func,fun() -> common_misc:update_goods_notify({role,RoleID},NewItemInfo) end}};
        _ ->
            {ok,[_OldItemInfo]} = mod_bag:delete_goods(RoleID,ItemInfo#p_goods.id),
            {ItemInfo#p_goods{current_num=0},{func,fun() -> undefined end}}
    end.

%% 批量使用道具判断
assert_multi_use_item(ItemInfo,UseNum,TransModule) when is_integer(UseNum) andalso UseNum > 0 andalso UseNum =< ?MAX_OVER_LAP  ->
	case ItemInfo#p_goods.current_num - UseNum of
		R when R >= 0 ->
			ok;
		_ ->
			TransModule:abort(?_LANG_PARAM_ERROR)
	end.
			
%%doc 使用道具获得一只异兽
get_new_pet(ItemInfo, ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, TransModule) ->
    RoleID = RoleAttr#p_role_attr.role_id,
    {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
    case mod_spring:is_in_spring_map() of
        false ->
            case catch erlang:list_to_integer(Par) of
                {'EXIT',_Reason} ->
                    TransModule:abort(?_LANG_SYSTEM_ERROR);
                PetTypeID ->
                    %% 召唤出来的异兽都属于绑定的
                    case mod_map_pet:t_get_new_pet(RoleAttr#p_role_attr.role_id,PetTypeID,RoleAttr#p_role_attr.level,
                                                   RoleAttr#p_role_attr.role_name,true,RoleBase#p_role_base.faction_id,
                                                   ItemBaseInfo#p_item_base_info.colour) of
                        {ok,PetBagInfo,PetInfo} ->
                            mod_map_pet:refresh_qrhl_data(RoleID),
                            mgeem_persistent:pet_persistent(PetInfo),
                            mgeem_persistent:pet_bag_persistent(PetBagInfo),
                            {NewItemInfo, RoleBase, RoleAttr,[Msg|MsgList], [?_LANG_ITEM_GET_NEW_PET_OK|PromptList]};
                        {error,Reason} ->
                            TransModule:abort(Reason)
                    end 
            end;
        _ ->
            TransModule:abort(<<"温泉不能使用召唤符">>)
    end.

%%doc 使用道具增加异兽生命
add_pet_hp(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, TransModule) ->
     {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_SYSTEM_ERROR);
        HpAddValue ->
            case mod_map_pet:pet_add_hp(RoleAttr#p_role_attr.role_id,HpAddValue) of
                {ok,PetId,NewHp} ->
                    PetMsg = 
                        {func,fun() ->
                                      Record = #m_pet_attr_change_toc{pet_id=PetId,change_type=12,value=NewHp},
                                      common_misc:unicast({role,RoleAttr#p_role_attr.role_id}, ?DEFAULT_UNIQUE, ?PET, ?PET_ATTR_CHANGE, Record)
                         end},
                    {NewItemInfo, RoleBase, RoleAttr,[PetMsg,Msg|MsgList], [?_LANG_PET_ADD_HP_ITEM_USE_OK|PromptList]};
                {error,Reason} ->
                    TransModule:abort(Reason)
            end 
    end.


%%doc 使用道具增加异兽经验
add_pet_exp(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, TransModule) ->
	assert_multi_use_item(ItemInfo,UseNum,TransModule),
	{NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_SYSTEM_ERROR);
        ExpAddValue ->
			TotalExpAddValue = ExpAddValue * UseNum,
            case mod_map_pet:add_pet_exp(RoleAttr#p_role_attr.role_id,TotalExpAddValue,false) of
                {ok,NewPetInfo,NoticeType} ->
                    #p_role_base{role_id=RoleID} = RoleBase,
                    NoticeFun = {func,fun()->
                                              mod_map_pet:notice_after_add_exp(RoleID, NoticeType, NewPetInfo)
                                 end},
                    NewMsgList = [NoticeFun,Msg|MsgList],
                    {NewItemInfo, RoleBase, RoleAttr,NewMsgList, [?_LANG_PET_ADD_EXP_ITEM_USE_OK|PromptList]};
                {error,Reason} ->
                    TransModule:abort(Reason)
            end 
    end.

%%doc 使用异兽经验葫芦
add_pet_refining_exp(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, _Par, _EffectID, UseNum, _State, TransModule) ->
    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    ExpAddValue = (ItemInfo#p_goods.level*1000000000 + ItemInfo#p_goods.quality)*UseNum,
    case mod_map_pet:add_pet_exp(RoleAttr#p_role_attr.role_id,ExpAddValue,false) of
        {ok,NewPetInfo,NoticeType} ->
            #p_role_base{role_id=RoleID} = RoleBase,
            NoticeFun = {func,fun()->
                                      mod_map_pet:notice_after_add_exp(RoleID, NoticeType, NewPetInfo)
                         end},
            NewMsgList = [NoticeFun,Msg|MsgList],
            Content = io_lib:format(?_LANG_PET_ADD_REFINING_EXP_ITEM_USE_OK, [ExpAddValue]),
            {NewItemInfo, RoleBase, RoleAttr,NewMsgList, [Content|PromptList]};
        {error,Reason} ->
            TransModule:abort(Reason)
    end.

%% @doc 加醉酒bufff
add_drunk_buff(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, _Par, _EffectID, UseNum, _State, _TransModule) ->
    mod_item:add_role_drunk_count(RoleAttr#p_role_attr.role_id),
    BuffID = case ItemInfo#p_goods.current_colour of
                 1 -> 10737;
                 2 -> 10738;
                 3 -> 10739;
                 4 -> 10740;
                 _ -> 0 
             end,
    case BuffID =/= 0 of
        true ->
            {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
            {ok, BuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
            mod_role_buff:add_buff(RoleAttr#p_role_attr.role_id,[BuffDetail]), 
            Prompt = lists:flatten(io_lib:format(?_LANG_ITEM_USE_WINE_OK,[common_tool:to_list(ItemInfo#p_goods.name)])),
            {NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],[Prompt|PromptList]};
        false ->
            {ItemInfo,RoleBase,RoleAttr,MsgList,PromptList}
    end.

%%@doc 使用道具召唤副本怪物
item_call_monster(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, TransModule) ->
	#p_role_attr{role_id=RoleID} = RoleAttr,
	case catch erlang:list_to_integer(Par) of
		{'EXIT',_Reason} ->
			?ERROR_MSG("~ts:~w ~w~n",["使用道具召唤副本怪物道具时配置文件出错，错误的配置是",_ItemBaseInfo,_Reason]),
			TransModule:abort(?_LANG_SYSTEM_ERROR);
		MonsterTypeID ->
			{NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
			[mod_map_monster:call_monster_around_role(RoleID,MonsterTypeID,1200) || _S <- lists:seq(1, UseNum)],
			PromptMsg = lists:concat(["成功使用",common_tool:to_list(ItemInfo#p_goods.name)]),
			{NewItemInfo, RoleBase, RoleAttr, [Msg|MsgList], [PromptMsg|PromptList]}
	end.

%% 增加精力值
add_energy(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, TransModule) ->
    EnergyAdd = 
        case catch erlang:list_to_integer(Par) of
            {'EXIT',_Reason} ->
                TransModule:abort(?_LANG_ITEM_ADD_ENERGY_SYSTEM_ERROR);
            EnergyAddT ->
                EnergyAddT*UseNum
        end,
    #p_role_attr{role_id=RoleID} = RoleAttr,
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,RoleExtInfo} ->
            {ok, #p_role_fight{energy=CurEnergy}} = mod_map_role:get_role_fight(RoleID),
            #r_role_map_ext{energy_drug_usage=RoleEnergyUsage} = RoleExtInfo,
            #r_role_energy_drug_usage{count=Count, last_use_time=LastUseTime} = RoleEnergyUsage,
            [CountLimit] = common_config_dyn:find(etc, energy_drug_usage_limit),
            LastUseDate = common_time:time_to_date(LastUseTime),
            {NewItemInfo, Msg, Prompt} = 
                case {CurEnergy >= ?DEFAULT_ENERGY, Count < CountLimit, LastUseDate =:= date()} of
                    {true, _, _} ->
                        TransModule:abort(?_LANG_ITEM_USE_ENERGY_DRUG_NOT_NEED);
                    {false, true, true} ->
                        {ItemInfo2,MsgT} = update_item(RoleID,ItemInfo,UseNum),
                        update_role_energy(RoleID, EnergyAdd, RoleEnergyUsage, RoleExtInfo, Count+1),
                        {ItemInfo2, MsgT, ?_LANG_ITEM_USE_ENERGY_DRUG_OK};
                    {false, _, false} ->
                        {ItemInfo2,MsgT} = update_item(RoleID,ItemInfo,UseNum),
                        update_role_energy(RoleID, EnergyAdd, RoleEnergyUsage, RoleExtInfo, 1),
                        {ItemInfo2, MsgT, ?_LANG_ITEM_USE_ENERGY_DRUG_OK};
                    {_, _, _} -> 
                        Content = common_tool:to_binary(io_lib:format(?_LANG_ITEM_USE_ENERGY_DRUG_TO_MAX, [CountLimit])),
                        TransModule:abort(Content)
                end,
            {NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList], [Prompt|PromptList]};
        _ ->
            {ItemInfo,RoleBase,RoleAttr,MsgList,PromptList}
    end.

update_role_energy(RoleID, EnergyAdd, RoleEnergyUsage, RoleExtInfo, Count) ->
    mod_map_role:t_add_role_energy(RoleID, EnergyAdd),
    NewRoleEnergyUsage = RoleEnergyUsage#r_role_energy_drug_usage{count=Count, last_use_time=common_tool:now()},
    mod_map_role:t_set_role_map_ext_info(RoleID, RoleExtInfo#r_role_map_ext{energy_drug_usage=NewRoleEnergyUsage}).

%%@doc 播放客户端的效果
show_client_effect(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, _TransModule) ->
    #p_role_attr{role_id=RoleID} = RoleAttr,
    {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
    
    #p_goods{typeid=UseItemTypeId} = ItemInfo,
    Effect = #p_item_effect{funid=1000,parameter=Par},
    SendSelf = #m_item_use_special_toc{item_id = UseItemTypeId,
                                       succ = true,
                                       use_status = 2,
                                       use_effect = 2,
                                       effects = [Effect]},
    
    Fun = {func,
           fun() -> 
                   common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?ITEM, ?ITEM_USE_SPECIAL, SendSelf)
           end},
    NewMsgList =  [Fun,Msg|MsgList],
    {NewItemInfo, RoleBase, RoleAttr, NewMsgList, PromptList}.

    
%% @doc 加免战bufff
add_noattack_buff(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, _Par, _EffectID, UseNum, State, TransModule) ->
    #p_goods{current_colour=CurrColor,name=GoodsName} = ItemInfo,
    #p_role_attr{role_id=RoleID} = RoleAttr,
    
    BuffID = case CurrColor of
                 2 -> 10983;    %%免战牌的BUFF
                 3 -> 10984;
                 _ -> 0 
             end,
    #map_state{mapid=MapID} = State,
    %%是否在可以使用免战牌的地图中
    case common_misc:is_in_noattack_buff_valid_map(MapID) of
        true->
            case mod_map_actor:get_actor_mapinfo(RoleID,role) of
                undefined->
                    TransModule:abort(?_LANG_ITEM_USE_NOATTACK_BUFF_STATE_INVALID);
                #p_map_role{state=?ROLE_STATE_FIGHT}->
                    TransModule:abort(?_LANG_ITEM_USE_NOATTACK_BUFF_STATE_INVALID);
                _ ->
                    next
            end,
            case BuffID =/= 0 of
                true ->
                    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
                    {ok, BuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
                    mod_role_buff:add_buff(RoleAttr#p_role_attr.role_id,[BuffDetail]), 
                    
                    Fun = {func,
                           fun() -> 
                                   mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE)    %%修改为和平模式
                           end},
                    Prompt = common_misc:format_lang(?_LANG_ITEM_USE_NOATTACK_BUFF_OK, [common_tool:to_list(GoodsName)]),
                    {NewItemInfo,RoleBase,RoleAttr,[Fun,Msg|MsgList],[Prompt|PromptList]};
                false ->
                    {ItemInfo,RoleBase,RoleAttr,MsgList,PromptList}
            end;
        _ ->
            TransModule:abort(?_LANG_ITEM_USE_NOATTACK_BUFF_MAP_INVALID)
    end.

%% 在符文争夺战中使用buff
add_country_treasure_buff(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, TransModule) ->
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            ?ERROR_MSG("~ts:~w ~w~n",["使用符文争夺战产出的Buff时配置文件出错，错误的配置是",_ItemBaseInfo,_Reason]),
            ErrMsg = lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_USE_BUFF_ERROR,[common_tool:to_list(ItemInfo#p_goods.name)])),
            TransModule:abort(ErrMsg);
        BuffID ->
            case mgeem_map:get_mapid() =:= mod_country_treasure:get_default_map_id() of
                true ->
                    #p_role_attr{role_id=RoleID} = RoleAttr,
                    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
                    {ok, BuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
                    case BuffID =:= 10986 of 
                        true ->
                            %% 无敌符，先debuff
                            mod_role_buff:del_buff_by_type(RoleID, [-1]);
                        false ->
                            ignore
                    end,
                    NewRoleBase = mod_role_buff:add_buff2(RoleBase, [BuffDetail]), 
                    Prompt = lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_USE_BUFF_OK,[common_tool:to_list(ItemInfo#p_goods.name)])),
                    {NewItemInfo,NewRoleBase,RoleAttr,[Msg|MsgList],[Prompt|PromptList]};
                _ ->
                    {ItemInfo,RoleBase,RoleAttr,MsgList,[?_LANG_COUNTRY_TREASURE_USE_BUFF_OUTSIDE | PromptList]}
            end
    end.

%% 使用藏宝图道具
%% 可以获得铜钱，道具，可以召唤小BOSS，可以进入副本，副本5小怪加1精英怪和采集宝箱
%% 需要控制玩家背包满了时出错处理
use_cang_bao_tu(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, _Par, _EffectID, UseNum, _State, TransModule) ->
    {NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
    {ok,_RewardType,_ItemRewardResult,PromptMsg,Fun,NewRoleAttrT} = 
        mod_cang_bao_tu_fb:t_do_use_cang_bao_tu(RoleAttr#p_role_attr.role_id,ItemInfo,TransModule),
    case Fun =:= undefined of
        true ->
            NewMsgList =  [Msg|MsgList];
        _ ->
            NewMsgList =  [Fun,Msg|MsgList]
    end,
    case erlang:is_record(NewRoleAttrT, p_role_attr) of
        true ->
            NewRoleAttr = NewRoleAttrT;
        _ ->
            NewRoleAttr = RoleAttr
    end,
    {NewItemInfo, RoleBase, NewRoleAttr, NewMsgList, [PromptMsg|PromptList]}.

%% 夺命金丹(目前只能在封魔殿对怪物使用)
bomb(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,EffectID,UseNum,_State, TransModule) ->
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_ITEM_BOMB_ERROR);
        ReduceHp ->
            #p_role_attr{role_id=RoleID,role_name=RoleName} = RoleAttr,
            {MonsterID,TypeID} = mod_bigpve_fb:look_monsterInfo(EffectID),
            case MonsterID > 0 andalso mod_bigpve_fb:is_role_in_map() =:= true of
                true ->
                    [#p_monster_base_info{monstername=MonsterName}] = cfg_monster:find(TypeID),
                    ReduceFunc = {func, 
                                  fun() -> 
                                          mgeem_map:absend({apply, mgeem_map, do_broadcast_insence_include,[[{role,RoleID}],?BIGPVE,?BIGPVE_BOMB,
                                                                                 #m_bigpve_bomb_toc{monster_id=EffectID,reduce_hp=ReduceHp},mgeem_map:get_state()]}),
                                          SendMessage = {mod_map_monster,{reduce_hp,EffectID, ReduceHp, RoleID, role}},
                                          common_misc:send_to_rolemap(RoleID,SendMessage),
                                          mod_bigpve_fb:hook_use_bomb(RoleID)
                                  end},
                    {NewItemInfo, NoticeFunc} = update_item(RoleID, ItemInfo, UseNum),
                    Msg = common_misc:format_lang("【~s】怒气大发，向【~s】投了一颗夺命金丹，威力惊人。",[common_tool:to_list(RoleName),common_tool:to_list(MonsterName)]),
                    ?WORLD_CENTER_BROADCAST(Msg),
                    {NewItemInfo,RoleBase,RoleAttr,[ReduceFunc,NoticeFunc|MsgList],[PromptList]};
                false ->
                    case MonsterID =:= 0 of
                        true ->
                            nil;
                        false ->
                            TransModule:abort(?_LANG_ITEM_USE_BOMB_ONLY_IN_BIGPVE_FB)
                    end
            end
    end.

%%使用积分卡加积分
add_jifen(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
	#p_role_attr{role_id=RoleID} = RoleAttr,
	{NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
	case catch erlang:list_to_integer(Par) of
		{'EXIT',_Reason} ->
			TransModule:abort(?_LANG_SYSTEM_ERROR);
		AddJifen ->
            AddJifen1 = AddJifen*UseNum,
			case catch mod_vip:assert_use_vip_card(RoleID) of
				{error,ErrCode,_ErrReason} ->
					if
						ErrCode =:= ?ERR_SYS_ERR ->
							TransModule:abort(?_LANG_SYSTEM_ERROR);
						true ->
							TransModule:abort(ErrCode)
					end;
				{ok,_VipInfo} ->
					mgeer_role:absend(RoleID,{mod_vip,{add_jifen,RoleID,AddJifen1}}),
					{NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],[concat(["使用星级积分卡增加",erlang:integer_to_list(AddJifen1),"星级积分"])|PromptList]}
			end
	end. 

%%增加阅历
add_yueli(ItemInfo,_ItemBaseInfo,RoleBase,_RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
    RoleID = RoleBase#p_role_base.role_id,
    {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_SYSTEM_ERROR);
        AddYueli ->
            AddYueli1 = AddYueli*UseNum,
            {ok,RoleAttr1} = common_bag2:t_gain_yueli(AddYueli1, RoleID, ?GAIN_TYPE_YUELI_BY_ITEM_CARD),
            ChangeList = [#p_role_attr_change{change_type=?ROLE_YUELI_ATTR_CHANGE,new_value=RoleAttr1#p_role_attr.yueli}],
            DataRec = #m_role2_attr_change_toc{roleid=RoleID,changes=ChangeList},
            {NewItemInfo,RoleBase,RoleAttr1,[DataRec,Msg|MsgList],[concat(["使用阅历卡增加",erlang:integer_to_list(AddYueli1),"阅历"])|PromptList]}
    end. 

%%增加怒气
add_nuqi(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
    RoleID = RoleBase#p_role_base.role_id,
    {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
    case catch erlang:list_to_integer(Par) of
        {'EXIT',_Reason} ->
            TransModule:abort(?_LANG_SYSTEM_ERROR);
        AddNuqi ->
            AddNuqi1 = AddNuqi*UseNum,
            mgeem_map:run(fun() -> mod_map_role:add_nuqi(RoleID, AddNuqi1) end),
            {NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],[concat(["使用道具增加",erlang:integer_to_list(AddNuqi1),"怒气"])|PromptList]}
    end.    

%%使用体力卡加体力
add_tili(ItemInfo,_ItemBaseInfo,RoleBase,RoleAttr,MsgList,PromptList,Par,_EffectID,UseNum,_State, TransModule) ->
	#p_role_attr{role_id=RoleID} = RoleAttr,
  case catch erlang:list_to_integer(Par) of
    {'EXIT',_Reason} ->
      TransModule:abort(?_LANG_SYSTEM_ERROR);
    AddTili ->
      case catch mod_tili:use_tili_card(RoleID, AddTili, UseNum) of
        {error,_ErrCode,ErrReason} ->
          TransModule:abort(ErrReason);
        {ok,RoleTili, ActullyUsed} ->
          case ActullyUsed =< 0 of
            true -> TransModule:abort(<<"您现在无需使用体力卡">>);
            false -> ignore
          end,
          {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,ActullyUsed),
          AddTili1 = ActullyUsed*AddTili,
          mod_tili:cast_role_tili_info(RoleTili),
          {NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],[concat(["使用体力卡增加",erlang:integer_to_list(AddTili1),"体力"])|PromptList]}
      end
	end. 

%% 使用可减少技能时间CD BUFF的道具
reduce_skill_cd(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, TransModule) ->
	case catch erlang:list_to_integer(Par) of
		{'EXIT',_Reason} ->
			?ERROR_MSG("~ts:~w ~w~n",["使用使用可减少技能时间CD BUFF的道具时配置文件出错，错误的配置是",_ItemBaseInfo,_Reason]),
			TransModule:abort(?_LANG_SYSTEM_ERROR);
		BuffID ->
			{NewItemInfo,Msg} = update_item(RoleAttr#p_role_attr.role_id,ItemInfo,UseNum),
			{ok, BuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
			mod_role_buff:add_buff(RoleAttr#p_role_attr.role_id,[BuffDetail]), 
			Prompt = lists:concat(["成功使用",common_tool:to_list(ItemInfo#p_goods.name)]),
			{NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],[Prompt|PromptList]}
	end.

add_guard_fb_buff(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, _Par, _EffectID, UseNum, _State, _TransModule) ->
	case mod_guard_fb:is_in_fb_map() of
		true ->
			#p_role_attr{role_id=RoleID,level=Level} = RoleAttr,
			{NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
			mgeer_role:absend(RoleID, {mod_guard_fb, {add_buff_item_buff,RoleID,ItemInfo#p_goods.typeid,Level}}),
			Prompt = lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_USE_BUFF_OK,[common_tool:to_list(ItemInfo#p_goods.name)])),
			{NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],[Prompt|PromptList]};
		_ ->
			{ItemInfo,RoleBase,RoleAttr,MsgList,[<<"该物品只能在圣女魔尊洞窟中使用">> | PromptList]}
	end.

add_gongxun(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, TransModule) ->
	case catch erlang:list_to_integer(Par) of
		{'EXIT',_Reason} ->
			?ERROR_MSG("~ts:~w ~w~n",["使用战功卡时配置文件出错，错误的配置是",_ItemBaseInfo,_Reason]),
			TransModule:abort(?_LANG_SYSTEM_ERROR);
		AddGongxun ->
            AddGongxun1 = AddGongxun*UseNum,
			#p_role_attr{gongxun=Gongxun,role_id=RoleID}=RoleAttr,
			NewRoleAttr2 = RoleAttr#p_role_attr{gongxun=Gongxun+AddGongxun1},
			GongxunMsg = 
				{func,fun() ->
							  AttrChangeList = [{gongxun, NewRoleAttr2#p_role_attr.gongxun}],
							  DataRecord2 = #m_role2_attr_change_toc{roleid=RoleID, changes=common_role:get_attr_change_list(AttrChangeList)},
							  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord2)
				 end},
			{NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
			{NewItemInfo,RoleBase,NewRoleAttr2,[GongxunMsg,Msg|MsgList],[concat(["使用战功卡增加",erlang:integer_to_list(AddGongxun1),"战功"])|PromptList]}
	end.

use_soap(ItemInfo, _ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, _Par, EffectID, UseNum, _State, _TransModule) ->
    case mod_spring:is_in_spring_map() of
        true ->
            #p_role_attr{role_id=RoleID,role_name=RoleName} = RoleAttr,
            ItemName = common_tool:to_list(ItemInfo#p_goods.name),
            case mod_spring:check_can_use(RoleID,RoleAttr,EffectID,ItemInfo) of
                {ok,NewSpringRoleInfo,NewBSpringRoleInfo,NewValue,{SelfAddExp,SelfAddPrestige},{EffectName,OtherAddExp,OtherAddPrestige}} ->
                    {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
                    mgeem_map:send({mod_spring, {{use_item,self},RoleID,NewSpringRoleInfo,NewValue,ItemInfo#p_goods.typeid,{SelfAddExp,SelfAddPrestige},{RoleName,EffectName}}}),
                    mgeem_map:send({mod_spring, {{use_item,other},EffectID,ItemInfo#p_goods.typeid,{OtherAddExp,OtherAddPrestige},{RoleName,EffectName},NewBSpringRoleInfo}}),
                    Prompt = lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_USE_BUFF_OK,[ItemName])),
                    {NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],[Prompt|PromptList]};
                {error,Msg} when erlang:is_binary(Msg)->
                    {ItemInfo,RoleBase,RoleAttr,MsgList,[Msg | PromptList]}
            end;
        _ ->
            {ItemInfo,RoleBase,RoleAttr,MsgList,[<<"该物品只能在温泉中使用">> | PromptList]}
    end.

use_huoling(ItemInfo, ItemBaseInfo, RoleBase, RoleAttr, MsgList, PromptList, Par, _EffectID, UseNum, _State, _TransModule) ->
    ItemID = ItemInfo#p_goods.typeid,
    RoleID = RoleAttr#p_role_attr.role_id,

    case lists:keymember(ItemID, 2, cfg_nuqi_huoling:is_huoling_element_item_id()) of
        true ->
            mod_nuqi_huoling:add_yihuo_element(RoleID, ItemInfo#p_goods.typeid, UseNum),
            {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
            {NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],["使用异火元素成功"|PromptList]};
        false -> 
            TypeID = list_to_integer(Par),
            % true = lists:member(ItemID, cfg_nuqi_huoling:is_huoling_yihuo_item_id()),
            {_, ExistNum} = mod_nuqi_huoling:add_yihuo(RoleID, ItemBaseInfo, UseNum, TypeID),

            case ExistNum > 0 of
                true -> 
                    CreateInfo = #r_goods_create_info{
                        bind    = true, 
                        type    = ?TYPE_ITEM, 
                        type_id = ItemID, 
                        num     = ExistNum
                    },
                    Message = ?_LANG_YIHUO_ITEM, 
                    GoodsList = common_misc:get_mail_items_create_info(RoleID, [CreateInfo]),
                    common_letter:sys2p(RoleID,Message,"异火道具", GoodsList,14);
                false -> ignore
            end, 

            {NewItemInfo,Msg} = update_item(RoleID,ItemInfo,UseNum),
            {NewItemInfo,RoleBase,RoleAttr,[Msg|MsgList],["使用异火成功"|PromptList]}
    end.



