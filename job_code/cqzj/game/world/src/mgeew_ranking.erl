%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :排行榜
%%%
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(mgeew_ranking).

-behaviour(gen_server).
-include("mgeew.hrl").

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([
         start/0,
         start_link/0,
         cmp/1,
         reload_config/0,
         send_ranking_cofig/1,
         send_activity_prize/4,
         send_ranking_activity/2,
         create_equip/8,
		 init_all_module2/1,
		 get_rankid_by_module_name/1,
		 get_next_ten_minute_diff/2
        ]).


-define(RERESH_INTERVAL,1).     %%间隔刷新
-define(RERESH_IMMEDIATE,2).    %%立即刷新
-define(RERESH_SNAPSHOT,3).     %%镜像刷新

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 transient, brutal_kill, worker, 
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).


reload_config() ->
    case global:whereis_name(?MODULE) of
        undefined ->
            mgeew_ranking:start();
        Pid ->
            Pid ! reload_config
    end.


cmp([]) ->
    true;
cmp([{Element1,Element2}|List]) ->
    case Element1 < Element2 of
        true ->
            true;
        false ->
            case Element1 > Element2 of
                true ->
                    false;
                false ->
                    cmp(List)
            end
    end.


send_ranking_cofig(RoleID) ->
    global:send(?MODULE,{send_ranking_to_role,RoleID}).


send_activity_prize(_RoleID,[],_Title,_Text) ->
    ok;
send_activity_prize(RoleID,[#r_rank_prize_goods{type_id=TypeID,num=Number,bind=Bind,last_time=LastTime}|List],Title,Text) ->
    case LastTime of
        0 ->
            StartTime = 0,
            EndTime = 0;
        _ ->
            StartTime = common_tool:now(),
            EndTime = StartTime + LastTime
    end,
    case common_config_dyn:find(item,TypeID) of
        [] ->
            case common_config_dyn:find(equip,TypeID) of
                [] ->
                     create_stone(RoleID,Number,TypeID,Bind,StartTime,EndTime,Title,Text),
                     send_activity_prize(RoleID,List,Title,Text);
                _ ->
                     create_equip(RoleID,Number,TypeID,Bind,StartTime,EndTime,Title,Text),
                     send_activity_prize(RoleID,List,Title,Text)
            end;
        _ ->
            create_item(RoleID,Number,TypeID,Bind,StartTime,EndTime,Title,Text), 
            send_activity_prize(RoleID,List,Title,Text)
    end.
   
     
create_stone(RoleID,Number,TypeID,Bind,StartTime,EndTime,Title,Text) ->
    Info = #r_stone_create_info{role_id=RoleID,bag_id=0,num=Number,
                                typeid=TypeID,bind=Bind,start_time=StartTime,end_time=EndTime},
    case common_bag2:creat_stone(Info) of
        {ok,GoodsList} ->
            NewGoodsList = [ G#p_goods{id=1,bagposition=1,bagid=9999}||G<-GoodsList ],
            common_letter:sys2single(RoleID,Title,Text,NewGoodsList);
        {error,Reason}->
            ?ERROR_MSG("create_goods error,Reason=~w",[Reason])
    end.
create_equip(RoleID,Number,TypeID,Bind,StartTime,EndTime,Title,Text) ->
    Info = #r_equip_create_info{role_id=RoleID,bag_id=0,num=Number,color=1,
                                typeid=TypeID,bind=Bind,start_time=StartTime,end_time=EndTime},
    case common_bag2:creat_equip_without_expand(Info) of
        {ok,GoodsList} ->
            NewGoodsList = [ G#p_goods{id=1,bagposition=1,bagid=9999}||G<-GoodsList ],
            common_letter:sys2single(RoleID,Title,Text,NewGoodsList);
        {error,Reason}->
            ?ERROR_MSG("create_goods error,Reason=~w",[Reason])
    end.
create_item(RoleID,Number,TypeID,Bind,StartTime,EndTime,Title,Text) ->
     Info = #r_item_create_info{role_id=RoleID, bag_id=0,  num=Number, typeid=TypeID, bind=Bind,
                               start_time=StartTime, end_time=EndTime},
    case common_bag2:create_item(Info) of
        {ok,GoodsList} ->
            NewGoodsList = [ G#p_goods{id=1,bagposition=1,bagid=9999}||G<-GoodsList ],
            common_letter:sys2single(RoleID,Title,Text,NewGoodsList);
        {error,Reason}->
            ?ERROR_MSG("create_goods error,Reason=~w",[Reason])
    end.

%%======================================================
init([]) ->
    load_ranking_config(),
    init_all_module(),
    {_,{_H,M,S}} = erlang:localtime(),
    %%每十分钟检测一次，并且根据当前时间计算下次检测时间
	?DBG(get_next_ten_minute_diff(M,S)),
    erlang:send_after( get_next_ten_minute_diff(M,S), self(), loop),
    {ok, none}.


handle_call(Call, _From, State) ->
	Reply = ?DO_HANDLE_CALL(Call, State),
    {reply, Reply, State}.


handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(exit, State) ->
    {stop, bad, State};

handle_info({rank,ModuleName}, State) ->
    ModuleName:rank(),
    {noreply, State};

handle_info({rank,ModuleName,RankSize}, State) ->
    ModuleName:rank(RankSize),
    {noreply, State};

handle_info({init_all_module2,RankID}, State) ->
	init_all_module2(RankID),
    {noreply, State};

handle_info({debug,Fun,Args}, State) ->
    Ret = apply(Fun,Args),
    ?ERROR_MSG("ret = ~w",[Ret]),
    {noreply, State};
handle_info({reset}, State) ->
	ranking_consume_today:reset_consume_rank(),
	{noreply, State};
handle_info({reward}, State) ->
	send_rank_reward(ranking_consume_today,{0,0}),
{noreply, State};

handle_info({stats_open_activity_data,TypeList}, State) ->
	ModuleName = ranking_role_level,
	ModuleName:rank(),
	Rank1 = get({{ModuleName,?CATEGORY_WARRIOR},ranking_info_list}),
	Rank2 = get({{ModuleName,?CATEGORY_HUNTER},ranking_info_list}),
	Rank3 = get({{ModuleName,?CATEGORY_RANGER},ranking_info_list}),
	Rank4 = get({{ModuleName,?CATEGORY_DOCTOR},ranking_info_list}),
	global:send(mgeew_open_activity,{stats_open_activity_data,lists:append([Rank1,Rank2,Rank3,Rank4]),TypeList}),
    {noreply, State};

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%%获取下一个整数的10分钟的时间差（ms）
get_next_ten_minute_diff(M,S)->
    (9 - (M rem 10))*60*1000 + (60-S)*1000.

get_real_module_name(ModuleName)->
    case ModuleName of
        {ranking_role_level,1}->
            ranking_role_level;
        {ranking_role_level,_} ->
            nil;
        _ ->
            ModuleName
    end.
do_handle_call({ModuleName}) ->
	ModuleName:get_rank() ;
do_handle_call(_) ->
    error.

do_handle_info(loop) ->
    RankIDList = get(rank_id_list),
    {_,{H,M,S}} = erlang:localtime(),
    erlang:send_after( get_next_ten_minute_diff(M,S), self(), loop),
    lists:foreach(
      fun(RankID) ->
			  timer:sleep(10),
              {RankInfo,ModuleName} = get({rank_info,RankID}),
              #p_ranking{refresh_type=RefreshType,refresh_interval=RefreshInterval,capacity=Capacity} = RankInfo,
              case RefreshType of
                  ?RERESH_INTERVAL ->
                      case (H*60+M) rem RefreshInterval of
                          0 ->
                              case get_real_module_name(ModuleName) of
                                  nil->
                                      ignore;
								  ranking_fighting_power ->
                                      ?TRY_CATCH( ranking_fighting_power:rank(Capacity),Err1 );
                                  RealModuleName ->
                                      ?TRY_CATCH( RealModuleName:rank(),Err1 )
                              end;
                          _ ->
                              nil
                      end;
                  ?RERESH_IMMEDIATE ->
                      nil;
                  ?RERESH_SNAPSHOT ->
                      %%定时更新镜像数据
                      case {H,M} =:= RefreshInterval of
                          true->
                              ModuleName:snapshot();
                          _ ->
                              ignore
                      end
              end,
			   send_rank_reward(ModuleName,{H,M})
      end,RankIDList),
	reset_yesterday_rank({0,0}),
	reset_rank({H,M});

%%GM专用，更新所有排行榜
do_handle_info(update_all_rank) ->
    RankIDList = get(rank_id_list),
    lists:foreach(
      fun(RankID) ->
              {_,ModuleName} = get({rank_info,RankID}),
              case get_real_module_name(ModuleName) of
                  nil->
                      ignore;
                  ranking_fighting_power ->
                      ?TRY_CATCH( ranking_fighting_power:rank(50),Err1 );
                  RealModuleName ->
                      ?TRY_CATCH( RealModuleName:rank(),Err2 )
              end
      end,RankIDList);

do_handle_info({rank_activity,ModuleName}) ->
     ModuleName:do_rank_activity();

do_handle_info({ranking_element_update,ModuleName,Info}) ->
    ModuleName:update(Info);


do_handle_info({ranking_handle,ModuleName,Info}) ->
    ModuleName:handle(Info);
do_handle_info({snapshot,ModuleName}) ->
    ModuleName:snapshot();


do_handle_info({send_ranking_to_role,_RoleID}) ->
    ignore;
do_handle_info({get,Key}) ->
	?ERROR_MSG("33333333333333333333==~w",[get(Key)]);
    
    
do_handle_info({_Unique, ?RANKING, _Method, _DataIn, _RoleID, _Pid, _Line}=Info) ->
    do_handle_method(Info);

do_handle_info(reload_config) ->
    load_ranking_config().


terminate(Reason, State) ->
    ?INFO_MSG("terminate : ~w , reason: ~w", [Reason, State]),
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

load_ranking_config() ->
    %%读取每个排行榜的详细信息
    RankInfoList = common_config_dyn:list(rank_info),
    RankIDList = lists:foldl(
                   fun({RankID,[RankInfo,ModuleName]},Acc) ->
                           put({rank_info,RankID},{RankInfo,ModuleName}),
                           [RankID|Acc]
                   end,[],RankInfoList),
    put(rank_id_list,RankIDList).


init_all_module() ->
    RankIDList = get(rank_id_list),
    lists:foreach(
      fun(RankID) ->
              ?TRY_CATCH( init_all_module2(RankID) )
      end,RankIDList).

init_all_module2(RankID) ->
    {RankInfo,ModuleName} = get({rank_info,RankID}),
    case get_real_module_name(ModuleName) of
        nil->
            ignore;
        RealModuleName ->
            ?TRY_CATCH( RealModuleName:init(RankInfo) )
    end.

send_ranking_activity(ActivityKey,List)->
    common_activity:send_special_activity({stat_ranking,{ActivityKey,List}}).


do_handle_method({_, ?RANKING, ?RANKING_GET_RANK, _, _RoleID, _Pid, _Line}=Info) ->
    do_ranking_get_rank(Info);
do_handle_method({_, ?RANKING, ?RANKING_EQUIP_JOIN_RANK, _, _RoleID, _Pid, _Line}=Info) ->
    do_ranking_equip_join_rank(Info);
do_handle_method({_, ?RANKING, ?RANKING_ROLE_ALL_RANK, _, _RoleID, _Pid, _Line}=Info) ->
    do_ranking_role_all_rank(Info);
do_handle_method({_, ?RANKING, ?RANKING_PET_JOIN_RANK, _, _RoleID, _Pid, _Line}=Info) ->
    do_ranking_pet_join_rank(Info);
do_handle_method(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


%%@interface 
do_ranking_get_rank({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_ranking_get_rank_tos{rank_id=RankID} = DataIn,
    case get({rank_info,RankID}) of
        {_RankInfo,ModuleName} ->
            case ModuleName of
                {ranking_role_level,Category} ->
                    ranking_role_level:send_ranking_info(Unique, Module, Method, RoleID, PID, RankID,Category);
                _ ->
                    ModuleName:send_ranking_info(Unique, Module, Method, RoleID, PID, RankID)
            end;
        undefined ->
            ?ERROR_MSG("do_ranking_get_rank error,RoleID=~w,DataIn=~w",[RoleID,DataIn])
    end.

%%@interface 
do_ranking_equip_join_rank({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    %% goods_id已经地图路由过来的时候改成了goodsinfo
    #m_ranking_equip_join_rank_tos{rank_id = RankID,goods_id = GoodsInfo} = DataIn,
    
    case check_equip_can_rank(GoodsInfo) of
        {error, Reason} ->
            R2 = #m_ranking_equip_join_rank_toc{reason = Reason, rank_id = RankID},
            ?UNICAST_TOC(R2);
        ok ->
            do_ranking_equip_join_rank_2({Unique, Module, Method, DataIn, RoleID, PID, _Line})
    end.

check_equip_can_rank(GoodsInfo) ->
    case common_config_dyn:find(equip, GoodsInfo#p_goods.typeid) of 
        [EquipBaseInfo] when EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_JINGJIE ->
            {error, ?_LANG_RANKING_EQUIP_IS_JINGJIE};
        [EquipBaseInfo] when EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_SHENQI ->
            {error, ?_LANG_RANKING_EQUIP_IS_SHENQI};
        [EquipBaseInfo] when EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MARRY ->
            {error, ?_LANG_RANKING_EQUIP_IS_MARRY};
        _ -> 
            ok
    end.

do_ranking_equip_join_rank_2({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_ranking_equip_join_rank_tos{rank_id = RankID,goods_id = GoodsInfo} = DataIn,
    case get({rank_info,RankID}) of
        {_RankInfo,ModuleName} ->
            case ModuleName:update({GoodsInfo,RoleID}) of
                ok ->
                    Record = #m_ranking_equip_join_rank_toc{succ = true,rank_id = RankID};
                {fail,Reason} ->
                    Record = #m_ranking_equip_join_rank_toc{reason = Reason, rank_id = RankID}
            end;
        undefined ->
            Record = #m_ranking_equip_join_rank_toc{reason = ?_LANG_RANKING_NOT_OPEN, rank_id = RankID}
    end,
    ?UNICAST_TOC(Record).
    
%%@interface 
do_ranking_role_all_rank(Info)->
    mod_role_all_rank:send_role_all_ranking_info(Info).

%%@interface 
do_ranking_pet_join_rank({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_ranking_pet_join_rank_tos{rank_id = RankID,pet_id = PetID} = DataIn,
    case get({rank_info,RankID}) of
        {_RankInfo,ModuleName} ->
            case ModuleName:update({PetID,RoleID}) of
                ok ->
                    Record = #m_ranking_pet_join_rank_toc{succ = true,rank_id = RankID};
                {fail,Reason} ->
                    Record = #m_ranking_pet_join_rank_toc{reason = Reason, rank_id = RankID}
            end;
        undefined ->
            self() ! {send_ranking_to_role,RoleID},
            
            Record = #m_ranking_pet_join_rank_toc{reason = ?_LANG_RANKING_NOT_OPEN, rank_id = RankID}
    end,
    ?UNICAST_TOC(Record).

get_rankid_by_module_name(ModuleName) ->
	RankInfoList = common_config_dyn:list(rank_info),
	case lists:filter(fun({_RankID,[_RankInfo,RankModuleName]})->
							  RankModuleName =:= ModuleName 
					  end, RankInfoList) of
		[] ->
			?ERROR_MSG("get_rankid_by_module_name not_found,ModuleName=:~w",[ModuleName]);
		[{RankID,[_RankInfo,_RankModuleName]}] ->
			RankID
	end.

send_rank_reward(ModuleName,{0,0}) ->
	case ModuleName of
		ranking_consume_today ->
			ranking_consume_today:send_reward_letter();
		_ ->
			ignore
	end;
send_rank_reward(_,_) ->
	ignore.

reset_yesterday_rank({0,0}) ->
	ranking_consume_yesterday:reset_consume_rank();
reset_yesterday_rank(_) ->
	ignore.

reset_rank({_,0}) ->
	?DBG(),
	ranking_consume_today:reset_consume_rank();
reset_rank(_) ->
	ignore.
	
