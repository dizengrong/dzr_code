%% 装备铁匠铺配置文件
-define(EQUIP_BUILD_MODULES,[mod_equip_build,mod_equip_change]).


%% 默认装备打造处理进程数
-define(DEFAULT_EQUIP_BUILD_PROCESS_COUNT,2).

%% 默认的可使用的背包id
-define(DEFAULT_EQUIP_BUILD_BAG_ID,[1,2,3,4]).
%% 默认可存放新装备的背包
-define(DEFAULT_EQUIP_BUILD_KEEP_BAG_ID,[1,2,3,4]).

%% 默认装备材质列表
%% 装备材质 0，所有，1:金,2:木,3:皮,4:布,5:玉,
-define(DEFAULT_EQUIP_BUILD_MATERIAL_DICT,[1,2,3,4,5]).

%% 道具类型，1：基础材料，2：附加材料，3：品质材料
-define(EQUIP_BUILD_BASE,1).
-define(EQUIP_BUILD_ADD,2).
-define(EQUIP_BUILD_PINZHI,3).


%% 打造记录 id,最小级别，最大级别，基础材料级别，基础材料数量,打造费用,单位:文,打造装备id列表
-record(r_equip_build,{id,min_level,max_level,base_goods_level,base_goods_num,fee,equip_list = []}).

%% 装备打造道具记录 材质， 道具ID，道具类型，1：基础材料，2：附加材料，道具级别
-record(r_equip_build_item,{material,item_id,type,level}).

%% 装备打造颜色产生概率配置记录，附加材料级别，白色，绿色，蓝色，紧色，橙色，金色
-record(r_equip_build_equip_color,{add_goods_level,white,green,blue,purple,orange,gold}).

%% 装备打造颜色产生的品质概率配置记录，颜色，品质概率
-record(r_equip_build_equip_quality,{equip_color,weight = []}).

%% 装备打造概率打孔数记录 附加材料级别
-record(r_equip_build_equip_punch_num,{add_goods_level,num_0,num_1,num_2,num_3,num_4,num_5,num_6}).


%% 装备改造，其中装备品质改造，装备升级，装备分解配置信息
-define(ETS_EQUIP_CHANGE,ets_equip_change).
%% 默认装备改造处理进程数
-define(DEFAULT_EQUIP_CHANGE_PROCESS_COUNT,2).

%%  装备分解颜色最低限制
-define(DEFAULT_EQUIP_DECOMPOSE_COLOR_MIN_LEVEL,3).
%% 装备分解获取基础材料概率权值
-define(DEFAULT_EQUIP_DECOMPOSE_BASE_SEED,100).
%% 装备分解材料放置背包配置
-define(DEFAULT_EQUIP_DECOMPOSE_BAG,[1,2,3,4]).

%% 装备强化材料配置记录 材料类型id，材料级别
-record(r_equip_reinforce_material,{type_id,item_level}).

%% 装备品质改造产生的品质概率配置记录，附加材料级别，需要的附加材料数量,品质概率
-record(r_equip_build_change_quality,{item_level,item_num,weight = []}).

%% 装备升级基础材料记录 装备最小级别，装备最大级别，基础材料级别，需要的数量
-record(r_equip_upgrade_base_material,{min_level,max_level,item_level,number}).
%% 装备升级保留品质材料记录,品质值，附加材料级别，附加材料数量
-record(r_equip_upgrade_quality_material,{quality,item_level,number}).
%% 装备升级保留强化材料记录，强化等级，强化材料级别，强化材料数量
-record(r_equip_upgrade_reinforce_material,{reinforce,item_level,number}).
%% 装备升级五行属性材料记录，装备五行级别，附加材料级别，附加材料数量
-record(r_equip_upgrade_fiveele_material,{five_ele_level,item_level,number}).

%% 装备升级绑定属性材料记录，绑定级别（最高级），附加材料级别，附加材料数量
-record(r_equip_upgrade_bind_material,{bind_level,item_level,number}).

%% 装备分解获取基础材料概记录，装备最小级别，装备最大级别，基础材料级别，获取概率，获取数量
-record(r_equip_decompose_base_material,{min_level,max_level,item_level,probability,number}).

%% 装备分解获取附加材料概率记录，最小精炼系数，最大精炼系数，附加材料item_0 到 item_6,获取概率，获取数量
-record(r_equip_decompose_add_material,{min_index,max_index,item_0,item_1,item_2,item_3,item_4,item_5,item_6,number}).


%% 装备五行珠材料记录
-record(r_equip_fiveele_material,{type_id,number}).

%% 装备五行附加属性概念,属性级别，概率
-record(r_equip_fiveele_attr_level,{level_1,level_2,level_3,level_4,level_5,level_6}).

%% 装备五行级别提升概率
-record(r_equip_fiveele_upgrade_material,{item_level,item_num,level_1,level_2,level_3,level_4,level_5,level_6}).

%% 装备五行激活属性记录
%% code 1 物理伤抗万分比,2魔法伤抗万分比,3增加伤害万分比,4破甲万分比,5伤害反射万分比
-record(r_equip_fiveele_attr,{code,level,value}).

