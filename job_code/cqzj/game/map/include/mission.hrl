-include("mgeem.hrl").

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

-record(mission_time_limit, {
    time_limit_start=0,%% 开始--时*3600+分*60
    time_limit_start_day=0,%% 开始--周几、月几
    time_limit_start_timestamp=0,%% 开始--具体某一天的时间戳
    time_limit_end=0,%% 结束--时*3600+分*60
    time_limit_end_day=0,%% 结束--周几、月几
    time_limit_end_timestamp=0 %% 结束--具体某一天的时间戳
}).

%%@doc 单个新手任务配置数据
-record(mission_tutorial, {
    match_key,%% tuple()
    mission_id=0,
    int_data=[]
}).

%%@doc 任务侦听器数据
-record(mission_listener_data, {
    type,
    value,
    int_list,
    need_num
}).

%%@doc 前置任务道具
-record(pre_mission_prop, {
    prop_id,
    prop_num
}).

%%@doc 任务侦听器用来触发的数据 即数据库中保留的 当事件发生时检查触发
-record(mission_listener_trigger_data, {
    key, %% tuple() {DataType, DataTypeValue}
    type,
    value,
    mission_id_list
}).

%%@doc 任务状态数据
-record(mission_status_data, {
    npc_list=[],%% NPC列表
    collect_point_list=[],%%本任务该状态下 允许的采集点ID
    time_limit = 0,%%时间限制型任物
    use_item_point_list = [] %% 本任务状态下才能使用相应的任务道具位置
}).

%% 任务状态数据 赠送道具并使用道具完成任务相关状态特殊数据配置
%% item_id 道具id map_id 地图id tx,ty 位置 total_progress 进度 new_type_id 新的道具id new_number 道具数据 show_name 显示名称
%% progress_desc 读条操作显示
-record(mission_status_data_use_item,{item_id=0,map_id=0,tx=0,ty=0,
       total_progress=0,new_type_id=0,new_number=0,show_name,progress_desc}).


%%@doc 奖励数组的每个元素类型 
-record(mission_reward_data, {
    rollback_times=1,%% 执行次数大于该值时奖励回滚为第一次奖励
    prop_reward_formula=1,%% 道具给与方式 1全部给与 2选择 3随机 4转盘
    attr_reward_formula=1,%% 属性给与公式 1普通 x...
    exp=0,%%经验奖励
    silver=0,%%钱币
    silver_bind=0,%%铜钱,
    gold_bind=0,%%礼券,
    prestige =0,%%声望值
    category_reward =false,%%是否根据职业给道具
    prop_reward,%%道具奖励#p_mission_prop
    tili = 0
}).

%%@doc 任务计数器
-record(mission_counter, {
    key={0, 0},%% {KeyType,ID} KeyType=0表示普通任务,=1表示循环任务
    id=0,%% 任务ID
    big_group=0,
    last_clear_counter_time=0,%% 最后一次清零的时间
    commit_times=0,%% 提交次数,
    succ_times=0,%% 成功次数
    other_data=null%% 其他数据数组
}).

%%@doc 任务基础数据
-record(mission_base_info, {
    id,%% 任务ID
    name,%% 任务名
    type=0,%% 类型-1主-2支-3循 4-境界
    model,%% 模型处理模块
    big_group=0,%% 大组
    small_group=0,%% 小组
    time_limit_type=0,%% 时间限制类型--0无限制--1每天--2每周--3每月
    time_limit=[],%% #mission_time_limit
    pre_mission_id=0, %%前置任务ID
    next_mission_list=[], %%后置任务ID列表
    pre_prop_list=[], %%前置任务道具列表 #pre_mission_prop{}
    gender=0,%% 性别
    faction=0,%国家
    team=0,%% 是否需要组队
    family=0,%% 需要家族
    min_level=0,%% 最低等级限制
    max_level=0,%% 最高等级限制
    vip_level=0,%% 最低VIP级别
    max_do_times=1,%% 最多可以做的次数
    listener_list=[],%% #mission_listener_data 侦听器数据
    max_model_status=0,%% 最大状态的模型值从0开始算
    model_status_data=[],%% #mission_status_data 状态数据
    reward_data%% #mission_reward_data 奖励数据
}).

-define(MODULE_MISSION_DATA_DETAIL, mission_data_detail).%% 任务内存基础数据模块名
-define(MODULE_MISSION_DATA_KEY_GROUP, mission_data_key_group).%% 任务内存数据分组key模块名
-define(MODULE_MISSION_DATA_KEY_NO_GROUP, mission_data_key_no_group).%% 任务内存数据没有分组的key模块名
-define(MODULE_MISSION_DATA_SETTING, module_mission_data_setting).%% 任务内存数据配置模块名

%%@doc 任务详细信息模块基础代码
-define(MISSION_DATA_DETAIL_HEADER(ModuleName), 
(fun() ->
"-module(" ++ ModuleName ++ ").
-export([get/1, get_group/1, get_group_random_one/1]). 
~s
get(Other) -> throw({mission_data_detail_error, not_match, Other}). 
~s
get_group(Other) -> throw({mission_data_group_detail_error, not_match, Other}). 
~s
get_group_random_one(Other) -> throw({mission_data_group_random_one_detail_error, not_match, Other}). "
end)()).

%%@doc 任务key模块基础代码
-define(MISSION_DATA_KEY_HEADER(ModuleName), 
(fun() ->
"-module(" ++ ModuleName ++ ").
-export([get/1]).
~s 
get(_Other) -> false. "
end)()).


%%任务类型：
-define(MISSION_TYPE_MAIN, 1).  %%主
-define(MISSION_TYPE_BRANCH, 2). %%支
-define(MISSION_TYPE_LOOP, 3). %%循环
-define(MISSION_TYPE_TITLE, 4). %%称号


%%@doc 任务广播列表
-define(MISSION_UNICAST_DICT_KEY, mission_unicast_dict_key).
%%@doc 任务列表操作 用来合并各种更新操作
-define(MISSION_UNICAST_UPDATE_DICT_KEY, mission_unicast_update_dict_key).

%%@doc 任务数据持久化时间
%%@doc 要比主循环的持久化大一点 才能错开用户的持久化 否则会同时间大批玩家持久化
-define(MISSION_PERSISTENT_TIME, 40).

%%@doc 任务调试自用的DEBUG宏
-define(MISSION_DEBUG(P, Data), (fun() ->
    ?ERROR_MSG("=======任务调试========~n"++P, Data)
end)()).


%%@doc 任务时间限制类型 --> 无限制
-define(MISSION_TIME_LIMIT_NO, 0).

%%@doc 任务时间限制类型 --> 每天
-define(MISSION_TIME_LIMIT_DAILY, 1).

%%@doc 任务时间限制类型 --> 每月 x - 每月 y
-define(MISSION_TIME_LIMIT_MONTH, 2).

%%@doc 任务时间限制类型 --> 每周 x - 每周 y
-define(MISSION_TIME_LIMIT_WEEK, 3).

%%@doc 任务时间限制类型 --> 具体某一天到某一天
-define(MISSION_TIME_LIMIT_SOMEDAY, 4).


%%@doc 任务模型状态未接状态,任务模型状态从0开始计起
-define(MISSION_MODEL_STATUS_FIRST, 0).

%%@doc 玩家的自己的任务状态
%%@doc 1未接 2已接 3可提交
-define(MISSION_STATUS_NOT_ACCEPT, 1).
-define(MISSION_STATUS_DOING, 2).
-define(MISSION_STATUS_FINISH, 3).

%%@doc 委托任务的状态:0=未接,1=已接,2=已完成(尚未领奖),3=不可接(循环次数不在允许范围内)
-define(MISSION_AUTO_STATUS_NOT_START, 0).
-define(MISSION_AUTO_STATUS_DOING, 1).
-define(MISSION_AUTO_STATUS_FINISH, 2).
-define(MISSION_AUTO_STATUS_MAX_LIMIT, 3).

-define(MISSION_CODE_SUCC, 0).
-define(MISSION_CODE_FAIL_SYS, 1). %%系统错误
-define(MISSION_CODE_FAIL_NOT_FOUND, 2). %%未找到对应任务
-define(MISSION_CODE_FAIL_STATUS_ERROR, 3).%%玩家试图做任务 但目前任务所处状态不对
-define(MISSION_CODE_FAIL_NPC_NOT_MATCH, 4).%%玩家试图做任务 但对话的NPC不是系统想要的
-define(MISSION_CODE_FAIL_BAG_NOT_ENOUGH_POS, 5).%%任务赠送道具，出现背包空间已满的错误
-define(MISSION_CODE_FAIL_GIVE_PROP, 6).%%玩家增加任务道具时出现错误
-define(MISSION_CODE_FAIL_DEL_PROP, 7).%%玩家扣除任务道具时出现错误
-define(MISSION_CODE_FAIL_SB_NOT_MATCH_TIME, 8).%%守边未到达时间
-define(MISSION_CODE_FAILE_CITAN_CHOOSE_A_FACTION, 9).%%刺探选择一个国家
-define(MISSION_CODE_FAILE_CITAN_CHOOSE_A_FACTION_LIMIT, 10).%%去同一个国家达到次数限制
-define(MISSION_CODE_FAIL_SB_DUPLICATE_DO, 11).%%守边前端频繁提交 应该是计时器出问题 或丢帧导致频繁提交
-define(MISSION_CODE_FAIL_PMISSIONINFO_NOT_FOUND, 12). %%未找到对应的执行任务
-define(MISSION_CODE_FAIL_NOT_BUY_NEED_PROP, 13). %%未打开商城购买道具
-define(MISSION_CODE_FAIL_NOT_LEVEL_UP, 14). %%未进行升级
-define(MISSION_CODE_FAIL_DEDUCT_PRE_PROP, 15). %%扣除前置道具失败
-define(MISSION_CODE_FAIL_TOUCH_SET_NOT_FOUND, 16). %%没有任务摆设需要触摸
-define(MISSION_CODE_FAIL_TITLE_MISSION_CANNOT_CANCEL, 17). %%不能取消境界副本任务
-define(MISSION_CODE_FAIL_CANNOT_CANCEL, 18). %%特殊任务不能取消

-define(MISSION_CODE_AUTHFAIL_FACTION_LIMIT, 20). %%任务验证失败-国家限制
-define(MISSION_CODE_AUTHFAIL_SEX_LIMIT, 21). %%任务验证失败-性别限制
-define(MISSION_CODE_AUTHFAIL_TEAM_LIMIT, 22). %%任务验证失败-组队限制
-define(MISSION_CODE_AUTHFAIL_FAMILY_LIMIT, 23). %%任务验证失败-宗族限制
-define(MISSION_CODE_AUTHFAIL_LEVEL_LIMIT, 24). %%任务验证失败-级别限制
-define(MISSION_CODE_AUTHFAIL_PREMISSION_LIMIT, 25). %%任务验证失败-前置任务限制
-define(MISSION_CODE_AUTHFAIL_TIME_LIMIT, 26). %%任务验证失败-时间限制
-define(MISSION_CODE_AUTHFAIL_MAX_DO_TIMES_LIMIT, 27). %%任务验证失败-最多次数限制
-define(MISSION_CODE_AUTHFAIL_PROP_NOT_ENOUGH, 28). %%任务验证失败-缺少任务道具
-define(MISSION_CODE_AUTHFAIL_DOING_AUTO_MISSION, 29). %%真正做此项的委托任务
-define(MISSION_CODE_AUTHFAIL_VIP_LIMIT, 30). %%任务验证失败-VIP级别不够
-define(MISSION_CODE_AUTHFAIL_ROLE_SILVER_LIMIT, 32). %%任务验证失败-玩家身上	钱币不够

%%@doc 委托任务的错误状态码
-define(MISSION_AUTO_CODE_SUCC, 0).
-define(MISSION_AUTO_CODE_FAIL_SYS, 1). %%系统错误
-define(MISSION_AUTO_CODE_FAIL_NOT_START, 2). %%委托任务尚未开始
-define(MISSION_AUTO_CODE_FAIL_HAS_FINISHED, 3). %%委托任务已经完成
-define(MISSION_AUTO_CODE_FAIL_GOLD_NOT_ENOUGH, 4).  %%委托任务，扣除的元宝不足
-define(MISSION_AUTO_CODE_FAIL_MAX_LIMIT, 5). %%已经达到委托的任务上线


-define(MISSION_ERROR_MAN, man).  %%任务系统内部抛错的错误头

%%@doc 数值奖励类型
-define(MISSION_ATTR_REWARD_FORMULA_NO, 0).%%0木有奖励
-define(MISSION_ATTR_REWARD_FORMULA_NORMAL, 1).%%1普通 -按照配置多少就给多少 没任何其他计算
-define(MISSION_ATTR_REWARD_FORMULA_CALC_ALL_TIMES, 2).%%2对所有的经验和银两都按照次数来累计计算
-define(MISSION_ATTR_REWARD_FORMULA_CALC_EXP_TIMES, 3).%%3仅对经验按照次数来累计计算
-define(MISSION_ATTR_REWARD_FORMULA_WU_XING, 4).%%给与五行属性

%%@doc 道具奖励类型
-define(MISSION_PROP_REWARD_FORMULA_NO, 0).%%0木有奖励
-define(MISSION_PROP_REWARD_FORMULA_CHOOSE_ONE, 1).%%几个选一个
-define(MISSION_PROP_REWARD_FORMULA_CHOOSE_RANDOM, 2).%%从随机库取一个
-define(MISSION_PROP_REWARD_FORMULA_ALL, 3).%%3全部给于

%%%任意怪改为当怪物id为0时出发
-define(MISSION_FREE_MONSTER_ID, 0).%%%打任意怪的怪物id

%%@doc 侦听器类型
-define(MISSION_LISTENER_TYPE_MONSTER, 1).%%怪物
-define(MISSION_LISTENER_TYPE_PROP, 2).%%道具
-define(MISSION_LISTENER_TYPE_BUY_PROP, 3).%%商城购买道具
-define(MISSION_LISTENER_TYPE_ROLE_LEVEL, 4).   %%玩家升等级
-define(MISSION_LISTENER_TYPE_SPEC_EVENT, 5).   %%特殊事件侦听器
-define(MISSION_LISTENER_TYPE_GIVE_USE_PROP, 9).%% 赠送使用道具
-define(MISSION_LISTENER_TYPE_TOUCH_SET, 10).%%触摸任务摆设
-define(MISSION_LISTENER_TYPE_JINGJIE, 11). %%初出茅庐境界的任务类型（完成任务可以得境界），基本上只有13号模型用
-define(MISSION_LISTENER_TYPE_ENTER_SW_FB, 12). %%进入副本的任务类型（进入副本就算完成任务），基本上只有13号模型用
-define(MISSION_LISTENER_TYPE_PET_GROW, 13).%%异兽对练
-define(MISSION_LISTENER_TYPE_PET_UNDERSTAND, 14).%%异兽提悟
-define(MISSION_LISTENER_TYPE_PET_ATTACK_APTITUDE, 15).%%异兽的攻击资质
-define(MISSION_LISTENER_TYPE_PET_LEVELUP, 16).%%异兽升级到指定级别
-define(MISSION_LISTENER_TYPE_ENTER_HERO_FB, 17). %%进入斗帝副本
-define(MISSION_LISTENER_TYPE_EQUIP_QIANGHUA, 18).%%装备强化
-define(MISSION_LISTENER_TYPE_EQUIP_UPGRADE, 19).%%装备部位进阶
-define(MISSION_LISTENER_TYPE_SKILL_UPGRADE, 20).%%星宿升级
-define(MISSION_LISTENER_TYPE_FASHION_QIANGHUA,21). %% 时装强化
-define(MISSION_LISTENER_TYPE_MOUNT_QIANGHUA,22). %% 坐骑强化
-define(MISSION_LISTENER_TYPE_CONSUME_UNBIND_GOLD,23). %% 累计消耗多少非礼券

 -define(MISSION_LISTENER_TYPE_YBC,    24).%%完成多少次个人拉镖

 -define(MISSION_LISTENER_TYPE_NUQI_SKILL_UPGRADE, 25).%%怒气技能升级
 -define(MISSION_LISTENER_TYPE_NUQI_SHAPE_UPGRADE, 26).%%怒气技能形态升级


-define(MISSION_LISTENER_TYPE_REINFORCE, 1401).%%强化装备，基本上只有14号模型用
-define(MISSION_LISTENER_TYPE_CHANGE_QUALITY, 1402).%%品质提升，基本上只有14号模型用
-define(MISSION_LISTENER_TYPE_EQUIP_SLOTNUM_UPGRADE_COLOR, 61).%%装备部位提色



-define(MISSION_KEY_LEVEL_RANGE, 10).%%任务等级范围 等级跨度

%%@doc 事务方法的key
-define(MISSION_TRANS_FUNC_LIST(RoleID),{mission_trans_func_list,RoleID}).

-define(DO_TRANS_FUN(TransFun),
        case common_transaction:transaction(TransFun) of
            {atomic,Result}->
                mod_mission_unicast:c_unicast(RoleID),
                mod_mission_misc:c_trans_func(RoleID),
                {atomic, Result};
        	{aborted,{throw,{bag_error,{not_enough_pos,_BagID}}=R3}}->
				mod_mission_unicast:r_unicast(RoleID),
                mod_mission_misc:r_trans_func(RoleID),
                {aborted,R3};
			{aborted,{bag_error,{not_enough_pos,_BagID}}=R3}->
                mod_mission_unicast:r_unicast(RoleID),
                mod_mission_misc:r_trans_func(RoleID),
                {aborted,R3};
            {aborted, {error, ErrorCode, ErrorStr}} ->
                mod_mission_unicast:r_unicast(RoleID),
                mod_mission_misc:r_trans_func(RoleID),
                common_misc:send_common_error(RoleID, ErrorCode, ErrorStr);
            {aborted,Result}->
                case Result of
                    {man, _, _}->
                        ignore;
                    _ ->
                        ?ERROR_MSG("transaction aborted,RoleID=~w,Result=~w,PInfo=~w,MissionBaseInfo=~w",[RoleID,Result,PInfo,MissionBaseInfo])
                end,
                mod_mission_unicast:r_unicast(RoleID),
                mod_mission_misc:r_trans_func(RoleID),
                {aborted,Result}
        end).

%%@doc 任务数据里的扩展字段
-record(mission_data_extend, {key, extend_data}).

%%@doc 任务扩展数据key定义
%%@doc 刺探
-define(MISSION_EXTEND_DATA_KEY_CI_TAN, 1).

%%@doc 任务在地图大循环时处理玩家任务列表更新 - 保存需要更新的玩家列表
-define(MISSION_MAP_LOOP_ROLE_LIST, mission_map_loop_role_list).

%%@doc 任务版本号
-define(MISSION_VS_DICT_KEY, mission_vs_dict_key).

-define(MISSION_MODEL_1,1). %% 对话模型,选择题
-define(MISSION_MODEL_2,2). %% 打怪
-define(MISSION_MODEL_3,3). %% 打怪收集
-define(MISSION_MODEL_4,4). %% 道具搜集模型 - 2次对话
-define(MISSION_MODEL_5,5). %% 道具搜集模型 - 3次对话 - 中间那只NPC给道具
-define(MISSION_MODEL_6,6). %% 商城购买任务模型 - 3次对话 - 中间状态购买道具
-define(MISSION_MODEL_7,7). %% 道具搜集模型 - 3次对话 - 第一只npc给道具
-define(MISSION_MODEL_8,8). %% 采集模型
-define(MISSION_MODEL_9,9). %% 守边模型
-define(MISSION_MODEL_10,10). %% 刺探模型
-define(MISSION_MODEL_11,11). %% 神兵图鉴兑换模型，判断是否集齐图鉴（一）（二）（三）
-define(MISSION_MODEL_12,12). %% 玩家升级任务模型 - 3次对话 - 中间状态去升级
-define(MISSION_MODEL_13,13). %% 特殊事件的侦听器 - 3次对话 - 中间状态去完成事件
-define(MISSION_MODEL_14,14). %% 装备强化、品质提升模型，其实就是触发事件的参数，>=指定的value的参数值就OK
-define(MISSION_MODEL_15,15). %% 道具收集任务
-define(MISSION_MODEL_16,16). %% 使用道具完成任务类型 4 status 
-define(MISSION_MODEL_17,17). %% 使用道具完成任务类型 3 status
-define(MISSION_MODEL_18,18). %% 使用道具召唤怪物并杀死完成任务类型 3 status
