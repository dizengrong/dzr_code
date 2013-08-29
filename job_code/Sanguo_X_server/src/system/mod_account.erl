-module(mod_account).
-include("common.hrl").


-export([create_role/3,init_global_name_table/0,get_account_id_by_name/1,get_info_by_id/1,
		 get_account_info_rec/1,get_account_id_by_rolename/1, get_player_name/1,
		 get_main_role_id/1,clear_fcm/1,get_roleSex_by_PlayerId/1]).

-export([create_visitor/0,visitor_to_player/3]).

-record (account_id_map, {account = "", id = 0}).
-record (rolename_account_map, {rolename = "", account = ""}).


%% 获取主角色id
get_main_role_id(PlayerId) ->
	AccountRec = get_account_info_rec(PlayerId),
	AccountRec#account.gd_RoleID.

%% 获得主角性别
get_roleSex_by_PlayerId(PlayerId) ->
    AccountRec = get_account_info_rec(PlayerId),
    AccountRec#account.gd_Sex.

init_global_name_table()->
	init_account_id_map_table(),
	init_rolename_account_map_table(),
	init_max_account_id_table(),
	ok.

init_account_id_map_table() ->
	ets:new(ets_account_id_map, [public,named_table,set,{keypos, #account_id_map.account}]),

	%% 加载帐号信息
	F = fun([AccountID,Account]) ->
			NewAccount = binary_to_list(Account),	
			ets:insert(ets_account_id_map, #account_id_map{account = NewAccount, id = AccountID})
		end,
	lists:foreach(F, db_sql:get_all("SELECT gd_AccountID, gd_Account FROM gd_account ORDER BY gd_AccountID")).

init_rolename_account_map_table() ->
	ets:new(ets_rolename_account_map, [public,named_table,set,{keypos, #rolename_account_map.rolename}]),

	F = fun([Account,AccountRoleName]) ->
			Record = #rolename_account_map{
						rolename = binary_to_list(AccountRoleName),
						account = binary_to_list(Account)},			
			ets:insert(ets_rolename_account_map, Record)
		end,
	lists:foreach(F, db_sql:get_all("SELECT gd_Account,gd_RoleName FROM gd_account ORDER BY gd_AccountID")).

init_max_account_id_table()	->
	Server_index_offset = util:get_app_env(server_index) * ?MAX_ACCOUNT_PER_SERVER,
	ets:new(ets_max_account_index,[public,named_table,set,{keypos, 1}]),
	Sql = io_lib:format("SELECT IFNULL(MAX(gd_AccountID),0) FROM gd_account where gd_AccountID < ~w", 
					    [Server_index_offset + ?MAX_ACCOUNT_PER_SERVER]),
	Max_account = case db_sql:get_one(Sql) of
		null ->
			0;
		Num ->
			Num rem ?MAX_ACCOUNT_PER_SERVER
	end,

	ets:insert(ets_max_account_index,{max_num,Max_account + Server_index_offset}).

	
create_role(AccName, RoleName, MerId) ->
	case validate_name(RoleName) of
		 {false, Msg1} -> 
		 	{false, Msg1};
		 true ->
		 	case register_account(AccName, RoleName) of
				{true, Id} ->
					create_account(AccName, RoleName, Id, MerId, ?ACCOUNT_RANK_PLAYER);
				{false, Msg2} ->	%% 角色名已经存在了
					?INFO(account, "Failed register: ~w ~w, Msg: ~w", 
						  [AccName, RoleName, Msg2]),
					{false, 2}
			end
	end.
	
create_account(AccName, RoleName, Id, MerId, _Rank)->
	?INFO(account,"create account ~w, name ~s, rolename ~s, merid ~w, rank ~w",[Id,AccName, RoleName, MerId, _Rank]),
	RoleRec = role_base:init_new_role(Id, MerId, 1),
	Account_info = #account{
				gd_accountID = Id,
				gd_Account   = AccName,
				gd_RoleName  = RoleName,
				gd_RoleID    = MerId,
				gd_Sex		 = RoleRec#role.gd_roleSex},
	player_db:insert_account_rec(Id, Account_info),
	
	
	RoleRec1 = RoleRec#role{
				gd_name     = RoleName, 
				gd_isBattle = 2},
	role_db:insert_role_rec(Id, RoleRec1),

	%% 在这里初始化玩家建号时的一些数据
	RoleDataRec = #role_data{gd_accountId = Id, gd_EmployableList = []},
	role_db:insert_role_data_rec(Id, RoleDataRec),
	player_db:insert_player_data(Id, #player_data{gd_accountId = Id}),

	mod_economy:init(Id),
%%	mod_scene:init_position(Id),

	mod_items:initItems(Id),
	mod_xunxian:initXunxian(Id),
%% 	mod_arena:initArena(Id),

	mod_guaji:initGuaji(Id),
	mod_marstower:initMarsTower(Id),

	mod_yunbiao:init_yunbiao(Id),
	{true,Id}.	
	
	
    %% 角色名合法性检测
validate_name(Name) ->
    case validate_name(len, Name) of
		{false, Msg} ->
			{false, Msg};
		true ->
			validate_name(content, Name)
	end.

%% 角色名合法性检测:长度
validate_name(len, Name) ->
    case asn1rt:utf8_binary_to_list(list_to_binary(Name)) of
        {ok, CharList} ->
            Len = util:string_width(CharList),   
            case Len < 21 andalso Len > 1 of
                true ->
                    true;
                false ->
                    %%角色名称长度为1~5个汉字
                    {false, 3}
            end;
        {error, _Reason} ->
            %%非法字符
            {false, 1}
    end;

%% 角色名合法性检测:是否包含被屏蔽词汇
validate_name(content, Name) ->
	case mod_word_filter:find_prohibited_words(Name) of
		not_found ->
			true;
		{found, _PosLen} ->
			{false, 1}
	end.
    
register_account(AccName, RoleName)->
	global:set_lock({account,account}),
	Reply = case ets:lookup(ets_account_id_map, AccName) of
		[]->
			case ets:lookup(ets_rolename_account_map, RoleName) of
				[] ->
					[{max_num,Id}] = ets:lookup(ets_max_account_index,max_num),
					ets:insert(ets_max_account_index,{max_num,Id+1}),
					ets:insert(ets_account_id_map, 
							   #account_id_map{account = AccName, id = Id+1}),
					ets:insert(ets_rolename_account_map, 
							   #rolename_account_map{rolename = RoleName, account = AccName}),
					{true, Id+1};
				_ ->
					{false, role_exist}
			end;
		[_Rec]->
			{false, account_exist}
	end,
	global:del_lock({account,account}),
	Reply.

get_account_id_by_name(Name)->
	case ets:lookup(ets_account_id_map,Name) of
		[]->
			false;
		[Record]->
			{true, Record#account_id_map.id}
	end.

get_account_info_rec(PlayerId) ->
	player_db:get_account_rec(PlayerId).	
	
get_info_by_id(Id)->
	Account_info = player_db:get_account_rec(Id),
	Economy_info = mod_economy:get_economy_status(Id),
	{Account_info,Economy_info}.

get_player_name(ID) ->
	Acc = player_db:get_account_rec(ID),
	Acc#account.gd_RoleName.

%% 根据角色名获取其玩家id
-spec get_account_id_by_rolename(string()) -> false | {true, player_id()}.
get_account_id_by_rolename(Name)->
	case ets:lookup(ets_rolename_account_map,Name) of
		[Acc_name]->
			get_account_id_by_name(Acc_name#rolename_account_map.account);
		[]->
			false
	end.

clear_fcm(Id)->
	%%player_db:update_player_data_elements(Id,Id, [{#player_data.gd_fcmOfflineTime,#player_data.gd_fcmOfflineTime}]).
	player_db:update_player_data_elements(Id,Id, [{#player_data.gd_fcmOfflineTime,0}]).

create_visitor()->
	MerId = util:rand(1, 6),
	%%减少进入临界区的可能
	Hash = util:rand(1,100),
	[{max_num,DispatchId}] = ets:lookup(ets_max_account_index,max_num),

	AccName = "visitor_" ++ integer_to_list(Hash) ++ "_" ++ integer_to_list(DispatchId+1),
	RoleName = "游客_" ++ integer_to_list(Hash) ++ "_" ++ integer_to_list(DispatchId+1),

	{true,Id} = register_account(AccName,RoleName),

	{true,Id} = create_account(AccName, RoleName, Id, MerId, ?ACCOUNT_RANK_VISITOR),

	{{true, Id, AccName, RoleName}, MerId}.

%%-spec visitor_to_player(id,acc_name,role_name)->ok|{false,reason}.
visitor_to_player(Id,Acc_name,Role_name)->
	%%更新ets_account_id_map
	%%更新ets_rolename_account_map
	%%更新account_info
	Acc_info = get_account_info_rec(Id),
	Old_acc_name = Acc_info#account.gd_Account,
	Old_role_name = Acc_info#account.gd_RoleName,

	player_db:update_account_elements(Id, Id, [{#account.gd_Account,Acc_name},{#account.gd_RoleName,Role_name}]),

	global:set_lock({account,Id}),
	
	ets:delete(ets_account_id_map, Old_acc_name),
	ets:insert(ets_account_id_map, #account_id_map{account = Acc_name,id = Id}),

	ets:delete(ets_rolename_account_map, Old_role_name),
	ets:insert(ets_rolename_account_map, #rolename_account_map{rolename = Role_name, account = Acc_name}),

	global:del_lock({account,Id}).