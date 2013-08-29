-module (pt_13).

-include("common.hrl").

-export([read/2, write/2]).

read(13000, _)->
	{ok, []};

read(13001, _) ->
	{ok, []};

read(13010, _) ->
	{ok, []};

read(13011, <<QihunId:8, FinishRightNow:8>>) ->
	{ok, {QihunId, FinishRightNow}};	

read(13012, _) ->
	{ok, []};

read(13020, _) ->
	{ok, []};	

read(13021, <<QihunId:8>>) ->
	{ok, QihunId};

read(13025, _) ->
	{ok, []}.

write(13000, State) ->
    {ok, pt:pack(13000, <<State:8>>)};

write(13010, {LastLevelingId, Level, LeftTime}) ->
    {ok, pt:pack(13010, <<LastLevelingId:8,
    					  Level:16,
    					  LeftTime:32>>)};


write(13020, PinjieRec) ->
	{PinjieLevel1, Perfect1} = PinjieRec#qihun_pinjie.gd_jing,
	{PinjieLevel2, Perfect2} = PinjieRec#qihun_pinjie.gd_li,
	{PinjieLevel3, Perfect3} = PinjieRec#qihun_pinjie.gd_yuan,
	{PinjieLevel4, Perfect4} = PinjieRec#qihun_pinjie.gd_dun,
	{PinjieLevel5, Perfect5} = PinjieRec#qihun_pinjie.gd_yu,
	{PinjieLevel6, Perfect6} = PinjieRec#qihun_pinjie.gd_zhun,
	{PinjieLevel7, Perfect7} = PinjieRec#qihun_pinjie.gd_shan,
	{PinjieLevel8, Perfect8} = PinjieRec#qihun_pinjie.gd_yun,
	{PinjieLevel9, Perfect9} = PinjieRec#qihun_pinjie.gd_su,
	{PinjieLevel10, Perfect10} = PinjieRec#qihun_pinjie.gd_bao,
	Data = <<(?MAX_QIHUN_ID):16,
			 1:8, PinjieLevel1:8, Perfect1:16,
			 2:8, PinjieLevel2:8, Perfect2:16,
			 3:8, PinjieLevel3:8, Perfect3:16,
			 4:8, PinjieLevel4:8, Perfect4:16,
			 5:8, PinjieLevel5:8, Perfect5:16,
			 6:8, PinjieLevel6:8, Perfect6:16,
			 7:8, PinjieLevel7:8, Perfect7:16,
			 8:8, PinjieLevel8:8, Perfect8:16,
			 9:8, PinjieLevel9:8, Perfect9:16,
			 10:8, PinjieLevel10:8, Perfect10:16>>,
    {ok, pt:pack(13020, Data)};

write(13025, Stage) ->
    {ok, pt:pack(13025, <<Stage:8>>)}.

