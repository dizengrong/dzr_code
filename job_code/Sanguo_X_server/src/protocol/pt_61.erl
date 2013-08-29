-module(pt_61).
%%mail:laojiajie@4399.net

-include("common.hrl").

-export([read/2, write/2]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%										READ 												   		%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

read(61000,<<>>) ->
	{ok,[]};

read(61001,<<Precent:32, IsUseDrug:8, IsUseBlood:8, IsAutoStop:8, IsAutoBuy:8>>) ->
	{ok,{Precent, IsUseDrug, IsUseBlood, IsAutoStop, IsAutoBuy}};

read(61002,<<>>) ->
	{ok,[]};

read(61003,<<>>) ->
	{ok,[]};

read(61004,<<AddTimes:32>>) ->
	{ok,AddTimes};

read(Cmd, _R) ->
	?ERR(guaji, "client protocal not matched:~w", [Cmd]),
    {error, protocal_no_match}.




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%										WRITE 														%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


write(61000,GuajiRec) ->
	Times = GuajiRec#guaji.gd_Times,
	Precent = GuajiRec#guaji.gd_Percent,
	IsUseDrug = GuajiRec#guaji.gd_IsUseDrug,
	IsUseBlood = GuajiRec#guaji.gd_IsUseBlood,
	IsAutoStop = GuajiRec#guaji.gd_IsAutoStop,
	IsAutoBuy = GuajiRec#guaji.gd_IsAutoBuy,
	?INFO(guaji, "send_data=~w", [[61000, Times, Precent, IsUseDrug, IsUseBlood, IsAutoStop, IsAutoBuy]]),
	{ok, pt:pack(61000, <<Times:32, Precent:32, IsUseDrug:8, IsUseBlood:8, IsAutoStop:8, IsAutoBuy:8>>)};


write(61002,{Times,Type}) ->
	?INFO(guaji,"send_data=~w",[[61002,Times,Type]]),
	{ok, pt:pack(61002, <<Times:32,Type:8>>)};

write(61003,Type) ->
	?INFO(guaji,"send_data=~w",[[61003,Type]]),
	{ok, pt:pack(61003, <<Type:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.