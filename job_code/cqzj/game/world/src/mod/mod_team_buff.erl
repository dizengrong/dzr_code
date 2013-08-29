%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 组队状态处理模块
%%% @end
%%% Created :  7 Jul 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_team_buff).

%% Include files
-include("mgeew.hrl").

%% API
-export([handle/1,
         delete_team_buff/1]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(BUFF_TYPE_FRIEND, 83).


%%%===================================================================
%%% API
%%%===================================================================
handle(Info) ->
    ?TRY_CATCH( do_handle_info(Info) ),
    ok.

delete_team_buff(RoleId)->
    ?TRY_CATCH( do_delete_team_buff(RoleId) ),
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle_info({TeamRoleList}) ->
    do_team_friend_buff(TeamRoleList);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts Info=~w",["无法处理组队状态参数",Info]).

do_delete_team_buff(RoleId)->
    delete_role_team_friend_buff(RoleId),
    ok.

do_team_friend_buff(TeamRoleList) ->

    %%筛选队伍成员，并得到两人的亲密度等级
    FriendList = [{TeamRoleA#p_team_role.role_id, TeamRoleB#p_team_role.role_id, 
                   get_friend_level(TeamRoleA#p_team_role.role_id, TeamRoleB#p_team_role.role_id)} 
                  || TeamRoleA <- TeamRoleList,
                     TeamRoleB <- TeamRoleList,
                     TeamRoleA#p_team_role.is_offline =:= false,
                     TeamRoleB#p_team_role.is_offline =:= false,
                     TeamRoleA#p_team_role.role_id =/= TeamRoleB#p_team_role.role_id,
                     mod_team:check_valid_distance(TeamRoleA,TeamRoleB) =:= true],

    %%去掉等级为0的组
    FriendList2 = filter_friend_level(FriendList),

    %%加好友度
    do_team_add_friendly(FriendList2),

    FriendList3 = filter_max_lv_friend(FriendList2),

    %%每个队员分别加BUFF
    add_team_firend_buff(FriendList3).
    

add_team_firend_buff(FriendList) ->
    [FriendBuffList] = common_config_dyn:find(friend,friend_buff),
    lists:foreach(
      fun({RoleID, _FriendID, Level}) ->
              %%获取应该加的BUFF
              {Level,BuffID}= lists:keyfind(Level,1,FriendBuffList),
              {ok, BuffDetail} = mgeew_skill_server:get_buf_detail(BuffID),
              %%发一个加BUFF的消息给角色
              case get({friend_buff, RoleID}) of
				  undefined->
					  put({friend_buff, RoleID},true),
		              add_buff_to_map_role(RoleID,BuffDetail);
				  _ ->
					  ignore
			  end
      end, FriendList).

delete_role_team_friend_buff(RoleID) ->
	case get({friend_buff, RoleID}) of
		undefined->
			ignore;
		_ ->
            del_buff_to_map_role(RoleID,?BUFF_TYPE_FRIEND),
			erase({friend_buff, RoleID})
	end.

%%增加好友度
do_team_add_friendly(FriendList) ->
    Now = common_tool:now(),
    lists:foreach(
	  fun({RoleID, FriendID, FriendLevel}) ->
			  if
				  FriendLevel=:=0 ->
					  delete_role_team_friend_buff(RoleID);
				  true->
              case get({add_friendly, FriendID, RoleID}) of
                  undefined ->
                      case get_last_time_add_friendly(RoleID, FriendID) of
                          undefined ->
                              do_team_add_friendly2(RoleID, FriendID);
                          LastTime ->
									  case Now - LastTime >= 10*60 of
                                  true ->
                                      do_team_add_friendly2(RoleID, FriendID);
                                  _ ->
                                      ignore
                              end
                      end;
                  _ ->
                      erase({add_friendly, FriendID, RoleID})
              end
			  end
      end, FriendList).

do_team_add_friendly2(RoleID, FriendID) ->
    case global:whereis_name(mod_friend_server) of
        undefined ->
            ignore;
        PID ->
            [{AddFriendly,_,_}] = common_config_dyn:find(friend,add_friendly_by_team),
            PID ! {add_friendly, RoleID, FriendID, AddFriendly, 1},
            put({last_time_add_friendly, RoleID, FriendID}, common_tool:now()),
            put({add_friendly, RoleID, FriendID}, true)
    end.

get_last_time_add_friendly(RoleID, FriendID) ->
    case get({last_time_add_friendly, RoleID, FriendID}) of
        undefined ->
            get({last_time_add_friendly, FriendID, RoleID});
        LastTime ->
            LastTime
    end.

%%根据亲密度划分等级，仇人或黑名单都没有BUFF加成
get_friend_level(RoleID, FriendID) ->
    try
        FriendInfo = mod_friend_server:get_dirty_friend_info(RoleID, FriendID),
        Friendly = FriendInfo#r_friend.friendly,
        FriendType = FriendInfo#r_friend.type,
        if FriendType =/= 1 ->
                0;
           true ->
                case mod_friend_server:get_friend_base_info_by_friendly(Friendly) of
                    #r_friend_base_info{friend_level = FriendLevel} ->
                        FriendLevel;
                    _ ->
                        0
                end
        end
    catch
        _ : _ ->
            0
    end.

filter_friend_level(FriendList) ->
    lists:foldl(
      fun({RoleID, FriendID, Level}, Acc) ->
              case Level =:= 0 of
                  true ->
                      case if_other_friend_in_team(RoleID, FriendList) of
                          true ->
                              Acc;

                          false ->
                              delete_role_team_friend_buff(RoleID),
                              Acc
                      end;
                  _ ->
                      [{RoleID, FriendID, Level}|Acc]
              end
      end, [], FriendList).

%%只过滤剩下好友度最高的关系
filter_max_lv_friend(FriendList) ->
    lists:foldl(
      fun({RoleID, FriendID, Level}, Acc) ->
              case lists:keyfind(RoleID, 1, Acc) of
                  false ->
                      [{RoleID, FriendID, Level}|Acc];
                  {RoleID, _, MaxLevel} ->
                      case Level > MaxLevel of
                          true ->
                              [{RoleID, FriendID, Level}|lists:keydelete(RoleID, 1, Acc)];
                          _ ->
                              Acc
                      end
              end
      end, [], FriendList).
  

if_other_friend_in_team(RoleID, FriendLvList) ->
	lists:any(
	  fun({TmpRoleID, _FriendID, Level}) ->
			  case RoleID =:= TmpRoleID andalso Level>0 of
				  true ->
					  true;
				  _ ->
					  false
			  end
	  end, FriendLvList).


add_buff_to_map_role(RoleID,BuffDetail)->
   mod_role_buff:add_buff(RoleID, [BuffDetail]).

del_buff_to_map_role(RoleID,BuffType)->
  mod_role_buff:del_buff_by_type(RoleID,[BuffType]).
