-module(pt_38).

-export([read/2, write/2]).


-include("common.hrl").

read(38000,_Bin) ->
	{ok,[]};

read(38001,_Bin) ->
	{ok,[]};

read(38003,_Bin) ->
	{ok,[]};

read(38004,<<Size:16, IDList/binary>>) ->
	WorldIDList = readIDList(Size, IDList),
	{ok,WorldIDList};

read(38005,<<BookID:32,Num:8>>) ->
	{ok,{BookID,Num}};

read(38006,<<Floor:8>>) ->
	{ok,Floor};

read(38007,_Bin) ->
	{ok,[]};

read(38008,_Bin) ->
	{ok,[]};


read(proto_num,finish)->
	{ok,finish}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write(38000,{TranslateLevel,AchieveLevel}) ->
	{ok,pt:pack(38000, <<TranslateLevel:16,AchieveLevel:16>>)};

write(38001,{MapID,PlayerX,PlayerY,MonsterList}) ->
	case length(MonsterList) of
		0 ->
			MonsterNum = 0,
			ListBin = <<>>;
		MonsterNum ->
			F = fun({MonsterID, X, Y}) ->
						<<MonsterID:32, X:16, Y:16>>
				end,
			ListBin = list_to_binary(lists:map(F, MonsterList))
		end,
	{ok,pt:pack(38001,<<MapID:16,PlayerX:16,PlayerY:16,MonsterNum:16,ListBin/binary>>)};

write(38002,TranslateLevel) ->
	{ok,pt:pack(38002,<<TranslateLevel:16>>)};

write(38003,Point) ->
	{ok,pt:pack(38003,<<Point:32>>)};

write(38006,{Floor,ID,RoleID,Name}) ->
	{ok, pt:pack(38006,<<Floor:8,ID:32,RoleID:32,(pt:write_string(Name))/binary>>)};

write(38007,{Result,Floor}) ->
	{ok,pt:pack(38007,<<Result:8,Floor:8>>)};

write(proto_num,finish)->
	{ok,finish}.

readIDList(0, _) ->
	[];
readIDList(Size, <<WorldID:32, IDList/binary>>) ->
	RestIDList = readIDList(Size-1, IDList),
	[WorldID|RestIDList].