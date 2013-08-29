-module(pt_62).

-include("common.hrl").

-export([read/2,write/2,commer/3]).

%%request enther boss scene -----register to battle
read(62000, _Bin)->
	{ok, {}};

%%request boss basic information
read(62001, _Bin)->
	{ok, {}};

%% 62002:世界BOSS伤害排行信息
read(62002, _Bin)->
	{ok, {}};

%%boss appear
read(62003, _Bin)->
	{ok, {}};

%%update boss hp
read(62004, _Bin)->
	{ok, {}};

%%boss result
read(62005, _Bin)->
	{ok, {}};


%%fight boss
read(62006, _Bin)->
	{ok, {}};


%% 62008:世界BOSS鼓舞¶
%% 鼓舞请求(C->S)
%% int8:   鼓舞类型（1-元宝 2-银币）
read(62008, Bin)->
	<<Type:8>> = Bin,
	{ok, [Type]};

%%gold 鼓舞

%%gold clean battle cd
read(62007, _Bin)->
	{ok, {}};


read(62009, _Bin)->
	{ok, {}};

%%请求离开世界boss场景
read(62010, _Bin)->
	{ok, {}}.



%% 请求进入世界BOSS场景（C->S)   
%% S->C  返回地图跳转包（11004），切换场景
%% write(62000, [Left_Time])->
%% 	{ok, pt:pack(62000, <<Left_Time:32>>)};

%% 返回世界BOSS基本信息（S->C)
%% string:  上次BOSS战排名第一玩家名（BOSS全名：魔化的XXX，这里返回XXX，即上次BOSS战排名第一玩家名）
%% int16：   BOSS等级
%% int：     佣兵ID（这里是玩家的主角ID）
%% uint：    本次BOSS的最大血量
%% uint:     BOSS当前血量
%%int8:   已鼓舞次数（0-5   0-未鼓舞过）

%% 注意：如果进入世界BOSS场景，BOSS战已开始，只有在收到S->C发出62001后，才能发伤害信息
write(62001, {Id, BossRecord})->
	CountInspire = mod_counter:get_counter(Id, ?INSPIRE_SUCCES),
%% 	GoldInspire = mod_counter:get_counter(Id, ?GOLD_INSPIRE_SUCCES),
%% 	CountInspire = SilverInspire + GoldInspire,
	?INFO(boss,"CountInspire:~w",[CountInspire]),
	case ets:lookup(?ETS_BOSS_HP, boss_hp) of
		[] ->
			BossHpRec = #boss_hp{hp_value = BossRecord#boss_rec.boss_hp},
			ets:insert(?ETS_BOSS_HP, BossHpRec),
			BossHpRec;
		[BossHpRec] ->
			BossHpRec
	end,
	?INFO(boss, "boss_hp_rec:~w",[BossHpRec]),
	BossBinName = pt:write_string(BossRecord#boss_rec.boss_nickname),
	Bin = <<BossBinName/binary,(BossRecord#boss_rec.boss_level):16,
		(BossRecord#boss_rec.boss_id):32,(BossRecord#boss_rec.boss_hp):32,(BossHpRec#boss_hp.hp_value):32>>,
	?INFO(boss,"Max hp:~w,cur hp:~w",[BossRecord#boss_rec.boss_hp,BossHpRec#boss_hp.hp_value]),
	{ok, pt:pack(62001, <<Bin/binary,CountInspire:8>>)};

%% 返回世界BOSS伤害排行信息（S->C)
%% Array:   上榜人数（最多10个）
%%   int8：  排名（1-10）
%%   string：   玩家名字
%%   uint：     造成的总伤害
write(62002, DamgageList)->
	?INFO(boss,"DamageList:~w",[DamgageList]),
	Length = length(DamgageList),
	LengthList = lists:seq(1, Length),
	Bin = commer(DamgageList,LengthList,[]),
	ResultBin = list_to_binary(Bin),
	?INFO(boss,"Bin:~w",[Bin]),
%% 	F = fun(Info,N)->
%% 		?INFO(boss,"Info:~w,N:~w",[Info,N]),
%% 		NickName = mod_account:get_player_name(Info#boss_damage.id),
%% 		BinName = pt:write_string(NickName),
%% 		[<<N:8,BinName/binary,(Info#boss_damage.damage_value):32>>]
%% 	end,
%% 	Bin = list_to_binary([F(Info,N) || Info <-DamgageList, N <- lists:seq(1, Length)]),
	{ok, pt:pack(62002, <<Length:16,ResultBin/binary>>)};


%% 世界BOSS出现(S->C)
%% int：     佣兵资源ID（玩家的佣兵ID查找出的放大的模型ID）
%% int:            怪物进度id
%% int16:          初始点X
%% int16：           初始点Y
write(62003, {BId, BossId, X, Y})->
	?INFO(boss,"BId, BossId, X, Y:~w",[[BId, BossId, X, Y]]),
	Bin = <<BId:32,BossId:32,X:16,Y:16>>,
	{ok, pt:pack(62003, Bin)};

write(62004, BossHp)->
	{ok, pt:pack(62004, <<BossHp:32>>)};

%% 62005:世界BOSS结果¶
%% 世界BOSS结果(S->C)
%% int:            怪物进度id
%% string： 击杀BOSS玩家名字(未击杀传"")
%% uint：     奖励银币
%% int:      奖励军功
%% Array:   上榜人数（前3名）
%%   int8：  排名（1-3）
%%   string：   玩家名字
%%   uint：     造成的总伤害
write(62005, Result)->
	List = ets:tab2list(?ETS_BOSS_DAMAGE),
	HerosList0 = lists:sort(fun(Rec1,Rec2) -> Rec1#boss_damage.damage_value >Rec2#boss_damage.damage_value end, List),
	case length(HerosList0) =< ?RANKING_FIRST_THREE of
		true ->
			HerosList = HerosList0;
		false ->
			HerosList = lists:sublist(HerosList0, 1, ?RANKING_FIRST_THREE)
	end,
	Length = length(HerosList),
	LengthList = lists:seq(1, Length),
%% 	Fun = fun(Rec,N) ->
%% 		NickName = mod_account:get_player_name(Rec#boss_damage.id),
%% 		BinName = pt:write_string(NickName),
%% 		DamageValue = Rec#boss_damage.damage_value,
%% 		[<<N:8,BinName/binary,DamageValue:32>>]
%% 		end,
%% 	Bin = erlang:list_to_binary([Fun(Rec,N) || Rec <- HerosList, N <- lists:seq(1, Length)]),

	Bin = commer(HerosList,LengthList,[]),
	ResultBin = list_to_binary(Bin),
	BossId = data_boss:get_magic_boss_id(),

	{StrName, Silver, Popularity} = Result,
	BinPlayerName = pt:write_string(StrName),
	
	{ok, pt:pack(62005, <<BossId:32,BinPlayerName/binary,Silver:32,Popularity:32,Length:16,ResultBin/binary>>)};

write(62007, CdTime)->
	?INFO(boss,"boss cd time:~w",[CdTime]),
	{ok, pt:pack(62007, <<CdTime:32>>)};

%% 返回CD时间(S->C)
%% int8:   已鼓舞次数（0-5   第一次鼓舞失败回0）
write(62008, CountInspire)->
	?INFO(boss,"CountInspire:~w",[CountInspire]),
	{ok, pt:pack(62008, <<CountInspire:8>>)};

%% 我对世界BOSS的伤害(S->C)
%% uint:   我对世界BOSS的伤害
write(62009, Damage)->
	?INFO(boss, "player hurt boss value, damage value:~w",[Damage]),
	{ok, pt:pack(62009, <<Damage:32>>)};

write(62100, Time) ->
	{ok, pt:pack(62100, <<Time:32>>)}.

commer([], [], Bin)->
	Bin;
commer([H1 | T1],[H2 | T2], Bin)->
	?INFO(boss,"boss damage:player and his rank Info:~w,N:~w",[H1,H2]),
	NickName = mod_account:get_player_name(H1#boss_damage.id),
	BinName = pt:write_string(NickName),
	Bin0 = [<<H2:8,BinName/binary,(H1#boss_damage.damage_value):32>> | Bin],
	commer(T1, T2, Bin0).


