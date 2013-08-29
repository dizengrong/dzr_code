%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2011, 
%%% @doc
%%% 精练系统模块共用工具类
%%% @end
%%% Created : 27 Apr 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_refining_tool).

%% INCLUDE
-include("mgeem.hrl").
%% API
-export([
         get_p_goods_by_special/2,
         get_equip_color_by_quality/2,
         get_equip_quality_by_color/1,
         get_p_goods_by_param/1
        ]).

%%%===================================================================
%%% API
%%%===================================================================
%% 装备的品质计算装备的颜色
get_equip_color_by_quality(Quality,SubQuality) ->
    [QualityToColor] = common_config_dyn:find(refining,quality_to_color),
    [MaxSubQuality] = common_config_dyn:find(refining,equip_change_quality_sub_max_level),
    SumQuality = 
        case (Quality - 1) < 0 of
            true ->
                SubQuality;
            _ ->
                (Quality - 1) * MaxSubQuality + SubQuality
        end,
    lists:foldl(
      fun({MinQuality,MaxQuality,CurColor},AccColor) ->
              case SumQuality >= MinQuality andalso MaxQuality >= SumQuality of
                  true ->
                      CurColor;
                  _ ->
                      AccColor
              end
      end,1,QualityToColor).
%% 装备的颜色计算装备的品质和子品质
%% 返回 {Quality,SubQuality}
get_equip_quality_by_color(Color) ->
    [ColorToQualityList] = common_config_dyn:find(refining,color_to_quality),
    case lists:keyfind(Color,1,ColorToQualityList) of
        false ->
            Quality = 1,
            SubQuality = 1;
        {Color,Quality,SubQuality} ->
            ignore
    end,
    {Quality,SubQuality}.
    
%% 返回相应的p_goods
%% CreateGoodsSpecialRecord 结构为 r_goods_create_special
%% 返回结果 {ok,GoodsList},{error,Reason}
get_p_goods_by_special(RoleID,CreateGoodsSpecialRecord) ->
    #r_goods_create_special{item_type = ItemType,item_id = ItemId,item_num = ItemNum,
                            bind = ItemBind,start_time = PStartTime,end_time = PEndTime,days = PDays,
                            color = _ColorList,quality = QualityList,sub_quality = SubQualityList,
                            reinforce = ReinforceList,punch_num = PPunchNum,stons =StonsList} = CreateGoodsSpecialRecord,
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
    PunchNum = 
        case erlang:length(StonsList) > PPunchNum of
            true ->
                erlang:length(StonsList);
            false ->
                PPunchNum
        end,
    CreateInfo =
		if ItemType =:= ?TYPE_EQUIP ->
			   Quality = mod_refining:get_random_number(QualityList,0,1),
			   SubQuality = mod_refining:get_random_number(SubQualityList,0,1),
			   Color = mod_refining_tool:get_equip_color_by_quality(Quality,SubQuality),
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
                #r_equip_create_info{num=ItemNum,typeid = ItemId,bind=Bind,start_time = StartTime,
                                     end_time = EndTime,color=Color,quality=Quality,sub_quality = SubQuality,
                                     punch_num=PunchNum,rate=ReinforceRate,result=ReinforceResult,result_list=ReinforceList};
           ItemType =:= ?TYPE_STONE ->
                #r_stone_create_info{num=ItemNum,typeid = ItemId,bind=Bind,start_time = StartTime,end_time = EndTime};
           true ->
                #r_item_create_info{num = ItemNum,typeid = ItemId,bind=Bind,start_time = StartTime,end_time = EndTime}
        end,
    ?DEBUG("~ts,CreateInfo=~w",["创建奖励道具",CreateInfo]),
    if ItemType =:= ?TYPE_EQUIP ->
            ?DEBUG("~w",[common_bag2:creat_equip_without_expand(CreateInfo)]),
            case common_bag2:creat_equip_without_expand(CreateInfo) of
                {ok,EquipGoodsList} ->
                    get_p_goods_by_special2(RoleID,CreateGoodsSpecialRecord,EquipGoodsList);
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
%% 处理装备道具附加属性和宝石
get_p_goods_by_special2(RoleID,CreateGoodsSpecialRecord,EquipGoodsList) ->
    #r_goods_create_special{item_id = ItemId,stons =StonsList,
                            add_attr = AddAttrList} = CreateGoodsSpecialRecord,
    [EquipBaseInfo] = common_config_dyn:find_equip(ItemId),
    EquipGoodsList2 = 
        lists:map(
          fun(Goods) ->
                  %% 颜色品质处理
                  Goods2 = mod_refining:equip_colour_quality_add(new,Goods,1,1,1),
                  %% 强化处理
                  Goods3 = mod_equip_change:equip_reinforce_property_add(Goods2,EquipBaseInfo),
                  %% 洗炼属性
                  Goods4 = mod_refining_bind:do_equip_bind_for_item_gift(Goods3,EquipBaseInfo,AddAttrList),
                  %% 宝石处理
                  Goods5 = 
                      lists:foldl(
                        fun(StoneTypeId,AccGoods) ->
                                StoneCreateInfo = #r_stone_create_info{num=1,typeid=StoneTypeId,bind=true},
                                case common_bag2:creat_stone(StoneCreateInfo) of
                                    {ok,[StoneGoods]} ->
                                        AccStoneList = AccGoods#p_goods.stones,
                                        EmbePos = AccGoods#p_goods.stone_num + 1,
                                        StoneGoods2 = StoneGoods#p_goods{roleid=RoleID,
                                                                         bagposition=1,bagid=1,
                                                                         id=EmbePos, embe_pos=EmbePos},
                                        AccStoneList2 = lists:reverse([StoneGoods2|lists:reverse(AccStoneList)]),
                                        AccGoods#p_goods{stone_num = AccGoods#p_goods.stone_num + 1,
                                                         stones = AccStoneList2};
                                    _ ->
                                        AccGoods
                                end
                        end,Goods4#p_goods{stones = [],stone_num=0},StonsList),
                  Goods6 = 
                      if Goods5#p_goods.stones =/= [] ->
                              mod_equip_change:equip_stone_property_add(Goods5);
                         true ->
                              Goods5
                      end,
                  %% 精炼系数处理
                  case common_misc:do_calculate_equip_refining_index(Goods6) of
                      {ok,Goods6T} ->
                          Goods6T;
                      {error,_RefiningIndexError} ->
                          Goods6
                  end
          end,EquipGoodsList),
    {ok,EquipGoodsList2}.

%% ItemType 道具类型
%% ItemId 道具类型id
%% ItemNumber 道具数量
%% IteamBind 洗炼 0 洗炼 1不洗炼
%% ItemColor 道具颜色，装备颜色不起作用
%% ItemQuality 品质 1...5
%% ItemSubQuality 子品质 1...6
%% ReinforceList 强化 强化 [16,..] 强化配置，十位数表时级别，个位数表进星级 不可以断级配置
%% PunchNum 开了数 孔数 1,2,3,4,5,6
%% AddAttr 附加属性 结构为 [{code,level},...]   此装备玩家重新洗炼时就会部分属性消失
%% code 为洗炼属性的编码，
%% 1、主属性,2、力量,3、敏捷,4、智力,5、精神,6、体质,7、最大生命值,8、最大灵气值,9、生命恢复速度,10、灵气恢复速度,11、攻击速度,12、移动速度,
%% 返回 {error,Reason} or {ok,GoodsList} GoodsList结构为 [p_goods,...]
get_p_goods_by_param({ItemType,ItemId,ItemNumber,ItemBind,ItemColor,ItemQuality,ItemSubQuality,ReinforceList,PunchNum,AddAttr}) ->
    Bind = if ItemBind =:= 0 ->
                   true;
              true ->
                   true
           end,
    
    CreateInfo =
        if ItemType =:= ?TYPE_EQUIP ->
                Color = 0,
                [EquipBaseInfo] = common_config_dyn:find_equip(ItemId),
                case EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT of
                    true ->
                        Quality = 0,SubQuality = 0;
                    _ ->
                        Quality = ItemQuality,
                        SubQuality = ItemSubQuality
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
                #r_equip_create_info{num=ItemNumber,typeid = ItemId,bind=Bind,color=Color,quality=Quality,sub_quality = SubQuality,
                                     punch_num=PunchNum,rate=ReinforceRate,result=ReinforceResult,result_list=ReinforceList};
           ItemType =:= ?TYPE_STONE ->
                #r_stone_create_info{num=ItemNumber,typeid = ItemId,bind=Bind};
           true ->
                #r_item_create_info{num = ItemNumber,typeid = ItemId,bind=Bind,color=ItemColor}
        end,
    ?DEBUG("~ts,CreateInfo=~w",["创建奖励道具",CreateInfo]),
    if ItemType =:= ?TYPE_EQUIP ->
            ?DEBUG("~w",[common_bag2:creat_equip_without_expand(CreateInfo)]),
            case common_bag2:creat_equip_without_expand(CreateInfo) of
                {ok,EquipGoodsList} ->
                    [EquipBaseInfo2] = common_config_dyn:find_equip(ItemId),
                    case EquipBaseInfo2#p_equip_base_info.slot_num =:= ?PUT_MOUNT
                        orelse EquipBaseInfo2#p_equip_base_info.slot_num =:= ?PUT_FASHION of
                        true ->
                            {ok,EquipGoodsList};
                        _ ->
                            get_p_goods_by_param2(ItemId,AddAttr,EquipGoodsList)
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
%% AddAttrList 结构为装备洗炼属性的[{code,level},...]
get_p_goods_by_param2(ItemId,AddAttrList,EquipGoodsList) ->
    [EquipBaseInfo] = common_config_dyn:find_equip(ItemId),
    EquipGoodsList2 = 
        lists:map(
          fun(Goods) ->
                  %% 颜色品质处理
                  Goods2 = mod_refining:equip_colour_quality_add(new,Goods,1,1,1),
                  %% 强化处理
                  Goods3 = mod_equip_change:equip_reinforce_property_add(Goods2,EquipBaseInfo),
                  %% 洗炼属性
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
