%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @doc 宗族创建管理进程
%%%-------------------------------------------------------------------
-module(mod_family_manager).

-behaviour(gen_server).

-include("mgeew.hrl").

%% API
-export([
         start/0,
         start_link/0,
         register_family/1,
         get_new_family_id/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


-record(state, {}).

-define(all_family_list, all_family_list).

-define(REGENE_RECOMMAND_USER_TICKET, 5 * 60 * 1000).


%%10秒更新一次宗族列表
-define(REGENE_FAMILY_LIST, 10 * 1000).

%%三小时检查一次宗族在线人数,并作相应处理
-define(FAMILY_ONLINECHK_INTERVAL,1000*60*60*3).
-define(REDUCE_SILVER_FOR_CREATE_FAMILY,reduce_silver_for_create_family).

%%默认宗族地图中的初始化田地大小
-define(DEFAULT_FARM_SIZE,10).

-define(donate_gold,1).
-define(donate_silver,2).
-define(donate_token,3).%%家族令
%% 创建宗族信件

%%%===================================================================
%%% API
%%%===================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {mod_family_sup,
                                                 {mod_family_sup, start_link, []},
                                                 permanent, infinity, supervisor, [mod_family_sup]}),
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE, 
                                                 {?MODULE, start_link, []},
                                                 transient, 3000000, worker, [?MODULE]}).

%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).


register_family(FamilyID) ->
    case FamilyID > 0 of
        true ->
            case supervisor:start_child(mod_family_sup, 
                                        {lists:concat(["family_", FamilyID]), 
                                         {mod_family, start_link, [FamilyID]},
                                         transient, 300000, worker, [mod_family]}) of
                {ok, _PID} ->
                    ?DEBUG("~ts:~w", ["宗族进程启动成功", FamilyID]),
                    ok;
                {error,{already_started,_}} ->
                    ?DEBUG("~ts:~w", ["宗族进程已经启动", FamilyID]),
                    ok;
                {error, Reason} ->
                    ?ERROR_MSG("~ts:~w", ["启动宗族进程失败", Reason]),
                    {error, Reason}
            end;
        false ->
            ignore
    end.

%%--------------------------------------------------------------------
init([]) ->
    case db:transaction(fun() -> t_init_family_counter() end) of
        {atomic, ok} ->
            ets:new(ets_family_join_history, [named_table, set, public]),
            gene_family_list([1, 2, 3]),
            ok = common_config_dyn:reload(family_ybc_money),
            erlang:send_after(1000, self(), gene_recommend_user),
            {ok, #state{}};
        {aborted, Reason} ->
            ?ERROR_MSG("", ["初始化宗族计数表失败", Reason]),
            {stop, Reason}
    end.



%%@doc 获取新的家族ID
get_new_family_id()->
    %% DB_FAMILY_COUNTER 这个表的数据可能有误，我们加上自我修复
    [#r_family_counter{value=LID}] = db:read(?DB_FAMILY_COUNTER, 1, write),
    
    List = db:dirty_match_object(?DB_FAMILY,#p_family_info{_='_'}),
    FamilyIdList = [ TID ||#p_family_info{family_id=TID}<-List ],
    MaxFamilyID = case FamilyIdList of
                      []-> 0;
                      _ -> lists:max(FamilyIdList)
                  end,
    
    if
        LID>=MaxFamilyID-> 
            LID + 1;
        true->
            MaxFamilyID + 1
    end.

%%获取人数最多、自动招收的家族id
do_auto_join_family(RoleID) ->
	[#p_role_base{faction_id = RoleFactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
	FamilyKeyList = db:dirty_all_keys(?DB_FAMILY),
	case FamilyKeyList of
		[] ->
			%%没有家族，则创建家族，这里需要通知前端当前适合的家族不存在，所以返回[]
			[];
		_ ->
			%%找出不满人的并且自动招收的家族列表LL
			G = fun(FamilyKey) ->
					[#p_family_info{cur_members = CM, level = LV, is_auto_join = IS, faction_id = FamilyFactionID}] = db:dirty_read(?DB_FAMILY, FamilyKey),
					#r_family_config{max_member = MM} = cfg_family:level_config(LV),
					MM > CM andalso IS == true andalso RoleFactionID == FamilyFactionID
				end,
			LL = lists:filter(G, FamilyKeyList),
			%%找出不满人的家族的人数以及排名
			F = fun(FamilyKey) ->
					[#p_family_info{cur_members = CM, level = LV}] = db:dirty_read(?DB_FAMILY, FamilyKey),
					{FamilyKey, CM, LV}
				end,
			L = lists:map(F, LL),
			%%判断符合条件的家族数量
			case length(L) of
				0 ->	%%没有返回[]
					[];
				1 ->	%%只有一个则直接加入
					[{FO, _CMO, _LVO}] = L,
					FO;
				_ ->
					%%找出人数最多的家族，家族人数相同则选等级最高的家族
					[{F1, CM1, LV1}, {F2, CM2, LV2}|_] = lists:reverse(lists:keysort(2, L)),
					case CM1 =:= CM2 of
						true ->
							%%两个家族的人数一样，判断排名
							case LV1 > LV2 of
								true ->
									F1;
								false ->
									F2
							end;
						false ->
							%%两个家族的人数不一样，加入家族F1
							F1
					end
			end
	end.		

t_init_family_counter() ->
    case db:read(?DB_FAMILY_COUNTER, 1, write) of
        [] ->
            db:write(?DB_FAMILY_COUNTER, #r_family_counter{id=1, value=1}, write);
        _ ->
            ok
    end.


gene_family_list(FactionIDList) ->
    gene_family_list_no_loop(FactionIDList),
    erlang:send_after(?REGENE_FAMILY_LIST, self(), gene_family_list).

gene_family_list_no_loop(FactionIDList) ->
    lists:foreach(
      fun(FactionID) ->
              SqlResult = mod_mysql:select(io_lib:format("select family_id, family_name, create_role_id, create_role_name, " ++ 
                                                              "owner_role_id," ++
                                                              "owner_role_name, faction_id, active_points, cur_members, level from " ++
                                                              "t_family_summary where faction_id=~w " ++ 
                                                              "order by active_points desc, level desc", [FactionID])),
			  case SqlResult of
				  {ok, FamilyList} ->
			  			FamilyList2 = [ transform_family_fields(Family) || Family<-FamilyList ],
              			put(lists:concat(["faction_family_list_", FactionID]), FamilyList2);
				  {error,Reason}->
					  	?WARNING_MSG("~ts: ~w", ["获取宗族排行榜数据出错", Reason])
			  end
			  
      end, FactionIDList).

transform_family_fields(FamilyFields) when is_list(FamilyFields)->
    [FamilyID, FamilyName, CreateRoleID, CreateRoleName, OwnerRoleID, OwnerRoleName,
     FactionID, ActivePoints, CurMembers, Level] = FamilyFields,
    #p_family_summary{id=FamilyID, name=FamilyName, create_role_id=CreateRoleID, 
                      create_role_name=CreateRoleName, owner_role_id=OwnerRoleID,
                      owner_role_name=OwnerRoleName, cur_members=CurMembers, 
                      faction_id=FactionID, level=Level, active_points=ActivePoints}.


%%--------------------------------------------------------------------
handle_call(hot_create_ets, _From, State) ->
    Reply = ets:new(ets_family_join_history, [named_table, set, public]),
    {reply, Reply, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.


%%--------------------------------------------------------------------
handle_info({'EXIT', PID, Reason}, State) ->
    ?ERROR_MSG("~ts: ~w, ~w", ["宗族管理进程收到exit消息", PID, Reason]),
    {noreply, State};
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.


%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.


%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

-define(FAMILY_MODULE_ROUTER(TheModule),do_handle_info({Unique, TheModule, Method, Record, RoleID, PID, Line}) ->
    #p_role_base{family_id=FamilyID} = mod_role_tab:get({?role_base, RoleID}),
    router_to_family_process(FamilyID, {Unique, TheModule, Method, Record, RoleID, PID, Line})).

do_handle_info({Unique, Module, ?FAMILY_LIST, Record, RoleID, PID, Line}) 
  when is_record(Record, m_family_list_tos) ->
    do_list(Unique, Module, ?FAMILY_LIST, Record, RoleID, PID, Line);

%%创建宗族
do_handle_info({Unique, Module, ?FAMILY_CREATE, Record, RoleID, PID, Line}) 
  when is_record(Record, m_family_create_tos) ->
    do_create(Unique, Module, ?FAMILY_CREATE, Record, RoleID, PID, Line);

%%申请加入宗族
do_handle_info({Unique, Module, ?FAMILY_REQUEST, Record, RoleID, PID, Line}) 
  when is_record(Record, m_family_request_tos) ->
    #m_family_request_tos{family_id=FamilyID} = Record, 
    
	case db:dirty_read(?DB_FAMILY, FamilyID) of
		[#p_family_info{is_auto_join = IS}] ->
			case IS of
				true ->
					%%家族设置为自动加入，直接加入
					join_family_direct(RoleID, FamilyID);
				false ->
					%%家族设置不是自动加入，调用发送请求接口
					do_request(FamilyID, {Unique, Module, ?FAMILY_REQUEST, Record, RoleID, PID, Line})
			end;
		_ ->
			[]
	end;

%%同意宗族的邀请
do_handle_info({Unique, Module, ?FAMILY_AGREE, Record, RoleID, PID, Line})
  when is_record(Record, m_family_agree_tos) ->
    #m_family_agree_tos{family_id=FamilyID} = Record,
    router_to_family_process(FamilyID, {Unique, Module, ?FAMILY_AGREE, Record, RoleID, PID, Line});

%%设置宗族的自动加入状态
do_handle_info({Unique, Module, ?FAMILY_AUTO_STATE, Record, RoleID, PID, Line})
  when is_record(Record, m_family_auto_state_tos) ->
	#m_family_auto_state_tos{family_id = FamilyID} = Record,
    router_to_family_process(FamilyID, {Unique, Module, ?FAMILY_AUTO_STATE, Record, RoleID, PID, Line});

%%获取宗族活动状态
do_handle_info({Unique, Module, ?FAMILY_ACTIVESTATE, Record, RoleID, PID, Line})
  when is_record(Record, m_family_activestate_tos) ->
    #m_family_activestate_tos{family_id=FamilyID} = Record,
    router_to_family_process(FamilyID, {Unique, Module, ?FAMILY_ACTIVESTATE, Record, RoleID, PID, Line});
%%拒绝宗族邀请
do_handle_info({Unique, Module, ?FAMILY_REFUSE, Record, RoleID, PID, Line})
  when is_record(Record, m_family_refuse_tos) ->
    #m_family_refuse_tos{family_id=FamilyID} = Record,
    router_to_family_process(FamilyID, {Unique, Module, ?FAMILY_REFUSE, Record, RoleID, PID, Line});
%%打开我的宗族面板
do_handle_info({Unique, Module, ?FAMILY_PANEL, Record, RoleID, PID, Line}) 
  when is_record(Record, m_family_panel_tos) ->
    do_panel(Unique, Module, ?FAMILY_PANEL, Record, RoleID, PID, Line);

%%获取某个宗族的详细信息 p_family_info
do_handle_info({Unique,Module,?FAMILY_DETAIL,Record,RoleID,PID,Line})
    when is_record(Record,m_family_detail_tos)->
    do_family_detail(Unique,Module,?FAMILY_DETAIL,Record,RoleID,PID,Line);

%%获取推荐的邀请玩家列表
do_handle_info({Unique, Module, ?FAMILY_CAN_INVITE, _, RoleID, _, Line}) ->
    do_can_invite(Unique, Module, ?FAMILY_CAN_INVITE, RoleID, Line);

%%召唤族员参与宗族boss战
do_handle_info({Unique,_Module,?FAMILY_MEMBER_ENTER_MAP,Record,RoleID,PID,Line}) ->
    ?DEBUG("jojocatcallmember comming ~p",[RoleID]),
    #p_role_base{family_id=FamilyID} = mod_role_tab:get({?role_base, RoleID}),
    router_to_family_process(FamilyID,{Unique,?FAMILY,?FAMILY_MEMBER_ENTER_MAP,Record,RoleID,PID,Line});
%%宗族捐献
do_handle_info({Unique, _Module, ?FAMILY_GET_DONATE_INFO, Record, RoleID, PID, _Line})->
    do_get_donate_info(Unique,Record,RoleID,PID);

%%种植模块
?FAMILY_MODULE_ROUTER( ?PLANT );
%%宗族技能模块
?FAMILY_MODULE_ROUTER( ?FMLSKILL );
%%宗族仓库
?FAMILY_MODULE_ROUTER( ?FMLDEPOT );
%%宗族主模块
?FAMILY_MODULE_ROUTER( ?FAMILY );
%%家庭福利
?FAMILY_MODULE_ROUTER( ?FAMILY_WELFARE );


%%处理异步方式Money接口的返回消息
do_handle_info({?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr, ?REDUCE_SILVER_FOR_CREATE_FAMILY}) ->
    do_reduce_role_silver_for_create_successful(RoleID, RoleAttr);
do_handle_info({?REDUCE_ROLE_MONEY_FAILED, RoleID, Reason, ?REDUCE_SILVER_FOR_CREATE_FAMILY}) ->
    do_reduce_role_silver_for_create_failed(RoleID, Reason);
    

%%成员升级之后的处理
do_handle_info({member_levelup,FamilyID,MemberID,NewLevel})->
    router_to_family_process(FamilyID,{member_levelup,MemberID,NewLevel});

%%处理玩家达到25级的时候自动加入宗族
do_handle_info({auto_join_family, RoleID}) ->
	case do_auto_join_family(RoleID) of
		[] ->
			%%搜索不到能够自动加入的家族，返回信息给前段，前段弹出创建家族界面
			R = #m_family_auto_join_toc{
      				family_id = 0
     			},
    		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_AUTO_JOIN, R);
		FamilyID ->
			%%调用加入家族接口，直接加入家族
			join_25_family_direct(RoleID, FamilyID)
	end;

do_handle_info(gene_recommend_user) ->
    gene_recommend_user();

do_handle_info({gene_family_list, FactionList}) when erlang:is_list(FactionList) ->
    gene_family_list(FactionList);

do_handle_info(gene_family_list) ->
    gene_family_list([1, 2, 3]);

do_handle_info({update_family_ext_info,FamilyID,NewFamilyExtInfo})->
    router_to_family_process(FamilyID,{update_family_ext_info,NewFamilyExtInfo});

do_handle_info({role_online, _RoleID, FamilyID}) ->
    register_family(FamilyID);

do_handle_info({family_donate,DonateRecord,TokenTimes,FamilyID,RoleName,{Unique,DataIn,RoleID,PID}})->
    {ok,AddContribute,AddExp}=do_role_family_donate(FamilyID,RoleName,TokenTimes,{Unique,DataIn,RoleID,PID}),
    %%增加捐献的数据到列表
    NewDonateRecord = DonateRecord#p_family_pray_rec{
      add_contribute = AddContribute, 
      add_family_exp = AddExp
    },
    mod_map_fml_idol:add_donate_record(FamilyID, NewDonateRecord),

    router_to_family_process(FamilyID,{family_donate,RoleID,AddContribute,AddExp});

do_handle_info({donate_delete_role,FamilyID,RoleID})->
    do_delete_role_donate(FamilyID,RoleID);

do_handle_info({donate_delete_family,FamilyID})->
    do_delete_family_donate(FamilyID);

do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知的消息", Info]),
    ok.

%%删除捐献列表中的角色
do_delete_role_donate(FamilyID,RoleID)->
    case db:dirty_read(?DB_FAMILY_DONATE,FamilyID) of
        []->ignore;
        [FamilyDonate]->
            GoldDonateList = lists:keydelete(RoleID, #p_role_family_donate_info.role_id, FamilyDonate#r_family_donate.gold_donate_record),
            SilverDonateList = lists:keydelete(RoleID, #p_role_family_donate_info.role_id, FamilyDonate#r_family_donate.silver_donate_record),
            db:dirty_write(?DB_FAMILY_DONATE,FamilyDonate#r_family_donate{gold_donate_record=GoldDonateList,
                                                                          silver_donate_record=SilverDonateList})
    end.

%% 删除捐献列表中的宗族
do_delete_family_donate(FamilyID)->
    case db:dirty_read(?DB_FAMILY_DONATE,FamilyID) of
        []->ignore;
        [_FamilyDonate]->
            db:dirty_delete(?DB_FAMILY_DONATE, FamilyID)
    end.

do_role_family_donate(FamilyID,RoleName,TokenTimes,{Unique,DataIn,RoleID,PID})->
    #m_family_donate_tos{donate_type=DonateType,
                         donate_value = DonateValue}=DataIn,   
    case db:dirty_read(?DB_FAMILY_DONATE,FamilyID) of
        []->
            FamilyDonate =#r_family_donate{family_id = FamilyID,
                             gold_donate_record=[],
                             silver_donate_record =[]};
        [FamilyDonate]->
            next
        end,
    #r_family_donate{gold_donate_record=GoldDonateList,
                     silver_donate_record = SilverDonateList} = FamilyDonate,
    case DonateType of
        ?donate_gold->
            {RoleDonateInfo,NewGoldDonateList}=do_add_donate_value(RoleID,RoleName,DonateValue,GoldDonateList),
            db:dirty_write(?DB_FAMILY_DONATE, FamilyDonate#r_family_donate{gold_donate_record=NewGoldDonateList}),
            AddExp = DataIn#m_family_donate_tos.donate_value*100,
            AddContribute = DataIn#m_family_donate_tos.donate_value*10;
        ?donate_silver->
            {RoleDonateInfo,NewSilverDonateList}=do_add_donate_value(RoleID,RoleName,DonateValue,SilverDonateList),
            db:dirty_write(?DB_FAMILY_DONATE, FamilyDonate#r_family_donate{silver_donate_record=NewSilverDonateList}),
            AddExp = DataIn#m_family_donate_tos.donate_value,
            AddContribute = DataIn#m_family_donate_tos.donate_value;
        ?donate_token ->
            RoleDonateInfo = #p_role_family_donate_info{
                role_id=RoleID,
                role_name=RoleName,
                donate_amount=TokenTimes
            },
            AddExp = DataIn#m_family_donate_tos.donate_value * 10,
            AddContribute = DataIn#m_family_donate_tos.donate_value
    end,
    R = #m_family_donate_toc{donate_type=DonateType,
                             donate_info=RoleDonateInfo},
    common_misc:unicast2(PID, Unique, ?FAMILY, ?FAMILY_DONATE, R),
    {ok,AddContribute,AddExp}.

do_add_donate_value(RoleID,RoleName,DonateValue,List)->
    case lists:keyfind(RoleID, #p_role_family_donate_info.role_id,List) of
        false->
            NewRoleDonateInfo = #p_role_family_donate_info{role_id=RoleID,role_name=RoleName,donate_amount=DonateValue},
            {NewRoleDonateInfo,[NewRoleDonateInfo|List]};
        RoleDonateInfo->
            NewRoleDonateInfo =RoleDonateInfo#p_role_family_donate_info{donate_amount=RoleDonateInfo#p_role_family_donate_info.donate_amount+DonateValue},
            {NewRoleDonateInfo,[NewRoleDonateInfo|lists:delete(RoleDonateInfo, List)]}
    end.


do_get_donate_info(Unique,_Record,RoleID,PID)->
    #p_role_base{family_id=FamilyID} = mod_role_tab:get({?role_base, RoleID}),
    case db:dirty_read(?DB_FAMILY_DONATE,FamilyID) of
        []->
            R=#m_family_get_donate_info_toc{donate_gold_list=[],donate_silver_list = []};
        [FamilyDonateInfo]->
            R=#m_family_get_donate_info_toc{donate_gold_list=FamilyDonateInfo#r_family_donate.gold_donate_record,
                                   donate_silver_list = FamilyDonateInfo#r_family_donate.silver_donate_record}
    end,
    common_misc:unicast2(PID, Unique, ?FAMILY, ?FAMILY_GET_DONATE_INFO, R). 




make_recommend_key(FactionID) ->
    lists:concat(["recommend_user_", FactionID]).


do_family_detail(Unique,Module,Method,Record,RoleID,_PID,Line)->
    case db:dirty_read(?DB_FAMILY, Record#m_family_detail_tos.family_id) of
	[] ->
	    R_toc = #m_family_detail_toc{
	      succ = false,
	      reason = ?_LANG_FAMILY_NOT_EXITS_WHEN_REQUEST_DETAIL
	     };
	[Detail] ->
	    R_toc = #m_family_detail_toc{succ=true, content = Detail}
    end,    
    common_misc:unicast(Line,RoleID,Unique,Module,Method,R_toc).


do_can_invite(Unique, Module, Method, RoleID, Line) ->
    {ok, #p_role_base{faction_id=FactionID}} = common_misc:get_dirty_role_base(RoleID),
    InviteList = case get(make_recommend_key(FactionID)) of
                     undefined ->
                         [];
                     L ->
                         get_can_invite_list(RoleID, L, [])
                 end,

    R = #m_family_can_invite_toc{roles=InviteList},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%% @doc 获取推荐族员列表
get_can_invite_list(_RoleID, [], InviteList) ->
    InviteList;
get_can_invite_list(_RoleID, _OnlineList, InviteList) when length(InviteList) >= 8 ->
    InviteList;
get_can_invite_list(RoleID, [#r_role_online{role_id=TargetID}|T], InviteList) ->
    %% 百分之十的机会先中
    case 10 < common_tool:random(1, 100) andalso RoleID =/= TargetID of
        true ->
            {ok, #p_role_attr{level=Level,category = CategoryT}} = common_misc:get_dirty_role_attr(TargetID),
            case Level >= 10 of
                true ->
                    {ok, #p_role_base{role_name=TargetName, sex=Sex}} = common_misc:get_dirty_role_base(TargetID),
                    case CategoryT =:= 0 of
                        true ->
                            Category = 1;
                        _ ->
                            Category = CategoryT
                    end,
                    InviteList2 = [#p_recommend_member_info{role_id=TargetID, role_name=TargetName, sex=Sex, level=Level, category=Category}|InviteList],
                    get_can_invite_list(RoleID, T, InviteList2);
                _ ->
                    get_can_invite_list(RoleID, T, InviteList)
            end;
        _ ->
            get_can_invite_list(RoleID, T, InviteList)
    end.


%%生成邀请推荐玩家列表
gene_recommend_user() ->
    lists:foreach(
      fun(FactionID) ->
              L1 = db:dirty_match_object(?DB_USER_ONLINE, #r_role_online{family_id=0, faction_id=FactionID, _='_'}),
              put(make_recommend_key(FactionID), L1)
      end, [1, 2, 3]),
    erlang:send_after(?REGENE_RECOMMAND_USER_TICKET, self(), gene_recommend_user).


%%获得所有宗族列表中的某一页
get_family_list_of_all(PageID, NumOfPage) ->
	All = get(?all_family_list),
	case All of
		undefined ->
			{0, []};
		_ ->
			Size =  erlang:length(All),
			case Size > 0 of
				true ->
					Start = (PageID - 1) * NumOfPage + 1,
					TotalPage = common_tool:ceil(Size/NumOfPage),
					{TotalPage, lists:sublist(All, Start, NumOfPage)};
				false ->
					{0, []}
			end
	end.
    

%%获得本国宗族中的某一页
get_family_list_of_faction(FactionID, PageID, NumOfPage) ->
    Key = lists:concat(["faction_family_list_", FactionID]),
    All = get(Key),
    Size = erlang:length(All),
    case Size > 0 of
        true ->
            Start = (PageID - 1) * NumOfPage + 1,
            TotalPage = common_tool:ceil(Size/NumOfPage),
            {TotalPage, lists:sublist(All, Start, NumOfPage)};
        false ->
            {0, []}
    end.


get_family_list(FactionID, FamilyID, PageID, NumOfPage, [], _Type) ->
    case FamilyID > 0 of
        true ->
            %%显示所有的宗族
            get_family_list_of_all(PageID, NumOfPage);
        false ->
            %%显示本国宗族
            get_family_list_of_faction(FactionID, PageID, NumOfPage)
    end;
get_family_list(FactionID, FamilyID, PageID, NumOfPage, SearchContent, Type) ->
    case FamilyID > 0 of
        true ->
            %%显示所有的宗族
            get_family_list_of_all_search(PageID, NumOfPage, SearchContent, Type);
        false ->
            %%显示本国宗族
            get_family_list_of_faction_search(FactionID, PageID, NumOfPage, SearchContent, Type)
    end.

get_family_list_of_all_search(PageID, NumOfPage, SearchContent, Type) ->
    All = get(?all_family_list),
    Size =  erlang:length(All),
    case Size > 0 of
        true ->
            Lists = lists:filter(
                      fun(F) ->
                              case Type of
                                  1 ->
                                      string:str(common_tool:to_list(F#p_family_summary.name), SearchContent) > 0;
                                  2 ->
                                      string:str(common_tool:to_list(F#p_family_summary.owner_role_name), SearchContent) > 0
                              end
                      end, All),
            Start = (PageID - 1) * NumOfPage + 1,
            TotalPage = common_tool:ceil(erlang:length(Lists)/NumOfPage),
            {TotalPage, lists:sublist(Lists, Start, NumOfPage)};
        false ->
            {0, []}
    end.
    

get_family_list_of_faction_search(FactionID, PageID, NumOfPage, SearchContent, Type) ->
    Key = lists:concat(["faction_family_list_", FactionID]),
    %%搜索所有的宗族，检查出哪些符合条件
    All = get(Key),
    Size =  erlang:length(All),
    case Size > 0 of
        true ->
            Lists = lists:filter(
                      fun(F) ->
                              case Type of
                                  1 ->
                                      string:str(common_tool:to_list(F#p_family_summary.name), SearchContent) > 0;
                                  2 ->
                                      string:str(common_tool:to_list(F#p_family_summary.owner_role_name), SearchContent) > 0
                              end
                      end, All),
            case Lists of
                []->
                    {0, []};
                _ ->
                    Start = (PageID - 1) * NumOfPage + 1,
                    TotalPage = common_tool:ceil(erlang:length(Lists)/NumOfPage),
                    {TotalPage, lists:sublist(Lists, Start, NumOfPage)}
            end;
        false ->
            {0, []}
    end.


do_list(Unique, Module, Method, Record, RoleID, _PID, Line) ->
    #m_family_list_tos{page_id=PageID, num_per_page=NumOfPage, search_content=SearchContent, search_type=Type} = Record,
    case Type of
        1 ->
            Type2 = 1;
        _ ->
            Type2 = 2
    end,
    case PageID < 1 orelse NumOfPage =:= undefined of
        true ->
            PageID2 = 1;
        false ->
            PageID2 = PageID
    end,
    case NumOfPage < 1 orelse NumOfPage =:= undefined of
        true ->
            NumOfPage2 = 5;
        false ->
            NumOfPage2 = NumOfPage
    end,
    RequestFrom = Record#m_family_list_tos.request_from,
    ?DEBUG("family_request_from ~w",[RequestFrom]),
    #p_role_base{family_id=FamilyID, faction_id=FactionID} = mod_role_tab:get({?role_base, RoleID}),
    SearchContent2 = string:strip(SearchContent),
    case RequestFrom of 
	1 ->
	    {TotalPage, FamilyList} = get_family_list(FactionID, FamilyID, PageID2, NumOfPage2, SearchContent2, Type2);
	_ ->
	    {TotalPage,FamilyList} = get_family_list(FactionID,0,PageID2,NumOfPage2,SearchContent2,Type2)
    end,
    R = #m_family_list_toc{
      family_list=FamilyList,
      total_page = TotalPage,
      page_id=PageID2,
      request_from=RequestFrom
     },
    common_misc:unicast(Line,RoleID,Unique,Module,Method,R),
    ok.
        

%%查看宗族面板
do_panel(Unique, Module, Method, Record, RoleID, _PID, Line) ->
    #m_family_panel_tos{num_per_page=NumPerPageTmp} = Record,
    NumPerPage = erlang:abs(NumPerPageTmp),
    #p_role_base{family_id=FamilyID, faction_id=FactionID} = mod_role_tab:get({?role_base, RoleID}),
    {TotalPage, FamilyList} = get_family_list(FactionID, FamilyID, 1, NumPerPage, [], 1),
    %%获取宗族邀请列表
    Invites = db:dirty_match_object(?DB_FAMILY_INVITE, #p_family_invite_info{target_role_id=RoleID, _='_'}),
    Request = db:dirty_match_object(?DB_FAMILY_REQUEST, #p_family_request_info{role_id=RoleID, _='_'}),
    %%获取本国宗族第一页
    R = #m_family_panel_toc{requests=Request, invites=Invites, family_list=FamilyList, total_page=TotalPage},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%%申请加入宗族
do_request(FamilyID, {Unique, Module, Method, Record, RoleID, PID, Line}) ->
    case router_to_family_process(FamilyID, {Unique, Module, Method, Record, RoleID, PID, Line}) of
        ok ->
            ok;
        error ->
            Reason = ?_LANG_FAMILY_THE_REQUEST_FAMILY_NOT_EXIST,
            R = #m_family_request_toc{succ=false, reason=Reason},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
    end.

%%将消息路由到宗族进程
router_to_family_process(FamilyID, Info) when is_integer(FamilyID) ->
    ProcessName = common_misc:make_family_process_name(FamilyID),
    case global:whereis_name(ProcessName) of
        undefined ->
            register_family(FamilyID),
            do_send_to_family_process(ProcessName, Info);
        PID ->
            erlang:send(PID, Info),
            ok
    end.
do_send_to_family_process(ProcessName, Info) when is_list(ProcessName)->
    case global:whereis_name(ProcessName) of
        undefined ->
            ?ERROR_MSG("~ts:~w ~w", ["没有找到宗族进程", ProcessName, Info]),
            error;
        _ ->
            global:send(ProcessName, Info),
            ok
    end.


do_reduce_role_silver_for_create_successful(RoleID, RoleAttr) ->
    case get_create_family_request(RoleID) of
        undefined ->
            ok;
        {Unique, Module, Method, {FamilyName, PublicNotice, PrivateNotice, QQ, IsInvite}, PID,_Line} ->
            case db:transaction(fun() -> t_do_create(RoleID, FamilyName, PublicNotice, PrivateNotice, QQ) end) of
                {atomic, FamilyInfo} ->
                    mod_family:add_family_join_times(RoleID),
                    FamilyID = FamilyInfo#p_family_info.family_id,
                    register_family(FamilyID),

                    FamilyName = FamilyInfo#p_family_info.family_name,
                    {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
                    mod_family:notify_world_update(RoleID, FamilyInfo),
                    RoleName = RoleBase#p_role_base.role_name,
                    gene_family_list_no_loop([FamilyInfo#p_family_info.faction_id]),
                    %% 发送宗族开通信件
                    Letter = common_letter:create_temp(?FAMILY_CREATE_FAMILY_LETTER,[RoleName, FamilyName]),
                    common_letter:sys2p(RoleID, Letter, "成功创建家族的通知", 14),
                    Content = lists:flatten(io_lib:format("~s ~s ~s ~s", ["玩家[", RoleName, "]创建了家族", FamilyName])),
                    %%邀请好友
                    if IsInvite ->
                            RoleList = invite_join_family(RoleID),
                            lists:foreach(fun(TargetRole)->
                                            {_TargetRoleID,TargetRoleName}=TargetRole,
                                            Record=#m_family_invite_tos{role_name=TargetRoleName},
                                            router_to_family_process(FamilyID, {Unique, Module, ?FAMILY_INVITE, Record, RoleID, PID, _Line})
                                            end,RoleList);
                       true->
                            ignore
                    end,
                    %%广播通知所有的好友
                    FList = mod_friend_server:get_dirty_friend_list(RoleID),
                    RF = #m_friend_create_family_toc{role_id=RoleID, family_id=FamilyID, family_name=FamilyName},
                    lists:foreach(
                      fun(#r_friend{friendid=FID}) ->
                              common_misc:unicast({role, FID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_CREATE_FAMILY, RF)
                      end, FList),
                    %%需要世界广播
                    common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE, Content),
                    hook_family_change:hook(change, {RoleID, FamilyID, 0}),
                    
                    hook_family:create(FamilyInfo),
                    common_title_srv:add_title(?TITLE_FAMILY,RoleID,?FAMILY_TITLE_OWNER),
                    %%end	    
                    R = #m_family_create_toc{family_info=FamilyInfo, 
                                             new_silver=RoleAttr#p_role_attr.silver,
                                             new_silver_bind=RoleAttr#p_role_attr.silver_bind,
                                             new_gold = RoleAttr#p_role_attr.gold,
                                             new_gold_bind = RoleAttr#p_role_attr.gold_bind},
                    common_misc:unicast2(PID, Unique, Module, Method, R);
                {aborted, ErrorInfo} ->
                    case erlang:is_binary(ErrorInfo) of
                        true ->
                            Reason = ErrorInfo;
                        false ->
                            Reason = ?_LANG_SYSTEM_ERROR
                    end,
                    ?ERROR_MSG("创建宗族失败:RoleID=~w,ErrorInfo=~w", [RoleID, ErrorInfo]),
                    do_create_error(Unique, Module, Method, Reason, PID)
            end,
            erase_create_family_request(RoleID)
    end.

do_reduce_role_silver_for_create_failed(RoleID, Reason) ->
    case get_create_family_request(RoleID) of
        undefined ->
            ignore;
        {Unique, Module, Method, _Args, PID, _Line} ->
            do_create_error(Unique, Module, Method, Reason, PID),
            erase_create_family_request(RoleID)
    end,
    ok.

%%创建宗族
do_create(Unique, Module, Method, Record, RoleID, PID, Line) ->
    #m_family_create_tos{family_name=FamilyNameTmp, public_notice=PublicNotice, 
                         private_notice=PrivateNotice, qq=QQ, is_invite=IsInvite} = Record,
    FamilyName = filter_family_name(FamilyNameTmp),
    %%检查宗族名称，检查宗族内外公告，检查是否满足创建条件
    case check_name(FamilyName) of
        ok ->
            case check_notice(PublicNotice, PrivateNotice) of
                ok ->
                    %%先检查其他创建条件
                    case check_create_condition(RoleID) of
                        ok->
                            do_create2(Unique, Module, Method, 
                                       {FamilyName, PublicNotice, PrivateNotice, QQ, IsInvite}, RoleID, PID,Line);
                        {error,Reason}->
                            do_create_error(Unique, Module, Method, Reason, PID)
                    end;
                {error, Reason} ->
                    do_create_error(Unique, Module, Method, Reason, PID)
            end;
        {error, Reason} ->
            do_create_error(Unique, Module, Method, Reason, PID)
    end.
do_create2(Unique, Module, Method, {FamilyName, PublicNotice, PrivateNotice, QQ, IsInvite}, RoleID, PID,Line) ->
    case get_create_family_request(RoleID) of
        undefined ->
            %% 异步消息给地图
            [{DeductFeeType,DeductNum}] = common_config_dyn:find(family_base_info,create_family_fee),
            if
                (DeductFeeType=:=gold_any) orelse (DeductFeeType=:=gold_bind) ->
                    ConsumeLogType = ?CONSUME_TYPE_GOLD_CREATE_FAMILY,
                    DeductTuple1   = undefined,
                    DeductTuple2   = {DeductFeeType,DeductNum,ConsumeLogType,""};
                (DeductFeeType=:=silver_any) orelse (DeductFeeType=:=silver_bind) ->
                    ConsumeLogType = ?CONSUME_TYPE_SILVER_CREATE_FAMILY,
                    DeductTuple1   = {DeductFeeType,DeductNum,ConsumeLogType,""},
                    DeductTuple2   = undefined;
                true->
                    DeductTuple1   = undefined,
                    DeductTuple2   = undefined,
                    ConsumeLogType = error
            end,
            case is_integer(ConsumeLogType) andalso DeductNum>0 of
                true->
                    common_role_money:reduce(RoleID, {DeductTuple1, DeductTuple2},
                                             ?REDUCE_SILVER_FOR_CREATE_FAMILY,?REDUCE_SILVER_FOR_CREATE_FAMILY),
                    set_create_family_request(RoleID, {Unique, Module, Method, 
                                                       {FamilyName, PublicNotice, PrivateNotice, QQ, IsInvite}, PID,Line});
                _ ->
                    do_create_error(Unique, Module, Method, ?_LANG_FAMILY_CREATE_REQUEST_IN_PROCESS, PID)
            end;
        _ ->
            do_create_error(Unique, Module, Method, ?_LANG_FAMILY_CREATE_REQUEST_IN_PROCESS, PID)
    end.

%%@doc 检查创建宗族的条件,非事务实现
check_create_condition(RoleID)->
    #p_role_attr{level=RoleLevel} = mod_role_tab:get({?role_attr, RoleID}),
    [MinTitleCreateFamily] = common_config_dyn:find(family_base_info,min_level_create_family),
    %% 检查玩家等级
    case is_integer(RoleLevel) andalso RoleLevel >= MinTitleCreateFamily of
        true ->
            RoleBase = mod_role_tab:get({?role_base, RoleID}),
            %%检查是否已经有宗族了
            case RoleBase#p_role_base.family_id > 0 of
                false ->
                    case mod_family:is_special_family_date() of
                        true->
                            case mod_family:can_join_family_in_special_date(RoleID) of
                                true->
                                    ok;
                                _ ->
                                    {error, ?_LANG_JOIN_FAMILY_MAX_TIMES}
                            end;
                        _ ->
                            %%检查上一次离开宗族的时间
                            case do_check_last_op_time(RoleID) of
                                true->
                                    ok;
                                _ ->
                                    {error,?_LANG_FAMILY_LAST_OP_TIME_CREATE_LIMIT}
                            end
                    end;
                true ->
                    {error,?_LANG_FAMILY_ALREAD_HAS_A_FAMILY_WHEN_CREATE}
            end;
        _ ->
            {error,common_tool:get_format_lang_resources(?_LANG_FAMILY_TITLE_NOT_ENOUGH_WHEN_CREATE,[MinTitleCreateFamily])}
    end.


%% 保存玩家请求创建宗族信息
set_create_family_request(RoleID, {Unique, Module, Method, {FamilyName, PublicNotice, PrivateNotice, QQ, IsInvite}, PID,Line}) ->
    erlang:put({create_family_request, RoleID}, {Unique, Module, Method, {FamilyName, PublicNotice, PrivateNotice, QQ, IsInvite}, PID,Line}).
get_create_family_request(RoleID) ->
    erlang:get({create_family_request, RoleID}).
erase_create_family_request(RoleID) ->
    erlang:erase({create_family_request, RoleID}).

do_create_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_create_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).


%%成功则返回宗族的ID
t_do_create(RoleID, FamilyName, PublicNotice, PrivateNotice, QQ) ->
    %%扣玩家钱币，修改玩家属性
    [#p_role_attr{office_name=OfficeName, level=RoleLevel}] = db:read(?DB_ROLE_ATTR, RoleID, write),
    %% 玩家等级可以直接读取，因为玩家升级时一定会进行持久化
    
    RoleBase = mod_role_tab:get({?role_base, RoleID}),
    FamilyID = get_new_family_id(),
    
    NewRoleBase = RoleBase#p_role_base{family_id=FamilyID, family_name=FamilyName},
    #p_role_base{role_name=RoleName, faction_id=FactionID, sex=Sex, head=Head} = NewRoleBase,
    NewM = #p_family_member_info{role_id=RoleID, role_name=RoleName,
                                 sex=Sex, head=Head, office_name=OfficeName, family_contribution=0,
                                 role_level= RoleLevel,
                                 online=true, title=?FAMILY_TITLE_OWNER},
    Members = [NewM],
    [DefaultCreateFamilyLevel] = common_config_dyn:find(family_base_info,default_create_family_level),
    [IsCreateFamilyMap] = common_config_dyn:find(family_base_info,is_create_family_map),
    #r_family_config{next_level_exp=NextLevelExp} = cfg_family:level_config(DefaultCreateFamilyLevel),
    FamilyRecord = #p_family_info{
      family_id           = FamilyID, 
      family_name         = FamilyName, 
      owner_role_id       = RoleID, 
      owner_role_name     = RoleName,
      faction_id          = FactionID, 
      level               = DefaultCreateFamilyLevel,
      exp                 = 0,
      next_level_exp      = NextLevelExp, 
      create_role_id      = RoleID,
      create_role_name    = RoleName, 
      cur_members         = 1, 
      enable_map          = IsCreateFamilyMap,
      kill_uplevel_boss   = false, 
      uplevel_boss_called = false,
      second_owners       = [], 
      active_points       = 0, 
      money               = 0, 
      request_list        = [], 
      invite_list         = [],
      members             = Members,  
      ybc_type            = 0, 
      ybc_creator_id      = 0,
      gongxun             = 0,
      public_notice       = PublicNotice, 
      private_notice      = PrivateNotice, 
      qq                  = QQ
    },
	mod_role_tab:put({?role_base, RoleID}, NewRoleBase),
    db:write(?DB_FAMILY_EXT, 
             #r_family_ext{family_id=FamilyID, last_resume_time=0, 
                           common_boss_called=false, 
                           common_boss_killed=false}, 
             write),
    db:write(?DB_FAMILY, FamilyRecord, write),
    db:write(?DB_FAMILY_COUNTER, #r_family_counter{id=1, value=FamilyID}, write),
    FamilyRecord.


%%家族设置自动加入，则加入家族的时候，不通过申请，直接加入
join_family_direct(RoleID, FamilyID) ->
	router_to_family_process(FamilyID, {join_family_direct, RoleID, FamilyID}).

%%25级自动加入
join_25_family_direct(RoleID, FamilyID) ->
	router_to_family_process(FamilyID, {join_25_family_direct, RoleID, FamilyID}).

%%检查常见的宗族名称是否合法
check_name(FamilyName) ->
    case erlang:length(FamilyName) < 2 of
        true ->
            {error, ?_LANG_FAMILY_NAME_MUST_MORE_THAN_ONE};
        false ->
            %%是否重名
            Sql = lists:flatten(io_lib:format("select family_id from t_family_summary where family_name='~s';", [FamilyName])),
            case mod_mysql:select(Sql) of
                {ok, []} ->
                    ok;
                _ ->
                    {error, ?_LANG_FAMILY_NAME_DUPLICATEED}
            end
    end.


%%检查宗族的内外公告
check_notice(_PublicNotice, _PrivateNotice) ->
    ok.


%%过滤宗族名称
filter_family_name(FamilyNameTmp) ->
    string:strip(FamilyNameTmp).


%%@doc 离开宗族当天，创建不能再新宗族
do_check_last_op_time(RoleID) ->
    #p_role_ext{family_last_op_time=LastOpTime} = mod_role_tab:get({role_ext, RoleID}),
    case is_integer(LastOpTime) andalso LastOpTime>0 of
        true->
            {Date,_Time} = common_tool:seconds_to_datetime(LastOpTime),
            Date =/= date();
        false->
            true
    end.

invite_join_family(RoleID)->
    {RoleList1,RestNum1}=get_clan(RoleID,30),
    if RestNum1>0 ->
            {RoleList2,_RestNum2}=get_friend(RoleList1,RoleID,RestNum1),
            RoleList1++RoleList2;
        true->
            RoleList1
    end.
            
%%同门
get_clan(_RoleID,Num)->
    RoleIDList1 = [],
    filter_list([],RoleIDList1,Num).

%%好友
get_friend(RoleIDList,RoleID,Num)->
    RoleFriendList1 = mod_friend_server:get_dirty_friend_list(RoleID),
    RoleIDList1 = [Friend#r_friend.friendid||Friend<-RoleFriendList1],
    filter_list(RoleIDList,RoleIDList1,Num).


filter_list(OldList,NewList,Num)->
    NewList1 =lists:foldr(fun(RoleID,Acc)-> 
                    case common_misc:is_role_online(RoleID) of
                        false->Acc;
                        true->
                            {ok,RoleBase} = common_misc:get_dirty_role_base(RoleID),
                            case RoleBase#p_role_base.family_id=:=0 of
                                true->  
                                        {ok,RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
                                        Level= RoleAttr#p_role_attr.level,
                                        RoleName = RoleAttr#p_role_attr.role_name,
                                        case Level>9 of
                                            true->[{Level,RoleID,RoleName}|Acc];
                                            false->Acc
                                        end;
                                false->Acc
                            end
                    end
                end, [], NewList),
    NewList2 = lists:sort(fun(E1,E2)-> {L1,_,_}=E1,{L2,_,_}=E2,L1>L2 end,NewList1),
    NewList3=[begin {_,RoleID,RoleName}=E,{RoleID,RoleName} end ||E<-NewList2],
    NewList4 = lists:filter(fun(E2)->lists:all(fun(E1)-> E1=/=E2 end ,OldList) end,NewList3),

    if length(NewList4) <Num ->
            {NewList4,Num-length(NewList4)};
        true->
            {List1,_List2}= lists:split(Num,NewList4),
            {List1,0}
    end.
