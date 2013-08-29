%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2011, 
%%% @doc
%%% 玩家礼包模块
%%% @end
%%% Created : 20 Apr 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_gift).

%% INCLUDE
-include("mgeem.hrl").
-include("gift.hrl").

%% API
-export([
         handle/1,
         do_handle_info/1,
         hook_category_change/3
        ]).
-export([
         get_p_goods_by_reward_prop/2,
         get_p_goods_by_item_gift_base_record/1,
		 set_role_gift_extend/2,
		 get_role_gift_extend/2,
		 del_role_gift_extend/2
        ]).

%%%===================================================================
%%% API
%%%===================================================================

do_handle_info(Info)->
    handle(Info).

handle({_, ?GIFT, ?GIFT_ITEM_QUERY,_,_,_,_}=Info) ->
    %% 道具礼包查询
    do_gift_item_query(Info);
handle({_, ?GIFT, ?GIFT_ITEM_AWARD,_,_,_,_}=Info) ->
    %% 道具礼包领奖
    do_gift_item_award(Info);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


%% Extend={typeid,random}
set_role_gift_extend(RoleID,Extend) ->
	NewRoleGift = 
		case db:dirty_read(?DB_ROLE_GIFT,RoleID) of
			[] ->
				#r_role_gift{role_id=RoleID,extend=[Extend]};
			[#r_role_gift{extend=ExtendList}=RoleGift] ->
				{Key,_} = Extend,
				RoleGift#r_role_gift{extend=[Extend|lists:keydelete(Key, 1, ExtendList)]}
		end,
	db:dirty_write(?DB_ROLE_GIFT,NewRoleGift).

del_role_gift_extend(RoleID,ExtendKey) ->
	case db:dirty_read(?DB_ROLE_GIFT,RoleID) of
		[] ->
			ignore;
		[#r_role_gift{extend=ExtendList}=RoleGift] ->
			db:dirty_write(?DB_ROLE_GIFT,RoleGift#r_role_gift{extend=lists:keydelete(ExtendKey, 1, ExtendList)})
	end.

get_role_gift_extend(RoleID,ExtendKey) ->
	case db:dirty_read(?DB_ROLE_GIFT,RoleID) of
		[] ->
			0;
		[#r_role_gift{extend=ExtendList}] ->
			case lists:keyfind(ExtendKey, 1, ExtendList) of
				false -> 0;
				{ExtendKey,Random} -> Random
			end
	end.

%%%===================================================================
%%% Internal functions
%%%===================================================================


%%@interface 道具礼包查询
do_gift_item_query({Unique, Module, Method, _DataIn, RoleID, PID, _Line}=Info)->
    case catch check_do_gift_item_query(RoleID) of
        {ok,?GIFT_ITEM_STATUS_INIT,AwardGoods,AwardLevel,ItemGiftBase}->
            do_gift_item_query_2(Info,AwardGoods,AwardLevel,ItemGiftBase);
        {ok,AwardGoods,AwardLevel,_ItemGiftBase}->
            R2 = #m_gift_item_query_toc{succ=true,cur_goods=[AwardGoods],award_role_level=AwardLevel},
            ?UNICAST_TOC(R2);
        {error,ErrCode,Reason}->
            R2 = #m_gift_item_query_toc{succ=false,reason=Reason,reason_code=ErrCode},
            ?UNICAST_TOC(R2)
    end.

check_do_gift_item_query(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{category=RoleCategory} ->
			case RoleCategory of
				0 ->
					erlang:throw({error,?_LANG_GIFT_ITEM_AWARD_ERROR,0});
				_ ->
					next
			end;
        _ ->
            RoleCategory = null,
            erlang:throw({error,?_LANG_GIFT_ITEM_AWARD_ERROR,0})
    end,
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined ->
            erlang:throw({error,?_LANG_GIFT_ITEM_AWARD_ERROR,0});
        _ ->
            next
    end,
    case db:dirty_read(?DB_ROLE_GIFT,RoleID) of
        []->
            get_next_award_gift(RoleID,RoleCategory);
        [#r_role_gift{gifts=[]}]->
            get_next_award_gift(RoleID,RoleCategory);

        %%已经创建物品
        [#r_role_gift{gifts=[H|_T]}]->
            #r_role_gift_info{cur_gift=CurGift,expand_field=ExpandField,status=Status} = H,
            case Status of
                ?GIFT_ITEM_STATUS_AWARD->
                    get_next_award_gift(RoleID,RoleCategory,ExpandField);
                _ ->
                    case CurGift of
                        [AwardGoods]->next;
                        AwardGoods when is_record(AwardGoods,p_goods)->
                            next
                    end,
                    #r_item_gift_base{role_level=AwardLevel} = ItemGiftBase = ExpandField,
                    {ok,AwardGoods,AwardLevel,ItemGiftBase}
            end
    end.


do_gift_item_query_2({Unique, Module, Method, _DataIn, RoleID, PID, _Line},AwardGoods,AwardLevel,ItemGiftBase)->
    TransFun = fun() -> 
                       t_gift_item_query(RoleID,AwardGoods,ItemGiftBase)
               end,
    case db:transaction( TransFun ) of
        {atomic, ok} ->
            R2 = #m_gift_item_query_toc{succ=true,cur_goods=[AwardGoods],award_role_level=AwardLevel},
            ?UNICAST_TOC(R2);
        {aborted, Error} ->
            case Error of
                {Reason, ErrCode} when is_binary(Reason) ->
                    R2 = #m_gift_item_query_toc{succ=false,reason=Reason,reason_code=ErrCode},
                    ?UNICAST_TOC(R2);
                _ ->
                    ?ERROR_MSG("~ts,RoleId=~w,Error=~w",["查询道具礼包出错",RoleID,Error]),
                    R2 = #m_gift_item_query_toc{succ=false,reason=?_LANG_GIFT_ITEM_QUERY_ERROR,reason_code=0},
                    ?UNICAST_TOC(R2)
            end
    end.

%%@return {ok,AwardGoods,AwardLevel}
t_gift_item_query(RoleID,AwardGoods,ItemGiftBase)->
    %%设置为未领取状态
    CurGiftList = case is_list(AwardGoods) of
                      true-> AwardGoods;
                      _ -> [AwardGoods]
                  end,
                      
    RoleGiftInfo = #r_role_gift_info{gift_type=?GIFT_TYPE_ITEM,cur_gift=CurGiftList,status=?GIFT_ITEM_STATUS_INIT,expand_field=ItemGiftBase},
    case db:read(?DB_ROLE_GIFT,RoleID) of
        []->
            RoleGiftRec2 = #r_role_gift{role_id = RoleID,gifts = [RoleGiftInfo]};
        [RoleGiftRec1] ->
            RoleGiftRec2 = RoleGiftRec1#r_role_gift{role_id = RoleID,gifts = [RoleGiftInfo]}
    end,
    db:write(?DB_ROLE_GIFT,RoleGiftRec2,write),
    ok.

%%@interface 道具礼包领奖
do_gift_item_award({Unique, Module, Method, _DataIn, RoleID, PID, _Line}=Info)->
    case catch check_do_gift_item_award(RoleID) of
        {ok,AwardGoods,ItemGiftBase}->
            do_gift_item_award_2(Info,AwardGoods,ItemGiftBase);
        {error,ErrCode,Reason}->
            R2 = #m_gift_item_award_toc{succ=false,reason=Reason,reason_code=ErrCode},
            ?UNICAST_TOC(R2)
    end.

do_gift_item_award_2({Unique, Module, Method, _DataIn, RoleID, PID, _Line},AwardGoods,ItemGiftBase)->
    TransFun = fun()->
                       t_gift_item_award(RoleID,AwardGoods,ItemGiftBase)
               end,
    case db:transaction( TransFun ) of
        {atomic, {ok,AwardGoodsList}} ->
            common_item_logger:log(RoleID,AwardGoods,?LOG_ITEM_TYPE_GIFT_ITEM_AWARD),
            common_misc:update_goods_notify({role, RoleID}, AwardGoodsList),
            
            R2 = #m_gift_item_award_toc{succ=true,award_goods=AwardGoodsList};
        {aborted, Error} ->
            case Error of
                {throw,{bag_error,{not_enough_pos,_}}}->
                    R2 = #m_gift_item_award_toc{succ=false,reason=?_LANG_GIFT_ITEM_AWARD_NOT_BAG_POS};
                {Reason, ErrCode} when is_binary(Reason) ->
                    R2 = #m_gift_item_award_toc{succ=false,reason=Reason,reason_code=ErrCode};
                _ ->
                    ?ERROR_MSG("~ts,RoleId=~w,Error=~w",["查询领取礼包出错",RoleID,Error]),
                    R2 = #m_gift_item_award_toc{succ=false,reason=?_LANG_GIFT_ITEM_AWARD_ERROR,reason_code=0}
            end
    end,
    ?UNICAST_TOC(R2).

t_gift_item_award(RoleID,AwardGoods,ItemGiftBase)->
    {ok,AwardGoodsList} = mod_bag:create_goods_by_p_goods(RoleID,AwardGoods),
    
    RoleGiftInfo = #r_role_gift_info{gift_type=?GIFT_TYPE_ITEM,cur_gift=[AwardGoods],status=?GIFT_ITEM_STATUS_AWARD,expand_field=ItemGiftBase},
    case db:read(?DB_ROLE_GIFT,RoleID) of
        []->
            RoleGiftRec2 = #r_role_gift{role_id = RoleID,gifts = [RoleGiftInfo]};
        [RoleGiftRec1] ->
            RoleGiftRec2 = RoleGiftRec1#r_role_gift{role_id = RoleID,gifts = [RoleGiftInfo]}
    end,
    db:write(?DB_ROLE_GIFT,RoleGiftRec2,write),
    {ok,AwardGoodsList}.
        
%%检查并返回可以领奖的物品
check_do_gift_item_award(RoleID)->
    case check_do_gift_item_query(RoleID) of
        {ok,?GIFT_ITEM_STATUS_INIT,AwardGoods,AwardLevel,ItemGiftBase}->
            next;
        {ok,AwardGoods,AwardLevel,ItemGiftBase}->
            next;
        {error,ErrCode,Reason}->
            AwardGoods = AwardLevel = ItemGiftBase = null,
            erlang:throw({error,Reason,ErrCode})
    end,
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{level=RoleLevel} ->
            if
                RoleLevel>=AwardLevel->
                    next;
                true->
                    erlang:throw({error,common_tool:get_format_lang_resources(?_LANG_GIFT_ITEM_AWARD_AWARD_ROLE_LEVEL,[AwardLevel]),0})
            end;
        _ ->
            erlang:throw({error,?_LANG_GIFT_ITEM_AWARD_ERROR,0})
    end,
    {ok,AwardGoods,ItemGiftBase}.

get_all_item_gift_list()->
    [GiftIdList] = common_config_dyn:find(item_gift,item_gift_list),
    GiftIdList.

%%@doc 获取下一个可以领奖的物品
get_next_award_gift(RoleID,RoleCategory)->
    AllGiftIdList = get_all_item_gift_list(),
    get_next_award_gift_2(RoleID,RoleCategory,0,AllGiftIdList).

get_next_award_gift(RoleID,RoleCategory,ExpandField) when is_record(ExpandField,r_item_gift_base)->
    #r_item_gift_base{id=Id} = ExpandField,
    AllGiftIdList = get_all_item_gift_list(),
    get_next_award_gift_2(RoleID,RoleCategory,Id,AllGiftIdList).

%%根据上一次领奖的ID查询下一次的领奖物品
get_next_award_gift_2(_RoleID,_,_,[])->
    {error,0,?_LANG_GIFT_ITEM_QUERY_NOT_GIFT};
get_next_award_gift_2(RoleID,RoleCategory,LastGiftId,[H|T]) when is_integer(LastGiftId)->
    case LastGiftId<H of
        true-> 
            [AllList] = common_config_dyn:find(item_gift,item_gift_base),
            {_,ItemGiftBaseList} = lists:keyfind(H, 1, AllList), 
            case ItemGiftBaseList of
                [ItemGiftBase]->
                    next;
                _ ->
                    %%根据职业获取对应的物品
                    ItemGiftBase = lists:keyfind(RoleCategory, #r_item_gift_base.category, ItemGiftBaseList)
            end,
          
            #r_item_gift_base{role_level=RoleLevel} = ItemGiftBase,
            {ok,GoodsList} = get_p_goods_by_item_gift_base_record(ItemGiftBase),
            [AwardGoods|_] = [Goods#p_goods{id = ?GIFT_ITEM_GOODS_ID,roleid = RoleID,bagid = 0,bagposition = 0}|| Goods <- GoodsList],
            
            {ok,?GIFT_ITEM_STATUS_INIT,AwardGoods,RoleLevel,ItemGiftBase};
        _ ->
            get_next_award_gift_2(RoleID,RoleCategory,LastGiftId,T)
    end;
get_next_award_gift_2(_,_,_,_)->
    {error,0,?_LANG_GIFT_ITEM_QUERY_NOT_GIFT}.



%% @doc 根据奖励配置生成p_goods
%% @return {ok,GoodsList} or {error,Reason}
get_p_goods_by_reward_prop(RoleID,RewardProp) when is_record(RewardProp,r_reward_prop) ->
    #r_reward_prop{prop_id=PropId,num=Num,bind=IsBind,color=ColorArg} = RewardProp,
    PropType = common_misc:get_prop_type(PropId),
    
    {Color,Quality,SubQuality} = get_quality_by_color(PropType,ColorArg),
    %%增加创建物品时负数的判断
    case Num =< 0 of
        true ->
            throw({error,num_must_larger_than_zero});
        false ->
            ignore
    end,
    BagID = BagPos = 1,
    
    case PropType of
        ?TYPE_ITEM ->
            CreateInfo = #r_item_create_info{role_id=RoleID, num=Num, typeid=PropId, bind=IsBind,color=Color,
                                             bag_id=BagID,bagposition=BagPos},
            common_bag2:create_item(CreateInfo);
        ?TYPE_STONE ->
            CreateInfo = #r_stone_create_info{role_id=RoleID, num=Num, typeid=PropId, bind=IsBind,
                                              bag_id=BagID,bagposition=BagPos},
            common_bag2:creat_stone(CreateInfo);
        ?TYPE_EQUIP ->
            CreateInfo = #r_equip_create_info{role_id=RoleID, num=Num, typeid=PropId, bind=IsBind,sub_quality = SubQuality,
                                              color=Color, quality=Quality, punch_num=0,
                                              bag_id=BagID,bagposition=BagPos},
            {ok,GoodsList1} = common_bag2:creat_equip_without_expand(CreateInfo),
            GoodsList2 = [ mod_refining:equip_colour_quality_add(new,Goods1,Color,Quality,SubQuality)||Goods1<-GoodsList1 ],
            {ok,GoodsList2}
    end.

get_quality_by_color(PropType,ColorArg)->
    if
        ColorArg =:= undefined ->
            Color = 0;
        true ->
            %%默认是0，这样就按照装备的配置中指定颜色来赠送
            Color = ColorArg
    end,
    
    case PropType of
        ?TYPE_EQUIP ->
            {Quality,SubQuality} = mod_refining_tool:get_equip_quality_by_color(Color),
            next;
        _ ->
            SubQuality = 1,
            Quality = ?QUALITY_GENERAL
    end,
    {Color,Quality,SubQuality}.


%% 根据道具礼包配置生成p_goods
%% ItemGiftBase 结构 r_item_gift_base
%% 返回 {ok,GoodsList} or {error,Reason}
get_p_goods_by_item_gift_base_record(ItemGiftBase) ->
    #r_item_gift_base{item_type = ItemType,item_id = ItemId,item_number = ItemNumber,
                      bind = ItemBind,
                      start_time = PStartTime,end_time = PEndTime,days = PDays,
                      color = ColorList,quality = QualityList,sub_quality = SubQualityList,
                      punch_num = PunchNum,
                      reinforce = ReinforceList} = ItemGiftBase,
    Bind = if ItemBind =:= 0 ->
                   false;
              ItemBind =:= 100 ->
                   true;
              true ->
                   RandomNumber = random:uniform(100),
                   if ItemBind >= RandomNumber ->
                           true;
                      true ->
                           false
                   end
           end,
    NowSeconds = common_tool:now(),
    {StartTime,EndTime} = 
        if PStartTime =:= 0 andalso PEndTime =:= 0 andalso PDays =/= 0 ->
                {NowSeconds - 5, NowSeconds + 24*60*60 * PDays};
           PStartTime =/= 0 andalso PEndTime =/= 0 andalso PDays =:= 0 ->
                {PStartTime,PEndTime};
           PStartTime =:= 0 andalso PEndTime =/= 0 andalso PDays =:= 0 ->
                {NowSeconds - 5,PEndTime};
           true ->
                {0,0}
        end,
    CreateInfo =
        if ItemType =:= ?TYPE_EQUIP ->
                [EquipBaseInfo] = common_config_dyn:find_equip(ItemId),
                case EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT of
                    true ->
                        Color = 1,Quality = 0,SubQuality = 0;
                    _ ->
                        Color = mod_refining:get_random_number(ColorList,0,1),
                        Quality = mod_refining:get_random_number(QualityList,0,1),
                        SubQuality = mod_refining:get_random_number(SubQualityList,0,1)
                end,
                if ReinforceList =:= [] ->
                        ReinforceResult = 0,
                        ReinforceRate = 0;
                   true ->
                        ReinforceResult = lists:max(ReinforceList),
                        ReinforceLevel = ReinforceResult div 10,
                        ReinforceGrade = ReinforceResult rem 10,
                        [ReinforceRateList] = common_config_dyn:find(refining,reinforce_rate),
                        {_,ReinforceRate} = lists:keyfind({ReinforceLevel,ReinforceGrade},1,ReinforceRateList)
                end,
                #r_equip_create_info{num=ItemNumber,typeid = ItemId,bind=Bind,start_time = StartTime,
                                     end_time = EndTime,color=Color,quality=Quality,sub_quality = SubQuality,
                                     punch_num=PunchNum,rate=ReinforceRate,result=ReinforceResult,result_list=ReinforceList};
           ItemType =:= ?TYPE_STONE ->
                #r_stone_create_info{num=ItemNumber,typeid = ItemId,bind=Bind,start_time = StartTime,end_time = EndTime};
           true ->
                Color = mod_refining:get_random_number(ColorList,0,1),
                #r_item_create_info{num = ItemNumber,typeid = ItemId,bind=Bind,start_time = StartTime,end_time = EndTime, color=Color}
        end,
    ?DEBUG("~ts,CreateInfo=~w",["创建奖励道具",CreateInfo]),
    if ItemType =:= ?TYPE_EQUIP ->
            case common_bag2:creat_equip_without_expand(CreateInfo) of
                {ok,EquipGoodsList} ->
                    [EquipBaseInfo2] = common_config_dyn:find_equip(ItemId),
                    case EquipBaseInfo2#p_equip_base_info.slot_num =:= ?PUT_MOUNT
                        orelse EquipBaseInfo2#p_equip_base_info.slot_num =:= ?PUT_FASHION of
                        true ->
                            {ok,EquipGoodsList};
                        _ ->
                            get_p_goods_by_item_gift_base_record2(ItemGiftBase,EquipGoodsList)
                    end;
                {error,EquipError} ->
                    {error,EquipError}
            end;
       ItemType =:= ?TYPE_STONE ->
            common_bag2:creat_stone(CreateInfo);
       ItemType =:= ?TYPE_ITEM ->
            common_bag2:create_item(CreateInfo);
        true ->
            {error,item_type_error}
    end.
%% AddAttrList 结构为装备绑定属性的[{code,level},...]
get_p_goods_by_item_gift_base_record2(ItemGiftBase,EquipGoodsList) ->
    #r_item_gift_base{item_id = ItemId,add_attr = AddAttrList} = ItemGiftBase,
    [EquipBaseInfo] = common_config_dyn:find_equip(ItemId),
    EquipGoodsList2 = 
        lists:map(
          fun(Goods) ->
                  %% 颜色品质处理
                  Goods2 = mod_refining:equip_colour_quality_add(new,Goods,1,1,1),
                  %% 强化处理
                  Goods3 = mod_equip_change:equip_reinforce_property_add(Goods2,EquipBaseInfo),
                  %% 绑定属性
                  Goods4 = mod_refining_bind:do_equip_bind_for_item_gift(Goods3,EquipBaseInfo,AddAttrList),
                  %% 精炼系数处理
                  Goods5 = 
                      case common_misc:do_calculate_equip_refining_index(Goods4) of
                          {ok,Goods4T} ->
                              Goods4T;
                          {error,_RefiningIndexError} ->
                              Goods4
                      end,
                  Goods5#p_goods{stones = []}
          end,EquipGoodsList),
    {ok,EquipGoodsList2}.

%% 玩家职业信息需要重新更新道具奖励
hook_category_change(_RoleId,_RoleLevel,_Category) ->
    ignore.
