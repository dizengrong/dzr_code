%%%-----------------------------------
%%% @Module  : pt_30
%%% @Email   : chenjianrong@4399.com
%%% @Created : 2011.09.23
%%% @Description: 30, team info.
%%%-----------------------------------

-module(pt_30).

-export([read/2, write/2]).


-include("common.hrl").
%%
%%客户端 -> 服务端 ----------------------------
%%

%% 创建队伍请求(30000) C1->S
%% CMSG_TEAM_CREATE				= 30000			//创建队伍请求
%% int 			场景id			

read(30000, Bin) ->
	case Bin of
       <<Scene_id:32>> ->
		{ok,Scene_id};
	_ ->
		?DEBUG(pt30,"can't match bin as ~w",[Bin]),
           {error, no_match}
    end;
    

%% 邀请组队/加入队伍(30001) C1/C2->S
%% CMSG_TEAM_INVITE				= 30001			//邀请组队/加入队伍请求
%% Byte:		操作码，0,邀请组队，1加入队伍
%% string：		玩家名字
read(30001, Bin) ->
	<<Ops_code:8,Bin1/binary>> = Bin,
	{Name, _} = pt:read_string(Bin1),
	{ok,{Ops_code,Name}};

%% 对组队邀请的处理(30002) C2->S
%% CMSG_TEAM_INVITE_HANDLE				=30002				//对组队邀请的处理
%% byte		操作0通过1拒绝
%% Uint32：		玩家id		
read(30002, Bin) ->
	case Bin of
       <<Result:8,Uid:32>> ->
		{ok,{Result,Uid}};
	_ ->
		?DEBUG(pt30,"can't match bin as ~w",[Bin]),
           {error, no_match}
    end;

%% 转移队长(30003) C1->S
%% CMSG_TEAM_CAPTAIN_CHANGE					=30003			//转移队长
%% byte	   0
read(30003, _Bin) ->
	{ok, no_data};

%% 离开/解散/踢出队伍请求(30005) C1,C2->S
%% 副本外：
%% 	C1解散/踢出队伍
%% 	C2 主动离开副本
%% 副本内：
%% 	C1，C2,主动离开副本
%% CMSG_TEAM_LEAVE					=30004			
%% byte：		操作 0 离开 1 解散 2踢出
read(30005, Bin) ->
	case Bin of
       <<Op_code:8>> ->
		{ok,{Op_code}};
	_ ->
		?DEBUG(pt30,"can't match bin as ~w",[Bin]),
           {error, no_match}
	end;

%% 队长确认是否同意加入(30006) C1->S
%% Byte:		操作码，0同意，1不同意
%% Int:			玩家ID
read(30006, Bin) ->
	case Bin of
       <<Result:8,Uid:32>> ->
		{ok,{Result,Uid}};
	_ ->
		?DEBUG(pt30,"can't match bin as ~w",[Bin]),
           {error, no_match}
    end;


%% 查询可加入队伍列表(30009) C->S 
%% CMSG_TEAM_LIST_GET                        = 30009    
%%     uint32：    副本ID    
read(30009, Bin) ->
	case Bin of
       <<Scene_id:32>> ->
		{ok,{Scene_id}};
	_ ->
		?DEBUG(pt30,"can't match bin as ~w",[Bin]),
           {error, no_match}
    end;

%%快速加入队伍(30010)C->S
%%SMSG_QUICK_ADD_TEAM _RESULT							=30010			
%%Uint32	场景id
read(30010,Bin)->
	<<Scene_id:32>> = Bin,
	{ok,{Scene_id}};

%% 请求组队聊天窗队员的信息(30011) C->S
%% CMSG_TEAM_CHAT_MEMBER                        = 30011    
%% uint8:0
read(30011,_Bin)->
	{ok,{}};

%% 发送聊天（30012）C->S
%% CMSG_TEAM_CHAT_SEND                                     = 30012
%% String        聊天内容
read(30012,Bin)->
	{Content, _} = pt:read_string(Bin),
	{ok,{Content}};

%% 请求掉落的物品（30013）C->S
%% CMSG_TEAM_CHAT_GOODS                                    = 30013
%% uint8:0
read(30013,_Bin)->
	{ok,{}};

%% 跳转组队地图（30020）C->S
%% CMSG_GOTO_DUNGUEON                                    = 30013
%% uint16 场景id
read(30020,Bin)->
	<<Scene_id:16>> = Bin,
	{ok,{Scene_id}};


read(proto_num,finish)->
	{ok,finish}.

%%
%% 服务端-> 客户端 ----------------------------
%%
%% 创建队伍回复(30000) S->C1
%% CMSG_TEAM_CREATE				= 30000			//创建队伍请求
%% Byte		0成功，1失败			
write(30000, {Result}) ->
	{ok, pt:pack(30000, <<Result:8>>)};


%% 邀请组队/加入队伍成功(30001) S->C1, C2
%% （队员收到组队邀请并接受，或者主动加入某个队伍）
%% SMSG_TEAM_INVITE				= 30001			//邀请组队/加入队伍成功
%% Byte:		操作码，0,邀请组队成功，1加入队伍成功
%% Uint32：		队长id	
%% string：		队长名字
%% uint32：		队员id
%% string：		队员名字
%% uint16：		队长主角原型id				
%% uint16：		队员主角原型id				
%% byte：		对方圣痕等级
%% int 			场景id
write(30001, {Result,Team}) ->
	Lead_id = Team#team.leader_id,
	Lead_name = Team#team.leader_name,
	
	Mate_id = Team#team.mate_id,
	Mate_name = Team#team.mate_name,

	Lead_merid =Team#team.leader_career,
	Mate_merid = Team#team.mate_career,
	
	Lead_level = Team#team.leader_level,
	Mate_level = Team#team.mate_level,

	Lead_name_bin = pt:write_string(Lead_name),
	Mate_name_bin = pt:write_string(Mate_name),
	
	Scene_id = Team#team.scene_id,

	{ok, pt:pack(30001, <<Result:8,Lead_id:32,Lead_name_bin/binary,Mate_id:32,Mate_name_bin/binary,
						  	Lead_merid:16,Mate_merid:16,Lead_level:8,Mate_level:8,Scene_id:32>>)};

%% 收到组队邀请(30002) S->C2
%% SMSG_TEAM_INVITE_APPLY				=30002			//收到组队邀请
%% Uint32：		玩家id		
%% String：		玩家名字
write(30002, {Id, Name,SceneId}) ->
	Name_bin = pt:write_string(Name),
	
	{ok, pt:pack(30002, <<Id:32,Name_bin/binary,SceneId:32>>)};


%% 收到加入队伍的申请(30006) S->C1
%% SMSG_TEAM_JOIN_APPLY =30006 
%% uint： 申请人的账号ID
%% String： 申请人的名字
%% uint8： 申请人等级 
%% uint8： 申请人的佣兵ID
write(30006, {Id, Name,Level,Role_id}) ->
	Name_bin = pt:write_string(Name),
	
	{ok, pt:pack(30006, <<Id:32,Name_bin/binary,Level:8,Role_id:8>>)};


%% 队长变更(30004) S->C1, S->C2
%% SMSG_TEAM_	CAPTAIN_CHANGE				=30003				//队长变更通知
%% Uint32:		队长id
%% string：		队长名字
%% Uint32:		队员id
%% string:		队员名字
write(30004, {Team}) ->
	Leader_id = Team#team.leader_id,
	Leader_name = Team#team.leader_name,
	Mate_id = Team#team.mate_id,
	Mate_name = Team#team.mate_name,

	Leader_name_bin = pt:write_string(Leader_name),
	Mate_name_bin = pt:write_string(Mate_name),
	
	{ok, pt:pack(30004, <<Leader_id:32,Leader_name_bin/binary,Mate_id:32,Mate_name_bin/binary>>)};

%% 离开/解散/踢出队伍通知(30005) S->C1，S->C2
%% SMSG_TEAM_LEAVE					=30004			
%% byte:		离开原因 0主动离开1队长解散队伍导致 2被踢 3离线
%% 副本外：	解散，踢出队伍，离开
%% 副本内：	主动离开副本，离线
%% int32:		离开的用户的id
write(30005, {Reason,Id}) ->
	{ok, pt:pack(30005, <<Reason:8,Id:32>>)};



write(30009,Team_list)->
	F = fun(Team) ->
		Leader_id = Team#team.leader_id,
		Lead_name = Team#team.leader_name,
		Lead_level = Team#team.leader_level,
		
		Lead_major_merid = Team#team.leader_career,

		Lead_name_bin = pt:write_string(Lead_name),
		<<Lead_name_bin/binary,Lead_level:8,Lead_major_merid:8,Leader_id:32>>
	end,
	List_num = length(Team_list),
    Bin_list = list_to_binary([F(Team) || Team <- Team_list]),
	{ok, pt:pack(30009, <<List_num:16,Bin_list/binary>>)};

%% SMSG_TEAM_CHAT_MEMBER                                   = 30011
%% String:名字
%% uint8:等级
%% uint8:佣兵ID
%% uint8:是否是队长（0-是，1-不是）
write(30011,{Id,Team})->
	if 
		Team#team.leader_id == Id ->
			Name = Team#team.leader_name,
			Level = Team#team.leader_level,
			Career = Team#team.leader_career,
			Is_lead = 0;
		Team#team.mate_id == Id->
			Name = Team#team.mate_name,
			Level = Team#team.mate_level,
			Career = Team#team.mate_career,
			Is_lead = 1
	end,
	
	Name_bin = pt:write_string(Name),
	{ok,pt:pack(30011,<<Name_bin/binary,Level:8,Career:8,Is_lead:8>>)}; 

%% 接受到聊天内容（30012）S->C
%% SMSG_TEAM_CHAT_GET                                      = 30012
%% String          发送者名字
%% String          聊天内容
write(30012,{Name,Content})->
	Name_bin = pt:write_string(Name),			
	Content_bin = pt:write_string(Content),
	{ok,pt:pack(30012,<<Name_bin/binary,Content_bin/binary>>)};

%% 请求掉落的物品（30013）C->S
%% CMSG_TEAM_CHAT_GOODS                                    = 30013
%% uint8:0
%% 返回掉落的物品(30013)S->C
%% SMSG_TEAM_CHAT_GOODS                                    = 30013
%% int16:捡到物品的人数
%% String：名字
%% int16:物品个数
%% (数组)
%%       int：物品ID
%%      int8：物品数量
write(30013,{Team})->
	Item_pick_info_list = Team#team.item_list,
	
	Lead_id = Team#team.leader_id,
	Mate_id = Team#team.mate_id,

	%%filter them into 2 lists, then make the binary.
	F_filter_owner = fun(Item_pick_info,Id)->
		if 
			Item_pick_info#item_pick_info.id == Id -> true;
			true-> false
		end
	end,

	F_filter_lead = fun(Item_pick_info)->
		F_filter_owner(Item_pick_info,Lead_id)
	end,

	F_filter_mate = fun(Item_pick_info)->
		F_filter_owner(Item_pick_info,Mate_id)
	end,

	Lead_pick = lists:filter(F_filter_lead,Item_pick_info_list ),
	Mate_pick = lists:filter(F_filter_mate,Item_pick_info_list ),
	
	Lead_bin = get_bin_from_list(Lead_pick),
	Mate_bin = get_bin_from_list(Mate_pick),

	Len = case {length(Lead_pick),length(Mate_pick)} of
		{0,0}-> 0;
		{0,_}-> 1;
		{_,0}-> 1;
		{_,_}-> 2
	end,
		
	{ok,pt:pack(30013,<<Len:16,Lead_bin/binary,Mate_bin/binary>>)};
		

write(proto_num,finish)->
	{ok,finish}.

get_bin_from_list(Pick_list)->
	if
		length(Pick_list) == 0 ->
			<<>>;
		true->
			[First_item|_] = Pick_list,
			?INFO(team,"get the name from the first item ~w",[First_item]),
			Id = First_item#item_pick_info.id,
			Info = mod_account:get_account_info_rec(Id),
			Name_bin = pt:write(Info#account.gd_RoleName),
			 
			F = fun(Item)->
				<<(Item#item_pick_info.item_id):32,(Item#item_pick_info.item_num):8>>
			end,	
			Item_bin = list_to_binary(lists:map(F, Pick_list)),
			<<Name_bin/binary,Item_bin/binary>>
	end. 
