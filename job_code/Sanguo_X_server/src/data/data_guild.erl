-module(data_guild).
-compile(export_all).

-include("common.hrl").


get_guild_exp(1) ->
    0;
    
get_guild_exp(2) ->
    144830;
    
get_guild_exp(3) ->
    325860;
    
get_guild_exp(4) ->
    552150;
    
get_guild_exp(5) ->
    818370;
    
get_guild_exp(6) ->
    1131570;
    
get_guild_exp(7) ->
    1500050;
    
get_guild_exp(8) ->
    1933550;
    
get_guild_exp(9) ->
    2443550;
    
get_guild_exp(10) ->
    3043550;
    

get_guild_exp(_) ->
    ?UNDEFINED.

get_guild_donate(1) ->
    10000;
    
get_guild_donate(2) ->
    12000;
    
get_guild_donate(3) ->
    14000;
    
get_guild_donate(4) ->
    16000;
    
get_guild_donate(5) ->
    18000;
    
get_guild_donate(6) ->
    20000;
    
get_guild_donate(7) ->
    22000;
    
get_guild_donate(8) ->
    24000;
    
get_guild_donate(9) ->
    26000;
    
get_guild_donate(10) ->
    30000;
    

get_guild_donate(_) ->
    ?UNDEFINED.


    
    
    