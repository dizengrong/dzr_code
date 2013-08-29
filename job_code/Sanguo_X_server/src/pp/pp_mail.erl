%%%------------------------------------
%%% @Module     : pp_mail
%%% @Author     : cjr
%%% @Email      : chenjianrong@4399.com
%%% @Created    : 2011-09-05
%%% @Description: 信件操作
%%%------------------------------------
-module(pp_mail).
-export([handle/3]).
-include("common.hrl").


%%if we need to limit the player send mail frequence, we might use status to save previous sent timestamp.
handle(14000, PlayerId, {Type,StartIndex}) ->
	mod_mail:get_mail_list(Type,StartIndex,14000,PlayerId),
	{ok, no_change};
	  
handle(14001, PlayerId, {MailID}) ->
	mod_mail:get_mail(MailID,PlayerId),
	{ok, no_change};

handle(14002, PlayerId,{Type,Receiver,Title,Content}) ->
	case Type of
		%%personal mail
		3	->	
			mod_mail:send_priv_mail(Receiver, Title, Content, PlayerId);
		%%guide mail
		2	->	
			mod_mail:send_guide_mail(Title,Content,PlayerId);
		_	->	
			{ok, Bin} = pt_14:write(14002,{failure,wrong_type}),
			lib_send:send(PlayerId, Bin)
	end,
	{ok, no_change};

handle(14003, PlayerId,{IdList,Type,Start_index}) ->
	mod_mail:delete_mail_list(IdList,Type,Start_index,PlayerId),
	{ok, no_change};

handle(14005, PlayerId,{Mail_id,Code,Good_id,Good_num}) ->
	mod_mail:get_attachment(Mail_id,Code,Good_id,Good_num,PlayerId),
	{ok, no_change};

handle(14006, PlayerId,{}) ->
	{ok,Bin} = pt_14:write(14006,{0}),
	lib_send:send(PlayerId, Bin).



