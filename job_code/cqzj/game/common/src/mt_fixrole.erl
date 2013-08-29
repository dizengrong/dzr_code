-module(mt_fixrole).

-compile(export_all).

-include("mnesia.hrl").
-include("all_pb.hrl").

-define(ERROR_MSG(Format, Args),
        common_logger:error_msg( node(), ?MODULE,?LINE,Format, Args)).

connect_db() ->
    ok.


update() ->
    connect_db(),
    code:load_file(common_config_dyn),
    ?ERROR_MSG("fix_bad_role_pos [start]",[]),
    fix_bad_role_pos(),
    ?ERROR_MSG("fix_bad_role_pos [end]",[]),
    
    ok.

%%@doc 获取有问题的账户ID列表
get_bad_role_id_list()->
    MatchHead = #p_role_base{role_id='$1', _='_'},
    Guard = [],
    AllRoleIDList = db:dirty_select(?DB_ROLE_BASE_P, [{MatchHead, Guard, ['$1']}]),
    BadRoleIdList = 
        lists:foldl(
          fun(RoleID,AccIn)-> 
                  case db:dirty_read(?DB_ROLE_POS_P, RoleID) of
                      [] ->
                          [RoleID|AccIn];
                      _ ->
                          AccIn
                  end
          end, [], AllRoleIDList),
    {ok,length(BadRoleIdList),BadRoleIdList}.


%%@doc 获取有问题的账户数据
fix_bad_role_pos() ->
    AllList = db:dirty_match_object(?DB_ROLE_BASE_P, #p_role_base{_='_'}),
    Now = common_tool:now(),
    lists:foreach(
      fun(#p_role_base{role_id=RoleID,faction_id=FactionId,max_hp=MaxHp,max_mp=MaxMp}) ->
              case db:dirty_read(?DB_ROLE_POS_P, RoleID) of
                  [] ->
                      MapId = common_misc:get_home_map_id(FactionId),
                      MapProcessName = common_misc:get_common_map_name(MapId),
                      {MapId,Tx,Ty} = common_misc:get_born_info_by_map(MapId),
                      
                      RolePos = #p_role_pos{role_id=RoleID,map_id=MapId,pos=#p_pos{tx=Tx,ty=Ty},map_process_name=MapProcessName,
                                            old_map_process_name=MapProcessName},
                      db:dirty_write(?DB_ROLE_POS,RolePos),
                      db:dirty_write(?DB_ROLE_POS_P,RolePos);
                  _ ->
                      ignore
              end,
              case db:dirty_read(?DB_ROLE_FIGHT_P, RoleID) of
                  [] ->
                      RoleFight = #p_role_fight{role_id=RoleID,hp=MaxHp,mp=MaxMp,energy=28000,energy_remain=28000,
                                                time_reset_energy=Now},
                      db:dirty_write(?DB_ROLE_FIGHT,RoleFight),
                      db:dirty_write(?DB_ROLE_FIGHT_P,RoleFight);
                  _ ->
                      ignore
              end
      end, AllList).





