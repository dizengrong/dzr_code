%% Author: Administrator
%% Created: 2012-1-21
%% Description: TODO: Add description to pt_33
-module(pt_33).

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

%% 我的排名
read(33000, Bin) ->
	<<AccountID:32>> = Bin,
	{ok, {AccountID}};

%% 个人排行
read(33001, Bin) ->
	<<Range:16, Page:16>> = Bin,
	{ok, {Range, Page}};

%% 爬塔排行
read(33002, Bin) ->
	<<Page:16>> = Bin,
	{ok,  {Page}};

%% 副本
read(33003, Bin) ->
	<<Range:16, Page:16>> = Bin,
	?INFO(rank,"Range is ~w, Page is ~w",[Range, Page]),
	{ok, {Range, Page}};


read(33004,<<ID:32>>) ->
{ok,ID};

read(33005,<<ID:32,RoleId:16>>) ->
{ok,{ID,RoleId}};

%% 最强装备
read(33006, Bin) ->
	<<Range:8, Page:16>> = Bin,
	{ok, {Range, Page}};

%% 人气
read(33007, Bin) ->
	<<Range:8, Page:16>> = Bin,
	{ok, {Range, Page}};

%% 战斗力
read(33008, Bin) ->
	<<Range:8, Career:8, Page:16>> = Bin,
	{ok, {Career, Range, Page}};

%% 公会
read(33009, Bin) ->
	<<Page:16>> = Bin,
	{ok, {Page}};

%% 下水道层数
read(33010, Bin) ->
	<<Range:8, Page:16>> = Bin,
	{ok, {Range, Page}};

%% 魂石
read(33011, Bin) ->
	<<Range:8, Page:16>> = Bin,
	{ok, {Range, Page}};

%% 坐骑
read(33012, Bin) ->
    <<Range:8, Page:16>> = Bin,
    {ok, {Range, Page}};

%% 送花
read(33013, Bin) ->
    <<Range:8, Page:16>> = Bin,
    {ok, {Range, Page}};

%% 收花
read(33014, Bin) ->
    <<Range:8, Page:16>> = Bin,
    {ok, {Range, Page}}.

%% 个人排行
write(33001, {Range, TotalPages, CurPage, EntryNum, List}) ->
	Header = <<Range:16, TotalPages:16, CurPage:16, EntryNum:16>>,
	ListGen = fun(Entry, {CurPos, AccBin}) ->
					  ?INFO(liuzhe1,"entry is ~w",[Entry]),
					  {AccID, Name, Level, RoleID, GuildName, CombatPoint} = Entry,
					  PtName = pt:write_string(Name),
					  PtGuildName = pt:write_string(GuildName),
					  NewBin = <<AccBin/binary, CurPos:16, AccID:32, RoleID:16, PtName/binary, Level:16,
								CombatPoint:32, PtGuildName/binary>>,
					  {CurPos+1, NewBin}
			  end,
	StartPos = (CurPage - 1) * ?RANKINGS_ENTRIES_PER_PAGE + 1,
	{_, Bin} = lists:foldl(ListGen, {StartPos, Header}, List),
	pt:pack(33001, Bin);

%% 返回我的排名
write(33000, RankList) ->
	?INFO(rank,"RankList is ~w",[RankList]),
	[CombatTotal,CombatRole] = RankList,
	Bin = <<CombatTotal:32,CombatRole:32>>,
	pt:pack(33000, Bin);

%% 返回公会排名
write(33009, {TotalPages, CurPage, EntryNum, List}) ->
	Header = <<TotalPages:16, CurPage:16, EntryNum:16>>,
	ListGen = fun(Entry, {CurPos, AccBin}) ->
					  {GuildID, GuildName, GuildLevel, HisMerit, MemberNum, MaxMemberCount} = Entry,
					  PtGuildName = pt:write_string(GuildName),
					  NewBin = <<AccBin/binary, CurPos:16, GuildID:16,
								 PtGuildName/binary, GuildLevel:16, HisMerit:32, MemberNum:16, MaxMemberCount:16>>,
					  {CurPos+1, NewBin}
			  end,
	StartPos = (CurPage - 1) * ?RANKINGS_ENTRIES_PER_PAGE + 1,
	{_, Bin} = lists:foldl(ListGen, {StartPos, Header}, List),
	pt:pack(33009, Bin);

%% 爬塔
write(33002, {TotalPages, CurPage, EntryNum, List}) ->
	 ?INFO(liuzhe1,"entry is ~w",[List]),
	Header = <<TotalPages:16, CurPage:16, EntryNum:16>>,
	ListGen = fun(Entry, {CurPos, AccBin}) ->
					  ?INFO(liuzhe1,"entry is ~w",[Entry]),
					  {AccID, Name, Level, Combat, Tower, _updateTime} = Entry,
					   MainRoleId = mod_role:get_main_role_employed_id(AccID),
					  PtName = pt:write_string(Name),
					  NewBin = <<AccBin/binary, CurPos:16, AccID:32, MainRoleId:16, PtName/binary, Level:16,
								Tower:32, Combat:32>>,
					  {CurPos+1, NewBin}
			  end,
	StartPos = (CurPage - 1) * ?RANKINGS_ENTRIES_PER_PAGE + 1,
	{_, Bin} = lists:foldl(ListGen, {StartPos, Header}, List),
	pt:pack(33002, Bin);

%% 副本排行
write(33003, {Range, TotalPages, CurPage, EntryNum, List}) ->
	Header = <<Range:16, TotalPages:16, CurPage:16, EntryNum:16>>,
	ListGen = fun(Entry, {CurPos, AccBin}) ->
					  ?INFO(liuzhe1,"entry is ~w",[Entry]),
					  {_, PlayerId, Score, _} = Entry,
					  Name = mod_account:get_player_name(PlayerId),
					  PtName = pt:write_string(Name),
					  Level = mod_role:get_main_level(PlayerId),
					  Combat = mod_rank:getAllRolesCombatPointFromMemory(PlayerId),
					  MainRoleId = mod_role:get_main_role_employed_id(PlayerId),
					  NewBin = <<AccBin/binary, CurPos:16, PlayerId:32, MainRoleId:16, PtName/binary, Level:16,
								Score:32, Combat:32>>,
					  {CurPos+1, NewBin}
			  end,
	StartPos = (CurPage - 1) * ?RANKINGS_ENTRIES_PER_PAGE + 1,
	{_, Bin} = lists:foldl(ListGen, {StartPos, Header}, List),
	pt:pack(33003, Bin);


write(33006, {Range, TotalPages, CurPage, EntryNum, List}) ->
	Header = <<Range:8, TotalPages:16, CurPage:16, EntryNum:16>>,
	ListGen = fun(Entry, {CurPos, AccBin}) ->
					  {AccID, HolyLevel, RoleID, Name, GuildName, WorldID, ItemID, _Level, _IntensifyLevel} = Entry,
					  PtName = pt:write_string(Name),
					  PtGuildName = pt:write_string(GuildName),
					  NewBin = <<AccBin/binary, CurPos:16, AccID:32, PtName/binary, HolyLevel:8, 
								 RoleID:8, PtGuildName/binary, WorldID:32, ItemID:16>>,
					  {CurPos+1, NewBin}
			  end,
	StartPos = (CurPage - 1) * ?RANKINGS_ENTRIES_PER_PAGE + 1,
	{_, Bin} = lists:foldl(ListGen, {StartPos, Header}, List),
	pt:pack(33006, Bin);

%% 返回战斗力排行，多了一个职业ID所以要单独来……
write(33008, {Career, Range, TotalPages, CurPage, EntryNum, List}) ->
	Header = <<Range:8, Career:8, TotalPages:16, CurPage:16, EntryNum:16>>,
	ListGen = fun(Entry, {CurPos, AccBin}) ->
					  {AccID, Name, Level, RoleID, GuildName, CombatPoint} = Entry,
					  PtName = pt:write_string(Name),
					  PtGuildName = pt:write_string(GuildName),
					  NewBin = <<AccBin/binary, CurPos:16, AccID:32, PtName/binary, Level:8,
								 RoleID:8, PtGuildName/binary, CombatPoint:32>>,
					  {CurPos+1, NewBin}
			  end,
	StartPos = (CurPage - 1) * ?RANKINGS_ENTRIES_PER_PAGE + 1,
	{_, Bin} = lists:foldl(ListGen, {StartPos, Header}, List),
	pt:pack(33008, Bin);

write(33011, {Range, TotalPages, CurPage, EntryNum, List}) ->
	Header = <<Range:8, TotalPages:16, CurPage:16, EntryNum:16>>,
	ListGen = fun(Entry, {CurPos, AccBin}) ->
					  {AccID, HolyLevel, RoleID, Name, GuildName, _StoneID, StoneLevel, StoneNum} = Entry,
					  PtName = pt:write_string(Name),
					  PtGuildName = pt:write_string(GuildName),
					  NewBin = <<AccBin/binary, CurPos:16, AccID:32, PtName/binary, HolyLevel:8, 
								 RoleID:8, PtGuildName/binary, StoneLevel:8, StoneNum:16>>,
					  {CurPos+1, NewBin}
			  end,
	StartPos = (CurPage - 1) * ?RANKINGS_ENTRIES_PER_PAGE + 1,
	{_, Bin} = lists:foldl(ListGen, {StartPos, Header}, List),
	pt:pack(33011, Bin);

%% 返回各种玩家排名……
write({default, Protocol}, {Range, TotalPages, CurPage, EntryNum, List}) ->
	Header = <<Range:8, TotalPages:16, CurPage:16, EntryNum:16>>,
	ListGen = fun(Entry, {CurPos, AccBin}) ->
					  {AccID, Name, Level, RoleID, GuildName, RankingValue} = Entry,
					  PtName = pt:write_string(Name),
					  PtGuildName = pt:write_string(GuildName),
					  NewBin = <<AccBin/binary, CurPos:16, AccID:32, PtName/binary, Level:8,
								 RoleID:8, PtGuildName/binary, RankingValue:32>>,
					  {CurPos+1, NewBin}
			  end,
	StartPos = (CurPage - 1) * ?RANKINGS_ENTRIES_PER_PAGE + 1,
	{_, Bin} = lists:foldl(ListGen, {StartPos, Header}, List),
	pt:pack(Protocol, Bin);
% uint:           玩家账号id
% string：          玩家名
% string：          公会名
% int8：             威望ID
% int8：             官职ID
% Array：           佣兵个数
%  int16:          佣兵ID 
write(33004,PlayerId) ->
	Weiwang = mod_role:get_weiwang(PlayerId),
	GuanzhiID = mod_official:get_official_position(PlayerId),
	Name = mod_account:get_player_name(PlayerId),
	RoleList = role_base:get_employed_id_list(PlayerId),
	case erlang:length(RoleList) of
		RoleNum when RoleNum =< 0 ->
			RoleBin = <<>>;
		RoleNum ->
			F = fun(RoleId) ->
				<<RoleId:16>>
			end,
			RoleBin = list_to_binary(lists:map(F, RoleList))
	end,

	{ok,pt:pack(33004,<<
		PlayerId:32,
		(pt:write_string(Name))/binary,
		(pt:write_string(Name))/binary,
		Weiwang:8,
		GuanzhiID:8,
		RoleNum:16,
		RoleBin/binary
		>>)};

write(33005,{RoleRec,ItemList}) ->
	?INFO(role,"33005 send ItemList =~w",[ItemList]),
	FightAbility = mod_role:calc_combat_point(RoleRec),
	{PlayerId,RoleId} = RoleRec#role.key,
	_IsInGuild = guild:is_in_guild(PlayerId),
	SkillList = 
		case RoleRec#role.gd_roleRank == 1 of
			true ->
				lists:filter(fun({_,SkillModeId,_}) -> 
					SkillInfo = data_skill:skill_info(SkillModeId),
					Type = SkillInfo#skill_info.type,
					Type =:= ?SKILL_NORMAL2 orelse Type =:=?SKILL_SPECIAL orelse Type =:= ?SKILL_GIFT end,
					RoleRec#role.gd_skill);
			false ->
				lists:filter(fun({_,SkillModeId,_}) -> 
					SkillInfo = data_skill:skill_info(SkillModeId),
					Type = SkillInfo#skill_info.type,
					Type =:= ?SKILL_NORMAL orelse Type =:= ?SKILL_SPECIAL end,RoleRec#role.gd_skill)
		end,
	?INFO(role,"33005 send SkillList =~w",[SkillList]),
	case erlang:length(SkillList) of
		SkillListNum when SkillListNum =< 0 ->
			SkillListBin = <<>>;
		SkillListNum ->
			F3 = fun({_,SkillModeId,_}) ->
				<<SkillModeId:32>>
			end,
			SkillListBin = list_to_binary(lists:map(F3, SkillList))
	end,

	case erlang:length(ItemList) of
		ListNum when ListNum =< 0 ->
			ListBin = <<>>;
		ListNum ->
			F = fun(Item) ->
						{_, WorldID} = Item#item.key,
						ItemID = Item#item.cfg_ItemID,
						IntLevel = Item#item.gd_IntensifyLevel,
						IsBind = Item#item.gd_IsBind,
						Quality = Item#item.gd_Quality,
						IsQiling = Item#item.gd_IsQiling,
						InlayInfo = Item#item.gd_InlayInfo,		
						XilianInfo = Item#item.gd_XilianInfo,
						HoleNum = data_items:get_equip_hole_num(IntLevel div 5),
						case erlang:length(InlayInfo) of
							InlayNum when InlayNum =< 0 ->
								InlayBin = <<>>;
							InlayNum ->
								F2 = fun({A, B}) ->
											<<A:8, B:32>>
									end,
								InlayBin = list_to_binary(lists:map(F2, InlayInfo))
						end,
						case erlang:length(XilianInfo) of
							XilianNum when XilianNum =< 0 ->
								XilianBin = <<>>;
							XilianNum ->
								F1 = fun({A1, B1, C1}) ->
						 					<<A1:32, B1:8, C1:32>>
									end,
								XilianBin = list_to_binary(lists:map(F1, XilianInfo))
						end,
						<<WorldID:32,ItemID:32,IsBind:8,Quality:8,IntLevel:32,0:8,HoleNum:8,IsQiling:32,
						InlayNum:16,InlayBin/binary,XilianNum:16,XilianBin/binary>>
				end,
			ListBin = list_to_binary(lists:map(F, ItemList))
	end,
	{ok, pt:pack(33005, <<PlayerId:32,RoleId:16,
			 (RoleRec#role.gd_roleLevel):16,
			 % (RoleRec#role.gd_exp):32,
			 FightAbility:32,
			 (RoleRec#role.gd_currentHp):32,
			 (RoleRec#role.gd_maxHp):32,
			 (RoleRec#role.gd_liliang):32,
			 (RoleRec#role.gd_yuansheng):32,
			 (RoleRec#role.gd_tipo):32,
			 (RoleRec#role.gd_minjie):32,
			 (RoleRec#role.p_att):32,
			 (RoleRec#role.m_att):32,
			 (RoleRec#role.p_def):32,
			 (RoleRec#role.m_def):32,
			 (RoleRec#role.gd_speed):32,
			 
			 (RoleRec#role.gd_baoji):32,
			 (RoleRec#role.gd_shanbi):32,
			 
			 
			 (RoleRec#role.gd_gedang):32,
			 (RoleRec#role.gd_mingzhong):32,
			 (RoleRec#role.gd_zhiming):32,
			 (RoleRec#role.gd_xingyun):32,
			 (RoleRec#role.gd_fanji):32,
			 
			 (RoleRec#role.gd_pojia):32,
			 
			 (RoleRec#role.gd_liliangTalent):32,
			 (RoleRec#role.gd_yuanshengTalent):32,
			 (RoleRec#role.gd_tipoTalent):32,
			 (RoleRec#role.gd_minjieTalent):32,
			 (RoleRec#role.gd_fliliang):32,
			 (RoleRec#role.gd_fyuansheng):32,
			 (RoleRec#role.gd_ftipo):32,
			 (RoleRec#role.gd_fminjie):32,
			 SkillListNum:16, 
			 SkillListBin/binary,
			 ListNum:16,
			 ListBin/binary>>)}.
	
%%
%% Local Functions
%%

