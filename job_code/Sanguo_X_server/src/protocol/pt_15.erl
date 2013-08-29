%% Author: dizengrong@gmail.com
%% Created: 2011-8-13
%% Description: 佣兵协议处理
-module(pt_15).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([read/2, write/2]).

%%%=========================================================================
%%% 解包函数
%%%=========================================================================

read(15000, <<Code:8>>) ->
	{ok, Code};

read(15010, <<Code:8>>) ->
	{ok, Code};

read(15020, <<RoleId:16, IsBattle:8>>) ->
	{ok, {RoleId, IsBattle}};

read(15100, <<Code:8>>) ->
	{ok, Code};

read(15050, _) ->
	{ok, []};

read(15101, _) ->
	{ok, []};

read(15102, <<RoleId:16, Action:8>>) ->
	{ok, {RoleId, Action}};

read(15200, <<RoleId:16, AttriId:8, IsProtected:8, AutoUseCard:8>>) ->
	{ok, {RoleId, AttriId, IsProtected, AutoUseCard}};

read(15201, <<RoleId:16, Size:16, Bin/binary>>) ->
	ReservedList = pt:binary_to_id_list(Size, 32, Bin, []),
	{ok, {RoleId, ReservedList}};

read(15202, <<ARoleId:16, BRoleId:16, Size:16, Bin/binary>>) ->
	ReservedList = pt:binary_to_id_list(Size, 32, Bin, []),
	{ok, {ARoleId, BRoleId, ReservedList}};	

read(15210, <<RoleId:16, AutoUseCard:8>>) ->
{ok, {RoleId, AutoUseCard}};

read(15300, _) ->
{ok, []};

read(15301, _) ->
{ok, []};

read(15302, _) ->
{ok, []};

read(15303, <<ZhaoshuType:8>>) ->
{ok, ZhaoshuType};

read(15400,<<ID:32>>) ->
{ok,ID};

read(15401,<<ID:32,RoleId:16>>) ->
{ok,{ID,RoleId}};

read(15501,<<RoleID:32,SkillID:32,ItemID:32,Num:16>>) ->
{ok,{RoleID,SkillID,ItemID,Num}};

read(_Cmd, _) ->
	{ok, []}.
%%%=========================================================================
%%% 组包函数
%%%=========================================================================

write(15000, [CanEmployNum, IsInGuild, EmployedNum, MerList]) ->
	Size = length(MerList),
	Data = write_role_list(Size, MerList, IsInGuild),
	{ok, pt:pack(15000, <<CanEmployNum:8, EmployedNum:8, Size:16, Data/binary>>)};

write(15001, RoleRec) ->
	FightAbility = mod_role:calc_combat_point(RoleRec),
	{_PlayerId, MerId} = RoleRec#role.key,
	Data = <<MerId:16, 
			 (RoleRec#role.gd_roleLevel):16,
			 (RoleRec#role.gd_exp):32,
			 (RoleRec#role.gd_isBattle):8,
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
			 0:32,
			 (RoleRec#role.gd_baoji):32,
			 (RoleRec#role.gd_shanbi):32,
			 0:32,
			 0:32,
			 (RoleRec#role.gd_gedang):32,
			 (RoleRec#role.gd_mingzhong):32,
			 (RoleRec#role.gd_zhiming):32,
			 (RoleRec#role.gd_xingyun):32,
			 (RoleRec#role.gd_fanji):32,
			 0:32,
			 (RoleRec#role.gd_pojia):32,
			 
			 (RoleRec#role.gd_liliangTalent):32,
			 (RoleRec#role.gd_yuanshengTalent):32,
			 (RoleRec#role.gd_tipoTalent):32,
			 (RoleRec#role.gd_minjieTalent):32,
			 (RoleRec#role.gd_fliliang):32,
			 (RoleRec#role.gd_fyuansheng):32,
			 (RoleRec#role.gd_ftipo):32,
			 (RoleRec#role.gd_fminjie):32
			 >>,
	{ok, pt:pack(15001, Data)};

write(15002, {RoleId, SkillTupleList, IsInGuild}) ->
	RoleRec = data_role:get(RoleId),
	IsMainRole = (RoleRec#role.gd_roleRank == 1),
	{ok, pt:pack(15002, <<RoleId:16, 
						  (length(SkillTupleList)):16,
						  (write_role_skill_list(SkillTupleList, IsMainRole, IsInGuild))/binary>>)};

%% 装备更新包
%SMSG_MERCENARY_EQUIP_INFO_RESPONSE                =  15010
% Array:   装备个数
%   uint:   佣兵Id
%   int8:   装备位置   1-武器  2-衣服  3-腰带  4-鞋子  5-配饰  6-帽子
%   uint：   物品唯一ID
%   uint：   物品原型ID
%   int8：   是否绑定     0-未绑定  1-已绑定
%   int8：   品质   0-普通 1-精良  2-优秀  3-完美   4-传说
%   uint：   套装ID
%   int8:   强化等级
%   int8:   化形编号   0-未化形，1-3对应3种化形后的编号
write(15010, EquipList) ->
	?INFO(items, "SendData = ~w", [[15010, EquipList]]),
	case erlang:length(EquipList) of
		ListNum when ListNum =< 0 ->
			ListBin = <<>>;
		ListNum ->
			F = fun(Item) ->
						{_, WorldID} = Item#item.key,
						ItemID = Item#item.cfg_ItemID,
						BagPos = Item#item.gd_BagPos,
						RoleID = Item#item.gd_RoleID,
						IntLevel = Item#item.gd_IntensifyLevel,
						IsBind = Item#item.gd_IsBind,
						Quality = Item#item.gd_Quality,
						SuitID = Item#item.gd_IsQiling,
						?INFO(items, "SendData = ~w", [[RoleID, BagPos, WorldID, ItemID, IsBind, Quality, SuitID, IntLevel]]),
						<<RoleID:32, BagPos:8, WorldID:32, ItemID:32, IsBind:8, Quality:8, SuitID:32, IntLevel:32, 0:8>>
				end,
			ListBin = list_to_binary(lists:map(F, EquipList))
	end,
	{ok, pt:pack(15010, <<ListNum:16, ListBin/binary>>)};

%% 装备信息获取
write(15011, _Equipment) ->

	ok;
	

write(15100, EmployableIdList) ->
	Size = length(EmployableIdList),
	Data = pt:write_id_list(Size, EmployableIdList, 16),
    {ok, pt:pack(15100, <<Size:16, Data/binary>>)};

write(15101, FiredRoleRecList) ->
	Size = length(FiredRoleRecList),
	Data = write_fired_role_list(Size, FiredRoleRecList),
	{ok, pt:pack(15101, <<Size:16, Data/binary>>)};

write(15102, {RoleId, IsEmployed}) ->
	{ok, pt:pack(15102, <<RoleId:16, IsEmployed:8>>)};

write(15210, {RoleId, AddtionalVal, TotalFliliang, TotalFyuansheng, TotalFtipo, TotalFminjie}) ->
	{ok, pt:pack(15210, <<RoleId:16, AddtionalVal:8, 
						  TotalFliliang:16, TotalFyuansheng:16, 
						  TotalFtipo:16, TotalFminjie:16>>)};

write(15300, Junwei) ->
	{ok, pt:pack(15300, <<Junwei:32>>)};

write(15301, Flag) ->
	{ok, pt:pack(15301, <<Flag:8>>)};

% uint:           玩家账号id
% string：          玩家名
% string：          公会名
% int8：             威望ID
% int8：             官职ID
% Array：           佣兵个数
%  int16:          佣兵ID 
write(15400,PlayerId) ->
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

	{ok,pt:pack(15400,<<
		PlayerId:32,
		(pt:write_string(Name))/binary,
		(pt:write_string(Name))/binary,
		Weiwang:8,
		GuanzhiID:8,
		RoleNum:16,
		RoleBin/binary
		>>)};
	

write(15401,{RoleRec,ItemList}) ->
	?INFO(role,"15401 send ItemList =~w",[ItemList]),
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
	?INFO(role,"15401 send SkillList =~w",[SkillList]),
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
	{ok, pt:pack(15401, <<PlayerId:32,RoleId:16,
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
%%=============================================================================
%% Local Functions
%%=============================================================================

write_role_list(0, [], _IsInGuild) -> <<>>;
write_role_list(Size, [RoleRec | Rest], IsInGuild) ->
	RestData = write_role_list(Size - 1, Rest, IsInGuild),
	FightAbility = mod_role:calc_combat_point(RoleRec),
	SkillData = write_role_skill_list(RoleRec#role.gd_skill, (RoleRec#role.gd_roleRank == 1), IsInGuild),
	{_PlayerId, MerId} = RoleRec#role.key,
	Data = <<MerId:16, 
			 (RoleRec#role.gd_roleLevel):16,
			 (RoleRec#role.gd_exp):32,
			 (RoleRec#role.gd_isBattle):8,
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
			 0:32,
			 (RoleRec#role.gd_baoji):32,
			 (RoleRec#role.gd_shanbi):32,
			 0:32,
			 0:32,
			 (RoleRec#role.gd_gedang):32,
			 (RoleRec#role.gd_mingzhong):32,
			 (RoleRec#role.gd_zhiming):32,
			 (RoleRec#role.gd_xingyun):32,
			 (RoleRec#role.gd_fanji):32,
			 0:32,
			 (RoleRec#role.gd_pojia):32,
			 (RoleRec#role.gd_liliangTalent):32,
			 (RoleRec#role.gd_yuanshengTalent):32,
			 (RoleRec#role.gd_tipoTalent):32,
			 (RoleRec#role.gd_minjieTalent):32,
			 (RoleRec#role.gd_fliliang):32,
			 (RoleRec#role.gd_fyuansheng):32,
			 (RoleRec#role.gd_ftipo):32,
			 (RoleRec#role.gd_fminjie):32,

			 (length(RoleRec#role.gd_skill)):16, 
			 SkillData/binary
			 >>,
	<<RestData/binary, Data/binary>>.


write_role_skill_list([], _IsMainRole, _IsInGuild) -> <<>>;
write_role_skill_list([{SkillUid, SkillModeId, SkillExp} | Rest], IsMainRole, IsInGuild) ->
	RestData = write_role_skill_list(Rest, IsMainRole, IsInGuild),
	SkillInfo = data_skill:skill_info(SkillModeId),
	case SkillInfo#skill_info.type of
		?SKILL_GUILD -> 
			case IsInGuild of
				true ->
					GuildData = 1;
				false ->
					GuildData = 2
			end;
		_ ->
			GuildData = 0
	end,
	<<SkillUid:32, SkillModeId:32, SkillExp:32, GuildData:8, RestData/binary>>.


%% 回被解雇的佣兵列表(15101)  S->C
%% SMSG_MERCENARY_RECRUITED                =  15101
%% Array:      被解雇的佣兵数
%%     int16    佣兵ID
%%     int16    佣兵等级
%%     uint    佣兵生命上限
%%     uint    佣兵力量
%%     uint    佣兵元神
%%     uint    佣兵体魄
%%     uint    佣兵敏捷
%%     uint    佣兵物理攻击
%%     uint    佣兵法术攻击
%%     uint    佣兵物理防御
%%     uint    佣兵法术防御
%%     uint    佣兵速度
%%     uint    佣兵怒气
%%     uint    佣兵暴击
%%     uint    佣兵闪避
%%     uint    佣兵连击
%%     uint    佣兵反震
%%     uint    佣兵格挡
%%     uint    佣兵命中
%%     uint    佣兵致命
%%     uint    佣兵幸运
%%     uint    佣兵反击
%%     uint    佣兵毒
%%     uint    佣兵破甲
write_fired_role_list(0, []) -> <<>>;
write_fired_role_list(Size, [FiredRoleRec | Rest]) ->
	RestData = write_fired_role_list(Size - 1, Rest),
	{_PlayerId, MerId} = FiredRoleRec#role.key,
	Data = <<MerId:16, 
			 (FiredRoleRec#role.gd_roleLevel):16,
			 %%(FiredRoleRec#role.gd_exp):32,
			 (FiredRoleRec#role.gd_maxHp):32,
			 (FiredRoleRec#role.gd_liliang):32,
			 (FiredRoleRec#role.gd_yuansheng):32,
			 (FiredRoleRec#role.gd_tipo):32,
			 (FiredRoleRec#role.gd_minjie):32,
			 (FiredRoleRec#role.p_att):32,
			 (FiredRoleRec#role.m_att):32,
			 (FiredRoleRec#role.p_def):32,
			 (FiredRoleRec#role.m_def):32,
			 (FiredRoleRec#role.gd_speed):32,
			 0:32,
			 (FiredRoleRec#role.gd_baoji):32,
			 (FiredRoleRec#role.gd_shanbi):32,
			 0:32,
			 0:32,
			 (FiredRoleRec#role.gd_gedang):32,
			 (FiredRoleRec#role.gd_mingzhong):32,
			 (FiredRoleRec#role.gd_zhiming):32,
			 (FiredRoleRec#role.gd_xingyun):32,
			 (FiredRoleRec#role.gd_fanji):32,
			 0:32,
			 (FiredRoleRec#role.gd_pojia):32
			 >>,
	<<RestData/binary, Data/binary>>.


