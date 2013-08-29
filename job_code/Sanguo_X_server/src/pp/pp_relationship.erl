%%%--------------------------------------
%%% @Module  : pp_relationship
%%% @Author  : cjr
%%% @Email   : chenjianrong@4399.com
%%% @Created : 2011-09-14
%%% @Description:  管理玩家间的关系
%%%--------------------------------------
-module(pp_relationship).

-include("common.hrl").

-export([handle/3]).

handle(18000, Id, {Type,Page}) ->
	%% type defination:0好友1公会2黑名单3最近联系人
	case Type of
		0 ->
			mod_relationship:query_friend(Id,Page);
		1 ->
			mod_relationship:query_guide(Id);
		2->
			mod_relationship:query_black(Id,Page);
		4->
			mod_relationship:recommend_friend(Id, data_relationship:get_recommend_num());
		_->
			?DEBUG(pp_relate,"unexpect type ~w",[Type])
	end;
	

handle(18001, Id, Name) ->
	mod_relationship:add_friend(Id,Name);
	

handle(18002, Id, Friend_id) ->
	mod_relationship:del_friend(Id, Friend_id);
	

handle(18003, Id, Friend_id) ->
	mod_relationship:add_black_list(Id, Friend_id);
	

handle(18004, Id, Friend_id) ->
	mod_relationship:remove_black(Id, Friend_id);
	

handle(18006, Id,  {Friend_id,Oper_code}) ->
	case Oper_code of 
		0	->
			mod_relationship:approve_add_friend(Id, Friend_id,0);
		_ 	->
			?INFO(relation, "Reject to add friends ~w, return ~w", [Friend_id,Oper_code])
	end;

handle(18008, Id, Friend_id) ->
	mod_relationship:pray(Id, Friend_id);


handle(18012, Id, {}) ->
	mod_relationship:base_info(Id);

handle(18013, Id, {Num}) ->
	mod_relationship:recommend_friend(Id,Num);


handle(finish, finish, finish) ->
	{ok, finish}.

