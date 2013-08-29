-module(scene).
-behaviour(gen_server).

-include("common.hrl").

-define(scene_pid, get_scene_pid(ID)).

-export([start_link/1, init/1, handle_cast/2, handle_call/3, handle_info/2, terminate/2, code_change/3]).

%% protocol interfaces
-export(
	[
	 	fly/4,
		get_near_cell/3,
		get_scene_tab/2, 
		go_back/2,
		go_to/2, 
		go_to/4, 
		move_check/2, 
		player_enter/2, 
		player_move/2, 
		scene_jump/2 
	]).

-export(
	[	
	 	can_move/3,
		get_cell_info/3, 
		get_position/1, 
		get_same_scene_id/1,
		set_scene_state/3, 
		clear_scene_state/2,
		die/1,
		write_app_string/1
	]).

-type cell() :: integer().

%% scene useful function
%% (1) can_move: check whether a point in the scene is movable.
%% (2) get_position: return the position information {SceneID, X, Y} where the player is in 
%% (3) go_to: go to a specified point immediately if the point is movable

%================================================================================================
% call back functions
%================================================================================================

start_link(ID) ->
	?INFO(scene, "ID = ~w", [ID]),
	gen_server:start_link(?MODULE, ID, []).

%% we put the record #player_cell into the 'state' 
%% to optimize the original code
init(ID) ->
	process_flag(trap_exit, true),
	put(id, ID),
	mod_player:update_module_pid(ID, ?MODULE, self()),
	
	Position = 
		case gen_cache:lookup(?SCENE_CACHE_REF, ID) of
			[ ] -> scene_man:init_player_position(ID);
			[P] -> P
		end,
	
	Scene = Position#position.scene,
	X     = Position#position.x,
	Y     = Position#position.y,
	
	%% the rest of the fields in the player cell will be
	%% initialize by the enter_scene function
	{_, _, Num, _} = get_cell_info(Scene, X, Y),
	
	State = 
		#player_cell {
			player_id  = ID, 
			scene_id   = Scene, 
			x          = X,
			y          = Y,
			cell       = Num,
			path       = [] 
		},			 
    {ok, State}.

%% pt 11000 player move in the scene
%% *caution* server does not check this path!!

handle_cast({player_move, Path}, State = #player_cell {player_id = ID, scene_id = SceneID, x = X, y = Y}) ->
	?INFO(scene, "MovePath = ~w", [Path]),
	
	case check_move_lock() of
	true  -> NState = State;
	false -> 
		{C, R, N, Type} = get_cell_info(SceneID, X, Y),
		Tab = get_scene_tab(ID, SceneID),
		
		NState = State#player_cell {path = Path},
		ets:update_element(Tab, #player_cell.player_id, {#player_cell.path, Path}),
		
		{ok, Msg} = pt_11:write(11000, [ID, Path]),
		%% if player is in *dungeon*, we just have to broadcast the state to 
		%% his teammate, if exist. otherwise, we have to broadcast to all the players 
		%% in this player's vision
		
		case Type == ?SCENE_DUNGEON orelse 
			 Type == ?SCENE_MARSTOWER of
			false ->
				%% dungeon need not broadcast
				CellList = get_near_cell(N, C, R),
				?INFO(scene, "NearCell = ~w", [CellList]),
				broadcast_move(ID, Tab, Msg, CellList);
			true ->
				case mod_team:get_team_state(ID) of
					false -> ok;
					{true, ID, MemberID} -> %% player is captain
						case ets:lookup(Tab, MemberID) of
							[] -> ?ERR (scene, "can not find player in dungeon!"), ok;
							[#player_cell {send_pid = Spid}] ->
								lib_send:send(Spid, Msg),
								set_member_location(Tab, MemberID, Path)
						end;
					{true, _MemberID, ID} ->
						ok %% team member can not move!
				end
		end
	end,	
	{noreply, NState};

%% pt 11001 player enter the scene
handle_cast({player_enter, SceneID}, State = #player_cell {player_id = ID, x = X, y = Y, scene_id = SceneID}) ->
	%% two SceneIDs must match
	?INFO(scene, "calling player_enter"),
	unlock_move(),
	
	{C, R, N, Type} = get_cell_info(SceneID, X, Y),	
	%% real logic about scene
	NState = get_player_cell(State, N),
	Tab = get_scene_tab(ID, SceneID),
	ets:insert(Tab, NState),
	
	?INFO(scene, "Type = ~w", [Type]),
	case Type of 
		?SCENE_DUNGEON ->
			%% TODO: if find_another_team_member is true?
			case mod_team:find_another_team_member(ID) of
				false -> ok;
				MemID -> 
					case ets:lookup(Tab, MemID) of
						[MemState] ->
							{ok, SelfBin} = pt_11:write(11001, [State]),
							{ok, MemBin}  = pt_11:write(11001, [MemState]),
							lib_send:send(MemID, SelfBin),
							lib_send:send(ID, MemBin);
						[] -> ok
					end	
			end,
			mod_dungeon:sendProgress(ID);
		?SCENE_MARSTOWER ->
			mod_marstower:sendMonsterList(ID);
		_ ->  
			%% when Type of ?SCENE_CITY
		    MonsterList = mod_monster:get_all_monster(SceneID),
			{ok, MonBin} = pt_11:write(11405, MonsterList),
			lib_send:send(ID, MonBin),

			CellList = get_near_cell(N, C, R),
			?INFO(scene, "CellList = ~w, calling broadcast player enter", [CellList]),
			broadcast_player_enter(NState, Tab, CellList)
			%% mod_monster:player_enter(NState, SceneID, CellList)
	end,
	{noreply, NState};

%% pt 11003 player move checking
handle_cast({move_check, PosX, PosY}, State = #player_cell{ player_id = ID, 
	scene_id = SceneID, x = X, y = Y, path = Path}) ->
	
	?INFO(scene, "move checking.. PoxX = ~w, PosY = ~w, X = ~w, Y = ~w, path = ~w", 
		  [PosX, PosY, X, Y, Path]),
	
	case check_move_lock() of
	true  -> 
		NState = State; 
	false ->
		case Path of
		[{NX, NY} | _] ->
			CanMove = can_move(SceneID, PosX, PosY),
			CheckP  = check_distance(PosX, NX, PosY, NY, ?MOVE_CHECK_SCOPE),
			CheckD  = check_distance(PosX, X,  PosY, Y,  ?MOVE_CHECK_SCOPE),
			
			if (CanMove =/= true) ->
					?ERR(scene, "Can not move to ~w!", [{PosX, PosY}]);
			   (CheckP =/= true) ->
					?ERR(scene, "Check path fail! target = ~w", [{NX, NX}]);
			   (CheckD =/= true) ->
					?ERR(scene, "Check Distance fail! target = ~w", [{PosX, PosY}]);
			   true ->
				   ok
			end,
			
			case CanMove andalso CheckP andalso CheckD of
				false ->
					NState = State,
					%% reset location?
					?ERR(scene, "Can not move from ~w: (~w, ~w) to (~w, ~w)", [SceneID, X, Y, NX, NY]);
				true  ->
					Tab = get_scene_tab(ID, SceneID),
					{C, R, O, T} = get_cell_info(SceneID, X, Y),
					{_, _, N, _} = get_cell_info(SceneID, PosX, PosY),
					
					NState = State#player_cell {path = tl(Path), x = PosX, y = PosY, cell = N}, 
					
					ets:update_element(Tab, ID, 
						[{#player_cell.path, tl(Path)},
						 {#player_cell.cell, N}, 
						 {#player_cell.x, PosX},
						 {#player_cell.y, PosY}]),
				
					{LeaveList, EnterList} = get_vision_change_cell(O, N, C, R),
					?INFO(scene, "Cell info Col = ~w, Row = ~w, Old = ~w, New = ~w", [C, R, O, N]),
					?INFO(scene, "Leave = ~w, Enter = ~w", [LeaveList, EnterList]),
					
					ets:insert(Tab, NState),
					case T of
						?SCENE_DUNGEON   -> ok;
						?SCENE_MARSTOWER -> ok;
						_ ->
						%% broadcast move check if player is not in dungeon 
						broadcast_move_check(NState, Tab, LeaveList, EnterList)
					end
			end;
		_ -> 
			NState = State,
			?ERR(scene, "Path = ~w, .. move check fail!", [Path])
		end
	end,
	{noreply, NState};

%% pt 11004
handle_cast({scene_jump, NSceneID}, State = #player_cell {scene_id = SceneID, x = X, y = Y})
  	when NSceneID =/= SceneID ->
	
	%% we don't need to check accessible any more
	{FromX, FromY} = data_jump_point:get_from(SceneID, NSceneID),
	case check_distance(FromX, X, FromY, Y, ?CAN_JUMP_SCOPE) of
		true -> 
			{ToX, ToY} = get_jump_point(SceneID, NSceneID),
			leave_scene(State, NSceneID, ToX, ToY),
			
			NState = State#player_cell {scene_id = NSceneID, x = ToX, y = ToY},	
			%% we save the state in every jump event(update gen_cache)
			save_state(NState);
		false ->
			NState = State
	end,
	{noreply, NState};

%% pt 11005 go back: 
%% SceneID must match
handle_cast({go_back, SceneID}, State = #player_cell {scene_id = SceneID}) ->
	[Scene] = ets:lookup(?ETS_SCENE_INFO, SceneID),
	Type = Scene#scene_info.type,
	?INFO(scene,"Type:~w",[Type]),
	case Scene#scene_info.type of
		?SCENE_CITY ->
			%% ignore this message;
			NState = State;
		_ ->
			{NSceneID, Nx, Ny} = 
				%% TODO: 
				case Type of 
					?SCENE_DUNGEON   -> data_jump_point:get_leave_dungeon(SceneID);
					?SCENE_MARSTOWER -> data_jump_point:get_leave_tower(SceneID);
					?SCENE_ARENA2 	 -> data_jump_point:get_leave_boss_scene(SceneID)
				end,

			leave_scene(State, NSceneID, Nx, Ny),
			NState = State#player_cell {scene_id = NSceneID, x = Nx, y = Ny},
			save_state(NState)
	end,
	{noreply, NState};
	
handle_cast({go_to, NSceneID, Nx, Ny}, State) ->
	case can_move(NSceneID, Nx, Ny) of
		false -> 
			?ERR(scene, "Can not move to ~w: {~w, ~w}", [NSceneID, Nx, Ny]),
			NState = State;
		true ->
			leave_scene(State, NSceneID, Nx, Ny),
			NState = State#player_cell {scene_id = NSceneID, x = Nx, y = Ny},
			save_state(NState)
	end,	
	{noreply, NState};


%% pt 11016 flying shoes
handle_cast({fly, SceneID, X, Y}, State = #player_cell {state = S, player_id = ID}) ->
	case S band ?SCENE_STATE_RB =/= 0 of
		true -> 
			?INFO(scene, "can not use flying shoes when escorting");
		false ->
			case mod_items:has_items(ID, 289, 1) of
			true ->
				mod_items:useNumByItemID(ID, 289, 1),
				go_to(ID, SceneID, X, Y);
			false ->
				ok
			end
	end,
	{noreply, State};

%% change the appearance of the player
%% send the 11011 back to the client
handle_cast({set_scene_state, App, Arg}, 
	State = #player_cell {state = OldApp, scene_id = SceneID, x = X, y = Y, player_id = ID}) ->
	
	?INFO(scene, "handling set scene state"),
			
	NApp = OldApp bor App,
	case App of
		?SCENE_STATE_RB -> 
			?INFO(scene, "RbData = ~w", [Arg]),
			NState = State#player_cell {state = NApp, rb_data = Arg};
		?SCENE_STATE_BATTLE ->
			NState = State#player_cell {state = NApp};
		?SCENE_STATE_DAZUO ->
			NState = State#player_cell {state = NApp};
		_ ->
			NState = State
	end,
	
	{C, R, N, _T} = get_cell_info(SceneID, X, Y),
	CellList = get_near_cell(N, C, R),
	
	Tab = get_scene_tab(ID, SceneID),
	ets:update_element(Tab, ID, {#player_cell.state, NApp}),
	
	?INFO(scene, "broadcast app change"),
	broadcast_app_change(ID, Tab, NState, CellList),
	{noreply, NState};

handle_cast({clear_scene_state, App}, 
	State = #player_cell {state = OldApp, scene_id = SceneID, x = X, y = Y, player_id = ID}) ->
	NApp = OldApp band (bnot App),
	
	NState = State#player_cell{state = NApp},

	{C, R, N, _T} = get_cell_info(SceneID, X, Y),
	CellList = get_near_cell(N, C, R),

	Tab = get_scene_tab(ID, SceneID),
	ets:update_element(Tab, ID, {#player_cell.state, NApp}),
	
	broadcast_app_change(ID, Tab, NState, CellList),
	{noreply, NState};

handle_cast(die, State) ->
	{stop, "Die", State};

handle_cast(Msg, State) ->
	?INFO(scene, "unknown message: ~w", [Msg]),
	{noreply, State}.

handle_info(Msg, State) ->
	?INFO(scene, "unknown message: ~w", [Msg]),
	{noreply, State}.

%% get the current position
handle_call(get_position, _From, State = #player_cell{scene_id = SceneID, x = X, y = Y}) ->
	Reply = {SceneID, X, Y},
	{reply, Reply, State};

%% get all the player's id in the scene
handle_call(get_same_scene_id, _From, State = #player_cell {player_id = ID, scene_id = SceneID}) ->
	Tab = get_scene_tab(ID, SceneID),
	MatchSpec = [{
		#player_cell {
			player_id = '$1',
			_ = '_'			    
		},
		[], ['$1']
	}],
	List = ets:select(Tab, MatchSpec),
	{reply, List, State};

%% for debug 
handle_call(Msg, _From, State) ->
	?INFO(scene, "unknown message: ~w", [Msg]),
	{reply, ok, State}.

terminate(Reason, State = #player_cell {x = X, y = Y, scene_id = SceneID}) ->
	?INFO(scene, "Scene terminate! Reason: ~w", [Reason]),
	save_state(State),
	
	ID  = State#player_cell.player_id,
	Tab = get_scene_tab(ID, SceneID),
	%% when terminating, we must broadcast the leave message to clear this player
	{C, R, N, _} = get_cell_info(SceneID, X, Y),
	CellList = get_near_cell(N, C, R),
	broadcast_player_leave(ID, Tab, CellList),
	ets:delete(Tab, ID),
	ets:delete(?ETS_SCENE_ROOM, ID).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%======================================================================================================
% scene's information functions;
%======================================================================================================

-spec get_scene_pid(player_id()) -> pid().
get_scene_pid(ID) ->
	Ps = mod_player:get_player_status(ID),
	Ps#player_status.scene_pid.

-spec open_scene(player_id(), scene_id()) -> ok.
open_scene(ID, SceneID) ->
	gen_server:call(?scene_pid, {open_scene, SceneID}).

%% internal functions
%% notice: client side's index begins from 0
%% but server side's index begins from 1...
-spec get_cell_info(scene_id(), xpos(), ypos()) -> 
	{CellCols, CellRows, CellNum, SceneType} when
											  
CellCols  :: integer(),  %% how many cells in a *row*;
CellRows  :: integer(),  %% how many cells in a *column*;
CellNum   :: integer(),  %% cell index, begin from 1
SceneType :: integer().  %% type of scene.

get_cell_info(SceneID, X, Y) ->
	[#scene_info {cellcols = C, cellrows = R, type = T}] = 
		ets:lookup(?ETS_SCENE_INFO, SceneID),
		
	CellNum = C * (Y div ?CELL_HEIGHT) + X div ?CELL_WIDTH + 1,
	{C, R, CellNum, T}.

%% get scene table returns the scene ets where the player in 
%% -spec get_scene_tab(player_id(), scene_id()) -> table().
get_scene_tab(ID, SceneID) ->
	case lists:member(SceneID, [?INIT_MAP]) of
		false -> 
			list_to_atom("map_" ++ integer_to_list(SceneID));
		true ->
			if (ID == 0) -> %% called by monster to get the whole list of virtual room
				lists:map(
					fun(N) ->
						list_to_atom("map_" ++ integer_to_list(SceneID) ++ "_" ++ integer_to_list(N))
					end, lists:seq(1, 20));
			true ->
				RoomID = 
				case ets:lookup(?ETS_SCENE_ROOM, ID) of
					[] -> random:uniform(20);
					[#scene_room{room_id = RID}] -> RID
				end,
				
				%% insert this record in scene room quietly
				ets:insert(?ETS_SCENE_ROOM, #scene_room {id = ID, scene_id = SceneID, room_id = RoomID}),
				
				list_to_atom("map_" ++ 
				integer_to_list(SceneID) ++ "_" ++
				integer_to_list(RoomID))
			end
	end.

-spec get_jump_point(scene_id(), scene_id()) -> {xpos(), ypos()}.
get_jump_point(OSceneID, NSceneID) ->
	Scene = data_scene:get(OSceneID),
	case Scene#scene.type of
		?SCENE_DUNGEON -> 
			data_scene:get_default_xy(NSceneID);
		_ ->
			data_jump_point:get_to(OSceneID, NSceneID)
	end.


leave_scene(State, NSceneID, Nx, Ny) ->
	?INFO(scene, "NScene: ~w, Nx: ~w, Ny: ~w", [NSceneID, Nx, Ny]),
	SceneID = State#player_cell.scene_id,
	ID      = State#player_cell.player_id,
	X       = State#player_cell.x,
	Y       = State#player_cell.y,
	
	%% FIXME: in dd's code, he uses try catch to handle this function
	%% and said that sometimes it will be strange to find out that 
	%% ets table did not contain player's ID
	
	%% (1) first delete the player data in the ets
	Scene   = data_scene:get(SceneID),
	Type    = Scene#scene.type,
	Tab     = get_scene_tab(ID, SceneID),
	ets:delete(Tab, ID),
	ets:delete(?ETS_SCENE_ROOM, ID),
	
	%% (2) lock the movement
	lock_move(),
	
	%% (3) send the jump packet, force the client to send back 11001 (player_enter)
	{ok, JumpBin} = pt_11:write(11004, [NSceneID, Nx, Ny]), 
	?INFO(scene,"NSceneID, Nx, Ny:~w",[[NSceneID, Nx, Ny]]),
	lib_send:send(ID, JumpBin),
	?INFO(scene, "Scene is ~w, ",[Scene]),
	case Type of
		?SCENE_DUNGEON -> 
			mod_dungeon:leave(ID, SceneID),
			case mod_team:find_another_team_member(ID) of
				false -> ok;
				MemID -> 
					case ets:lookup(Tab, MemID) of
						[] -> ok;
						[#player_cell {send_pid = Spid}] ->
							{ok, Bin} = pt_11:write(11002, [ID]),
							lib_send:send(Spid, Bin)
					end
			end;
		?SCENE_CITY -> 
			{C, R, N, _T} = get_cell_info(SceneID, X, Y),
			LeaveCells = get_near_cell(N, C, R),
			broadcast_player_leave(ID, Tab, LeaveCells);
		Other ->
			?INFO(scene,"type is ~w", [Other]), 
			{C, R, N, _T} = get_cell_info(SceneID, X, Y),
			LeaveCells = get_near_cell(N, C, R),
			broadcast_player_leave(ID, Tab, LeaveCells)
	end.

-spec save_state(State :: #player_cell {}) -> ok.
save_state(State) ->
	SID = State#player_cell.scene_id,
	ID  = State#player_cell.player_id,
	X   = State#player_cell.x,
	Y   = State#player_cell.y,
			 
	Updates = [{#position.scene, SID}, {#position.x, X}, {#position.y, Y}],
	gen_cache:update_element(?SCENE_CACHE_REF, ID, Updates).
	

-spec write_app_string(State :: #player_cell{}) -> string().
write_app_string(State) ->
	Str = write_app_string(State, 7, [], false),
	?INFO(bill, "Str = ~s", [Str]),
	Str.

write_app_string(_State, Index, Str, _) when Index < 0 -> Str;
write_app_string(State, Index, Str, Exist) ->
	StateBit = State#player_cell.state,
	TestBit = 1 bsl Index,
	
	case StateBit band TestBit == 0 of
		true ->
			%% the bit is not set, continue the next loop;
			write_app_string(State, Index - 1, Str, Exist);
		false ->
			case TestBit of
			?SCENE_STATE_RB -> 
				?INFO(yunbiao, "test bit = 1"),
				Data = State#player_cell.rb_data,
				NStr = lists:flatten(io_lib:format("0:~w", [Data])),
				?INFO(yunbiao, "NStr = ~w", [NStr]);
			_ ->
				NStr = ""
			end,
			
			if (NStr == []) -> 
				%% no data corresponed to this bit;
				write_app_string(State, Index - 1, Str, Exist);
			(Exist == false) ->
				write_app_string(State, Index - 1, NStr, true);
			true ->
				write_app_string(State, Index - 1, NStr ++ "," ++ Str, true)
			end
	end.
	
%====================================================================================================
% cell handling 
%====================================================================================================
%% get near cell gets the cell near to the CellN
%% near means the target cell's Y and X should not diff the CellN by 1

-spec get_near_cell(CellNum :: cell(), CellCol :: integer(), CellRow :: integer()) -> [cell()].
%% CellCol : How many cells in a *row*
%% CellRow : How many cells in a *column*

get_near_cell(N, C, R) ->
	if  (N == 1) ->  %% left upper cell
			[N, N + 1, N + C, N + C + 1];                                          
		(N == C) -> %% right upper cell
			[N - 1, N, N + C - 1, N + C];                                          
		(N == (R - 1) * C + 1) -> %% left lower cell;
			[N - C, N - C + 1, N, N + 1];                          
		(N == R * C) -> %% rigt lower grid;
			[N - C - 1, N - C, N - 1, N];                                      
		(N < C) -> %% first row;
			[N - 1, N, N + 1, N + C - 1, N + C, N + C + 1];                         
		(N rem C == 1) -> %% first column;
			[N - C, N - C + 1, N, N + 1, N + C, N + C + 1];                   
		(N rem C == 0) -> %% last column;
			[N - C - 1, N - C, N - 1, N, N + C - 1, N + C];                   
		(N > (R - 1) * C) ->  %% last row;
			[N - C - 1, N - C, N - C + 1, N - 1, N, N + 1];               
		true ->  %% internal grid
			[N - C - 1, N - C, N - C + 1, N - 1, N, N + 1, N + C - 1, N + C, N + C + 1]
	end.

get_scene_type(SceneID) ->
	Scene = data_scene:get(SceneID),
	Scene#scene.type.

 -spec get_vision_change_cell(Old :: cell(), New :: cell(), 
		CellCol :: integer(), CellRow :: integer()) -> [cell()].	

get_vision_change_cell(O, N, C, R) ->
	if (O == N) ->
		{[], []};
	true ->
		Ox = (O - 1) rem C + 1,
		Nx = (N - 1) rem C + 1,
		
		Oy = (O + C - 1) div C,
		Ny = (N + C - 1) div C,
		
		?INFO(scene, "Ox, Oy = {~w, ~w}", [Ox, Oy]),
		?INFO(scene, "Nx, Ny = {~w, ~w}", [Nx, Ny]),
		
		OList = get_surround_xy(Ox, Oy),
		NList = get_surround_xy(Nx, Ny),
		
		?INFO(scene, "OList = ~w, NList = ~w", [OList, NList]),
		
		LeaveList = [(Y - 1) * C + X || {X, Y} <- OList,
			X > 0, X =< C, Y > 0, Y =< R, check_distance(X, Nx, Y, Ny, 1) == false],
		EnterList = [(Y - 1) * C + X || {X, Y} <- NList, 
			X > 0, X =< C, Y > 0, Y =< R, check_distance(X, Ox, Y, Oy, 1) == false],
	
		?INFO(scene, "OldCell = ~w, NewCell = ~w", [O, N]),
		?INFO(scene, "Leave = ~w, Enter = ~w", [LeaveList, EnterList]),
		{LeaveList, EnterList}
	end.
	  
get_surround_xy(X, Y) ->
	[{X - 1, Y - 1}, {X, Y - 1}, {X + 1, Y - 1}, 
	 {X - 1, Y    }, {X, Y    }, {X + 1, Y    },
	 {X - 1, Y + 1}, {X, Y + 1}, {X + 1, Y + 1}].

get_player_cell(State, CellNum) ->
	ID      = State#player_cell.player_id,
	Account = player_db:get_account_rec(ID),
	Role    = mod_role:get_main_role_rec(ID),
	Ps      = mod_player:get_player_status(ID),
	
	State#player_cell {
		role_id        = Account#account.gd_RoleID,
		role_rank      = Account#account.gd_AccountRank,
		nickname       = Account#account.gd_RoleName, 
		cell           = CellNum,
		level          = Role#role.gd_roleLevel,	
		send_pid       = Ps#player_status.send_pid,
		move_queue_pid = Ps#player_status.move_queue_pid
	}.

%% only when player in dungeon can use this function 
%% to set member's location by leader
set_member_location(SceneTab, MemberID, Path) ->
	{X, Y} = lists:last(Path),
	ets:update_element(SceneTab, MemberID, [{#player_cell.x, X}, {#player_cell.y, Y}]).
	

%====================================================================================================
% broadcast functions
%====================================================================================================
%% get near cell gets the cell near to the CellN
%% near means the target cell's Y and X should not diff the CellN by 1
	
broadcast_move(ID, SceneTab, Msg, CellList) ->
	F = fun(Cell, List) ->
			%% MatchSpec select those move_queue_pid record which
			%% player_id is not equal the value ID
			MatchSpec = [{
				#player_cell {
					player_id = '$1',
					move_queue_pid = '$2',
					cell = Cell,
					_ = '_'
				}, 
				[{'=/=', '$1', ID}], 
				['$2']
			}],
			case ets:select(SceneTab, MatchSpec) of
				[] -> List;
				MatchList -> lists:append(MatchList, List) 
			end
		end,
	MqList = lists:foldl(F, [], CellList),
	?INFO(scene, "MqList = ~w", [MqList]),
	
	G = fun(Mq) ->
			move_queue:send_move_msg(Mq, Msg)
		end,
	lists:foreach(G, MqList).
	
broadcast_move_check(State, Tab, LeaveCells, EnterCells) ->
	%% 11002 leave scene
	%% 11001 enter scene
	ID = State#player_cell.player_id,
	SceneId = State#player_cell.scene_id,
	broadcast_player_leave(ID, Tab, LeaveCells),
	broadcast_player_enter(State, Tab, EnterCells).
	%% mod_monster:player_move_check(State, LeaveCells,  EnterCells, SceneId).


broadcast_enter_vision(ID, Tab, EnterMsg, EnterCell) ->
	%% ID certainly would not be in the EnterCell
	?INFO(scene, "enter vision, ID = ~w, EnterCell = ~w", [ID, EnterCell]),
	
	MatchSpec = [{
		#player_cell {
			player_id = '$1', 
			send_pid = '$2',
			cell = EnterCell,
			_ = '_'
		}, 
		[{'=/=', '$1', ID}], ['$2']
	}],
	
	SendList = ets:select(Tab, MatchSpec),
	lists:foreach(fun(Spid) -> lib_send:send(Spid, EnterMsg) end, SendList).
	
broadcast_leave_vision(ID, Tab, Msg, LeaveCell) ->
	?INFO(scene, "calling broadcast leave vision"),
	%% ID certainly would not be in the LeaveCell 
	MatchSpec = [{
		#player_cell {
			player_id = '$1', 
			send_pid  = '$2',
			cell = LeaveCell,
			_ = '_'
		}, 
		[{'=/=', '$1', ID}], [['$1', '$2']]
	}],
	SendList = ets:select(Tab, MatchSpec),
	
	%% when scene terminate we may also call this function	
	Sspid = 
		case ets:lookup(?ETS_ONLINE, ID) of
			[#ets_online {send_pid = SelfSendPid}] -> SelfSendPid;
			[] -> 0
		end,
	
	lists:foreach(
	  	fun([_OtherID, Spid]) -> 
			lib_send:send(Spid, Msg)
		end, SendList),

	if (Sspid =/= 0) ->
		lists:foreach(
			fun ([OtherID, _]) ->
				{ok, Bin} = pt_11:write(11002, [OtherID]),
				lib_send:send(Sspid, Bin)
			end, SendList);
	true -> 
		ok 
	end.

broadcast_player_enter(State, Tab, EnterCells) ->
	{ok, EnterMsg} = pt_11:write(11001, [State]),
	F = fun(EnterCell) ->
			broadcast_player_enter_1(State, Tab, EnterMsg, EnterCell)
		end,
	lists:foreach(F, EnterCells).

broadcast_player_enter_1(State, Tab, EnterMsg, EnterCell) ->
	?INFO(scene,"EnterMsg: ~w", [EnterMsg]),
	ID = State#player_cell.player_id,
	SelfSpid = State#player_cell.send_pid,
	?INFO(scene,"SelfSpid: ~w", [SelfSpid]),
	
	MatchSpec = [{
		#player_cell {
			player_id = '$1', 
			cell = EnterCell,
			_ = '_'
		}, 
		[{'=/=', '$1', ID}], 
		['$_'] %% return the whole record whose id is not ID
	}],
	StateList = ets:select(Tab, MatchSpec),
	
	?INFO(scene, "Player Enter: Cell = ~w, StateList = ~w", [EnterCell, StateList]),
	
	%% broadcast the enter message to the other player near us
	lists:foreach(
	  	fun(#player_cell {send_pid = Spid}) -> 
			?INFO(scene, "send_pid = ~w, sending player enter message", [Spid]),
			lib_send:send(Spid, EnterMsg) 
		end, StateList),
	
	%% notify us the other player's information!
	if (StateList =/= []) ->
		{ok, PlayersMsg} = pt_11:write(11001, StateList),
		lib_send:send(SelfSpid, PlayersMsg);
	true ->
		ok
	end.

broadcast_player_leave(ID, Tab, LeaveCells) ->
	{ok, Msg} = pt_11:write(11002, [ID]),
	F = fun(LeaveCell) -> broadcast_leave_vision(ID, Tab, Msg, LeaveCell) end,
	lists:foreach(F, LeaveCells).
	

broadcast_monster_enter(Tab, Msg, CellList) ->
	F = fun(Cell) ->
			broadcast_monster_enter_1(Tab, Msg, Cell)
		end,
	lists:foreach(F, CellList).

broadcast_monster_enter_1(Tab, Msg, Cell) ->
	MatchSpec = [{
		#player_cell {
			cell = Cell,			  
			send_pid = '$1',
			_ = '_'
		},
		[], ['$1']		  
	}],
	
	case ets:select(Tab, MatchSpec) of
		[] -> ok;
		SendIdList ->
			lists:foreach(fun(SendId) ->lib_send:send(SendId, Msg) end, SendIdList)
	end.

broadcast_app_change(ID, Tab, State, CellList) ->
	Str = write_app_string(State),
	?INFO(scene, "Str = ~w~n, State = ~w", [Str, State]),
	App = State#player_cell.state,
	
	{ok, Msg} = pt_11:write(11051, {ID, App, Str}),
	?INFO(scene, "app change Msg = ~w", [Msg]),
	
	F = fun(Cell) ->
			broadcast_app_change_1(Tab, Msg, Cell)
		end,
	lists:foreach(F, CellList).

broadcast_app_change_1(Tab, Msg, Cell) ->
	MatchSpec = [{
		#player_cell {
			cell = Cell,			  
			send_pid = '$1',
			_ = '_'
		},
		[], ['$1']
	}],
	case ets:select(Tab, MatchSpec) of
		[] -> 
			?INFO(scene, "SendList = []"), 
			ok;
		SendList ->
			?INFO(scene, "sendList = ~w", [SendList]),
			lists:foreach(
				fun(SendId) ->
					lib_send:send(SendId, Msg)
				end, SendList)
	end.

%% new scene's optimized search funtion, using another ets table to help searching
%% CellList here must be ordered, but this can be guarantee by the get_surround_xy function
get_broadcast_id_list(_GridTab, _CellList) ->
	[].

%====================================================================================================
% help functions
%====================================================================================================

lock_move() ->
	erlang:put(lock_move, true).

unlock_move() ->
	erlang:put(lock_move, false).

check_move_lock() ->
	erlang:get(lock_move) == true.

check_distance(X1, X2, Y1, Y2) ->
	check_distance(X1, X2, Y1, Y2, 3).

check_distance(X1, X2, Y1, Y2, D) when D >= 0->
	abs(X1 - X2) =< D andalso
	abs(Y1 - Y2) =< D.
		
can_move(SceneID, X, Y) ->
	[#scene_info {cols = C}] = ets:lookup(?ETS_SCENE_INFO, SceneID),
	%% this first element of mask info is the scene id
	%% so the formula is Y * C + X + '2' here instead of '1'
	ets:lookup_element(?ETS_MASK_INFO, SceneID, Y * C + X + 2) =/= 49.
	   
%=====================================================================================================
% external interface: synchronized call
%=====================================================================================================

get_position(ID) ->
	gen_server:call(?scene_pid, get_position).

get_same_scene_id(ID) ->
	gen_server:call(?scene_pid, get_same_scene_id).

die(ID) ->
	gen_server:cast(?scene_pid, die).

%=====================================================================================================
% external functions asynchronized call
%=====================================================================================================

%% pt 11000: player move from one point to another
player_move(ID, PosList) ->
	gen_server:cast(?scene_pid, {player_move, PosList}).
  
%% pt 11001: player enter a scene
player_enter(ID, SceneID) ->
	gen_server:cast(?scene_pid, {player_enter, SceneID}).

%% pt 11003: move check
move_check(ID, {PosX, PosY}) ->
	gen_server:cast(?scene_pid, {move_check, PosX, PosY}).

%% pt 11004: jump to a new scene
scene_jump(ID, NewSceneID) ->
	gen_server:cast(?scene_pid, {scene_jump, NewSceneID}).

%% pt 11005: leave scene
go_back(ID, SceneID) ->
	gen_server:cast(?scene_pid, {go_back, SceneID}).

%% pt 11008:  reset location
reset_location(ID, X, Y) ->
	gen_server:cast(?scene_pid, {reset_location, X, Y}).

%% pt 11016: flying shoes
go_to(ID, SceneID) ->
	{DesX, DesY} = data_scene:get_default_xy(SceneID),
	go_to(ID, SceneID, DesX, DesY).

go_to(ID, SceneID, DesX, DesY) ->
	gen_server:cast(?scene_pid, {go_to, SceneID, DesX, DesY}).

set_scene_state(ID, Appearance, Arg) ->
	gen_server:cast(?scene_pid, {set_scene_state, Appearance, Arg}).

clear_scene_state(ID, Appearance) ->
	gen_server:cast(?scene_pid, {clear_scene_state, Appearance}).

fly(ID, SceneID, DesX, DesY) ->
	gen_server:cast(?scene_pid, {fly, SceneID, DesX, DesY}).







