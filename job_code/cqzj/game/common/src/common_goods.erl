%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%
%%% @end
%%% Created : 24 Dec 2010 by  <>
%%%-------------------------------------------------------------------
-module(common_goods).

-include("common.hrl").

%% API
-export([get_notify_goods_name/1]).

%%%===================================================================
%%% API
%%%===================================================================

get_notify_goods_name(Goods) ->
    #p_goods{type=GoodsType, typeid=TypeID, current_colour = Color} = Goods,
    GoodsName = 
        if GoodsType =:= ?TYPE_EQUIP ->
                [#p_equip_base_info{kind=Kind, equipname=Name}] = common_config_dyn:find_equip(TypeID),
                [SpecEquipKind] = common_config_dyn:find(etc, spec_equip_name_kind),
                IsSpecEquip = lists:member(Kind, SpecEquipKind),
                if 
                    IsSpecEquip ->
                        common_tool:to_list(Name);
                    Color =:= ?COLOUR_WHITE ->
                        lists:append([common_tool:to_list(?_LANG_EQUIP_CONST_QUALITY_GENERAL),
                                      common_tool:to_list(Name)]);
                    Color =:= ?COLOUR_GREEN ->
                        lists:append([common_tool:to_list(?_LANG_EQUIP_CONST_QUALITY_WELL),
                                      common_tool:to_list(Name)]);
                    Color =:= ?COLOUR_BLUE ->
                        lists:append([common_tool:to_list(?_LANG_EQUIP_CONST_QUALITY_GOOD),
                                      common_tool:to_list(Name)]);
                    Color =:= ?COLOUR_PURPLE ->
                        lists:append([common_tool:to_list(?_LANG_EQUIP_CONST_QUALITY_FLAWLESS),
                                      common_tool:to_list(Name)]);
                    Color =:= ?COLOUR_ORANGE ->
                        lists:append([common_tool:to_list(?_LANG_EQUIP_CONST_QUALITY_PERFECT),
                                      common_tool:to_list(Name)]);
                    Color =:= ?COLOUR_GOLD ->
                        lists:append([common_tool:to_list(?_LANG_EQUIP_CONST_QUALITY_GOLD),
                                      common_tool:to_list(Name)]);
                    true ->
                        lists:append([common_tool:to_list(?_LANG_EQUIP_CONST_QUALITY_GENERAL),
                                      common_tool:to_list(Name)])
                end;
           GoodsType =:= ?TYPE_STONE ->
                [#p_stone_base_info{stonename=Name}] = common_config_dyn:find_stone(TypeID),
                common_tool:to_list(Name);
           true ->
                [#p_item_base_info{itemname=Name}] = common_config_dyn:find_item(TypeID),
                common_tool:to_list(Name)
        end,
    GoodsName2 = 
        if Goods#p_goods.current_num > 1 ->
                lists:append(["【",GoodsName,"】×",erlang:integer_to_list(Goods#p_goods.current_num)]);
           true ->
                lists:append(["【",GoodsName,"】"])
        end,
    if Color =:= ?COLOUR_WHITE ->
            lists:append(["<font color=\"#FFFFFF\">",GoodsName2,"</font>"]);
       Color =:= ?COLOUR_GREEN->
            lists:append(["<font color=\"#12CC95\">",GoodsName2,"</font>"]);
       Color =:= ?COLOUR_BLUE->
            lists:append(["<font color=\"#0D79FF\">",GoodsName2,"</font>"]);
       Color =:= ?COLOUR_PURPLE->
            lists:append(["<font color=\"#FE00E9\">",GoodsName2,"</font>"]);
       Color =:= ?COLOUR_ORANGE->
            lists:append(["<font color=\"#FF7E00\">",GoodsName2,"</font>"]);
       Color =:= ?COLOUR_GOLD->
            lists:append(["<font color=\"#FFD700\">",GoodsName2,"</font>"]);
       true ->
            lists:append(["<font color=\"#FFFFFF\">",GoodsName2,"</font>"])
    end.

%%%===================================================================
%%% Internal functions
%%%===================================================================
