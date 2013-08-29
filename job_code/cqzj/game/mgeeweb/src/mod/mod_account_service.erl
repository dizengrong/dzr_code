%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 18 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_account_service).

%% API
-export([
         get/3
        ]).

-include("mgeeweb.hrl").

get("/get_account_all_data" ++ _, Req, _) ->
    do_get_account_all_data(Req);
get("/has_role" ++ _, Req, _) ->
    do_has_role(Req);
get("/get_all_no_role_id" ++ _, Req, _) ->
    do_get_all_no_role_id(Req);
get("/get_all" ++ _, Req, _) ->
    do_get_all(Req);
get("/get_role_id" ++ _, Req, _) ->
    do_get_role_id(Req);    
get("/get_role_base_info/" ++ _, Req, _) ->
    do_get_role_base_info(Req);
get("/create_role" ++ _, Req, _) ->
    do_create_role(Req);
get("/pass_fcm" ++ _, Req, _) ->
    do_pass_fcm(Req);
get("/change_fcm_status" ++ _, Req, _) ->
    do_change_fcm_status(Req);
get("/kick_stall/"++RoleId,Req,_)->
    do_kick_stall(RoleId,Req);
get("/reset_energy/" ++ RoleId, Req, _) ->
    do_reset_role_energy(RoleId, Req);
get("/skill_return_exp/" ++ RoleID, Req, _) ->
    do_skill_return_exp(RoleID, Req);
get("/rebind" ++ _, Req, _) ->
    do_rebind_account(Req);
get("/del" ++ _, Req, _) ->
    do_rename_account(Req);

get(_, Req, _) ->
    Req:not_found().

do_rename_account(Req) ->
	Get = Req:parse_qs(),
	RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
	TmpAccountName = common_tool:to_binary(proplists:get_value("account_name", Get)),
	catch global:send(common_misc:get_role_line_process_name(RoleID),{'EXIT', delete, error_auth_packet}),
	case db:transaction(fun() -> 
								case db:read(?DB_ROLE_BASE,RoleID,write) of
									[] ->
										[{result, ok}, {msg, "该角色已被删除，请刷新页面"}];
									[#p_role_base{account_name=AccountName}=RoleBase] ->
										case AccountName =:= TmpAccountName of
											true ->
												NewAccountName = common_tool:to_binary(lists:flatten(lists:concat([common_tool:to_list(AccountName), "※"]))),
												db:write(?DB_ROLE_BASE, RoleBase#p_role_base{account_name=NewAccountName},write),
												db:write(?DB_ROLE_BASE_P, RoleBase#p_role_base{account_name=NewAccountName},write),
												[{result, ok}];
											false ->
												[{result, error}, {msg, "请求超时"}]
										end
								end
						end) of
		{atomic,Rtn} ->
			mgeeweb_tool:return_json(Rtn, Req);
		{aborted, Reason} ->
			?ERROR_MSG("do_rename_account error:~w",[Reason]),
			mgeeweb_tool:return_json_error(Req)
	end.

%% 重新绑定账号
do_rebind_account(Req) ->
	Get = Req:parse_qs(),
	AccountName = common_tool:to_binary(proplists:get_value("account_name", Get)),
	NewAccountName = common_tool:to_binary(proplists:get_value("new_account", Get)),
	ServerID = common_tool:to_integer(proplists:get_value("server_id", Get)),
	case db:dirty_read(?DB_ACCOUNT_REBIND_P, AccountName) of
		[] ->
			Rtn = [{result, ok}, {msg, "该账号没有需要重新绑定的角色，请刷新页面"}],
			mgeeweb_tool:return_json(Rtn, Req);
		[#r_account_rebind{need_rebind_list=NeedRebindList} = R] ->
			case lists:keyfind(ServerID, #r_rebind_role.server_id, NeedRebindList) of
				false ->
					Rtn = [{result, ok}, {msg, "该角色已重新绑定账号，请刷新页面"}],
					mgeeweb_tool:return_json(Rtn, Req);
				RebindRole ->
					TmpAccountName = RebindRole#r_rebind_role.new_tmp_account,
					%% 确定该账号是否尚未绑定过角色
					case db:dirty_match_object(?DB_ROLE_BASE_P, #p_role_base{account_name=NewAccountName, _='_'}) of
						[] ->
							case db:dirty_match_object(?DB_ROLE_BASE_P, #p_role_base{account_name=TmpAccountName, _='_'}) of
								[] ->
									Rtn = [{result, ok}, {msg, "该角色已重新绑定账号，请刷新页面"}],
									mgeeweb_tool:return_json(Rtn, Req);
								[RoleBase] ->
									db:dirty_write(?DB_ROLE_BASE_P, RoleBase#p_role_base{account_name=NewAccountName}),
									NewR = R#r_account_rebind{need_rebind_list=lists:delete(RebindRole, NeedRebindList)},
									db:dirty_write(?DB_ACCOUNT_REBIND_P, NewR),
									db:dirty_write(?DB_FCM_DATA, #r_fcm_data{account=NewAccountName}),
									db:dirty_delete(?DB_FCM_DATA, TmpAccountName),
									case db:dirty_read(?DB_ACCOUNT, TmpAccountName) of
										[] ->
											db:dirty_write(?DB_ACCOUNT, #r_account{account_name=NewAccountName, 
																				   create_time=common_tool:now(),
																				   role_num=1});
										[RAccount] ->
											db:dirty_delete(?DB_ACCOUNT, TmpAccountName),
											db:dirty_write(?DB_ACCOUNT, RAccount#r_account{account_name=NewAccountName})
									end,
									Rtn = [{result, ok}],
									mgeeweb_tool:return_json(Rtn, Req)
							end;
						_ ->
							Rtn = [{result, error}, {msg, "该账号已经绑定角色"}],
							mgeeweb_tool:return_json(Rtn, Req)
					end
			end
	end.    

do_get_all_no_role_id(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{account_name=AccountName, _='_'}) of
        [] ->
            mgeeweb_tool:return_json_error(Req);
        [#p_role_base{role_id=RoleID}] ->
            {Host, Port, GatewayKey} = gen_server:call({global, mgeel_key_server}, {get_all_lines_and_key, AccountName, RoleID}),
            [#p_role_attr{level=Level}] = db:dirty_read(db_role_attr, RoleID),
            [#p_role_pos{map_id=MapID, pos=#p_pos{tx=TX, ty=TY}}] = db:dirty_read(db_role_pos, RoleID),
            Rtn = [{level, Level}, {map_id, MapID}, {tx, TX}, {ty, TY}, {result, ok}, 
                   {gateway_key, GatewayKey}, {role_id, RoleID},
                   {gateway_host, Host}, {gateway_port, Port}],
            mgeeweb_tool:return_json(Rtn, Req)
    end.
    

do_get_all(Req) ->
	Get = Req:parse_qs(),
	AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
	RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
	{Host, Port, GatewayKey} = gen_server:call({global, mgeel_key_server}, {get_all_lines_and_key, AccountName, RoleID}),
	[#p_role_attr{level=Level}] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
	[#p_role_base{faction_id=FactionID,sex=Sex}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    case catch db:dirty_read(db_role_pos, RoleID) of
        [#p_role_pos{map_id=MapID, pos=#p_pos{tx=TX, ty=TY}}]->
            next;
		_ ->
			%%如果因为掉线数据存储问题，先回到王城
			{MapID,TX,TY} = common_misc:get_born_info_by_map( common_misc:get_home_map_id(FactionID) )
	end,
	Rtn = [{level, Level}, {map_id, MapID}, {tx, TX}, {ty, TY}, {result, ok}, 
		   {gateway_key, GatewayKey},{sex,Sex},
		   {gateway_host, Host}, {gateway_port, Port}],
	mgeeweb_tool:return_json(Rtn, Req).
    
do_pass_fcm(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    db:transaction(
      fun() ->
              case db:read(?DB_FCM_DATA, AccountName, write) of
                  [] ->
                      db:write(?DB_FCM_DATA, #r_fcm_data{account=AccountName, passed=true}, write);
                  [FcmData] ->
                      db:write(?DB_FCM_DATA, FcmData#r_fcm_data{passed=true}, write)
              end
      end),
    mgeeweb_tool:return_json_ok(Req).

do_change_fcm_status(Req)->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    TmpStatus = common_tool:to_integer(proplists:get_value("status", Get)),
    Status=
        case TmpStatus of
            1->true;
            _->false
        end,   
    db:transaction(
      fun() ->
              case db:read(?DB_FCM_DATA, AccountName, write) of
                  [] ->
                      db:write(?DB_FCM_DATA, #r_fcm_data{account=AccountName, passed=Status}, write);
                  [FcmData] ->
                      db:write(?DB_FCM_DATA, FcmData#r_fcm_data{passed=Status}, write)
              end
      end),
    mgeeweb_tool:return_json_ok(Req).

do_kick_stall(RoleId,Req)->
    IntRoleId = common_tool:to_integer(RoleId),

    case db:dirty_read(?DB_STALL, IntRoleId) of
        [] ->
            Rtn = [{result, "角色不在摆摊中"}];

        [StallDetail] ->
            #r_stall{mode=Mode, remain_time=RemainTime, mapid=MapID} = StallDetail,
            case Mode =:= 1 andalso RemainTime =:= 0 of
                true ->
                    Rtn = [{result, "摊位已结束"}];
                _ ->
                    MapPName = common_misc:get_common_map_name(MapID),
                    case gen_server:call({global, MapPName}, {kick_role_stall, IntRoleId}) of
                        ok ->
                            Rtn = [{result,"踢摊位成功"}];
                        {error, Reason} ->
                            Rtn = [{result,lists:concat(["踢摊位失败,原因为:",common_tool:to_list(Reason)])}]
                    end
            end
    end,
    mgeeweb_tool:return_json(Rtn,Req).

do_get_role_base_info(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{account_name = AccountName, _='_'}) of
        [] ->
            Rtn = [{result, false}];
        [#p_role_base{role_id=RoleID}] ->
            [#p_role_attr{level=Level}] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
            [#p_role_pos{map_id=MapID}] = db:dirty_read(?DB_ROLE_POS, RoleID),
            Rtn = [{result, true}, {map_id, MapID}, {level, Level}]
    end,
    mgeeweb_tool:return_json(Rtn, Req).
%%获取当前人数最少的国家
do_get_faction_id() ->
    case db:dirty_read(?DB_ROLE_FACTION, 1) of
        [] ->
            Faction1 = 0;
        [#r_role_faction{number=N1}] ->
            Faction1 = N1
    end,
    case db:dirty_read(?DB_ROLE_FACTION, 2) of
        [] ->
            Faction2 = 0;
        [#r_role_faction{number=N2}] ->
            Faction2 = N2
    end,
    case db:dirty_read(?DB_ROLE_FACTION, 3) of
        [] ->
            Faction3 = 0;
        [#r_role_faction{number=N3}] ->
            Faction3 = N3
    end,
    Min = lists:min([Faction1, Faction2, Faction3]),
    case Min of
        Faction1 ->
            1;
        Faction2 ->
            2;
        _ ->
            3
    end.

%% 获取账号下的角色
do_has_role(Req) ->
    Get = Req:parse_qs(),
    StrAccountName = proplists:get_value("account", Get),
    AccountName = common_tool:to_binary( StrAccountName ),
    Rtn = 
        case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{account_name = AccountName, _='_'}) of
            [] ->
                LowerStrAccountName = get_lower_account_name(StrAccountName),
                
                case do_has_role_2(LowerStrAccountName) of 
                    {ok,Roles}-> 
                        transfer_account_roles(Roles);
                    _ ->
                        [{result, false}]
                end;
            Roles ->
                transfer_account_roles(Roles)
        end,
    mgeeweb_tool:return_json(Rtn, Req).

get_lower_account_name(StrAccountName)->
    case common_config:is_account_case_sensitive() of
        true->
            StrAccountName;
        _ ->
            string:to_lower( StrAccountName )
    end.

transfer_account_roles(Roles) ->
	case erlang:length(Roles) =:= 1 of
		true ->
			[#p_role_base{role_id=RoleID}] = Roles,
			[{result, true}, {role_id,RoleID} ];
		false ->
			SimpleRoles = 
				lists:foldl(
				  fun(#p_role_base{role_id=RoleID,role_name=RoleName,account_name=AccountName,sex=Sex,head=Head,faction_id=FactionID,create_time=CreateTime,server_id=ServerID}, Acc) ->
						  [#p_role_attr{level=Level,category=Category,jingjie=Jingjie,gold=Gold,gold_bind=GoldBind}] = db:dirty_read(?DB_ROLE_ATTR,RoleID),
						  NewR = #r_simple_role_detail{role_id=RoleID,role_name=RoleName,account_name=AccountName,sex=Sex,head=Head,faction_id=FactionID,create_time=CreateTime,
													 level=Level,category=Category,jingjie=Jingjie,gold=Gold,gold_bind=GoldBind,server_id=ServerID},
						  [ mgeeweb_tool:transfer_to_json(NewR) | Acc]
				  end, [], Roles),
			[{result, true}, {game_name,common_tool:game_name()}, {roles,SimpleRoles} ]
	end.

do_has_role_2(StrAccountName)->
    AccountName = common_tool:to_binary( StrAccountName ),
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{account_name = AccountName, _='_'}) of
        [] ->
            not_found;
        Roles ->
            {ok,Roles}
    end.
do_get_account_all_data(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{account_name = AccountName, _='_'}) of
        [] ->
            Rtn = [{has_role, false}, {default_faction, do_get_faction_id()}];
        [#p_role_base{role_id=RoleID}] ->
            {Host, Port, GatewayKey} = gen_server:call({global, mgeel_key_server}, {get_all_lines_and_key, AccountName, RoleID}),
            [#p_role_attr{level=Level, role_name=RoleName}] = db:dirty_read(db_role_attr, RoleID),
            [#p_role_pos{map_id=MapID, pos=#p_pos{tx=TX, ty=TY}}] = db:dirty_read(db_role_pos_p, RoleID),
            %% 判断玩家是否需要重新绑定账号
            case db:dirty_read(?DB_ACCOUNT_REBIND_P, AccountName) of
                [] ->
                    Rtn = [{level, Level}, {map_id, MapID}, {tx, TX}, {ty, TY}, {result, ok}, 
                           {gateway_key, GatewayKey},
                           {gateway_host, Host}, {gateway_port, Port}, {has_role, true}, {role_id,RoleID}, 
                           {default_faction, do_get_faction_id()}],
                    ignore;
                [#r_account_rebind{need_rebind_list=NeedRebindList}] ->
                    case NeedRebindList =:= [] of
                        true ->
                            Rtn = [{level, Level}, {map_id, MapID}, {tx, TX}, {ty, TY}, {result, ok}, 
                                   {gateway_key, GatewayKey},
                                   {gateway_host, Host}, {gateway_port, Port}, {has_role, true}, 
                                   {role_id,RoleID}, {default_faction, do_get_faction_id()}],
                            ok;
                        false ->
                            List = lists:foldl(
                                     fun(R, Acc) ->
                                             [ mgeeweb_tool:transfer_to_json(R) | Acc]
                                     end, [], NeedRebindList),                    
                            Rtn = [{result, need_rebind}, {list, List}, {role_name, RoleName}]
                    end
            end
    end,    
    mgeeweb_tool:return_json(Rtn,Req).

%%@doc 获取玩家的角色ID
do_get_role_id(Req) ->    
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    case common_misc:get_roleid_by_accountname(AccountName) of
        RoleID when is_integer(RoleID) andalso RoleID>0->
            Result = [{result, RoleID}],
            mgeeweb_tool:return_json(Result, Req);
        RoleIdList when is_list(RoleIdList) andalso length(RoleIdList)>1 ->
            %% multiple
            Result = [{result, multiple}],
            mgeeweb_tool:return_json(Result, Req);
        _ ->
            mgeeweb_tool:return_json_error(Req)
    end.


%% 创建新的角色，信息已经在PHP那边过滤，这边无需再次判断和过滤
do_create_role(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("ac", Get)),
    Uname = common_tool:to_binary(proplists:get_value("uname", Get)),
    Sex = common_tool:to_integer(proplists:get_value("sex", Get)),
    FactionID = common_tool:to_integer(proplists:get_value("fid", Get)),
    Head = common_tool:to_integer(proplists:get_value("head", Get)),
    HairType = common_tool:to_integer(proplists:get_value("hair_type", Get)),
    HairColor = common_tool:to_binary(proplists:get_value("hair_color", Get)),
    AccountType = common_tool:to_integer(proplists:get_value("account_type", Get, ?ACCOUNT_TYPE_NORMAL)),
	Category = common_tool:to_integer(proplists:get_value("category", Get)),
    %%默认无职业，职业ID为0
    case catch gen_server:call({global, mgeel_account_server}, {add_role, AccountName, AccountType, Uname, Sex, FactionID,
                                                                Head, HairType, HairColor, Category}) of
        {ok, RoleID} ->
            Rtn = [{result, ok}, {role_id, RoleID}],
            mgeeweb_tool:return_json(Rtn, Req);
        {error, Reason} ->
            Rtn = [{result, Reason}],
            mgeeweb_tool:return_json(Rtn, Req);
        Error ->
            ?ERROR_MSG("~p", [Error]),
            Rtn = [{result, system_error}],
            mgeeweb_tool:return_json(Rtn, Req)
    end.

%% @doc 重置精力值
do_reset_role_energy(RoleIDStr, Req) ->
    RoleID = common_tool:to_integer(RoleIDStr),
    case mgeer_role:absend(RoleID, {mod_map_role, {reset_role_energy, RoleID}}) of
        ok ->
            mgeeweb_tool:return_json_ok(Req);
        _ ->
            mgeeweb_tool:return_json_error(Req)
    end.

%% @doc 技能返回经验
do_skill_return_exp(RoleIDStr, Req) ->                
    RoleID = common_tool:to_integer(RoleIDStr),
    case mgeer_role:absend(RoleID, {mod_map_role, {skill_return_exp, RoleID}}) of
        ok ->
            mgeeweb_tool:return_json_ok(Req);
        _ ->
            mgeeweb_tool:return_json_error(Req)
    end.
