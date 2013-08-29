
-record (xunxian, {
	gd_AccountID     = 0,		%% 主键：玩家id
	gd_LastTime 	 = 0,		%% 上次炼金时间
	gd_FreeTimes 	 = 0,		%% 剩余免费次数
	gd_ImmortalPos   = 0,		%% 仙人位置
	gd_ItemList 	 = 0		%% 物品列表
	}).

-record (xunxian_types, {
	gd_AccountID     = {integer},
	gd_LastTime 	 = {integer},
	gd_FreeTimes 	 = {integer},
	gd_ImmortalPos   = {integer},
	gd_ItemList 	 = {term}
	}).

-define(MAX_FREE_XUNXIAN_TIMES,10).

-define(MAX_ITEM_POS,20).