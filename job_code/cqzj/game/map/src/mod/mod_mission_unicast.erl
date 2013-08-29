%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 任务通知模块
%%%
%%% Created : 2011-04-05
%%% -------------------------------------------------------------------
-module(mod_mission_unicast).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mission.hrl"). 

-export([
         p_update_unicast/3,
         p_unicast/5,
         c_unicast/2,
         c_unicast/1,
         r_unicast/1
        ]).

%% --------------------------------------------------------------------
%% 向发送到前端的数据列表压入一条需要删除的数据
%% --------------------------------------------------------------------
p_update_unicast(del, RoleID, MissionID) when is_integer(MissionID) ->
    NewUpdateRecord = 
    case get_update_unicast(RoleID) of
        false ->
            #m_mission_update_toc{del_mission_list=[MissionID], update_mission_list=[]};
        UpdateRecord ->
            OldList = UpdateRecord#m_mission_update_toc.del_mission_list,
            UpdateList = UpdateRecord#m_mission_update_toc.update_mission_list,
            InUpdateList = lists:keyfind(MissionID, #p_mission_info.id, UpdateList),
            if
                InUpdateList ->
                    UpdateList2 = lists:keydelete(MissionID, #p_mission_info.id, UpdateList);
                true ->
                    UpdateList2 = UpdateList
            end,
            Exists = lists:member(MissionID, OldList),
            if
                Exists =:= true ->
                    UpdateRecord#m_mission_update_toc{
                        del_mission_list=OldList,
                        update_mission_list=UpdateList2};
                true ->
                    UpdateRecord#m_mission_update_toc{
                        del_mission_list=[MissionID|OldList],
                        update_mission_list=UpdateList2}
            end
    end,
    put({?MISSION_UNICAST_UPDATE_DICT_KEY, RoleID}, NewUpdateRecord);
 
%% --------------------------------------------------------------------
%% 想任务列表更新数据里插入一条任务
%% --------------------------------------------------------------------
p_update_unicast(update, RoleID, PInfo) when is_record(PInfo,p_mission_info) ->
    NewUpdateRecord = 
    case get_update_unicast(RoleID) of
        false ->
            #m_mission_update_toc{update_mission_list=[PInfo], del_mission_list=[]};
        UpdateRecord ->
            OldList = UpdateRecord#m_mission_update_toc.update_mission_list,
            DelList = UpdateRecord#m_mission_update_toc.del_mission_list,
            MissionID = PInfo#p_mission_info.id,
            InDelList = lists:member(MissionID, DelList),
            if
                InDelList ->
                    DelList2 = lists:delete(MissionID, DelList);
                true ->
                    DelList2 = DelList
            end,
            Exists = lists:keyfind(MissionID, #p_mission_info.id, OldList),
            if
                Exists =:= false ->
                    UpdateRecord#m_mission_update_toc{
                        update_mission_list=[PInfo|OldList],
                        del_mission_list=DelList2};
                true ->
                    UniqueList = lists:keydelete(MissionID, #p_mission_info.id, OldList),
                    UpdateRecord#m_mission_update_toc{
                        update_mission_list=[PInfo|UniqueList],
                        del_mission_list=DelList2}
            end
    end,
    put({?MISSION_UNICAST_UPDATE_DICT_KEY, RoleID}, NewUpdateRecord).                 
       
%% --------------------------------------------------------------------
%% 获得任务列表更新数据
%% --------------------------------------------------------------------     
get_update_unicast(RoleID) ->
    case get({?MISSION_UNICAST_UPDATE_DICT_KEY, RoleID}) of
        undefined ->
            false;
        UpdateRecord ->%%#m_mission_update_toc
            UpdateRecord
    end.

%% --------------------------------------------------------------------
%% 最终导出广播列表时 再合并一次其他需要广播的信息
%% --------------------------------------------------------------------
get_merged_unicast(RoleID) ->
    UnicastList = get_unicast_list(RoleID),
    case get_update_unicast(RoleID) of
        false ->
            UnicastList;
        UpdateRecord ->
            UnicastData = #r_unicast{
                roleid = RoleID, 
                module = ?MISSION, 
                unique = ?DEFAULT_UNIQUE, 
                method = ?MISSION_UPDATE,
                record = UpdateRecord
                },
            [UnicastData|UnicastList]
    end.
 
erase_merged_unicast(RoleID) ->
    erase({?MISSION_UNICAST_UPDATE_DICT_KEY, RoleID}).

get_unicast_list(RoleID) ->
    case get({?MISSION_UNICAST_DICT_KEY, RoleID}) of
        undefined ->
            [];
        List ->
            List
    end.

%% --------------------------------------------------------------------
%% 向发送到前端的数据列表压入一条新数据
%% --------------------------------------------------------------------
p_unicast(RoleID, Unique, Module, Method, DataRecord) ->
    UnicastData = #r_unicast{
      roleid = RoleID, 
      module = Module, 
      unique = Unique, 
      method = Method,
      record = DataRecord
     },
    UnicastList = get_unicast_list(RoleID),
    put({?MISSION_UNICAST_DICT_KEY, RoleID}, [UnicastData|UnicastList]).

%% --------------------------------------------------------------------
%% 提交发送到前端的数据列表 即发送
%% --------------------------------------------------------------------
c_unicast(RoleID) ->
    Line = common_misc:get_role_line_by_id(RoleID),
    c_unicast(RoleID, Line).
c_unicast(RoleID, Line) ->
    UnicastList = get_merged_unicast(RoleID),
    erase_merged_unicast(RoleID),
    common_misc:unicast(Line, UnicastList),
    put({?MISSION_UNICAST_DICT_KEY, RoleID}, []).

%% --------------------------------------------------------------------
%% 回滚发送到前端的数据列表 即清除
%% --------------------------------------------------------------------
r_unicast(RoleID) ->
    erase_merged_unicast(RoleID),
    put({?MISSION_UNICAST_DICT_KEY, RoleID}, []).