-module(cache_xunxian).

%%
%% Include files
%%
-include("common.hrl").
-define(CACHE_XUNXIAN_REF, cache_util:get_register_name(xunxian)).

-export([init/1,getXunxianInfo/1,updateXunxian/1]).

init(AccountID) ->
	XunxianRec = #xunxian{
					gd_AccountID     = AccountID,
					gd_LastTime 	 = 0,
					gd_FreeTimes 	 = ?MAX_FREE_XUNXIAN_TIMES,
					gd_ImmortalPos   = 1,
					gd_ItemList 	 = []
					},
	gen_cache:insert(?CACHE_XUNXIAN_REF, XunxianRec).

getXunxianInfo(AccountID) ->
	case gen_cache:lookup(?CACHE_XUNXIAN_REF, AccountID) of
		[] ->
			[];
		[Xunxian] ->
			Xunxian
	end.

updateXunxian(Xunxian) ->
	gen_cache:update_record(?CACHE_XUNXIAN_REF, Xunxian).

