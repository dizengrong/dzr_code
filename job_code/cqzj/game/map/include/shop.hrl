%% 免费商店
-define(FREE_SHOP,999999999).
%% 限量商店
-define(BAG_SHOP_NPC_ID,888888).
%% 快速购买商店
-define(QUICK_BUY_SHOP_ID,70023).
%% 每天限量抢购的刷新时间
-define(BAG_SHOP_REFRESH_TIME,{12,0,0}).

-define(BIND_GOLD, 4).
-define(BIND_SILVER, 3).
-define(GOLD, 2).
-define(SILVER, 1).
-define(UNAVAI, 0).
%% 买回物品列表物品数量
-define(BUY_BACK_NUM,6).
%% 客户端请求类型
-define(GET_LIST,1). %%获取买回物品列表
-define(BUY_BACK,2). %%玩家买回物品

%%神密商店
-record(r_egg_shop_goods, {type,typeid,bind,start_time,end_time,num,org_price,cur_price,rate,discount=0,is_max_discount=false,money_bind}).

-define(ALL_SHOP_IDS,[70005,70006,70007,70022,70023,80112,80113,80114,80115,80119,80120,80121]).

