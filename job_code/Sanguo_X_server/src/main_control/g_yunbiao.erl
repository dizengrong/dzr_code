-module(g_yunbiao).
-behaviour(gen_server).

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-include("common.hrl").
-export([start_link/0,
		 send_award/0,
		 get_jixing_rec_from_cache/1
		]).

start_link() ->
	gen_server:start_link({local,?MODULE},?MODULE, [], []).



init([])->
	process_flag(trap_exit, true),
	%%24:00 触发奖励，邮件形式通知
	{H, M, S} = data_yun_biao:get_send_award_time(),
	SetTime = H*?SECONDS_PER_HOUR + M*?SECONDS_PER_MINUTE +S,
	{H1, M1, S1} = erlang:time(), 
	NowTime = H1*?SECONDS_PER_HOUR + M1*?SECONDS_PER_MINUTE + S1,
	Time =
		case (SetTime - NowTime) > 0 of
			true ->
				SetTime - NowTime;
			false ->
				SetTime - NowTime + ?SECONDS_PER_DAY
		end,
	timer:apply_after(Time, ?MODULE, send_award, []),
	?INFO(yunbiao,"init g_yunbiao"),
	{ok, null}.


handle_call({get_jixing_rec, Id}, _From, State)->
	?INFO(yunbiao,"client request get jinxing rec"),
	Reply = get_jixing_rec_from_cache(Id),
	
	?INFO(yunbiao,"get_jixing_rec,Newrec:~w",[Reply]),
	{reply, Reply, State};

handle_call({update_jixing, Id}, _From, State)->
	?INFO(yunbiao, "udate_jixing"),
	[Rec] = get_jixing_rec_from_cache(Id),
	?INFO(yunbiao,"update_jixing,its original rec:~w",[Rec]),

	NewYunShiPoint = Rec#jixing.yunshi_Point+1,
	CurStartLevel = Rec#jixing.starLevel,
	case CurStartLevel =:= 0 of
		true ->
			{NeedPoint, _AddFactor0} = data_yun_biao:get_up_need_yunshipoint(1);
		false ->
			{NeedPoint, _AddFactor0} = data_yun_biao:get_up_need_yunshipoint(CurStartLevel)
	end,

	Num = mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES),
	Goldcount = data_yun_biao:get_goldcount_cost(Num),
	
	NowTime = util:unixtime(),

	NewRec = case NeedPoint =:= NewYunShiPoint of 
					true ->
						%%吉星升级
						{UpYunShiPoint, AddFactor} = data_yun_biao:get_up_need_yunshipoint(CurStartLevel+1),
						
						NRec = Rec#jixing{starLevel = Rec#jixing.starLevel+1, yunshi_Point = 0,up_yunshi_point = UpYunShiPoint,
							goldcount=Goldcount,addfactor= round(AddFactor*100),last_zhuanyun_time = NowTime},
						NRec;
					false ->
						NRec = Rec#jixing{yunshi_Point = Rec#jixing.yunshi_Point+1,goldcount=Goldcount,last_zhuanyun_time = NowTime},
						NRec
			   end,
	?INFO(yunbiao,"update jixing, new_rec:~w",[NewRec]),
	gen_cache:update_record(?CACHE_JIXING, NewRec),
	{reply, NewRec, State};

handle_call({finish, _AccountID}, _From, State)->
	{reply, ok, State}.


handle_cast(_Request, State)->
	{noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason,_State) ->
    ok.

code_change(_OldVsn,State,_Extra) ->
    {ok, State}.

send_award()->
	%%取出所有运镖人数Y
	?INFO(yunbiao, "send award on time"),
	YUNbiao_num = mod_counter:get_counter(0, ?COUNTER_YUNBIAO_NUM),
	ZhuanyunList = gen_cache:tab2list(?CACHE_ZHUANYUN_REF),
	F = fun(Info)->
			N = Info#zhuanyun.zhuanyun_times,
			Populary=400+N*YUNbiao_num*1.5,
			PlayerName = mod_account:get_player_name(Info#zhuanyun.id)
			%%发邮件给玩家
			%% 例如mod_mail:send_sys_mail(["0915"],"Title","message,hello,how are you",[{289,3},{198,1}],100,999,100000,1).
%% 			mod_mail:send_sys_mail([PlayerName], "每天转运军功奖励", "恭喜你获得转运军功", GoodsList, 0, 0, 0, 0),
		end,
	[F(Info) || Info <- ZhuanyunList],
	%%清理数据
	gen_cache:remove_cache_data(?CACHE_ZHUANYUN_REF, 0),
	timer:apply_after(?SECONDS_PER_DAY, ?MODULE, send_award, []),
	ok.

get_jixing_rec_from_cache(Id)->
	?INFO(yunbiao,"get_jixing_rec_from_cache"),
	Reply =  case gen_cache:lookup(?CACHE_JIXING, yunbiao) of
			 	[]->
					?INFO(yunbiao,"not jixing record,insert a new one"),
					NewRec = get_new_jixing_rec(Id),
					?INFO(yunbiao, "new jixing rec = :~w",[NewRec]),
					gen_cache:insert(?CACHE_JIXING, NewRec),
					NewRec;
				[Rec] ->
					%%第二天重置
					case util:check_other_day(Rec#jixing.last_zhuanyun_time) of
						true ->
							?INFO(yunbiao, "the other day ,client request jixing message,get a reset jixing rec" ),
							NewRec = get_new_jixing_rec(Id),
							?INFO(yunbiao, "reset new jixing rec = :~w",[NewRec]),
							gen_cache:update_record(?CACHE_JIXING, NewRec),
							NewRec;
						fasle ->
							?INFO(yunbiao, "player request jixing message in the same day"),
							Rec
					end
			end,
	Reply.


get_new_jixing_rec(Id)->
	Num = mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES),
	Goldcount = data_yun_biao:get_goldcount_cost(Num),
	{UpYunShiPoint, AddFactor} = data_yun_biao:get_up_need_yunshipoint(1),

	?INFO(yunbiao,"Num:~w,Goldcount:~w,up_yunshi_point:~w,add_factor:~w",
                       [Num,Goldcount,UpYunShiPoint,AddFactor]),	

	NewRec = #jixing{fkey = yunbiao, starLevel=0,up_yunshi_point = UpYunShiPoint,
						goldcount = Goldcount,addfactor= round(1*100)},
	NewRec.