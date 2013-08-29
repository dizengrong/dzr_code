%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc 累积经验、离线经验或者其他名字
%%%
%%% @end
%%% Created :  1 Mar 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_accumulate_exp).

-include("mgeem.hrl").

%% 个人拉镖
-define(ACCUMULATE_EXP_PERSON_YBC, 1).
%% 宗族拉镖
-define(ACCUMULATE_EXP_FAMILY_YBC, 2).
%% 守边
-define(ACCUMULATE_EXP_PROTECT_FACTION, 3).
%% 刺探
-define(ACCUMULATE_EXP_SPY, 4).

%% 累积经验类型列表
-define(ACCUMULATE_ID_LIST, [1, 2, 3, 4]).

%% 默认可以领取的经验百分比
-define(DEFAULT_ACCUMULATE_RATE, 10).


%% API
-export([
         handle/1,
         loop/0,
         role_online/1,
         role_do_person_ybc/1,
         role_do_spy/1,
         role_do_family_ybc/1,
         role_do_protect_faction/1,
         role_exit_family/1,
		 do_update_lv/2,
         do_refresh_free/6,
		 do_fetch_all_accExp/2
        ]).

%% 用于处理跨天自动刷新经验的问题
loop() ->
    ok.

handle(Info) ->
    do_handle_info(Info),
    ok.

do_handle_info({Unique, Module, ?ACCUMULATE_EXP_VIEW, _R, RoleID, PID, _Line}) ->
    do_fetch_all(Unique, Module, ?ACCUMULATE_EXP_VIEW, RoleID, PID);
do_handle_info({Unique, Module, ?ACCUMULATE_EXP_REFRESH, R, RoleID, PID, _Line}) ->
    do_refresh(Unique, Module, ?ACCUMULATE_EXP_REFRESH, R, RoleID, PID);
do_handle_info({Unique, Module, ?ACCUMULATE_EXP_GET, _R, RoleID, PID, _Line}) ->
    do_fetch_all(Unique, Module, ?ACCUMULATE_EXP_GET, RoleID, PID);
do_handle_info({set_role_acc, _RoleID, _ID, _Days, _Date}) ->
    ok;
%% 	do_set_role_acc(RoleID, ID, Days, Date);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知消息", Info]),
    ok.

%% do_set_role_acc(RoleID, ID, Days, Date) ->
%%     common_transaction:t(
%%       fun() ->
%%               {ok, #r_role_accumulate_exp{list=List} = R} = mod_map_role:get_role_accumulate_exp(RoleID),
%%               {ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
%%               case lists:keyfind(ID, #r_accumulate_exp_info.id, List) of
%%                   false ->
%%                       NewList = [#r_accumulate_exp_info{id=ID, days=Days, last_done_date=Date, last_done_level=Level, rate=10} | List];
%%                   _ ->
%%                       NewList = lists:keyreplace(ID, #r_accumulate_exp_info.id, List, 
%%                                                  #r_accumulate_exp_info{id=ID, days=Days, last_done_date=Date, last_done_level=Level, rate=10})
%%               end,
%%               mod_map_role:set_role_accumulate_exp(RoleID, R#r_role_accumulate_exp{list=NewList})
%%       end).

%% VIP免费刷新
do_refresh_free(Unique, Module, Method, R, RoleID, PID) ->
    #r_role_accumutlate{rate=OldRate}=R,
	{ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
    case common_transaction:t(
           fun() ->
                   %% 计算是否成功刷新，VIP百分百成功率
                   RateSucc = 100,
                   case common_tool:random(1, 100) =< RateSucc of
                       true ->
                           NewRate = get_next_rate(OldRate);
                       false ->
                           NewRate = OldRate
                   end,
                   {RefDate, _} = erlang:localtime(),
                   NewRec = R#r_role_accumutlate{rate=NewRate,accstarday=RefDate},
                   mod_map_role:set_role_accumulate_exp(RoleID, NewRec),
                   NewRec
           end)
    of
        {atomic, NewRec} ->
				AccaulateExp = get_all_acc_exp(NewRec#r_role_accumutlate.list_rec),
				RateExp = erlang:round(NewRec#r_role_accumutlate.rate*AccaulateExp/100),
				NextExp = erlang:round(get_next_rate(NewRec#r_role_accumutlate.rate)*AccaulateExp/100),
				Rec = #m_accumulate_exp_view_toc{allexp = AccaulateExp,cangetexp = RateExp,nextexp = NextExp,gold = get_need_gold_by_level(Level),flag = get_color_screen(NewRec#r_role_accumutlate.rate)},
                Ref = #m_accumulate_exp_refresh_toc{gold=0,reason=?_LANG_ACCUMULATE_EXP_VIP_REF_OK},
				common_misc:unicast2(PID, Unique, Module, Method,Ref),
				common_misc:unicast2(PID, Unique, Module, ?ACCUMULATE_EXP_VIEW, Rec),
                ok;
        {aborted, Error} ->
            Reason = ?_LANG_ACCUMULATE_EXP_SYSTEM_ERROR_WHEN_REFRESH,
            ?ERROR_MSG("~ts:~w", ["刷新奖励时发生系统错误", Error]),
            common_misc:unicast2(PID, Unique, Module, Method, #m_accumulate_exp_refresh_toc{succ=false, reason=Reason})
    end.


%%查看角色累积的经验
do_fetch_all_accExp(RoleID,_View) ->
	Fetch = fun() ->
   				 case mod_map_role:get_role_accumulate_exp(RoleID) of
					{error, role_not_found} ->
			    		{error,role_not_found};
					{ok, R} ->	
                        {RefDate, _} = erlang:localtime(),
                        case R#r_role_accumutlate.accstarday =:= RefDate of
                            true ->                           
                                AccRate = R#r_role_accumutlate.rate;
                            false ->
                                AccRate = ?DEFAULT_ACCUMULATE_RATE
                        end,
						AccaulateExp = get_all_acc_exp(R#r_role_accumutlate.list_rec),                        
						RateExp = erlang:round(AccRate*AccaulateExp/100),                        
						NextExp = erlang:round(get_next_rate(AccRate)*AccaulateExp/100), 
				 		{ok,AccaulateExp,RateExp,NextExp,R,AccRate}
 		 		 end				
			end,		
	case common_transaction:t(Fetch) of
		{atomic, {ok,AllExp, NowExp, NextExp,Rec,RealRate}} ->                
                {ok,AllExp, NowExp, NextExp,Rec,RealRate};
		{atomic,{error,role_not_found}} ->
		    {error,?_LANG_ACCUMULATE_EXP_NOT_FIT};
        {aborted, _Error} ->
			{error,?_LANG_ACCUMULATE_EXP_NOT_FIT}
	end.	

do_clear_accExp(RoleID,R) ->
    Clear = fun() ->
                NewRec = R#r_role_accumutlate{list_rec=after_fectch(RoleID,R#r_role_accumutlate.list_rec),rate = ?DEFAULT_ACCUMULATE_RATE},    
                mod_map_role:set_role_accumulate_exp(RoleID, NewRec)
            end,
    case common_transaction:t(Clear) of
        {atomic,_} ->
            ok;
        {aborted,Error} ->
            ?ERROR_MSG("~ts:~w", ["获取累积经验时发生系统错误", Error])
    end.
%% 使用元宝刷新
do_refresh_use_gold(Unique, Module, Method, AccumulateExp, RoleID, PID) -> 
    #r_role_accumutlate{rate=Rate} = AccumulateExp,
    {ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
    case common_transaction:t(
           fun() ->
                   NeedGold = get_need_gold_by_level(Level),
                   case common_bag2:t_deduct_money(gold_any, NeedGold, RoleID, ?CONSUME_TYPE_GOLD_REFRESH_ACCUMULATE_EXP) of
                        {ok, NewRoleAttr} ->
                            ok;
                        {error, Reason} -> 
                            NewRoleAttr = null,
                            erlang:throw({error, Reason})
                   end,
                   %% 计算是否成功刷新
                   RateSucc = get_refresh_succ_rate(Rate),  
                   %% 记录元宝日志

                   case common_tool:random(1, 100) =< RateSucc of
                       true ->
                           Success = true,
                           NewRate = get_next_rate(Rate);
                       false ->
                           Success = false,
                           NewRate = Rate
                   end,   
                   {RefDate, _} = erlang:localtime(),
                   NewRec1 = AccumulateExp#r_role_accumutlate{rate=NewRate,accstarday=RefDate}, 
                   mod_map_role:set_role_accumulate_exp(RoleID, NewRec1),
                   {NeedGold, NewRate, NewRoleAttr,Success}
           end)
    of 
        {atomic, {NeedGold, NewRate, NewRoleAttr,Success}} ->
			NewRec = AccumulateExp#r_role_accumutlate{rate=NewRate}, 
			AccaulateExp = get_all_acc_exp(NewRec#r_role_accumutlate.list_rec),
			RateExp = erlang:round(NewRec#r_role_accumutlate.rate*AccaulateExp/100),
			NextExp = erlang:round(get_next_rate(NewRec#r_role_accumutlate.rate)*AccaulateExp/100),
			Rec = #m_accumulate_exp_view_toc{allexp = AccaulateExp,cangetexp = RateExp,nextexp = NextExp,gold = get_need_gold_by_level(Level),flag = get_color_screen(NewRec#r_role_accumutlate.rate)},
			case Success of
                true ->
                    Notice = lists:flatten(io_lib:format(?_LANG_ACCUMULATE_EXP_REF_OK, [NeedGold])),
                    Ref = #m_accumulate_exp_refresh_toc{gold=NeedGold,reason=Notice};
                false ->
                    Notice = lists:flatten(io_lib:format(?_LANG_ACCUMULATE_EXP_REF_FAIL, [NeedGold])),
                    Ref = #m_accumulate_exp_refresh_toc{succ=false,gold=NeedGold,reason=Notice}
            end,            
			common_misc:unicast2(PID, Unique, Module, Method,Ref),
			common_misc:unicast2(PID, Unique, Module, ?ACCUMULATE_EXP_VIEW, Rec),
            ChangeList = [
                              #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewRoleAttr#p_role_attr.gold},
                              #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.gold_bind}],
            common_misc:role_attr_change_notify({pid, PID}, RoleID, ChangeList),
            ok;
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    Reason = ?_LANG_ACCUMULATE_EXP_SYSTEM_ERROR_WHEN_REFRESH,
                    ?ERROR_MSG("~ts:~w", ["刷新奖励时发生系统错误", Error])
            end,
            do_refresh_error(Unique, Module, Method, Reason, PID)
    end,
    ok.


do_refresh_error(Unique, Module, Method, Reason, PID) ->
    R = #m_accumulate_exp_refresh_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).


%% 角色上线时调用
%% 用于初始化一些信息，如当前已经有几天的连续登录经验
role_online(RoleID) ->
    {ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
    case Level>19 of
        true ->
            do_update_lv(RoleID,Level);
        false ->
            ignore
    end,
    ok.

%% 玩家拉个人镖时调用
role_do_person_ybc(RoleID) ->
    do(RoleID, ?ACCUMULATE_EXP_PERSON_YBC),
    ok.

%% 玩家刺探时调用
role_do_spy(RoleID) ->
    do(RoleID, ?ACCUMULATE_EXP_SPY),
    ok.

do_update_lv(RoleID,NewLevel)->
   {DateToday, _} = erlang:localtime(),
   case common_transaction:t(
   fun() ->
   		 case mod_map_role:get_role_accumulate_exp(RoleID) of
			{error, role_not_found} ->
			    NewRec = do_add_role_allaccumulate_exp(RoleID,NewLevel,DateToday);%%玩家第一次累积
			{ok, R} ->	
			    NewRec = R#r_role_accumutlate{list_rec=update_role_task_lv(R#r_role_accumutlate.list_rec,NewLevel)}
 		 end,
  		 mod_map_role:set_role_accumulate_exp(RoleID, NewRec)
   end)
   of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["hook角色升级更新累积经验错误", Error]),
            ok
    end,                   
    ok.

do_ref_rate(RoleID) ->
	case mod_map_role:get_role_accumulate_exp(RoleID) of
		{error, role_not_found} ->
			{error,?_LANG_ACCUMULATE_EXP_NO};
		{ok, Rec} ->
			{ok,Rec}
	end.

do(RoleID, ID) ->
    case common_transaction:t(
           fun() ->
				   {ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
                   {DateToday, _} = erlang:localtime(),
                   case mod_map_role:get_role_accumulate_exp(RoleID) of
					  {error, role_not_found} ->
						  NewRec = do_add_role_allaccumulate_exp(RoleID,Level,DateToday);
					  {ok, Value} ->
							case get_right_task(Level,Value#r_role_accumutlate.list_rec,DateToday,ID) of
	      						 {ok,Rec} ->
		  							 NewRec = Value#r_role_accumutlate{list_rec=Rec};									 
          						 _ ->
		  							 NewRec = do_add_role_allaccumulate_exp(RoleID,Level,DateToday)
	   						 end	 						   
				   end,
				   mod_map_role:set_role_accumulate_exp(RoleID, NewRec)
           end)
    of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["hook角色完成累积经验动作时发生系统错误", Error]),
            ok
    end,                   
    ok.

%% 玩家拉宗族镖时调用
role_do_family_ybc(RoleID) ->
    do(RoleID, ?ACCUMULATE_EXP_FAMILY_YBC).

%% 玩家做守边任务时调用
role_do_protect_faction(RoleID) ->
    do(RoleID, ?ACCUMULATE_EXP_PROTECT_FACTION),
    ok.

%% 玩家退出宗族（包括被踢的情况)
role_exit_family(_RoleID) ->
    ok.

%% %% 用于主动通知玩家有累积经验可以领取
%% do_notify(RoleID, AccumulateExpList) ->
%%     List = lists:foldl(
%%              fun(AccumulateExp, Acc) ->
%%                      [get_info_from_r_to_p(RoleID, AccumulateExp) | Acc]
%%              end, [], AccumulateExpList),
%%     common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACCUMULATE_EXP, ?ACCUMULATE_EXP_NOTIFY, #m_accumulate_exp_notify_toc{list=List}).


%% 提升经验比例成功后升到的对立比例
%% 参数为当前的比例
%% 返回值为成功后的比例
get_next_rate(10) ->
    15;
get_next_rate(15) ->
    23;
get_next_rate(23) ->
    35;
get_next_rate(35) ->
    52;
get_next_rate(52) ->
    75;
get_next_rate(75) ->
    100;          
get_next_rate(100) ->
    100.

get_color_screen(10) ->
	0;
get_color_screen(15) ->
	1;
get_color_screen(23) ->
	1;
get_color_screen(35) ->
	2;
get_color_screen(52) ->
	2;
get_color_screen(75) ->
	3;
get_color_screen(100) ->
	4.

%% 参数：当前经验百分比
%% 返回值：提升成功的概率
get_refresh_succ_rate(10) ->
    100;
get_refresh_succ_rate(15) ->
    70;
get_refresh_succ_rate(23) ->
    45;
get_refresh_succ_rate(35) ->
    25;
get_refresh_succ_rate(52) ->
    15;
get_refresh_succ_rate(75) ->
    10.




%% 该活动每天可以做多少次
get_times_per_day_by_id(1) ->
    3;
get_times_per_day_by_id(2) ->
    1;
get_times_per_day_by_id(3) ->
    4;
get_times_per_day_by_id(4) ->
    4.

%% 刷新需要多少元宝
get_need_gold_by_level(Level) when Level >= 20 andalso Level < 40 ->
    2;
get_need_gold_by_level(Level) when Level >= 40 andalso Level < 60 ->
    4;
get_need_gold_by_level(Level) when Level >= 60 andalso Level < 80 ->
    6;
get_need_gold_by_level(Level) when Level >= 80 andalso Level < 100 ->
    8;
get_need_gold_by_level(Level) when Level >= 100 andalso Level < 120 ->
    10;
get_need_gold_by_level(Level) when Level >= 120 andalso Level < 140 ->
    10;
get_need_gold_by_level(Level) when Level >= 140 andalso Level < 160 ->
    12;
get_need_gold_by_level(_Level) ->
	100.


do_refresh(Unique, Module, Method, _R, RoleID, PID) ->
	case do_ref_rate(RoleID) of
		{error,_Reason} ->
			do_refresh_error(Unique, Module, Method, ?_LANG_ACCUMULATE_NOT_VALID_ID, PID);
		{ok,#r_role_accumutlate{rate=OldRate}=R} ->
                    case OldRate of
                        100 ->
                            do_refresh_error(Unique, Module, Method, ?_LANG_ACCUMULATE_EXP_MAX_RATE, PID);
						_ ->
                            do_refresh_use_gold(Unique, Module, Method, R, RoleID, PID)
					end
	end.

date_to_timestamp(Dates) ->
    Seconds1 = calendar:datetime_to_gregorian_seconds({Dates, {0,0,1}}),
    Seconds2 = calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}),
    Seconds1 - Seconds2.
    
timestamp_to_date(Timestamp) ->
    Seconds1 = calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}),
    Seconds2 = Timestamp + Seconds1,
    {Day,_Times} = calendar:gregorian_seconds_to_datetime(Seconds2),
    Day.



do_get_nextDay(StarDate,Num) ->
   timestamp_to_date(date_to_timestamp(StarDate)+86400*Num).

do_get_daysTask(DateStart,NCount,Level) ->
   TaskCls = #tasklist{lastleve=Level,thisdaynum=0,accstate=0,thisday=DateStart},
   lists:foldl(fun (_,NewList)-> [TaskCls#tasklist{thisday=do_get_nextDay(DateStart,length(NewList))}|NewList] end,[TaskCls],lists:duplicate(NCount, dummy)).
                               
do_add_role_allaccumulate_exp(RoleID,Level,ThisDay) ->
    TaskCls = do_get_daysTask(ThisDay,4,Level),
    PersonTask=#r_day_task{taskid=1,listask=TaskCls,daynum=5},    
	case Level<40 of
		true ->
			case Level<25 of
				true ->
					TaskList =[PersonTask];
				false ->
					Fmaily = PersonTask#r_day_task{taskid=2}, 
					TaskList =[PersonTask,Fmaily]
			end;
		false ->	
			Fmaily = PersonTask#r_day_task{taskid=2}, 
  		    Sb = PersonTask#r_day_task{taskid=3},
   		    Ct = PersonTask#r_day_task{taskid=4},
		    TaskList =[PersonTask,Fmaily,Sb,Ct]
    end,
    #r_role_accumutlate{roleid=RoleID,accstarday=ThisDay,list_rec=TaskList,isget=0,rate=?DEFAULT_ACCUMULATE_RATE}.
    


do_task_day(Srlist,ThisDay,Lv,TaskID) ->
    F =  fun(M,NewList) ->
			case M#tasklist.thisday =:= ThisDay of
			   true ->
			       case (M#tasklist.thisdaynum<get_times_per_day_by_id(TaskID)) of
                         true ->
							 case M#tasklist.thisdaynum=:=(get_times_per_day_by_id(TaskID)-1) of
									true ->
									   [M#tasklist{lastleve=Lv,accstate=1,thisdaynum=M#tasklist.thisdaynum+1}|NewList];
									false ->
									   [M#tasklist{lastleve=Lv,thisdaynum=M#tasklist.thisdaynum+1}|NewList]
							 end;
                         false ->
						    NewList
					end;
		 	  false ->
			  	  [M|NewList]
			end	     	
        end,
    Result = lists:foldl(F,[],Srlist),
    Del = fun(Old,NewList) ->
                case Old#tasklist.accstate=:=1 of
		     true ->
			    NewList;
             false ->
			    [Old|NewList]
		end
	  end,
    lists:foldl(Del,[],Result).

get_currtList_maxData(ScrList) ->
   F = fun(A,B) -> A#tasklist.thisday>B#tasklist.thisday end,
   [MaxDate|_T] = lists:sort(F,ScrList),
   do_get_nextDay(MaxDate#tasklist.thisday,1).

get_right_task(Lv,ScrList,ThisDay,TaskID) ->
    OtherTask = [X||X <- ScrList,X#r_day_task.taskid=/=TaskID],
    SpeclTask = [Y||Y <- ScrList,Y#r_day_task.taskid=:=TaskID],
    case SpeclTask of
	[SrcRec|T] ->
	    case [X||X <- SrcRec#r_day_task.listask, X#tasklist.thisday=:=ThisDay] of
		[] ->		
		   case SrcRec#r_day_task.daynum<5 of
                       true ->
                          MaxCurrentDate = get_currtList_maxData(SrcRec#r_day_task.listask),
                          Deal = lists:append(SrcRec#r_day_task.listask,do_get_daysTask(MaxCurrentDate,4-SrcRec#r_day_task.daynum,Lv));
                       false ->
                          NewList = do_task_day(SrcRec#r_day_task.listask,ThisDay,Lv,TaskID),
                          Nownum = length(NewList),
                          case Nownum<5 of
                              true ->
                                  Deal = lists:append(NewList,do_get_daysTask(get_currtList_maxData(NewList),4-Nownum,Lv));					   
			                  false ->
                                  Deal = NewList
                           end,
                           Deal		
		   end;
		[_|_] ->
		   Deal = do_task_day(SrcRec#r_day_task.listask,ThisDay,Lv,TaskID),
	       Deal
	    end,
	    NewSrcRec = SrcRec#r_day_task{listask = Deal,daynum= length(Deal)},
	    NewResult = lists:append(lists:append(T,[NewSrcRec]),OtherTask),
	    {ok,NewResult};
    [] ->
	    {error,?_LANG_ACCUMULATE_EXP_NOT_FIT}
    end.
    
do_create_newTask(Level,ThisDay,TaskID) ->
	TaskCls = do_get_daysTask(ThisDay,4,Level),
	#r_day_task{taskid=TaskID,listask=TaskCls,daynum=5}.

modiy_list(Scrlist,ID,Lv) ->
   {DateToday, _} = erlang:localtime(),
   SpeciD = [Y||Y <- Scrlist,Y#r_day_task.taskid=:=ID],
   case SpeciD of
       [] ->
           {ok,do_create_newTask(Lv,DateToday,ID)};
       [Rec|_] ->
	       case length(Rec#r_day_task.listask)>0 of
		      true ->
		            {ok,Rec};
		      false ->
		            {ok,do_create_newTask(Lv,DateToday,ID)}
	   end
   end.

update_role_task_lv(ScrList,Lv) ->
   case Lv>40 of
	   false ->
		   case Lv>25 of
			   true ->
                   {ok,FamliyYB} = modiy_list(ScrList,2,Lv),
                   {ok,LbList} = modiy_list(ScrList,1,Lv),
				   NewList = [FamliyYB,LbList];
			   false ->
				   NewList = ScrList
		   end;	   
	   true ->
           {ok,Sb} = modiy_list(ScrList,3,Lv),
           {ok,Ct} = modiy_list(ScrList,4,Lv),
           {ok,FamYB} = modiy_list(ScrList,2,Lv),
           {ok,LbList} = modiy_list(ScrList,1,Lv),
		   NewList = [Sb,Ct,FamYB,LbList]
   end,
   F = fun(X,List) ->
	  		[X#r_day_task{listask=update_role_lv(X#r_day_task.listask,Lv)}|List]
       end,
   lists:foldl(F,[],NewList).

update_role_lv(ScrList,Lv) ->
   {DateToday, _} = erlang:localtime(),
   F = fun(X,Newlist) ->
		case X#tasklist.thisday =:= DateToday of
			true ->
			    [X#tasklist{lastleve =Lv}|Newlist];
			false ->
			    [X|Newlist] 
		end
       end,
   lists:foldl(F,[],ScrList). 
	


%%取出三天并且要小于当前日期的任务累积,有多少算多少
get_minDate_three(Srclist) ->
   {FlagData, _} = erlang:localtime(),	
   F = fun(A,B) -> A#tasklist.thisday<B#tasklist.thisday end,
   SortList = lists:sort(F,Srclist),
   case length(SortList)>3 of
      true ->
          NewSort = lists:sublist(SortList,3);
      false ->
          NewSort = SortList 
   end,
   F2 = fun(X) ->
			 X#tasklist.thisday<FlagData
		end,
   lists:filter(F2,NewSort).
   
%%取得某个任务的累积记录
get_task_list(TaskID,SrcList) ->
   SpeclTask = [Y||Y <- SrcList,Y#r_day_task.taskid=:=TaskID],
   case SpeclTask of
	[] ->
	    [];
	[H|_] ->
	    get_minDate_three(H#r_day_task.listask)
   end.

%% 获得各种活动的每天的基本经验，没有乘以百分比
%% 显示给前端时需要先乘以百分比
do_get_exp_by_id(?ACCUMULATE_EXP_PERSON_YBC, Level, Times) ->
	BaseExp = erlang:round(12 * math:pow(Level, 1.7)),
	case Times of
		0 ->
			0;
		1 ->
			3*BaseExp;
		2 ->
			5*BaseExp;
		3 ->
			6*BaseExp
	end;
do_get_exp_by_id(?ACCUMULATE_EXP_FAMILY_YBC, Level, Times) ->
    erlang:round(250 * math:pow(Level, 1.7) * Times);
do_get_exp_by_id(?ACCUMULATE_EXP_PROTECT_FACTION, Level, Times) ->
    erlang:round(210 * math:pow(Level, 1.5) * Times);
do_get_exp_by_id(?ACCUMULATE_EXP_SPY, Level, Times) ->
    erlang:round(150 * math:pow(Level, 1.3) * Times).
%%取得总共的累积任务
get_all_acc_exp(SrcList) ->
   get_task_exp(SrcList,1)+get_task_exp(SrcList,2)+get_task_exp(SrcList,3)+get_task_exp(SrcList,4).
%%取得总共的累积经验
get_task_exp(SrcList,TaskID) ->
   F = fun(X,Sum) -> 
		 Sum+do_get_exp_by_id(TaskID,X#tasklist.lastleve,get_times_per_day_by_id(TaskID)-X#tasklist.thisdaynum)	
       end,
   ResultList = get_task_list(TaskID,SrcList),
   lists:foldl(F, 0,ResultList).

%%领取后重新插入新的五天记录
after_fectch(RoleID,SrcList) ->
	{ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
    [Y#r_day_task{listask=do_get_daysTask(date(),4,Level)}||Y <- SrcList].



do_fetch_all(Unique, Module, ?ACCUMULATE_EXP_VIEW, RoleID, PID) -> 
    {ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
	case do_fetch_all_accExp(RoleID,0) of
		{error,Reason} ->
			Rec = #m_accumulate_exp_view_toc{succ=false, reason=Reason};
		{ok,AllExp,Canexp,NextExp,_R,RealRate} ->
			Rec = #m_accumulate_exp_view_toc{allexp = AllExp,cangetexp = Canexp,nextexp = NextExp,gold = get_need_gold_by_level(Level),flag = get_color_screen(RealRate)}
	end,    
    common_misc:unicast2(PID, Unique, Module, ?ACCUMULATE_EXP_VIEW, Rec);
do_fetch_all(Unique, Module, ?ACCUMULATE_EXP_GET, RoleID, PID) ->                   
	case do_fetch_all_accExp(RoleID,1) of
		{error,Reason} ->
			do_fetch_error(Unique, Module, ?ACCUMULATE_EXP_VIEW, Reason, PID);
		{ok,_,Canexp,_,R,_} ->
			do_add_exp(Unique, Module,?ACCUMULATE_EXP_GET,RoleID,PID,Canexp,R),
			do_fetch_all(Unique, Module, ?ACCUMULATE_EXP_VIEW, RoleID, PID)
	end.	


do_add_exp(Unique, Module, Method, RoleID, PID,Exp,Rec) ->
    case common_transaction:t(
           fun() ->                 
                   {Exp, mod_map_role:t_add_exp(RoleID, Exp)}
           end)
    of 
        {atomic, {Exp, {exp_change, NewExp}}} ->
            R = #m_accumulate_exp_get_toc{addexp=Exp},
            common_misc:unicast2(PID, Unique, Module, Method, R),
            ExpChange = #p_role_attr_change{change_type=?ROLE_EXP_CHANGE, new_value=NewExp},
            DataRecord = #m_role2_attr_change_toc{roleid=RoleID, changes=[ExpChange]},
            do_clear_accExp(RoleID,Rec),
            hook_activity_schedule:hook_exp_change(RoleID, Exp),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord);
        {atomic, {Exp, {level_up, Level, RoleAttr, RoleBase}}} ->
            R = #m_accumulate_exp_get_toc{addexp=Exp},
            common_misc:unicast2(PID, Unique, Module, Method, R),
            do_clear_accExp(RoleID,Rec),
            hook_activity_schedule:hook_exp_change(RoleID, Exp),
            mod_map_role:do_after_level_up(Level, RoleAttr, RoleBase, Exp, ?DEFAULT_UNIQUE, true);
        {aborted, ?_LANG_ROLE2_ADD_EXP_EXP_FULL} ->
            DataRecord = #m_role2_exp_full_toc{text=?_LANG_ROLE2_ADD_EXP_EXP_FULL},
            common_misc:unicast2(PID, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_EXP_FULL, DataRecord);
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    Reason = ?_LANG_ACCUMULATE_EXP_SYSTEM_ERROR_WHEN_FETCH,
                    ?ERROR_MSG("~ts:~w", ["领取累积经验时发生系统错误", Error])
            end,
            do_fetch_error(Unique, Module, Method, Reason, PID)
    end.
    

 do_fetch_error(Unique, Module, Method, Reason, PID) ->
    R = #m_accumulate_exp_get_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).   

    





















