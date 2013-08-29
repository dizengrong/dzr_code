-module(mod_mail).
-behaviour(gen_server).
-export([init/1,handle_info/2,handle_cast/2, handle_call/3,terminate/2, code_change/3]).
-export([start_link/0, stop/0, send_sys_mail/9, send_priv_mail/4,delete_mail_list/4,get_mail/2,send_guide_mail/3,get_mail_list/4,get_attachment/5,
		notify_new_mail/1,notify_new_mail_local/2,get_unread_mail_num/1]).
-export([check_mail/3,get_mail_list_do/3,check_mail_time/1,send_mail_to_one/13]).

-include("common.hrl").
%% -include("player_record.hrl").
%% -include("mail_record.hrl").


-define(MAIL_PER_PAGE,6).
-define(MAIL_MAX_TIME,60*60*24*7).


-define(MAX_NUM, 100).              %% 每个用户信件数量上限
-define(MAX_TITLE_LENGTH,45).		%% Max Title length is 15 Chinese characters
-define(MAX_CONTENT_LENGTH,1500).	%% Max Content length is 500 Chinese characters
-define(MAX_NAME_LENGTH,21).		%% Max user name length,7个字符



%%------------------------------------------------
%%   接口函数
%%------------------------------------------------


%%启动服务
start_link() ->
	gen_server:start_link({local,?MODULE},?MODULE, [], []).


%%发送私人邮件：收件人名字，标题，内容，发送者状态
send_priv_mail(Name,Title,Content,PlayerId) ->
	gen_server:cast(?MODULE,{'send_priv_mail',[Name,Title,Content,PlayerId]}).

%%发送系统邮件：收件人名字列表，标题，内容，物品金币信息
%% 例如mod_mail:send_sys_mail(["20121017"],"Title","message,hello,how are you",[{289,3},{198,1}],100,999,100000,10,1).
send_sys_mail(NameList,Title,Content,GoodsList,Gold,Bind_gold,Silver,Jungong,GoodsBind) ->
	?INFO(mail,"Name ~w, Title ~w, Content ~w, GoodsList ~w",[NameList, Title, Content, GoodsList]),
	[gen_server:cast(?MODULE,{'send_sys_mail',[Name,Title,Content,GoodsList,Gold,Bind_gold,Silver,Jungong,GoodsBind]})|| Name <- NameList]. %%对NameList中的用户逐个发送系统邮件

%%公会邮件，未完成
send_guide_mail(Title,Content,PlayerId) ->
	gen_server:cast(?MODULE,{'send_guide_mail',[Title,Content,PlayerId]}).

%%取得邮件列表
get_mail_list(Type,StartIndex,Ops_code,PlayerId) ->
	gen_server:cast(?MODULE,{'get_mail_list',[Type,StartIndex,Ops_code,PlayerId]}).

%%读取邮件
get_mail(MailId,PlayerId) ->
	gen_server:cast(?MODULE,{'get_mail',[MailId,PlayerId]}).

%%删除邮件
delete_mail_list(IdList,Type,StartIndex,PlayerId) ->
	gen_server:cast(?MODULE,{'delete_mail_list',[IdList,Type,StartIndex,PlayerId]}).

%%取得附件 mod_mail:get_attachment(80,1,0,0,6000398)
get_attachment(Mail_id,Code,Good_id,Good_num,PlayerId) ->
	gen_server:cast(?MODULE,{'get_attachment',[Mail_id,Code,Good_id,Good_num,PlayerId]}).

%%取得未读邮件的数量
get_unread_mail_num(PlayerId) ->
	gen_server:cast(?MODULE,{'get_unread_mail_num',[PlayerId]}).

%%---------------------------------------------
%%   回调函数
%%---------------------------------------------

init([]) ->
    process_flag(trap_exit, true),
    {ok, []}.


handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({'send_priv_mail',[Name,Title,Content,PlayerId]}, State) ->
	case send_single_mail(Name,Title,Content,3,PlayerId) of   %%写入数据库
		{ok,Name} ->
			{ok,BinData} = pt_14:write(14002,0), %%发送成功的消息
			lib_send:send(PlayerId,BinData),
			notify_new_mail(Name);  %%通知收件人
		{error,Errcode} ->
			mod_err:send_err(PlayerId,14,Errcode),
			?INFO(mail,"Mod:14,Errcode is ~w",[Errcode])
	end,
	{noreply,State};

handle_cast({'send_sys_mail',[Name,Title,Content,GoodsList,Gold,Bind_gold,Silver,Jungong,GoodsBind]},State) ->
	Timestamp = util:unixtime(),
    case check_mail(Name, Title, Content) of
        {error, Errcode} ->
			?INFO(mail,"Mod:14,Errcode is ~w",[Errcode]);
        {ok, Name} ->
			FilteredTitle = lib_word_filter:filter_prohibited_words(Title),
			?DEBUG(mail, "Filtered title: ~w, original title: ~w", [FilteredTitle, Title]),
			FilteredContent = lib_word_filter:filter_prohibited_words(Content),
			?DEBUG(mail, "Filtered content: ~w, original content: ~w", [FilteredContent, Content]),
            case send_mail_to_one(1, Timestamp, 0,"系统", Name, FilteredTitle, FilteredContent, GoodsList,Gold,Bind_gold,Silver,Jungong,GoodsBind) of
				ok -> %% 发送成功
                    notify_new_mail(Name),
                    ok;
                {error, Errcode} ->
                	?DEBUG(mail,"Somewthing wrong during send sys mail, Name ~w, Title~w, Content ~w, GoodsList ~w Reason~w",
					[Name, Title, Content, GoodsList, Errcode]),
					?INFO(mail,"Mod:14,Errcode is ~w",[Errcode])
            end
    end,
	{noreply,State};

%%handle_cast({'send_guide_mail',[Title,Content,PlayerId]},State) ->        %%需要mod_guide模块取得特定用户
%%	PlayerStatus = mod_player:get_player_status(PlayerId),
%%	{noreply,State};
	

handle_cast({'get_mail_list',[Type,StartIndex,Ops_code,PlayerId]},State) ->
	{Total_mail_num,Return_Mail_num,Mail_list} = get_mail_list_do(PlayerId,StartIndex,Type),
	case Ops_code of
		14000 ->
		{ok,Bin} = pt_14:write(14000,{Type,Total_mail_num,Return_Mail_num,Mail_list});
		14003 ->
		{ok,Bin} = pt_14:write(14003,{Type,Total_mail_num,Return_Mail_num,Mail_list})
	end,
	lib_send:send(PlayerId,Bin),
	{noreply,State};

handle_cast({'get_mail',[MailId,PlayerId]},State) ->
	case get_mail_do(MailId,PlayerId) of
	{ok,Mail} -> 
		{ok,Bin} = pt_14:write(14001,Mail);
	_Other ->
		{ok,Bin} = pt_14:write(14001,{failure,unknow_reason})
	end,
	?INFO(mail,"mail bin is ~w",[Bin]),
	lib_send:send(PlayerId,Bin),
	{noreply,State};

handle_cast({'delete_mail_list',[IdList,Type,StartIndex,PlayerId]},State) ->
	case del_mail(IdList,PlayerId) of
		ok -> 
			get_mail_list(Type,StartIndex,14003,PlayerId),
			get_unread_mail_num(PlayerId);
		error ->
			{ok,Bin} = pt_14:write(14003,1),
			lib_send:send(PlayerId,Bin)
	end,
	{noreply,State};


handle_cast({'get_unread_mail_num',[PlayerId]},State) ->
	Count_sql = io_lib:format("select Count(1) from `GD_MailBox` where gd_RecAccountID = ~w and gd_ReciveStatus = 1 ",
			[PlayerId]),
	Num = db_sql:get_one(Count_sql),
	?INFO(mail,"$$$$$$$$$$$$$$$$$$$$$$$ Num = ~w",[Num]),
	{ok,Bin} = pt_14:write(14006,{Num}),
	lib_send:send(PlayerId,Bin),
	{noreply,State};


handle_cast({'get_attachment',[Mail_id,Code,_Good_id,_Good_num,PlayerId]},State) ->
	%%currently we didn't use good info directly but from mail.

	case get_mail_do(Mail_id,PlayerId) of
		{ok,Mail} ->
			case Mail#mail.attachment_status of
				1 ->
					case Code of
						0 ->
							GoodsNum = check_goodslist_num(Mail#mail.goods_list),
							case GoodsNum =:= 0 of
								true ->
									mod_economy:add_bind_gold(PlayerId,Mail#mail.bind_gold,?GOLD_FROM_MAIL),
									mod_economy:add_gold(PlayerId,Mail#mail.gold,?GOLD_FROM_MAIL),
									mod_economy:add_silver(PlayerId,Mail#mail.silver,?SILVER_FROM_MAIL),
									mod_economy:add_popularity(PlayerId,Mail#mail.jungong,?SILVER_FROM_MAIL),
									?INFO(mail,"get ~w bind gold, ~w gold, ~w silver from mail",[Mail#mail.bind_gold,Mail#mail.gold,Mail#mail.silver]),
									NewMail = Mail#mail{silver_status = 0,gold_status = 0,bind_gold_status = 0,jungong_status = 0},
									attach_taken(Mail_id,NewMail,Code,PlayerId),
									{ok,Bin} = pt_14:write(14005,{Mail_id,0});
								false ->
									case mod_items:getBagNullNum(PlayerId) > GoodsNum of
										false -> 
											mod_err:send_err(PlayerId,14,?ERR_ITEM_BAG_NOT_ENOUGH),
											?INFO(mail,"Mod:14,Errcode is ~w",[?ERR_ITEM_BAG_NOT_ENOUGH]),
											{ok,Bin} = pt_14:write(14005,{Mail_id,1});
										true ->
											Fun = fun({_ID,IsCanTake,ItemID,Num},ItemList) ->
												case IsCanTake =:= 1 of
													true ->
														ItemList++[{ItemID,Num,1}];
													false ->
														ItemList
												end
											end,
											ItemList = lists:foldl(Fun,[],Mail#mail.goods_list),
											case mod_items:createItems(PlayerId, ItemList, ?ITEM_FROM_MAIL) of
												%%0 as successs
												ok->
												mod_economy:add_bind_gold(PlayerId,Mail#mail.bind_gold,?GOLD_FROM_MAIL),
												mod_economy:add_gold(PlayerId,Mail#mail.gold,?GOLD_FROM_MAIL),
												mod_economy:add_silver(PlayerId,Mail#mail.silver,?SILVER_FROM_MAIL),
													?INFO(mail,"get ~w bind gold, ~w gold, ~w silver from mail",[Mail#mail.bind_gold,Mail#mail.gold,Mail#mail.silver]),
													NewGoodsList = goodsListModify(Mail#mail.goods_list,Code),
													NewMail = Mail#mail{silver_status = 0,gold_status = 0,bind_gold_status = 0,goods_list = NewGoodsList},					
													attach_taken(Mail_id,NewMail,Code,PlayerId),
													{ok,Bin} = pt_14:write(14005,{Mail_id,0});
												Fail ->
													?DEBUG(mail,"fail to get item, reason ~w",[Fail]),
													{ok,Bin} = pt_14:write(14005,{Mail_id,1})
											end
									end
							end;
						1 ->
							case Mail#mail.gold > 0 andalso Mail#mail.gold_status =:= 1 of
								true ->
									mod_economy:add_gold(PlayerId,Mail#mail.gold,?GOLD_FROM_MAIL),
									NewMail = Mail#mail{gold_status = 0},
									attach_taken(Mail_id,NewMail,Code,PlayerId),
									{ok,Bin} = pt_14:write(14005,{Mail_id,0});
								false ->
									mod_err:send_err(PlayerId,14,?ERR_MAIL_ITEM_HAVE_TAKE),
									?INFO(mail,"Mod:14,Errcode is ~w",[?ERR_MAIL_ITEM_HAVE_TAKE]),
									{ok,Bin} = pt_14:write(14005,{Mail_id,1})
							end;
						2 ->
							case Mail#mail.bind_gold > 0 andalso Mail#mail.bind_gold_status =:= 1 of
								true ->
									mod_economy:add_bind_gold(PlayerId,Mail#mail.bind_gold,?GOLD_FROM_MAIL),
									NewMail = Mail#mail{bind_gold_status = 0},
									attach_taken(Mail_id,NewMail,Code,PlayerId),
									{ok,Bin} = pt_14:write(14005,{Mail_id,0});
								false ->
									mod_err:send_err(PlayerId,14,?ERR_MAIL_ITEM_HAVE_TAKE),
									?INFO(mail,"Mod:14,Errcode is ~w",[?ERR_MAIL_ITEM_HAVE_TAKE]),
									{ok,Bin} = pt_14:write(14005,{Mail_id,1})
							end;
						3 ->
							case Mail#mail.silver > 0 andalso Mail#mail.silver_status =:= 1 of
								true ->
									mod_economy:add_silver(PlayerId,Mail#mail.silver,?SILVER_FROM_MAIL),
									NewMail = Mail#mail{silver_status = 0},
									attach_taken(Mail_id,NewMail,Code,PlayerId),
									{ok,Bin} = pt_14:write(14005,{Mail_id,0});
								false ->
									mod_err:send_err(PlayerId,14,?ERR_MAIL_ITEM_HAVE_TAKE),
									?INFO(mail,"Mod:14,Errcode is ~w",[?ERR_MAIL_ITEM_HAVE_TAKE]),
									{ok,Bin} = pt_14:write(14005,{Mail_id,1})
							end;
						4 ->
							case Mail#mail.jungong > 0 andalso Mail#mail.jungong_status =:= 1 of
								true ->
									mod_economy:add_popularity(PlayerId,Mail#mail.jungong,?POPULARITY_FROM_MAIL),
									NewMail = Mail#mail{jungong_status = 0},
									attach_taken(Mail_id,NewMail,Code,PlayerId),
									{ok,Bin} = pt_14:write(14005,{Mail_id,0});
								false ->
									mod_err:send_err(PlayerId,14,?ERR_MAIL_ITEM_HAVE_TAKE),
									?INFO(mail,"Mod:14,Errcode is ~w",[?ERR_MAIL_ITEM_HAVE_TAKE]),
									{ok,Bin} = pt_14:write(14005,{Mail_id,1})
							end;
						_Else ->
							case lists:keyfine(Code,1,Mail#mail.goods_list) of
								false ->
									mod_err:send_err(PlayerId,14,?ERR_MAIL_ITEM_NOT_EXIT),
									?INFO(mail,"Mod:14,Errcode is ~w",[?ERR_MAIL_ITEM_NOT_EXIT]),
									{ok,Bin} = pt_14:write(14005,{Mail_id,1});
								{_ID,IsCanTake,ItemID,Num} ->
									case IsCanTake =:= 1 of
										true ->
											case mod_items:getBagNullNum(PlayerId) > 0 of
												false -> 
													mod_err:send_err(PlayerId,14,?ERR_ITEM_BAG_NOT_ENOUGH),
													?INFO(mail,"Mod:14,Errcode is ~w",[?ERR_ITEM_BAG_NOT_ENOUGH]),
													{ok,Bin} = pt_14:write(14005,{Mail_id,1});
												true ->
													mod_items:createItems(PlayerId, [{ItemID,Num,1}], ?ITEM_FROM_MAIL),
													NewGoodsList = goodsListModify(Mail#mail.goods_list,Code),
													NewMail = Mail#mail{silver_status = 0,gold_status = 0,bind_gold_status = 0,goods_list = NewGoodsList},					
													attach_taken(Mail_id,NewMail,Code,PlayerId),
													{ok,Bin} = pt_14:write(14005,{Mail_id,0})
											end
									end
							end
					end;
				_->
					?INFO(mail,"no attachment can be taken, mail is ~w",[Mail]),
					{ok,Bin} = pt_14:write(14005,{Mail_id,1})
			end;
		_ ->
			{ok,Bin} = pt_14:write(14005,{Mail_id,0})
	end,
	lib_send:send(PlayerId, Bin),
	{noreply,State};

handle_cast({'clean_mail'}, State) ->
    check_mail_time(),
    {noreplay, State};

handle_cast(_Msg, State) ->
	%%?DEBUG("cast got unknown msg ~w",[Msg]),
    {noreply, State}.

handle_info({'EXIT', _, Reason}, State) ->
    ?INFO(terminate,"exit:~w", [Reason]),
    {stop, Reason, State};

handle_info(_Info, State) ->
	%%?DEBUG("cast got unknown info ~w",[Info]),
    {noreply, State}.

terminate(Reason, _State) ->
	?INFO(mail,"exit because ~w",[Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

notify_new_mail(Name)->
	% Name = erlang:list_to_atom(Name1),
	case mod_account:get_account_id_by_rolename(Name) of
		{true,Id} ->
			?INFO(mail,"HAVE A Look!Name = ~w",[Name]),
			notify_new_mail_local(Name,Id);
		false ->
			?INFO(mail,"user ~s not found",[Name])
		end.
	

notify_new_mail_local(_Name,Id)->
	{ok, Bin1} = pt_14:write(14004, 1),
	lib_send:send(Id, Bin1),

	case mod_player:is_online(Id) of
		{true,_Ps}->
			get_unread_mail_num(Id);
		false->
			?ERR(mail,"it's not bug, but a little abnormal, check whether it can heppen")
	end.

stop() ->
    gen_server:call(?MODULE, stop).

%%///////////////////////////////////////////////////////////////
%%      实现函数
%%///////////////////////////////////////////////////////////////



check_content(Content) ->
    check_length(Content, ?MAX_CONTENT_LENGTH).

check_length(Item, LenLimit) ->
	?INFO(mail,"Item ~w, len limit ~w",[Item, LenLimit]),
    case asn1rt:utf8_binary_to_list(list_to_binary(Item)) of
        {ok, UnicodeList} ->
            Len = string_width(UnicodeList),   
            Len =< LenLimit andalso Len >= 1;
        {error, _Reason} ->
            error
    end.

check_mail(Name, Title, Content) ->
    case check_title(Title) of  %% 检查标题合法性
        true ->
            case check_content(Content) of  %% 检查内容合法性
                true ->
                    F = fun(Item) ->
                            case is_binary(Item) of
                                true ->     %% 二进制数据转换为字符串
                                    binary_to_list(Item);
                                false ->    %% 无须转换
                                    Item
                            end
                    end,
                    NewName = F(Name),
                    
                    case check_name(NewName) of
                            true ->
                                {ok, NewName};
                            false ->
                                {error, ?ERR_MAIL_WRONG_NAME}
                    end;
                false ->
                    {error, ?ERR_MAIL_WRONG_CONTENT};       %% 内容长度非法
                error ->
                    {error, ?ERR_MAIL_WRONG_CONTENT}
            end;
        false ->
            {error, ?ERR_MAIL_WRONG_TITLE};     %% title长度非法
        error ->
            {error, ?ERR_MAIL_WRONG_TITLE}
    end.

check_mail_time() ->
    Sql = "select id from mail",    %% 获得所有信件的id
    case db_sql:execute(Sql) of
        {ok, []} ->
            ok;
        error ->
            %%?ERR("*******Execute ~w:~w/0 error!*******", [?MODULE, check_mail_time]);
			error;		
        {ok, ItemList} ->
            lists:foreach(fun(Item) -> [Id] = Item, check_mail_time(Id) end, ItemList)
    end.

check_mail_time(Id) ->
	CurrTimestamp = util:unixtime(),
	Cut_time = CurrTimestamp - ?MAIL_MAX_TIME,
    SqlGetMail = io_lib:format(<<"select gd_MailID from gd_mailbox where gd_AccountID = ~w and gd_MailSendTime<~w">>, [Id,Cut_time]),
    case db_sql:execute(SqlGetMail) of
        {ok, []} ->
            ok;
        error ->
            ok;
        {ok, [Mail]} ->
            [timely_del_one_mail(Mail_id) || Mail_id<-Mail]
        end.

check_name(Name) ->
    case check_length(Name, ?MAX_NAME_LENGTH) of
        true ->
            %%lib_player:is_exists(Name);     %% 存在true，不存在false
			true;
		
        _Other ->       %% false与error
            false
    end.

check_title(Title) ->
    check_length(Title, ?MAX_TITLE_LENGTH).

send_single_mail(Name, Title, Content,Type,PlayerId) ->
	AccountInfo = mod_account:get_account_info_rec(PlayerId),
    Timestamp = util:unixtime(),
	case check_mail(Name, Title, Content) of
		{error, Errcode} ->
			{error, Errcode};
		{ok, RName} ->

%% 新需求，这时候不用替代词发送，而是返回有敏感词，不允许发送			
%% 			FilteredTitle = lib_word_filter:filter_prohibited_words(Title),
%% 			?INFO(mail, "Filtered title: ~w, original title: ~w", [FilteredTitle, Title]),
%% 			FilteredContent = lib_word_filter:filter_prohibited_words(Content),
%% 			?INFO(mail, "Filtered content: ~w, original content: ~w", [FilteredContent, Content]),
			case {lib_word_filter:find_prohibited_words(Content),
					lib_word_filter:find_prohibited_words(Title)} of
			{not_found,not_found}->
				GoodsList = [],
				case send_mail_to_one(Type, Timestamp, PlayerId,AccountInfo#account.gd_RoleName, 
					RName,Title, Content,GoodsList,0,0,0,0,0) of
					ok ->
						{ok, RName};
					{error, Errcode} ->
						{error, Errcode}
				end;
			_->
				?INFO(mail,"filtered because sensitive words"),
				%%mod_err:send_err_by_id(PlayerId, ?ERR_PROHIBIT_WORD),
				{error, ?ERR_PROHIBIT_WORD}
			end
	end.

send_mail_to_one(Type, Timestamp, SId,SName, RName, Title, Content, GoodsList,Gold,Bind_gold,Silver,Jungong,GoodsBind) ->
	Fun = fun({ItemID,Num},Sum) ->
		{{Sum,1,ItemID,Num},Sum+1}
	end,
	{GoodsList1,_Sum} = lists:mapfoldl(Fun,30,GoodsList),
	?INFO(mail,"GoodsList = ~w",[GoodsList1]),
	EscapedRName = db_sql:sql_str_escape(RName, ""),
	Sql = io_lib:format(<<"select gd_AccountID from `GD_Account` where gd_RoleName = '~s' limit 1">>, [EscapedRName]),
	?INFO(mail, "sql is ~s",[Sql]),
	case db_sql:execute(Sql) of
        {ok, []} ->
			?INFO(mail,"no result"),
            {error, ?ERR_MAIL_WRONG_NAME};
        {ok, [[RId]]} ->
			insert_mail(Type, Timestamp, SId,SName, RId, RName, Title, Content, GoodsList1,Gold,Bind_gold,Silver,Jungong,GoodsBind);
%%             case GoodsId of
%%                 0 ->        %% no goods attached
%%                     insert_mail(Type, Timestamp, SId,SName, RId, RName, Title, Content, GoodsId, GoodsNum);
%%                 _ ->        %% 物品 
%% 					insert_mail(Type, Timestamp, SId,SName, RId, RName, Title, Content, GoodsId, GoodsNum)
%%             end;
        _ ->
            {error, ?ERR_MAIL_SEARCH_SQL_ERROR}
    end.


insert_mail(Type, Timestamp, SId, SName, RId,RName, Title, Content, GoodsList,Gold,Bind_gold,Silver,Jungong,GoodsBind) ->
	case (length(GoodsList) > 0) orelse (Gold>0) orelse (Bind_gold>0) orelse (Silver>0) of
		  true ->
			  Attachment_status = 1;
		  false ->
			  Attachment_status = 2
	end,
	GoodsList1 = io_lib:format("~w",[GoodsList]),
	case Gold > 0 of 
		true ->
			Gold_status = 1;
		false ->
			Gold_status = 0
	end,
	case Bind_gold > 0 of
		true ->
			Bind_gold_status = 1;
		false ->
			Bind_gold_status = 0
	end,
	case Silver > 0 of
		true ->
			Silver_status = 1;
		false ->
			Silver_status = 0
	end,
	case Jungong > 0 of
		true ->
			Jungong_status = 1;
		false ->
			Jungong_status = 0
	end,
    Sql = db_sql:make_insert_sql('GD_MailBox', 
		["gd_AccountID","gd_RoleName","gd_RecAccountID","gd_RecRoleName",
		 	"gd_MailTitle","gd_MailContent","gd_MailType","gd_Attachment",
		 		"gd_AttachmentState","gd_SendStatus","gd_ReciveStatus","gd_MailSendTime","gd_mail_gold_status",
					"gd_mail_gold","gd_mail_bind_gold_status","gd_mail_bind_gold",
					"gd_mail_bind_silver_status","gd_mail_bind_silver",
					"gd_mail_jungong_status","gd_mail_jungong","gd_Attachment_isbind"],
		[SId,SName,RId,RName,
		 	Title,Content,Type,GoodsList1,
		 		Attachment_status,0,1,Timestamp,Gold_status,
					Gold,Bind_gold_status,Bind_gold,Silver_status,Silver,Jungong_status,Jungong,GoodsBind]),
	?INFO(mail,"insert_mail,GoodsList = ~w",[GoodsList]),
								 
    case db_sql:execute(Sql) of
        {ok, _} ->
            ok;
        error ->
            {error, ?ERR_MAIL_SEARCH_SQL_ERROR}
    end.

get_mail_do(MailId,PlayerId) ->
	SqlGetMail = io_lib:format(<<"select gd_MailID,gd_AccountID,gd_RoleName,gd_MailTitle,"
								"gd_MailContent,gd_MailType,gd_Attachment,"
								"gd_AttachmentState,gd_ReciveStatus,gd_MailSendTime,gd_mail_gold_status,"
								"gd_mail_gold,gd_mail_bind_gold_status,gd_mail_bind_gold,gd_mail_bind_silver_status,gd_mail_bind_silver,"
								"gd_mail_jungong_status,gd_mail_jungong,gd_Attachment_isbind "
								"from `GD_MailBox` where gd_MailID = '~w' and gd_RecAccountID = '~w'  limit 1">>, 
								[MailId,PlayerId]),
	
	case db_sql:execute(SqlGetMail) of
		{ok,[Result]} ->
			?INFO(mail,"Result is ~w",[Result]),
			%%todo, actually we don't need all fields
			[Mail_id, Sender_id, Sender_name,Title,
				Content,Type,GoodsList,
				Attachment_status,_Status,Timestamp,
				Gold_status,Gold,Bind_gold_status,Bind_gold,Silver_status,Silver,Jungong_status,Jungong,Goods_isbind] = Result,
			%% set the mail_status to 0
			SqlReadMail = io_lib:format("update `GD_MailBox` set gd_ReciveStatus=0 where gd_MailID='~w'",[MailId]),
			db_sql:execute(SqlReadMail),
			
			{ok,#mail{
				mail_id = Mail_id,
				sender_name = Sender_name,
				sender_id = Sender_id,
				mail_type = Type ,
				mail_title = Title,
				mail_status = 0,
				timestamp = Timestamp,
				attachment_status = Attachment_status,
				goods_list = util:bitstring_to_term(GoodsList),
				mail_content = Content,
				gold_status = Gold_status,
				gold = Gold,
				bind_gold_status = Bind_gold_status,
				bind_gold = Bind_gold,
				silver_status = Silver_status,
				silver = Silver,
				jungong_status = Jungong_status,
				jungong = Jungong,
				goods_isbind = Goods_isbind}};
		_ ->
			error
	end.


string_width(String) ->
    string_width(String, 0).
string_width([], Len) ->
    Len;
string_width([H | T], Len) ->
    case H > 255 of
        true ->
            string_width(T, Len + 2);
        false ->
            string_width(T, Len + 1)
    end.

del_mail(IdList, PlayerId) when is_list(IdList) ->    %% 根据客户端发送的信件id列表删除信件
    lists:foreach(fun(Id) -> del_one_mail(Id,PlayerId) end, IdList);
del_mail(_, _) ->
    error.

del_one_mail(Id,PlayerId) ->
	Sql = io_lib:format(<<"delete from GD_MailBox where gd_MailID = ~w and gd_RecAccountID = ~w ">>, [Id,PlayerId]),
	db_sql:execute(Sql).

timely_del_one_mail(Id)->
	Sql = io_lib:format(<<"delete from GD_MailBox where gd_MailID = ~w ">>, [Id]),
    db_sql:execute(Sql).

get_mail_list_do(PlayerId,StartIndex,Type) ->
	%%Columns = " `gd_AccountID`,`gd_RoleName`,`gd_RecAccountID`,`gd_MailType`,`gd_MailTitle`,`gd_ReciveStatus`,`gd_AttachmentState`,'gd_MailSendTime' ",
	case Type of 
		0 ->
			Count_sql = io_lib:format(<<"select Count(*) from `GD_MailBox` where gd_RecAccountID = ~w ">>, [PlayerId]),
		    %%Mail_list_sql = io_lib:format(<<"select ~w from `GD_MailBox` where gd_RecAccountID = ~w limit ~w,~w">>, [Columns,PlayerId,StartIndex,?MAIL_PER_PAGE]);
			Mail_list_sql = io_lib:format(<<"select gd_MailID,gd_RoleName,gd_RecAccountID,gd_MailType,gd_MailTitle,gd_ReciveStatus,gd_AttachmentState,gd_MailSendTime from `GD_MailBox` where gd_RecAccountID = ~w ORDER BY gd_mailsendtime desc limit ~w,~w">>, [PlayerId,StartIndex,?MAIL_PER_PAGE]);
		_ ->
			Count_sql = io_lib:format(<<"select Count(*) from `GD_MailBox` where gd_MailType = ~w and gd_RecAccountID = ~w ">>, [Type,PlayerId]),
		    %%Mail_list_sql = io_lib:format(<<"select ~w from `GD_MailBox` where gd_MailType = ~w and gd_RecAccountID = ~w limit ~w,~w">>, [Columns,Type,PlayerId,StartIndex,?MAIL_PER_PAGE])
			Mail_list_sql = io_lib:format(<<"select gd_MailID,gd_RoleName,gd_RecAccountID,gd_MailType,gd_MailTitle,gd_ReciveStatus,gd_AttachmentState,gd_MailSendTime from `GD_MailBox` where gd_MailType = ~w and gd_RecAccountID = ~w  ORDER BY gd_mailsendtime desc limit ~w,~w">>, [Type,PlayerId,StartIndex,?MAIL_PER_PAGE])
	end,
	{ok,Mail_list} = db_sql:execute(Mail_list_sql),
	{ok,[[Mail_count]]} = db_sql:execute(Count_sql),
	
	case Mail_list of 
		[]	->
			Ret_mail_list = [];
		_ ->
			F = fun([Id,SendName,SenderId,MailType,Title,Status,AttachmentStatus,TimeStamp]) ->
			#mail{mail_id=Id,
				  sender_name=SendName,
				  sender_id=SenderId,
				  mail_type=MailType,
				  mail_title=Title,
				  mail_status=Status,
				  attachment_status=AttachmentStatus,
				  timestamp=TimeStamp}
			end,
			Ret_mail_list = [F(Mail)|| Mail<-Mail_list]
		end,
	{Mail_count,length(Ret_mail_list),Ret_mail_list}.


attach_taken(Mail_id,Mail,_Code,_PlayerId) ->
	ItemNum = check_goodslist_num(Mail#mail.goods_list),
	case ItemNum > 0 of
		true ->
			GoodsStatus = 1;
		false ->
			GoodsStatus = 0
	end,
	case (GoodsStatus =:=0) andalso (Mail#mail.gold_status =:= 0) andalso
	 (Mail#mail.bind_gold_status =:= 0) andalso (Mail#mail.silver_status =:= 0)
	 andalso(Mail#mail.jungong_status =:= 0) of
	 true ->
	 	AttachmentStatus = 0;
	 false ->
	 	AttachmentStatus = 1
	 end,
	 ?INFO(mail,"GoodsStatus = ~w,gold_status =~w,bind_gold_status=~w,silver_status =~w,AttachmentStatus=~w",
	 					[GoodsStatus,Mail#mail.gold_status,Mail#mail.bind_gold_status,Mail#mail.silver_status,AttachmentStatus]),
	 GoodsList = io_lib:format("~w",[Mail#mail.goods_list]),
	Sql = db_sql:make_update_sql('GD_MailBox',["gd_Attachment", 
												"gd_AttachmentState", 
												"gd_mail_gold_status", 
												"gd_mail_gold", 
												"gd_mail_bind_gold_status", 
												"gd_mail_bind_gold", 
												"gd_mail_bind_silver_status", 
												"gd_mail_bind_silver",
												"gd_mail_jungong_status",
												"gd_mail_jungong"],

												[GoodsList,
												AttachmentStatus,
												Mail#mail.gold_status,
												Mail#mail.gold,
												Mail#mail.bind_gold_status,
												Mail#mail.bind_gold,
												Mail#mail.silver_status,
												Mail#mail.silver,
												Mail#mail.jungong_status,
												Mail#mail.jungong],
												"gd_MailID",Mail_id),
	?INFO(mail,"remove attachment by ~s",[Sql]),
	db_sql:execute(Sql).


check_goodslist_num(GoodsList) ->
	Fun = fun({_ID,IsCanTake,_ItemID,_Num},Sum) ->
		case IsCanTake =:= 1 of
			true ->
				Sum+1;
			false ->
				Sum
		end
	end,
	lists:foldl(Fun,0,GoodsList).

goodsListModify(GoodsList,Code) ->
	case Code of
		0 ->
			Fun = fun({ID,_IsCanTake,ItemID,Num}) ->
				{ID,0,ItemID,Num}
			end,
			lists:map(Fun,GoodsList);
		_Else ->
			Fun = fun({ID,IsCanTake,ItemID,Num}) ->
				case ID =:= Code of
					true ->
						{ID,0,ItemID,Num};
					false ->
						{ID,IsCanTake,ItemID,Num}
				end
			end,
			lists:map(Fun,GoodsList)
	end.
