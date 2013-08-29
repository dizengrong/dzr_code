-module(mod_chat).
%% mod_chat:scene_chat(2077,[77]).
%% pp_chat:handle(16011,4000324,[33]).
-include("common.hrl").

-export([start_link/1, world_chat/2, private_chat/3, send_to_self/2,scene_chat/2,guild_chat/2,buy_horn/2,send_horn/2, send_private_chat/3,team_chat/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([world_chat2/2, private_chat2/2, send_to_self2/2,scene_chat2/2,guild_chat2/2,send_horn2/2,buy_horn2/2,team_chat2/2]).

-record(state, {player_id = 0}).

start_link({PlayerId})->
	gen_server:start_link(?MODULE, {PlayerId}, []).


world_chat(PlayerId, Content) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.chat_pid, 
					{message, world_chat2, [PlayerId, Content]}).

%% 场景聊天
scene_chat(PlayerId,Content)->
    ?INFO(chat,"PlayerId, Content:~w",[[PlayerId, Content]]),
    Ps = mod_player:get_player_status(PlayerId),
    gen_server:cast(Ps#player_status.chat_pid,
                    {message, scene_chat2, [PlayerId,Content]}).

%% 场景聊天
team_chat(PlayerId,Content)->
    ?INFO(chat,"PlayerId, Content:~w",[[PlayerId, Content]]),
    Ps = mod_player:get_player_status(PlayerId),
    gen_server:cast(Ps#player_status.chat_pid,
                    {message, team_chat2, [PlayerId,Content]}).

%% 公会聊天
guild_chat(PlayerId,Content)->
    ?INFO(chat,"PlayerId, Content:~w",[[PlayerId, Content]]),
    Ps = mod_player:get_player_status(PlayerId),
    gen_server:cast(Ps#player_status.chat_pid,
                    {message, guild_chat2, [PlayerId,Content]}).

private_chat(PlayerId, ReceiverName, Content) ->
	?INFO(chat,"PlayerId, ReceiverName, Content:~w",[[PlayerId, ReceiverName, Content]]),
	PS = mod_player:get_player_status(PlayerId),
	Pid = PS#player_status.chat_pid,
	?INFO(chat, "chat pid = ~w, is_alive = ~w", 
		[Pid, erlang:is_process_alive(Pid)]),
 
	gen_server:cast(PS#player_status.chat_pid, 
					{message, private_chat2, [PlayerId, ReceiverName, Content]}).

send_to_self(PlayerId, Content) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.chat_pid, 
					{message, send_to_self2, [PlayerId, Content]}).
%% 发送小喇叭
send_horn(Id, Content)->
	PS = mod_player:get_player_status(Id), 
	gen_server:cast(PS#player_status.chat_pid, 
					{message, send_horn2, [Id, Content]}).

buy_horn(Id, Num)->
	PS = mod_player:get_player_status(Id), 
	gen_server:cast(PS#player_status.chat_pid, 
					{message, buy_horn2, [Id, Num]}).

init({PlayerId})->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, PlayerId),
	mod_player:update_module_pid(PlayerId, ?MODULE, self()),
    {ok, #state{player_id = PlayerId}}.




handle_cast({message, Action, Args}, State) ->
	?INFO(chat, "Action = ~w, Args = ~w", [Action, Args]),
	?MODULE:Action(State, Args),
	{noreply, State}.

handle_call({message, Action, Args}, _From, State) ->
	?MODULE:Action(State, Args).

handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, State) ->
	?INFO(player, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.	

%% ====================== handle cast message =========================
world_chat2(State, [PlayerId, Content]) ->
	?INFO(world_chat,"PlayerId:~w,Content:~w",[PlayerId, Content]),
	case Content of
		[$g, $m, $: | GmCmd] ->
			case util:get_app_env(enable_gm) of
				false->
					send_world_chat(PlayerId, Content);
				true->			
					try
						[CmdCode | CmdParameters] = string:tokens(GmCmd, " "),
						CmdCode1 = list_to_integer(CmdCode),
						catch case pp_gm:handle(PlayerId, CmdCode1, CmdParameters) of
							{'EXIT',_Reason} -> ?INFO(gm, "wrong gm input", []);
							Result -> Result
						end
					catch
						Type:What ->
							?ERR(?MODULE, "PLAYER user gm failed: type:~w, waht:~w", [Type, What])
				end
			end;
		_ ->
			send_world_chat(PlayerId, Content)
	end,
	{noreply, State}.

scene_chat2(State, [PlayerId, Content]) ->
    ?INFO(scene_chat,"PlayerId:~w,Content:~w",[PlayerId, Content]),
    case Content of
        [$g, $m, $: | GmCmd] ->
            case util:get_app_env(enable_gm) of
                false->
                    send_scene_chat(PlayerId, Content);
                true->          
                    try
                        [CmdCode | CmdParameters] = string:tokens(GmCmd, " "),
                        CmdCode1 = list_to_integer(CmdCode),
                        catch case pp_gm:handle(PlayerId, CmdCode1, CmdParameters) of
                            {'EXIT',_Reason} -> ?INFO(gm, "wrong gm input", []);
                            Result -> Result
                        end
                    catch
                        Type:What ->
                            ?ERR(?MODULE, "PLAYER user gm failed: type:~w, waht:~w", [Type, What])
                end
            end;
        _ ->
            send_scene_chat(PlayerId, Content)
    end,
    {noreply, State}.

team_chat2(State, [PlayerId, Content]) ->
    ?INFO(scene_chat,"PlayerId:~w,Content:~w",[PlayerId, Content]),
    case Content of
        [$g, $m, $: | GmCmd] ->
            case util:get_app_env(enable_gm) of
                false->
                    send_scene_chat(PlayerId, Content);
                true->          
                    try
                        [CmdCode | CmdParameters] = string:tokens(GmCmd, " "),
                        CmdCode1 = list_to_integer(CmdCode),
                        catch case pp_gm:handle(PlayerId, CmdCode1, CmdParameters) of
                            {'EXIT',_Reason} -> ?INFO(gm, "wrong gm input", []);
                            Result -> Result
                        end
                    catch
                        Type:What ->
                            ?ERR(?MODULE, "PLAYER user gm failed: type:~w, waht:~w", [Type, What])
                end
            end;
        _ ->
            send_team_chat(PlayerId, Content)
    end,
    {noreply, State}.

guild_chat2(State, [PlayerId, Content]) ->
    ?INFO(scene_chat,"PlayerId:~w,Content:~w",[PlayerId, Content]),
    case Content of
        [$g, $m, $: | GmCmd] ->
            case util:get_app_env(enable_gm) of
                false->
                    send_scene_chat(PlayerId, Content);
                true->          
                    try
                        [CmdCode | CmdParameters] = string:tokens(GmCmd, " "),
                        CmdCode1 = list_to_integer(CmdCode),
                        catch case pp_gm:handle(PlayerId, CmdCode1, CmdParameters) of
                            {'EXIT',_Reason} -> ?INFO(gm, "wrong gm input", []);
                            Result -> Result
                        end
                    catch
                        Type:What ->
                            ?ERR(?MODULE, "PLAYER user gm failed: type:~w, waht:~w", [Type, What])
                end
            end;
        _ ->
            send_guild_chat(PlayerId, Content)
    end,
    {noreply, State}.

private_chat2(State, [PlayerId, ReceiverName, Content]) ->
	?INFO(chat,"Playid :~w, ReceiverName:~w, Content:~s",[PlayerId,ReceiverName,Content]),
	case mod_account:get_account_id_by_rolename(ReceiverName) of
		false -> %% 没有这个昵称的玩家
			{ok, Packet} = pt_err:write(16006),
			lib_send:send(PlayerId, Packet);
		{true, ReceiverPlayerId} ->
			case mod_player:is_online(ReceiverPlayerId) of
				false -> 
					{ok, Packet} = pt_err:write(16005),
					lib_send:send(PlayerId, Packet);
				{true, _ReceiverPS} ->
					send_private_chat(PlayerId, ReceiverPlayerId, Content)
			end
	end,
	{noreply, State}.
					
send_to_self2(State, [PlayerId, Content]) ->
	
	AccountRec = mod_account:get_account_info_rec(PlayerId),
	{ok, Packet} = pt_16:write(16000, [
			PlayerId,
			AccountRec#account.gd_RoleName,
			Content,
			1, 
			AccountRec#account.gd_Sex,
			mod_vip:get_vip_level(PlayerId),
			AccountRec#account.gd_AccountRank
	]),
	lib_send:send_by_id(PlayerId, Packet),
	{noreply, State}.

send_horn2(State, [Id, Content]) ->
	%%使用小喇叭，物品数目更新,423位小喇叭编号
	Horn_num = cache_items:getItemNumByItemID(Id, 1, 424),
    ?INFO(chat,"Horn_count is ~w",[Horn_num]),
	case Horn_num < 1 of
		false ->
			FilteredContent = lib_word_filter:filter_prohibited_words(Content),
			?INFO(chat, "Filtered content: ~w, original content: ~w", [FilteredContent, Content]),
			AccountRec = mod_account:get_account_info_rec(Id),
			{ok, BinData} = pt_16:write(16004, [
												Id,
												AccountRec#account.gd_RoleName,
												FilteredContent,
												AccountRec#account.gd_Sex,
												mod_vip:get_vip_level(Id)
												]),
			lib_send:send_to_all(BinData),
%% 			NotiItemList = lib_items:deleteSomeItems(Id,[{Cfg_item_id,1}],[]),
			NotiItemList = lib_items:deleteSomeItems(Id,[{424,1}],[]),
			{ok,Bin1} = pt_12:write(12001,NotiItemList),
			lib_send:send(Id,<<Bin1/binary>>),
			%% 成就通知
			mod_achieve:useHornNotify(Id,1);
		true ->
			?ERR(?MODULE,"Can not horn"),
			{ok, Packet} = pt_err:write(16007),
			lib_send:send_by_id(Id, Packet)
	end,
	{noreply, State}.

buy_horn2(_State, [Id, Num])->
    mod_items:buyItem(Id,9998,424,Num).

%% ====================== end hanle cast message ======================

%% ====================== handle call message =========================
%% ====================== end hanle call message ======================
			
send_world_chat(PlayerId, Content)->
	FilteredContent = lib_word_filter:filter_prohibited_words(Content),
	?INFO(chat, "Filtered content: ~w, original content: ~w", [FilteredContent, Content]),
	AccountRec = mod_account:get_account_info_rec(PlayerId),
	{ok, BinData} = pt_16:write(16000, [
			PlayerId,
			AccountRec#account.gd_RoleName,
			FilteredContent,
			1, %% TO-DO: LINE ID
			AccountRec#account.gd_Sex,
			mod_vip:get_vip_level(PlayerId),
			AccountRec#account.gd_AccountRank
		]),
	lib_send:send_to_all(BinData).

send_scene_chat(PlayerId, Content)->
    FilteredContent = lib_word_filter:filter_prohibited_words(Content),
    ?INFO(chat, "Filtered content: ~w, original content: ~w", [FilteredContent, Content]),
    AccountRec = mod_account:get_account_info_rec(PlayerId),
    {ok, BinData} = pt_16:write(16011, [
            PlayerId,
            AccountRec#account.gd_RoleName,
            FilteredContent,
            1, %% TO-DO: LINE ID
            AccountRec#account.gd_Sex,
            mod_vip:get_vip_level(PlayerId),
            AccountRec#account.gd_AccountRank
        ]),
    Same_scene_list=scene:get_same_scene_id(PlayerId),
    
    F = fun(OtherPlayerId) ->
            [OtherPlayerId]
        end,        
    L = lists:map(F, Same_scene_list),
    ?INFO(land,"get the scene players list is ~w",[L]),
    lib_send:send_to_scene(L, BinData).

send_team_chat(PlayerId, Content)->
    FilteredContent = lib_word_filter:filter_prohibited_words(Content),
    ?INFO(chat, "Filtered content: ~w, original content: ~w", [FilteredContent, Content]),
    AccountRec = mod_account:get_account_info_rec(PlayerId),
    {ok, BinData} = pt_16:write(16013, [
            PlayerId,
            AccountRec#account.gd_RoleName,
            FilteredContent,
            1, %% TO-DO: LINE ID
            AccountRec#account.gd_Sex,
            mod_vip:get_vip_level(PlayerId),
            AccountRec#account.gd_AccountRank
        ]),
    case mod_team:find_another_team_member(PlayerId) of
		false ->
			{ok, Packet} = pt_err:write(?ERR_CAN_NOT_IN_TEAM),
			lib_send:send_by_id(PlayerId, Packet);
		TeamPlayerId ->
			?INFO(land,"get the team player list is ~w",[TeamPlayerId]),
    		lib_send:send_by_id(TeamPlayerId, BinData)
	end.



send_guild_chat(PlayerId, Content)->
    FilteredContent = lib_word_filter:filter_prohibited_words(Content),
    ?INFO(chat, "Filtered content: ~w, original content: ~w", [FilteredContent, Content]),
    AccountRec = mod_account:get_account_info_rec(PlayerId),
    {ok, BinData} = pt_16:write(16012, [
            PlayerId,
            AccountRec#account.gd_RoleName,
            FilteredContent,
            1, %% TO-DO: LINE ID
            AccountRec#account.gd_Sex,
            mod_vip:get_vip_level(PlayerId),
            AccountRec#account.gd_AccountRank
        ]),
    ?INFO(chat,"start to get guild member"),
    L=guild:get_guild_member_list(PlayerId),
    F = fun(OtherPlayerId) ->
        [OtherPlayerId]
    end,
    FormatList = lists:map(F, L),
	case FormatList of
		[]-> FormatList2 = [[PlayerId]];
	    _->FormatList2=FormatList
	end,
    ?INFO(chat,"end to get guild member"),
   %% L=ets:match(?ETS_ONLINE, #ets_online{id='$1', _ = '_'}),
    ?INFO(land,"get the guild players list is ~w",[FormatList2]),
    lib_send:send_to_guild(FormatList2, BinData).

send_private_chat(SenderPlayerId, ReceiverPlayerId, Content) ->
	SenderAccountRec   = mod_account:get_account_info_rec(SenderPlayerId),
	FilteredContent    = lib_word_filter:filter_prohibited_words(Content),
	ReceiverAccountRec = mod_account:get_account_info_rec(ReceiverPlayerId),
	
	Sender_Rec =mod_role:get_main_role_rec(SenderPlayerId),
	Receive_Rec = mod_role:get_main_role_rec(ReceiverPlayerId),
	Sender_level = Sender_Rec#role.gd_roleLevel,
	Receive_level = Receive_Rec#role.gd_roleLevel,

	Sender_guild_name = guild:get_guild_name(SenderPlayerId),

	Receive_guild_name = guild:get_guild_name(ReceiverPlayerId),
	{ok, Packet} = pt_16:write(16003, [
			SenderPlayerId, 
			SenderAccountRec#account.gd_RoleName, 
			FilteredContent, 
			1, 
			ReceiverPlayerId, 
			ReceiverAccountRec#account.gd_RoleName,
			SenderAccountRec#account.gd_RoleID,
			ReceiverAccountRec#account.gd_RoleID,
			Sender_level,
			Receive_level,
			Sender_guild_name,
			Receive_guild_name
		]),
	lib_send:send_by_id(SenderPlayerId, Packet),
	case gen_cache:lookup(?CACHE_BLACK_LIST, {ReceiverPlayerId, SenderPlayerId}) of
		[] ->lib_send:send_by_id(ReceiverPlayerId, Packet);
		__ ->ok
	end.
	