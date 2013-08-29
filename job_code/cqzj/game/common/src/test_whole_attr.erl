%% Author: Administrator
%% Created: 2012-2-27
%% Description: TODO: Add description to test
-module(test_whole_attr).

%%
%% Include files
%%

-include("common.hrl").
-include("common_server.hrl").

%%
%% Exported Functions
%%

-export([test/0]).

%%
%% API Functions
%%


test() ->
	TypeList = [30701101,30701201,30701301,30701401,30702101,30702102,30703101,30703102,30704101,30704102,30705101,30705102,30706101,30706102,30707101,30707102,30708101,30708102],
	List4 = db:dirty_match_object(db_role_attr, #p_role_attr{_='_'}),
	HitRoles3 = 
		lists:foldl(
		  fun(#p_role_attr{role_id=RoleID,equips=GoodList},Acc1) ->
				  B = lists:any(fun(TypeID)->
										F = lists:keymember(TypeID,#p_goods.typeid,GoodList),
										case F of
											true ->
												lists:any(fun(#p_goods{whole_attr=WA,current_colour=CL,typeid=TypeID2}=G) ->
																  case (CL =:= 4 orelse CL =:= 5) andalso TypeID2 =:= TypeID of
																	  true ->
																		  TT = WA=:=undefined orelse WA=:=[],
																		  case TT of
																			  true ->
																				  ?DBG(G);
																			  false ->
																				  ni
																		  end,
																		  TT;
																	  false ->
																		  false
																  end
														  end,GoodList);
											false ->
												false 
										end
								end, TypeList),
				  case B of
					  true ->
						  [RoleID|Acc1];
					  false ->
						  Acc1
				  end
		  end,[],List4),
	?DBG(HitRoles3).


%%
%% Local Functions
%%

