%% 商贸活动活文件

%% 商贸活动商品进程字典前缀
%% 玩家商贸活动购买的商品存储的格式
%% 存放的格式为 {{role_trading,RoleId} r_role_trading}
-define(ROLE_TRADING_DICT_PREFIX,role_trading).
%% 商贸活动商店进程字典前缀
%% 商贸活动NPC商店存储格式,{Key,Value}
%% Key = {trading_shop,map_id,npc_id}
%% Value = r_trading_shop_goods
-define(TRADING_SHOP_DICT_PREFIX,trading_shop).
%% 商贸商店物品信息记录
%% faction_id 国家id
%% map_id 地图id npc_id 商贸商店npc id goods 商贸商店物品信息 p_trading_goods
%% current_price_index 当前价格索引
%% current_seconds 此次商店信息更新时间，秒
-record(r_trading_shop_goods,{faction_id,map_id,npc_id,goods,current_price_index,current_seconds}).

%% 商贸商店物品价格下次更新时间，进程字典格式
%% erlang:put({trading_price_seconds,MapId},seconds)
-define(TRADING_PRICE_SECONDS_DICT_PREFIX,trading_price_seconds).
%% 商贸商店物品数量下次更新时间，进程字典格式
%% erlang:put({trading_number_seconds,MapId},seconds)
-define(TRADING_NUMBER_SECONDS_DICT_PREFIX,trading_number_seconds).

%% 重新初始化商贸商店信息
%% erlang:put({trading_reload_shop_goods,MapId},{ReloadSeconds,Status})
-define(TRADING_RELOAD_SHOP_GOODS_DICT_PREFIX,trading_reload_shop_goods).

%% 商贸商店信息记录
%% faction_id 国家id
%% map_id 地图id npc_id NPC ID goods_ids 商贸商品类型id列表
%% init_price_indexs 初始价格索引列表 best_price_index 最佳初始价格索引
%% buy_price_index 此商店买入的价格索引
%% sale_price_index 此商店卖出的价格索引
-record(r_trading_shop_info,{faction_id,map_id,npc_id,goods_ids,init_price_indexs,
                             best_price_index,buy_price_index,sale_price_index}).
%% 商贸商店概率记录，用来保存商店的商品体格变化
-record(r_trading_shop_price,{npc_id = 0,faction_id = 0, map_id = 0,price_indexs = [],best_index = 0,init_index = 0}).
%% 商贸活动配置文件
-define(TRADING_GOODS_CONFIG,trading_goods).
-define(TRADING_CONFIG,trading).

%% 玩家级别与获取的商贸商票配置文件
%% min_level 低小级别 max_level 最高级别 bill 商票价值 max_bill 商票价值上限 
%% item_id 商票材料id item_number商票数量 bind 绑定 1 绑定 2 不绑定
-record(r_role_trading_bill,{min_level,max_level,bill,max_bill,item_id,item_number,bind}).

%% 可获取或交还商贸商票功能的NPC配置
%% faction_id 国家id map_id 地图id npc_id NPC ID
-record(r_trading_bill_npc,{faction_id,map_id,npc_id}).

%% 可以使用增加商贸收益道具配置
%% week 星期 1..7 星期一到星期日 item_id 道具id add_value 增加万分比
-record(r_trading_income_item,{week,item_id,item_number,add_value}).

%% 商贸状态定义
-define(TRADING_STATUS_GET,1).%% 获得商票
-define(TRADING_STATUS_RETURN,2). %% 交还
-define(TRADING_STATUS_DESTROY,3). %% 管理员销毁
-define(TRADING_STATUS_PERSON_HANDLE,4). %% 玩家销毁
-define(TRADING_STATUS_PERSON_DEAD,5). %% 玩家死亡

%% 玩家奖励类型
-define(TRADING_AWARD_TYPE_INIT,0). %% 初始化

%% 地图商贸商店初始化数据标志
%% Status 状态 1 未初始化，2 已初始化
%% erlang:put({trading_shop_init_status,MapId},Status)
-define(TRADING_SHOP_INIT_STATUS_DICT_PREFIX,trading_shop_init_status).

-define(TRADING_SHOP_INIT_STATUS_FALSE,1).
-define(TRADING_SHOP_INIT_STATUS_TRUE,2).

%% 商贸广播消息处理（宗族商贸日广播）
%% Date erlang:date()
%% Status 状态 1 未处理，2 已处理
%% erlang:put({trading_broadcast_status,MapId},{Date,Status})
-define(TRADING_BROADCAST_STATUS_DICT_PREFIX,trading_broadcast_status).

%% 商贸广播消息处理（商贸结束广播）
%% NextBroadcastSeconds 下次广播时间 common_tool:now()
%% erlang:put({trading_end_broadcast_status,MapId},NextBroadcastSeconds)
-define(TRADING_END_BROADCAST_STATUS_DICT_PREFIX,trading_end_broadcast_status).

%% 完成商贸的铜钱的奖励倍数
-define(REWARD_SILVER_BIND_MUL, 10).
