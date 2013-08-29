%%%------------------------------------
%%% @Module     : mod_relationship
%%% @Author     : cjr
%%% @Email      : chenjianrong@4399.com
%%% @Created    : 2011.09.14
%%% @Description: 好友服务
%%%------------------------------------
-module(mod_relationship).
-behaviour(gen_server).
-include("common.hrl").

%% gen_server callbacks   
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,   
     terminate/2, code_change/3]).   

%% API   
-export([start_link/1,
		 add_friend/2,			%%add friend
		 approve_add_friend/3,	%%approve add friend
		 del_friend/2,			%%del friend
		 add_black_list/2,
		remove_black/2,
		query_friend/2,
		query_black/2,
		base_info/1,
		pray/2,
		recommend_friend/2     
	]).   

-export([
	get_familiar/2,
	add_familiar/3,
	is_friend/2
  ]).

%%主要为奴隶系统提供
-export([get_all_friend_list/1
		]).	


%%====================================================================   
%% API   
%%====================================================================   
%%--------------------------------------------------------------------   
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}   
%% Description: Starts the server   
%%--------------------------------------------------------------------   
start_link(Id) ->   
    gen_server:start_link(?MODULE, {Id}, []).

add_friend(Id,Name)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {add_friend,{Id,Name}}).

%%flag用来标示客户端发来的请求还是服务端发起的添加请求
approve_add_friend(Id,Friend_id,Flag)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {approve_add_friend,{Id,Friend_id,Flag}}).

del_friend(Id,Friend_id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {delete_friend,{Id,Friend_id}}).

add_black_list(Id,Friend_id)->
	del_friend(Id,Friend_id),
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {add_black_list,{Id,Friend_id}}).

remove_black(Id,Name)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {remove_black,{Id,Name}}).


query_friend(Id,Page)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {query_friend,{Id,Page}}).

query_black(Id,Page)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {query_black,{Id,Page}}).

base_info(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {base_info,Id}).
	
pray(Id, Friend_id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {pray,Id,Friend_id}).

	
recommend_friend(Id,Num)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.relation_pid, {recommend_friend,Id,Num}).

get_familiar(Id,Friend_id)->
	case mod_player:is_online(Id) of
		{true,PS}->
			gen_server:call(PS#player_status.relation_pid, {get_familiar,Id,Friend_id});
		false->
			0
	end.

add_familiar(Id,Friend_id,Num)->
	case gen_cache:lookup(?CACHE_FRIEND, {Id,Friend_id}) of
		[Friend]->
			New_friend = Friend#friend{familiar = Friend#friend.familiar + Num},
			mod_achieve:familiarNotify(Id,Friend#friend.familiar + Num),
			gen_cache:update_record(?CACHE_FRIEND, New_friend),
			true;
		Other->
			?INFO(relation,"can't find familiar, return as ~w",[Other]),
			false
	end.
	
is_friend(Id,Friend_id)->
	case gen_cache:lookup(?CACHE_FRIEND, {Id,Friend_id}) of
		[_Friend]->
			true;
		[]->
			false
	end.

-spec get_all_friend_list(integer())->list().
get_all_friend_list(Id)->
	Full_list = gen_cache:lookup(?CACHE_FRIEND, Id),
	?INFO(relation,"get all friend list for ~w",[Id]),
	Full_list.

%%====================================================================   
%% gen_server callbacks   
%%====================================================================   
  
%%--------------------------------------------------------------------   
%% Function: init(Args) -> {ok, State} |   
%%                         {ok, State, Timeout} |   
%%                         ignore               |   
%%                         {stop, Reason}   
%% Description: Initiates the server   
%%--------------------------------------------------------------------   
init({Id}) ->
	%%use ets table to maintain pray status, and we might also need to provide interface 
	%%to clear it.
	%%since ets can just use single index, we need to create 2 to enhance search performance
	erlang:process_flag(trap_exit, true),
	put(id,Id),	

	mod_player:update_module_pid(Id, ?MODULE, self()),

	{ok, {}}.

%%--------------------------------------------------------------------   
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |   
%%                                      {reply, Reply, State, Timeout} |   
%%                                      {noreply, State} |   
%%                                      {noreply, State, Timeout} |   
%%                                      {stop, Reason, Reply, State} |   
%%                                      {stop, Reason, State}   
%% Description: Handling call messages   
%%--------------------------------------------------------------------   

handle_call({get_familiar,Id,Friend_id}, _From, State) -> 
	case gen_cache:lookup(?CACHE_FRIEND, {Id,Friend_id}) of
		[Friend]->
			Reply = Friend#friend.familiar;
		Other->
			?INFO(relation,"can't get familiar, return as ~w",[Other]),
			Reply = 0
	end,
	{reply, Reply, State}.


%%add friend reqeust, check the add condition, and send the request if requester is online
%%check in friend list
%%check in black list
handle_cast({add_friend,{Id,Name}}, State) ->
	?INFO(relation,"add friend request from ~w to ~w",[Id,Name]),
	Ret = case mod_account:get_account_id_by_rolename(Name) of
		false->
			?INFO(relation,"wrong user name"),
			{false, ?ERR_WRONG_USER_NAME};
		{true,Friend_id}->
			case in_friend_list(Id,Friend_id) of
				true->
					?INFO(relation, "already friend"),
					{false, ?ERR_ALREADY_FRIEND};
				false->
					case in_black_list(Id,Friend_id) of
						true->
							?INFO(relation,"already in black list"),
							{false, ?ERR_ALREADY_IN_BLACK_LIST};
						false->
							case mod_player:is_online(Friend_id) of
								{true,_PS} ->
									Info = mod_account:get_account_info_rec(Id),
									?INFO(relation,"accounti info is ~w, id is ~w",[Info,Id]),
									My_name = Info#account.gd_RoleName,
									Sex = Info#account.gd_Sex,					
									Career_id = Info#account.gd_RoleID,					
		
									Level = mod_role:get_main_level(Id),
							
									{ok,Bin} = pt_18:write(18006,{Id,My_name,Level,Sex,Career_id}),
									lib_send:send(Friend_id,Bin),
									{true, Bin};
								false->
									?INFO(relation,"friend is not online"),
									{false, ?ERR_FRIEND_OFFLINE}
							end %%end mod_player:is_online(Friend_id)
					end %%end black list check
			end %%end friend list check
	end,

	case  Ret  of
		{false,ErrCode} ->
			mod_err:send_err_by_id(Id, ErrCode);
		{true, _Bin}	->
			skip
	end,
	
	{noreply, State};

handle_cast({approve_add_friend,{Id,Friend_id,_Flag}}, State) ->
	?INFO(relation,"add friend request from ~w to ~w",[Id,Friend_id]),

	case in_friend_list(Id,Friend_id) andalso in_friend_list(Friend_id,Id) of
		true->
			?INFO(relation, "already friend");
		false->
			case in_black_list(Id,Friend_id) orelse in_black_list(Friend_id,Id) of
				true->
					?INFO(relation,"already in black list");
				false->
					Friend = insert_friend_info(Id,Friend_id),
					insert_friend_info(Friend_id,Id),
					?INFO(relation,"friend id is ~w",[Friend_id]),
					case mod_player:is_online(Friend_id) of
						{true,_Friend_ps}->
							Level = mod_role:get_main_level(Friend_id),
							Prayable = case can_pray(Id,Friend_id) of 
								true->
%% 										?INFO(relation,"Prayable:~w",[Prayable]),
										?CAN_PRAY;
								false->
										?CAN_NOT_PRAY
							end,									

							Dynamic_info = #contact_dynamic_info{
								level = Level,
								online_status = ?ONLINE,
								prayable = Prayable};
%% 								?INFO(relation,"Prayable:~w",[Prayable]);
						_->
							%%todo, fill the last logout time
							Dynamic_info = #contact_dynamic_info{}
					end,

					{ok, Bin} = pt_18:write(18005,{Friend,Dynamic_info}),
						
					lib_send:send(Id,Bin)
			end %%end black list check
	end, %%end friend list check 
	{noreply, State};

handle_cast({delete_friend,{Id,Friend_id}}, State) ->
	?INFO(relation,"delete friend request from ~w to ~w",[Id,Friend_id]),
	case in_friend_list(Id,Friend_id) of
		true->
			?ERR(todo, "we'd better provide a key delete in gen cache to do that"),
			gen_cache:delete(?CACHE_FRIEND, #friend{key={Id,Friend_id}}),
			
			case in_friend_list(Friend_id,Id) of 
				true->
					?INFO(relation, "success removed for Id ~w, Friend_id ~w",[Id,Friend_id]),
					?ERR(todo, "we'd better provide a key delete in gen cache to do that"),
%% 					Player = mod_player:get_player_status(Id),
%% 					Info = mod_account:get_account_info_rec(Id),
%% 					mod_announcement:send_relationship(Player,Info),
					gen_cache:delete(?CACHE_FRIEND, #friend{key={Friend_id,Id}});
					
				false->
					?INFO(relation, "not a friend, abnormal and should not reach")
			end;
		false->
			?INFO(relation, "not a friend")
	end,
	{noreply, State};

handle_cast({add_black_list,{Id,Black_id}}, State) ->
	?INFO(relation,"add_black_list request from ~w to ~w",[Id,Black_id]),
	Info = mod_account:get_account_info_rec(Black_id),
	Name = Info#account.gd_RoleName,
	
	case in_black_list(Id,Black_id) of
				true->
					?INFO(relation, "already in black list");
				false->
					Black_info = mod_account:get_account_info_rec(Black_id),
							
					Black_sex = Black_info#account.gd_Sex,					
					Black_career_id = Black_info#account.gd_RoleID,					
		
					Black = #black_list{key = {Id,Black_id},
								role_name	=	Name,
								familiar	=	0,
								sex			=	Black_sex,
								career		= 	Black_career_id
							},
							
					gen_cache:insert(?CACHE_BLACK_LIST, Black)
					%%刷新好友列表不再显示已拉入黑名单的人

					
	end,
	{noreply, State};

handle_cast({remove_black,{Id,Name}}, State) ->
	?INFO(relation,"add_black_list request from ~w to ~w",[Id,Name]),
	%%先前传进的name是一个id哦
%% 	case mod_account:get_account_id_by_rolename(Name) of
%% 		false->
%% 			?INFO(relation,"wrong player name");
%% 		{true,Black_id} ->
%% 			case in_black_list(Id,Black_id) of
%% 				true->
%% 					?ERR(todo, "we'd better provide a key delete in gen cache to do that"),
%% 					gen_cache:delete(?CACHE_BLACK_LIST, #black_list{key={Id,Black_id}});
%% 				false->
%% 					?INFO(relation, "not a Black")
%% 			end
%% 	end,
%% 	{noreply, State};
	case in_black_list(Id,Name) of
		true->
			?ERR(todo, "we'd better provide a key delete in gen cache to do that"),
			gen_cache:delete(?CACHE_BLACK_LIST, #black_list{key={Id,Name}}),
			case in_black_list(Name,Id) of
				true ->
					gen_cache:delete(?CACHE_BLACK_LIST, #black_list{key={Name,Id}});
				false->
					?INFO(relation, "not a Black")
			end;
		false->
			?INFO(relation, "not a Black")
	end,
	{noreply, State};

handle_cast({query_friend,{Id,Page}}, State) ->
	?INFO(relation,"query_friend from ~w",[Id]),
	
	Full_list = gen_cache:lookup(?CACHE_FRIEND, Id),
	Total_friend_num = length(Full_list),
%% 	if                                         %%限制显示200人
%% 		Total_friend_num1 >= ?MAX_SHOW_FRIENDS_NUM ->
%% 			Total_friend_num = ?MAX_SHOW_FRIENDS_NUM;
%% 		true ->
%% 			Total_friend_num =Total_friend_num1
%% 	end,
	%% 	GZ1215(陈冠炜) 11:41:54
	%% 然后客户端这边，每页的item数量是9
	Friend_per_page = data_relationship:get_friend_page_size(),
	Start = (Page-1) * Friend_per_page+1,
	?INFO(relation,"Friend_list is ~w,start is ~w, Friend_per_page is ~w",[Full_list,Start, Friend_per_page]),

	F = fun(Friend, Acc) ->
		{_,Friend_id} = Friend#friend.key,
		case mod_player:is_online(Friend_id) of
			{true,_PS}->
				Prayable = case can_pray(Id,Friend_id) of       %%======================
					true ->                                     %%==2012-08-03 modify===
						?CAN_PRAY;
					false ->
						?CAN_NOT_PRAY
				end,                                            %%======================
				Contact_info = #contact_dynamic_info{
				level = mod_role:get_main_level(Friend_id),
				prayable = Prayable,
				online_status = ?ONLINE,
				last_logout_time = 0};
			false->
				Account_info = mod_account:get_account_info_rec(Friend_id),
				
				Contact_info = #contact_dynamic_info{
					level = 0,
					prayable = ?CAN_NOT_PRAY,
					online_status = ?OFFLINE,
					last_logout_time = Account_info#account.gd_LastLoginTime}
		end,
			
		[{Friend,Contact_info} | Acc]
	end,
	
	Info_list = lists:foldr(F,[],Full_list),
	
	%%是否在线>亲密度＞等级从大到小>玩家ID由小到大排
	F_sort = fun({Friend1,Contact_info1},{Friend2,Contact_info2})->
		{_Id,Friend1_id1} = Friend1#friend.key,
		{_Id,Friend1_id2} = Friend2#friend.key,
		if
			Contact_info1#contact_dynamic_info.online_status < Contact_info2#contact_dynamic_info.online_status->true;
			Contact_info1#contact_dynamic_info.online_status > Contact_info2#contact_dynamic_info.online_status->false;

			Friend1#friend.familiar > Friend2#friend.familiar->true;
			Friend1#friend.familiar < Friend2#friend.familiar->false;

			Contact_info1#contact_dynamic_info.level < Contact_info2#contact_dynamic_info.level->true;
			Contact_info1#contact_dynamic_info.level > Contact_info2#contact_dynamic_info.level->false;
			
			Friend1_id1 < Friend1_id2 -> true;
			true->		false
		end
	end,

	Sorted_list = lists:sort(F_sort, Info_list),
	
	Final_friend_list = if
			length(Sorted_list) =< Friend_per_page ->
				Sorted_list;
		 	true->
				lists:sublist(Sorted_list, Start, Friend_per_page)
	end,

	{ok,Bin} = pt_18:write(18000,{friend,{Final_friend_list,Total_friend_num,Page}}),
	lib_send:send(Id,Bin),

	{noreply, State};

handle_cast({query_black,{Id,Page}}, State) ->
	?INFO(relation,"query_black from ~w",[Id]),
	
	List = gen_cache:lookup(?CACHE_BLACK_LIST, Id),
	Total_black_num = length(List),
	%% 	GZ1215(陈冠炜) 11:41:54
	%% 然后客户端这边，每页的item数量是9
%% 	if                                         %%限制显示200人
%% 		Total_black_num1 >= ?MAX_SHOW_BLACK_NUM ->
%% 			Total_black_num = ?MAX_SHOW_BLACK_NUM;
%% 		true ->
%% 			Total_black_num =Total_black_num1
%% 	end,
	Black_per_page = data_relationship:get_friend_page_size(),
	Start = (Page-1) * Black_per_page+1,
	?INFO(relation,"Black_list is ~w,start is ~w, Friend_per_page is ~w",[List,Start, Black_per_page]),

	Black_list = if
			length(List) =< Black_per_page ->
				List;
		 	true->
				lists:sublist(List, Start, Black_per_page)
	end,

	F = fun(Black, Acc) ->
		{_,Black_id} = Black#black_list.key,
		case mod_player:is_online(Black_id) of
			{true,_PS}->
				Contact_info = #contact_dynamic_info{
					level = mod_role:get_main_level(Black_id),
					prayable = ?CAN_NOT_PRAY,
					online_status = ?ONLINE,
					last_logout_time = 0};
			false->
				Account_info = mod_account:get_account_info_rec(Black_id),
				
				Contact_info = #contact_dynamic_info{
					level = 0,
					prayable = ?CAN_NOT_PRAY,
					online_status = ?OFFLINE,
					last_logout_time = Account_info#account.gd_LastLoginTime}
		end,
			
		[{Black,Contact_info} | Acc]
	end,
	
	Info_list = lists:foldr(F,[],Black_list),
	
	{ok,Bin} = pt_18:write(18000,{black_list,{Info_list,Total_black_num,Page}}),
	lib_send:send(Id,Bin),

	{noreply, State};

handle_cast({base_info,Id}, State) ->
	Level = mod_role:get_main_level(Id),
	
	Popular = 0, 

	Can_send = mod_counter:get_counter(Id,?COUNTER_PRAY),        %%玩家剩余送出祝福数
	Send_max = data_relationship:max_pray_num(Level),	         %%玩家可送出祝福总数
	Can_recv = mod_counter:get_counter(Id,?COUNTER_PRAYED),      %%玩家剩余接受祝福数
	Recv_max = data_relationship:max_prayed_num(Level),          %%玩家可接受祝福总数
	
	?INFO(relation, "Can send is ~w, send_max ~w, can recv ~w, recv_max ~w",[Can_send,Send_max,Can_recv,Recv_max]),

 	{ok, Bin} = pt_18:write(18012, {Level,Popular,Can_send,Send_max,Can_recv,Recv_max}),
	lib_send:send(Id, Bin),

	{noreply, State};

handle_cast({pray,Id,Friend_id}, State) ->
	case can_pray(Id,Friend_id) of 
		true->
			%%添加祝福记录
			%%添加亲密度
			%%调用加金钱什么的接口
			%%调用任务/成就等接口
			
			?INFO(relation,"can pray"),
			[Friend] = gen_cache:lookup(?CACHE_FRIEND, {Id,Friend_id}),
			mod_counter:add_counter(Id,?COUNTER_PRAY),
			mod_counter:add_counter(Friend_id,?COUNTER_PRAYED),
			
									
			gen_cache:update_record(?CACHE_FRIEND, Friend#friend{last_pray_time = util:unixtime(),
							familiar = Friend#friend.familiar+1}),
			%% 成就通知
			mod_achieve:familiarNotify(Id,Friend#friend.familiar+1),
			%%todo, 
			?ERR(todo,"add something for pray bonus later"),
			%%%银币=int[(1-|祝福人的等级-被祝福人的等级|*0.006)*同等级每次祝福的银币]；
			%%%经验=int[(1-|祝福人的等级-被祝福人的等级|*0.006)*同等级每次祝福的经验]；
			Main_level = mod_role:get_main_level(Id),
			Friend_level = mod_role:get_main_level(Friend_id),
			Level_silver1 = data_relationship:get_level_silver(Main_level),%%祝福者同等级每次祝福的银币
			Level_silver2 = data_relationship:get_level_silver(Friend_level),%%被祝福者同等级每次祝福的银币
			Silver1 = trunc((1-abs(Main_level-Friend_level)*0.006)*Level_silver1),%%祝福者获得银币数
			Silver2 = trunc((1-abs(Main_level-Friend_level)*0.006)*Level_silver2),%%被祝福者获得银币数
			?INFO(relation,"Level_silver:~w",[Level_silver1]),

			Level_exp1 = data_relationship:get_level_exp(Main_level),%%祝福者同等级每次祝福的经验
			Level_exp2 = data_relationship:get_level_exp(Friend_level),%%祝福者同等级每次祝福的经验
			Exp1 = trunc((1-abs(Main_level-Friend_level)*0.006)*Level_exp1),%%祝福者获得经验数
			Exp2 = trunc((1-abs(Main_level-Friend_level)*0.006)*Level_exp2),%%被祝福者获得经验数
			?INFO(relation,"Level_Exp1:~w",[Level_exp1]),
			?INFO(relation,"Exp1:~w",[Exp1]),
			Main_role_id = mod_role:get_main_role_rec(Id),%%get role_id
			Friend_role_id =mod_role:get_main_role_rec(Friend_id),
			mod_role:add_exp(Id, {Main_role_id, Exp1}, 1),
			mod_role:add_exp(Friend_id, {Friend_role_id, Exp2}, 1),
			mod_economy:add_silver(Id, Silver1, 1),
			mod_economy:add_silver(Friend_id, Silver2, 1),

			%% 通知成就
			mod_achieve:friendSendNotify(Id,1),
			%%reply 18008 to both users
			Friend_info = mod_account:get_account_info_rec(Friend_id),
			?INFO(relation,"Friend_info:",[Friend_info]),
			{ok,Bin1} = pt_18:write(18008, {Friend_id,
					Friend_info#account.gd_RoleName,
					?PT_PRAY,
					Friend_info#account.gd_Sex,
					Exp1,
					Silver1,
					Friend_info#account.gd_RoleID,
					?CAN_NOT_PRAY
					}),
			?INFO(relation,"Bin1:~w",[Bin1]),
			lib_send:send(Id,Bin1),
	
			Can_pray_back = case can_pray(Friend_id,Id) of 
				true->
					?CAN_PRAY;
				false->
					?CAN_NOT_PRAY
			end,
			 
			Info = mod_account:get_account_info_rec(Id),
			{ok,Bin2} = pt_18:write(18008, {Id,
					Info#account.gd_RoleName,
					?PT_PRAYED,
					Info#account.gd_Sex,
					Exp2,
					Silver2,
					Info#account.gd_RoleID,
					Can_pray_back
					}),
			?INFO(relation,"Bin2:~w",[Bin2]),
			lib_send:send(Friend_id,Bin2);
		false->
			?INFO(relation,"can't pray")
	end,
		

	{noreply, State};

handle_cast({recommend_friend,Id,Num}, State) ->
	Id_list = random_friend_list(Num),

	?INFO(relation, "Name_list = ~w", [Id_list]),

	Id_list2 = filter_friend(Id,Id_list),
	?INFO(relation, "Name_list2 = ~w", [Id_list2]),
	
	Id_list3 = filter_black(Id,Id_list2),
	?INFO(relation, "Name_list3 = ~w", [Id_list3]),
	
	%%filter itself
	F_filter_self = fun(Friend_id)->
		if
			Friend_id == Id -> false;
			true->true
		end
	end,  

	Id_list4 = lists:filter(F_filter_self,Id_list3),
	
	?INFO(relation,"name list 4 is ~w",[Id_list4]),
	
	F_build_recommend_info = fun(Friend_id,Acc)->
		case mod_player:is_online(Friend_id) of
			{true,_PS}->
				Account_info = mod_account:get_account_info_rec(Friend_id),
				Friend = #friend{
					key = {Id,Friend_id},
					role_name	=	Account_info#account.gd_RoleName,
					familiar	=	0,
					sex			=	Account_info#account.gd_Sex,
					career		= 	Account_info#account.gd_RoleID,
					last_pray_time = 0
				},
				Contact_info = #contact_dynamic_info{
					level = mod_role:get_main_level(Friend_id),
					prayable = ?CAN_PRAY,
					online_status = ?ONLINE,
					last_logout_time = 0},
				[{Friend,Contact_info}|Acc];
			false->
				Acc
		end
	end,

	Id_list5 = lists:foldl(F_build_recommend_info , [], Id_list4),
	?INFO(relation,"name list 5 is ~w",[Id_list5]),
	{ok, Bin} = pt_18:write(18000, {recommend,{Id_list5,length(Id_list5),1}}),
	lib_send:send(Id, Bin),

	{noreply, State};


handle_cast(finish, State) ->
	{noreply, State}.

%%--------------------------------------------------------------------   
%% Function: handle_info(Info, State) -> {noreply, State} |   
%%                                       {noreply, State, Timeout} |   
%%                                       {stop, Reason, State}   
%% Description: Handling all non call/cast messages   
%%--------------------------------------------------------------------   
handle_info({'EXIT', _, Reason}, State) ->
    ?INFO(terminate,"exit:~w", [Reason]),
    {stop, Reason, State};


handle_info(_Info, State) ->   
    {noreply, State}.   
  
%%--------------------------------------------------------------------   
%% Function: terminate(Reason, State) -> void()   
%% Description: This function is called by a gen_server when it is about to   
%% terminate. It should be the opposite of Module:init/1 and do any necessary   
%% cleaning up. When it returns, the gen_server terminates with Reason.   
%% The return value is ignored.   
%%--------------------------------------------------------------------   
terminate(Reason, _State) ->
	?INFO(relation, "terminating relation for ~w",[Reason]),
    ok.   
  
%%--------------------------------------------------------------------   
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}   
%% Description: Convert process state when code is changed   
%%--------------------------------------------------------------------   
code_change(_OldVsn, State, _Extra) ->   
    {ok, State}.   
  
%%--------------------------------------------------------------------   
%%% Internal functions   
%%--------------------------------------------------------------------  
in_friend_list(Id,Friend_id)->
	case gen_cache:lookup(?CACHE_FRIEND, {Id,Friend_id}) of
		[]->
			false;
		_->
			true
	end.

in_black_list(Id,Friend_id)->
	case gen_cache:lookup(?CACHE_BLACK_LIST, {Id,Friend_id}) of
		[]->
			false;
		_->
			true
	end.

can_pray(Id,Friend_id)->
	%%当天没祝福过他
	%%祝福次数未满
	%%已祝福次数未满
	case gen_cache:lookup(?CACHE_FRIEND, {Id,Friend_id}) of
		[Friend]->
			case util:check_other_day(Friend#friend.last_pray_time) of
				true->
					Pray_count = mod_counter:get_counter(Id,?COUNTER_PRAY),
					My_level = mod_role:get_main_level(Id),
					?INFO(relation,"Pray_count:~w,My_level:~w",[Pray_count,My_level]),
					case data_relationship:reach_pray_max(Pray_count,My_level) of
						false->
							Prayed_count = mod_counter:get_counter( Friend_id,?COUNTER_PRAY),
							Friend_level = mod_role:get_main_level(Id),
						
							case data_relationship:reach_prayed_max(Prayed_count,Friend_level) of
								false->
									true;
								true->
									?INFO(relation,"can't prayed since max time reached count ~w, level ~w",[Prayed_count,Friend_level]),
									false
							end;
						true->	
							?INFO(relation,"can't pray since max time reached, count ~w, level ~w",[Pray_count,My_level]),
							false
					end;
				false->
					?INFO(relation,"can't pray already pray today ~w",[Friend#friend.last_pray_time]),
					false
			end; %% end check anohter day
		[]->
			?INFO(relation, "not a friend"),
			false
	end.
	

%%返回值为[id,...]
-spec random_friend_list(pos_integer()) -> list().
random_friend_list(Num)->
	Online_list = ets:tab2list(?ETS_ONLINE),
    OnlineInfoList = util:get_rand_list_elems(Online_list, Num),
	
	?INFO(relation, "Num = ~w, OnlineInfoList = ~w", [Num, OnlineInfoList]),
	
	F = fun(Ets_online)->
			Ets_online#ets_online.id
		end,
	
	[F(Info) || Info <- OnlineInfoList].

filter_friend(Id,List)->
	F = fun(Friend_id)->
		case gen_cache:lookup(?CACHE_FRIEND, {Id,Friend_id}) of
			[]->
				true;
			_->
				false
		end
	end, 

	lists:filter(F, List).

filter_black(Id,List)->
	F = fun(Friend_id)->
		case gen_cache:lookup(?CACHE_BLACK_LIST, {Id,Friend_id}) of
			[]->
				true;
			_->
				false
		end
	end, 

	lists:filter(F, List).

-spec insert_friend_info(integer(),integer())->#friend{}.
insert_friend_info(Id,Friend_id)->
	Friend_info = mod_account:get_account_info_rec(Friend_id),
				
	Friend_sex = Friend_info#account.gd_Sex,					
	Friend_career_id = Friend_info#account.gd_RoleID,					
	Name = Friend_info#account.gd_RoleName,	

	Friend = #friend{key = {Id,Friend_id},
						role_name	=	Name,
						familiar	=	0,
						sex			=	Friend_sex,
						career		= 	Friend_career_id
	},
					
	gen_cache:insert(?CACHE_FRIEND, Friend),
	%% 成就通知
	mod_achieve:friendNotify(Id),
	Friend.
