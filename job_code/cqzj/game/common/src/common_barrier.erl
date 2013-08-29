%% Author: dizengrong
%% Created: 2012-11-12
%% @doc: 这里实现的是t6项目中通用的关卡处理
%% 主要目的是想为代码中的mod_examine_fb和mod_hero_fb模块来继承这个模块
%% 以便实现通用的处理

-module (common_barrier).

-include("common.hrl").

-export([send_reward/6, send_reward/5
	]).

%% 发送副本的通关奖励: 
%% send_reward(角色id, 经验, 声望, 银币, [{物品id, 数量, 物品类型, 是否绑定}])
send_reward(RoleId, Exp, Prestige, Silver, Items) ->
	send_reward(RoleId, Exp, Prestige, Silver, 0, Items).

send_reward(RoleId, Exp, Prestige, Silver, Yueli, Items) ->
	mod_map_role:do_add_exp(RoleId, Exp),
	common_bag2:add_prestige(RoleId, Prestige, ?GAIN_TYPE_PRESTIGE_FROM_FB),
	common_bag2:add_money(RoleId, silver_bind, Silver, ?GAIN_TYPE_SILVER_FB),
	case Yueli > 0 of
		true ->
			common_bag2:add_yueli(RoleId, Yueli, ?GAIN_TYPE_YUELI_FROM_FB);
		false -> ignore
	end,
	case mod_bag:add_items(RoleId, Items, ?LOG_ITEM_TYPE_FB_GAIN) of
		{true, _} -> ok;
		{error, _Reason} ->
			CreateInfoList = common_misc:get_items_create_info(RoleId, Items),
			GoodsList = common_misc:get_mail_items_create_info(RoleId, CreateInfoList),
			Text  = "亲爱的玩家，由于之前您的副本通关奖励的物品未能成功领取，"
					"所以系统以邮件的形式发给您了。",
			Title = "副本通关奖励",
			common_letter:sys2p(RoleId, Text, Title, GoodsList, 14)
	end.


