%% Author: Administrator
%% Created: 2011-10-10
%% Description: TODO: Add description to pt_24
-module(pt_24).

%%
%% Include files
%%
-include("common.hrl").

%%
%% Exported Functions
%%
-export([read/2, write/2]).

%%
%% API Functions
%%
%% 圣痕初始化数据请求
read(24000, <<Flag:8>>) ->
	?INFO(holy,"read: ~w",[[24000, Flag]]),
	{ok, Flag};

%% 圣痕升级请求
read(24001, <<Type:8>>) ->
	?INFO(holy,"read: ~w",[[24001, Type]]),
	{ok, Type};

%% 圣痕升级时间请求
read(24002, <<Type:8>>) ->
	?INFO(holy,"read: ~w",[[24002, Type]]),
	{ok, Type};

read(24003, <<Type:8>>) ->
	?INFO(holy,"read: ~w",[[24003, Type]]),
	{ok, Type};

read(_Cmd, _BinData) ->
	{error, not_match}.

write(24000, HolyList) ->
	if
		is_list(HolyList) =:= false ->
			ListNum = 0,
			ListBin = <<>>;
		HolyList =:= [] ->
			ListNum = 0,
			ListBin = <<>>;
		true ->
			ListNum = length(HolyList),
			F = fun({Type, Level}) ->
					<<Type:8, Level:8>>
				end,
			ListBin = list_to_binary(lists:map(F, HolyList))
	end,
	?INFO(holy, "SendData=[~w   ~w]", [ListNum, ListBin]),
	{ok, pt:pack(24000, <<ListNum:16, ListBin/binary>>)};

write(24001, HolyList) ->
	if
		is_list(HolyList) =:= false ->
			ListNum = 0,
			ListBin = <<>>;
		HolyList =:= [] ->
			ListNum = 0,
			ListBin = <<>>;
		true ->
			ListNum = length(HolyList),
			F = fun({Type, Level}) ->
					<<Type:8, Level:8>>
				end,
			ListBin = list_to_binary(lists:map(F, HolyList))
	end,
	?INFO(holy, "SendData=[~w   ~w]", [ListNum, ListBin]),
	{ok, pt:pack(24001, <<ListNum:16, ListBin/binary>>)};
%% write(24001, {Type, Level}) ->
%% 	?INFO(holy, "HolyInfo=[~w]", [{Type, Level}]),
%% 	{ok, pt:pack(24001, <<Type:8, Level:8>>)};

write(24002, {Type, UpgradeTime, Silver, Exp}) ->
	{ok, pt:pack(24002, <<Type:8, UpgradeTime:32, Silver:32, Exp:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
%%
%% Local Functions
%%

