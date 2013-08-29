-module(pt_29).

-include("common.hrl").

-export([read/2, write/2]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%												read													 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

read(29000, _BinData) ->
	{ok, []};

read(29001,<<Type:8>>) ->
	{ok,Type};

read(29003,_BinData) ->
	{ok,[]};

read(29004,<<Type:8,SubType:8>>) ->
	{ok,{Type,SubType}};

read(Cmd, _R) ->
	?ERR(scene, "client protocal not matched:~w", [Cmd]),
    {error, protocal_no_match}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%												write													  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write(29000, {SumPoint,AchieveNum,TypePoint}) ->
		Point1 = TypePoint#type_point.point1,
		Point2 = TypePoint#type_point.point2,
		Point3 = TypePoint#type_point.point3,
		Point4 = TypePoint#type_point.point4,
		Point5 = TypePoint#type_point.point5,
		Point6 = TypePoint#type_point.point6,
		Point7 = TypePoint#type_point.point7,
		Point8 = TypePoint#type_point.point8,
    {ok, pt:pack(29000, <<SumPoint:16,AchieveNum:16,Point1:16,Point2:16,Point3:16,
    						Point4:16,Point5:16,Point6:16,Point7:16,Point8:16
    						>>)};

write(29001,{Type,InfoList}) ->
	case erlang:length(InfoList) of
		ListNum when ListNum =< 0 ->
			ListBin = <<>>;
		ListNum ->
			F = fun({SubType,Progress}) -> 
				<<SubType:8,Progress:32>>
			end,
			ListBin = list_to_binary(lists:map(F, InfoList))
	end,
	{ok,pt:pack(29001,<<Type:8,ListNum:16,ListBin/binary>>)};

write(29002,{Type,SubType}) ->
	{ok,pt:pack(29002,<<Type:8,SubType:8>>)};

write(29003,AwardList) ->
	case erlang:length(AwardList) of
		ListNum when ListNum =< 0 ->
			ListBin = <<>>;
		ListNum ->
			F = fun({Type,SubType}) -> 
				<<Type:8,SubType:8>>
			end,
			ListBin = list_to_binary(lists:map(F, AwardList))
	end,
	{ok,pt:pack(29003,<<ListNum:16,ListBin/binary>>)};

write(29004,{Type,SubType}) ->
	{ok, pt:pack(29004,<<Type:8,SubType:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.