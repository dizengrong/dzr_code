-module (mod_team).

-include ("common.hrl").

-export([find_another_team_member/1, get_team_state/1]).

-export([init_team_ets/0,
		start_link/1,
		create_team/2,
		invite/2,
		add_team/2,
		accept_invite/2,
		approve/2,
		leave_scene/1, %%离开场景
		dismiss/1,     %%队长解散队伍
		fire/1,
		get_team_list/2,
		team_chat_window/1,
		team_chat/2,
		leave_team/1, %%离开队伍（用于重连的时候）
		enter_dungeon/2,
		resign_lead/1
		]).

%%其他模块
-export([prepare_team_battle/1]).

-define(ETS_TEAM_INDEX,ets_team_index).

%% gen_server callbacks   
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,   
     terminate/2, code_change/3]).   

%%为每个场景建立一个组队列表,按队长索引,记录场景中队伍个数以及相关信息
%%为每个id建立一个组队情况索引,记录该id在什么地图队伍,充当什么角色
%%对修改操作而言，两个表应该是同步的
%%考虑为这两个表的联动操作加入lock,保证数据一致性.
init_team_ets()->
	?INFO(team,"init 2 kind of ets for team"),
	ets:new(?ETS_TEAM_INDEX,[public,named_table,set,{keypos,#team_index.id}]),
	F_create_team_ets = fun(Scene_id)->
		ets:new(list_to_atom("ets_team_" ++ integer_to_list(Scene_id)), 
			[public,named_table,set,{keypos,#team.leader_id}])
	end,
	[F_create_team_ets(Scene_id) || Scene_id<-data_scene:get_all_dungeon()].


%% 组队模块调用函数
start_link(Id) ->   
    gen_server:start_link(?MODULE, {Id}, []).

create_team(Id,Scene_id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {create_team,{Id,Scene_id}}).

invite(Id,Name)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {invite,{Id,Name}}).
	
add_team(Id,Leader_name)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {add_team,{Id,Leader_name}}).
	
accept_invite(Id,Leader_id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {accept_invite,{Id,Leader_id}}).
	
approve(Id,Team_mate_id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {approve,{Id,Team_mate_id}}).

resign_lead(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {resign,{Id}}).
	
leave_scene(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {leave_scene,{Id}}).
	
dismiss(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {dismiss,{Id}}).

fire(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {fire,{Id}}).
	
get_team_list(Id,Scene_code)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {get_team_list,{Id,Scene_code}}).
	
team_chat_window(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {team_chat_window,{Id}}).
	
team_chat(Id,Content)->
	case find_another_team_member(Id) of
		false->
			?ERR(todo,"no team mate found, send error code");
		Another_id->
			PS = mod_player:get_player_status(Id),
			gen_server:cast(PS#player_status.team_pid, {team_chat,{Id,Another_id,Content}})
	end.
			
team_drop_items(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {team_drop_items,{Id}}).

enter_dungeon(Id,Scene_id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {enter_dungeon,{Id,Scene_id}}).

%% 其它模块调用函数
leave_team(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.team_pid, {leave_team,Id}).


%% TO-DO: 获取另一个成员，有则返回其playerId，否则返回false
-spec find_another_team_member(player_id()) -> player_id() | false.
find_another_team_member(Id) -> 
	PS = mod_player:get_player_status(Id),
	gen_server:call(PS#player_status.team_pid, {find_another_team_member,{Id}}).
	

%% TO-DO: 获取组队的状态
-spec get_team_state(player_id()) -> 
	false | {true, Leader::player_id(), Mate::player_id()}.
get_team_state(Id) -> 
	PS = mod_player:get_player_status(Id),
	gen_server:call(PS#player_status.team_pid, {get_team_state,{Id}}).
	
prepare_team_battle(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:call(PS#player_status.team_pid, {prepare_team_battle,{Id}}).
	

%%gen server函数
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


handle_call({find_another_team_member,{Id}}, _From, State) ->
	%% reply should be player_id() | false.
	Reply = record_find_another_team_member(Id),

					  
	{reply, Reply, State};

handle_call({get_team_state,{Id}}, _From, State) ->
	%%reply should be false | {true, Leader::player_id(), Mate::player_id()}.
	case ets:lookup(?ETS_TEAM_INDEX,Id) of
		[Team_index]->
			if
				Team_index#team_index.role == lead->
					?INFO(team,"find and return team mate id if it have"),
					Ets = get_ets_name(Team_index#team_index.scene_id),
					[Team] = ets:lookup(Ets,Id),
					if 
						Team#team.mate_id /= 0->
							Reply = {true,Team#team.leader_id,Team#team.mate_id};
						true->
							?INFO(team,"team only have the lead"),
							Reply = false
					end;
				Team_index#team_index.role == mate->
					Reply = false
			end;
		[]->
			?INFO(team,"not in any team"),
			Reply = false
	end,

	{reply, Reply, State};


handle_call({prepare_team_battle,{Id}}, _From, State) ->
	%%reply should be false | {true, Leader::player_id(), Mate::player_id()}.
	case ets:lookup(?ETS_TEAM_INDEX,Id) of
		[Team_index]->
			Ets = get_ets_name(Team_index#team_index.scene_id),
			[Team] = ets:lookup(Ets,Team_index#team_index.lead_id),
			if 
				Team#team.mate_id /= 0->
					?INFO(team,"2 members in a team"),
					Lead_list = mod_role:get_on_battle_list(Team#team.leader_id),
					Mate_list = mod_role:get_on_battle_list(Team#team.mate_id),
					Fun = fun(Role)->
						  
					    Nr = Role#role{gd_isBattle = Role#role.gd_isBattle+3} ,
						Nr
					end,
					Mate_list_new = lists:map(Fun, Mate_list),

					Reply = [{Team#team.leader_id,Lead_list},
							{Team#team.mate_id,Mate_list_new}];

				true->
					?INFO(team,"team only have the lead"),
					Reply = false
			end;
		[]->
			?INFO(team,"not in any team"),
			Reply = false
	end,

	{reply, Reply, State};


handle_call(_Request, _From, State) -> 
	Reply = ok,
	{reply, Reply, State}.

handle_cast({create_team,{Id,Scene_id}}, State) ->
	?INFO(team,"create a team for ~w,~w",[Id,Scene_id]),
	case can_create_team(Id,Scene_id) of
		ok->
			record_insert_team(Id,Scene_id),
			{ok,Bin} = pt_30:write(30000, {?TEAM_SUCCESS});
		{failure,Reason}->
			?ERR(team,"can't create team, reason ~w",[Reason]),
			{ok,Bin} = pt_30:write(30000, {?TEAM_FAIL})
	end,
	lib_send:send(Id,Bin),

	{noreply, State};

handle_cast({invite,{Id,Name}}, State) ->
	%%检查是否能邀请
	%%检查对方能否被邀请
	%%发送邀请请求
	?INFO(team,"invite ~w,~s",[Id,Name]),
	
	case can_invite(Id) of
		ok->
			{true,Mate_id} = mod_account:get_account_id_by_rolename(Name),
	
			case can_be_invited(Mate_id) of
				ok->
					[Team_index] = ets:lookup(?ETS_TEAM_INDEX,Id),
					{ok,Bin} = pt_30:write(30002, {Id, Name,Team_index#team_index.scene_id}),
					lib_send:send(Mate_id,Bin);
				{failure,Reason}->
					?INFO(team, "can't be invited because ~w",[Reason])
			end;
		{failure,Reason}->
			?ERR(team,"can't create team, reason ~w",[Reason])
	end,

	{noreply, State};

handle_cast({add_team,{Id,Leader_name}}, State) ->
	%%检查自己能否加入队伍
	%%检查队伍能否被加入
	%%发送加入请求
	?INFO(team,"add_team ~w,~s",[Id,Leader_name]),
	
	case can_be_invited(Id) of
		ok->
			{true,Leader_id} = mod_account:get_account_id_by_rolename(Leader_name),
			?INFO(team,"leader id is ~w",[Leader_id]),
			case can_invite(Leader_id) of
				ok->
					Info = mod_account:get_account_info_rec(Id),
					Level = mod_role:get_main_level(Id),
					{ok,Bin} = pt_30:write(30006, {Id, Info#account.gd_RoleName,
							Level,Info#account.gd_RoleID}),
					lib_send:send(Leader_id,Bin);
				{failure,Reason}->
					?INFO(team, "can't be invited because ~w",[Reason])
			end;
		{failure,Reason}->
			?ERR(team,"can't create team, reason ~w",[Reason])
	end,

	{noreply, State};

handle_cast({accept_invite,{Id,Leader_id}}, State) ->
	%%检查自己能否加入队伍
	%%检查队伍能否被加入
	%%加入队伍
	?INFO(team,"add_team ~w,~s",[Id,Leader_id]),
	
	case can_be_invited(Id) of
		ok->
			case can_invite(Leader_id) of
				ok->
					Team = record_join_team(Leader_id,Id),
					{ok,Bin1} = pt_30:write(30001, {?JOIN_SUCCESS,Team}),
					lib_send:send(Id,Bin1),

					{ok,Bin2} = pt_30:write(30001, {?INVITE_SUCCESS,Team}),
					lib_send:send(Leader_id,Bin2);

				{failure,Reason}->
					?INFO(team, "can't be invited because ~w",[Reason])
			end;
		{failure,Reason}->
			?ERR(team,"can't create team, reason ~w",[Reason])
	end,

	{noreply, State};

handle_cast({approve,{Id,Mate_id}}, State) ->
	%%检查自己能否加入队伍
	%%检查队伍能否被加入
	%%加入队伍
	?INFO(team,"Leader id ~w approve id ~w to join his team",[Id,Mate_id]),
	case can_be_invited(Mate_id) of
		ok->
			case can_invite(Id) of
				ok->
					Team = record_join_team(Id,Mate_id),

					{ok,Bin1} = pt_30:write(30001, {?INVITE_SUCCESS,Team}),
					lib_send:send(Id,Bin1),

					{ok,Bin2} = pt_30:write(30001, {?JOIN_SUCCESS,Team}),
					lib_send:send(Mate_id,Bin2);

				{failure,Reason}->
					?INFO(team, "can't approve because ~w",[Reason])
			end;
		{failure,Reason}->
			?ERR(team,"can't approve team, reason ~w",[Reason])
	end,

	{noreply, State};

handle_cast({resign,{Id}}, State) ->
	case record_resign_lead(Id) of
		{ok,New_team}->
			{ok,Bin} = pt_30:write(30004, {New_team}),
			lib_send:send(New_team#team.leader_id,Bin),
			lib_send:send(New_team#team.mate_id,Bin);
		{failure,Reason}->
			?DEBUG(team,"can't resign lead, reason is ~w",[Reason])
	end,
		
	{noreply, State};

handle_cast({leave_scene,{Id}}, State) ->
	case record_leave_team(Id) of
		{remove_team,Team}->
			{ok,Bin} = pt_30:write(30005, {?TEAM_LEAVE,Id}),
			send_team(Team,Bin);
		{leave_team,Team}->
			{ok,Bin} = pt_30:write(30005, {?TEAM_LEAVE,Id}),
			send_team(Team,Bin);
		{no_team}->
			?ERR(todo,"no team found for ~w",[Id])
	end,
		
	{noreply, State};


handle_cast({dismiss,{Id}}, State) ->
	case ets:lookup(?ETS_TEAM_INDEX, Id) of
		[Team_index]->
			if 
				Team_index#team_index.role == lead ->
					?INFO(team,"Id ~w will dismiss his team",[Id]),
					Team = record_remove_team(Team_index#team_index.scene_id,Id),
					{ok,Bin} = pt_30:write(30005, {?TEAM_DISMISS,Id}),
					send_team(Team,Bin);
					
					
				true->
					?DEBUG(team,"team mate tries to dismiss team, ignore it")
			end;
		[]->
			?INFO(team,"Id is not in any team, ignore it",[Id])
	end,
	{noreply, State};	

handle_cast({fire,{Id}}, State) ->
	case ets:lookup(?ETS_TEAM_INDEX, Id) of
		[Team_index]->
			if 
				Team_index#team_index.role == lead->
					case record_fire_team(Team_index#team_index.scene_id,Id) of
						{ok,Team}->
							?INFO(team,"send fire notice to team ~w",[Team]),
							{ok,Bin} = pt_30:write(30005, {?TEAM_FIRE,Id}),
							send_team(Team,Bin);
						no_teammate->
							?INFO(team,"no teammate to fire")
					end;								
				Team_index#team_index.role == mate->
					?DEBUG(team,"team mate tries to fire another id")
			end;
		[]->
			?INFO(team,"Id is not in any team, ignore it",[Id])
	end,
	{noreply, State};		

handle_cast({get_team_list,{Id,Scene_id}}, State) ->
	Team_list = record_get_team_list(Scene_id),
	{ok,Bin} = pt_30:write(30009,Team_list),
	lib_send:send(Id,Bin),
	{noreply, State};

handle_cast({team_chat_window,{Id}}, State) ->
	case ets:lookup(?ETS_TEAM_INDEX,Id) of
		[Team_index]->
			?INFO(team,"team found, pick up team and return"),
			Ets = get_ets_name(Team_index#team_index.scene_id),
			[Team] = ets:lookup(Ets,Team_index#team_index.lead_id),
			{ok,Bin} = pt_30:write(30011,{Id,Team}),
			lib_send:send(Id,Bin);
		[]->
			?ERR(todo,"Id ~w is not in any team, add error code",[Id])
	end,

 	{noreply, State};

handle_cast({team_chat,{Id,Another_id,Content}}, State) ->
	Another_info = mod_account:get_account_info_rec(Another_id),
	{ok,Bin} = pt_30:write(30012,{Another_info#account.gd_RoleName,Content}),
	lib_send:send(Id,Bin),

 	{noreply, State};

handle_cast({team_drop_items,{Id}}, State) ->
	case record_get_team(Id) of
		none->
			?INFO(team,"Id ~w is not in any team",[Id]);
		Team->
			{ok,Bin} = pt_30:write(30013,Team),
			lib_send:send(Id,Bin)
	end,
 	{noreply, State};

handle_cast({enter_dungeon,{Id,Scene_id}}, State) ->
	case record_find_another_team_member(Id) of
		false->
			?INFO(team,"request to enter dungeon without teammate"),
			mod_dungeon:client_enter(Id, Scene_id);
		Mate_id->
			mod_dungeon:client_enter(Id, Scene_id),
			mod_dungeon:client_enter(Mate_id, Scene_id)
	end,
 	{noreply, State};

handle_cast({leave_team,Id}, State) ->
	record_leave_team(Id),
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
	?INFO(team, "terminating relation for ~w",[Reason]),
	Id = get(id),

	record_leave_team(Id),

    ok.   
  
%%--------------------------------------------------------------------   
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}   
%% Description: Convert process state when code is changed   
%%--------------------------------------------------------------------   
code_change(_OldVsn, State, _Extra) ->   
    {ok, State}.   
  
%%内部函数

record_get_team(Id)->
	case ets:lookup(?ETS_TEAM_INDEX,Id) of
		[]->
			none;
		[Team_index]->
			Ets = get_ets_name(Team_index#team_index.scene_id),
			[Team] = ets:lookup(Ets,Team_index#team_index.lead_id),
			Team
	end.	

	
record_insert_team(Id,Scene_id)->
	Level = mod_role:get_main_level(Id),
	Info = mod_account:get_account_info_rec(Id),
	Team = #team{leader_id = Id,
		leader_level = Level,
		leader_name = Info#account.gd_RoleName,
		leader_career = Info#account.gd_RoleID, 
		scene_id = Scene_id
		
		},
	Ets = get_ets_name(Scene_id),
	ets:insert(Ets, Team),

	Team_index = #team_index{id = Id,
		scene_id = Scene_id,
		role = lead,	
		lead_id = Id},

	ets:insert(?ETS_TEAM_INDEX,Team_index),
	Team.

get_ets_name(Scene_id)->
	list_to_atom("ets_team_" ++ integer_to_list(Scene_id)).

can_create_team(Id,_Scene_id)->
	case ets:lookup(?ETS_TEAM_INDEX, Id) of
		[_Rec]->
			?INFO(team,"already in another team"),
			{failure,in_another_team};
		[]->
			ok
	end.

can_invite(Id)->
	case ets:lookup(?ETS_TEAM_INDEX,Id) of
		[Team_index]->
			Ets = get_ets_name(Team_index#team_index.scene_id),
			case ets:lookup(Ets,Id) of
			[Team]->
				if
					Team#team.state == pending ->
						ok;
					true->
						?INFO(team,"can't invite when it's not in pending state, record is ~w",[Team]),
						{failure,not_pending}
				end
			end;
		[]->
			?INFO(team,"didn't have a team"),
			{failure,no_team}
	end.

can_be_invited(Member_id)->
	case ets:lookup(?ETS_TEAM_INDEX, Member_id) of
		[_Rec]->
			?INFO(team,"already in another team"),
			{failure,in_another_team};
		[]->
			ok
	end.

record_join_team(Leader_id,Id)->
	[Team_index] = ets:lookup(?ETS_TEAM_INDEX, Leader_id),

	Ets = get_ets_name(Team_index#team_index.scene_id),

	[Old_team] = ets:lookup(Ets,Leader_id),
	
	Mate_info = mod_account:get_account_info_rec(Id),
	Mate_level = mod_role:get_main_level(Id), 

	New_team = Old_team#team{mate_id = Id,
						mate_level = Mate_level,
						mate_name = Mate_info#account.gd_RoleName,
						mate_career = Mate_info#account.gd_RoleID,
						state = ready},
	ets:insert(Ets, New_team),
	New_team_index = Team_index#team_index{id = Id,role = mate},
	ets:insert(?ETS_TEAM_INDEX,New_team_index),
	
	New_team.
	

record_resign_lead(Id)->
	case ets:lookup(?ETS_TEAM_INDEX, Id) of
		[Team_index]->
			Ets = get_ets_name(Team_index#team_index.scene_id),
			[Old_team] = ets:lookup(Ets,Id),
			case Old_team#team.mate_id of
				0->
					%% no mate in this team, can't resign leader
					{failure,no_mate};
				Mate_id->
					?INFO(team,"swap lead between lead ~w, mate ~w",[Id,Mate_id]),
					New_team = Old_team#team{leader_id = Old_team#team.mate_id,
							leader_name = Old_team#team.mate_name,
							leader_level = Old_team#team.mate_level,
							leader_career = Old_team#team.mate_career,

							mate_id = Old_team#team.leader_id,
							mate_name = Old_team#team.leader_name,
							mate_level = Old_team#team.leader_level,
							mate_career = Old_team#team.leader_career
							},

					[Lead_index] = ets:lookup(?ETS_TEAM_INDEX,Id),
					[Mate_index] = ets:lookup(?ETS_TEAM_INDEX,Mate_id),
					
					ets:delete(Ets,Id),
					ets:insert(Ets, New_team),

					?INFO(team,"update both lead id to new lead id"),
					ets:insert(?ETS_TEAM_INDEX,Lead_index#team_index{role = mate,lead_id = Old_team#team.mate_id}),
					ets:insert(?ETS_TEAM_INDEX,Mate_index#team_index{role = lead,lead_id = Old_team#team.mate_id}),
					{ok,New_team}
			end;
		[]->
			?INFO(team, "~w is not leader of any team"),
			{failure,not_leader}
	end.

record_get_team_list(Scene_id)->
	Ets = get_ets_name(Scene_id),
	ets:tab2list(Ets).

%%only team lead should call this logic, remove team and remove its record
%%the team and the other team member should also remove
%%不同状态下,Id为队长,队员的话,离开队伍对队伍的不同影响
%%team_state      lead               mate
%%pending         解散(队伍不再存在)  离开（队伍存在,状态变回pending）
%%ready           解散(队伍不再存在)  离开（队伍存在,状态变回pending）
%%playing         解散(队伍不再存在)  解散（队伍不再存在）
record_remove_team(Scene_id,Id)->
	%%clear records in ets, team index
	%%return old team record for send out messages
	Ets = get_ets_name(Scene_id),
	[Team] = ets:lookup(Ets,Id),
	
	ets:delete(Ets,Id),

	ets:delete(?ETS_TEAM_INDEX,Id),
	if 
		Team#team.mate_id /= 0 ->
			ets:delete(?ETS_TEAM_INDEX,Team#team.mate_id);
		true->
			?INFO(team,"no teammate, no need to change team index")
	end,

	Team.

%%only team mate should call this logic, leave team and remove its record
%%but the team and the other team member should still unchanged,team state change to pending
%%不同状态下,Id为队长,队员的话,离开队伍对队伍的不同影响
%%team_state      lead               mate
%%pending         解散(队伍不再存在)  离开（队伍存在,状态变回pending）
%%ready           解散(队伍不再存在)  离开（队伍存在,状态变回pending）
%%playing         解散(队伍不再存在)  解散（队伍不再存在）
record_leave_team(Scene_id,Lead_id,Mate_id)->
	%%clear records in ets, team index
	%%return old team record for send out messages
			
	Ets = get_ets_name(Scene_id),
	[Team] = ets:lookup(Ets,Lead_id),
	
	New_team = Team#team{mate_id = 0,
			    mate_name=none,
			    mate_level = 0,
			    mate_career = 0,
				state = pending},
	ets:insert(Ets,New_team),

	ets:delete(?ETS_TEAM_INDEX,Mate_id),

	Team.

record_fire_team(Scene_id,Lead_id)->
	Ets = get_ets_name(Scene_id),
	[Team] = ets:lookup(Ets,Lead_id),
	case Team#team.mate_id of
		0 ->
			no_teammate;
		Mate_id->
			New_team = Team#team{mate_id = 0,
			    mate_name=none,
			    mate_level = 0,
			    mate_career = 0,
				state = pending},
				ets:insert(Ets,New_team),

			ets:delete(?ETS_TEAM_INDEX,Mate_id),
			Team
	end.


%%spec leave_team(id)->{remove_team,#team{}}|{leave_team,#team{}|{no_team}
record_leave_team(Id)->
	%%不同状态下,Id为队长,队员的话,离开队伍对队伍的不同影响
	%%team_state      lead               mate
	%%pending         解散(队伍不再存在)  离开（队伍存在,状态变回pending）
	%%ready           解散(队伍不再存在)  离开（队伍存在,状态变回pending）
	%%playing         解散(队伍不再存在)  解散（队伍不再存在）

	case ets:lookup(?ETS_TEAM_INDEX,Id) of
		[Team_index]->
			?INFO(team,"get team state and role from ~w,and dipatch into 2 processes",[Team_index]),
			Ets = get_ets_name(Team_index#team_index.scene_id),
			[Team] = ets:lookup(Ets,Team_index#team_index.lead_id),
			case {Team_index#team_index.role,Team#team.state} of
				{lead,_State}->	
					record_remove_team(Team_index#team_index.scene_id,Id),
					Reply = {remove_team,Team};
				{mate,pending}->
					record_leave_team(Team_index#team_index.scene_id,Team_index#team_index.lead_id,Id),
					Reply = {leave_team,Team};
				{mate,ready}->
					record_leave_team(Team_index#team_index.scene_id,Team_index#team_index.lead_id,Id),
					Reply = {leave_team,Team};
				{mate,playing}->
					record_remove_team(Team_index#team_index.scene_id,Id),
					Reply = {remove_team,Team}
			end;
		[]->
			?INFO(team,"no team existing for ~w",[Id]),
			Reply = {no_team}
	end,
	
	Reply.

-spec record_find_another_team_member(integer())->integer()|false.
record_find_another_team_member(Id)->
	case ets:lookup(?ETS_TEAM_INDEX,Id) of
		[Team_index]->
			if
				Team_index#team_index.role == lead->
					?INFO(team,"find and return team mate id if it have"),
					Ets = get_ets_name(Team_index#team_index.scene_id),
					[Team] = ets:lookup(Ets,Id),
					if 
						Team#team.mate_id /= 0->
							Reply = Team#team.mate_id;
						true->
							?INFO(team,"team only have the lead"),
							Reply = false
					end;
				Team_index#team_index.role == mate->
					Reply = Team_index#team_index.lead_id
			end;
		[]->
			?INFO(team,"not in any team"),
			Reply = false
	end,
	Reply.

send_team(Team,Bin)->
	lib_send:send(Team#team.leader_id,Bin),
	if 
		Team#team.mate_id /= 0->
			lib_send:send(Team#team.mate_id,Bin);
		true->
			skip
	end.
