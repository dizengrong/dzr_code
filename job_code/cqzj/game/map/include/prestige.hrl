
%% 声望兑换配置记录定义
%% base_key 配置key {group_id,class_id}
%% group_id 组ID
%% class_id 子类ID
%% item_list 兑换的道具列表

%% key 唯一标识
%% item_type 道具类型 
%% item_id 道具类型id
%% number 道具数量
%% bind 绑定 0 绑定 1不绑定
%% color 道具颜色，装备颜色不在此项配置
%% quality 品质 1...5
%% sub_quality 子品质 1...6
%% reinforce 强化 [16,..] 强化配置，十位数表时级别，个位数表进星级 不可以断级配置
%% punch_num 孔数 1,2,3,4,5,6
%% add_attr 结构为 [{code,level},...]   此装备玩家重新绑定时就会部分属性消失
%% code 为绑定属性的编码，
%% 1、主属性,2、力量,3、敏捷,4、智力,5、精神,6、体质,7、最大生命值,8、最大灵气值,9、生命恢复速度,10、灵气恢复速度,11、攻击速度,12、移动速度,
%% min_level 最小级别
%% max_level 最大级别
%% need_prestige 需要的声望
%% is_broadcast 是否广播 0不广播 1广播
-record(r_prestige_exchange_base,{base_key,group_id,class_id,item_list = []}).
-record(r_prestige_exchange_base_item,{key,item_type,item_id,item_number,bind = 0,color = 0,quality = 0,sub_quality = 0,
                                       reinforce = [],punch_num = 0,add_attr = [],min_level =0,max_level=0,need_prestige = 0,is_broadcast = 0}).


