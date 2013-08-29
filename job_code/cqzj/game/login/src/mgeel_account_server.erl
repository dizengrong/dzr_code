%%%----------------------------------------------------------------------
%%% @copyright 2010 mgee (Ming Game Engine Erlang)
%%%
%%% @author odinxu, 2010-1-13
%%% @doc TODO: Add description to mod_account_manager
%%% @end
%%%----------------------------------------------------------------------

-module(mgeel_account_server).

-behaviour(gen_server).

-include("mgeel.hrl").
-include("letter.hrl").
-export([start/0, start_link/0]).
-export([
         handle/1,
         set_max_online_num/1,
         set_cushion_online_num/1,
         get_cushion_line/3,
         list_role/1,
         get_online_info/0,
         do_get_faction_id/0
        ]).

-export([
         add_role/3
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record( state, {} ).

%% ====================================================================

start() ->
    {ok, _} = supervisor:start_child(
                mgeel_sup, 
                {mgeel_account_server,
                 {mgeel_account_server, start_link, []},
                 transient, brutal_kill, worker, [mgeel_account_server]}),
    ok.


start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% ====================================================================

%%获取当前人数最少的国家
do_get_faction_id() ->
    case db:dirty_read(?DB_ROLE_FACTION, 1) of
        [] ->
            Faction1 = 0;
        [#r_role_faction{number=N1}] ->
            Faction1 = N1
    end,
    case db:dirty_read(?DB_ROLE_FACTION, 2) of
        [] ->
            Faction2 = 0;
        [#r_role_faction{number=N2}] ->
            Faction2 = N2
    end,
    case db:dirty_read(?DB_ROLE_FACTION, 3) of
        [] ->
            Faction3 = 0;
        [#r_role_faction{number=N3}] ->
            Faction3 = N3
    end,
    Min = lists:min([Faction1, Faction2, Faction3]),
    case Min of
        Faction1 ->
            1;
        Faction2 ->
            2;
        _ ->
            3
    end.

%%@doc 新建角色（包括普通玩家和GM的角色）
add_role(IsGMRole,AccountName,Data) when is_record(Data,m_role_add_tos)->
    #m_role_add_tos{role_name=RoleName, sex=Sex, head=HeadID, faction_id=FactionID,
                    hair_type=HairType, hair_color=HairColor} = Data,
    RoleName2 = filter_rolename(RoleName),
    Sex2 = common_tool:to_integer(Sex),
    HeadID2 = common_tool:to_integer(HeadID),
    FactionID2 = common_tool:to_integer(FactionID),
    
    %%如果创建GM角色，则不需要校验角色名
    ValidResult = case IsGMRole of
                      true->
                          valid_role_other_info(Sex2, HeadID2, FactionID2);
                      false->
                          valid_role_add_info(RoleName2, Sex2, HeadID2, FactionID2)
                  end,
    case IsGMRole of
        true ->
            AccountType = ?ACCOUNT_TYPE_GM;
        _ ->
            AccountType = ?ACCOUNT_TYPE_NORMAL
    end,
    case ValidResult of
        true ->
            AccountName2 = common_tool:to_binary(AccountName),
            gen_server:call({global, ?MODULE}, 
                            {add_gm_role, AccountName2, AccountType,RoleName2, Sex2, 
                             FactionID2, HeadID2, HairType, HairColor});
        {false, Reason} ->
            #m_role_add_toc{succ=false, reason=Reason}
    end.


handle({Unique, _Module, Method, Data, AccountName, PID}) ->
    case Method of
        ?ROLE_LIST ->
            mgeel_account_server:list_role(AccountName);
        ?ROLE_ADD ->
            add_role(false,AccountName,Data);
        ?ROLE_CHOSE ->
            RoleID = Data#m_role_chose_tos.roleid,
            Key = mgeel_key_server:gen_key(AccountName, RoleID),
            {MaxOnlineNum,CushionNum,OnlineNum} = get_online_info(),
            ?DEBUG("~w ~w ~w  ~w",[MaxOnlineNum,CushionNum,OnlineNum,Unique]),
            case OnlineNum < CushionNum of
                true ->
                    Line = mgeel_line:get_line(),                    
                    Key = mgeel_key_server:gen_key(AccountName, RoleID),
                    #m_role_chose_toc{succ=true, key=Key, lines=[Line]};
                false ->
                    case OnlineNum < MaxOnlineNum of
                        true ->
                            WaitSeconds = trunc(((OnlineNum - CushionNum)/100 + 1)) * 10,
                            DataRecord = #m_role_chose_toc{succ=true, key=Key, wait_second = WaitSeconds, lines = []};
                        false -> 
                            WaitSeconds = 60,
                            DataRecord = #m_role_chose_toc{succ=true, key=Key, wait_second = 60, lines = []}
                    end,
                    timer:apply_after((WaitSeconds-2)*1000, ?MODULE, get_cushion_line, [PID, AccountName, RoleID]),
                    DataRecord
            end;
        Other ->
	    ?ERROR_MSG("not implemented method of account_server :~w", [Other]),
            ignore
    end.


list_role(AccountName) ->
    ?ERROR_MSG("not implemented method of account_server :AccountName=~w", [AccountName]),
    error.


set_max_online_num(Num) ->
    case global:whereis_name(?MODULE) of
        undefined ->
            {fail,"server not exist!"};
        _ ->     
            global:send(?MODULE,{set_max_online_num,Num}),
            {ok,Num}
    end.

set_cushion_online_num(Num) ->
     case global:whereis_name(?MODULE) of
        undefined ->
            {fail,"server not exist!"};
        _ ->     
            global:send(?MODULE,{set_cushion_online_num,Num}),
            {ok,Num}
    end.

get_cushion_line(PID, AccountName, RoleID) ->
    {MaxOnlineNum, _CushionNum, OnlineNum} = get_online_info(),
    case OnlineNum =< MaxOnlineNum of
        true ->
            PID ! {wait_time_out, AccountName, RoleID};
        false ->
            timer:apply_after(60*1000, ?MODULE, get_cushion_line, [PID, AccountName, RoleID])
    end.

get_online_info() ->
    gen_server:call({global, ?MODULE}, get_online_info).


%% --------------------------------------------------------------------

init([]) ->
    case db:transaction( 
           fun() -> 
                   case db:read(?DB_ROLEID_COUNTER_P, 1, write) of
                       [] ->
                           db:write(?DB_ROLEID_COUNTER_P, #r_roleid_counter{id=1, last_role_id=0}, write);
                       [_] ->
                           ignore
                   end                   
           end) of
        {'EXIT', _} ->
            {stop, read_mnesia_record_error};
        {atomic, _} ->
            {ok, #state{}}
    end.

%% --------------------------------------------------------------------

handle_call(get_online_info, _From, State) ->
    MaxOnlineNum = get(max_online_num),
    CushionNum = get(cushion_online_num),
    OnlineNum = get(online_num),
    Reply = {MaxOnlineNum,CushionNum,OnlineNum},
    {reply, Reply, State};

%% @doc 创建角色，GM创建角色专用
handle_call({add_gm_role, AccountName, AccountType, RoleName, Sex, FactionID, HeadID, HairType, HairColor}, _From, State) ->
    Reply = do_add_role(AccountName, AccountType, RoleName, Sex, FactionID, HeadID, HairType, HairColor, 1),
    {reply, Reply, State};

%% @doc 创建角色
handle_call({add_role, AccountName, AccountType, RoleName, Sex, FactionID, HeadID, HairType, HairColor, Category}, _From, State) ->
    Reply = do_add_role(AccountName, AccountType, RoleName, Sex, FactionID, HeadID, HairType, HairColor, Category),
    {reply, Reply, State};

handle_call(Request, From, State) ->
    ?DEBUG("~w handle_cal from ~w : ~w", [?MODULE, From, Request]),
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------

do_handle_info({Unique, Module, Method, Data, RoleID, PID}) ->
    case Method of
        ?ROLE2_RENAME ->
            do_rename(Unique, Module, Method, Data, RoleID, PID);
        _ ->
            ?ERROR_MSG("~ts:~w", ["收到未知消息", {Unique, Module, Method, Data, RoleID, PID}])
    end;
do_handle_info({set_max_online_num,Num}) 
  when is_integer(Num) ->
    put(max_online_num,Num);

do_handle_info({set_cushion_online_num,Num}) 
 when is_integer(Num) ->
    put(cushion_online_num,Num);

do_handle_info({update_online_num,Num}) ->
    put(online_num,Num);

do_handle_info({pass_fcm, AccountName}) ->
    db:transaction(
      fun() ->
              case db:read(?DB_FCM_DATA, AccountName) of
                  [] ->
                      ignore;
                  [FcmData] ->
                      db:write(?DB_FCM_DATA, FcmData#r_fcm_data{passed=true}, write)
              end
      end);

do_handle_info({http, {_, RenamedHttpResult}}) ->
    do_handle_http(RenamedHttpResult);

do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["收到未知消息", Info]).

do_rename(Unique, Module, Method, Data, RoleID, PID) ->
	#m_role2_rename_tos{new_name=NewRoleName} = Data,
	URL = lists:concat([common_config:get_check_name_url(), "?", 
						mochiweb_util:urlencode([{"new_rolename", mochiweb_util:quote_plus(NewRoleName)},
												 {"role_id", RoleID}])]),
	R = httpc:request(get, {URL, []}, [], [{sync, false}]),
	?ERROR_MSG("~w ~s", [R, URL]),
	erlang:put({rename, RoleID}, {Unique, Module, Method, Data, RoleID, PID}),
	ok.
do_handle_http(RenamedHttpResult) ->
    case RenamedHttpResult of
        {Succ, _, Result} ->
            ?ERROR_MSG("~p", [Succ]),
            case Succ of
                {_, 200, "OK"} ->
                    Result2 = common_tool:to_list(Result),
                    ?ERROR_MSG("~ts", [Result2]),
                    [IsOk, Info] = string:tokens(Result2, "#"),
                    case IsOk of
                        "error" ->
                            [RoleID, ErrorInfo] = string:tokens(Info, "@"),                            
                            case erlang:get({rename, common_tool:to_integer(RoleID)}) of
                                undefined ->
                                    ignore;
                                {Unique, Module, Method, _Data, _RID, PID} ->
                                    R = #m_role2_rename_toc{succ=false, reason=ErrorInfo},
                                    common_misc:unicast2(PID, Unique, Module, Method, R)
                            end,
                            erlang:erase({rename, RoleID});
                        "ok" ->
                            [RoleIDT, NewRoleNameT] = string:tokens(Info, "@"),
                            NewRoleName = common_tool:to_binary(NewRoleNameT),
                            RoleID = common_tool:to_integer(RoleIDT),                            
                            case erlang:get({rename, RoleID}) of
                                undefined ->
                                    ignore;
                                {Unique, Module, Method, _Data, RoleID, PID} ->                                    
                                    mgeer_role:absend(RoleID, {mod_role2, {Unique, Module, Method, NewRoleName, RoleID, PID}})
                            end,
                            erlang:erase({rename, RoleID})
                    end;
                Error ->
                    ?ERROR_MSG("~ts:~p", ["请求判断用户名合法出错", Error]),
                    ignore
            end;
        Error ->
            ?ERROR_MSG("~ts:~p", ["请求判断用户名合法出错", Error]),
            ignore
    end,
    ok.
%%获取出生点信息
get_born_info(FactionID) ->
	case common_config_dyn:find(born, FactionID) of
		[ MapID ] ->
			[BornPointList] = common_config_dyn:find(etc, newer_born_point),
			Length = length(BornPointList),
			{TX, TY} = lists:nth(random:uniform(Length), BornPointList),
			{MapID, TX, TY};
		_ ->
			error
	end.

%% 创建角色
do_add_role(AccountName, AccountType, RoleName, Sex, FactionID, HeadID, HairType, HairColor, Category) ->
    case db:transaction(
           fun() -> 
                   t_add_role(AccountName, AccountType, RoleName, Sex, FactionID, HeadID, HairType, HairColor, Category) 
           end) 
        of
        {aborted, Error} ->                     
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    ?ERROR_MSG("~ts : ~w", ["创建用户失败", Error]),
                    Reason = ?_LANG_SYSTEM_ERROR
            end,
            {error, Reason};
        {atomic, NewRoleList} ->
            ?DEBUG("~ts", ["角色创建成功"]),
            RoleData = erlang:hd(NewRoleList),
            common_behavior:send({role_new, AccountName, RoleData}),            
            hook_register_ok:hook(NewRoleList),
            %% 防沉迷数据
            case catch db:dirty_read(?DB_FCM_DATA, AccountName) of
                [] ->
                    FcmData = #r_fcm_data{account=AccountName},
                    db:dirty_write(?DB_FCM_DATA, FcmData);
                _ ->
                    ok
            end, 
            {ok, (RoleData#p_role.base)#p_role_base.role_id}            
    end.

%%事务添加角色处理过程
t_add_role(AccountName, AccountType, RoleName, Sex, FactionID, SkinID, HairType, HairColor, Category) ->
    [IsOpenGuestAccount] = common_config_dyn:find(etc, is_open_guest_account),
    case AccountType =:= ?ACCOUNT_TYPE_GUEST of
        true ->
            case IsOpenGuestAccount of
                true ->
                    next;
                _ ->
                    db:abort(?_LANG_ROLE_ACCOUNT_TYPE_GUEST_NOT_OPEN)
            end;
        _ ->
            ignore
    end,
    %%角色ID
    [#r_roleid_counter{last_role_id=LastRoleID}] = db:read(?DB_ROLEID_COUNTER_P, 1, write),
    NewRoleID = LastRoleID + 1,
    case db:read(?DB_ROLE_BASE_P, NewRoleID, write) of
        [] ->
            case db:read(?DB_ROLE_NAME, RoleName) of
                [] ->
                    case get_born_info(FactionID) of
                        error ->
                            ?ERROR_MSG("~ts:~w", ["根据选择的国家查找出生点出错", FactionID]),
                            db:abort(?_LANG_SYSTEM_ERROR);
                        {MAPID, TX, TY} ->
                            t_add_role2(AccountName, AccountType, NewRoleID, RoleName, Sex, FactionID, SkinID, HairType, 
                                        HairColor, Category, MAPID, TX, TY)
                    end;
                [_] ->
                    db:abort(?_LANG_ROLE_NAME_EXIST)
            end;
        _ ->
            db:abort(?_LANG_ROLE_ID_IS_EXIST)
    end.
t_add_role2(AccountName, AccountType, RoleID, RoleName, Sex, FactionID, Head, HairType, HairColor, Category, MAPID, TX, TY) ->
    Now = common_tool:now(),
    case db:read(?DB_ACCOUNT, AccountName) of
        [] ->
            db:write(?DB_ACCOUNT, #r_account{account_name=AccountName, create_time=Now, role_num = 1}, write),
            RoleNum = 0;
        [#r_account{role_num=RoleNumT}] ->
            RoleNum = RoleNumT
    end,
    %%检查该玩家创建的角色数量
    case RoleNum < ?ACCOUNT_ROLE_COUNT_MAX of
        true ->
            OldRoleList = t_get_role_list_by_account(AccountName),
            RoleBase = make_new_role_base(RoleID, RoleName, AccountName, AccountType, Sex, Head, FactionID, Now, Category),
            %%更新国家角色数量
            case db:read(?DB_ROLE_FACTION, FactionID) of
                [] ->
                    db:write(?DB_ROLE_FACTION, #r_role_faction{faction_id=FactionID, number=1}, write);
                [#r_role_faction{number=OldNumber}] ->
                    db:write(?DB_ROLE_FACTION, #r_role_faction{faction_id=FactionID, number=OldNumber+1}, write)
            end,
            RolePos = make_new_role_pos(RoleID, MAPID, TX, TY),
            RoleSkin = #p_skin{skinid=Head, light_code=[0,0]},
            RoleExt = make_new_role_ext(RoleID, RoleName, Sex, RoleSkin, Now),
            RoleFight = make_new_role_fight(RoleID),
            RoleAttr = make_new_role_attr(RoleID, RoleName, Head, HairType, HairColor, Category),
            RoleReceFlowers = make_new_role_rece_flower_box(RoleID),
            RoleGiveFlowers = make_new_role_give_flower_box(RoleID),
			DefaultSkills = case Category of
				1 -> 
					[
                        #r_role_skill_info{skill_id=1, cur_level=1, category=Category},
                        #r_role_skill_info{skill_id=91000001, cur_level=1, category=Category}
                    ];
				3 ->
					[
                        #r_role_skill_info{skill_id=3, cur_level=1, category=Category},
                        #r_role_skill_info{skill_id=92000001, cur_level=1, category=Category}
                    ]
			end,
            %% 插入角色数据
            db:write(?DB_ROLE_BASE, RoleBase, write),
            db:write(?DB_ROLE_POS, RolePos, write),
            db:write(?DB_ROLE_EXT, RoleExt, write),
            db:write(?DB_ROLE_FIGHT, RoleFight, write),
            db:write(?DB_ROLE_ATTR, RoleAttr, write),
            db:write(?DB_ROLE_RECEIVE_FLOWERS,RoleReceFlowers,write),
            db:write(?DB_ROLE_GIVE_FLOWERS,RoleGiveFlowers,write),
            db:write(?DB_PAY_ACTIVITY_P, #r_pay_activity{role_id=RoleID}, write),
            db:write(?DB_ROLE_GOAL_P, #r_goal{role_id=RoleID}, write),
            db:write(?DB_ROLE_TILI_P, #r_role_tili{role_id=RoleID,cur_tili=200,last_auto_increase_time=Now}, write),
            db:write(?DB_ROLE_SKILL_P, #r_role_skill{role_id=RoleID, skill_list=DefaultSkills}, write),
			
            %% 记录角色名
            db:write(?DB_ROLE_NAME, #r_role_name{role_name=RoleName, role_id=RoleID}, write),
            NewRoleIDRecord = #r_roleid_counter{id=1, last_role_id=RoleID},
            Tmp = #p_role{base=RoleBase,fight=RoleFight,pos=RolePos,attr=RoleAttr,ext=RoleExt},
            %%初始化角色状态
            RoleState = #r_role_state{role_id=RoleID, normal=true},
            db:write(?DB_ROLE_STATE, RoleState, write),
            db:write(?DB_ROLEID_COUNTER_P, NewRoleIDRecord, write),
            %% 角色累积经验
            %%db:write(?DB_ROLE_ACCUMULATE_EXP_P, #r_role_accumulate_exp{role_id=RoleID, list=[]}, write),
            common_bag2:t_new_role_bag(RoleID),
            common_bag2:t_new_role_bag_basic(RoleID),
            common_consume_logger:gain_silver({RoleID, ?DEFAULT_SILVER_BIND, 
                                               ?DEFAULT_SILVER, ?GAIN_TYPE_SILVER_FROM_NEW_ROLE, ""}),
            common_consume_logger:gain_gold({RoleID, ?DEFAULT_GOLD_BIND, 
                                             ?DEFAULT_GOLD, ?GAIN_TYPE_GOLD_FROM_NEW_ROLE, ""}),
            [Tmp | OldRoleList];
        false ->
            db:abort(?_LANG_ROLE_MAX_COUNT_LIMIT)
    end.

t_get_role_list_by_account(AccountName) ->
    RoleBaseList = db:match_object(?DB_ROLE_BASE, #p_role_base{account_name=AccountName, _='_'}, read),
    lists:foldl(
      fun(#p_role_base{role_id=RoleID}, Acc0) ->
              [RoleBase] = db:read(?DB_ROLE_BASE, RoleID, write),
              [RolePos] = db:read(?DB_ROLE_POS, RoleID, write),
              [RoleExt] = db:read(?DB_ROLE_EXT, RoleID, write),
              [RoleFight] = db:read(?DB_ROLE_FIGHT, RoleID, write),
              [RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID, write),
              Tmp = #p_role{
                base=RoleBase,
                fight=RoleFight,
                pos=RolePos,
                attr=RoleAttr,
                ext=RoleExt
               },
              [Tmp | Acc0]
      end, [], RoleBaseList).

-spec(valid_role_add_info(
        RoleName::list(), 
        Sex::integer(), 
        SkinID::integer(), 
        FactionID::integer()
                   ) ->true | {false, Reason::binary()}).
valid_role_add_info(RoleName, Sex, SkinID, FactionID) ->
    case valid_rolename(RoleName) of
        true ->
            valid_role_other_info(Sex, SkinID, FactionID);
        Rtn ->
            {false, Rtn}
    end.

%%@doc 验证Role的其他信息
valid_role_other_info(Sex, SkinID, FactionID)->
    case valid_sex(Sex) of
        true ->
            case valid_skinid(SkinID) of
                true ->
                    case valid_factionid(FactionID) of
                        true ->
                            true;
                        Rtn ->
                            {false, Rtn}
                    end;
                Rtn ->
                    {false, Rtn}
            end;
        Rtn ->
            {false, Rtn}
    end.

-spec(valid_rolename(RoleName::binary()) -> true | binary()).                
valid_rolename(RoleName) ->
    case RoleName of
        <<>> ->
            ?_LANG_ROLENAME_CANNT_EMPTY;
        _ ->
            case common_validation:valid_username(RoleName) of
                true ->
                    case common_misc:check_name(RoleName) of
                        false ->
                            true;
                        true ->
                            ?_LANG_ROLENAME_BAN_WORDS
                    end;
                false ->
                    ?_LANG_ROLENAME_NOT_VALID_CHAR
            end
    end.

valid_skinid(SkinID) ->
    case SkinID > 0 andalso SkinID < 13 of
        true ->
            true;
        false ->
            ?_LANG_NOT_VALID_SKINID
    end.

valid_sex(Sex) ->
    case Sex =:= 1 orelse Sex =:= 2 of
        true ->
            true;
        false ->
            ?_LANG_NOT_VALID_SEX
    end.

valid_factionid(FactionID) ->
    case FactionID > 0 andalso FactionID < 4 of
        true ->
            true;
        false ->
            ?_LANG_NOT_VALID_FACTION
    end.


make_new_role_base(RoleID, RoleName, AccountName, AccountType, Sex, _Head, FactionID, Now, Category) ->
	RoleBase = #p_role_base{
        role_id            = RoleID, 
        role_name          = RoleName,
        account_name       = AccountName,
        sex                = Sex,
        create_time        = Now,
        head               = Category * 10 + Sex,
        faction_id         = FactionID,
        team_id            = 0,
        family_id          = 0,
        family_name        = [],
        max_hp             = common_misc:get_level_base_hp(?DEFAULT_ROLE_LEVEL),
        max_mp             = common_misc:get_level_base_mp(?DEFAULT_ROLE_LEVEL),
        str                = ?DEFAULT_ROLE_STR,
        int2               = ?DEFAULT_ROLE_INT,
        con                = ?DEFAULT_ROLE_CON,
        dex                = ?DEFAULT_ROLE_DEX,
        men                = ?DEFAULT_ROLE_MEN,
        base_str           = ?DEFAULT_ROLE_STR,
        base_int           = ?DEFAULT_ROLE_INT,
        base_con           = ?DEFAULT_ROLE_CON,
        base_dex           = ?DEFAULT_ROLE_DEX,
        base_men           = ?DEFAULT_ROLE_MEN,
        pk_title           = ?DEFAULT_PK_TITLE,
        max_phy_attack     = ?DEFAULT_MAX_PHY_ATTACK,
        min_phy_attack     = ?DEFAULT_MIN_PHY_ATTACK,
        max_magic_attack   = ?DEFAULT_MAX_MAGIC_ATTACK,
        min_magic_attack   = ?DEFAULT_MIN_MAGIC_ATTACK,
        phy_defence        = ?DEFAULT_PHY_DEFENCE,
        magic_defence      = ?DEFAULT_MAGIC_DEFENCE,
        hp_recover_speed   = ?DEFAULT_HP_RECOVER_SPEED,
        mp_recover_speed   = ?DEFAULT_MP_RECOVER_SPEED,
        luck               = ?DEFAULT_LUCK,
        move_speed         = ?DEFAULT_MOVE_SPEED,
        attack_speed       = ?DEFAULT_ATTACK_SPEED,
        no_defence         = ?DEFAULT_NO_DEFENCE,
        miss               = ?DEFAULT_MISS,
        double_attack      = ?DEFAULT_DOUBLE_ATTACK,
        phy_anti           = 0,
        magic_anti         = 0,
        pk_mode            = ?DEFAULT_PK_MODE,
        pk_points          = 0,
        last_gray_name     = 0,
        if_gray_name       = false,
        buffs              = [],
        hit_rate           = 10000,
        account_type       = AccountType
    },
    mod_role_base:recalc(RoleBase, #p_role_attr{level = 1}).


make_new_role_fight(RoleID) ->
    #p_role_fight{
       role_id           = RoleID,
       hp                = common_misc:get_level_base_hp(?DEFAULT_ROLE_LEVEL),
       mp                = common_misc:get_level_base_mp(?DEFAULT_ROLE_LEVEL),
       energy            = ?DEFAULT_ENERGY,
       energy_remain     = 0,
       time_reset_energy = common_tool:now(),
       max_nuqi          = cfg_role_nuqi:max_nuqi()
    }.

make_new_role_pos(RoleID, MapID, TX, TY) ->
%%     TX2 = TX - 3 + random:uniform(6),
%%     TY2 = TY - 3 + random:uniform(6),
    MapPName = common_map:get_common_map_name(MapID),
    #p_role_pos{
                 role_id=RoleID,
                 map_id=MapID,
                 pos=#p_pos{tx=TX, ty=TY, px=0, py=0, dir=4},
                 map_process_name=MapPName,
                 old_map_process_name=MapPName
               }.

%%根据玩家的选择产生角色结构体
make_new_role_attr(NewRoleID, NewRoleName, Head, _HairType, _HairColor, Category) ->
    case common_config_dyn:find(etc, is_beta_server) of
        [true] ->
            case common_config_dyn:find(etc,{create_role,gold_bind}) of
                [GoldBind] -> next;
                _ -> 
                    GoldBind = ?DEFAULT_GOLD_BIND
            end,
            case common_config_dyn:find(etc,{create_role,gold_unbind}) of
                [GoldUnBind] -> next;
                _ -> 
                    GoldUnBind = ?DEFAULT_GOLD
            end;
        _ ->
            GoldUnBind = ?DEFAULT_GOLD,
            GoldBind = ?DEFAULT_GOLD_BIND
    end,
    #p_role_attr{
        role_id             = NewRoleID,
        role_name           = NewRoleName,
        next_level_exp      = ?DEFAULT_ROLE_NEXT_LEVEL_EXP,
        exp                 = ?DEFAULT_ROLE_EXP,
        level               = ?DEFAULT_ROLE_LEVEL,
        five_ele_attr       = ?DEFAULT_FIVE_ELE_ATTR,
        last_login_location = [],
        equips              = [],
        skin                = #p_skin{
            skinid     = Head,
            light_code = [0,0],
            halo       = 0,
            gem        = 0
        },
        remain_skill_points = ?DEFAULT_REMAIN_SKILL_POINT,
        gold                = GoldUnBind,
        gold_bind           = GoldBind,
        silver              = ?DEFAULT_SILVER,
        silver_bind         = ?DEFAULT_SILVER_BIND,
        show_cloth          = true,
        moral_values        = 0,
        gongxun             = 0,
        active_points       = 0,
        last_login_ip       = undefined,
        jingjie             = 0,
        category            = Category
    }.

make_new_role_ext(RoleID, RoleName, RoleSex, _RoleSkin, Now) ->
    #p_role_ext{
                 role_id=RoleID, 
                 family_last_op_time=0,
                 signature=[],
                 birthday=0,
                 constellation=0,
                 country=0,
                 province=0,
                 city=0,
                 blog=[],
                 last_login_time=Now,
                 last_offline_time=Now - 1,
                 role_name=RoleName,
                 sex = RoleSex
               }.

make_new_role_rece_flower_box(RoleID) ->
    #r_receive_flowers{role_id=RoleID,flowers=[],count=1}.

make_new_role_give_flower_box(RoleID) ->
    #r_give_flowers{role_id=RoleID,score=0}.

filter_rolename(RoleName) ->
    common_tool:to_binary(string:strip(RoleName)).
    
