%% Author: xierongfeng
%% Created: 2012-11-16
%% Modified: 2013-2-18 (增加累计签到功能)
%% Modified: 2013-3-5  (根据策划修改)
%% Description: 签到功能
-module(mod_role_signin).

-define(_common_error, Unique, ?COMMON, ?COMMON_ERROR, #m_common_error_toc).
-define(_signin_info, Unique, ?SIGNIN, ?SIGNIN_INFO, #m_signin_info_toc).
-define(_signin_fetch, Unique, ?SIGNIN, ?SIGNIN_FETCH, #m_signin_fetch_toc).
-define(_signin_continue_info, Unique, ?SIGNIN, ?SIGNIN_CONTINUE_INFO, #m_signin_continue_info_toc).
-define(_signin_continue_fetch, Unique, ?SIGNIN, ?SIGNIN_CONTINUE_FETCH, #m_signin_continue_fetch_toc).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([init/2, delete/1, handle/1, get_normal_rewards/1, get_leiji_rewards/3]).

-export([check_continue_reward/3, merge_rewards/2, put_role_signin/2, get_continue_info/2, get_continue_info/1]).
%%
%% API Functions
%%
init(RoleID, Rec) when is_record(Rec, r_role_signin) ->
	put({r_role_signin, RoleID}, Rec);
init(_RoleID, _) ->
	ignore.

delete(RoleID) ->
	erase({r_role_signin, RoleID}).

handle({signin, PID, RoleID, Day}) ->
    {Y, M, _} = erlang:date(),
    {_, Signin} = is_role_signed(RoleID), 
    Unique = 0,
   	case lists:member({Y, M, Day}, Signin#r_role_signin.signin_days) of
   		true ->
   			common_misc:unicast2(PID, ?_common_error{error_str = <<"今天已经签到过了">>});
   		false ->
			normal_signin(RoleID, Signin, Y, M, Day, PID, 0)
	end;

handle({clear_signin, PID, RoleID}) ->
	Signin = #r_role_signin{},
	put_role_signin(RoleID, Signin), 
	{Y, M, _} = erlang:date(),

	DataIn = #m_signin_info_tos{
		select_year = Y, 
		select_month = M
	},
	handle({0, ?SIGNIN, ?SIGNIN_INFO, DataIn, RoleID, PID, 0}),
	get_continue_info(RoleID);

handle({Unique, ?SIGNIN, ?SIGNIN_INFO, DataIn, RoleID, PID, _Line}) ->
	#m_signin_info_tos{
		select_year = SelectYear, 
		select_month = SelectMonth
	} = DataIn, 

	{TodaySigned, #r_role_signin{
		signin_days = SigninDays
	}} = is_role_signed(RoleID),

	SigninDays1 = get_month_days_rec(SelectYear, SelectMonth, SigninDays), 

	SignNum = erlang:length(SigninDays1),
	
	get_sign_info_list(PID, SigninDays1, TodaySigned, SignNum, SelectYear, SelectMonth, Unique);

handle({Unique, ?SIGNIN, ?SIGNIN_FETCH, _DataIn, RoleID, PID, _Line}) ->
	{NowYear, NowMonth, NowDay} = erlang:date(), 

	{Signed, Signin} = is_role_signed(RoleID), 
	if
		Signed ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"今天已经签到过了">>});
		true ->
			normal_signin(RoleID, Signin, NowYear, NowMonth, NowDay, PID, Unique)
	end;

handle({_Unique, ?SIGNIN, ?SIGNIN_CONTINUE_INFO, _DataIn, RoleID, _PID, _Line}) ->
	get_continue_info(RoleID);

handle({Unique, ?SIGNIN, ?SIGNIN_CONTINUE_FETCH, DataIn, RoleID, PID, _Line}) ->
	#m_signin_continue_fetch_tos{
		fetch_num = FetchNum
	} = DataIn, 
	{_, Signin} = is_role_signed(RoleID), 
	LongestNum = get_longest_continue_num(Signin#r_role_signin.signin_days),

	case lists:member(FetchNum, Signin#r_role_signin.continue_list) of
		false ->
			case LongestNum >= FetchNum of
				true ->
					Rewards = cfg_signin:continue_rewards(FetchNum),
					CreateInfos = [#r_goods_create_info{
						bind    = true, 
						type    = ?TYPE_ITEM, 
						type_id = TypeID, 
						num     = Num
					}||{TypeID, Num} <- Rewards, TypeID > 3],

					CreateGoods = case CreateInfos == [] orelse common_transaction:t(fun
							() ->
								mod_bag:create_goods(RoleID, CreateInfos)
						end) of
							true ->
								ok;
							{atomic, {ok, UpdateList}} ->
								common_misc:update_goods_notify(PID, UpdateList),
								common_item_logger:log(RoleID, CreateInfos, ?LOG_ITEM_TYPE_GAIN_CONLOGIN),
								ok;
							_ ->
								Message = ?_LANG_SIGNIN_REWARD, 
								GoodsList = common_misc:get_mail_items_create_info(RoleID, CreateInfos),
								common_letter:sys2p(RoleID,Message,"签到奖励邮件", GoodsList,14),
								% common_misc:unicast2(PID, ?_common_error{error_str = <<"背包已满">>}),
								ok
					end,	

					if
						CreateGoods == ok ->
							common_misc:unicast2(PID, ?_signin_continue_fetch{
								succ = true, 
								fetch_num = LongestNum
							}),

							NewSignin = Signin#r_role_signin{
								continue_list = lists:sort([FetchNum|Signin#r_role_signin.continue_list])
							},
							put_role_signin(RoleID, NewSignin),
							get_continue_info(RoleID, NewSignin);
						true ->
							ignore
					end;
				false ->
					common_misc:unicast2(PID, ?_common_error{error_str = <<"该项未到条件, 不可领取">>})
			end;
		true ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"该项已经领取过了">>})
	end.



get_continue_info(RoleID) ->
	{_, Signin} = is_role_signed(RoleID),
	get_continue_info(RoleID, Signin).
get_continue_info(RoleID, Signin) ->
	{ok, #p_role_attr{
		level   = RoleLevel
	}} = mod_map_role:get_role_attr(RoleID),

	if
		RoleLevel >= 10 ->
			LongestNum = get_longest_continue_num(Signin#r_role_signin.signin_days),

			CanSignInList = cfg_signin:get_continue_days() -- Signin#r_role_signin.continue_list,
			ContinueInfos = lists:map(fun(H) ->
				State = if
					LongestNum >= H ->
						1;
					true ->
						2
				end, 
				#p_continue_info{
					fetch_num = H, 
					state = State
				}
			end, CanSignInList),

			_Unique = 0, 
			if
				ContinueInfos == [] ->
					[];
				true ->	
					Unique = 0,
					common_misc:unicast({role, RoleID}, ?_signin_continue_info{continue_infos = ContinueInfos, continue_num = LongestNum})
			end;
		true ->
			[]
	end.

get_longest_continue_num([]) ->
	0;
get_longest_continue_num([H|T]) ->
	get_longest_continue_num(T, H, 1, 1).

get_longest_continue_num([], _, _, 30) ->
	30;
get_longest_continue_num([], _, _, LongestNum) ->
	LongestNum;
get_longest_continue_num([H|T], Pre, Num, LongestNum) ->
	case get_next_date(Pre) == H of
		true ->
			get_longest_continue_num(T, H, Num + 1, erlang:max(Num + 1, LongestNum));
		false ->
			get_longest_continue_num(T, H, 1, LongestNum)
	end.

check_continue_reward(0, _, _) ->	
	ok;
check_continue_reward(FetchNum, SigninDays, {NowYear, FetchMonth, FetchDay}) ->
	true = lists:member({NowYear, FetchMonth, FetchDay}, SigninDays), 
	NextDate = get_next_date(NowYear, FetchMonth, FetchDay),
	check_continue_reward(FetchNum - 1, SigninDays, NextDate).

normal_signin(RoleID, Signin, NowYear, NowMonth, NowDay, PID, Unique) ->
	NowMonthDays = get_month_days_rec(NowYear, NowMonth, Signin#r_role_signin.signin_days),
	{ok, #p_role_attr{
		level   = RoleLevel
	}} = mod_map_role:get_role_attr(RoleID),

	LeijiSignNum = length(NowMonthDays),
	NormalRewards = get_normal_rewards(RoleLevel), 
	LeijiRewards = get_leiji_rewards(LeijiSignNum + 1, NowYear, NowMonth),
	Rewards1 = merge_rewards(NormalRewards, LeijiRewards),

	CreateInfos = [#r_goods_create_info{
		bind    = true, 
		type    = ?TYPE_ITEM, 
		type_id = TypeID, 
		num     = Num
	}||{TypeID, Num} <- Rewards1, TypeID > 3],

	CreateGoods = case CreateInfos == [] orelse common_transaction:t(fun() ->
			mod_bag:create_goods(RoleID, CreateInfos)
	end) of
		true ->
			ok;	
		{atomic, {ok, UpdateList}} ->
			common_misc:update_goods_notify(PID, UpdateList),
			common_item_logger:log(RoleID, CreateInfos, ?LOG_ITEM_TYPE_GAIN_CONLOGIN),
			ok;
		_ ->
			Message = ?_LANG_SIGNIN_REWARD, 
			GoodsList = common_misc:get_mail_items_create_info(RoleID, CreateInfos),
			common_letter:sys2p(RoleID,Message,"签到奖励邮件", GoodsList,14),
			ok
	end,	
	if
		CreateGoods == ok ->
			case lists:keyfind(1, 1, Rewards1) of
				{_, Silver} -> 
					common_bag2:add_money(RoleID, 
						silver_bind, Silver, ?GAIN_TYPE_SILVER_SIGNIN);
				_ ->
					ignore
			end,
			case lists:keyfind(2, 1, Rewards1) of
				{_, Exp} ->
					mod_map_role:do_add_exp(RoleID, Exp);
				_ ->
					ignore
			end,
			case lists:keyfind(3, 1, Rewards1) of
				{_, Prestige} ->
					common_bag2:add_prestige(RoleID, 
						Prestige, ?GAIN_TYPE_PRESTIGE_SIGNIN);
				_ ->
					ignore
			end,
			common_misc:unicast2(PID, ?_signin_fetch{
				succ = true
			}),

			NewSigninDays = lists:sort([{NowYear, NowMonth, NowDay} | NowMonthDays]),

			NewSignin = Signin#r_role_signin{
				signin_days = NewSigninDays
			},
			put_role_signin(RoleID, NewSignin), 

			TodaySigned = lists:member(erlang:date(), NewSigninDays),

			get_sign_info_list(
				PID, 
				NewSigninDays, 
				TodaySigned, 
				LeijiSignNum + 1, NowYear, NowMonth, Unique
			), 
			get_continue_info(RoleID, NewSignin);
		true ->
			ignore
	end.

%%
%% Local Functions
%%
% -record(r_role_signin, {
% 	signin_month = 0, %% 当前签到月份  note:用于删除上上月份的签到
% 	signin_days = [], %%% {year, month , day}
% 	continue_list = []  %%已经领取了的连续登陆奖励    如:3, 5, 7...
% }).
get_sign_info_list(PID, SigninDays1, TodaySigned, SignNum, SelectYear, SelectMonth, Unique) ->
	Days = [D1 || {_, _, D1} <- SigninDays1],
	LastDay = calendar:last_day_of_the_month(SelectYear, SelectMonth),
	common_misc:unicast2(PID, ?_signin_info{
		normal_list = Days, 
		today_signed = TodaySigned, 
		three_signed = SignNum >= 3, 
		seven_signed = SignNum >= 7, 
		fiftn_signed = SignNum >= 15,
		quanqin_signed = SignNum == LastDay
	}).

is_role_signed(RoleID) ->
	#r_role_signin{
		signin_days = SigninDays
	} = Signin = get({r_role_signin, RoleID}, #r_role_signin{}),
	{NowYear, NowMonth, NowDay} = erlang:date(),
	
	case SigninDays of
		[] ->
			{false, Signin};
		_ ->
			SignFlag = lists:member({NowYear, NowMonth, NowDay}, SigninDays),

			%%清除上上个月的签到记录
			% Signin1 = case NowYear == SigninYear andalso NowMonth == SigninMonth of

			Signin1 = case lists:member({NowYear, NowMonth , 1}, SigninDays) of
				true ->
					Signin;
				false ->
					{Year1, Month1} = get_prev_year_month(NowYear, NowMonth),
					Days1 = lists:filter(fun({Y, M, _}) ->
						Flag1 = (Y == Year1 andalso M == Month1), 
						Flag2 = (Y == NowYear andalso M == NowMonth), 

						Flag1 orelse Flag2
					end, SigninDays), 
					Signin#r_role_signin{signin_days = Days1}
			end, 
			% Signin2 = case SignFlag of
			% 	true ->
			% 		Signin1;
			% 	false ->
			% 		case is_next_day({SigninYear, SigninMonth, SigninDay}, NowDate) of
			% 			true ->
			% 				[];
			% 			false ->
			% 				Signin1#r_role_signin{continue_days = 0}
			% 		end
			% end, 
			{SignFlag, Signin1}
	end.

merge_rewards(List1, List2) ->
	lists:foldl(fun({Type, Num}, AccList) ->
		case lists:keyfind(Type, 1, AccList) of
			{_, Num1} ->
				lists:keystore(Type, 1, AccList, {Type, Num1 + Num});
			false ->
				[{Type, Num} | AccList]
		end
	end, List1, List2).

%%获取指定月签到天数
get_month_days_rec(SelectYear, SelectMonth, SigninDays) ->
	lists:filter(fun(H) ->
		{Y, M, _D} = H, 
		SelectYear == Y andalso SelectMonth == M
	end, SigninDays).

% is_today({OY, OM, OD}, {NY, NM, ND}) ->
% 	OY == NY andalso OM == NM andalso OD == ND.

get_next_date({Y, M, D}) ->
	get_next_date(Y, M, D).

get_next_date(Y, M, D) ->
	calendar:gregorian_days_to_date(calendar:date_to_gregorian_days(Y, M, D) + 1).

% is_next_day({OY, OM, OD}, {NY, NM, ND}) ->
% 	(calendar:date_to_gregorian_days(OY, OM, OD) + 1) == alendar:date_to_gregorian_days(NY, NM, ND).

get_prev_year_month(Year, 1) ->
	{Year - 1, 12};
get_prev_year_month(Year, Month) ->
	{Year, Month - 1}.

put_role_signin(RoleID, Signin) ->
	put({r_role_signin, RoleID}, Signin).

get(Key, Default) ->
	case get(Key) of
		undefined ->
			Default;
		Val ->
			Val
	end.

get_normal_rewards(RoleLevel) ->
	cfg_signin:normal_rewards(RoleLevel).

get_leiji_rewards(SignNum, NowYear, NowMonth) ->
	case calendar:last_day_of_the_month(NowYear, NowMonth) == SignNum of
		true ->
			cfg_signin:quanqin_rewards();
		false ->
			cfg_signin:leiji_rewards(SignNum)
	end.
