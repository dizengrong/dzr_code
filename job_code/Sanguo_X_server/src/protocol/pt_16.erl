%% Author: dzr
%% Created: 2011-8-29
%% Description: TODO: pt_16 聊天协议
-module(pt_16).

%%
%% Include files
%%
%%
%% Exported Functions
%%
-export([read/2, write/2]).
-include("common.hrl").
%%客户端 -> 服务端 ----------------------------

%% 世界聊天
read(16000, BinContent) ->
	{Content, _} = pt:read_string(BinContent),
    {ok, Content};

read(16001, BinContent) ->
	{Content, _} = pt:read_string(BinContent),
	{ok, Content};

%% 私人聊天
read(16003, BinData) ->
	{ReceiverName, Rest} = pt:read_string(BinData),
	{Content, _} = pt:read_string(Rest),
	?INFO(chat,"Content:~w",[Content]),
    {ok, [ReceiverName, Content]};

%% 小喇叭
read(16004, BinData) ->
	{Content, _} = pt:read_string(BinData),
    {ok, Content};

%%购买小喇叭
read(16010, <<Num:32>>)->
	{ok, Num};

%% 送花请求(16008) C->S
%% CMSG_COMMU_SEND_FLOWER					=16008			//送花
%% Byte：		类型
%% Int:			数量
%% int:			收花人账号id
read(16008, BinData) ->
	<<Type:8,Num:32,Id:32>> = BinData,
    {ok, {Type,Num,Id}};

read(16009, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 场景聊天
read(16011, BinContent) ->
    {Content, _} = pt:read_string(BinContent),
    {ok, Content};

%% 公会聊天
read(16012, BinContent) ->
    {Content, _} = pt:read_string(BinContent),
    {ok, Content};

%% 场景聊天
read(16013, BinContent) ->
    {Content, _} = pt:read_string(BinContent),
    {ok, Content}.

%%服务端 -> 客户端 ------------------------------------

%% 世界聊天
write(16000, [PlayerId, NickName, Content, LineId, Sex, Vip, Rank]) ->
	BinName = pt:write_string(NickName),
	BinContent = pt:write_string(Content),
	Data = <<PlayerId:32,
			 BinName/binary,
			 BinContent/binary,
			 LineId:16,
			 Sex:8,
			 Vip:8,
			 Rank:8>>,
    {ok, pt:pack(16000, Data)};

%% 公会聊天
write(16001, [PlayerId, NickName, Content, LineId, Sex, Vip]) ->
	BinName = pt:write_string(NickName),
	BinContent = pt:write_string(Content),
	Data = <<PlayerId:32,
			 BinName/binary,
			 BinContent/binary,
			 LineId:16,
			 Sex:8,
			 Vip:8>>,
    {ok, pt:pack(16001, Data)};

%% 私人聊天
%% 私人聊天通知(16003) S->C
%% int32:         发起者的账号ID
%% string:        发起者的角色名
%% string:         聊天内容
%% int16：        线路ID
%% int16:          接收者的账号id
%% string:         接收者的角色名
%% int16:          发起者的角色ID
%% int16:          接收者的角色ID
%% int16:          发起者的等级
%% int16:          接收者的等级
%% String:          发起者的公会名字
%% String:          接收者的公会

write(16003, [SenderId, NickName, Content, LineId, 
			  ReceiverId, ReceiverName, SenderMainRoleId, ReceiverMainRoleId,
				Sender_level,Receive_level,Sender_guild_name,Receive_guild_name]) ->
	BinName = pt:write_string(NickName),
	BinContent = pt:write_string(Content),
	BinReceiverName = pt:write_string(ReceiverName),

	BinSender_guildname = pt:write_string(Sender_guild_name),
	BinReceive_guildname = pt:write_string(Receive_guild_name),
	
	Data = <<SenderId:32,
			 BinName/binary,
			 BinContent/binary,
			 LineId:16,
			 ReceiverId:32,
			 BinReceiverName/binary,
			 SenderMainRoleId:16,
			 ReceiverMainRoleId:16,
			 Sender_level:16,
			 Receive_level:16,
			 BinSender_guildname/binary,
			 BinReceive_guildname/binary>>,
    {ok, pt:pack(16003, Data)};

%% 小喇叭
	
write(16004, [PlayerId, PlayerRoleName,Content,Sex,VipLevel]) ->
    PlayerNameBean = pt:write_string(PlayerRoleName),
    ContentBean = pt:write_string(Content),
    Data = <<PlayerId:32,
             PlayerNameBean/binary,
             ContentBean/binary,
             Sex:8,
             VipLevel:8>>,
	{ok, pt:pack(16004, Data)};

%% 聊天异常
write(16005, ErrCode) ->
    {ok, pt:pack(16005, <<ErrCode:8>>)};

%% 系统广播
write(16006, [Level, Type, LineID, AccountID, NickName, Gender, Content]) ->
	BinName = pt:write_string(NickName),
	Data = <<Level:8,				%% 广播区间，等级段
			 Type:8,				%% 广播类型
			 LineID:16,				%% 线路ID
			 Gender:8,				%% 性别
			 AccountID:32,			%% 玩家ID
			 BinName/binary,		%% 玩家名字
			 Content/binary>>,		%% 内容
	{ok, pt:pack(16006, Data)};

%% 公告
write(16007, [Times, Type, Content]) ->
	BinContent = pt:write_string(Content),
	Payload = <<Times:8, Type:8, BinContent/binary>>,
	{ok, pt:pack(16007, Payload)};

%% 送花请求(16008) S->C
%% GMSG_COMMU_SEND_FLOWER					=16008			//送花
%% Byte：		类型
%% Int：		数量
%% int:			送花人账号id
%% string：    送花人名称
%% int：		收花人账号id
%% string：		收花人名称
write(16008, {Type,Num,Sender_id,Sender_name,Recv_id,Recv_name}) ->
	Sender_str = pt:write_string(Sender_name),
	Recv_str = pt:write_string(Recv_name),
	
	{ok, pt:pack(16008,<<Type:8,Num:32,Sender_id:32,Sender_str/binary,Recv_id:32,Recv_str/binary>>)};


write(16009, {PlayerId, MajorMerId}) ->
    {ok, pt:pack(16009, <<PlayerId:32, MajorMerId:16>>)};

%% 场景聊天
write(16011, [PlayerId, NickName, Content, LineId, Sex, Vip, Rank]) ->
    BinName = pt:write_string(NickName),
    BinContent = pt:write_string(Content),
    Data = <<PlayerId:32,
             BinName/binary,
             BinContent/binary,
             LineId:16,
             Sex:8,
             Vip:8,
             Rank:8>>,
    {ok, pt:pack(16011, Data)};

%% 公会聊天
write(16012, [PlayerId, NickName, Content, LineId, Sex, Vip, Rank]) ->
    BinName = pt:write_string(NickName),
    BinContent = pt:write_string(Content),
    Data = <<PlayerId:32,
             BinName/binary,
             BinContent/binary,
             LineId:16,
             Sex:8,
             Vip:8,
             Rank:8>>,
    {ok, pt:pack(16012, Data)};
%%
%% Local Functions
%%

%% 组队
write(16013, [PlayerId, NickName, Content, LineId, Sex, Vip, Rank]) ->
    BinName = pt:write_string(NickName),
    BinContent = pt:write_string(Content),
    Data = <<PlayerId:32,
             BinName/binary,
             BinContent/binary,
             LineId:16,
             Sex:8,
             Vip:8,
             Rank:8>>,
    {ok, pt:pack(16000, Data)}.
