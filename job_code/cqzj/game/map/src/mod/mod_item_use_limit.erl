%%% @author fsk 
%%% @doc
%%%     特殊道具每天使用次数控制
%%% @end
%%% Created : 2012-8-16
%%%-------------------------------------------------------------------
-module(mod_item_use_limit).

-include("mgeem.hrl").

-export([
			assert_item_use_limit/4
		]).

-define(CONFIG_NAME,item_use_limit).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

%% 使用特殊道具次数满错误码
-define(ERR_USE_ITEM_FULL_TIMES_LIMIT,1002).

assert_item_use_limit(RoleID,RoleLevel,UseNum,TypeID) when is_integer(TypeID) ->
	[ItemBaseInfo] = common_config_dyn:find_item(TypeID),
	assert_item_use_limit(RoleID,RoleLevel,UseNum,ItemBaseInfo);
assert_item_use_limit(RoleID,RoleLevel,UseNum,ItemBaseInfo) ->
	#p_item_base_info{typeid=TypeID,itemname=ItemName,colour=Colour} = ItemBaseInfo,
	[ItemUseLimitConf] = ?find_config(item_use_limit),
	case common_tool:find_lists_section(TypeID,ItemUseLimitConf) of
		undefined -> ok;
		{_,VipConf} ->
			VipLevel = mod_vip:get_role_vip_level(RoleID),
			case common_tool:find_tuple_section(VipLevel,VipConf) of
				undefined ->
					?THROW_ERR(?ERR_USE_ITEM_FULL_TIMES_LIMIT,<<"VIP等级配置错误">>);
				{_,LevelConf} ->
					case common_tool:find_tuple_section(RoleLevel,LevelConf) of
						undefined ->
							?THROW_ERR(?ERR_USE_ITEM_FULL_TIMES_LIMIT,<<"角色等级配置错误">>);
						{_,MaxUseCount} ->
							{ok, #r_item_use_limit{use_log=UseLogList}=ItemUseLimitInfo} = get_item_use_limit_info(RoleID),
							NewTodayUseNum = 
								case lists:keyfind(TypeID,#r_item_use_limit_log.typeid,UseLogList) of
									false -> UseNum;
									#r_item_use_limit_log{today_use_num=TodayUseNum,last_use_time=LastUseTime} ->
										case common_time:is_today(LastUseTime) of
											true -> TodayUseNum + UseNum;
											false -> UseNum
										end
								end,
							case NewTodayUseNum > MaxUseCount of
								true ->
									GoodsName = common_misc:format_goods_name_colour(Colour,ItemName),
									?THROW_ERR(?ERR_USE_ITEM_FULL_TIMES_LIMIT,lists:concat([GoodsName,"达到当前VIP等级今日使用次数上限(<font color=\"#12CC95\">",MaxUseCount,"</font>次)，你可以升级VIP等级增加使用次数！"]));
								false ->
									Now = mgeem_map:get_now(),
									NewUseLogList = [#r_item_use_limit_log{typeid=TypeID,today_use_num=NewTodayUseNum,last_use_time=Now}
																			  |lists:keydelete(TypeID,#r_item_use_limit_log.typeid,UseLogList)],
									t_set_item_use_limit_info(RoleID,ItemUseLimitInfo#r_item_use_limit{use_log=NewUseLogList}),
									ok
							end
					end
			end
	end.
t_set_item_use_limit_info(RoleID, ItemUseLimitInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewRoleExtInfo = RoleExtInfo#r_role_map_ext{item_use_limit=ItemUseLimitInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
			ok;
		Reason ->
			?ERROR_MSG("t_set_item_use_limit_info error,RoleID=~w,ItemUseLimitInfo=~w,Reason=~w",[RoleID,ItemUseLimitInfo,Reason]),
			?THROW_SYS_ERR()
	end.
get_item_use_limit_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{item_use_limit=ItemUseLimitInfo}} ->
			{ok, ItemUseLimitInfo};
		Reason ->
			?ERROR_MSG("get_item_use_limit_info error,RoleID=~w,Reason=~w",[RoleID,Reason]),
			?THROW_SYS_ERR()
	end.
