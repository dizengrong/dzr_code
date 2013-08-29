%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     处理新手子模块，包括（新手卡激活码等）
%%% @end
%%% Created : 2010-12-17
%%%-------------------------------------------------------------------
-module(mod_newcomer).

-include("mgeem.hrl").

%% API
-export([
         handle/1,
		 hook_role_online/1,
		 do_newcomer_dailygold_fetch/1
         ]).

-define(MIN_ACTIVATE_CODE_LEN,14).  %%目前最短的激活码长度为14
-define(MAX_ACTIVATE_CODE_LEN,20).  %%目前最长的激活码长度为20
-define(DO_ACTIVATE_ERROR(Reason),do_activate_error(Unique, Module, Method, Reason, PID)).

-define(NEWCOMER_DAILYGOLD_FETCH_GAIN_ALREADY, 1001).

%%%===================================================================
%%% API
%%%===================================================================

handle({_, ?NEWCOMER, ?NEWCOMER_ACTIVATE_CODE, _, _, _PID, _Line}=Info)->
    do_activate_code(Info);
handle({Unique,?NEWCOMER,?NEWCOMER_DAILYGOLD_FETCH,DataIn,RoleID,PID,_Line}) ->
	do_newcomer_dailygold_fetch({Unique,?NEWCOMER,?NEWCOMER_DAILYGOLD_FETCH,DataIn,RoleID,PID,_Line});
handle({gm_fetch_reward, RoleID}) ->
    do_gm_set_fetch_reward(RoleID);
handle(Args) ->
    ?ERROR_MSG("~w, unknow args: ~w", [?MODULE,Args]),
    ok. 

%% 每日登录元宝奖励查询
hook_role_online(RoleID) ->
	do_newcomer_dailygold_info(RoleID).
		


%% ====================================================================
%% Internal functions
%% ====================================================================
do_newcomer_dailygold_info(RoleID) ->
	case check_newcomer_dailygold_info(RoleID) of
		{ok, LoginDay, RewardLimitDay} ->
			case common_config_dyn:find(present, {gold_reward,LoginDay}) of
				[{_MoneyType,GoldNum}] ->
					R2 = #m_newcomer_dailygold_info_toc{activity_id=99990,gold_num=GoldNum,login_day=LoginDay,reward_limit_day=RewardLimitDay},
					common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NEWCOMER, ?NEWCOMER_DAILYGOLD_INFO, R2);
				[] ->
					ignore
			end;
		_ ->
			ignore
	end.

check_newcomer_dailygold_info(RoleID) ->
	{ok, #p_role_base{create_time=CreateTime}} = mod_map_role:get_role_base(RoleID),
	{CreateTime2,_} = common_tool:seconds_to_datetime(CreateTime),
	LoginDay = common_time:diff_date(CreateTime2, erlang:date()),
	[RewardLimitDay] = common_config_dyn:find(present, reward_limit_day),
	if
		LoginDay =< RewardLimitDay ->
			{ok, #r_role_map_ext{role_present=RolePresent}} = mod_map_role:get_role_map_ext_info(RoleID),
			#r_role_present{last_time=LastTime,is_gain=IsGain} = RolePresent,
			case {LastTime =:= erlang:date(), IsGain} of
				{true, false} ->
					{ok, LoginDay+1,RewardLimitDay};
				{true, true} ->
					ignore;
				{false, _} -> 
					{ok, LoginDay+1,RewardLimitDay}
			end;
		true ->
			ignore
	end.

%% 获取元宝奖励
do_newcomer_dailygold_fetch({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	#m_newcomer_dailygold_fetch_tos{activity_id=ActivityID} = DataIn,
	case check_newcomer_dailygold_info(RoleID) of
		{ok, LoginDay, _RewardLimitDay} ->
			send_role_reward({Unique, Module, Method, DataIn, RoleID, PID, _Line},LoginDay);
		_ ->
			R2 = #m_newcomer_dailygold_fetch_toc{activity_id=ActivityID,err_code=1,reason=?NEWCOMER_DAILYGOLD_FETCH_GAIN_ALREADY},
			?UNICAST_TOC(R2)
	end.

%%　发送元宝奖励
send_role_reward({Unique, Module, Method, DataIn, RoleID, PID, _Line},LoginDay) ->
	#m_newcomer_dailygold_fetch_tos{activity_id=ActivityID} = DataIn,
	[{MoneyType,GoldNum}] = common_config_dyn:find(present, {gold_reward,LoginDay}),
	
	TransFun = fun() ->
					   {ok, RoleAttr2} = common_bag2:t_gain_money(MoneyType, GoldNum, RoleID, ?GAIN_TYPE_GOLD_NEWCOMER_DAILYGOLD_FETCH),
					   {ok,#r_role_map_ext{role_present=RolePresent}=RoleExtInfo} = mod_map_role:get_role_map_ext_info(RoleID),
					   NewRolePresent = RolePresent#r_role_present{last_time=erlang:date(),is_gain=true},
					   RoleMapExt2=RoleExtInfo#r_role_map_ext{role_present=NewRolePresent},
					   mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2),
					   {ok, RoleAttr2}
			   end,
	case catch common_transaction:t(TransFun) of
		{atomic, {ok, RoleAttr}} ->
			common_misc:send_role_gold_change(RoleID, RoleAttr),
			R2 = #m_newcomer_dailygold_fetch_toc{activity_id=ActivityID,gold_num=GoldNum,login_day=LoginDay},
			?UNICAST_TOC(R2);
		{aborted, AbortErr}->
			?ERROR_MSG("AbortErr=~w",[AbortErr])
	end.



%%检查激活码是否有效
check_activate_code(TmpCode)->
	Code = string:strip(TmpCode),
    case is_list(Code) andalso length(Code)>= ?MIN_ACTIVATE_CODE_LEN
         andalso length(Code)=<?MAX_ACTIVATE_CODE_LEN of
        true->
            next;
        _ -> 
            throw({error,?_LANG_NEWCOMER_ACTIVATE_CODE_WRONG})
    end,
    PublishKey = get_publish_key(Code),
    case common_config_dyn:find(activate_code,PublishKey) of
        []->
            IsMultTimes = false,
            throw({error,?_LANG_NEWCOMER_ACTIVATE_CODE_TYPE_ERROR});
        [#r_activate_code_info{is_mult_times=IsMultTimes,begin_time=0,end_time=0}]->
            next;
        [#r_activate_code_info{is_mult_times=IsMultTimes,begin_time=BeginTime,end_time=EndTime}]->
            Now = common_tool:now(),
            if
                Now < BeginTime->
                    Msg = common_misc:format_lang(?_LANG_NEWCOMER_ACTIVATE_CODE_BEGINTIME_ERR, [common_tool:seconds_to_datetime_string2(BeginTime)]),
                    throw({error,Msg});
                Now > EndTime->
                    Msg = common_misc:format_lang(?_LANG_NEWCOMER_ACTIVATE_CODE_ENDTIME_ERR, [common_tool:seconds_to_datetime_string2(EndTime)]),
                    throw({error,Msg});
                true->
                    next
            end
    end,
    {ok,IsMultTimes}.

%%@doc处理新手卡激活码功能
do_activate_code({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_newcomer_activate_code_tos{code=Code}=DataIn,
    case catch check_activate_code(Code) of
        {ok,IsMultTimes}->
            WhereExpr = io_lib:format("code='~s' ",[Code]),
            SqlCode = mod_mysql:get_esql_select(t_activate_code,[role_id],WhereExpr) ,
            case mod_mysql:select(SqlCode) of
                {ok,[]}->
                    ?DO_ACTIVATE_ERROR( ?_LANG_NEWCOMER_ACTIVATE_CODE_WRONG );
                {ok,[[MatchID]]}->
                    case (MatchID>0) of
                        true->
                            ?DO_ACTIVATE_ERROR( ?_LANG_NEWCOMER_ACTIVATE_CODE_BE_AWARED );
                        false->
                            PublishKey = get_publish_key(Code),
                            SqlRole = mod_mysql:get_esql_select(t_activate_code,[role_id],io_lib:format("`role_id`=~w and `publish_id`=~w limit 1",[RoleID,PublishKey])) ,
                            case mod_mysql:select(SqlRole) of
                                {ok,[]}->
                                    %%赠送奖品
                                    send_activate_gift({Unique, Module, Method, DataIn, RoleID, PID},PublishKey,WhereExpr);
                                {ok,[_]}->   
                                    case IsMultTimes of
                                        true->
                                            %%赠送奖品
                                            send_activate_gift({Unique, Module, Method, DataIn, RoleID, PID},PublishKey,WhereExpr);
                                        _ ->
                                            ?DO_ACTIVATE_ERROR( ?_LANG_NEWCOMER_ACTIVATE_CODE_ROLE_ONLY_ONCE )
                                    end;
                                Error1 ->
                                    ?ERROR_MSG("领取激活码错误，Error=~w",[Error1]),
                                    ?DO_ACTIVATE_ERROR( ?_LANG_SYSTEM_ERROR )
                            end
                    end;
                Error2 ->
                    ?ERROR_MSG("领取激活码错误，Error=~w",[Error2]),
                    ?DO_ACTIVATE_ERROR( ?_LANG_SYSTEM_ERROR )
            end;
        {error,Reason}->
            ?DO_ACTIVATE_ERROR( Reason )
    end.

%%@doc 更新系统数据库
update_activate_log(_PublishKey,RoleID,WhereExpr)->
    {ok, #p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    LoginIP = case db:dirty_read(?DB_USER_ONLINE, RoleID) of
                  [Record] ->
                      common_tool:ip_to_str( Record#r_role_online.login_ip );
                  _->
                      ""
              end,
    MTime = common_tool:now(),
    
    SqlUpdate = mod_mysql:get_esql_update(t_activate_code,[{role_id,RoleID},{role_level,RoleLevel},{mtime,MTime},{userip,LoginIP}],WhereExpr),
    {ok,_} = mod_mysql:update(SqlUpdate).

%%@doc 获取激活码发放PublishKey
%%@return -> 有发放类型和发放批次组成
get_publish_key(Code)->
	try
		PublishKey = string:substr(Code,13,(length(Code)-12)),
		common_tool:to_integer( string:strip(PublishKey) )
	catch
		_:_->
			throw({error,?_LANG_NEWCOMER_ACTIVATE_CODE_WRONG})
	end.

%%赠送激活码的礼品
send_activate_gift({Unique, Module, Method, _DataIn, RoleID, PID},PublishKey,WhereExpr)->
    [#r_activate_code_info{gift_id=GiftID,gift_num=GiftNum}] = common_config_dyn:find(activate_code,PublishKey),
    
    case send_activate_gift2(RoleID,GiftID,GiftNum) of
        ok->
            try
                update_activate_log(PublishKey,RoleID,WhereExpr),
                ?UNICAST_TOC( #m_newcomer_activate_code_toc{succ=true} ),
                common_item_logger:log(RoleID, GiftID,GiftNum,true,?LOG_ITEM_TYPE_GET_SYSTEM)
            catch
                _:Reason3->
                    ?ERROR_MSG("更新激活码数据库错误，Error=~w",[Reason3]),
                    ?DO_ACTIVATE_ERROR( ?_LANG_SYSTEM_ERROR )
            end;
        {error,Reason}->
            ?DO_ACTIVATE_ERROR( Reason )
    end.

send_activate_gift2(RoleID,ItemTypeID,ItemNum)->   
    CreateInfo = #r_goods_create_info{bind=true,type=?TYPE_ITEM, type_id=ItemTypeID, start_time=0,
                                      end_time=0, num=ItemNum, color=0,quality=0,
                                      punch_num=0,interface_type=present},
    case common_transaction:transaction(fun() -> mod_bag:create_goods(RoleID,CreateInfo) end) of
        {atomic, {ok,GoodsList}} ->
            common_item_logger:log(RoleID,ItemTypeID,ItemNum,true,?LOG_ITEM_TYPE_GET_SYSTEM),   
            common_misc:update_goods_notify({role,RoleID},GoodsList),
            ok;
        {aborted, {bag_error,{not_enough_pos,_BagID}}} ->
            ?ERROR_MSG("赠送激活码时，背包已满",[]),
            {error,?_LANG_NEWCOMER_ACTIVATE_CODE_BAG_FULL};
        {aborted, Reason2} ->
            ?ERROR_MSG("赠送激活码的礼品 Error,Reason2=~w~n=====",[Reason2]),
            {error,?_LANG_SYSTEM_ERROR}
    end.

%% gm命令设置可领取每天登录礼券奖励，设置创建时间为前一天create_time-86400
do_gm_set_fetch_reward(RoleID) ->
	{ok, #p_role_base{create_time=CreateTime}=RoleBase} = mod_map_role:get_role_base(RoleID),
	{CreateTime2,_} = common_tool:seconds_to_datetime(CreateTime),
	LoginDay = common_time:diff_date(CreateTime2, erlang:date()),
	[RewardLimitDay] = common_config_dyn:find(present, reward_limit_day),
	if
		LoginDay =< RewardLimitDay ->
			{ok, #r_role_map_ext{role_present=RolePresent}} = mod_map_role:get_role_map_ext_info(RoleID),
			#r_role_present{last_time=LastTime,is_gain=IsGain} = RolePresent,
			case {LastTime =:= erlang:date(), IsGain} of
				{true, true} ->
					TransFun = fun() ->
									   {ok,#r_role_map_ext{role_present=RolePresent}=RoleExtInfo} = mod_map_role:get_role_map_ext_info(RoleID),
									   NewRolePresent = RolePresent#r_role_present{is_gain=false},
									   RoleMapExt2=RoleExtInfo#r_role_map_ext{role_present=NewRolePresent},
									   NewCreateTime = CreateTime - 86400,
									   mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2),
									   mod_map_role:set_role_base(RoleID, RoleBase#p_role_base{create_time=NewCreateTime})
							   end,
					case catch common_transaction:t(TransFun) of
						{atomic, _} ->
							do_newcomer_dailygold_info(RoleID);
						{aborted, AbortErr}->
							?ERROR_MSG("AbortErr=~w",[AbortErr])
					end;
				_ -> 
					ignore
			end;
		true ->
			ignore
	end.

%%处理出错
do_activate_error(Unique, Module, Method, Reason, PID) ->
    Rec = #m_newcomer_activate_code_toc{succ=false, reason=Reason},
    ?UNICAST_TOC( Rec ).


