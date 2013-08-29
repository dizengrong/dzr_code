%%------------------------------------
%%% @Module     : pt_14
%%% @Author     : cjr
%%% @Email      : chenjianrong@4399.com
%%% @Created    : 2011.09.05
%%% @Description: 信件协议处理
%%%		overall : 尽量调用mod模块，尽快释放read接口。
%%%------------------------------------
-module(pt_14).
%% -export([]).

%% -include("mail_record.hrl").
-include("common.hrl").
-export([read/2,write/2]).
%%
%%客户端 -> 服务端 ----------------------------
%%

%% get mail list
%% 邮件列表请求(14000)C->S
%% CMSG_COMMU_MAIL_LIST: = 14000;			//请求邮件
%% Uint8: 邮件显示类型（0 为全部，1为系统邮件，2为帮会邮件，3 为私人邮件，默认为全部）
%% Uint16: 开始取邮件序号

read(14000, Bin) ->
	case Bin of
        <<Type:8,Start_index:16>> ->
			{ok,{Type,Start_index}};
		_ ->
            {error, no_match}
    end;

%% 玩家查看邮件请求(14001)C->S
%% CMSG_COMMU_MAIL_CONTENT = 14001;		//查看邮件内容
%% Uint:邮件ID
read(14001,Bin)->
	?INFO(mail,"BIN:~w",[Bin]),
	case Bin of 
		<<MailID:32>> ->
			{ok,{MailID}};
		_->
			{error,no_match}
	end;

%% 发送邮件请求(14002)C-S
%% CMSG_COMMU_MAIL_SEND = 14002;				//请求发送邮件
%% 
%% uint8:信件类型2为帮会邮件，3 为私人邮件
%% string:接收者名字(不支持多人发送)
%% String:邮件标题
%% String:邮件内容
read(14002,Bin)->
	<<Type:8,Rest1/binary>> = Bin,
 	{Receiver, Rest2} = pt:read_string(Rest1),
 	{Title,Rest3} = pt:read_string(Rest2),
 	{Content,_} = pt:read_string(Rest3),
	
	{ok,{Type,Receiver,Title,Content}};

%% 
%% 删除邮件请求(14003)C->S
%% CMSG_COMMU_MAIL_DELETE = 14003;			//请求删除邮件
%% Array:可以删除一封，也可以删除多封
%% [Int:邮件ID, ….]
%% Uint8: 邮件显示类型（0 为全部，1为系统邮件，2为帮会邮件，3 为私人邮件，默认为全部）
%% Uint16: 开始取邮件序号
read(14003,Bin)->
    <<N:16, Bin2/binary>> = Bin,
    case get_list2([], Bin2, N) of
        error ->
            {error, no_match};
        {IdList, RestBin} ->
        	<<Type:8,Start_index:16>> = RestBin,
			{ok,{IdList,Type,Start_index}}
    end;

%% 获取附件(14005)C->S
%% CMSG_COMMU_MAIL_ATTACH = 14005;			//获取附件物品
%% Int:邮件ID
read(14005,Bin)->
	<<Mail_id:32,Code:32>> = Bin,
	{ok,{Mail_id,Code,0,0}};

%% 查询获取未读邮件数量(14006)C->S
%% CMSG_GET_UNREAD = 14006;			//返回获取未读邮件数量
%% Uint8: 0
read(14006,_Bin)->
	{ok,{}}.





%%
%%服务端 -> 客户端 ------------------------------------
%% Int8:返回结果(0为查询成功，1为查询失败)
%% Uint8:邮件显示类型     （0 为全部，1为系统邮件，2为帮会邮件，3为私人邮件）
%% Uint16:该类型的邮件总数 
%% Uint8: 返回列表包含邮件数 
%% Array:邮件的一些头信息
%% 	[uint:邮件ID
%% 	Int:发送人角色ID
%% 	string:发送人昵称
%% 	int8:邮件类型（0为系统邮件，1为玩家邮件，2为帮会邮件）
%% 	String:邮件标题
%% 	Int8:邮件状态（0为已读，1为未读）
%% 	Int8:附件的状态（0为已领取，1为未领取，2为无附件）
%% 	Int:邮件发送的时间
%% ]

write(14000, {Type,Total_mail_num,Return_mail_num,Mail_list}) ->
	case Return_mail_num of 
		0 ->
			BinList = <<>>;
		_ ->
			F = fun(#mail{mail_id=Id,
				  sender_name=SendName,
				  sender_id=SenderId,
				  mail_type=MailType,
				  mail_title=Title,
				  mail_status=Status,
				  attachment_status=AttachmentStatus,
				  timestamp=TimeStamp}) ->
					Len1 = byte_size(SendName),
					Len2 = byte_size(Title),
					<<Id:32, SenderId:32,Len1:16,SendName/binary,MailType:8,Len2:16,Title/binary, Status:8,AttachmentStatus:8,TimeStamp:32>>
			end,
			BinList = list_to_binary([F(Mail) || Mail <- Mail_list])
		end,
	%%case Return_mail_num of
		%%0 ->
			%%{ok, pt:pack(14000, <<0:8,Type:8, Total_mail_num:16, Return_mail_num:8, 0:16>>)};
		%%_ ->
	{ok, pt:pack(14000, <<0:8,Type:8, Total_mail_num:16, Return_mail_num:8, Return_mail_num:16,BinList/binary>>)};

	



%% 查看邮件返回结果(14001)S->C
%% SMSG_COMMU_MAIL_CONTENT = 14001;			//返回邮件内容】
%% Uint8:处理结果0成功，1失败
%% Uint:邮件ID
%% String:发送人昵称
%% Int:发送人角色ID
%% int8:邮件类型（0为系统邮件，1为玩家邮件，2为帮派邮件）
%% String:邮件标题
%% Int8:邮件状态（0为已读，1为未读 ）
%% Int:邮件发送的时间
%% Int8:附件的状态（0为已领取，1为未领取，2为无附件）
%% Int16:附件物品的ID号
%% int32:附件物品的数量
%% String:邮件内容
%% int32:附件金币数量
%% int 32:附件金券数量
%% int 32:附件银币数量

write(14001, {failure,_Reason}) ->
	%%?DEBUG("get mail error, reason ~w", [Reason]),
	{ok, pt:pack(14000, <<1:8>>)};


write(14001, Mail) ->
	#mail{mail_id=Id,
				  sender_name=Sender_name,
				  sender_id=Sender_id,
				  mail_type=Mail_type,
				  mail_title=Title,
				  mail_status=Status,
				  attachment_status=Attachment_status,
				  timestamp=TimeStamp,
				  goods_list = ItemList,
				  mail_content=Mail_content,
				  silver = Silver,
				  gold = Gold,
				  bind_gold = Bind_gold,
				  jungong = Jungong,
				  silver_status = Silver_status,
				  gold_status = Gold_status,
				  bind_gold_status = Bind_gold_status,
				  jungong_status = Jungong_status
} = Mail,
	?INFO(mail,"ItemList = ~w",[ItemList]),
	case erlang:length(ItemList) of
		ListNum when ListNum =< 0 ->
			ListBin = <<>>;
		ListNum ->
			F = fun({ID,IsCanTake,ItemID,Num}) ->
				<<ID:16,IsCanTake:8,ItemID:16,Num:32>>
			end,
			ListBin = list_to_binary(lists:map(F, ItemList))
	end,

	Len1 = byte_size(Sender_name),
	Len2 = byte_size(Title),
	Len3 = byte_size(Mail_content),
	{ok, pt:pack(14001, <<0:8,Id:32,Len1:16,Sender_name/binary,Sender_id:32,Mail_type:8,Len2:16,Title/binary,
			Status:8,TimeStamp:32,Attachment_status:8,ListNum:16, ListBin/binary,Len3:16,Mail_content/binary,
			Gold_status:8,Gold:32,Bind_gold_status:8,Bind_gold:32,Silver_status:8,Silver:32,
			Jungong_status:8,Jungong:32>>)};

%% 发送邮件返回结果(14002)S->C
%% SMSG_COMMU_MAIL_SEND = 14002;				//发送邮件返回
%% uint8:返回结果(0 发送成功，1 发送失败，2接收者不存在，3 无发送帮会邮件权限，4邮件头太长，5 邮件内容太长，

write(14002, 0) ->
	{ok, pt:pack(14002,<<0:8>>)};



write(14002, {failure,Reason}) ->
	%%?DEBUG("get mail error, reason ~w", [Reason]),
	case Reason of
		wrong_type ->
			{ok, pt:pack(14002, <<1:8>>)};
		no_guide_mail_permission ->
			{ok, pt:pack(14002,<<3:8>>)};
		_ ->
			{ok, pt:pack(14002, <<Reason:8>>)}
	end;



%% 删除邮件返回结果(14003)S->C
%% SMSG_COMMU_MAIL_DELETE = 14003;			//删除邮件返回结果
%% Int8:返回结果(0为删除成功，1为删除失败)
%% //返回新的邮件列表，按时间排序，（该协议也应参见14000）
%% Uint8:邮件显示类型     （0 为全部，1为系统邮件，2为帮会邮件，3为私人邮件）
%% Uint8:该类型的邮件总数 
%% Uint8: 返回列表包含邮件数 
%% Array:邮件的一些头信息
%% 	[uint:邮件ID
%% 	Int:发送人角色ID
%% 	string:发送人昵称
%% 	int8:邮件类型（0 为全部，1为系统邮件，2为帮会邮件，3为私人邮件）
%% 	String:邮件标题
%% 	Int8:邮件状态（0为已读，1为未读）
%% 	Int8:附件的状态（0为已领取，1为未领取，2为无附件）
%% 	Int:邮件发送的时间
%% ]

write(14003, {Type,Total_mail_num,Return_mail_num,Maillist}) ->
	F = fun(#mail{mail_id=Id,
				  sender_name=SendName,
				  sender_id=SenderId,
				  mail_type=MailType,
				  mail_title=Title,
				  mail_status=Status,
				  attachment_status=AttachmentStatus,
				  timestamp=TimeStamp}) ->
		
		Len1 = byte_size(SendName),
		Len2 = byte_size(Title),
		<<Id:32, SenderId:32,Len1:16,SendName/binary,MailType:8,Len2:16,Title/binary, Status:8,AttachmentStatus:8,TimeStamp:32>>
	end,
	MailNum = length(Maillist),
    BinList = list_to_binary([F(Mail) || Mail <- Maillist]),
    {ok, pt:pack(14003, <<0:8,Type:8, Total_mail_num:16, Return_mail_num:8, MailNum:16,BinList/binary>>)};
	
write(14003, 0)->
    {ok, pt:pack(14003, <<0:8>>)};

write(14003, 1)->
    {ok, pt:pack(14003, <<1:8>>)};


%% 收到邮件(14004)S->C
%% SMSG_COMMU_MAIL_RECV = 14004;					//接收到邮件信息
%% Uint8:未读邮件总数
write(14004,Num) ->
	{ok,pt:pack(14004,<<Num:8>>)};

%% 返回获取附件结果(14005)S->C
%% SMSG_COMMU_MAIL_ATTACH = 14005;			//返回获取附件结果
%% Int:邮件ID
%% uint8:领取结果（0为成功，1为失败）
write(14005,{Mail_id,Result}) ->
	{ok,pt:pack(14005,<<Mail_id:32,Result:8>>)};

%% 返回获取未读邮件数量(14006)C->S
%% SMSG_GET_UNREAD = 14006;			//返回获取未读邮件数量
%% INT16: 未读邮件封数
write(14006,{Mail_num}) ->
	{ok,pt:pack(14006,<<Mail_num:16>>)}.


%% 获取列表（读取信件id列表）
%% 列表每项为int32
get_list2(AccList, Bin, N) when N > 0 ->
    case Bin of
        <<Item:32, Bin2/binary>> ->
            NewList = [Item | AccList],
            get_list2(NewList, Bin2, N - 1);
        _ ->
            error
    end;
get_list2(AccList, Bin, _N) ->
    {AccList, Bin}.