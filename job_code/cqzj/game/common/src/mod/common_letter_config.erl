-module(common_letter_config).

-export([get_expired_days/0,get_max_send_count/0,get_send_goods_price/0,get_type_list/0,get_default_type/0]).

%%玩家一天最多发多少封信件
get_expired_days() ->
    14.

get_max_send_count() -> 
    50.

get_send_goods_price() ->
    1000.

get_type_list() ->
    [{0,0,<<"私人">>},
     {1,1000,<<"家族">>},
     {2,0,<<"系统">>},
     {3,0,<<"退信">>},
     {4,0,<<"GM">>}].

get_default_type() ->
    0.





