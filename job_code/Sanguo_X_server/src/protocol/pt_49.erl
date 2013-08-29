-module(pt_49).

-export([read/2, write/2]).


-include("common.hrl").

read(49001,<<ID:32>>) ->
	{ok,ID};

read(49002,_Bin) ->
	{ok,[]};

read(proto_num,finish)->
	{ok,finish}.

write(49001,Type) ->
	{ok,pt:pack(49001,<<Type:8>>)};

write(49003,{ExpValue}) ->
	{ok,pt:pack(49003,<<ExpValue:32>>)};

write(proto_num,finish)->
	{ok,finish}.