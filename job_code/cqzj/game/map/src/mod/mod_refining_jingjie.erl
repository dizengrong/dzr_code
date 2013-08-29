%%%-------------------------------------------------------------------
%%% @author fangshaokong
%%% @doc
%%%     境界令镶嵌、拆卸
%%% @end
%%% Created : 2012-3-21
%%%-------------------------------------------------------------------
-module(mod_refining_jingjie).

-include("mgeem.hrl").

-export([
         is_jingjie_ling/1,
		 max_inlay_stone_num/1,
		 merge_repeat_jingjie_ling_stones/2
        ]).

%% 是否境界令
is_jingjie_ling(TypeID) ->
	max_inlay_stone_num(TypeID) > 0.

%% 每个孔最大镶嵌宝石个数
max_inlay_stone_num(TypeID) ->
	[List] = common_config_dyn:find(refining,equip_jingjie_list),
	case lists:keyfind(TypeID,1,List) of
		false ->
			0;
		{TypeID,MaxInlayStoneNum} ->
			MaxInlayStoneNum
	end.

%% 合并重复的境界令石头(绑定和非绑定合并)
merge_repeat_jingjie_ling_stones([],Stones) ->
	Stones;
merge_repeat_jingjie_ling_stones([PGoods|T],Stones) ->
	OtherTypeStoneList = 
		lists:filter(fun(Stone) ->
							 Stone#p_goods.typeid =/= PGoods#p_goods.typeid
					 end, Stones),
	SameTypeStoneList = 
		lists:filter(fun(Stone) ->
							 Stone#p_goods.typeid =:= PGoods#p_goods.typeid
					 end, Stones),	
	NewCurrentNum = 
		lists:foldl(fun(#p_goods{current_num=CurrentNum},Acc) ->
							CurrentNum+Acc
					end, 0, SameTypeStoneList),
	merge_repeat_jingjie_ling_stones(T,[PGoods#p_goods{current_num=NewCurrentNum} | OtherTypeStoneList]).
