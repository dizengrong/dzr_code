%% Author: ldk
%% Created: 2012-11-1
%% Description: TODO: Add description to mod_spring 
%% ————温泉模块————
-module(mod_spring).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([   
         init/2,
         loop/2,
         check_can_use/4,
         handle/1,
         handle/2,
         do_terminate/1,
         is_in_spring_map/0,
         hook_role_enter/2,
         hook_role_quit/1,
         hook_role_offline/1,
         assert_valid_map_id/1,
         get_map_name_to_enter/1,
         clear_map_enter_tag/1,
		 change_skin/2
        ]).

-export([
         gm_open_spring/1,
         gm_close_spring/0,
         gm_reset_open_times/0
        ]).

-define(ERR_SPRING_DISABLE,124001).     %%温泉活动暂未开放
-define(ERR_SPRING_ENTER_LV_LIMIT,124002).     %%等级不够，不能进入温泉
-define(ERR_SPRING_ENTER_IN_FB,124003).     %%已经在温泉副本里了
-define(ERR_SPRING_ENTER_FB_LIMIT,124004).     %%此地图不允许进入温泉
-define(ERR_SPRING_ENTER_CLOSING,124005).     %%温泉还没开启
-define(ERR_SPRING_ENTER_MAX_ROLE_NUM,124006).     %%已到副本最大人数，下次早点来吧
-define(ERR_SPRING_BUY_BUFF_NOT_IN_MAP,124007).     %%不在温泉地图里不能购买BUFF
-define(ERR_SPRING_BUY_BUFF_GOLD_NOT_ENOUGH,124008).     %%元宝不足不能购买BUFF
-define(ERR_SPRING_BUY_BUFF_MAX,124009).     %%已是最高倍数，不能再购买



-define(SPRING_MAP_ID,10512).     %%地图ID
%% 对应的活动ID, 与activity_notice.config里的一致
-define(SPRING_ACTIVITY_ID,10029). %%活动ID
-define(SPRING_MAP_NAME_TO_ENTER,spring_map_name_to_enter).
-define(SPRING_TIME_DATA,spring_time_data).

-define(SPRING_DATA_ADD,spring_data_add).
-define(SPRING_MAP_INFO,spring_map_info).
-define(SPRING_ENTRANCE_INFO,spring_entrance_info).

-define(BUY_BUFF_TYPE_EXP,1).
-define(BUY_BUFF_TYPE_PRESTIGE,2).

%% 30105121 30105122 30105123,分别是水花，男，女
-define(SPRING_WATER,30105121).     %%温泉特殊处理，水花
-define(GM_SPRING_OPEN_LAST_TIME,1800).     %%GM开启温泉持续时间

-define(SPRING_BUFF_WOMAN,110502).     %%BUFF，进入温泉和全体一样使用BUFF，女
-define(SPRING_BUFF_MAN,110501).     %%BUFF，进入温泉和全体一样使用BUFF,男
-define(SPRING_BUFF_TYPE,1004).     %%BUFF类型

-define(FEIZAO_ITEM_ID,11510004).     %%肥皂
-define(XIANGZAO_ITEM_ID,11510005).     %%香皂
-define(HUHUZAO_ITEM_ID,11510006).     %%护肤皂
  
-define(LAST_EXP_BUFFID,10000).     %%最后一个经验BUFFID，和配置文件里的一至
-define(LAST_PRESTIGE_BUFFID,20000).     %%最后一个声望BUFFID，和配置文件里的一至

%% 加经验间隔
-define(INTERVAL_EXP_LIST, interval_exp_list).

-define(T_SPRING_INFO, t_spring_info).
-define(T_SPRING_ROLE_INFO, t_spring_role_info).

-record(r_spring_entrance_info,{is_opening=false,map_role_num=0}).

-record(r_spring_map_info,{is_opening=false,cur_role_list=[]}).

-record(r_spring_data_add,{role_list=[],max_feizao=0,max_xiangzao=0,
                           max_huhuzao=0,max_shengwang=0,max_jingyan=0}).

-record(r_spring_time,{date = 0,start_time = 0,end_time = 0,
                       next_bc_start_time = 0,next_bc_end_time = 0,next_bc_process_time = 0,
                       before_interval = 0,close_interval = 0,process_interval = 0}).

-record(r_spring_role_info,{role_id=0,next_exp_buff_id=0,next_exp_buff_cost=0,buy_exp_buff_id=0,
                            next_prestige_buff_id=0,next_prestige_buff_cost=0,buy_prestige_buff_id=0,weapon,
                            feizao_times=0,xiangzao_times=0,huhuzao_times=0,
                            bei_feizao_times = 0, bei_xiangzao_times = 0, bei_huhuzao_times = 0,
                            summoned_pet_id = undefined }).

-define(CONFIG_NAME,spring).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

assert_valid_map_id(DestMapID)->
    case is_fb_map_id(DestMapID) of
        true->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
            throw({error,error_map_id,DestMapID})
    end.

is_fb_map_id(DestMapId)->
    DestMapId =:= ?SPRING_MAP_ID.

is_in_spring_map()->
    mgeem_map:get_mapid() == ?SPRING_MAP_ID.

get_map_name_to_enter(RoleID)->
    case get({?SPRING_MAP_NAME_TO_ENTER,RoleID}) of
        {_RoleID,FbMapProcessName}->
            FbMapProcessName;
        _ ->
            undefined
    end.

clear_map_enter_tag(RoleID)->
    erlang:erase({?SPRING_MAP_NAME_TO_ENTER,RoleID}).

%%
%% API Functions
%%
handle(Info,_State) ->
    handle(Info).

handle({_, ?SPRING, ?SPRING_ENTER,_,_,_,_,_}=Info) ->
    %% 进入温泉
    do_spring_enter(Info); 
handle({_, ?SPRING, ?SPRING_QUIT,_,_,_,_,_}=Info) ->
    %% 退出温泉
    do_spring_quit(Info);
handle({_, ?SPRING, ?SPRING_BUY_BUFF,_,_,_,_,_}=Info) ->
    do_spring_buy_buff(Info);

handle({req_spring_entrance_info}) ->
    do_req_spring_entrance_info();
handle({init_spring_entrance_info,EntranceInfo}) ->
    do_init_spring_entrance_info(EntranceInfo);

handle({kick_all_roles}) ->
    kick_all_roles();

handle({gm_open_spring, Second}) ->
    case is_opening_spring() of
        true->
            ignore;
        _ ->
            gm_open_spring(Second)
    end;
handle({gm_close_spring}) ->
    case is_opening_spring() of
        true->
            TimeData = case get_spring_time_data() of
				undefined ->
					#r_spring_time{};
				T ->
					T
			end,
            TimeData2 = TimeData#r_spring_time{end_time=common_tool:now()},
            set_spring_time_data(TimeData2),
            ok;
        _ ->
            ignore
    end;

handle({{use_item,self},RoleID,NewSpringRoleInfo,NewValue,ItemID,{SelfAddExp,SelfAddPrestige},{RoleName,EffectName}}) ->
    set_spring_role_info(RoleID,NewSpringRoleInfo),
    mod_map_role:do_add_exp(RoleID,SelfAddExp),
    mod_prestige:do_add_prestige(RoleID, SelfAddPrestige,?GAIN_TYPE_PRESTIGE_SPRING),
    R1 = #m_spring_update_toc{code=ItemID,value=NewValue},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SPRING, ?SPRING_UPDATE, R1),
    %%只有护肤皂使用才广播
    case ItemID of
        ?HUHUZAO_ITEM_ID ->
            BroadcastMsg = common_misc:format_lang(<<"~s对~s使用了护肤皂，大叹~s的皮肤好软，手感好滑">>,[RoleName,EffectName,EffectName]),
            catch ?WORLD_CENTER_BROADCAST(BroadcastMsg);
        _ ->
            ignore
    end,
    case ItemID of
        ?HUHUZAO_ITEM_ID ->
            Msg = common_misc:format_lang(<<"你对~s使用了护肤皂，经验和声望大增">>,[EffectName]);
        ?FEIZAO_ITEM_ID ->
            Msg = common_misc:format_lang(<<"你对~s使用了肥皂，经验和声望大增">>,[EffectName]);
        ?XIANGZAO_ITEM_ID ->
            Msg = common_misc:format_lang(<<"你对~s使用了香皂，经验和声望大增">>,[EffectName])
    end,
    common_misc:common_broadcast_item_get(RoleName, ItemID, ?MODULE),
    catch ?ROLE_CENTER_BROADCAST(RoleID,Msg);

handle({{use_item,other},EffectID,ItemID,{OtherAddExp,OtherAddPrestige},{RoleName,_EffectName}, NewSpringRoleInfo}) ->
    set_spring_role_info(EffectID,NewSpringRoleInfo),
    mod_map_role:do_add_exp(EffectID,OtherAddExp),
    mod_prestige:do_add_prestige(EffectID, OtherAddPrestige,?GAIN_TYPE_PRESTIGE_SPRING),
    case ItemID of
        ?HUHUZAO_ITEM_ID ->
            Msg = common_misc:format_lang(<<"~s对你使用了护肤皂，经验和声望大增">>,[RoleName]),
            set_spring_record({max_huhuzao});
        ?FEIZAO_ITEM_ID ->
            Msg = common_misc:format_lang(<<"~s对你使用了肥皂，经验和声望大增">>,[RoleName]),
            set_spring_record({max_feizao});
        ?XIANGZAO_ITEM_ID ->
            Msg = common_misc:format_lang(<<"~s对你使用了香皂，经验和声望大增">>,[RoleName]),
            set_spring_record({max_xiangzao})
    end,
    catch ?ROLE_CENTER_BROADCAST(EffectID,Msg);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

is_opening_spring()->
    case get_spring_map_info() of
        #r_spring_map_info{is_opening=IsOpening}->
            IsOpening;
        _ ->
            false
    end.

get_spring_entrance_info()->
    lookup(?SPRING_ENTRANCE_INFO).
get_spring_time_data()->
    lookup(?SPRING_TIME_DATA).
set_spring_time_data(TimeData2)->
    insert(?SPRING_TIME_DATA,TimeData2).
get_spring_map_info()->
    lookup(?SPRING_MAP_INFO).
set_spring_map_info(SpringMapInfo)->
    insert(?SPRING_MAP_INFO,SpringMapInfo).
get_spring_data_add()->
    lookup(?SPRING_DATA_ADD).
set_spring_data_add(SpringDataAdd)->
    insert(?SPRING_DATA_ADD,SpringDataAdd).
erase_spring_data_add()->
    insert(?SPRING_DATA_ADD,#r_spring_data_add{role_list=[]}).

lookup(Key) ->
	case ets:lookup(?T_SPRING_INFO, Key) of
		[{_, Value}] ->
			Value;
		_ ->
			undefined
	end.

insert(Key, Value) ->
	ets:insert(?T_SPRING_INFO, {Key, Value}).
		

get_spring_role_info(RoleID)->
	case ets:lookup(?T_SPRING_ROLE_INFO, RoleID) of
		[SpringRoleInfo] ->
			SpringRoleInfo;
		_ ->
			false
	end.

set_spring_role_info(_RoleID,SpringRoleInfo)->
	ets:insert(?T_SPRING_ROLE_INFO, SpringRoleInfo).
erase_spring_role_info() ->
    ets:delete_all_objects(?T_SPRING_ROLE_INFO).

hook_role_quit(RoleID)->
    case is_in_spring_map() of
        false ->
            ignore;
        true ->
            case get_spring_map_info() of
                #r_spring_map_info{cur_role_list=CurRoleList}=MapInfo->
                    NewCurRoleList = lists:delete(RoleID,CurRoleList),
                    set_spring_map_info(MapInfo#r_spring_map_info{cur_role_list=NewCurRoleList}),
                    req_spring_entrance_info(),
                    %% 移出加经验列表
                    %%同init在同一个进程,可添加记录进入玩家数据
                    delete_interval_exp_list(RoleID),
                    case get_spring_role_info(RoleID) of
                        false -> ignore;
                        #r_spring_role_info{summoned_pet_id = SummonedPetID} ->
                            case SummonedPetID of
                                undefined -> ignore;
                                _ ->
                                    PID   = erlang:get({roleid_to_pid, RoleID}),
                                    State = mgeem_map:get_state(),
                                    mod_map_pet:do_summon(RoleID, SummonedPetID, PID, true, State)
                            end
                    end;
                _ ->
                    ignore
            end
    end.

hook_role_offline(RoleID)->
    case get_spring_map_info() of
        #r_spring_map_info{cur_role_list=CurRoleList}=MapInfo->
            NewCurRoleList = lists:delete(RoleID,CurRoleList),
            set_spring_map_info(MapInfo#r_spring_map_info{cur_role_list=NewCurRoleList}),
            req_spring_entrance_info(),
            %% 移出加经验列表
            delete_interval_exp_list(RoleID),
            change_skin(RoleID,get_fashion(RoleID)),
            ok;
        _ ->
            ignore
    end.

hook_role_enter(RoleID,MapID) when MapID == ?SPRING_MAP_ID ->
    case get_spring_map_info() of
        #r_spring_map_info{is_opening=true}=SpringMapInfo->
            hook_role_enter_2(RoleID,SpringMapInfo);
        _ ->
            case is_fb_map_id(MapID) of
                true ->
                    do_spring_quit_2(RoleID);
                _ ->
                    ignore
            end
    end;
hook_role_enter(_RoleID,_MapID) ->
    ignore.

hook_role_enter_2(RoleID, SpringMapInfo)->
    hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_SPRING_FB),
    set_spring_record({max_role_num, RoleID}),
    #r_spring_map_info{cur_role_list=CurRoleList}=SpringMapInfo,
    set_spring_map_info(SpringMapInfo#r_spring_map_info{cur_role_list=[RoleID|CurRoleList]}),
    req_spring_entrance_info(),
    mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE),
    %% 插入加经验列表
    insert_interval_exp_list(RoleID),
    #r_spring_time{start_time = StartTime,end_time = EndTime} = get_spring_time_data(),
    {ok,OldWeapon} = change_skin(RoleID,enter),
    case get_spring_role_info(RoleID) of
        false ->
            {NextExpBuffID,NeedCostExp} = new_can_buy_buff(RoleID,?BUY_BUFF_TYPE_EXP),
            {NextPrestigeBuffID,NeedCostPrestige} = new_can_buy_buff(RoleID,?BUY_BUFF_TYPE_PRESTIGE),
            [FeizaoTimes] = ?find_config(feizao_max_times),
            [XiangzaoTimes] = ?find_config(xiangzao_max_times),
            [HuhuzaoTimes] = ?find_config(huhuzao_max_times),
            set_spring_role_info(RoleID,#r_spring_role_info{role_id=RoleID,
                                                            weapon=OldWeapon,
                                                            feizao_times=FeizaoTimes,
                                                            xiangzao_times=XiangzaoTimes,
                                                            huhuzao_times=HuhuzaoTimes,
                                                            bei_feizao_times=FeizaoTimes,
                                                            bei_xiangzao_times=XiangzaoTimes,
                                                            bei_huhuzao_times=HuhuzaoTimes,
                                                            next_exp_buff_id=NextExpBuffID,
                                                            next_exp_buff_cost=NeedCostExp,
                                                            next_prestige_buff_id=NextPrestigeBuffID,
                                                            next_prestige_buff_cost=NeedCostPrestige});
		SpringRole = #r_spring_role_info{feizao_times=FeizaoTimes,
			                            xiangzao_times=XiangzaoTimes,
			                            huhuzao_times=HuhuzaoTimes,
			                            next_exp_buff_id=NextExpBuffID,
			                            next_exp_buff_cost=NeedCostExp,
			                            next_prestige_buff_id=NextPrestigeBuffID,
			                            next_prestige_buff_cost=NeedCostPrestige} ->
            OldWeapon =:= ?SPRING_WATER orelse
                set_spring_role_info(RoleID,SpringRole#r_spring_role_info{weapon=OldWeapon})
    end,
    R1 = #m_spring_info_toc{fb_start_time=StartTime,fb_end_time=EndTime,
                            next_exp_buff_id=NextExpBuffID,need_cost_exp=NeedCostExp,feizao_times=FeizaoTimes,
                            xiangzao_times=XiangzaoTimes,huhuzao_times=HuhuzaoTimes,
                            next_prestige_buff_id=NextPrestigeBuffID,need_cost_prestige=NeedCostPrestige},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SPRING, ?SPRING_INFO, R1),
    ok.

get_fashion(RoleID) ->
    #r_spring_role_info{weapon=Weapon} = get_spring_role_info(RoleID),
    {Weapon}.
%%
change_skin(RoleID,ChangeSkin) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    {ok, #p_role_base{sex=Sex}} = mod_map_role:get_role_base(RoleID),
    #p_role_attr{skin=Skin} = RoleAttr,
    case ChangeSkin of
        enter ->
            case Sex of
                1 ->
                    mod_role_buff:add_buff(RoleID,?SPRING_BUFF_MAN),
                    Skin2 = Skin#p_skin{weapon=?SPRING_WATER};
                _ ->
                    mod_role_buff:add_buff(RoleID,?SPRING_BUFF_WOMAN),
                    Skin2 = Skin#p_skin{weapon=?SPRING_WATER}
            end;
        {Weapon} ->
            mod_role_buff:del_buff_by_type(RoleID,?SPRING_BUFF_TYPE),
            Skin2 = Skin#p_skin{weapon=Weapon}
    end,
	mod_role_tab:update_element(RoleID, p_role_attr, [{#p_role_attr.skin, Skin2}]),
	mod_map_role:do_update_map_role_info(RoleID, [{#p_map_role.skin, Skin2}]),
	{ok,Skin#p_skin.weapon}.


%% 玩家可以购买的buffID
%% return {NextBuffID,Cost}
new_can_buy_buff(_RoleID,BuffType) ->
    [{BuffID,_,Cost}|_BuffIDList] = spring_buff_list(BuffType),
    {BuffID,Cost}.

spring_buff_list(BuffType) ->
    [FbBuffList] = ?find_config(fb_buff_list),
    case lists:keyfind(BuffType,1,FbBuffList) of
        {BuffType,BuffIDList} ->
            BuffIDList;
        _ ->
            undefined
    end.

next_can_buy_buff(_RoleID,BuffType,{BuyBuffID,_CostMoney}) ->
    BuffIDList = spring_buff_list(BuffType),
    {_,NextBuyBuffID,_} = lists:keyfind(BuyBuffID, 1, BuffIDList),
    case lists:keyfind(NextBuyBuffID, 1, BuffIDList) of
        false ->
            case BuffType of
                ?BUY_BUFF_TYPE_PRESTIGE ->
                    NextCostMoney = NextBuyBuffID2 = ?LAST_PRESTIGE_BUFFID;
                _ ->
                    NextCostMoney = NextBuyBuffID2 = ?LAST_EXP_BUFFID
            end;
        {_,_,NextCostMoney} ->
            NextBuyBuffID2 = NextBuyBuffID
    end,
    {NextBuyBuffID2,NextCostMoney}.

init(MapId, _MapName) ->
    case is_fb_map_id(MapId) of
        true->
			ets:new(?T_SPRING_INFO, [named_table,public]),
			ets:new(?T_SPRING_ROLE_INFO, [named_table,public,{keypos, #r_spring_role_info.role_id}]),
            SpringMapInfo = #r_spring_map_info{is_opening=false,cur_role_list=[]},
            set_spring_map_info(SpringMapInfo),
            reset_battle_open_times(),
            SpringDataAdd = #r_spring_data_add{role_list=[]},
            set_spring_data_add(SpringDataAdd),
            ok;
        _ ->
            ignore
    end.

do_terminate(MapID) ->
    case MapID == ?SPRING_MAP_ID andalso is_opening() of
        true->
            RoleIdList = mod_map_actor:get_in_map_role(),
            lists:foreach(fun(RoleID) ->
                                  change_skin(RoleID,get_fashion(RoleID))         
                          end, RoleIdList);
        _ ->
            ignore
    end.

check_can_use(RoleID,RoleAttr,EffectID,ItemInfo) ->
    case mod_map_role:get_role_attr(EffectID) of
        undefined ->
            EffectLevel=EffectName=null,
            throw({error,<<"该物品不能直接使用">>});
        {ok,#p_role_attr{level=EffectLevel, role_name = EffectName }} ->
            next
    end,
    #r_spring_role_info{feizao_times=FeizaoTimes,
                        xiangzao_times=XiangzaoTimes,huhuzao_times=HuhuzaoTimes} = SpringRoleInfo = get_spring_role_info(RoleID),
    #r_spring_role_info{bei_feizao_times=BFeizaoTimes,
                        bei_xiangzao_times=BXiangzaoTimes,bei_huhuzao_times=BHuhuzaoTimes} = BSpringRoleInfo = get_spring_role_info(EffectID),
    case ItemInfo#p_goods.typeid of
        ?FEIZAO_ITEM_ID ->
            case FeizaoTimes > 0 of
                true ->
                    next;
                _ ->
                    throw({error,<<"使用失败，肥皂在此次温泉中已达最大使用次数">>})
            end,
            case BFeizaoTimes > 0 of
                true ->
                    next;
                _ ->
                    throw({error,<<"使用失败，目标玩家已经达到最大肥皂接受次数">>})
            end,
            NewValue = FeizaoTimes-1,
            FeizaoTimes1 = FeizaoTimes-1,
            XiangzaoTimes1 = XiangzaoTimes,
            HuhuzaoTimes1= HuhuzaoTimes,
            HuhuzaoTimes1= HuhuzaoTimes,
            BFeizaoTimes1 = BFeizaoTimes-1,
            BXiangzaoTimes1 = BXiangzaoTimes,
            BHuhuzaoTimes1= BHuhuzaoTimes;
        ?HUHUZAO_ITEM_ID ->
            case HuhuzaoTimes > 0 of
                true ->
                    next;
                _ ->
                    throw({error,<<"使用失败，护肤皂在此次温泉中已达最大使用次数">>})
            end,
            case BHuhuzaoTimes > 0 of
                true ->
                    next;
                _ ->
                    throw({error,<<"使用失败，目标玩家已经达到最大护肤皂接受次数">>})
            end,
            NewValue = HuhuzaoTimes-1 ,
            FeizaoTimes1 = FeizaoTimes,
            XiangzaoTimes1 = XiangzaoTimes,
            HuhuzaoTimes1= HuhuzaoTimes-1,
            BFeizaoTimes1 = BFeizaoTimes,
            BXiangzaoTimes1 = BXiangzaoTimes,
            BHuhuzaoTimes1= BHuhuzaoTimes-1;
        ?XIANGZAO_ITEM_ID ->
            case XiangzaoTimes > 0 of
                true ->
                    next;
                _ ->
                    throw({error,<<"使用失败，香皂在此次温泉中已达最大使用次数">>})
            end,
            case BXiangzaoTimes > 0 of
                true ->
                    next;
                _ ->
                    throw({error,<<"使用失败，目标玩家已经达到最大香皂接受次数">>})
            end,
            NewValue = XiangzaoTimes-1,
            FeizaoTimes1 = FeizaoTimes,
            XiangzaoTimes1 = XiangzaoTimes-1,
            HuhuzaoTimes1= HuhuzaoTimes,
            BFeizaoTimes1 = BFeizaoTimes,
            BXiangzaoTimes1 = BXiangzaoTimes-1,
            BHuhuzaoTimes1= BHuhuzaoTimes ;
        _ ->
            NewValue =0,
            FeizaoTimes1 = FeizaoTimes,
            XiangzaoTimes1 = XiangzaoTimes,
            HuhuzaoTimes1= HuhuzaoTimes,
            BFeizaoTimes1 = BFeizaoTimes,
            BXiangzaoTimes1 = BXiangzaoTimes,
            BHuhuzaoTimes1= BHuhuzaoTimes,
            throw({error,<<"使用物品出错">>})
    end,
    [{SelfAddExp,SelfAddPrestige}] = ?find_config({use_item,RoleAttr#p_role_attr.level}),
    [{OtherAddExp,OtherAddPrestige}] = ?find_config({use_item,EffectLevel}),
    [{{SelfExpMulit,SelfPrestigeMulit},{OtherExpMulit,OtherPrestigeMulit}}] = ?find_config({item,ItemInfo#p_goods.typeid}),
    Self = {common_tool:to_integer(SelfAddExp*SelfExpMulit),common_tool:to_integer(SelfAddPrestige*SelfPrestigeMulit)},
    Other = {EffectName,common_tool:to_integer(OtherAddExp*OtherExpMulit),common_tool:to_integer(OtherAddPrestige*OtherPrestigeMulit)},
    NewBSpringRoleInfo = BSpringRoleInfo#r_spring_role_info{bei_feizao_times=BFeizaoTimes1,
                                                            bei_xiangzao_times=BXiangzaoTimes1,bei_huhuzao_times=BHuhuzaoTimes1},
    {ok,SpringRoleInfo#r_spring_role_info{feizao_times=FeizaoTimes1, 
                                          xiangzao_times=XiangzaoTimes1,huhuzao_times=HuhuzaoTimes1}, 
        NewBSpringRoleInfo, NewValue, Self,Other}.

loop(MapId,NowSeconds) when MapId == ?SPRING_MAP_ID ->
    case get_spring_time_data() of
        #r_spring_time{date=Date} = NationBattleTimeData ->
            case Date =:= erlang:date() of
                true->
                    loop_2(NowSeconds,NationBattleTimeData);
                _->
                    ignore
            end;
        _ ->
            ignore
    end;
loop(_MapID,_Now) ->
    ignore.
loop_2(NowSeconds,NationBattleTimeData)->
    case ?find_config(enable_spring) of
        [true]->
            case is_opening() of
                true->
                    loop_opening(NowSeconds,NationBattleTimeData);
                _ ->
                    loop_closing(NowSeconds,NationBattleTimeData)
            end;
        _ ->
            ignore
    end.

loop_opening(NowSeconds,NationBattleTimeData)->
    #r_spring_time{end_time=EndTime} = NationBattleTimeData,
    %% 副本开启过程中广播处理
    do_fb_open_process_broadcast(NowSeconds,NationBattleTimeData),
    if
        EndTime>0 andalso NowSeconds>=EndTime->
            %% 关闭副本
            close_spring(),
            %% 活动关闭消息的提示
            common_activity:notfiy_activity_end(?SPRING_ACTIVITY_ID),
            ok;
        true->
            %% 加经验循环
            case ?find_config(fb_add_exp) of
                [{true,_}]->
                    do_add_exp_interval(NowSeconds);
                _ ->
                    ignore
            end,
            
            %%提前关闭广播
            ignore
    end.

loop_closing(NowSeconds,NationBattleTimeData)->
    #r_spring_time{start_time=StartTime, end_time=EndTime} = NationBattleTimeData,
    if
        StartTime>0 andalso NowSeconds>=StartTime->
            open_spring();
        true->
            %% 活动开始消息通知
            common_activity:notfiy_activity_start({?SPRING_ACTIVITY_ID, NowSeconds, StartTime, EndTime}),
            %%提前开始广播
            do_fb_open_before_broadcast(NowSeconds,NationBattleTimeData)
    end.

%%
%% Local Functions
%%
do_spring_enter({Unique, Module, Method, _DataIn, RoleID, PID, Line, State})->
    case catch check_spring_enter(RoleID) of
        ok ->
            do_spring_enter_2(Unique, RoleID, Line, State);
        {error,ErrCode,Reason}->
            R2 = #m_spring_enter_toc{err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

check_spring_enter(RoleID) ->
    [EnableSpring] = ?find_config(enable_spring),
    if
        EnableSpring=:=true->
            next;
        true->
            ?THROW_ERR( ?ERR_SPRING_DISABLE )
    end,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
        true -> 
            ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
        false -> ignore
    end,
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    assert_role_level(RoleAttr),

    #map_state{mapid=MapID,map_type=MapType} = mgeem_map:get_state(),
    IsInspringFb = is_fb_map_id(MapID),
    
    if
        MapType=:=?MAP_TYPE_COPY->
            ?THROW_ERR( ?ERR_SPRING_ENTER_FB_LIMIT );
        IsInspringFb->
            ?THROW_ERR( ?ERR_SPRING_ENTER_IN_FB );
        true->
            next
    end,
    %%检查入口信息
    case get_spring_entrance_info() of
        undefined->
            req_spring_entrance_info(),
            ?THROW_ERR( ?ERR_SPRING_ENTER_CLOSING );
        #r_spring_entrance_info{is_opening=true,map_role_num=CurRoleNum}->
            [NormalMaxRoleNum] = ?find_config(limit_fb_role_num),
            if
                CurRoleNum>=NormalMaxRoleNum->
                    req_spring_entrance_info(),
                    ?THROW_ERR( ?ERR_SPRING_ENTER_MAX_ROLE_NUM );
                true->
                    next
            end;
        _ ->
            req_spring_entrance_info(),
            ?THROW_ERR( ?ERR_SPRING_ENTER_CLOSING )
    end,
    ok.

assert_role_level(RoleAttr)->
    #p_role_attr{level=RoleLevel} = RoleAttr,
    [MinRoleLevel] = ?find_config(fb_min_role_level),
    if
        MinRoleLevel>RoleLevel->
            ?THROW_ERR( ?ERR_SPRING_ENTER_LV_LIMIT );
        true->
            next
    end,
    ok.

do_spring_enter_2(Unique, RoleID, Line, State) ->
    [FbBornPointsList] = ?find_config(fb_born_points),
    %%地图跳转
    FBMapId = ?SPRING_MAP_ID,
    FBMapName = common_map:get_common_map_name(FBMapId),
    {Tx,Ty} = common_tool:random_element(FbBornPointsList),
    set_map_enter_tag(RoleID,FBMapName),
    #p_role_pet_bag{summoned_pet_id=SummonedPetID} = mod_map_pet:get_role_pet_bag_info(RoleID),
    case get_spring_role_info(RoleID) of
        false ->
            {NextExpBuffID,NeedCostExp} = new_can_buy_buff(RoleID,?BUY_BUFF_TYPE_EXP),
            {NextPrestigeBuffID,NeedCostPrestige} = new_can_buy_buff(RoleID,?BUY_BUFF_TYPE_PRESTIGE),
            [FeizaoTimes] = ?find_config(feizao_max_times),
            [XiangzaoTimes] = ?find_config(xiangzao_max_times),
            [HuhuzaoTimes] = ?find_config(huhuzao_max_times),
            set_spring_role_info(RoleID,#r_spring_role_info{role_id=RoleID,
                                                            feizao_times=FeizaoTimes,
                                                            xiangzao_times=XiangzaoTimes,
                                                            huhuzao_times=HuhuzaoTimes,
                                                            bei_feizao_times=FeizaoTimes,
                                                            bei_xiangzao_times=XiangzaoTimes,
                                                            bei_huhuzao_times=HuhuzaoTimes,
                                                            next_exp_buff_id=NextExpBuffID,
                                                            next_exp_buff_cost=NeedCostExp,
                                                            next_prestige_buff_id=NextPrestigeBuffID,
                                                            next_prestige_buff_cost=NeedCostPrestige,
                                                            summoned_pet_id= SummonedPetID});
        SpringRole ->
            set_spring_role_info(RoleID,SpringRole#r_spring_role_info{summoned_pet_id = SummonedPetID})
    end,
    case SummonedPetID of
        undefined ->
            ignore;
        _ ->
            mod_map_pet:do_call_back(Unique, #m_pet_call_back_tos{pet_id=SummonedPetID,is_hidden=false}, RoleID, Line, State)
    end,
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID, FBMapId, Tx, Ty).

do_spring_quit({Unique, Module, Method, _DataIn, RoleID, PID, _Line,_})->
    case catch check_spring_quit(RoleID) of
        ok->
            change_skin(RoleID, get_fashion(RoleID)),
            do_spring_quit_2(RoleID);
        {error,ErrCode,Reason}->
            R2 = #m_spring_quit_toc{err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

check_spring_quit(_RoleID) ->
    ok.

do_spring_buy_buff({Unique, Module, Method, DataIn, RoleID, PID, _Line,_}) ->
    case catch check_spring_buy_buff(RoleID,DataIn) of
        {ok,BuffType,_OldBuffID,BuyBuffID,CostMoney,SpringRoleInfo}->
            case BuffType of
                ?BUY_BUFF_TYPE_PRESTIGE ->
                    set_spring_record({max_shengwang});
                ?BUY_BUFF_TYPE_EXP ->
                    set_spring_record({max_jingyan});
                _ ->
                    ?THROW_ERR("Error BuffType Value")
            end,
            TransFun = fun()-> 
                               {ok,RoleAttr} = t_deduct_buy_buff_money(CostMoney,RoleID),
                               {ok,RoleAttr}
                       end,
            case common_transaction:t( TransFun ) of
                {atomic, {ok,RoleAttr2}} ->
                    common_misc:send_role_gold_change(RoleID,RoleAttr2),
                    {NextBuffID,NextCostMoney} = next_can_buy_buff(RoleID,BuffType,{BuyBuffID,CostMoney}),
                    case BuffType of
                        ?BUY_BUFF_TYPE_PRESTIGE ->
                            set_spring_role_info(RoleID,SpringRoleInfo#r_spring_role_info{
                                                                                          buy_prestige_buff_id=BuyBuffID,                             
                                                                                          next_prestige_buff_id=NextBuffID,
                                                                                          next_prestige_buff_cost=NextCostMoney});
                        ?BUY_BUFF_TYPE_EXP ->
                            set_spring_role_info(RoleID,SpringRoleInfo#r_spring_role_info{
                                                                                          buy_exp_buff_id=BuyBuffID,    
                                                                                          next_exp_buff_id=NextBuffID,
                                                                                          next_exp_buff_cost=NextCostMoney})
                    end,
                    R2 = #m_spring_buy_buff_toc{type=BuffType,next_buff_id=NextBuffID,
                                                cost_money=NextCostMoney};
                {aborted, AbortErr} ->
                    {error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
                    R2 = #m_spring_buy_buff_toc{type=BuffType,err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_spring_buy_buff_toc{err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

%%扣除元宝
t_deduct_buy_buff_money(DeductMoney,RoleID)->
    case common_bag2:t_deduct_money(gold_unbind,DeductMoney,RoleID,?CONSUME_TYPE_GOLD_SPRING_REDUCE_COST) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error, Reason}->
            ?THROW_ERR_REASON( Reason );
        _ ->
            ?THROW_SYS_ERR()
    end. 

check_spring_buy_buff(RoleID,DataIn)->
    #m_spring_buy_buff_tos{type=BuffType} = DataIn,
    case is_in_spring_map() of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_SPRING_BUY_BUFF_NOT_IN_MAP )
    end,
    case get_spring_role_info(RoleID) of
        #r_spring_role_info{next_exp_buff_id=NextExpBuffID,next_exp_buff_cost=ExpCost,
                            buy_exp_buff_id=BuyExpBuffID,
                            next_prestige_buff_id=NextPrestigeBuffID,
                            next_prestige_buff_cost=PrestigeCose,
                            buy_prestige_buff_id=BuyPrestigeBuffID} = SpringRoleInfo ->
            case BuffType of
                ?BUY_BUFF_TYPE_PRESTIGE ->
                    case NextPrestigeBuffID of
                        ?LAST_PRESTIGE_BUFFID ->
                            ?THROW_ERR(?ERR_SPRING_BUY_BUFF_MAX);
                        _ ->
                            next
                    end,
                    NextBuffID=NextPrestigeBuffID,
                    OldBuffID = BuyPrestigeBuffID,
                    CostMoney=PrestigeCose;
                ?BUY_BUFF_TYPE_EXP ->
                    case NextExpBuffID of
                        ?LAST_EXP_BUFFID ->
                            ?THROW_ERR(?ERR_SPRING_BUY_BUFF_MAX);
                        _ ->
                            next
                    end,
                    NextBuffID=NextExpBuffID,
                    CostMoney=ExpCost,
                    OldBuffID = BuyExpBuffID
            end,
            next;
        _ ->
            NextBuffID = CostMoney = OldBuffID = SpringRoleInfo = null,
            ?THROW_SYS_ERR()
    end,
    {ok,BuffType,OldBuffID,NextBuffID,CostMoney,SpringRoleInfo}.

do_spring_quit_2(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{state=?ROLE_STATE_DEAD}->%%死亡状态
            mod_role2:do_relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, 
				RoleID, ?RELIVE_TYPE_ORIGINAL_FREE, mgeem_map:get_state());
        _ ->
            ignore
    end,
    common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SPRING,?SPRING_QUIT,#m_spring_quit_toc{}),
    {DestMapId,TX,TY} = get_spring_return_pos(RoleID),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY),
    ok.

set_map_enter_tag(RoleID,BattleMapName)->
    Val = {RoleID,BattleMapName},
    put({?SPRING_MAP_NAME_TO_ENTER,RoleID},Val).

set_spring_record(DataIn)->
    case get_spring_data_add() of
        undefined ->
            ?ERROR_MSG("spring_fb_have_no_value_error",[]);
        #r_spring_data_add{role_list=RoleList,max_feizao=MaxFeizao,max_xiangzao=MaxXiangzao,
                           max_huhuzao=MaxHuhuzao,max_shengwang=MaxShengwang,max_jingyan=MaxJingyan}=Data ->
            case DataIn of
                {max_feizao}->
                    NewMaxFeizao=MaxFeizao+1,
                    NewData=Data#r_spring_data_add{max_feizao=NewMaxFeizao},
                    set_spring_data_add(NewData);
                {max_xiangzao} ->
                    NewMaxXiangzao=MaxXiangzao+1,
                    NewData=Data#r_spring_data_add{max_xiangzao=NewMaxXiangzao},
                    set_spring_data_add(NewData);
                {max_huhuzao} ->
                    NewMaxHuhuzao=MaxHuhuzao+1,
                    NewData=Data#r_spring_data_add{max_huhuzao=NewMaxHuhuzao},
                    set_spring_data_add(NewData);
                {max_shengwang} ->
                    NewMaxShengwang=MaxShengwang+1,
                    NewData=Data#r_spring_data_add{max_shengwang=NewMaxShengwang},
                    set_spring_data_add(NewData);
                {max_jingyan} ->
                    NewMaxJingyan=MaxJingyan+1,
                    NewData=Data#r_spring_data_add{max_jingyan=NewMaxJingyan},
                    set_spring_data_add(NewData);
                {max_role_num, RoleID} ->
                    case lists:member(RoleID, RoleList) of
                        false->
                            NewRoleList=[RoleID|RoleList],
                            NewData=Data#r_spring_data_add{role_list=NewRoleList},
                            set_spring_data_add(NewData);
                        true->
                            next
                    end;
                
                _->
                    ?ERROR_MSG("unexpected record value",[])
            end;
        _ ->
            ?ERROR_MSG("spring_fb_value_is_not_illeger_error",[])
    end.

%%获取副本返回的位置
get_spring_return_pos(RoleID)->
    %%踢回京城
    common_map:get_map_return_pos_of_jingcheng(RoleID).

%%--------------------------------  温泉入口消息的代码，可复用  [start]--------------------------------
%%请求更新入口信息
req_spring_entrance_info()->
    send_map_msg({req_spring_entrance_info}).

do_req_spring_entrance_info()->
    case get_spring_map_info() of
        #r_spring_map_info{is_opening=IsOpening,cur_role_list=CurRoleList}->
            EntranceInfo = #r_spring_entrance_info{is_opening=IsOpening,map_role_num=erlang:length(CurRoleList)},
            
            init_spring_entrance_info(EntranceInfo),
            ok;
        _ ->
            ignore
    end.

%%同步更新入口信息
init_spring_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_spring_entrance_info)->
    [EntranceMapId] = ?find_config(entrance_map_id),
    SendInfo = {mod,?MODULE,{init_spring_entrance_info,EntranceInfo}},
  	case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
    	undefined->
        	ignore;
      	MapPID->
          	MapPID ! SendInfo
  	end.
    
do_init_spring_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_spring_entrance_info)->
    insert(?SPRING_ENTRANCE_INFO,EntranceInfo),
    ok.

%%--------------------------------  温泉入口消息的代码，可复用  [end]--------------------------------

%%--------------------------------  定时温泉的代码，可复用  [start]--------------------------------
is_opening() ->
    case get_spring_map_info() of
        #r_spring_map_info{is_opening=IsOpening}->
            IsOpening;
        _ ->
            false
    end.

%%@doc 重新设置下一次温泉时间
%%@return {ok,NextStartTimeSeconds}
reset_battle_open_times()->
    case common_fb:get_next_fb_open_time(?CONFIG_NAME) of
        {ok,Date,StartTimeSeconds,EndTimeSeconds,NextBcStartTime,NextBcEndTime,NextBcProcessTime,
         BeforeInterval,CloseInterval,ProcessInterval}->
            R1 = #r_spring_time{date = Date,
                                start_time = StartTimeSeconds,end_time = EndTimeSeconds,
                                next_bc_start_time = NextBcStartTime,
                                next_bc_end_time = NextBcEndTime,
                                next_bc_process_time = NextBcProcessTime,
                                before_interval = BeforeInterval,
                                close_interval = CloseInterval,
                                process_interval = ProcessInterval},
            set_spring_time_data(R1),
            {ok,StartTimeSeconds};
        {error,Reason}->
            {error,Reason}
    end.

%%--------------------------------  定时温泉的代码，可复用  [end]--------------------------------

%%--------------------------------  温泉广播的代码，可复用  [start]--------------------------------
%% 副本开起提前广播开始消息
%% Record 结构为 r_spring_time
%% 返回 new r_spring_time
do_fb_open_before_broadcast(NowSeconds,Record) ->
    #r_spring_time{
                             start_time = StartTime,
                             end_time = EndTime,
                             next_bc_start_time = NextBCStartTime,
                             before_interval = BeforeInterval} = Record,
    if StartTime =/= 0 
       andalso EndTime =/= 0 
       andalso NextBCStartTime =/= 0
       andalso NowSeconds >= NextBCStartTime 
       andalso NowSeconds < StartTime->
            %% 副本开起提前广播开始消息
           BeforeMessage = 
               case StartTime>NowSeconds of
                   true->
                       {_Date,Time} = common_tool:seconds_to_datetime(StartTime),
                       StartTimeStr = common_time:time_string(Time),
                       common_misc:format_lang(?_LANG_SPRING_PRESTART,[StartTimeStr]);
                   _ ->
                       ?_LANG_SPRING_STARTED
               end,
           ?WORLD_CHAT_BROADCAST(BeforeMessage),
           ?WORLD_CENTER_BROADCAST(BeforeMessage),
           set_spring_time_data( Record#r_spring_time{next_bc_start_time = NowSeconds + BeforeInterval} );
       true ->
           Record
    end.

%% 副本开启过程中广播处理
%% Record 结构为 r_spring_time
%% 返回
do_fb_open_process_broadcast(NowSeconds,Record) ->
    #r_spring_time{
                              start_time = StartTime,
                              end_time = EndTime,
                              next_bc_process_time = NextBCProcessTime,
                              process_interval = ProcessInterval} = Record,
    if 
        StartTime =/= 0 andalso EndTime =/= 0 
       andalso NowSeconds >= StartTime andalso EndTime >= NowSeconds 
       andalso NextBCProcessTime =/= 0
       andalso NowSeconds >= NextBCProcessTime ->
            %% 副本开起过程中广播时间到
            ?WORLD_CHAT_BROADCAST(?_LANG_SPRING_STARTED),
            set_spring_time_data( Record#r_spring_time{next_bc_process_time = NowSeconds + ProcessInterval} );
       true ->
            ignore
    end.

%%副本关闭的广播
do_fb_close_broadcast(NextStartTime)->
    EndMessageF = 
        if NextStartTime > 0 ->
               ?_LANG_SPRING_CLOSED_TIME;
           true ->
               ?_LANG_SPRING_CLOSED_FINAL
        end,
    ?WORLD_CHAT_BROADCAST(EndMessageF),
    ?WORLD_CENTER_BROADCAST(EndMessageF).

%%--------------------------------  温泉广播的代码，可复用  [end]--------------------------------

%%--------------------------------  加经验的代码，可复用  [start]--------------------------------
%% @doc 获取每次间隔加的经验
%% @doc 获取每次间隔加的经验
get_add_exp_prestige(Level) ->
    case ?find_config({fb_add_exp_prestige, Level}) of
        [] -> {100,1};
        [{Exp,Prestige}] -> {Exp,Prestige}
    end.

get_add_addition_exp_prestige(RoleID,{ExpAdd,Prestige}) ->
    #r_spring_role_info{buy_exp_buff_id=ExpBuffID,
                        buy_prestige_buff_id=PrestigeBuffID} = get_spring_role_info(RoleID),
    [ExpAddition] = ?find_config(fb_exp_addition),
    [PrestigeAddition] = ?find_config(fb_prestige_addition),
    case lists:keyfind(ExpBuffID, 1, ExpAddition) of
        false ->
            ExpAdd2 = ExpAdd;
        {_,Mult1} ->
            ExpAdd2 = ExpAdd*Mult1
    end,
    case lists:keyfind(PrestigeBuffID, 1, PrestigeAddition) of
        false ->
            Prestige2 = Prestige;
        {_,Mult2} ->
            Prestige2 = Prestige*Mult2
    end,
    {ExpAdd2,Prestige2}.


do_add_exp_interval(Now) ->
    RoleIDList = get_interval_exp_list(Now),
    case get_spring_map_info() of
        #r_spring_map_info{} ->
            lists:foreach(
              fun(RoleID) ->
                      case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                          undefined ->
                              delete_interval_exp_list(RoleID);
                          #p_map_role{level=Level} ->
                               {ExpAdd,Prestige} = get_add_exp_prestige(Level),
                               {ExpAdd2,Prestige2} = get_add_addition_exp_prestige(RoleID,{ExpAdd,Prestige}),
                              mod_map_role:do_add_exp(RoleID,common_tool:ceil(ExpAdd2)),
                               ?TRY_CATCH(mod_prestige:do_add_prestige(RoleID, Prestige2,?GAIN_TYPE_PRESTIGE_SPRING),Err1)
                      end
              end, RoleIDList);
        _ ->
            nil
    end.

%% @doc 插入加经验列表
insert_interval_exp_list(RoleID) ->
    List = get_interval_exp_list(RoleID),
    set_interval_exp_list(RoleID, [RoleID|lists:delete(RoleID, List)]).

delete_interval_exp_list(RoleID) ->
    List = get_interval_exp_list(RoleID),
    set_interval_exp_list(RoleID, lists:delete(RoleID, List)).

get_interval_exp_list(RoleID) ->
    [{_,ExpAddInterval}] = ?find_config(fb_add_exp),
    Key = RoleID rem ExpAddInterval,
    case get({?INTERVAL_EXP_LIST, Key}) of
        undefined ->
            put({?INTERVAL_EXP_LIST, Key}, []),
            [];
        List ->
            List
    end.

set_interval_exp_list(RoleID, List) ->
    [{_,ExpAddInterval}] = ?find_config(fb_add_exp),
    Key = RoleID rem ExpAddInterval,
    put({?INTERVAL_EXP_LIST, Key}, List).
    
%%--------------------------------  加经验的代码，可复用 [end] --------------------------------

%%--------------------------------  温泉开/关的代码，可复用 [start] --------------------------------
%%GM的方便命令
%% gm_open_spring(SecTime)->
%%     send_map_msg( {gm_open_battle, SecTime} ).
gm_close_spring()->
    send_map_msg( {gm_close_battle} ).
gm_reset_open_times()->
    send_map_msg( {gm_reset_open_times } ).

send_map_msg(Msg)->
    case global:whereis_name( common_map:get_common_map_name(?SPRING_MAP_ID) ) of
        undefined->
            ignore;
        MapPID->
            erlang:send(MapPID,{mod,?MODULE,Msg})
    end.

%%GM开启副本
gm_open_spring(Second)->
    %%GM命令，手动开启
    TimeData = case get_spring_time_data() of
		undefined ->
			#r_spring_time{};
		T ->
			T
	end,
    StartTime2 = common_tool:now(),
    EndTime2 = StartTime2 + ?GM_SPRING_OPEN_LAST_TIME,
    TimeData2 = TimeData#r_spring_time{date=date(),start_time=StartTime2 + Second, end_time=EndTime2,next_bc_process_time=StartTime2},
    set_spring_time_data(TimeData2).

%%开启副本
open_spring()->  
    set_spring_map_info(#r_spring_map_info{is_opening=true}),
    EntranceInfo = #r_spring_entrance_info{is_opening=true}, 
    init_spring_entrance_info(EntranceInfo),
    ok.


%%关闭副本
close_spring()->
    SpringMapInfo = get_spring_map_info(),
    set_spring_map_info(SpringMapInfo#r_spring_map_info{is_opening=false}),
    
    EntranceInfo = #r_spring_entrance_info{is_opening=false},
    init_spring_entrance_info(EntranceInfo),
    ?TRY_CATCH(do_spring_fb_log()),
    kick_all_roles(),
    {ok,NextStartTimeSeconds} = reset_battle_open_times(),
    do_fb_close_broadcast(NextStartTimeSeconds),
    ok.

%%--------------------------------  温泉开/关的代码，可复用 [end] --------------------------------
do_spring_fb_log()->
    #r_spring_data_add{role_list=RoleList,max_feizao=MaxFeizao,max_xiangzao=MaxXiangzao,
            max_huhuzao=MaxHuhuzao,max_shengwang=MaxShengwang,max_jingyan=MaxJingyan}=get_spring_data_add(),
    MaxRoleNum=length(RoleList),
    case get_spring_time_data() of
        #r_spring_time{start_time = StartTime,end_time = EndTime}->
            SpringFbLog=#r_spring_fb_log{start_time=StartTime,
                                         end_time=EndTime,
                                         max_feizao=MaxFeizao,
                                         max_xiangzao=MaxXiangzao,
                                         max_huhuzao=MaxHuhuzao,
                                         max_shengwang=MaxShengwang,
                                         max_jingyan=MaxJingyan,
                                         max_role_num=MaxRoleNum},
            erase_spring_data_add(),
            common_general_log_server:log_spring_fb(SpringFbLog); 
        _ ->
            ignore
    end.

kick_all_roles() ->
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(fun(RoleID) ->
                          change_skin(RoleID,get_fashion(RoleID)),
                          {DestMapId,TX,TY} = get_spring_return_pos(RoleID),
                            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SPRING, ?SPRING_QUIT, #m_spring_quit_toc{}),
                          mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY)
                  end, RoleIdList),
    erase_spring_role_info().
