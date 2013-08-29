%%%----------------------------------------------------------------------
%%% File    : mgeec_misc.erl
%%% Author  : Xiaosheng
%%% Created : 2010-07-18
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeec_misc).

%%
%% Include files
%%
-include("mgeec.hrl").

%%
%% Exported Functions
%%
-export([
         d_get_chat_role_info/1,
         check_in_channel/2,
         set_channel_role/5,
         del_channel_role/2,
         create_channel/1,
         get_channel_role/1,
         get_channel_sub_pnum/1,
         get_channel_extend_pname/2,
         update_channel_extend_counter/3,
         set_channel_extend_counter/3,
         get_channel_role_info/2,
         cast_role_router/2,
         get_free_extend_channel/1,
         get_level_channel/2,
         get_level_channel_pname/2,
         dn_update_channel_role_info/5,
         get_channel_list/1,
         get_faction_name/1
        ]).

%% --------------------------------------------------------------------
%% 约定
%% d_* 数据库脏操作 自行 try...catch
%% t_* 数据库事务操作 自行 db:transaction(fun)
%% --------------------------------------------------------------------

cast_role_router({pname, RoleProcessName}, RouterData) ->

    case global:whereis_name(RoleProcessName) of
        undefined ->
            {error, not_exists};
        Pid ->
            gen_server:cast(Pid, {router, RouterData}),
            {ok, Pid}
    end;

cast_role_router({pid, RoleProcessPID}, RouterData) ->
    gen_server:cast(RoleProcessPID, {router, RouterData}),
    {ok, RoleProcessPID};

cast_role_router({role, RoleID_RoleName}, RouterData) ->
    RoleProcessName = common_misc:chat_get_role_pname(RoleID_RoleName),
    case global:whereis_name(RoleProcessName) of
        undefined ->
            {error, not_exists};
        Pid ->
            gen_server:cast(Pid, {router, RouterData}),
            {ok, Pid}
    end;

cast_role_router(_Key, _RouterData) ->
    %%?DEV("~ts:~w ~ts:~w", ["cast 路由信息失败, Key", Key, "数据", RouterData]),
    {error, not_match}.

d_get_chat_role_info(Key) ->
    try 

        RoleBase = d_get_role_base(Key),
        RoleExt = d_get_role_ext(Key),

        #p_role_base{role_id=RoleID, 
                     role_name=RoleName,
                     faction_id=FactionID, 
                     sex=Sex} = RoleBase,

        NewRoleName = common_tool:to_list(RoleName),

        #p_chat_role{roleid=RoleID, 
                     rolename=NewRoleName, 
                     factionid=FactionID,
                     faction_name=get_faction_name(FactionID),
                     sex=Sex,
                     head=RoleBase#p_role_base.head,
                     sign=RoleExt#p_role_ext.signature
                    }

    catch
        _:Reason ->
            ?ERROR_MSG("~ts:~w", ["脏读玩家数据失败了", Reason]),
            false
    end.


%% --------------------------------------------------------------------
%% Function: get_faction_name/1
%% Description: 根据国家ID获得国家名
%% Parameter: int() FactionID 国家ID
%% Return: string() 国家名 如果失败 返回一个默认的国家名,可能是:"未知的国家"
%% --------------------------------------------------------------------

get_faction_name(FactionID) ->
    case FactionID of
        1 -> 
            ?_LANG_FACTION_1;
        2 -> 
            ?_LANG_FACTION_2;
        3 -> 
            ?_LANG_FACTION_3;
        Other -> 
            ?ERROR_MSG("~ts:~w", ["获取国家名发现异常,传入的国家ID是", Other]),
            ?_LANG_FACTION_UNKNOW
    end.

%%@doc 生成玩家的频道列表
%%@return list() [#p_channel_info]
get_channel_list(RoleChatData)->

    do_get_channel_list(RoleChatData, []).

do_get_channel_list(RoleChatData, ChannelList) ->
    {_, WorldChannelInfo} = 
        common_misc:chat_get_world_channel_info(),

    do_get_channel_list_2(RoleChatData, [WorldChannelInfo|ChannelList]).

do_get_channel_list_2(RoleChatData, ChannelList) ->
    
    #r_role_chat_data{faction_id=FactionID} = RoleChatData,

     {_, FactionChannelInfo} = 
        common_misc:chat_get_faction_channel_info(FactionID),

    do_get_channel_list_3(RoleChatData, [FactionChannelInfo|ChannelList]).

do_get_channel_list_3(RoleChatData, ChannelList) ->
    #r_role_chat_data{family_id=FamilyID} = RoleChatData,
    if
        FamilyID > 0 ->
            {_, FamilyChannelInfo} = 
                common_misc:chat_get_family_channel_info(FamilyID),

            ChannelList2 = [FamilyChannelInfo|ChannelList];
        true ->
            ChannelList2 = ChannelList
    end,

    do_get_channel_list_4(RoleChatData, ChannelList2).

do_get_channel_list_4(RoleChatData, ChannelList) ->
    #r_role_chat_data{team_id=TeamID} = RoleChatData,
    if
        TeamID > 0 ->
            {_, TeamChannelInfo} = common_misc:chat_get_team_channel_info(TeamID),
            ChannelList2 = [TeamChannelInfo|ChannelList];
        true ->
            ChannelList2 = ChannelList
    end,
    
    do_get_channel_list_5(RoleChatData, ChannelList2).
    
do_get_channel_list_5(RoleChatData, ChannelList) ->
    #r_role_chat_data{level=Level,faction_id=FactionID} = RoleChatData,
    ChannelInfo = get_level_channel(Level, FactionID),
    
    if
        ChannelInfo =/= false ->
            [ChannelInfo|ChannelList];
        true ->
            ChannelList
    end.

d_get_role_base(RoleID) when erlang:is_integer(RoleID) andalso RoleID > 0 ->
    {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
    RoleBase;

d_get_role_base(RoleName) when erlang:is_list(RoleName) andalso RoleName =/= "" ->
    RoleID = common_misc:get_roleid(RoleName),
    {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
    RoleBase;

d_get_role_base(_) ->
    throw(not_match_args).


d_get_role_ext(RoleID) when erlang:is_integer(RoleID) andalso RoleID > 0 ->
    {ok, RoleExt} = common_misc:get_dirty_role_ext(RoleID),
    RoleExt;

d_get_role_ext(RoleName) when erlang:is_list(RoleName) andalso RoleName =/= "" ->
    RoleID = common_misc:get_roleid(RoleName),
    {ok, RoleExt} = common_misc:get_dirty_role_ext(RoleID),
    RoleExt;

d_get_role_ext(_) ->
    throw(not_match_args).

get_channel_extend_pname(ChannelSign, ID) ->
    lists:concat([ChannelSign, "_", ID]).

get_channel_role(ChannelSign) ->
    ets:lookup(?ETS_CHANNEL_ROLE, ChannelSign).

set_channel_extend_counter(ChannelSign, ExtendID, Num) ->
    List = ets:lookup(?ETS_CHANNEL_COUNTER, ChannelSign),
    Extend = lists:keyfind(ExtendID, #channel_counter.extend_id, List),
    if
        Extend =:= false ->
            NewExtend = #channel_counter{channel_sign=ChannelSign, 
                                         extend_id=ExtendID, 
                                         num=Num};
        true ->
            NewExtend = Extend#channel_counter{num=Num},
            ets:delete_object(?ETS_CHANNEL_COUNTER, Extend)
    end,
    ets:insert(?ETS_CHANNEL_COUNTER, NewExtend).

update_channel_extend_counter(ChannelSign, ExtendID, Num) ->
    List = ets:lookup(?ETS_CHANNEL_COUNTER, ChannelSign),
    Extend = lists:keyfind(ExtendID, #channel_counter.extend_id, List),
    
    if
        Extend =:= false ->
            ?ERROR_MSG("~ts:~w ~w", ["仿佛有异常,竟然拿不到扩展频道", ChannelSign, ExtendID]),
            false;
        true ->
        #channel_counter{num=OldNum} = Extend,

        NewNum = Num + OldNum,
        NewExtend = Extend#channel_counter{num=NewNum},
        ets:delete_object(?ETS_CHANNEL_COUNTER, Extend),
        ets:insert(?ETS_CHANNEL_COUNTER, NewExtend)
    end.

set_channel_role(ChannelInfo, RoleID, RoleName, RoleChatInfo, Pid) ->
    %%?DEV("set_channel_role, channelinfo: ~w", [ChannelInfo]),
    ChannelSign = ChannelInfo#p_channel_info.channel_sign,
    create_channel(ChannelInfo),
    timer:sleep(300),
    ChoseExtend = get_free_extend_channel(ChannelSign),
    if
        ChoseExtend =/= [] ->
            ExtendID = ChoseExtend#channel_counter.extend_id,
            ExtendProcessName = get_channel_extend_pname(ChannelSign, ExtendID),
            Data = 
                #channel_role{channel_sign=ChannelSign,
                              role_id=RoleID,
                              role_info=RoleChatInfo,
                              pid=Pid,
                              channel_extend_process=ExtendProcessName},


            %%?DEV("~ts:~w ~ts:~w", ["玩家", RoleID, "尝试加入了频道", ChannelSign]),

            gen_server:cast({global, ChannelSign}, 
                            {join, RoleID, RoleName, RoleChatInfo, Pid, ExtendID}),

            del_channel_role(ChannelSign, RoleID),
            ets:insert(?ETS_CHANNEL_ROLE, Data);
        true ->
            ?ERROR_MSG("~ts:~w ~w", ["仿佛有异常,竟然拿不到扩展频道", RoleID, ChannelInfo]),
            ignore
    end.

get_free_extend_channel(ChannelSign) ->

    ExtendList = ets:lookup(?ETS_CHANNEL_COUNTER, ChannelSign),
    
    case ExtendList of
        [Extend|ExtendList2] ->

            lists:foldl(
              fun(ExtendItem, Pre) ->
                      #channel_counter{num=Num}=ExtendItem,
                      #channel_counter{num=PreNum}=Pre,
                      if
                          Num > PreNum  ->
                              Pre;
                          true ->
                              ExtendItem
                      end
              end, Extend, ExtendList2);
        [] ->
            []
    end.

del_channel_role(ChannelSign, RoleID) ->
    DelPattern = 
        {channel_role, 
         ChannelSign,
         RoleID,
         '_',
         '_', 
         '_'},

    ets:match_delete(?ETS_CHANNEL_ROLE, DelPattern).

get_channel_role_info(ChannelSign, RoleID) ->
    Pattern = 
        {channel_role, 
         ChannelSign,
         RoleID,
         '_',
         '_', 
         '_'},

    ChannelRoleList = ets:match_object(?ETS_CHANNEL_ROLE, Pattern),

    %%?DEV("~ts:~w", ["获取玩家频道角色信息", ChannelRoleList]),
    case ChannelRoleList of
        [ChannelRoleInfo] ->
            ChannelRoleInfo;
        _Other ->
            false
    end.

check_in_channel(ChannelSign, RoleID) ->   
    case get_channel_role_info(ChannelSign, RoleID) of
        false ->
            false;
        _ ->
            true
    end.

create_channel(ChannelInfo) ->

    ChannelSign = ChannelInfo#p_channel_info.channel_sign,
    case global:whereis_name(ChannelSign) of
        undefined ->
            {ok, Pid} = 
                supervisor:start_child(mgeec_channel_sup, [ChannelInfo]),
            Pid;
        Pid ->
            Pid
    end.

%%获取子进程数量
get_channel_sub_pnum(ChannelType) ->
    List = ?CHANNEL_TYPE_CONFIG,
    Vo = lists:keyfind(ChannelType, 1, List),
    %%?DEV("~ts:~w", ["获得频道子进程", Vo]),
    case Vo of
        false ->
            1;
        {_, Num} ->
            Num
    end.

get_level_channel(RoleLevel, FactionID) ->
    {level_channel, LevelList} =  mgeec_config:get_config(level_channel),
    %%?DEV("get_level_channel, levellist: ~w", [LevelList]),
	
    do_get_level_channel(RoleLevel, FactionID, LevelList).
   
do_get_level_channel(_RoleLevel, _FactionID, []) ->
    false;
do_get_level_channel(RoleLevel, FactionID, [LevelConfig|LevelList]) ->
    {Start, End, ChannelID, ChannelName} = LevelConfig,
    if
        RoleLevel >= Start andalso RoleLevel =< End ->

            ChannelSign = get_level_channel_pname(ChannelID, FactionID),

            %%?DEV("do_get_level_channel, channelsigh: ~w", [ChannelSign]),

            #p_channel_info{channel_sign=ChannelSign, 
                            channel_type=?CHANNEL_TYPE_LEVEL, 
                            channel_name=ChannelName};

        true ->
            do_get_level_channel(RoleLevel, FactionID, LevelList)
    end.

get_level_channel_pname(ChannelID, FactionID) ->
    lists:concat([?CHANNEL_SIGN_LEVEL_CHANNEL, "_", ChannelID, "_", FactionID]).

%%dn-->不带try的脏操作
dn_update_channel_role_info(RoleID, ChannelSign, ChannelType, IsOnline, RoleChatData) ->
    #r_role_chat_data{role_name=RoleName,faction_id=FactionId,
                      sex=Sex, office_name=OfficeName,head=Head,signature=Signature} = RoleChatData,
    
    Pattern = #p_chat_channel_role_info{channel_sign=ChannelSign, role_id=RoleID, _='_'},
    case  db:dirty_match_object(?DB_CHAT_CHANNEL_ROLES, Pattern) of
        [] ->
            OnlineNumAdd = 1,
            TotalNumAdd = 1,
            ok;
        RoleChannelInfoList ->
            lists:foreach(fun(RoleChannelInfo) -> 
                                  db:dirty_delete_object(?DB_CHAT_CHANNEL_ROLES, RoleChannelInfo)                  
                          end, RoleChannelInfoList),
            OnlineNumAdd = 1,
            TotalNumAdd = 0,
            ok
    end,
    
    NewData = 
        #p_chat_channel_role_info{channel_sign = ChannelSign,
                                  channel_type = ChannelType,
                                  role_id = RoleID,
                                  role_name = RoleName,
                                  sex = Sex,
                                  faction_id = FactionId,
                                  office_name = OfficeName,
                                  head=Head,
                                  sign=Signature,
                                  is_online = IsOnline},
    
    
    case db:dirty_read(?DB_CHAT_CHANNELS, ChannelSign) of
        [ChannelInfo] ->
            OnlineNum = ChannelInfo#p_channel_info.online_num+OnlineNumAdd,
            TotalNum = ChannelInfo#p_channel_info.total_num+TotalNumAdd,
            NewChannelInfo = ChannelInfo#p_channel_info{online_num=OnlineNum, total_num=TotalNum},
            db:dirty_write(?DB_CHAT_CHANNELS, NewChannelInfo);
        [] ->
            ?ERROR_MSG("~ts", ["没有找到频道的基本信息"]),
            NewChannelInfo = {error, empty}
    end,
    
    db:dirty_write(?DB_CHAT_CHANNEL_ROLES, NewData),
    {NewData, NewChannelInfo}.
