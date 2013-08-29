%%========================
%%arena协议===============
%%2012-08-15==============
-module(pt_31).
-export([read/2,write/2]).

-include("common.hrl").

%% 客户端--->服务端（C->S）

%%请求排位信息(31000) C->S
%%CMSG_ARENA_RANKING_INFO = 31000  
%%byte:   0
read(31000, _Bin)->
	{ok,[]};

%%请求玩家近五场战况(31001)C->S
%%CMSG_ARENA_RECENT_FIVE = 31001
%%byte:  0
read(31001, _Bin)->
	{ok, []};

%%发起挑战(31002)C->S
%%CMSG_ARENA_CHALLENG = 31002
%%int16:		名次
read(31002,  Bin)->
	<<Rank:16>> = Bin,
	{ok,[Rank]};

%%领取竞技场每天的奖励(31003)C-S
%%CMSG_ARENA_DAILY_AWARD  = 31003
%% byte:    0     0：查看状态，1：领取每天奖励
read(31003,  Bin)->
	<<Typestate:8>> = Bin,
	{ok, [Typestate]};

%%翻牌奖励(31004)C->S
%%CMSG_ARENA_card_award = 31004
%%byte :0
read(31004, _Bin)->
	{ok,[]};

%%英雄榜（31005）C->S
%CMSG_HEROES
%%byte: 8
read(31005,  Bin)->
	<<Page:8>> = Bin,
	?INFO(arena,"Page:~w",[Page]),
	{ok, [Page]};

%%清除cd
read(31006, Bin)->
	<<Byte:8>> = Bin,
	{ok, [Byte]};

%%购买挑战次数
read(31007, Bin)->
	<<Flag:8>> = Bin,
	{ok, [Flag]};

read(31008, _Bin)->
	{ok, []}.

%% 返回对手排名信息(31000) S->C
%% SMSG_ARENA_RANKING_INFO    =  31000,        // 返回排名信息
%% int16:    玩家数                (共6位，包含自己)
%% 		int16     名次
%% 		string    玩家名称
%% 		int16     玩家等级
%% 		Int32     战斗力
%% 		Int32     玩家id
write(31000, Info_list)->
	%%根据id获取等级、战斗力、昵称
	?INFO(arena,"ranking info_list ~w",[Info_list]),
	Length = erlang:length(Info_list),
	?INFO(arena,"info_list length:~w",[Length]),
	F = fun(Info)->
		?INFO(arena,"Info:~w",[Info]),
		Rec = mod_account:get_account_info_rec(Info#arena_rec.id),
		NickName = Rec#account.gd_RoleName,
		BinName = pt:write_string(NickName),
		?INFO(arena,"NickName:~w",[NickName]),
		Level = mod_role:get_main_level(Info#arena_rec.id),
		RoleRec = role_base:get_main_role_rec(Info#arena_rec.id),
		Zhandouli = mod_role:calc_combat_point(RoleRec),
		[<<(Info#arena_rec.rank):16, BinName/binary,Level:16,Zhandouli:32,(Rec#account.gd_RoleID):32>>]
		end,
	Bin = list_to_binary([F(Info) || Info<-Info_list]),
	?INFO(arena,"ranking_info:~w",[Bin]),
	{ok, pt:pack(31000,<<Length:16,Bin/binary>>)};

%% 返回玩家近五场挑战信息(31001)  S->C
%% SMSG_ARENA_RECENT _FIVE            =  31001,        // 返回近五场挑战情况（每五场清空一次）
%% int16        连胜次数
%% int16        排名
%% int16:        次数            (共5次，按时间先后顺序)
%% byte           胜负情况(列表[_,_,_,_,_])                   （0未开启1胜2负）
%% Int32:         银币奖励
%% Int32:         军功
%% byte:8         可以挑战次数
%% int32:         cd时间



write(31001, {Sustain_win,Rank,Recent_record,Silver,Jungong,Challengetimes,CdTime})->
	?INFO(arena,"Sustain_win:~w,Rank:~w,Recent_record:~w,Silver:~w,Jungong:~w,Challengetimes:~w,CdTime:~w",
		[Sustain_win,Rank,Recent_record,Silver,Jungong,Challengetimes, CdTime]),
	
		{A,B,C,D,E}= Recent_record,
		Bin = <<A:8,B:8,C:8,D:8,E:8>>,
%% 	F = fun(R)-> <<R:8>> end,
%% 	if
%% 		length(Recent_record) < 5 ->
%% 			Recent_record1 = lists:duplicate(5-length(Recent_record), 0) ++Recent_record;
%% 		true->
%% 			Recent_record1 = lists:sublist(Recent_record,5)
%% 	end,
%% 	%%顺序定义跟客户端不一样，reverse一下
%% 	Recent_record2 = lists:reverse(Recent_record1),
%% 	Bin = list_to_binary([F(R)|| R<-Recent_record2]),
	?INFO(arena, "send data=~w", [[Sustain_win,Rank,Recent_record]]),
	{ok, pt:pack(31001,<<Sustain_win:16,Rank:16,5:16,Bin/binary,Silver:32,Jungong:32,Challengetimes:8,CdTime:32>>)};

%%返回挑战(31002)S->C
%%SMSG_ARENA_CHALLENG =31002
%%byte: Result (0：挑战成功；1：挑战失败)
write(31002, {Result})->
	{ok, pt:pack(31002, <<Result:8>>)};

%%领取竞技场每天的奖励S->C
%%SMSG_ARENA_DAILY_AWARD = 31003
%%int32   银币数
%%int32   声望
%%byte:8  奖励状态
%%byte:8  宝箱类型
%% 	int16 长度
%% 		int32    首银币
%% 		int32    首军功
%% 		int32  	 末银币
%%      int32    末军功
write(31003,{MySilver,MyJunGong, AwardState, Type, AwardList})->
	Length = length(AwardList),
	?INFO(arena,"MySilver:~w,MyJunGong:~w,AwardState:~w, Type:~w",[MySilver,MyJunGong,AwardState, Type]),
	F = fun(Info)->
		{FSilver, FJunGong, MSilver, MJunGong} = Info,
		[<<FSilver:32, FJunGong:32, MSilver:32, MJunGong:32>>]
		end,
	Bin = list_to_binary([F(Info) || Info <- AwardList]),
	{ok, pt:pack(31003, <<MySilver:32,MyJunGong:32,AwardState:8,Type:8,Length:16,Bin/binary>>)};

%%翻牌奖励(31004)S->C
%%SMSG_ARENA_CARD_AWARD = 31004
 
%%int16:   长度
%%		byte: 类型          0金币， 1银币，2历练，3声望
%%		Uint32：		奖励数量
%%Uint8:		计算翻排奖励的连胜次数
write(31004, {BackList, _Win_num})->
	Length = length(BackList),
	F = fun(Info)->
		{Type, Account} = Info,
		[<<Type:8,Account:32>>]
		end,
	Bin = list_to_binary([F(Info) || Info<-BackList]),
	?INFO(arena, "Length:~w,Bin:~w",[Length,Bin]),
	{ok, pt:pack(31004,<<Length:16,Bin/binary>>)};

%%英雄榜（31005） S->C
%%SMSG_HEROES   = 31005
%% byte: 8  总页数
%% byte: 8  当前页码
%% int16:  长度
%%       int16:   排名
%%       string:  昵称
%%       Int32:   战斗力
%%       int16:   等级
write(31005, {heroes, {Page_count, Page, Back_list}})->
	?INFO(arena,"Back_list ~w",[Back_list]),
	Length = length(Back_list),
	?INFO(arena,"Back_list 's length:~w",[Length]),
	F = fun(Info)->
		?INFO(arena,"Info:~w",[Info]),
		Rec = mod_account:get_account_info_rec(Info#arena_rec.id),
		NickName = Rec#account.gd_RoleName,
		BinName = pt:write_string(NickName),
		?INFO(arena,"NickName:~w",[NickName]),
		RoleRec = role_base:get_main_role_rec(Info#arena_rec.id),
		Zhandouli = mod_role:calc_combat_point(RoleRec),
		Level =  mod_role:get_main_level(Info#arena_rec.id),
		[<<(Info#arena_rec.rank):16, BinName/binary,Zhandouli:32,Level:16>>]
		end,
	Bin = list_to_binary([F(Info) || Info<-Back_list]),
	?INFO(arena,"heroes_info:~w",[Bin]),
	{ok, pt:pack(31005,<<Page_count:8,Page:8,Length:16,Bin/binary>>)};

write(31006, {CdTime, GoldNeed})->
	?INFO(arena,"pt_31 cd time:~w,GoldNeed:~w",[CdTime,GoldNeed]),
	{ok, pt:pack(31006,<<CdTime:32,GoldNeed:16>>)};

%% 增加挑战次数(31007) S->C
%% SMSG_ARENA_ADD_CHALLENGE_TIMES  = 31007
%% int16:  需要的金币
write(31007,{add_challenge_times, Goldcount})->
	{ok, pt:pack(31007,<<Goldcount:16>>)};


%% 返回请求最近战况
%% SMSG_ARENA_REQUEST_WINRECORD     31008
%% int16:    长度
%%      string:  challengerid 挑战者name
%%      string：  被挑战者name
%%      int32:   挑战时间
%%      byte:   8   战况 0 输，1 为赢
%%      int32:  ranking 0排名不变，n排名变为第n名
write(31008, Queue)->
	?INFO(arena,"Queue:~w",[Queue]),
	List = queue:to_list(Queue),
	?INFO(arena,"queue to list, list:~w",[List]),
	Length = length(List),
   F = fun(Info)->
			?INFO(arena, "Info:~w",[Info]),
			ChallengerBinName = pt:write_string(Info#recent_rec.challenger_name),
			ChallengedBinName = pt:write_string(Info#recent_rec.challenged_name),
			?INFO(arena,"ChallengerName:~w,ChallengedName:~w",[Info#recent_rec.challenger_name,Info#recent_rec.challenged_name]),
			Time = util:unixtime()-Info#recent_rec.challenge_time,
			?INFO(arena,"challenge time:~w",[Time]),
			[<<ChallengerBinName/binary,ChallengedBinName/binary,
			Time:32,(Info#recent_rec.win_rec):8,(Info#recent_rec.ranking):32>>]
		end,
	Bin = list_to_binary([F(Info) || Info <- List]),
	{ok, pt:pack(31008, <<Length:16,Bin/binary>>)}.

