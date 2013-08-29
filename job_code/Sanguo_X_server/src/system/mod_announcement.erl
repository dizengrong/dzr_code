%% Author: 
%% Created: 2011-12-23
%% Description: 处理系统广播和公告
-module(mod_announcement).

-behaviour(gen_server).

%%
%% Include files
%%
%% -include("player_record.hrl").
-include("common.hrl").
%% -include("types.hrl").
%% -include("announcement.hrl").
%% -include("translation.hrl").

-define(HORN_REPUTATION, 3).
-define(HORN_REPUTATION_TIMES, 10).

-record(state, {account_id, nick_name, send_pids}).

%%
%% Exported Functions
%%
-export([
		 start_link/1,
		 send_relationship/2,
		 send_achievement/2,
		 send_run_business/1,
		 send_rob_success/3,
		 send_rob_fail/3,
		 send_purple_fragment/3,
		 send_purple_item/3,
		 send_online_arena/2,
		 send_online_award/1,
		 send_guild/2,
		 send_pet/1,
		 send_offline_arena/2,
		 send_horn/2,
		 send/3,
		 send_offline_arena_first_ranks/5,
		 send_boxing_host_changes/2,
		 send_flower/4,
         send_guild_donate/3,
         send_first_charge/3,
         send_world_boss_rank/4,
         send_world_boss_killer/3,
         send_new_card/3,
         send_exchange_card/4,
		 send_gen_event/1,
         send_player_gen_event/2,
		 send_announcement/2,
		 send_item_qualiy/3
		]).

-export([
		 init/1,
		 handle_cast/2,
		 handle_call/3,
		 handle_info/2,
		 code_change/3,
		 terminate/2
		]).

%%
%% API Functions
%%

%% 通告，供各个模块调用
start_link(PlayerId) ->
	gen_server:start_link(?MODULE, [PlayerId], []).

send_item_qualiy(PlayerId,_Info,Item)->
	send(PlayerId, ?SEND_ITEM_QUALIY, [Item]).

send_relationship(PlayerId, _Info) ->
	send(PlayerId, ?ADD_DELETE_FRIEND, []).

send_achievement(PlayerId, AchieveName) ->
	send(PlayerId, ?ANNOUNCE_ACHIEVEMENT, [AchieveName]).

send_run_business(PlayerId) ->
	send(PlayerId, ?ANNOUNCE_RUN_BUSINESS, []).

send_rob_success(PlayerId, VictimID, VictimID) ->
	send(PlayerId, ?ANNOUNCE_ROB_SUCCESS, [VictimID, VictimID]).

send_rob_fail(PlayerId, VictimID, VictimName) ->
	send(PlayerId,  ?ANNOUNCE_ROB_FAIL, [VictimID, VictimName]).

send_purple_fragment(PlayerId, ItemIdx, SourceType) ->
	send(PlayerId, ?ANNOUNCE_PURPLE_ITEM, [PlayerId, ItemIdx, 0, SourceType]).

send_purple_item(PlayerId, ItemIdx, SourceType) ->
	send(PlayerId,?ANNOUNCE_PURPLE_ITEM, [PlayerId, ItemIdx, 0, SourceType]).

%% get item is arena
send_online_arena(PlayerId, ItemID) ->
	send(PlayerId, ?ANNOUNCE_ONLINE_ARENA, [ItemID]).

send_online_award(PlayerId) ->
	send(PlayerId, ?ANNOUNCE_ONLINE_AWARD, []).

send_guild(PlayerId, GuildName) ->
	send(PlayerId, ?ANNOUNCE_GUILD, [GuildName]).

send_pet(PlayerId) ->
	send(PlayerId, ?ANNOUNCE_PET, []).

send_offline_arena(PlayerId, Wins) ->
	?INFO(announcement, "Wins = ~w", [Wins]),
	send(PlayerId,  ?ANNOUNCE_OFFLINE_ARENA, [Wins]).

send_horn(PlayerId, Content) ->
	send(PlayerId, ?ANNOUNCE_HORN, [Content]).

send_announcement(PlayerId, Content) ->
	send(PlayerId, ?ANNOUNCE_HORN, [Content]).

send_offline_arena_first_ranks(WinnerID, WinnerName, LoserID, LoserName, Rank)->
	?INFO(announcement,"winner ~w, loser id ~w, name ~w, rank ~w",[WinnerID, LoserID, LoserName, Rank]),
	send(WinnerID, ?ANNOUNCE_OFFLINE_ARENA_FIRST_RANKS, [WinnerID, WinnerName, LoserID, LoserName, Rank]).

	
%% BoxingType: 1-金币 2-银币 3-历练
send_boxing_host_changes(PlayerId, BoxingType)->
	send(PlayerId, ?ANNOUNCE_BOXING_HOST_CHANGES, [BoxingType]).

send_flower(PlayerId, ReceiverID, ReceiverName, Num) ->
	send(PlayerId, ?ANNOUNCE_FLOWER, [ReceiverID, ReceiverName, Num]).

send_guild_donate(PlayerId, GuildName, Donated) ->
    if
        Donated >= 50000 ->
            send(PlayerId, ?ANNOUNCE_GUILD_DONATE, [GuildName, Donated]);
        true -> void
    end.

send_first_charge(PlayerId, RewardItemID, RewardWorldID) ->
    send(PlayerId, ?ANNOUNCE_FIRST_CHARGE_REWARD, [PlayerId, RewardItemID, RewardWorldID]).

send_world_boss_rank(PlayerId, Rank, Silver, Reputation) ->
    send(PlayerId, ?ANNOUNCE_WORLD_BOSS_RANK, [Rank, Silver, Reputation]).

send_world_boss_killer(PlayerId, Silver, Reputation) ->
    send(PlayerId, ?ANNOUNCE_WORLD_BOSS_KILLER, [Silver, Reputation]).

send_new_card(PlayerId, CardID, Type) ->
    send(PlayerId, ?ANNOUNCE_NEW_CARD, [CardID, Type]).

send_exchange_card(PlayerId, LoserID, LoserName, CardID) ->
    send(PlayerId, ?ANNOUNCE_EXCHANGE_CARD, [LoserID, LoserName, CardID]).


%% 发送通告；ContentList的内容嘛，见协议文档或者后面的assemble_content……
-spec send(AnnID::integer(), Type::integer(), ContentList::list()) -> ok. 
send(AnnID,  Type, ContentList) ->
	?INFO(announcement, "Sending type = ~w", [Type]),
    AnnName = mod_account:get_player_name(AnnID),
	AnnGender = mod_account:get_roleSex_by_PlayerId(AnnID),
	ContentBin = assemble_content(AnnID, Type, ContentList),
    Ps = mod_player:get_player_status(AnnID),
	gen_server:cast(Ps#player_status.announcement_pid, {send_announcement, 
							 AnnID, AnnName, AnnGender, Type, ContentBin}).

%% 发送全局事件广播     TODO: 具体内容放到data文件里去？
send_gen_event(Event) ->
	StrToSend = 
		case Event of
			online_arena_apply_start ->
                data_translation("神翼角斗场开始报名啦！",[]);
			online_arena_battle_start ->
                data_translation("神翼角斗场战斗开始！",[]);
			online_arena_battle_end ->
                data_translation("神翼角斗场战斗结束！",[]);
			guild_competition_begin_apply ->
                data_translation("公会竞赛开始报名了少年们~",[]);
			guild_competition_final_apply ->
                data_translation("公会竞赛最后报名时间！！",[]);
			_->data_translation(Event,[])
		end,
	{ok, Bin} = pt_16:write(16007, [1, 1, StrToSend]),
	lib_send:send_to_all(Bin),
    ok.



%% 这是发给别人的……
-spec send_player_gen_event(account_id() | #player_status{} | pid(), #player_event{}) -> ok.
send_player_gen_event(AccountID, Event) when is_integer(AccountID) ->
    case mod_player:is_online(AccountID) of
        {true, PS} ->
            send_player_gen_event(PS, Event);
        false -> void
    end,
    ok;
send_player_gen_event(PS, Event) when is_record(PS, player_status) ->
    send_player_gen_event(PS#player_status.announcement_pid, Event);
send_player_gen_event(AnnPID, Event) when is_pid(AnnPID) ->
    gen_server:cast(AnnPID, {send_player_gen_event, Event}).

%%
%% gen_server 接口
%%
init([PlayerID]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, PlayerID),
	mod_player:update_module_pid(PlayerID, ?MODULE, self()),
	{ok, PlayerID}.

%% 通告
handle_cast({send_announcement, AnnID, AnnName, AnnGender, Type, ContentBin}, 
			State) ->
	?INFO(mod_announcement, "Type=~w, Content=~w", [Type, ContentBin]),
	Level =	case Type of
		?ANNOUNCE_RUN_BUSINESS ->
			get_broadcast_level(mod_role:get_main_level(AnnID));
		?ANNOUNCE_ONLINE_ARENA ->
			get_broadcast_level(mod_role:get_main_level(AnnID));
		_ -> 0
	    end,
	LineID = 1,
	{ok, Bin} = pt_16:write(16006, [Level, Type, LineID, AnnID, AnnName, AnnGender, ContentBin]),
	?INFO(announcement, "send_data=~w", [[Level, Type, LineID, AnnID, AnnName, AnnGender, ContentBin]]),
	lib_send:send_to_all(Bin),
	{noreply, State};

handle_cast({send_player_gen_event, Event}, State) ->
    Packet = parse_player_gen_event(Event),
    lib_send:send(State#state.send_pids, Packet),
    {noreply, State};

handle_cast(_Msg, State) ->
	?DEBUG(mod_announcement, "Got unknown message: ~w", [_Msg]),
	{noreply, State}.

handle_call(_Msg, _From, State) ->
	?DEBUG(mod_announcement, "Got unknown message from ~w: ~w", [_From, _Msg]),
	{noreply, State}.

handle_info(_Info, State) ->
	?DEBUG(mod_announcement, "handle_info called: ~w", [_Info]),
	{noreply, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
	?INFO(mod_announcement, "terminate called, Reason: ~w, State: ~w", [_Reason, _State]),
    ok.

%%
%% Local Functions
%%

assemble_content(_Player, ?SEND_ITEM_QUALIY, [Content]) ->
	pt:write_string(Content);

assemble_content(_Player, ?ADD_DELETE_FRIEND, []) ->
	<<>>;
assemble_content(_Player, ?ADD_DELETE_FRIEND, [AchName]) ->
	pt:write_string(AchName);

assemble_content(_Player, ?ANNOUNCE_ACHIEVEMENT, [AchName]) ->
	pt:write_string(AchName);
assemble_content(_Player, ?ANNOUNCE_RUN_BUSINESS, []) ->
	<<>>;
assemble_content(_Player, ?ANNOUNCE_ROB_SUCCESS, [RobberID, RobberName]) ->
	ContentStrPart1 = lists:flatten(io_lib:format("~w,", [RobberID])),
	ContentStr = ContentStrPart1 ++ RobberName,
	pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_ROB_FAIL, [RobberID, RobberName]) ->
	ContentStrPart1 = lists:flatten(io_lib:format("~w,", [RobberID])),
	ContentStr = ContentStrPart1 ++ RobberName,
	pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_PURPLE_ITEM, [PlayerID, ItemIdx, WorldIdx, SourceType]) ->
	ContentStr = lists:flatten(io_lib:format("~w,~w,~w,~w", [PlayerID, ItemIdx, WorldIdx, SourceType])),
	pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_ONLINE_ARENA, [ItemID]) ->
	ContentStr = integer_to_list(ItemID),
	pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_ONLINE_AWARD, []) ->
	<<>>;
assemble_content(_Player, ?ANNOUNCE_GUILD, [GuildName]) ->
	pt:write_string(GuildName);
assemble_content(_Player, ?ANNOUNCE_PET, []) ->
	<<>>;
assemble_content(_Player, ?ANNOUNCE_OFFLINE_ARENA, [Wins]) ->
	ContentStr = integer_to_list(Wins),
	pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_HORN, [Content]) ->
	pt:write_string(Content);
assemble_content(_Player, ?ANNOUNCE_OFFLINE_ARENA_FIRST_RANKS, [WinnerId,WinnerName,LoserID, LoserName, Rank]) ->
	ContentStr = lists:flatten(io_lib:format("~w,~w,~w,~w,~w", [WinnerId,WinnerName,LoserID, LoserName, Rank])),
	pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_BOXING_HOST_CHANGES, [BoxingType]) ->
	ContentStr = integer_to_list(BoxingType),
	pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_FLOWER, [ReceiverID, ReceiverName, Num]) ->
	ContentStr = integer_to_list(ReceiverID) ++ "," ++ ReceiverName ++ "," ++ integer_to_list(Num),
	pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_GUILD_DONATE, [GuildName, Donated]) ->
    ContentStr = GuildName ++ "," ++ integer_to_list(Donated),
    pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_FIRST_CHARGE_REWARD, [PlayerID, ItemIdx, WorldIdx]) ->
	ContentStr = lists:flatten(io_lib:format("~w,~w,~w", [PlayerID, ItemIdx, WorldIdx])),
    pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_WORLD_BOSS_RANK, [Rank, Silver, Reputation]) ->
    ContentStr = lists:flatten(io_lib:format("~w,~w,~w", [Rank, Silver, Reputation])),
    pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_WORLD_BOSS_KILLER, [Silver, Reputation]) ->
    ContentStr = lists:flatten(io_lib:format("~w,~w", [Silver, Reputation])),
    pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_NEW_CARD, [CardID, Type]) ->
    ContentStr = lists:flatten(io_lib:format("~w,~w", [CardID, Type])),
    pt:write_string(ContentStr);
assemble_content(_Player, ?ANNOUNCE_EXCHANGE_CARD, [LoserID, LoserName, CardID]) ->
	ContentStr1 = lists:flatten(io_lib:format("~w,", [LoserID])),
	ContentStr2 = lists:flatten(io_lib:format(",~w", [CardID])),
	ContentStr = ContentStr1 ++ LoserName ++ ContentStr2,
    pt:write_string(ContentStr).

get_broadcast_level(PlayerLevel) ->
	if 
		PlayerLevel >= 1 ->
			if 
				PlayerLevel =< 20 -> 1;
				PlayerLevel =< 50 -> 2;
				PlayerLevel =< 70 -> 3;
				PlayerLevel =< 85 -> 4;
				true -> 5
			end
	end.

parse_player_gen_event(#player_event{type=arena} = Event) ->
    {ok, Packet} = pt_31:write(31013, Event#player_event.content),
    Packet;
parse_player_gen_event(#player_event{type=garden} = Event) ->
    {ok, Packet} = pt_29:write(29015, Event#player_event.content),
    Packet;
parse_player_gen_event(#player_event{type=boxing} = Event) ->
    {ok, Packet} = pt_31:write(31014, Event#player_event.content),
    Packet;
parse_player_gen_event(#player_event{type=consume_bonus} = _Event) ->
    {ok, Packet} = pt_10:write(10035, {1, ""}),
    Packet.
data_translation(String,Para)->
    io_lib:format(String, Para).
