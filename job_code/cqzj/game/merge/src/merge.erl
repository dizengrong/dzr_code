%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 17 Jul 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(merge).

-include("merge.hrl").
-include("common.hrl").
-include("office.hrl").
-include("role_tables.hrl").

%% API
-export([
         start/0,
		 set_vip_title/2
        ]).

-record(r_role_name_tmp, {role_name, role_id_list=[]}).
-define(DB_ROLE_NAME_TMP, db_role_name_tmp).
-record(r_account_name_tmp, {account_name, role_id_list=[]}).
-record(r_family_name_tmp, {family_name, family_id_list=[]}).
-define(DB_ACCOUNT_NAME_TMP, db_account_name_tmp).
-define(DB_FAMILY_NAME_TMP, db_family_name_tmp).
-define(DEF_RAM_TABLE(Type,Rec),
        [{ram_copies, [node()]},
         {type, Type},
         {record_name, Rec},
         {attributes, record_info(fields, Rec)}
        ]).

%%%===================================================================
%%% API
%%%===================================================================
start() ->
	init(),
	do_start_merge(),
	end_process(),
	ok.

init() ->
    %% 启动日志服务器
    do_start_log_server(),
    global:register_name(merge_master, erlang:self()),
    common_loglevel:set(3),
    common_config_dyn:init(merge),
    ?LOG("~ts~n", ["主节点：读取配置文件成功，准备启动mnesia"]),
    start_mnesia(),   
    [ServerIDList] = common_config_dyn:find(merge, server_id_list),
    ?LOG("~ts:~w~n", ["主节点mnesia启动成功，准备启动合服子程序，本次参与合服的区包括", ServerIDList]),
    lists:foreach(
      fun(ServerID) ->
              erlang:spawn_link(fun() -> start_slave(ServerID) end),
              receive
                  {node_up, Node} ->
                      net_kernel:connect_node(Node),
                      mnesia:change_config(extra_db_nodes, [Node]),
                      global:send(make_global_name(ServerID), start_preprocess_data),
                      receive 
                          {prepare_ok, ServerID} ->
                              ?LOG("~ts:~p~n", ["区服数据处理完毕", ServerID])
                      end;
                  {no_merge_type_config, ServerID} ->
                      ?LOG("~ts:~p~n", ["配置出错，合服程序结束", ServerID]),
                      timer:sleep(200),
                      init:stop()
              end
      end, ServerIDList).


%% 开始合并数据
do_start_merge() ->
    %% 分析配置文件
    [ServerIDList] = common_config_dyn:find(merge, server_id_list),
    [MergeType] = common_config_dyn:find(merge, merge_type),
    case erlang:length(ServerIDList) =:= erlang:length(MergeType) of
        true ->
            ok;
        false ->
            ?LOG("~ts", ["严重问题，服务器列表和合服类型配置数据不统计，请检查！"]),
            timer:sleep(200),
            init:stop()
    end,
    global:sync(),
    %% 遍历角色表，并重命名角色名
    ?LOG("~ts~n", ["准备处理角色重名"]),
    do_process_role_name(ServerIDList),
    %% 遍历宗族名表，并重命名
    ?LOG("~ts~n", ["角色重名处理完毕，准备处理宗族重名"]),
    do_process_family_name(ServerIDList),
    %% 遍历账号表，并重新绑定账号
    ?LOG("~ts~n", ["宗族重名处理完毕，准备处理账号绑定问题"]),
    do_process_account_name(ServerIDList),
    ?LOG("~ts~n", ["账号处理完毕，准备 合并数据"]),
    %% 开始遍历各种数据并插入到最终数据表中
    do_init_data(),
    do_merge_data(ServerIDList),
    %% 删除所有临时表
    do_remove_all_tmp_table(ServerIDList),
    ?LOG("~ts~n", ["准备重新计算国家角色数据"]),
    do_reset_faction_role_num(),
    do_process_office_id(),
    update_vip_chat_title(),
    update_family_title(),
	update_jingjie_juewei_title(),
	%% 重算百强榜
	common_shell:reset_role_jingjie_rank(_IsMerge=true),
	?LOG("~ts~n", ["合并数据处理完毕，准备删除所有临时表"]),
    ok.
                 
update_vip_chat_title() ->	
    VipList = db:dirty_match_object(?DB_ROLE_VIP_P, #r_role_vip{_='_'}),
    lists:foreach(fun(#r_role_vip{role_id=RoleID,vip_level=Level}) ->
                          #r_vip_level_info{title_name=TitleName, color=Color} = get_vip_level_info(Level),
                          set_vip_title(RoleID, {TitleName, Color})
                  end,  VipList),
    ok.


update_family_title() ->
    FamilyList = db:dirty_match_object(?DB_FAMILY, #p_family_info{_='_'}),
    lists:foreach(fun(#p_family_info{members=Members}) ->
                          lists:foreach(fun(#p_family_member_info{role_id=RoleID,title=TitleName}) ->
                                                set_family_title(RoleID, TitleName)
                                        end, Members)
                  end, FamilyList),
    ok.

update_jingjie_juewei_title() ->
	AllRoleList = db:dirty_match_object(?DB_ROLE_ATTR_P, #p_role_attr{_='_'}),
	lists:foreach(fun(#p_role_attr{role_id=RoleID,jingjie=Jingjie,juewei=Juewei}) ->
						  add_jingjie_title(RoleID,Jingjie),
						  add_juewei_title(RoleID,Juewei)
				  end,AllRoleList).

add_juewei_title(RoleID,Juewei) ->
	case cfg_title:juewei_title(Juewei) of
		false->
			nil;
		Title->
			TitleID = get_new_titleid(),
			R = #p_title{id=TitleID, 
						 name=Title#r_juewei_title.title_name, 
						 color=Title#r_juewei_title.title_color, 
						 type=?TITLE_ROLE_JUEWEI, 
						 auto_timeout=false, 
						 timeout_time=0, 
						 role_id=RoleID, 
						 show_in_chat=Title#r_juewei_title.is_show_in_chat, 
						 show_in_sence=Title#r_juewei_title.is_show_in_sence},
			db:dirty_write(?DB_NORMAL_TITLE_P, R)
	end.

add_jingjie_title(_RoleID,_Jingjie) ->
	nil.

get_new_titleid() ->    
    Fun = fun() ->
                  case db:read(?DB_TITLE_COUNTER_P, 1, write) of
                      [] ->
                          Record = #r_title_counter{id = 1,last_title_id = 100000},
                          db:write(?DB_TITLE_COUNTER_P, Record, write),
                          100000;
                      [Record] ->
                          #r_title_counter{last_title_id = LastID} = Record,
                          NewRecord = Record#r_title_counter{last_title_id = LastID+1},
                          db:write(?DB_TITLE_COUNTER_P, NewRecord, write),
                          LastID+1
                  end
          end,
    {atomic,MaxID2} = db:transaction(Fun),
    MaxID2.

set_vip_title(RoleID, {TitleName, Color}) ->
    case db:dirty_match_object(?DB_NORMAL_TITLE_P, #p_title{type=?TITLE_VIP, role_id=RoleID, _='_'}) of
        [] ->
            TitleID = get_new_titleid(),
            if TitleName =:= "" ->
                    R = #p_title{id=TitleID, name=TitleName, type=?TITLE_VIP, auto_timeout=false, 
                                 role_id=RoleID, show_in_chat=true, show_in_sence=false, color=Color};
               true ->
                    R = #p_title{id=TitleID, name=TitleName, type=?TITLE_VIP, auto_timeout=false, 
                                 role_id=RoleID, show_in_chat=true, show_in_sence=true, color=Color}
            end;
        [TitleInfo] ->
            if TitleName =:= "" ->
                    R = TitleInfo#p_title{name=TitleName, show_in_chat=true, color=Color};
               true ->
                    R = TitleInfo#p_title{name=TitleName, show_in_chat=true, show_in_sence=true, color=Color}
            end
    end,
    db:dirty_write(?DB_NORMAL_TITLE_P, R),
    ok.

set_family_title(RoleID, TitleName) ->
    case db:dirty_match_object(?DB_NORMAL_TITLE_P,#p_title{type=?TITLE_FAMILY,role_id=RoleID,_='_'}) of
        [] ->
            TitleID = get_new_titleid(),
            R = #p_title{id=TitleID, name=TitleName, type=?TITLE_FAMILY, auto_timeout=false, 
                         role_id=RoleID, show_in_chat=false, show_in_sence=true,color="00ffff"};
        [TitleInfo] ->
            R = TitleInfo#p_title{name=TitleName, color="00ffff"}
    end,
    db:dirty_write(?DB_NORMAL_TITLE_P, R),
    ok.
%% @doc 获取VIP等级信息
get_vip_level_info(VipLevel) ->
	case common_config_dyn:find(vip, {vip_level_info, VipLevel}) of
		[] -> undefined;
		[LevelInfo] -> LevelInfo
	end.

do_process_office_id() ->
    lists:foreach(
      fun(#p_role_attr{office_id=OfficeID} = RoleAttr) ->
              case OfficeID > 0 of
                  true ->
                      EquipIdList = [32110101,32110102,32110103,32110104],
                      case RoleAttr#p_role_attr.equips of
                          EquipList when is_list(EquipList)	->
                              NewEquipList = 
                                  lists:foldl(fun(EquipId,Acc)	->
                                                      lists:keydelete(EquipId, #p_goods.typeid, Acc)
                                              end, EquipList, EquipIdList),                              
                              db:dirty_write(?DB_ROLE_ATTR_P, RoleAttr#p_role_attr{equips = NewEquipList, office_id=0, office_name=""});
                          _  ->
                              db:dirty_write(?DB_ROLE_ATTR_P, RoleAttr#p_role_attr{office_id=0, office_name=""})
                      end;
                  false ->
                      ignore
              end
      end, db:dirty_match_object(?DB_ROLE_ATTR_P, #p_role_attr{_='_'})).


do_init_data() ->
    mnesia:dirty_write(?DB_ROLEID_COUNTER_P, #r_roleid_counter{id=1, last_role_id=1}),
    mnesia:dirty_write(?DB_FAMILY_COUNTER_P, #r_family_counter{id=1, value=1}),
    mnesia:dirty_write(?DB_PAY_LOG_INDEX_P, #r_pay_log_index{id=1, value=1}),
    ok.

%% 合区子程序的入口
start_slave(ServerID) ->
    try
		start_slave2(ServerID)
    catch E:E2 ->
            ?LOG("~ts:~p ~p ~p~n", ["发生系统错误", E, E2, erlang:get_stacktrace()])
    end.

end_process() ->
	?LOG("~ts~n", ["合服完毕，恭喜！"]),
	mnesia:dump_log(),
    mnesia:stop(),
	init:stop(),
	ok.

start_slave2(ServerID) ->
    GlobalRegName = make_global_name(ServerID),
    start_mnesia_slave(), 
    net_kernel:connect(common_tool:list_to_atom(lists:concat(["merge_master@127.0.0.1"]))),        
    global:sync(),
    ?LOG("~ts:~p ~ts~n", ["合区子程序", ServerID, "正在启动中"]),
    global:register_name(GlobalRegName, erlang:self()),
    global:send(merge_master, {node_up, node()}),
    %% 等待主节点相应
    receive 
        start_preprocess_data ->
            global:sync(),
            ?LOG("~ts:~p~n", ["合区子程序正在准备处理数据", ServerID]),
            start_slave3(ServerID)
    end.

start_slave3(ServerID) ->
    common_loglevel:set(3),
    common_config_dyn:init(merge),
    ?LOG("~ts:~p~n", ["读取配置文件成功", ServerID]),   
    TabRoleBaseRenamed = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID),
    case mnesia:table_info(TabRoleBaseRenamed, size) > 0 of
        true ->
            ?LOG("~ts:~p~n", ["已有数据无需恢复，准备删除死号", ServerID]);
        false ->
            ?LOG("~ts:~p~n", ["创建数据库表成功，准备开始恢复对应区服数据", ServerID]),
            restore_data(ServerID),
            ?LOG("~ts:~p~n", ["还原数据成功，准备删除死号", ServerID])
    end,
    [IfDelRole] = common_config_dyn:find(merge, del_role),
    case IfDelRole of
        true ->
            common_del_role_info:do(),
            ?LOG("~ts:~p~n", ["删除死号成功", ServerID]);
        false ->
            ?LOG("~ts:~p~n", ["根据配置，不用删除死号", ServerID]),
            ignore
    end,

    rename_table(ServerID),
    ?LOG("~ts:~p~n", ["建立临时数据库表成功", ServerID]),
    copy_data(ServerID),
    ?LOG("~ts:~p~n", ["拷贝数据成功", ServerID]),
    remove_restore_data(),    
    ?LOG("~ts:~p~n", ["删除原有数据", ServerID]),
    [MergeTypeConfig] = common_config_dyn:find(merge, merge_type),
    case lists:keyfind(ServerID, 1, MergeTypeConfig) of
        false ->
            ?LOG("~ts:~p~n", ["严重问题，找不到区服的合服配置", ServerID]),
            global:send(merge_master, {no_merge_type_config, ServerID}),
            timer:sleep(1000),
            init:stop();
        {ServerID, FactionID} ->
            case FactionID > 0 of
                true ->
                    ?LOG("~ts:~p ~ts ~p~n", ["准备将区服", ServerID, "的所有国家置为", FactionID]),
                    reset_all_faction_id(ServerID, FactionID);
                false ->
                    ignore
            end
    end,
    ?LOG("~ts:~p~n", ["准备工作好好，等待下一步指令", ServerID]),
    %% 每个区服恢复数据后就开始等待
    global:send(merge_master, {prepare_ok, ServerID}),
    do_waiting(ServerID).

do_waiting(ServerID) ->
    receive 
        R ->
            ?LOG("~ts:~p~n", ["收到未知消息", R]),
            do_waiting(ServerID)
    end.

%% 重置被区服的所有的国家ID
reset_all_faction_id(ServerID, FactionID) ->
    %% 处理角色base
    TabRoleBaseRenamed = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID),
    lists:foreach(
      fun(R) ->
              mnesia:dirty_write(TabRoleBaseRenamed, R#p_role_base{faction_id=FactionID})
      end, mnesia:dirty_match_object(TabRoleBaseRenamed, #p_role_base{_='_'})),
    %% 处理宗族
    TabFamilyRenamed = get_renamed_table_name(?DB_FAMILY_P, ServerID),
    lists:foreach(
      fun(R) ->
              mnesia:dirty_write(TabFamilyRenamed, R#p_family_info{faction_id=FactionID})
      end, mnesia:dirty_match_object(TabFamilyRenamed, #p_family_info{_='_'})),
    %% 处理竞技场
    TabArenaRenamed = get_renamed_table_name(?DB_ROLE_ARENA_P, ServerID),
    lists:foreach(
      fun(R) ->
              mnesia:dirty_write(TabArenaRenamed, R#r_role_arena{faction_id=FactionID})
      end, mnesia:dirty_match_object(TabArenaRenamed, #r_role_arena{_='_'})),
    %%　处理场景大战副本
    TabSceneRenamed = get_renamed_table_name(?DB_SCENE_WAR_FB_P, ServerID),
    lists:foreach(
      fun(R) ->
              mnesia:dirty_write(TabSceneRenamed, R#r_scene_war_fb{faction_id=FactionID})
      end, mnesia:dirty_match_object(TabSceneRenamed, #r_scene_war_fb{_='_'})),
    %% 处理开箱子
    TabBoxRenamed = get_renamed_table_name(?DB_ROLE_BOX_P, ServerID),
    lists:foreach(
      fun(R) ->
              mnesia:dirty_write(TabBoxRenamed, R#r_role_box{faction_id=FactionID})
      end, mnesia:dirty_match_object(TabBoxRenamed, #r_role_box{_='_'})),
    ok.


do_merge_data(ServerIDList) ->
    lists:foreach(
      fun(ServerID) ->
              ?LOG("~ts:~p~n", ["合并区服数据", ServerID]),
              %% 有些表的数据只跟账号有关，直接合并就可以了
              lists:foreach(
                fun(R) ->
                        mnesia:dirty_write(?DB_ACCOUNT_P, R)
                end, mnesia:dirty_match_object(get_renamed_table_name(?DB_ACCOUNT_P, ServerID), #r_account{_='_'})),               
              lists:foreach(
                fun(R) ->
                        mnesia:dirty_write(?DB_FCM_DATA_P, R)
                end, mnesia:dirty_match_object(get_renamed_table_name(?DB_FCM_DATA_P, ServerID), #r_fcm_data{_='_'})),
              ?LOG("~ts:~p~n",  ["开始重置角色ID", ServerID]),
              do_reset_role_id(ServerID),
              ?LOG("~ts:~p~n",  ["开始重置宗族ID", ServerID]),
              do_reset_family_id(ServerID),
              ok
      end, ServerIDList),
    ?LOG("~ts~n", ["开始合并异兽数据"]),
    do_merge_pet_data(ServerIDList),
    ?LOG("~ts~n", ["开始合并势力数据"]),
    do_merge_faction_data(ServerIDList),
    ?LOG("~ts~n", ["开始更新玩家身上装备"]),
    do_update_role_attr(),
    ?LOG("~ts~n", ["开始合并充值记录"]),
    do_merge_pay_log(ServerIDList),
%%     ?LOG("~ts~n", ["开始合并信件"]),
%%     do_merge_letter(ServerIDList),
    ?LOG("~ts:~n", ["重置角色ID --- 更新角色背包信息"]),
    do_update_role_bag_info_when_reset_role_id(ServerIDList),
    ?LOG("~ts:~n", ["重置角色ID --- 更新摆摊信息"]),
    do_update_stall_info_when_reset_role_id(ServerIDList),
    ok.

get_new_pay_log_id() ->
    [#r_pay_log_index{value=Value}] = mnesia:dirty_read(?DB_PAY_LOG_INDEX_P, 1),
    mnesia:dirty_write(?DB_PAY_LOG_INDEX_P, #r_pay_log_index{id=1, value=Value+1}),
    Value+1.

-define(PERSONAL_LETTER_COUNTER_KEY,personal_letter_counter_key).

%% get_new_letter_id() ->
%%     Key = ?PERSONAL_LETTER_COUNTER_KEY,
%%     Count = case mnesia:dirty_read(?DB_WORLD_COUNTER_P, Key) of
%%                 [Info] when is_record(Info, r_world_counter) ->
%%                     Info#r_world_counter.value;
%%                 _ ->
%%                     1
%%             end,
%%     mnesia:dirty_write(?DB_WORLD_COUNTER_P, #r_world_counter{key=Key, value=Count+1}),
%%     Count.
%% 
%% do_merge_letter(ServerIDList) ->
%%     lists:foreach(
%%       fun(ServerID) ->
%%               TabLetterRenamed = get_renamed_table_name(?DB_PERSONAL_LETTER_P, ServerID),
%%               lists:foreach(
%%                 fun(R) ->
%%                         NewLetterID = get_new_letter_id(),
%%                         mnesia:dirty_write(?DB_PERSONAL_LETTER_P, R#r_personal_letter{id=NewLetterID})
%%                 end, mnesia:dirty_match_object(TabLetterRenamed, #r_personal_letter{_='_'}))
%%       end, ServerIDList),
%%     ok.      

do_merge_pay_log(ServerIDList) ->
    lists:foreach(
      fun(ServerID) ->
              TabPayLogRenamed = get_renamed_table_name(?DB_PAY_LOG_P, ServerID),              
              lists:foreach(
                fun(PayLog) ->
                        NewID = get_new_pay_log_id(),
                        mnesia:dirty_write(?DB_PAY_LOG_P, PayLog#r_pay_log{id=NewID})
                end, mnesia:dirty_match_object(TabPayLogRenamed, #r_pay_log{_='_'}))
      end, ServerIDList),
    ok.    

do_update_role_attr() ->
    lists:foreach(
      fun(#p_role_attr{equips=Equips, role_id=RoleID} = R) ->
              NewEquips = lists:foldl(
                            fun(Goods, Acc) ->
                                    [Goods#p_goods{roleid=RoleID} | Acc]
                            end, [], Equips),
              mnesia:dirty_write(?DB_ROLE_ATTR_P, R#p_role_attr{equips=NewEquips})
      end, mnesia:dirty_match_object(?DB_ROLE_ATTR_P, #p_role_attr{_='_'})),
    ok.


get_new_pet_id() ->
    new_id(pet).

new_id(Key) ->
    case mnesia:dirty_read(?DB_COUNTER_P,Key) of
        [] ->
            mnesia:dirty_write(?DB_COUNTER_P, #r_counter{key=Key,value=1}),
            1;
        [Info] ->
            ID = Info#r_counter.value,
            mnesia:dirty_write(?DB_COUNTER_P,Info#r_counter{value=ID+1}),
            ID + 1
    end.

do_merge_pet_data(ServerIDList) ->
    lists:foreach(
      fun(ServerID) ->
              EtsName = common_tool:list_to_atom(lists:concat(["pet_id_", ServerID])),
              ets:new(EtsName, [public, set, named_table]),
              TabPetRenamed = get_renamed_table_name(?DB_PET_P, ServerID),
              lists:foreach(
                fun(#p_pet{pet_id=PetID} = R) ->
                        NewPetID = get_new_pet_id(),
                        ets:insert(EtsName, {PetID, NewPetID}),
                        mnesia:dirty_write(?DB_PET_P, R#p_pet{pet_id=NewPetID})
                end, mnesia:dirty_match_object(TabPetRenamed, #p_pet{_='_'}))
      end, ServerIDList),
    %% 处理玩家异兽列表    
    lists:foreach(
      fun(ServerID) ->
              EtsName = common_tool:list_to_atom(lists:concat(["pet_id_", ServerID])),
              TabPetBagRenamed = get_renamed_table_name(?DB_ROLE_PET_BAG_P, ServerID),
              lists:foreach(
                fun(#p_role_pet_bag{pets=Pets} = R) ->
                        NewPets = lists:foldl(
                                    fun(#p_pet_id_name{pet_id=PetID} = R2, Acc) ->
                                            case ets:lookup(EtsName, PetID) of
                                                [] ->
                                                    Acc;
                                                [{PetID, NewPetID}] ->
                                                    [R2#p_pet_id_name{pet_id=NewPetID} | Acc]
                                            end
                                    end, [], Pets),
                        mnesia:dirty_write(?DB_ROLE_PET_BAG_P, R#p_role_pet_bag{pets=NewPets})
                end, mnesia:dirty_match_object(TabPetBagRenamed, #p_role_pet_bag{_='_'}))
      end, ServerIDList), 
	
	%% 处理玩家训练列表(只保留训练槽个数)
	lists:foreach(
	  fun(ServerID) ->
			  TabPetTrainingRenamed = get_renamed_table_name(?DB_PET_TRAINING_P, ServerID),
			  lists:foreach(
				fun(R) ->
						mnesia:dirty_write(?DB_PET_TRAINING_P, R)
				end, mnesia:dirty_match_object(TabPetTrainingRenamed, #r_pet_training{_='_'}))
	  end, ServerIDList), 
	
    ok.              

do_merge_faction_data(ServerIDList) ->  
    lists:foreach(
      fun(ServerID) ->
              TabBankRenamed = get_renamed_table_name(?DB_FACTION_INFO_P, ServerID),
              lists:foreach(
                fun(R) ->
                        #r_faction_info{faction_id=FactionId,juewei_level=CurLv} = R,
                        case mnesia:dirty_read(?DB_FACTION_INFO_P,FactionId) of
                            [#r_faction_info{juewei_level=OldLevel}] when OldLevel>CurLv->
                                ignore;
                            _ ->
                                mnesia:dirty_write(?DB_FACTION_INFO_P,R)
                        end
                end, mnesia:dirty_match_object(TabBankRenamed, #r_faction_info{_='_'}))
      end, ServerIDList),
    ok.

do_reset_faction_role_num() ->
    lists:foreach(
      fun(FactionID) ->
              Num = erlang:length(mnesia:dirty_match_object(?DB_ROLE_BASE_P, #p_role_base{faction_id=FactionID, _='_'})),
              mnesia:dirty_write(?DB_ROLE_FACTION_P, #r_role_faction{faction_id=FactionID, number=Num})
      end, [1,2,3]),    
    ok.

%% 坑爹的名字，重排角色ID时所有以role_id为主键的信息都需要删除并重插记录
do_update_info_case_role_id_is_key_when_reset_role_id(ServerID, RoleID, NewRoleID) ->
    SetTables = ?ROLE_TABLES_COMMON ++ ?ROLE_TABLES_MERGE,
    lists:foreach(
      fun(Tab) ->
              RenamedTable = get_renamed_table_name(Tab, ServerID),
              case mnesia:dirty_read(RenamedTable, RoleID) of
                  [] ->
                      ignore;
                  [R] ->
                      mnesia:dirty_delete_object(RenamedTable, R),
                      NewR = erlang:setelement(2, R, NewRoleID),
                      mnesia:dirty_write(Tab, NewR)
              end
      end, SetTables),
    ok.

%% 重排角色id时需要更新好友相关信息
do_update_friend_info_when_reset_role_id(ServerID) ->
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
	TabFriendRenamed = get_renamed_table_name(?DB_FRIEND_P, ServerID),
	lists:foreach(
	  fun(#r_friend{roleid=RoleID,friendid=FriendID}=R) ->
			  case ets:lookup(EtsTabName, RoleID) of
				  [] ->
					  ignore;
				  [{RoleID, NewRoleID}] ->
					  case ets:lookup(EtsTabName, FriendID) of
						  [] ->
							  ignore;
						  [{FriendID, NewFriendID}] ->
							  mnesia:dirty_write(?DB_FRIEND_P, R#r_friend{roleid=NewRoleID,friendid=NewFriendID})
					  end
			  end
	  end,mnesia:dirty_match_object(TabFriendRenamed, #r_friend{_='_'})),
	ok.


update_family_info_when_reset_role_id(ServerID) ->
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    TabFamilyRenamed = get_renamed_table_name(?DB_FAMILY_P, ServerID),
    lists:foreach(
      fun(FamilyInfo) ->
              #p_family_info{create_role_id=CreateRoleID, owner_role_id=OwnerRoleID, owner_role_name=OwnerRoleName,
                             create_role_name=CreateRoleName,
                             second_owners=SecondOwners, members=Members} = FamilyInfo,
              NewSecondOwners = lists:foldl(
                                  fun(#p_family_second_owner{role_id=SecondOwnerRoleID} = SecondOwner, Acc) ->
                                          case ets:lookup(EtsTabName, SecondOwnerRoleID) of
                                              [] ->
                                                  Acc;                                              
                                              [{SecondOwnerRoleID, NewSecondOwnerRoleID}] ->
                                                  [SecondOwner#p_family_second_owner{role_id=NewSecondOwnerRoleID} | Acc]
                                          end
                                  end, [], SecondOwners),
              NewMembers = lists:foldl(
                             fun(#p_family_member_info{role_id=MemberRoleID} = Member, Acc) ->
                                     case ets:lookup(EtsTabName, MemberRoleID) of
                                         [] ->
                                             Acc;
                                         [{MemberRoleID, NewMemberRoleID}] ->
                                             [Member#p_family_member_info{role_id=NewMemberRoleID} | Acc]
                                     end
                             end, [], Members),

              case ets:lookup(EtsTabName, OwnerRoleID) of
                  [] ->    
                      %% 这种情况下随机找个玩家来当族长
                      case erlang:length(NewMembers) > 1 of
                          true ->
                              %% 优先转让给副族长
                              case erlang:length(NewSecondOwners) > 0 of
                                  true ->                                            
                                      [#p_family_second_owner{role_id=SID, role_name=SName} | NewSecondOwners2] = SecondOwners,
									  case lists:keyfind(SID, #p_family_member_info.role_id, NewMembers) of
										  false ->
											  case mnesia:dirty_read(?DB_ROLE_BASE_P, SID) of
												  [] ->
													  ?LOG("副族长居然给删号了:~w",[SName]),
													  NewMembers2 = NewMembers;
												  [#p_role_base{sex=Sex}] ->
													  case mnesia:dirty_read(?DB_ROLE_ATTR_P, SID) of
														  [] ->
															  ?LOG("副族长居然给删号了:~w",[SName]),
															  NewMembers2 = NewMembers;
														  [#p_role_attr{office_name=OfficeName,family_contribute=FC}] -> 
															  %% 副族长居然不在族员列表中？                                                    
															  NewMember = #p_family_member_info{role_id=SID, role_name=SName, sex=Sex,
																								title=?FAMILY_TITLE_OWNER, 
																								office_name=OfficeName, family_contribution=FC},
															  NewMembers2 = [NewMember|NewMembers]
													  end
											  end;
										  Member ->
											  NewMember = Member#p_family_member_info{title=?FAMILY_TITLE_OWNER},
											  NewMembers2 = lists:keyreplace(SID, #p_family_member_info.role_id, NewMembers, NewMember)
									  end,
                                      NewFamilyInfo = FamilyInfo#p_family_info{owner_role_id=SID, owner_role_name=SName,
                                                                               members=NewMembers2, create_role_id=SID,
                                                                               create_role_name=SName,
                                                                               cur_members=erlang:length(NewMembers2),
                                                                               second_owners=NewSecondOwners2},
                                      mnesia:dirty_write(TabFamilyRenamed, NewFamilyInfo);
                                  false ->
                                      %% 随机找人，先删除掉族长
                                      Members2 = lists:keydelete(OwnerRoleID, #p_family_member_info.role_id, NewMembers),
                                      %% 按照宗族总贡献度排序
                                      Members3 = lists:keysort(#p_family_member_info.family_contribution, Members2),
                                      Member = erlang:hd(Members3),
                                      #p_family_member_info{role_id=MID, role_name=MName} = Member,
                                      NewMember = Member#p_family_member_info{title=?FAMILY_TITLE_OWNER},
                                      NewMembers2 = lists:keyreplace(MID, #p_family_member_info.role_id, Members2, NewMember),
                                      NewFamilyInfo = FamilyInfo#p_family_info{owner_role_id=MID, owner_role_name=MName,
                                                                               members=NewMembers2, create_role_id=MID,
                                                                               create_role_name=MName,
                                                                               second_owners=NewSecondOwners,
                                                                               cur_members=erlang:length(NewMembers2)},
                                      db:dirty_write(TabFamilyRenamed, NewFamilyInfo)
                              end;
                          false ->
                              mnesia:dirty_delete(TabFamilyRenamed, FamilyInfo#p_family_info.family_id)
                      end;
                  [{OwnerRoleID, NewOwnerRoleID}] ->                                   
                      case ets:lookup(EtsTabName, CreateRoleID) of
                          [] ->
                              NewCreateRoleID = NewOwnerRoleID,
                              NewCreateRoleName = OwnerRoleName;                  
                          [{CreateRoleID, NewCreateRoleID}] ->
                              NewCreateRoleName = CreateRoleName
                      end,
                      NewFamilyInfo = FamilyInfo#p_family_info{create_role_id=NewCreateRoleID, owner_role_id=NewOwnerRoleID,
                                                               create_role_name=NewCreateRoleName, 
                                                               second_owners=NewSecondOwners, members=NewMembers},
                      mnesia:dirty_write(TabFamilyRenamed, NewFamilyInfo)
              end
      end, mnesia:dirty_match_object(TabFamilyRenamed, #p_family_info{_='_'})),
    ok.

do_update_pet_info_when_reset_role_id(ServerID) ->
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    TabPetRenamed = get_renamed_table_name(?DB_PET_P, ServerID),
    lists:foreach(
      fun(#p_pet{role_id=RoleID} = R) ->
              case ets:lookup(EtsTabName, RoleID) of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      mnesia:dirty_write(TabPetRenamed, R#p_pet{role_id=NewRoleID})
              end
      end, mnesia:dirty_match_object(TabPetRenamed, #p_pet{_='_'})),
    TabPetBagRenamed = get_renamed_table_name(?DB_ROLE_PET_BAG_P, ServerID),

    lists:foreach(
      fun(#p_role_pet_bag{role_id=RoleID} = R) ->
              case ets:lookup(EtsTabName, RoleID)  of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      mnesia:dirty_delete_object(TabPetBagRenamed, R),
                      mnesia:dirty_write(TabPetBagRenamed, R#p_role_pet_bag{role_id=NewRoleID})
              end
      end, mnesia:dirty_match_object(TabPetBagRenamed, #p_role_pet_bag{_='_'})),

    TabPetTrainingRenamed = get_renamed_table_name(?DB_PET_TRAINING_P, ServerID),
    lists:foreach(
      fun(#r_pet_training{role_id=RoleID,cur_room=CurRoom} = R) ->
              case ets:lookup(EtsTabName, RoleID)  of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      mnesia:dirty_delete_object(TabPetTrainingRenamed, R),
                      mnesia:dirty_write(TabPetTrainingRenamed, #r_pet_training{role_id=NewRoleID,cur_room=CurRoom})
              end
      end, mnesia:dirty_match_object(TabPetTrainingRenamed, #r_pet_training{_='_'})),
	
    ok.

do_update_pay_log_when_reset_role_id(ServerID) ->
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    %% 处理充值日志
    TabPaylogRenamed = get_renamed_table_name(?DB_PAY_LOG_P, ServerID),
    lists:foreach(
      fun(#r_pay_log{role_id=RoleID} = R) ->
              case ets:lookup(EtsTabName, RoleID) of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      mnesia:dirty_write(TabPaylogRenamed, R#r_pay_log{role_id=NewRoleID})
              end
      end, mnesia:dirty_match_object(TabPaylogRenamed, #r_pay_log{_='_'})),
    ok.


do_update_stall_info_when_reset_role_id(ServerIDList) when is_list(ServerIDList) ->
    lists:foreach(fun(ServerID) -> do_update_stall_info_when_reset_role_id(ServerID) end, ServerIDList);
do_update_stall_info_when_reset_role_id(ServerID) when is_integer(ServerID) ->
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    %% 处理摆摊中的物品
    TabStallRenamed = get_renamed_table_name(?DB_STALL_GOODS_P, ServerID),
    lists:foreach(
      fun(#r_stall_goods{id={RoleID, GoodsID}, role_id=RoleID, goods_detail=GoodsInfo} = R) ->
              case ets:lookup(EtsTabName, RoleID) of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      NewGoodsInfo = GoodsInfo#p_goods{roleid=NewRoleID},
                      mnesia:dirty_write(?DB_STALL_GOODS_P, R#r_stall_goods{id={NewRoleID, GoodsID}, role_id=NewRoleID, goods_detail=NewGoodsInfo})
              end
      end, mnesia:dirty_match_object(TabStallRenamed, #r_stall_goods{_='_'})),

    TabStallTmpRenamed = get_renamed_table_name(?DB_STALL_GOODS_TMP_P, ServerID),
    lists:foreach(
      fun(#r_stall_goods{id={RoleID, GoodsID}, role_id=RoleID, goods_detail=GoodsInfo} = R) ->
              case ets:lookup(EtsTabName, RoleID) of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      NewGoodsInfo = GoodsInfo#p_goods{roleid=NewRoleID},
                      mnesia:dirty_write(?DB_STALL_GOODS_TMP_P, R#r_stall_goods{id={NewRoleID, GoodsID}, role_id=NewRoleID, goods_detail=NewGoodsInfo})
              end
      end, mnesia:dirty_match_object(TabStallTmpRenamed, #r_stall_goods{_='_'})),
    ok.

do_update_role_bag_info_when_reset_role_id(ServerIDList) when is_list(ServerIDList) ->
    lists:foreach(fun(ServerID) -> do_update_role_bag_info_when_reset_role_id(ServerID) end, ServerIDList);
do_update_role_bag_info_when_reset_role_id(ServerID) when is_integer(ServerID) ->
    %% 处理角色背包
    TabRoleBagBasicRenamed = get_renamed_table_name(?DB_ROLE_BAG_BASIC_P, ServerID),
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    lists:foreach(
      fun(#r_role_bag_basic{role_id=RoleID} = R) ->
              case ets:lookup(EtsTabName, RoleID) of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      mnesia:dirty_write(?DB_ROLE_BAG_BASIC_P, R#r_role_bag_basic{role_id=NewRoleID})
              end
      end, mnesia:dirty_match_object(TabRoleBagBasicRenamed, #r_role_bag_basic{_='_'})),
    TabRoleBagRenamed = get_renamed_table_name(?DB_ROLE_BAG_P, ServerID),
    lists:foreach(
      fun(#r_role_bag{role_bag_key={RoleID, BagID}, bag_goods=BagGoods} = R) ->
              case ets:lookup(EtsTabName, RoleID) of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      NewBagGoods = lists:foldl(
                                      fun(Goods, Acc) ->
                                              TypeID = Goods#p_goods.typeid,
                                              %% 合服后所有的官职装备全部收回
                                              case lists:member(TypeID, [?OFFICE_EQUIP_MINISTER, ?OFFICE_EQUIP_GENERAL,
                                                                         ?OFFICE_EQUIP_JINYIWEI, ?OFFICE_EQUIP_KING]) of
                                                  true ->
                                                      Acc;
                                                  false ->
                                                      NewGoodsInfo = Goods#p_goods{roleid=NewRoleID},
                                                      [NewGoodsInfo | Acc]
                                              end
                                      end, [], BagGoods),
                      mnesia:dirty_write(?DB_ROLE_BAG_P, R#r_role_bag{role_bag_key={NewRoleID, BagID}, bag_goods=NewBagGoods})
              end
      end, mnesia:dirty_match_object(TabRoleBagRenamed, #r_role_bag{_='_'})),
    ok.

%% 重排角色ID
do_reset_role_id(ServerID) ->
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    ets:new(EtsTabName, [public, set, named_table]),
    TabRoleBaseRenamed = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID),
    lists:foreach(
      fun(#p_role_base{role_id=RoleID}) ->
              NewRoleID = get_new_role_id(),             
              %% 记录每个节点角色ID的重新映射关系
              ets:insert(EtsTabName, {RoleID, NewRoleID}),                  
              do_update_info_case_role_id_is_key_when_reset_role_id(ServerID, RoleID, NewRoleID),              
              ok
      end, mnesia:dirty_match_object(TabRoleBaseRenamed, #p_role_base{_='_'})),
    update_role_id_map(ServerID),
    ok.

do_update_pay_failed_when_reset_role_id(ServerID) ->
    %% 处理充值失败记录
    TabPayFailedRenamed = get_renamed_table_name(?DB_PAY_FAILED_P, ServerID),
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    lists:foreach(
      fun(#r_pay_failed{role_id=RoleID} = R) ->
              case ets:lookup(EtsTabName, RoleID) of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      mnesia:dirty_write(?DB_PAY_FAILED_P, R#r_pay_failed{role_id=NewRoleID})
              end
      end, mnesia:dirty_match_object(TabPayFailedRenamed, #r_pay_failed{_='_'})),
    ok.

do_update_role_name_when_reset_role_id(ServerID) ->
    TabRoleNameRenamed = get_renamed_table_name(?DB_ROLE_NAME_P, ServerID),
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    lists:foreach(
      fun(#r_role_name{role_id=RoleID} = R) ->
              case ets:lookup(EtsTabName, RoleID) of
                  [] ->
                      ignore;
                  [{RoleID, NewRoleID}] ->
                      mnesia:dirty_write(?DB_ROLE_NAME_P, R#r_role_name{role_id=NewRoleID})
              end
      end, mnesia:dirty_match_object(TabRoleNameRenamed, #r_role_name{_='_'})),
    ok.


update_role_id_map(ServerID) ->
    ?LOG("~ts:~p~n", ["重置角色ID --- 更新宗族信息", ServerID]),
    update_family_info_when_reset_role_id(ServerID),
    ?LOG("~ts:~p~n", ["重置角色ID --- 更新好友信息", ServerID]),
    do_update_friend_info_when_reset_role_id(ServerID),
    ?LOG("~ts:~p~n", ["重置角色ID --- 更新异兽信息", ServerID]),
    do_update_pet_info_when_reset_role_id(ServerID),
    ?LOG("~ts:~p~n", ["重置角色ID --- 更新充值信息", ServerID]),
    do_update_pay_log_when_reset_role_id(ServerID),
    ?LOG("~ts:~p~n", ["重置角色ID --- 更新充值失败日志信息", ServerID]),
    do_update_pay_failed_when_reset_role_id(ServerID),
    ?LOG("~ts:~p~n", ["重置角色ID --- 更新角色名信息", ServerID]),
    do_update_role_name_when_reset_role_id(ServerID),
    ?LOG("~ts:~p~n", ["重置角色ID --- 更新信件信息", ServerID]),
    do_update_letter_info_when_reset_role_id(ServerID),
    ok.

-define(TYPE_LETTER_SYSTEM,2).

do_update_letter_info_when_reset_role_id(ServerID) ->
    TabPersonLetterRenamed = get_renamed_table_name(?DB_PERSONAL_LETTER_P, ServerID),
    EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
    lists:foreach(
      fun(#r_personal_letter{id=ID, send_id=SendID, recv_id=RecvID} = R) ->
              case ets:lookup(EtsTabName, SendID) of
                  [] ->
                      NewSendID = 0,
                      Type = ?TYPE_LETTER_SYSTEM,
                      case ets:lookup(EtsTabName, RecvID) of
                          [] ->
                              mnesia:dirty_delete(TabPersonLetterRenamed, ID);
                          [{RecvID, NewRecvID}] ->
                              mnesia:dirty_write(TabPersonLetterRenamed, R#r_personal_letter{send_id=NewSendID, type=Type, recv_id=NewRecvID})
                      end;
                  [{SendID, NewSendID}] ->
                      case ets:lookup(EtsTabName, RecvID) of
                          [] ->
                              mnesia:dirty_delete(TabPersonLetterRenamed, ID);
                          [{RecvID, NewRecvID}] ->
                              mnesia:dirty_write(TabPersonLetterRenamed, R#r_personal_letter{send_id=NewSendID, recv_id=NewRecvID})
                      end
              end
      end, mnesia:dirty_match_object(TabPersonLetterRenamed, #r_personal_letter{_='_'})),
    ok.

get_new_family_id() ->
    [#r_family_counter{value=LastFamilyID}] = mnesia:dirty_read(?DB_FAMILY_COUNTER_P, 1),
    mnesia:dirty_write(?DB_FAMILY_COUNTER_P, #r_family_counter{id=1, value=LastFamilyID+1}),
    LastFamilyID + 1.

do_reset_family_id(ServerID) ->
    TabFamilyInfoRenamed = get_renamed_table_name(?DB_FAMILY_P, ServerID),
    TabFamilyExtRenamed = get_renamed_table_name(?DB_FAMILY_EXT_P, ServerID),
    EtsTabName = common_tool:list_to_atom(lists:concat(["family_id_map_", ServerID])),
    ets:new(EtsTabName, [public, set, named_table]),
    %% 前面角色ID重置时已经更新了宗族中的玩家信息
    lists:foreach(
      fun(#p_family_info{family_id=FamilyID, members=Members} = FamilyInfo) ->
              NewFamilyID = get_new_family_id(),
              ets:insert(EtsTabName, {FamilyID, NewFamilyID}),
              lists:foreach(
                fun(#p_family_member_info{role_id=RoleID}) ->
                        case mnesia:dirty_read(?DB_ROLE_BASE_P, RoleID) of
                            [] ->
                                ignore;
                            [RoleBase] ->
                                mnesia:dirty_write(?DB_ROLE_BASE_P, RoleBase#p_role_base{family_id=NewFamilyID})
                        end
                end, Members),
              mnesia:dirty_write(?DB_FAMILY_P, FamilyInfo#p_family_info{family_id=NewFamilyID}),
              case mnesia:dirty_read(TabFamilyExtRenamed, FamilyID) of
                  [] ->
                      mnesia:dirty_write(?DB_FAMILY_EXT_P, #r_family_ext{family_id=NewFamilyID});
                  [FamilyExt] ->
                      mnesia:dirty_write(?DB_FAMILY_EXT_P, FamilyExt#r_family_ext{family_id=NewFamilyID})
              end
      end, mnesia:dirty_match_object(TabFamilyInfoRenamed, #p_family_info{_='_'})),
    TabFamilyAssertsRenamed = get_renamed_table_name(?DB_FAMILY_ASSETS_P, ServerID),
    lists:foreach(
      fun(#r_family_assets{family_id=FamilyID} = R) ->
              case ets:lookup(EtsTabName, FamilyID) of
                  [] ->
                      ignore;
                  [{FamilyID, NewFamilyID}] ->
                      mnesia:dirty_write(?DB_FAMILY_ASSETS_P, R#r_family_assets{family_id=NewFamilyID})
              end
      end, mnesia:dirty_match_object(TabFamilyAssertsRenamed, #r_family_assets{_='_'})),
    TabFamilyDepotRenamed = get_renamed_table_name(?DB_FAMILY_DEPOT_P, ServerID),
    lists:foreach(
      fun(#r_family_depot{depot_key={FamilyID, BagID}} = R) ->
              case ets:lookup(EtsTabName, FamilyID) of
                  [] ->
                      ignore;
                  [{FamilyID, NewFamilyID}] ->
                      mnesia:dirty_write(?DB_FAMILY_DEPOT_P, R#r_family_depot{depot_key={NewFamilyID, BagID}})
              end
      end, mnesia:dirty_match_object(TabFamilyDepotRenamed, #r_family_depot{_='_'})),
	TabFamilyShopRenamed = get_renamed_table_name(?DB_FAMILY_SHOP_P, ServerID),
    lists:foreach(
      fun(#r_family_shop{family_id=FamilyID} = R) ->
              case ets:lookup(EtsTabName, FamilyID) of
                  [] ->
                      ignore;
                  [{FamilyID, NewFamilyID}] ->
                      mnesia:dirty_write(?DB_FAMILY_SHOP_P, R#r_family_shop{family_id=NewFamilyID})
              end
      end, mnesia:dirty_match_object(TabFamilyShopRenamed, #r_family_shop{_='_'})),
    ok.


get_new_role_id() ->
    [#r_roleid_counter{last_role_id=LastRoleID} = R] = mnesia:dirty_read(?DB_ROLEID_COUNTER_P, 1),
    mnesia:dirty_write(?DB_ROLEID_COUNTER_P, R#r_roleid_counter{last_role_id=LastRoleID+1}),
    LastRoleID + 1.
%% get_new_role_id(RoleID, ServerID) ->
%% 	EtsTabName = common_tool:list_to_atom(lists:concat(["role_id_map", ServerID])),
%% 	case ets:lookup(EtsTabName, RoleID) of
%% 		[] ->
%% 			0;
%% 		[{RoleID, NewRoleID}] ->
%% 			NewRoleID
%% 	end.

do_remove_all_tmp_table(ServerIDList) ->
    lists:foreach(
      fun(ServerID) ->
              lists:foreach(
                fun({Tab, _Definition}) ->
                        mnesia:delete_table(get_renamed_table_name(Tab, ServerID)),
                        mnesia:delete_table(get_renamed_tmp_table_name(Tab, ServerID))
                end, mgeed_mnesia:table_defines())
      end, ServerIDList),
    ok.

create_account_name_tmp_table() ->
    mnesia:create_table(?DB_ACCOUNT_NAME_TMP, ?DEF_RAM_TABLE(set, r_account_name_tmp)),
    ok.

create_family_name_tmp_table() ->
    mnesia:create_table(?DB_FAMILY_NAME_TMP, ?DEF_RAM_TABLE(set, r_family_name_tmp)),
    ok.

create_role_name_tmp_table() ->
    mnesia:create_table(?DB_ROLE_NAME_TMP, ?DEF_RAM_TABLE(set, r_role_name_tmp)),
    ok.

%% 处理账号重复的问题
do_process_account_name(ServerIDList) ->
    %% 创建一个临时表，用于记录哪些名字是重复的
    create_account_name_tmp_table(),
    %% 先跑一次循环，检查哪些角色名是重复的
    lists:foreach(
      fun(ServerID) ->
              Tab = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID),
              lists:foreach(
                fun(#p_role_base{role_id=RoleID, account_name=AccountName}) ->
                        case mnesia:dirty_read(?DB_ACCOUNT_NAME_TMP, AccountName) of
                            [] ->
                                mnesia:dirty_write(?DB_ACCOUNT_NAME_TMP, #r_account_name_tmp{account_name=AccountName, 
                                                                                             role_id_list=[{ServerID, RoleID}]}),
                                ok;
                            [#r_account_name_tmp{role_id_list=RoleIDList} = R] ->
                                mnesia:dirty_write(?DB_ACCOUNT_NAME_TMP, 
                                                   R#r_account_name_tmp{role_id_list=[{ServerID, RoleID} | RoleIDList]}),
                                ok
                        end
                end, mnesia:dirty_match_object(Tab, #p_role_base{_='_'}))
      end, ServerIDList),
    %% 遍历出哪些角色的账号是重复的
    Dumplicates = 
        lists:foldl(
          fun(#r_account_name_tmp{role_id_list=RoleIDList} = R, Acc) ->
                  case erlang:length(RoleIDList) > 1 of
                      true ->
                          [R | Acc];
                      false ->
                          Acc
                  end
          end, [], mnesia:dirty_match_object(?DB_ACCOUNT_NAME_TMP, #r_account_name_tmp{_='_'})),
    [PostFix] = common_config_dyn:find(merge, rename_postfix),
    lists:foreach(
      fun(#r_account_name_tmp{account_name=AccountName, role_id_list=RoleIDList}) ->
			  ?LOG("AccountName:~p~n",[AccountName]),
              NewIDList = lists:foldl(
                            fun({ServerID, RoleID}, Acc) ->
                                    [#p_role_attr{level=Level}] = mnesia:dirty_read(get_renamed_table_name(?DB_ROLE_ATTR_P, ServerID), RoleID),
                                    TBaseTab = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID), 
                                    [#p_role_base{create_time=CreateTime}] = mnesia:dirty_read(TBaseTab, RoleID),
                                    [{Level, ServerID, RoleID, CreateTime} | Acc]
                            end, [], RoleIDList),
              NewIDList2 = po_sort(NewIDList, fun({LevelA, _ServerIDA, _, CreateTimeA}, {LevelB, _ServerIDB, _, CreateTimeB}) -> 
                                                      if
                                                          LevelA > LevelB ->
                                                              true;
                                                          LevelA =:= LevelB ->
                                                              CreateTimeA =< CreateTimeB;
                                                          true ->
                                                              false
                                                      end
                                              end),

			  [{_L, FirstServerID, FirstRoleID, _CreateTime} | RemainList] = NewIDList2,
			  %%写入区服ID
			  FirstTBaseTab = get_renamed_table_name(?DB_ROLE_BASE_P, FirstServerID),
			  [R1] = mnesia:dirty_read(FirstTBaseTab, FirstRoleID),
			  mnesia:dirty_write(FirstTBaseTab, R1#p_role_base{server_id=FirstServerID}),
			  
			  lists:foreach(
				fun({_, ServerID, RoleID, _}) ->
						TBaseTab = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID),
						[R2] = mnesia:dirty_read(TBaseTab, RoleID),
						NewAccountName = common_tool:to_binary(lists:flatten(lists:concat([common_tool:to_list(AccountName), PostFix, ServerID]))),
						mnesia:dirty_write(TBaseTab, R2#p_role_base{server_id=ServerID}),
						TAttrTab = get_renamed_table_name(?DB_ROLE_ATTR_P, ServerID),
						[#p_role_attr{level=Level, category=Category}] = mnesia:dirty_read(TAttrTab, RoleID),
						NewRebindRole = #r_rebind_role{server_id=ServerID, role_name=R2#p_role_base.role_name, 
													   faction_id=R2#p_role_base.faction_id, category=Category,
													   level=Level,
													   new_tmp_account=NewAccountName},
						case mnesia:dirty_read(?DB_ACCOUNT_REBIND_P, AccountName) of
							[] ->                                
								mnesia:dirty_write(?DB_ACCOUNT_REBIND_P, #r_account_rebind{account=AccountName, 
																						   need_rebind_list=[NewRebindRole]});
							[#r_account_rebind{need_rebind_list=OldRebindList}=RebindRecord] ->
								case lists:keyfind(ServerID, #r_rebind_role.server_id, OldRebindList) of
									false ->
										mnesia:dirty_write(?DB_ACCOUNT_REBIND_P, RebindRecord#r_account_rebind{
																											   need_rebind_list=[NewRebindRole | OldRebindList]});
									_ ->
										ignore
								end
						end
				end, RemainList),
			  
			  ok
      end, Dumplicates),
    ok.

%% 数据库中记录 family_list  [{server_id, family_id}, ......]
do_process_family_name(ServerIDList) ->
    %% 创建一个临时表，用于记录哪些名字是重复的
    create_family_name_tmp_table(),
    %% 先跑一次循环，检查哪些角色名是重复的
    lists:foreach(
      fun(ServerID) ->
              Tab = get_renamed_table_name(?DB_FAMILY_P, ServerID),
              lists:foreach(
                fun(#p_family_info{family_name=FamilyName, family_id=FamilyID}) ->
                        case mnesia:dirty_read(?DB_FAMILY_NAME_TMP, FamilyName) of
                            [] ->
                                mnesia:dirty_write(?DB_FAMILY_NAME_TMP, #r_family_name_tmp{family_name=FamilyName, 
                                                                                           family_id_list=[{ServerID, FamilyID}]}),
                                ok;
                            [#r_family_name_tmp{family_id_list=FamilyIDList} = R] ->
                                mnesia:dirty_write(?DB_FAMILY_NAME_TMP, R#r_family_name_tmp{family_id_list=[{ServerID, FamilyID} | FamilyIDList]}),
                                ok
                        end
                end, mnesia:dirty_match_object(Tab, #p_family_info{_='_'}))
      end, ServerIDList),
    %% 遍历出哪些宗族名是重复的
    Dumplicates = 
        lists:foldl(
          fun(#r_family_name_tmp{family_id_list=FamilyIDList} = R, Acc) ->
                  case erlang:length(FamilyIDList) > 1 of
                      true ->
                          [R | Acc];
                      false ->
                          Acc
                  end
          end, [], mnesia:dirty_match_object(?DB_FAMILY_NAME_TMP, #r_family_name_tmp{_='_'})),
    [PostFix] = common_config_dyn:find(merge, rename_postfix),
    lists:foreach(
      fun(#r_family_name_tmp{family_name=FamilyName, family_id_list=FamilyIDList}) ->
			  ?LOG("FamilyName:~p~n",[FamilyName]),
              NewIDList = lists:foldl(
                            fun({ServerID, FamilyID}, Acc) ->
                                    TFamilyTmp = get_renamed_table_name(?DB_FAMILY_P, ServerID), 
                                    [#p_family_info{level=Level, active_points=AC}] = mnesia:dirty_read(TFamilyTmp, FamilyID),
                                    [{Level, ServerID, FamilyID, AC} | Acc]
                            end, [], FamilyIDList),
              NewIDList2 = po_sort(NewIDList, fun({LevelA, _ServerIDA, _, ACA}, {LevelB, _ServerIDB, _, ACB}) -> 
                                                      if
                                                          LevelA > LevelB ->
                                                              true;
                                                          LevelA =:= LevelB ->
                                                              ACA >= ACB;
                                                          true ->
                                                              false
                                                      end
                                              end),
              %% 排名最前面的不用改名，其他都按照规则改名
              [{_L, _ServerID, _FamilyID, _AC} | RemainList] = NewIDList2,
              lists:foreach(
                fun({_, ServerID, FamilyID, _}) ->
                        NewFamilyName = common_tool:to_binary(lists:flatten(lists:concat([common_tool:to_list(FamilyName), PostFix, ServerID]))),
                        rename_family_name(FamilyID, NewFamilyName, ServerID)
                end, RemainList),
              ok
      end, Dumplicates),
    ok.

rename_family_name(FamilyID, NewFamilyName, ServerID) ->
    TabFamilyInfoRenamed = get_renamed_table_name(?DB_FAMILY_P, ServerID),
    [#p_family_info{members=Members} = FamilyInfo] = mnesia:dirty_read(TabFamilyInfoRenamed, FamilyID),
    TabRoleBaseRenamed = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID),
    lists:foreach(
      fun(#p_family_member_info{role_id=RoleID}) ->
              case mnesia:dirty_read(TabRoleBaseRenamed, RoleID) of
                  [] ->
                      ignore;
                  [R] ->
                      mnesia:dirty_write(TabRoleBaseRenamed, R#p_role_base{family_name=NewFamilyName})
              end
      end, Members),
    NewFamilyInfo = FamilyInfo#p_family_info{family_name=NewFamilyName},
    mnesia:dirty_write(TabFamilyInfoRenamed, NewFamilyInfo).


%% 处理角色重名的情况，并根据规则进行重命名
%% 数据库中记录 role_id_list  [{server_id, role_id}, ......]
do_process_role_name(ServerIDList) ->
    %% 创建一个临时表，用于记录哪些名字是重复的
    create_role_name_tmp_table(),
    %% 先跑一次循环，检查哪些角色名是重复的
    lists:foreach(
      fun(ServerID) ->
              Tab = get_renamed_table_name(?DB_ROLE_NAME_P, ServerID),
              lists:foreach(
                fun(#r_role_name{role_name=RoleName, role_id=RoleID}) ->
                        case mnesia:dirty_read(?DB_ROLE_NAME_TMP, RoleName) of
                            [] ->
                                mnesia:dirty_write(?DB_ROLE_NAME_TMP, #r_role_name_tmp{role_name=RoleName, role_id_list=[{ServerID, RoleID}]}),
                                ok;
                            [#r_role_name_tmp{role_id_list=RoleIDList} = R] ->
                                mnesia:dirty_write(?DB_ROLE_NAME_TMP, R#r_role_name_tmp{role_id_list=[{ServerID, RoleID} | RoleIDList]}),
                                ok
                        end
                end, mnesia:dirty_match_object(Tab, #r_role_name{_='_'}))
      end, ServerIDList),
    %% 遍历出哪些角色是重复的
    Dumplicates = 
        lists:foldl(
          fun(#r_role_name_tmp{role_id_list=RoleIDList} = R, Acc) ->
                  case erlang:length(RoleIDList) > 1 of
                      true ->
                          [R | Acc];
                      false ->
                          Acc
                  end
          end, [], mnesia:dirty_match_object(?DB_ROLE_NAME_TMP, #r_role_name_tmp{_='_'})),
    [PostFix] = common_config_dyn:find(merge, rename_postfix),
    lists:foreach(
      fun(#r_role_name_tmp{role_name=RoleName, role_id_list=RoleIDList}) ->
			  ?LOG("RoleName:~p~n",[RoleName]),
			  NewIDList = lists:foldl(
							fun({ServerID, RoleID}, Acc) ->
									case mnesia:dirty_read(get_renamed_table_name(?DB_ROLE_ATTR_P, ServerID), RoleID) of
										[] ->
											Acc;
										[#p_role_attr{level=Level}] ->
											TBaseTab = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID), 
											case mnesia:dirty_read(TBaseTab, RoleID) of
												[] ->
													Acc;
												[#p_role_base{create_time=CreateTime}] ->
													[{Level, ServerID, RoleID, CreateTime} | Acc]
											end
									end
							end, [], RoleIDList),
              NewIDList2 = po_sort(NewIDList, fun({LevelA, _ServerIDA, _, CreateTimeA}, {LevelB, _ServerIDB, _, CreateTimeB}) -> 
                                                      if
                                                          LevelA > LevelB ->
                                                              true;
                                                          LevelA =:= LevelB ->
                                                              CreateTimeA =< CreateTimeB;
                                                          true ->
                                                              false
                                                      end
                                              end),
              %% 排名最前面的不用改名，其他都按照规则改名
			  case erlang:is_list(NewIDList2) andalso erlang:length(NewIDList2) > 0 of
				  true ->
					  [{_L, _ServerID, _RoleID, _CreateTime} | RemainList] = NewIDList2,
					  lists:foreach(
						fun({_, ServerID, RoleID, _}) ->
								NewRoleName = common_tool:to_binary(lists:flatten(lists:concat([common_tool:to_list(RoleName), PostFix, ServerID]))),
								rename_role_name(RoleID, NewRoleName, ServerID)
						end, RemainList);
				  false ->
					  ok
			  end,
              ok
      end, Dumplicates),
    ok.

%% 角色改名，除充值日志意外的日志都不用管了
rename_role_name(RoleID, NewRoleName, ServerID) ->
    %% 不用管重名判断了，一定不会重复的
    TabRoleBaseRenamed = get_renamed_table_name(?DB_ROLE_BASE_P, ServerID),
    [#p_role_base{role_name=RoleName, family_id=FamilyID} = RoleBase] = mnesia:dirty_read(TabRoleBaseRenamed, RoleID),
    TabRoleAttrRenamed = get_renamed_table_name(?DB_ROLE_ATTR_P, ServerID),
    [RoleAttr] = mnesia:dirty_read(TabRoleAttrRenamed, RoleID),
    mnesia:dirty_write(TabRoleAttrRenamed, RoleAttr#p_role_attr{role_name=NewRoleName}),
    mnesia:dirty_write(TabRoleBaseRenamed, RoleBase#p_role_base{role_name=NewRoleName}),
    %% 处理充值日志
    TabPayLogRenamed = get_renamed_table_name(?DB_PAY_LOG_P, ServerID),
    lists:foreach(
      fun(R) ->
              mnesia:dirty_write(TabPayLogRenamed, R#r_pay_log{role_name=NewRoleName})
      end, mnesia:dirty_match_object(TabPayLogRenamed, #r_pay_log{role_id=RoleID, _='_'})),
    %% 角色名表
    TabRoleNameRenamed = get_renamed_table_name(?DB_ROLE_NAME_P, ServerID),
    mnesia:dirty_write(TabRoleNameRenamed, #r_role_name{role_name=NewRoleName, role_id=RoleID}),
    mnesia:dirty_delete(TabRoleNameRenamed, RoleName),
    %% 全局信件
    TabPublicLetterRenamed = get_renamed_table_name(?DB_PUBLIC_LETTER_P, ServerID),
    case mnesia:dirty_read(TabPublicLetterRenamed, RoleID) of
        [] ->
            ignore;
        [PublicLetter] ->
            mnesia:dirty_write(TabPublicLetterRenamed, PublicLetter#r_public_letter{role_name=NewRoleName})
    end,
    %% 场景大战副本
    TabSceneWarFbRenamed = get_renamed_table_name(?DB_SCENE_WAR_FB_P, ServerID),
    case  mnesia:dirty_read(TabSceneWarFbRenamed, RoleID) of
        [] ->
            ignore;
        [SceneWarFb] ->
            mnesia:dirty_write(TabSceneWarFbRenamed, SceneWarFb#r_scene_war_fb{role_name=NewRoleName})
    end,
    %% 处理异兽
    TabPetRenamed = get_renamed_table_name(?DB_PET_P, ServerID),
    case mnesia:dirty_match_object(TabPetRenamed, #p_pet{role_id=RoleID, _='_'}) of
        [] ->
            ok;
        PetList ->
            lists:foreach(
              fun(Pet) ->
                      mnesia:dirty_write(TabPetRenamed, Pet#p_pet{role_name=NewRoleName})
              end, PetList)
    end,
    %% 处理宗族
    TabFamilyInfoRenamed = get_renamed_table_name(?DB_FAMILY_P, ServerID),
    case mnesia:dirty_read(TabFamilyInfoRenamed, FamilyID) of
        [] ->
            ignore;
        [#p_family_info{members=Members}=FamilyInfo] ->            
            case lists:keyfind(RoleID, #p_family_member_info.role_id, Members) of
                false ->
                    FamilyInfoTmp = FamilyInfo,
                    ignore;
                R ->
                    NewMembers = lists:keyreplace(RoleID, #p_family_member_info.role_id, Members, R#p_family_member_info{role_name=NewRoleName}),
                    FamilyInfoTmp = FamilyInfo#p_family_info{members=NewMembers}
            end,
            case FamilyInfoTmp#p_family_info.create_role_id =:= RoleID of
                true ->
                    FamilyInfo2 = FamilyInfoTmp#p_family_info{create_role_name=NewRoleName};
                false ->
                    FamilyInfo2 = FamilyInfoTmp
            end,
            case FamilyInfo2#p_family_info.owner_role_id =:= RoleID of
                true ->
                    FamilyInfo3 = FamilyInfo2#p_family_info{owner_role_name=NewRoleName};
                false ->
                    FamilyInfo3 = FamilyInfo2
            end,
            SecondOwners = FamilyInfo3#p_family_info.second_owners,
            case lists:keyfind(RoleID, #p_family_second_owner.role_id, SecondOwners) of
                false ->
                    FamilyInfo4 = FamilyInfo3;
                SecondOwner ->
                    NewSecondOwner = SecondOwner#p_family_second_owner{role_id=RoleID, role_name=NewRoleName},
                    NewSecondOwners = lists:keyreplace(RoleID, #p_family_second_owner.role_id, SecondOwners, NewSecondOwner),
                    FamilyInfo4 = FamilyInfo3#p_family_info{second_owners=NewSecondOwners}
            end,
            mnesia:dirty_write(TabFamilyInfoRenamed, FamilyInfo4)
    end,        
    ok.

po_sort(L, Func) -> 
    po_sort_a(L, [], [], Func).

po_sort_a([], [],  R, _Func) -> 
    R;
po_sort_a([A], PA, R, Func) -> 
    po_sort_a(PA, [], [A|R], Func);
po_sort_a([A,B|T], PA, R, Func) -> 
    case Func(A, B) of
        false ->
            po_sort_a([A|T], [B|PA], R, Func);
        true ->
            po_sort_a([B|T], [A|PA], R, Func)
    end.

%% 删除所有数据的数据，这些数据已经被拷贝到新表了
remove_restore_data() ->
    lists:foreach(
      fun({Tab, _Definition}) ->
              mnesia:clear_table(Tab)
      end, mgeed_mnesia:table_defines()).

%% 拷贝数据
copy_data(ServerID) ->
    lists:foreach(
      fun({Tab, _Definition}) ->
              Pattern = mnesia:table_info(Tab, wild_pattern),
              AllRecord = mnesia:dirty_match_object(Tab, Pattern),
              Tab2 = get_renamed_table_name(Tab, ServerID),
              [mnesia:dirty_write(Tab2, R) || R <- AllRecord]
      end, mgeed_mnesia:table_defines()),
    ok.

do_start_log_server() ->
    case global:whereis_name(merge_log_server) of
        undefined ->
            PID = erlang:self(),
            erlang:spawn(fun() -> merge_log:start_log_server(merge_log_server, PID) end),
            %% 强制等待日志服务器启动完成
            receive 
                log_server_started ->
                    ok
            end;
        _PID ->
            ignore
    end.

get_renamed_table_name(Tab, ServerID) ->
    common_tool:list_to_atom(lists:concat([Tab, "_", ServerID])).

get_renamed_tmp_table_name(Tab, ServerID) ->
    common_tool:list_to_atom(lists:concat([Tab, "_tmp_", ServerID])).

%% 建立所有P表对应的重命名表 db_role_attr_p => db_role_attr_p_3
rename_table(ServerID) ->
    mgeed_mnesia:init_db(),
    lists:foreach(
      fun({Tab, Definition}) ->
              D2 = lists:keydelete(disc_copies, 1, Definition),
              Tab2 = get_renamed_table_name(Tab, ServerID),
              D3 = [{ram_copies, [erlang:node()]} | D2],
              Tab3 = get_renamed_tmp_table_name(Tab, ServerID),
              mnesia:create_table(Tab2, D3),
              mnesia:create_table(Tab3, D3)
      end, mgeed_mnesia:table_defines()).

%% 从mnesia的备份文件中恢复数据
%% 恢复的文件名规则： /data/database/merge/4399/merge.3
restore_data(ServerID) ->
    FilePath = lists:flatten(lists:concat(["/data/database/merge/", get_agent_name(), "/merge.", ServerID])),
    MapTables = [T || {T, _} <- db_loader:map_table_defines()],
    WorldTables = [T || {T, _} <- db_loader:world_table_defines()],
    ChatTables = [T || {T, _} <- db_loader:chat_table_defines()],
    LoginTables = [T || {T, _} <- db_loader:login_table_defines()],
    case file:read_file_info(FilePath) of
        {ok, _} ->
            [SkipTablesTmp] = common_config_dyn:find(merge, skip_tables),
            SkipTables = SkipTablesTmp ++ MapTables ++ WorldTables ++ 
                ChatTables ++ LoginTables,
            case mnesia:restore(FilePath, [{skip_tables, SkipTables}]) of
                {atomic, _} ->
                    ?LOG("~ts:~p~n", ["还原数据成功", ServerID]);
                {aborted, Error} ->
                    ?LOG("~ts:~p ~p ~n", ["还原区服数据出错", ServerID, Error]),
                    timer:sleep(200),
                    init:stop()
            end;
        {error, Error} ->
            ?LOG("~ts:~s ~p~n", ["读取区服数据文件出错", FilePath, Error]),
            timer:sleep(200),
            init:stop(),
            ignore
    end.

start_mnesia() ->
	os:cmd("rm -rf /data/database/merge_data"),
	mnesia:start(),
	mnesia:change_table_copy_type(schema, node(), disc_copies),
	mnesia:wait_for_tables(mnesia:system_info(local_tables), infinity),
	lists:foreach(
	  fun({Tab, Definition}) ->
			  mnesia:create_table(Tab, Definition)
	  end, mgeed_mnesia:table_defines()),
	ok.

start_mnesia_slave() ->
    mnesia:start().

make_global_name(ServerID) ->
    lists:concat(["merge_server_", ServerID]).
    	
%% 从配置文件读取代理商的名字
get_agent_name() ->
    [AgentName] = common_config_dyn:find(merge, agent_name),
    AgentName.


