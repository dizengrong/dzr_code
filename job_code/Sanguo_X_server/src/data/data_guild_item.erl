-module(data_guild_item).
-compile(export_all).

-include("common.hrl").

get(1) ->
	#guild_item {
		id    = 1,
		level = 1,
		exp   = 2
	};
	
get(2) ->
	#guild_item {
		id    = 2,
		level = 2,
		exp   = 2
	};
	
get(3) ->
	#guild_item {
		id    = 3,
		level = 3,
		exp   = 222
	};
	
get(4) ->
	#guild_item {
		id    = 4,
		level = 4,
		exp   = 3
	};
	
get(5) ->
	#guild_item {
		id    = 5,
		level = 5,
		exp   = 3
	};
	
get(6) ->
	#guild_item {
		id    = 6,
		level = 6,
		exp   = 3
	};
	
get(7) ->
	#guild_item {
		id    = 7,
		level = 7,
		exp   = 3
	};
	
get(8) ->
	#guild_item {
		id    = 8,
		level = 8,
		exp   = 32
	};
	
get(9) ->
	#guild_item {
		id    = 9,
		level = 9,
		exp   = 2
	};
	
get(10) ->
	#guild_item {
		id    = 10,
		level = 10,
		exp   = 3
	};
	
get(11) ->
	#guild_item {
		id    = 11,
		level = 2,
		exp   = 10
	};
	

get(_) ->
	?UNDEFINED.