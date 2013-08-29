%%------------------------------------
%%% @Module     : pt_18
%%% @Author     : cjr
%%% @Email      : chenjianrong@4399.com
%%% @Created    : 2011.09.15
%%% @Description: 好友通讯协议模块
%%%		overall : 尽量调用mod模块，尽快释放read接口。
%%%------------------------------------
-module(pt_18).

-export([read/2,write/2]).

-include("common.hrl").
%%
%%客户端 -> 服务端 ----------------------------
%%
%% 获取列表(18000) C->S
%% CMSG_COMMU_FRIEND_LIST				= 18000			//获取列表
%% byte:  		0好友1公会2黑名单
%% int16:		页数,页数是0返回全部
read(18000, Bin) ->
	<<Type:8,Num:16>> = Bin,
	{ok,{Type,Num}};

%% 添加好友请求(18001) C->S
%% CMSG_COMMU_ADD_FRIEND				= 18001			//添加好友请求
%% string：		玩家名字	
read(18001, Bin) ->
	{Name, _} = pt:read_string(Bin),
	{ok,Name};

%% 删除好友(18002) C->S
%% CMSG_COMMU_DEL_FRIEND				=18002			//删除好友
%% Uint32：		玩家id		
read(18002, Bin) ->
	case Bin of
        <<Uid:32>> ->
			{ok,Uid};
		_ ->
			?DEBUG(pt18,"can't match bin as ~w",[Bin]),
            {error, no_match}
    end;

%% 拖入黑名单(18003) C->S
%% CMSG_COMMU_ADD_BLACK					=18003				//拖入黑名单
%% uint32			被拖玩家ID
read(18003, Bin) ->
	case Bin of
        <<Uid:32>> ->
			{ok,Uid};
		_ ->
			?DEBUG(pt18,"can't match bin as ~w",[Bin]),
            {error, no_match}
    end;

%% 从黑名单中删除(18004) C->S
%% CMSG_COMMU_DEL_BLACK					=18004				//从黑名单中删除
%% Uint32：		玩家id	
read(18004, Bin) ->
	case Bin of
        <<Uid:32>> ->
			{ok,Uid};
		_ ->
			?DEBUG(pt18,"can't match bin as ~w",[Bin]),
            {error, no_match}
    end;


%% 玩家对好友申请的处理(18006) C->S
%% CMSG_COMMU_FRIEND_APPLY_HANDLE					=18006			
%% Uint32:		申请玩家id
%% Byte：		操作 0 通过 1拒绝
read(18006, Bin) ->
	case Bin of
        <<Uid:32,Oper:8>> ->
			{ok,{Uid,Oper}};
		_ ->
			?DEBUG(pt18,"can't match bin as ~w",[Bin]),
            {error, no_match}
    end;

%% 祝福好友(18008) C->S
%% CMSG_COMMU_FRIEND_BLESS							=18008			
%% uint32:		被祝福好友id
read(18008, Bin) ->
	case Bin of
        <<Uid:32>> ->
			{ok,Uid};
		_ ->
			?DEBUG(pt18,"can't match bin as ~w",[Bin]),
            {error, no_match}
    end;



%% 好友相关信息(18012) C->S
%% CMSG_FRIEND_LIST				=18012			//返回列表
%% Byte:	0
read(18012, _Bin) ->
	{ok,{}}.





%% 
%% 服务端 -> 客户端 ------------------------------------ 
%% 返回列表(18000) S->C
%% GMSG_COMMU_FRIEND_LIST                =18000    
%%     		 byte:        0好友1 公会2黑名单 3最近联系人
%%      	int16:        总好友数
%%      	int16:        当前页码
%%uint16:        玩家数        
%%      	uint32:         玩家id
%%     		 byte：    		头像id
%%         string：        玩家名字
%%          byte：       	 等级
%%          byte：        	性别 	0女	1男
%%          byte：        	是否在线 0在线 1离线
%%          uint16：        与该玩家的亲密度
%%          byte：        	是否可祝福            1可以，0不可以
%%          int:            最后一次在线时间

write(18000,{black_list,{Black_list,Total_black_num,Page}})->
	F = fun({Contact,Contact_dynamic_info})->
			{_,Id} = Contact#black_list.key,
			Career = Contact#black_list.career,
			Name = Contact#black_list.role_name,
			Sex = Contact#black_list.sex,
			Familiar = Contact#black_list.familiar,

			Level = Contact_dynamic_info#contact_dynamic_info.level,
			Offline= Contact_dynamic_info#contact_dynamic_info.online_status,
			Prayable = Contact_dynamic_info#contact_dynamic_info.prayable, 
			LastLogoutTime = Contact_dynamic_info#contact_dynamic_info.last_logout_time,

			Name_bin = pt:write_string(Name),
			%%Name_len = byte_size(Name),
			<<Id:32, 
              Career:8,
              Name_bin/binary,
              Level:8,
              Sex:8,
              Offline:8,
              Familiar:16,
              Prayable:8,
              LastLogoutTime:32>>	
	end,
	case Black_list of 
		[[]] ->
			Len2 = 0,
			{ok, pt:pack(18000, <<0:8,Len2:16>>)};
		_ ->
			BinList = list_to_binary([F(Black) || Black<-Black_list]),
			Len2 = length(Black_list),
			{ok, pt:pack(18000, <<2:8,Total_black_num:16,Page:16,Len2:16,BinList/binary>>)}
	end;

%% 返回列表(18000) S->C
%% GMSG_COMMU_FRIEND_LIST                =18000    
%%     		 byte:        0好友1 公会2黑名单 3最近联系人
%%      	int16:        总好友数
%%      	int16:        当前页码
%%uint16:        玩家数        
%%      	uint32:         玩家id
%%     		 byte：    		头像id
%%         string：        玩家名字
%%          byte：       	 等级
%%          byte：        	性别 	0女	1男
%%          byte：        	是否在线 0在线 1离线
%%          uint16：        与该玩家的亲密度
%%          byte：        	是否可祝福            1可以，0不可以
%%          int:            最后一次在线时间
write(18000,{Type,{Friend_list,Total_friend_num,Page}}) when (Type == friend orelse Type == recommend) ->
	Type_bit = if 
			Type == friend -> 0;
			Type == recommend -> 4
	end,

	F = fun({Contact,Contact_dynamic_info})->
			{_,Id} = Contact#friend.key,
			Career = Contact#friend.career,
			Name = Contact#friend.role_name,
			Sex = Contact#friend.sex,
			Familiar = Contact#friend.familiar,

			Level = Contact_dynamic_info#contact_dynamic_info.level,
			Offline= Contact_dynamic_info#contact_dynamic_info.online_status,
			Prayable = Contact_dynamic_info#contact_dynamic_info.prayable, 
			LastLogoutTime = Contact_dynamic_info#contact_dynamic_info.last_logout_time,

			Name_bin = pt:write_string(Name),
			%%Name_len = byte_size(Name),
			<<Id:32, 
              Career:8,
              Name_bin/binary,
              Level:8,
              Sex:8,
              Offline:8,
              Familiar:16,
              Prayable:8,
              LastLogoutTime:32>>	
	end,
	case Friend_list of 
		[[]] ->
			Len2 = 0,
			{ok, pt:pack(18000, <<Type_bit:8,Len2:16>>)};
		_ ->
			BinList = list_to_binary([F(Friend) || Friend<-Friend_list]),
			Len2 = length(Friend_list),
			{ok, pt:pack(18000, <<Type_bit:8,Total_friend_num:16,Page:16,Len2:16,BinList/binary>>)}
	end;

%% 添加名单（好友或黑名单）成功(18005) S->C
%% CMSG_COMMU_ADD_LIST_SUCCESS					=18005				//添加名单成功
%% Byte:		名单类型，0好友名单，1黑名单
%% Uint32：		玩家id
%% Uint16:		玩家等级
%% string:		玩家名字
%% int16：		头像id
%% byte：		性别 0女1男
%% byte：		是否在线 0在线 1离线
%% uint16：	与该玩家的亲密度
%% byte：		是否可祝福			1可以，0不可以

%%Contact有可能是friend结构或者black list结构
write(18005,{Contact,Contact_dynamic_info})->
	case is_record(Contact,friend) of
		true->
			Type = 0,
			{_,Id} = Contact#friend.key,
			Name = Contact#friend.role_name,
			Role_id = Contact#friend.career,
			Sex = Contact#friend.sex,
			Familiar = Contact#friend.familiar;
		false->
			%%should be blacklist, and no 3rd option
			Type = 1,
			{_,Id} = Contact#black_list.key,
			Name = Contact#black_list.role_name,
			Role_id = Contact#black_list.career,
			Sex = Contact#black_list.sex,
			Familiar = 0
	end,

	Level = Contact_dynamic_info#contact_dynamic_info.level,
	Online = Contact_dynamic_info#contact_dynamic_info.online_status,
	Prayable = Contact_dynamic_info#contact_dynamic_info.prayable,
		
	Name_bin = pt:write_string(Name),
	{ok, pt:pack(18005, <<Type:8,Id:32,Level:16,Name_bin/binary,
		Role_id:16,Sex:8,Online:8,Familiar:16,Prayable:8>>)};



%% Int：		申请玩家id
%% string		申请玩家名字
%% byte：		申请玩家等级	
%% byte：		申请玩家性别
write(18006,{ID,Name,Level,Sex,Career_id})->
	Name_bin = pt:write_string(Name),
	{ok, pt:pack(18006, <<ID:32,Name_bin/binary,Level:8,Sex:8,Career_id:16>>)};


%% 祝福好友通知(18008) S->C
%% GMSG_COMMU_FRIEND_BLESS                            =18008            
%%     Uint32：        玩家id
%%     string：        玩家名字
%%     byte：        祝福/被祝福        0祝福 1 被祝福
%%     byte：        玩家性别
%%     uint32：        获得经验
%%     uint32：        获得金钱
%%     uint16:        对方角色id
%%     uint8：      被祝福时是否已祝福对方    1未祝福 0已祝福



write(18008, {Id,Name,Pray_type,Sex,Exp,Money,Role_id,Prayable}) ->
	Name_bin = pt:write_string(Name),
	
	{ok, pt:pack(18008, <<Id:32,Name_bin/binary,Pray_type:8,Sex:8,Exp:32,Money:32,Role_id:16,Prayable:8>>)};


%% 赠送礼物通知(18009) S->C
%% GMSG_COMMU_FRIEND_GIFT						=18009			
%% uint32：		玩家id
%% String：		玩家名字
%% Byte：		赠送/被赠送       0赠送1被赠送
%% uint16：		礼物类型
%% uint16：		礼物数量
%% byte：		玩家性别
%% byte：		玩家vip等级
%% uint32：		获得经验
write(18009, {Id,Name,Pray_type,Gift_type,Gift_num,Sex,Vip,Exp}) ->
	Name_bin = pt:write_string(Name),
	
	{ok, pt:pack(18009, <<Id:32,Name_bin/binary,Pray_type:8,Gift_type:16,Gift_num:16,Sex:8,Vip:8,Exp:32>>)};



%% 祝福,送礼异常结果(18010) S->C
%% Uint32:		接收祝福,礼物玩家id
%% Byte:		异常代码
%% 0	不在线
%% 1	被祝福次数已满
%% 2	祝福次数已满
%% 3	其它
write(18010, {Id,Result}) ->
	{ok, pt:pack(18010, <<Id:32,Result:8>>)};


%% 好友异常返回(18011) S->C
%% GMSG_COMMU_ERROR_CODE						=18011			
%% Byte:		操作码
%% 0	添加好友
%% 1	拉黑名单
%% 2	删除好友
%% byte：		错误码	
%% 0对象不存在
%% 1对象不在线
%% 2添加自己
%% 3对象已经是好友
%% 4黑名单人数满
%% 5其它
write(18011,{Opcode,Result})->
	{ok, pt:pack(18011, <<Opcode:8,Result:8>>)};



%% 返回列表(18012) S->C
%% SMSG_FRIEND_LIST				=18012			//返回列表
%% byte:		圣痕等级
%% uint16:		人气
%% byte:		已送祝福
%% byte:		本日可送祝福
%% byte:		已收祝福
%% byte:		本日可收祝福
write(18012,{Self_level,Popular,Can_send,Send,Can_recv,Recv})->
{ok, pt:pack(18012, <<Self_level:8,Popular:16,Can_send:8,Send:8,Can_recv:8,Recv:8>>)};


write(finish,finish) ->
	{ok,ok}.
	
