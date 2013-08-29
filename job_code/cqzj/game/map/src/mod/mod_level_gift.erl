%% Author: MarkyCai
%% Created: 2011-2-18
%% Description: 等级礼包
-module(mod_level_gift).
%%
%% Include files
%%
-include("mgeem.hrl").
-define(IS_CLOSED,isclosed).
-define(IS_OPENED,isopened).
%%
%% Exported Functions
%%
-export([init/2, delete/1]).

-export([send_role_level_gift/1,handle/1]).

%%
%% ==============API Functions====================
%%
init(_RoleID, LevelGift) when is_record(LevelGift, r_role_level_gift) ->
	put(r_role_level_gift, LevelGift);
init(_RoleID, _LevelGift) ->
	put(r_role_level_gift, #r_role_level_gift{
		gifts   = [-1, ?IS_OPENED]
	}).

delete(_RoleID) ->
	erase(r_role_level_gift).


%% 发送等级礼包 
send_role_level_gift(RoleID) ->
	case get_next_level_gift(RoleID) of
		{ok, [],_Reason} ->
			ignore;
		{ok,[Gift],_Reason} ->
			Data = #m_level_gift_list_toc{gift=Gift},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE,?LEVEL_GIFT,?LEVEL_GIFT_LIST,Data)
	end.

%% 处理客户端领取礼包请求
handle({Unique,?LEVEL_GIFT,?LEVEL_GIFT_ACCEPT,DataIn,RoleID, _PID,_Line,_State}) ->
    #m_level_gift_accept_tos{id=GiftLevel} = DataIn,
    case get_next_level_gift(RoleID) of
        {ok, [],Reason} ->
            Data = #m_level_gift_accept_toc{succ=false,reason=Reason},
            common_misc:unicast({role, RoleID}, Unique,?LEVEL_GIFT,?LEVEL_GIFT_ACCEPT,Data);
        {ok,[#p_level_gift_info{id=NextGiftLevel,goods_list=GoodsList,next_level=IfOpen}],_Reason} ->	
            RoleLevel =case mod_map_role:get_role_attr(RoleID) of
                           {ok,RoleAttr} ->
                               RoleAttr#p_role_attr.level;
                           _->0
                       end,
            case (RoleLevel < GiftLevel) orelse (NextGiftLevel=/=GiftLevel) of
                true->
                    Data = #m_level_gift_accept_toc{succ=false,reason=?_LANG_LEVEL_GIFT_ERROR_LEVEL},
                    common_misc:unicast({role, RoleID}, Unique,?LEVEL_GIFT,?LEVEL_GIFT_ACCEPT,Data);
                false->
                    case common_transaction:transaction(
                           fun()->
                                   mod_bag:create_goods_by_p_goods(RoleID,GoodsList)
                           end) 
                        of
                        {aborted,{bag_error,{not_enough_pos,_BagID}}} ->
                            Data = #m_level_gift_accept_toc{succ=false,reason=?_LANG_LEVEL_GIFT_ENOUGH_POS},
                            common_misc:unicast({role, RoleID}, Unique,?LEVEL_GIFT,?LEVEL_GIFT_ACCEPT,Data);
                        {aborted, _Reason} ->
                            Data = #m_level_gift_accept_toc{succ=false,reason=?_LANG_LEVEL_GIFT_SYSTEM_ERROR},
                            common_misc:unicast({role, RoleID}, Unique,?LEVEL_GIFT,?LEVEL_GIFT_ACCEPT,Data);
                        
                        {atomic,{ok,NewGoodsList}} ->
                            gift_goods_log(GoodsList),
                            NewState=case IfOpen of 
                                         1 -> ?IS_OPENED;
                                         0 -> ?IS_CLOSED 
                                     end,
                            NewGifts=[NextGiftLevel,NewState],
                            put(r_role_level_gift, #r_role_level_gift{gifts=NewGifts}),
                            Data = #m_level_gift_accept_toc{succ=true,goods_list=NewGoodsList},
                            common_misc:unicast({role, RoleID},Unique,?LEVEL_GIFT,?LEVEL_GIFT_ACCEPT,Data),
                            %% 通知客户端下一个等级礼包信息，注意一定要在accept返回之后
                            send_role_level_gift(RoleID)
                    end
            
            end
    end;

handle({Unique,?LEVEL_GIFT,?TIME_GIFT_ACCEPT,DataIn,RoleID, PID,Line,State}) ->
    mod_time_gift:handle({Unique,?LEVEL_GIFT,?TIME_GIFT_ACCEPT,DataIn,RoleID, PID,Line,State}).

%%
%% =============Local Functions======================
%%
get_next_level_gift(RoleID)->
	case get(r_role_level_gift) of
		#r_role_level_gift{gifts=[LastGiftLevel,State]}->
			next;
		_->
			LastGiftLevel = -1,
			State=?IS_OPENED
	end,
	case State of 
		?IS_CLOSED->
			{ok,[],?_LANG_LEVEL_GIFT_HAS_ACCEPT};
		?IS_OPENED->
			case level_gift_conf(RoleID,LastGiftLevel) of
				{_TypeID1,NextGiftLevel1,_IfOpen1,_GiftName1} ->
					case level_gift_conf(RoleID,NextGiftLevel1) of
						{TypeID2,_NextGiftLevel2,IfOpen2,GiftName2}->
							case  common_config_dyn:find(gift,TypeID2) of
								[#r_gift{gift_list=GiftBaseList}] ->
									GoodsList = make_gift_goods_list(RoleID,GiftBaseList),
									%% 重构之后，nextlevel放bool值，判断是否还有礼包
									%% true:还有礼包为领取
									%% false：当前礼包是否是最后一个
									{ok,[#p_level_gift_info{id=NextGiftLevel1,gift_name=GiftName2,goods_list=GoodsList,next_level=IfOpen2}],<<>>};
								_ ->
									{ok,[],?_LANG_LEVEL_GIFT_NOT_GIFT}
							end;
						_->
							{ok,[],?_LANG_LEVEL_GIFT_NOT_GIFT}
					end;
				_->
					{ok,[],?_LANG_LEVEL_GIFT_NOT_GIFT}
			end
	end.

level_gift_conf(_RoleID,GiftLevel) ->
	case common_config_dyn:find(level_gift,GiftLevel) of
		[] ->
			erase(r_role_level_gift),
			ok;
		[Conf] ->
			Conf
	end.

%% 创建要发送到前端的礼包数据		
make_gift_goods_list(RoleID,GiftBaseList) ->
    GoodsList = 
        lists:foldl(
          fun(GiftBase,Acc) ->
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
                  CI = #r_goods_create_info{bind=GiftBase#p_gift_goods.bind, 
                                            type=GiftBase#p_gift_goods.type, 
                                            start_time=GiftBase#p_gift_goods.start_time,
                                            end_time=GiftBase#p_gift_goods.end_time,
                                            type_id=GiftBase#p_gift_goods.typeid,
                                            num=GiftBase#p_gift_goods.num,
                                            quality = Quality,sub_quality = SubQuality,
                                            color=Color},
                  {ok,TempGoodsList} = mod_bag:create_p_goods(RoleID, CI),
                  lists:append(TempGoodsList,Acc)
          end,[],GiftBaseList),
    lists:map(fun(Goods) -> Goods#p_goods{id=1,bagposition=0,bagid=0} end,GoodsList).

%% 记录领取礼包的日志
gift_goods_log(GoodsList) ->
    lists:foreach(
      fun(Goods) ->
              #p_goods{roleid=RoleID}=Goods,
              common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_LI_BAO_HUO_DE)
      end,GoodsList).



