%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%
%%% @end
%%% Created : 25 Oct 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_dead_broadcast).

-include("mgeem.hrl").
-include("office.hrl").

-export([role_killed/8]).

-define(KILLNOTICE, "本势力勇士[~s]在 ~s 成功击杀入侵者").
%%-define(DEADNOTICE, "你被【~s】的玩家<font color=\"#fff47c\">[~s]</font>杀死了").

%% 国家中央广播
-define(WORLD_CENTRAL_BROADCAST, 1).
%% 国家中央广播
-define(COUNTRY_CENTRAL_BROADCAST, 2).

%%角色被杀死了
%%杀死外国玩家或被外国玩家杀死都有广播，竞技区及某些特定地图除外
%%RoleID：死亡玩家ID，SrcActorID：杀人的玩家ID，InReadoArea是否在竞技区
role_killed(RoleID, RoleName, FactionID,  SActorID, SRoleName, SFactionID,
            MapID, InReadoArea) ->
    %% 国战期间不发送死亡信件
    IsInWaroffaction = mod_waroffaction:is_in_waroffaction(FactionID),
    
    %%所有副本地图不需要发送死亡信件
    case common_config_dyn:find(fb_map,MapID) of
        []->
            IsNoDeadLetter = false;
        _ ->
            IsNoDeadLetter = true
    end,
    case IsInWaroffaction orelse IsNoDeadLetter  of
        true ->
            ignore;
        _ ->
            role_killed_notice(SRoleName, RoleID, SFactionID)
    end,
    %%如果杀死的是本国玩家就什么都不用做了
    case FactionID =:= SFactionID orelse InReadoArea of
        true ->
            ok;
        _ ->
            dead_broadcast(RoleID, RoleName, SActorID, SRoleName, FactionID, SFactionID, MapID, IsInWaroffaction)
    end.

dead_broadcast(RoleID, RoleName, SrcActorID, SrcRoleName, FactionID, SrcFactionID, MapID, IsInWaroffaction) ->
    InSelfCountry = common_misc:if_in_self_country(FactionID, MapID),
    SrcInSelfCountry = common_misc:if_in_self_country(SrcFactionID, MapID),
    MapName = common_map:get_map_str_name(MapID),
    %%在本国杀死外国玩家广播
    case SrcInSelfCountry andalso (not IsInWaroffaction) of
        true ->
            kill_foreigner_broadcast(SrcFactionID, SrcRoleName, RoleName, MapName);
        _ ->
            ok
    end,
    %%在本国被外国玩家杀害，国战期间不广播
    case InSelfCountry andalso (not IsInWaroffaction) of
        true ->
            killed_by_foreigner_broadcast(RoleID, RoleName, SrcActorID, SrcRoleName, SrcFactionID, MapID, FactionID);
        _ ->
            ok
	end,
	%% 战斗力排行第一位给杀死中央广播
	case common_role:get_fighting_power_rank(RoleID) of
		#p_role_fighting_power_rank{ranking=Ranking,title=Title} when Ranking =:= 1 ->
			Msg = get_fighting_power_rank_killed_msg(RoleName, FactionID, Title, SrcRoleName, SrcFactionID),
			common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg);
		_ ->
			%% 特殊官职玩家被杀死中央广播
			{ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
			#p_role_attr{office_id=OfficeID} = RoleAttr,
			
			case OfficeID > 0 of
				true ->
					{Channel, BcMsg} = get_broadcast_channel_msg(OfficeID, FactionID, RoleName, SrcFactionID, SrcRoleName),
					
					case Channel of
						?WORLD_CENTRAL_BROADCAST ->
							common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, BcMsg);
						_ ->
							common_broadcast:bc_send_msg_faction(FactionID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, BcMsg)
					end;
				_ ->
					%% 如果等级排行榜第一位被杀死会有广播
					case db:dirty_read(?DB_ROLE_LEVEL_RANK, RoleID) of
						[#p_role_level_rank{ranking=1, category=Category}] ->
							Msg = get_level_rank_killed_msg(RoleName, FactionID, Category, SrcRoleName, SrcFactionID),
							common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg);
						_ ->
							ignore
					end
			end
	end.

%% @doc 获取等级排行榜第一名玩家被杀广播消息
get_level_rank_killed_msg(RoleName, FactionID, Category, SrcRoleName, SrcFactionID) ->
 	CateName = case Category of
                   1 ->
                       "至尊虎皇";
                   2 ->
                       "至尊雀皇";
                   3 ->
                       "至尊龙皇";
                   _ ->
                       "至尊玄皇"
               end,
    lists:flatten(io_lib:format("天哪！~s的~s<font color=\"#FFFF00\">[~s]</font>居然被~s的<font color=\"#FFFF00\">[~s]</font>击败了", 
                                [get_faction_name_by_id(FactionID), CateName, RoleName,
                                 get_faction_name_by_id(SrcFactionID), SrcRoleName])).

%% @doc 获取战斗力排行榜第一名玩家被杀广播消息
get_fighting_power_rank_killed_msg(RoleName, FactionID, Title, SrcRoleName, SrcFactionID) ->
	lists:flatten(io_lib:format("天哪！~s的~s<font color=\"#FFFF00\">[~s]</font>居然被~s的<font color=\"#FFFF00\">[~s]</font>击败了", 
								[get_faction_name_by_id(FactionID), Title, RoleName,
								 get_faction_name_by_id(SrcFactionID), SrcRoleName])).

kill_foreigner_broadcast(SrcFactionID, SrcRoleName, _RoleName, MapName) ->
    Notice = io_lib:format(?KILLNOTICE, [SrcRoleName, MapName]),
    Notice2 = lists:flatten(Notice),
    common_broadcast:bc_send_msg_faction(SrcFactionID, ?BC_MSG_TYPE_CENTER, ?BC_MSG_SUB_TYPE, Notice2).

killed_by_foreigner_broadcast(RoleID, RoleName, SrcActorID, SrcRoleName, SrcFactionID, MapID, FactionID) ->
    case mod_map_actor:get_actor_txty_by_id(SrcActorID, role) of
        undefined ->
            ignore;
        {TX, TY} ->
            DataRecord = #m_map_role_killed_toc {
              role_name=RoleName,
              killer_name=SrcRoleName,
              faction_id=SrcFactionID,
              map_id=MapID,
              tx=TX,
              ty=TY
             },

            common_misc:chat_broadcast_to_faction(FactionID, ?MAP, ?MAP_ROLE_KILLED, DataRecord),

            common_map:send_to_all_map({mod_map_role, {killed_by_foreigner, RoleID, FactionID, MapID, TX, TY}})
    end.

%% @doc 获取广播的频道及内容
get_broadcast_channel_msg(OfficeID, FactionID, RoleName, SrcFactionID, SrcRoleName) ->
    case OfficeID of
        %% ?TITLE_EMPEROR ->
        %%     {?WORLD_CENTRAL_BROADCAST, lists:flatten(io_lib:format("天啊！皇帝[~s]居然被 ~s 的[~s]打败了", 
        %%                                                            [RoleName, get_faction_name_by_id(SrcFactionID), SrcRoleName]))};
        ?OFFICE_ID_KING ->
            {?WORLD_CENTRAL_BROADCAST, lists:flatten(io_lib:format("<font color=\"#FFFFFF\">天啊！~s<font color=\"#FFFF00\">~s</font>居然被 ~s 的<font color=\"#FFFF00\">~s</font>打败了</font>", 
                                                                   [get_faction_king_name_by_id(FactionID), RoleName, 
                                                                    get_faction_name_by_id(SrcFactionID), SrcRoleName]))};
        ?OFFICE_ID_JINYIWEI ->
            {?WORLD_CENTRAL_BROADCAST, lists:flatten(io_lib:format("<font color=\"#FFFFFF\">天啊！~s禁卫<font color=\"#FFFF00\">~s</font>居然被 ~s 的<font color=\"#FFFF00\">~s</font>打败了</font>",
                                                                     [get_faction_name_by_id(FactionID),
                                                                      RoleName, get_faction_name_by_id(SrcFactionID), SrcRoleName]))};
        ?OFFICE_ID_MINISTER ->
            {?WORLD_CENTRAL_BROADCAST, lists:flatten(io_lib:format("<font color=\"#FFFFFF\">天啊！~s文曲太傅<font color=\"#FFFF00\">~s</font>居然被 ~s 的<font color=\"#FFFF00\">~s</font>打败了</font>",
                                                                     [get_faction_name_by_id(FactionID),
                                                                      RoleName, get_faction_name_by_id(SrcFactionID), SrcRoleName]))};
        _ ->
            {?WORLD_CENTRAL_BROADCAST, lists:flatten(io_lib:format("<font color=\"#FFFFFF\">天啊！~s天纵神将<font color=\"#FFFF00\">~s</font>居然被 ~s 的<font color=\"#FFFF00\">~s</font>打败了</font>",
                                                                     [get_faction_name_by_id(FactionID),
                                                                      RoleName, get_faction_name_by_id(SrcFactionID), SrcRoleName]))}
    end.

%%发个信件告诉自己给谁杀了。。。
role_killed_notice(SrcRoleName, RoleID, SrcFactionID) ->
        %%lists:flatten(io_lib:format(?DEADNOTICE, [get_faction_name_by_id(SrcFactionID), SrcRoleName])),
    Text = common_letter:create_temp(?DEAD_LETTER,[get_faction_name_by_id(SrcFactionID), SrcRoleName]),
    common_letter:sys2p(RoleID, Text, "PK失败的信息通知", 2).

get_faction_name_by_id(FactionID) ->
    if
        FactionID =:= 1 ->
            "<font color=\"#00FF00\">西夏</font>";
        FactionID =:= 2 ->
            "<font color=\"#F600FF\">南诏</font>";
        true ->
            "<font color=\"#00CCFF\">东周</font>"
    end.

get_faction_king_name_by_id(FactionID) ->
    if
        FactionID =:= 1 ->
            "<font color=\"#00FF00\">西夏国王</font>";
        FactionID =:= 2 ->
            "<font color=\"#F600FF\">南诏盟主</font>";
        true ->
            "<font color=\"#00CCFF\">东周族皇</font>"
    end.    
