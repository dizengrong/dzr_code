%%%-------------------------------------------------------------------
%%% @author  bisonwu
%%% @copyright (C) 2010, 
%%% @doc
%%%     common_general_log_server 节点中通用的日志服务器
%%%     对于数据量不大的日志，都可以使用该log_server
%%% @end
%%% Created : 23 Nov 2010 by  <>
%%%-------------------------------------------------------------------
-module(common_general_log_server).
-behaviour(gen_server).

-export([start/1,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([
         log_exchange/1,
         log_letter/1,
         log_boss/1,
         log_trading/1,
         log_personal_ybc/1,
         log_family_ybc/1,
         log_user_offline/1,
         log_conlogin/1,
         log_act_benefit/1,
         log_hero_fb/1,
         log_vip_pay/1,
         log_role_level/1,
         log_role_jingjie/1,
         log_role_grow/1,
         log_scene_war_fb/1,
         log_arena_result/1,
         log_fb_drop_thing/1,
         log_rankreward/1,
         log_warofking_fb/1,
         log_warofmonster_fb/1,
         log_bigpve_fb/1,
         log_spring_fb/1,
		 log_nationbattle_fb/1,
		 log_arenabattle_fb/1,
         log_examine_fb/1,
         log_mine_fb/1,
         log_jingjie_skill_operate/1,
		 log_fashion_evolve/1,
		 log_logout/1,
		 log_use_score/1,
		 log_skill_action/1,
         log_tower_fb/1
        ]).

-export([
		 log_rnkm/1,
		 log_random_mission/1
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").

%%定时发消息进行持久化
-define(DUMP_INTERVAL, 30 * 1000).
-define(MAX_DUMP_RECORD_COUNT, 500).
-define(MSG_DUMP_LOG, msg_dump_log).


%% ====================================================================
%% API functions
%% ====================================================================

-define(SEND_LOG(),
        Type = element(1,LogRecord),
        erlang:send(?MODULE, {log, Type, LogRecord})).

-define(LOG_TYPE_LIST,[
                       %%日常福利的日志
                       {r_act_benefit_log,t_log_activity_benefit,
                            record_info(fields, r_act_benefit_log)},
                       %%连续登陆奖励的日志
                       {r_conlogin_log,t_log_conlogin,
                            record_info(fields, r_conlogin_log)},
                       %%玩家升级的日志
                       {r_role_level_log,t_log_role_level,
                            record_info(fields, r_role_level_log)},
                       %%玩家境界的日志
                       {r_role_jingjie_log,t_log_role_jingjie,
                            record_info(fields, r_role_jingjie_log)},
                       %%玩家培养的日志
                       {r_role_grow_log,t_log_role_grow,
                            record_info(fields, r_role_grow_log)},
                       %%BOSS状态的日志
                       {r_log_boss_state,t_log_boss_state,
                        [boss_id,boss_type,boss_name,boss_state,map_id,special_id,mtime,drop_item,last_hurt_player,ext]},
                       %%师徒模块的日志
                       {r_educate_fb_role_log,t_log_role_educate,
                        [faction_id,role_id,role_name,leader_role_id,leader_role_name,
                         monster_level,start_time,status,end_time,count,times,lucky_count,dead_times]},
                       {r_educate_fb_log,t_log_educate,
                        [faction_id,leader_role_id,leader_role_name,monster_level,
                        start_time,status,end_time,count,in_role_ids,in_role_names,out_role_ids,
                        in_number,out_number,dead_times]},
                       %%P2P交易的日志
                       {r_exchange_log,t_log_exchange,
                        record_info(fields, r_exchange_log)},
                       %%宗族拉镖的日志
                       {r_family_ybc_log,t_log_family_ybc,
                        [ybc_no,family_id,mtime,content]},
                       %%宗族拉镖
                       {r_letter_log,t_log_letter,
                        [role_id, role_name, target_role_id, target_role_name, goods, time]
                       },
                       %%大乘期征途副本的日志
                       {r_hero_fb_log,t_log_hero_fb,
                        [role_id, role_name, faction_id, fb_id, start_time, end_time, status]
                       },
					   %%上古战场的日志
                       {r_nationbattle_fb_log,t_log_nationbattle_fb, record_info(fields,r_nationbattle_fb_log)},
                       
					   %%战神坛的日志
                       {r_arenabattle_fb_log,t_log_arenabattle_fb, record_info(fields,r_arenabattle_fb_log)},
                       
                       %%王座争霸战的日志
                       {r_warofking_fb_log,t_log_warofking_fb, record_info(fields,r_warofking_fb_log)},
                       
                       %%怪物攻城战的日志
                       {r_warofmonster_fb_log,t_log_warofmonster_fb, record_info(fields,r_warofmonster_fb_log)},
					   
					   %%封魔殿			   
                       {r_bigpve_fb_log,t_log_bigpve_fb, record_info(fields,r_bigpve_fb_log)},
                       
                       %%温泉               
                       {r_spring_fb_log,t_log_spring_fb, record_info(fields,r_spring_fb_log)},
					   
                       %%通天副本的日志
                       {r_tower_fb_log,t_log_tower_fb,
                        [role_id, role_name, faction_id, fb_id, start_time, end_time, status]
                       },
                       %%个人拉镖的日志
                       {r_personal_ybc_log,t_log_personal_ybc,
                        [role_id,start_time,ybc_color,final_state,end_time]
                       },
                       %%场景副本的日志
                       {r_scene_war_fb_log,t_log_scene_war,
                        [role_id,role_name,faction_id,level,team_id,status,times,
                         start_time,end_time,fb_id,fb_seconds,fb_type,fb_level,dead_times,
                         in_number,out_number,in_role_ids,in_role_names,out_role_ids,
                         monster_born_number,monster_dead_number]
                       },
                       %%场景副本采集的日志
                       {r_scene_war_fb_log_collect,t_log_scene_war_collect,
                        [fb_id,fb_seconds,collect_id,collect_number]
                       },
                       %%商贸日志
                       {r_role_trading_log,t_log_role_trading,
                        [role_id,role_name,role_level,faction_id,family_id,family_name,
                         base_bill,bill,max_bill,trading_times,status,start_time,last_bill,
                         family_money,family_contribution,end_time,reward_silver,reward_silver_bind]
                       },
                       %%玩家离线的日志
                       {r_user_offline,t_log_user_offline,
                        [account_name, offline_time, offline_reason_no]
                       },
                       %%vip开通续期日志
                       {r_vip_pay_log,t_log_vip_pay,
                        [role_id, pay_type, pay_time, is_first]
                       },
                       %% 记录竞技场的结果日志
                       {r_arena_result_log,t_log_arena_result,
                            record_info(fields, r_arena_result_log)},
                       %% 记录副本掉落物品
                       {r_fb_drop_thing_log,t_log_fb_drop_thing,
                            record_info(fields, r_fb_drop_thing_log)},
                       
                       %% 检验副本日志
                       {r_examine_fb_log,t_log_examine_fb,
                        record_info(fields,r_examine_fb_log)},
                       %% 晶矿副本日志
                       {r_mine_fb_log,t_log_mine_fb,
                        record_info(fields,r_mine_fb_log)},
                       
                       %% 排行榜奖励的日志
                       {r_rankreward_log,t_log_rankreward,
                        record_info(fields,r_rankreward_log)},
					   %% 境界技能操作日志
                       {r_role_jingjie_skill_operate_log,t_log_role_jingjie_skill_operate,
                        record_info(fields,r_role_jingjie_skill_operate_log)},
					   %%时装法宝进阶日志
						{r_fashion_evolve_log,t_log_fashion_evolve, record_info(fields,r_fashion_evolve_log)}, 
						%% 封神榜日志
                       {r_rnkm_log,t_log_rnkm,
                        record_info(fields,r_rnkm_log)},
					   				%% 闯关日志
                       {r_random_mission_log,t_log_random_mission,
                        record_info(fields,r_random_mission_log)},
					   	%%积分日志
                       {r_score_use_log,t_log_use_score,
                        record_info(fields,r_score_use_log)},
						%%技能日志
             		   {r_skill_action_log,t_log_skill_action,
                        record_info(fields,r_skill_action_log)},
						
						%%下线日志
                       {r_logout_log,t_log_logout,
                        record_info(fields,r_logout_log)}
                      ]).  

log_conlogin(LogRecord) when is_record(LogRecord, r_conlogin_log) ->
    ?SEND_LOG().

log_act_benefit(LogRecord) when is_record(LogRecord,r_act_benefit_log)->
    ?SEND_LOG().

log_exchange(LogRecord) when is_record(LogRecord,r_exchange_log) ->
    ?SEND_LOG().

log_family_ybc(LogRecord) when is_record(LogRecord,r_family_ybc_log)->
    ?SEND_LOG().

log_letter(LogRecord) when is_record(LogRecord,r_letter_log) ->
    ?SEND_LOG().

log_trading(LogRecord) when is_record(LogRecord,r_role_trading_log)->
    ?SEND_LOG().

log_boss(LogRecord) when is_record(LogRecord,r_log_boss_state)->
    ?SEND_LOG().

log_hero_fb(LogRecord) when is_record(LogRecord,r_hero_fb_log) ->
    ?SEND_LOG().

log_personal_ybc(LogRecord) when is_record(LogRecord,r_personal_ybc_log)->
    ?SEND_LOG().
    
log_user_offline(#r_user_offline{account_name=undefined}) ->
    ignore;
log_user_offline(LogRecord) when is_record(LogRecord,r_user_offline) ->
    ?SEND_LOG().

log_scene_war_fb(LogRecord) when is_record(LogRecord,r_scene_war_fb_log) ->
    ?SEND_LOG();
log_scene_war_fb(LogRecord) when is_record(LogRecord,r_scene_war_fb_log_collect) ->
    ?SEND_LOG().
    
log_vip_pay(LogRecord) when is_record(LogRecord,r_vip_pay_log)->
    ?SEND_LOG().

log_role_level(LogRecord) when is_record(LogRecord,r_role_level_log)->
    ?SEND_LOG().

log_role_jingjie(LogRecord) when is_record(LogRecord,r_role_jingjie_log)->
    ?SEND_LOG().

log_role_grow(LogRecord) when is_record(LogRecord,r_role_grow_log)->
    ?SEND_LOG().

log_fb_drop_thing(LogRecord) when is_record(LogRecord,r_fb_drop_thing_log)->
    ?SEND_LOG().

log_arena_result(LogRecord) when is_record(LogRecord,r_arena_result_log)->
    ?SEND_LOG().

log_rankreward(LogRecord) when is_record(LogRecord,r_rankreward_log)->
    ?SEND_LOG().

log_warofking_fb(LogRecord) when is_record(LogRecord,r_warofking_fb_log)->
    ?SEND_LOG().

log_warofmonster_fb(LogRecord) when is_record(LogRecord,r_warofmonster_fb_log)->
    ?SEND_LOG().

log_bigpve_fb(LogRecord) when is_record(LogRecord,r_bigpve_fb_log)->
    ?SEND_LOG().

%%记录温泉副本日志
log_spring_fb(LogRecord) when is_record(LogRecord,r_spring_fb_log)-> 
    ?SEND_LOG().

log_tower_fb(LogRecord) when is_record(LogRecord,r_tower_fb_log) ->
    ?SEND_LOG().

log_nationbattle_fb(LogRecord) when is_record(LogRecord,r_nationbattle_fb_log)->
    ?SEND_LOG().

log_arenabattle_fb(LogRecord) when is_record(LogRecord,r_arenabattle_fb_log)->
    ?SEND_LOG().

log_examine_fb(LogRecord) when is_record(LogRecord,r_examine_fb_log)->
    ?SEND_LOG().

log_mine_fb(LogRecord) when is_record(LogRecord,r_mine_fb_log)->
    ?SEND_LOG().

log_jingjie_skill_operate(LogRecord) when is_record(LogRecord,r_role_jingjie_skill_operate_log)->
    ?SEND_LOG().

log_rnkm(LogRecord) when is_record(LogRecord,r_rnkm_log)->
    ?SEND_LOG().
 
log_random_mission(LogRecord) when is_record(LogRecord,r_random_mission_log)->
    ?SEND_LOG().
%% 时装法宝日志记录
log_fashion_evolve(LogRecord) when is_record(LogRecord,r_fashion_evolve_log)-> 
    ?SEND_LOG(). 

%% 积分日志记录
log_use_score(LogRecord) when is_record(LogRecord,r_score_use_log)-> 
    ?SEND_LOG(). 

%% 技能操作日志记录
log_skill_action(LogRecord) when is_record(LogRecord,r_skill_action_log)-> 
    ?SEND_LOG(). 

log_logout(LogRecord) when is_record(LogRecord,r_logout_log)->
    ?SEND_LOG().

%% ====================================================================
%% External functions
%% ====================================================================

start(Super) ->
    {ok,_} = supervisor:start_child(Super, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, brutal_kill, worker, [?MODULE]}).
    

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG),
    {ok, []}.
 
 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

-define(DO_DUMP_FIELDS_LOG(Tab,FieldNames),
        try
          QueuesInsert = lists:reverse(Queues),
          mod_mysql:batch_insert(Tab, FieldNames, QueuesInsert, ?MAX_DUMP_RECORD_COUNT),
          put(Key, [])
        catch
            _:Reason->
              ?ERROR_MSG("insert to table:~w error,Key=~w,reason:~w  stack:~w",[Tab,Key,Reason,erlang:get_stacktrace()])
        end).

%% 记录信件交易日志
do_handle_info({log,Type=r_letter_log, LetterLog}) ->
    LetterLog2 = gen_letter_log(LetterLog),
    [r_letter_log|T] = tuple_to_list(LetterLog2),

    common_misc:update_dict_queue(Type, T);

%% boss的记录(respawn,dead)
do_handle_info({log,Type=r_log_boss_state,BossDetailInfo})->
    ItemJson = gen_boss_log_list(BossDetailInfo),
    BossLogList = BossDetailInfo#r_log_boss_state{
                        drop_item = ItemJson                                               
                    },
    [r_log_boss_state|T] = tuple_to_list(BossLogList),
    common_misc:update_dict_queue(Type, T);

%% 普通日志的实现
do_handle_info({log, Type, LogRecord}) ->
    [_H|T] = tuple_to_list(LogRecord),
    common_misc:update_dict_queue(Type, T);


% do_handle_info(?MSG_DUMP_LOG) ->
    
    % lists:foreach(fun(E)->
    %                   Key = element(1,E),
    %                   case get(Key) of
    %                       undefined -> ignore;
    %                       [] -> ignore;
    %                       Queues -> 
    %                           do_dump_log(Key,Queues)
    %                   end
    %               end, ?LOG_TYPE_LIST),
    % erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);

do_handle_info(_Info) ->ok.
    % ?ERROR_MSG("unknow msg, info: ~w", [Info]).


% do_dump_log(Key,Queues)->
%     {Key,Tab,FieldNames} = lists:keyfind(Key, 1, ?LOG_TYPE_LIST),
%     ?DO_DUMP_FIELDS_LOG(Tab,FieldNames).



%%%===================================================================
%%% Internal functions
%%%===================================================================

%%@doc 目的是获取目标发信人的role_id
gen_letter_log(LetterLog) ->
    #r_letter_log{role_id=RoleID1, role_name=RoleName, target_role_name=TargetRoleName1, target_role_id=TargetRoleID} = LetterLog,
    RoleIDReal = case (RoleID1=:=undefined) orelse(RoleID1=:=0) of
                     true->
                         common_misc:get_roleid(RoleName);
                     _->
                         RoleID1
                 end,
    TargetRoleNameReal = case (TargetRoleName1=:=undefined) orelse (TargetRoleName1=:="") of
                             true->
                                 common_misc:get_dirty_rolename(TargetRoleID);
                             _->
                                 TargetRoleName1
                         end,
    
    LetterLog#r_letter_log{ role_id=RoleIDReal,target_role_name=TargetRoleNameReal }.

gen_boss_log_list(BossDetailInfo)->
    DropItems = BossDetailInfo#r_log_boss_state.drop_item,
    if is_list(DropItems) andalso length(DropItems) > 0 ->
	    ItemList = [ [{item_type,Ele#r_log_boss_item_drop.item_type},{item_typeid,Ele#r_log_boss_item_drop.item_typeid},{color,Ele#r_log_boss_item_drop.color},{quality,Ele#r_log_boss_item_drop.quality},{num,Ele#r_log_boss_item_drop.num}]  ||  Ele <- DropItems],
	    ItemJson = common_json2:to_json(ItemList),
	    ItemJson;
       true->
	    ""
    end.


    
