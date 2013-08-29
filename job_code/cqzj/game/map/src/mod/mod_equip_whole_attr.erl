%% Author: caochuncheng
%% Created: 2011-11-12
%% Description: 装备套装备属性处理
-module(mod_equip_whole_attr).

-include("mgeem.hrl").
-include("refining.hrl").

-export([do_handle_equip_whole_attr/1,
         set_whole_attr_not_active/1,
     notify_equip_whole_attr_change/3,
     get_equip_whole_attr_total_number/1]).

%% 集齐某个套装的装备个数 
get_equip_whole_attr_total_number(EquipWholeAttrID) ->
  case common_config_dyn:find(equip_whole_attr,{equip_whole_base_info,EquipWholeAttrID}) of
    [EquipWholeInfo] when erlang:is_record(EquipWholeInfo,r_equip_whole_info) ->
      EquipWholeInfo#r_equip_whole_info.total_number;
    _ ->
      0
  end.

%% 通知套装装备属性改变
%% [GoodsId,WholeAttrNumber,AttrCode,Active,Number,AttrCode,Active,Number,..]
notify_equip_whole_attr_change(Arg,RoleID,Equips) when erlang:is_list(Equips) ->
  NewIntValueList = 
    lists:foldl(
      fun(EquipGoods,AccEquipWholeAttrList) -> 
          WholeAttr = EquipGoods#p_goods.whole_attr,
          case erlang:is_list(WholeAttr) =:= true andalso WholeAttr =/= [] of
            true ->
              EquipWholeAttrArr = 
                lists:foldl(
                fun(PEquipWholeAttr,SubAccEquipWholeAttrList) ->
                    [PEquipWholeAttr#p_equip_whole_attr.attr_code,
                     PEquipWholeAttr#p_equip_whole_attr.active,
                     PEquipWholeAttr#p_equip_whole_attr.number|SubAccEquipWholeAttrList]
                end,[],WholeAttr),
              lists:append([AccEquipWholeAttrList,
                    [EquipGoods#p_goods.id,
                     erlang:length(WholeAttr) * 3|EquipWholeAttrArr]]);
            _ ->
              AccEquipWholeAttrList
          end
      end,[],Equips),
  case Arg of
    {role,_} ->
      ChangeAttList = [#p_role_attr_change{change_type=?ROLE_EQUIP_WHOLE_ATTR_CHANGE,
                         new_int_value_list=NewIntValueList}],
      common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList)
  end;
      
notify_equip_whole_attr_change(_,_RoleID,_Equips) ->
  [].

%% 设置装备套装属性不生效
%% 返回 #p_goods
set_whole_attr_not_active(#p_goods{type = ?TYPE_EQUIP,current_colour = Color}=EquipGoods) ->
    case common_config_dyn:find(equip_whole_attr, {equip_id,EquipGoods#p_goods.typeid,Color}) of
        [] ->
            EquipGoods;
        _ ->
            case erlang:is_list(EquipGoods#p_goods.whole_attr) andalso EquipGoods#p_goods.whole_attr =/= [] of
                true ->
                    WholeAttrList = [PEquipWholeAttr#p_equip_whole_attr{active = ?EQUIP_WHOLE_ATTR_STATUS_NOT_ACTIVE,
                                                                        number = 0}||PEquipWholeAttr <- EquipGoods#p_goods.whole_attr],
                    EquipGoods#p_goods{whole_attr = WholeAttrList};
                _ ->
                    EquipGoods#p_goods{whole_attr = []}
            end
    end;
set_whole_attr_not_active(EquipGoods) ->
    EquipGoods.
    

%% 玩家身上装备套装属性计算
%% 返回  {ok,EquipGoodsList,EquipWholeAttrBuffIdList}
do_handle_equip_whole_attr(EquipGoodsList) ->
    %% 查找出玩家身上装备的所有套装 [{WholeId,[EquipGoodsList]},...]
    AllWholeEquipGoodsList = 
        lists:foldl(
          fun(WholeEquipGoodsA,AccAllWholeEquipGoodsList) -> 
                  case erlang:is_list(WholeEquipGoodsA#p_goods.whole_attr) =:= true andalso
                           WholeEquipGoodsA#p_goods.whole_attr =/= [] of
                      true ->
                          [#p_equip_whole_attr{id=PWholeId}=_HEquipWholeAttr|_TEquipWholeAttr] = WholeEquipGoodsA#p_goods.whole_attr,
                          case lists:keyfind(PWholeId,1,AccAllWholeEquipGoodsList) of
                              false ->
                                  [{PWholeId,[WholeEquipGoodsA]}|AccAllWholeEquipGoodsList];
                              {PWholeId,SubAccAllWholeEquipGoodsList} ->
                                  [{PWholeId,[WholeEquipGoodsA|SubAccAllWholeEquipGoodsList]}|
                                       lists:keydelete(PWholeId, 1, AccAllWholeEquipGoodsList)]
                          end;
                      _ ->
                          AccAllWholeEquipGoodsList
                  end
          end, [], EquipGoodsList),
    %% 处理套装是否生效
    {WholeEquipGoodsList,WholeAttrBuffIdList} =
        lists:foldl(
          fun({WholeIdB,AllWholeEquipGoodsListB},{AccWholeEquipGoodsList,AccWholeAttrBuffIdList}) -> 
                  case get_equip_whole_attr_buff_id_list(WholeIdB,AllWholeEquipGoodsListB) of
                      {ok,NewWholeEquipGoodsList,NewAddWholeAttrBuffIdList} ->
                          {lists:append([NewWholeEquipGoodsList,AccWholeEquipGoodsList]),
                           lists:append([AccWholeAttrBuffIdList,NewAddWholeAttrBuffIdList])};
                      EquipWholeAttrError ->
                          ?ERROR_MSG("~ts,WholeId=~w,EquipWholeAttrError=~w",["装备套装备属性出错",WholeIdB,EquipWholeAttrError]),
                          {AccWholeEquipGoodsList,AccWholeAttrBuffIdList}
                  end
          end, {[],[]}, AllWholeEquipGoodsList),
    NewEquipGoodsList = 
        lists:foldl(
          fun(WholeEquipGoodsC,AccNewEquipGoodsList) ->
                  [WholeEquipGoodsC|lists:keydelete(WholeEquipGoodsC#p_goods.id,#p_goods.id,AccNewEquipGoodsList)]
          end,EquipGoodsList,WholeEquipGoodsList),
   {ok,NewEquipGoodsList,WholeAttrBuffIdList}.
%% 返回套装处理过的新的信息
%% {ok,NewWholeEquipGoodsList,NewAddWholeAttrBuffIdList} or {error,Reason}
get_equip_whole_attr_buff_id_list(WholeId,WholeEquipGoodsList) ->
    case common_config_dyn:find(equip_whole_attr,{equip_whole_base_info,WholeId}) of
        [EquipWholeInfo] when erlang:is_record(EquipWholeInfo,r_equip_whole_info) ->
            get_equip_whole_attr_buff_id_list2(WholeId,WholeEquipGoodsList,EquipWholeInfo);
        _ ->
            {error,nod_found_by_whole_id}
    end.
get_equip_whole_attr_buff_id_list2(_WholeId,WholeEquipGoodsList,EquipWholeInfo) ->
    #r_equip_whole_info{add_attr_list = AddAttrList} = EquipWholeInfo,
    CurWholeEquipNumber = erlang:length(WholeEquipGoodsList),
    ValidWholeEquipNumber = erlang:length([EquipGoodsA#p_goods.id || EquipGoodsA <- WholeEquipGoodsList]),
    {WholeEquipGoodsList2,AllAttrIndexList} = 
        lists:foldl(
          fun(EquipGoodsB,{AccWholeEquipGoodsList2,AccAllAttrIndexList}) -> 
                  {WholeAttrList,AccAllAttrCodeList2} = 
                      lists:foldl(
                        fun(PEquipWholeAttr,{AccWholeAttrList,AccAttrIndexList}) -> 
                                case ValidWholeEquipNumber >= PEquipWholeAttr#p_equip_whole_attr.active_number of
                                    true ->
                                        WholeAttrActive = ?EQUIP_WHOLE_ATTR_STATUS_ACTIVE,
                                        case lists:member(PEquipWholeAttr#p_equip_whole_attr.attr_index,AccAttrIndexList) of
                                            true ->
                                                AccAttrIndexList2 = AccAttrIndexList;
                                            _ ->
                                                AccAttrIndexList2 = [PEquipWholeAttr#p_equip_whole_attr.attr_index|AccAttrIndexList]
                                        end;
                                    _ ->
                                        WholeAttrActive = ?EQUIP_WHOLE_ATTR_STATUS_NOT_ACTIVE,
                                        AccAttrIndexList2 = AccAttrIndexList
                                end,
                                {[PEquipWholeAttr#p_equip_whole_attr{active = WholeAttrActive,number = CurWholeEquipNumber} | AccWholeAttrList],
                                 AccAttrIndexList2}
                        end,{[],AccAllAttrIndexList},EquipGoodsB#p_goods.whole_attr),
                  {[EquipGoodsB#p_goods{whole_attr = WholeAttrList}|AccWholeEquipGoodsList2],AccAllAttrCodeList2}
          end,{[],[]},WholeEquipGoodsList),
    WholeAttrBuffIdList =
        lists:foldl(
          fun(AddAttrIndex,AccWholeAttrBuffIdList) -> 
                  case lists:keyfind(AddAttrIndex,#r_equip_whole_attr.attr_index,AddAttrList) of
                      #r_equip_whole_attr{buff_id = BuffId} ->
                          [BuffId | AccWholeAttrBuffIdList];
                      _ ->
                          AccWholeAttrBuffIdList
                  end
          end,[],AllAttrIndexList),
    {ok,WholeEquipGoodsList2,WholeAttrBuffIdList}.
