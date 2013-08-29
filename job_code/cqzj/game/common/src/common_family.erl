%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 22 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_family).

-include("common.hrl").

%% API
-export([
         info/2,
         nofity_role_online/2,
         nofity_role_offline/2,
         info_by_roleid/2,
         rename/2,
         update_member_name/3,
         broadcast_to_all_inmap_member/4,
         broadcast_to_all_inmap_member_except/5,
         kick_member_in_map_online/1,
         kick_member_in_map_online/2,
		 get_member_office_name/2,
		 get_family_boss_base_exp/1
        ]).

kick_member_in_map_online(FamilyID) ->
    FamilyMapPName = common_map:get_family_map_name(FamilyID),
    case global:whereis_name(FamilyMapPName) of
        undefined ->
            {error, family_map_process_not_found};
        PID ->
            PID ! {mod_map_family, kick_all_role},
            ok
    end.

%% 将族员踢出宗族地图
kick_member_in_map_online(FamilyID, RoleID) ->
    FamilyMapPName = common_map:get_family_map_name(FamilyID),
    case global:whereis_name(FamilyMapPName) of
        undefined ->
            {error, family_map_process_not_found};
        PID ->
            PID ! {mod_map_family, {kick_role, RoleID}},
            ok
    end.

%% 广播给所有在宗族地图中的成员
broadcast_to_all_inmap_member(FamilyID, Module, Method, Record) ->
    FamilyMapPName = common_map:get_family_map_name(FamilyID),
    case global:whereis_name(FamilyMapPName) of
        undefined ->
            {error, family_map_process_not_found};
        PID ->
            PID ! {mod_family, {broadcast_to_all_inmap_member, Module, Method, Record}},
            ok
    end.

%% 广播给所有在宗族地图中的成员，排除掉某个人
broadcast_to_all_inmap_member_except(FamilyID, Module, Method, Record, RoleID) ->
    FamilyMapPName = common_map:get_family_map_name(FamilyID),
    case global:whereis_name(FamilyMapPName) of
        undefined ->
            {error, family_map_process_not_found};
        PID ->
            PID ! {mod_map_family, {broadcast_to_all_inmap_member_except, Module, Method, Record, RoleID}},
            ok
    end.

%% 宗族改名
rename(FamilyID, NewFamilyName) ->
    NewFamilyName2 = common_tool:to_list(NewFamilyName),
    case erlang:length(NewFamilyName2) < 2 of
        true ->
            {false, ?_LANG_FAMILY_NAME_MUST_MORE_THAN_ONE};
        false ->
            case db:dirty_match_object(?DB_FAMILY, #p_family_info{family_name=NewFamilyName, _='_'}) of
                [] ->
                    FName = common_misc:make_family_process_name(FamilyID),
                    case global:whereis_name(FName) of
                        undefined ->
                            do_rename_offline(FamilyID, NewFamilyName);
                        PID ->
                            PID ! {rename, NewFamilyName}
                    end,
                    true;
                _ ->
                    {false, ?_LANG_FAMILY_NAME_ALREADY_EXIST}
            end
    end.

update_member_name(FamilyID, RoleID, RoleName) ->
    FName = common_misc:make_family_process_name(FamilyID),
    case global:whereis_name(FName) of
        undefined ->
            do_update_member_name_offline(FamilyID, RoleID, RoleName);
        PID ->
            PID ! {update_member_name, RoleID, RoleName}
    end,
    ok.

do_update_member_name_offline(FamilyID, RoleID, RoleName) ->
    db:transaction(
      fun() ->
              [#p_family_info{members=Members}=FamilyInfo] = db:read(?DB_FAMILY, FamilyID, write),
              case lists:keyfind(RoleID, #p_family_member_info.role_id, Members) of
                  false ->
                      ignore;
                  R ->
                      NewMembers = lists:keyreplace(RoleID, #p_family_member_info.role_id, Members, R#p_family_member_info{role_name=RoleName}),
                      db:write(?DB_FAMILY, FamilyInfo#p_family_info{members=NewMembers}, write)
              end,
              case FamilyInfo#p_family_info.create_role_id =:= RoleID of
                  true ->
                      FamilyInfo2 = FamilyInfo#p_family_info{create_role_name=RoleName};
                  false ->
                     FamilyInfo2 = FamilyInfo
              end,
              case FamilyInfo2#p_family_info.owner_role_id =:= RoleID of
                  true ->
                      FamilyInfo3 = FamilyInfo2#p_family_info{owner_role_name=RoleName};
                  false ->
                      FamilyInfo3 = FamilyInfo2
              end,
              SecondOwners = FamilyInfo3#p_family_info.second_owners,
              case lists:keyfind(RoleID, #p_family_second_owner.role_id, SecondOwners) of
                  false ->
                      FamilyInfo4 = FamilyInfo3;
                  SecondOwner ->
                      NewSecondOwner = SecondOwner#p_family_second_owner{role_id=RoleID, role_name=RoleName},
                      NewSecondOwners = lists:keyreplace(RoleID, #p_family_second_owner.role_id, SecondOwners, NewSecondOwner),
                      FamilyInfo4 = FamilyInfo3#p_family_info{second_owners=NewSecondOwners}
              end,
              db:write(?DB_FAMILY, FamilyInfo4, write)
      end).

do_rename_offline(FamilyID, NewFamilyName) ->
    db:transaction(
      fun() ->
              [#p_family_info{members=Members}=FamilyInfo] = db:read(?DB_FAMILY_P, FamilyID, write),
              lists:foreach(
                fun(#p_family_member_info{role_id=RoleID}) ->
                        [R] = db:read(?DB_ROLE_BASE_P, RoleID, write),
                        db:write(?DB_ROLE_BASE_P, R#p_role_base{family_name=NewFamilyName}, write)
                end, Members),
              db:write(?DB_FAMILY_P, FamilyInfo#p_family_info{family_name=NewFamilyName}, write)
      end).
    

info(FamilyID, Info) when FamilyID>0 ->
    FName = common_misc:make_family_process_name(FamilyID),
    case global:whereis_name(FName) of
        undefined ->
            ignore;
        PID ->
            PID ! Info
    end;
info(_FamilyID, _Info) ->
    ignore.

nofity_role_offline(FamilyID, RoleID) ->
    Name = common_misc:make_family_process_name(FamilyID),
    case global:whereis_name(Name) of
        undefined ->
            ignore;
        _ ->
            catch global:send(Name, {role_offline, RoleID})
    end.


nofity_role_online(FamilyID, RoleID) ->
    Name = common_misc:make_family_process_name(FamilyID),
    case global:whereis_name(Name) of
        undefined ->
            ignore;
        _ ->
            global:send(Name, {role_online, RoleID})
    end.

info_by_roleid(RoleID, Info) ->
    case db:dirty_read(?DB_ROLE_BASE, RoleID) of
        [] ->
            ignore;
        [#p_role_base{family_id=FamilyID}] ->
            case FamilyID > 0 of
                true ->
                    info(FamilyID, Info);
                false ->
                    ignore
            end
    end.
                            
get_member_office_name(FamilyId,RoleId)	->
    case db:dirty_read(?DB_FAMILY,FamilyId) of
        [FamilyInfo] when is_record(FamilyInfo,p_family_info)	->
            case lists:keyfind(RoleId,#p_family_member_info.role_id,FamilyInfo#p_family_info.members) of
                MemberInfo	when is_record(MemberInfo,p_family_member_info)	->
                    MemberInfo#p_family_member_info.title;
                _ ->
                    ?_LANG_NONE
            end;
        _ ->
            ?_LANG_NONE
    end.
	
get_family_boss_base_exp(RoleLevel) ->
	case common_config_dyn:find(family_boss, level_exp) of
		[ExpList] ->
			lists:foldl(
			  fun({MinLevel,MaxLevel,Exp}, AccExp) ->
					  if RoleLevel >= MinLevel andalso MaxLevel >= RoleLevel ->
							 Exp;
						 true ->
							 AccExp
					  end
			  end, 0, ExpList);
		_ ->
			0
	end.

