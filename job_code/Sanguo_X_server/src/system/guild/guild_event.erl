
-module(guild_event).

-include("common.hrl").

%% guild_event 
%% (1) join guild Param = {guild_event, Type, Time, {AppID, AppName}}
%% (2) quit guild Param = {guild_event, Type, Time, {MemID, MemName}}
%% (3) donate     Param = {guild_event, Type, Time, {MemID, MemName, ExpAdd}}
%% (4) designate  Param = {guild_event, Type, Time, {MemID, MemName, Rank}}
%% (5) upgrade    Param = {guild_event, Type, Time, {Level}}
%% (6) transfer   Param = {guild_event, Type, Time, {NPID,  NName, OPID, OName}}
%% (7) fire       Param = {guild_event, Type, Time, {MemID, MemName}}
%% (7) *not_implement*

-export([create_event_tab/0, add_event/2, get_event/1, format_event/1]).

-spec create_event_tab() -> #guild_event_tab {}.
create_event_tab() ->
	#guild_event_tab {
		index = 0, 
		num   = 0,
		vec   = erlang:make_tuple(30, ?UNDEFINED)
	}.

-spec add_event(Tab, Event) -> NTab when 
	Event :: #guild_event{} | [#guild_event{}],
	Tab   :: #guild_event_tab{},
	NTab  :: #guild_event_tab{} .

add_event(Tab = #guild_event_tab {num = N, index = I, vec = V}, Event) when not is_list(Event) ->
	Index = I rem ?GUILD_EVENT_MAX + 1,
	Num   = if (N >= ?GUILD_EVENT_MAX) -> N; true -> N + 1 end,
	Vec   = setelement(Index, V, Event), 
	
	Tab#guild_event_tab {
		index = Index,			  
		num	  = Num,
		vec   = Vec
	};

add_event(Tab, [Event | Rest]) ->
	NTab = add_event(Tab, Event),
	add_event(NTab, Rest);

add_event(Tab, []) -> Tab.

-spec get_event(Tab) -> List when
	Tab  :: #guild_event_tab{},
	List :: [#guild_event {}]. %% event list

get_event(Tab) ->
	Vec = Tab#guild_event_tab.vec,
	Num = Tab#guild_event_tab.num,
	Idx = Tab#guild_event_tab.index,
	get_event(Vec, Num, Idx, []).

get_event(_Tuple, 0, _Index, List) -> 
	lists:reverse(List);

get_event(Tuple, Num, Index, List) ->
	NIndex = if (Index > 1) -> Index - 1; true -> ?GUILD_EVENT_MAX end,
	get_event(Tuple, Num - 1, NIndex, [element(Index, Tuple) | List]).


-spec format_event(E :: #guild_event{}) -> string().
format_event(#guild_event {type = Type, content = C}) ->
	Fmt = 
		case Type of
			1 -> element(2, C);
			2 -> element(2, C);
			3 -> io_lib:format("~s,~w", [element(2, C), element(3, C)]);
			4 -> io_lib:format("~s,~w", [element(2, C), element(3, C)]);
			5 -> io_lib:format("~w",    [element(1, C)]);
			6 -> io_lib:format("~s,~s", [element(2, C), element(4, C)]);
			7 -> io_lib:format("~s",    [element(2, C)]);
			8 -> ""
		end,
	lists:flatten(Fmt).




















