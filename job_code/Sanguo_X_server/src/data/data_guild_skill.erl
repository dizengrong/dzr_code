-module(data_guild_skill).
-compile(export_all).

-include("common.hrl").

get(1, 1) ->
	#guild_skill {
		id          = 1,
		level       = 1,
		guild_level = 2,
		value       = 120,
		exp         = 500,
		coin        = 3000
	};

get(1, 2) ->
	#guild_skill {
		id          = 1,
		level       = 2,
		guild_level = 2,
		value       = 200,
		exp         = 1500,
		coin        = 6000
	};

get(1, 3) ->
	#guild_skill {
		id          = 1,
		level       = 3,
		guild_level = 2,
		value       = 370,
		exp         = 4300,
		coin        = 15000
	};

get(1, 4) ->
	#guild_skill {
		id          = 1,
		level       = 4,
		guild_level = 2,
		value       = 570,
		exp         = 7200,
		coin        = 90000
	};

get(1, 5) ->
	#guild_skill {
		id          = 1,
		level       = 5,
		guild_level = 2,
		value       = 760,
		exp         = 9000,
		coin        = 180000
	};
get(1, 6) ->
	#guild_skill {
		id          = 1,
		level       = 6,
		guild_level = 2,
		value       = 1020,
		exp         = 11200,
		coin        = 300000
	};

get(1, 7) ->
	#guild_skill {
		id          = 1,
		level       = 7,
		guild_level = 2,
		value       = 1270,
		exp         = 14000,
		coin        = 420000
	};

get(1, 8) ->
	#guild_skill {
		id          = 1,
		level       = 8,
		guild_level = 2,
		value       = 1540,
		exp         = 17500,
		coin        = 480000
	};
get(1, 9) ->
	#guild_skill {
		id          = 1,
		level       = 9,
		guild_level = 2,
		value       = 1760,
		exp         = 21900,
		coin        = 540000
	};

get(1, 10) ->
	#guild_skill {
		id          = 1,
		level       = 10,
		guild_level = 2,
		value       = 2048,
		exp         = 27300,
		coin        = 600000
	};

get(2, 1) ->
	#guild_skill {
		id          = 2,
		level       = 1,
		guild_level = 2,
		value       = 120,
		exp         = 500,
		coin        = 3000
	};
get(2, 2) ->
	#guild_skill {
		id          = 2,
		level       = 2,
		guild_level = 2,
		value       = 200,
		exp         = 1500,
		coin        = 6000
	};

get(2, 3) ->
	#guild_skill {
		id          = 2,
		level       = 3,
		guild_level = 2,
		value       = 370,
		exp         = 4300,
		coin        = 15000
	};
get(2, 4) ->
	#guild_skill {
		id          = 2,
		level       = 4,
		guild_level = 2,
		value       = 570,
		exp         = 7200,
		coin        = 90000
	};

get(2, 5) ->
	#guild_skill {
		id          = 2,
		level       = 5,
		guild_level = 2,
		value       = 760,
		exp         = 9000,
		coin        = 180000
	};
get(2, 6) ->
	#guild_skill {
		id          = 2,
		level       = 6,
		guild_level = 2,
		value       = 1020,
		exp         = 11200,
		coin        = 300000
	};

get(2, 7) ->
	#guild_skill {
		id          = 2,
		level       = 7,
		guild_level = 2,
		value       = 1270,
		exp         = 14000,
		coin        = 420000
	};
get(2, 8) ->
	#guild_skill {
		id          = 2,
		level       = 8,
		guild_level = 2,
		value       = 1540,
		exp         = 17500,
		coin        = 480000
	};

get(2, 9) ->
	#guild_skill {
		id          = 2,
		level       = 9,
		guild_level = 2,
		value       = 1760,
		exp         = 21900,
		coin        = 540000
	};
get(2, 10) ->
	#guild_skill {
		id          = 2,
		level       = 10,
		guild_level = 2,
		value       = 2048,
		exp         = 27300,
		coin        = 600000
	};

get(3, 1) ->
	#guild_skill {
		id          = 3,
		level       = 1,
		guild_level = 3,
		value       = 150,
		exp         = 500,
		coin        = 3000
	};

get(3, 2) ->
	#guild_skill {
		id          = 3,
		level       = 2,
		guild_level = 3,
		value       = 240,
		exp         = 1500,
		coin        = 6000
	};

get(3, 3) ->
	#guild_skill {
		id          = 3,
		level       = 3,
		guild_level = 3,
		value       = 440,
		exp         = 4300,
		coin        = 15000
	};

get(3, 4) ->
	#guild_skill {
		id          = 3,
		level       = 4,
		guild_level = 3,
		value       = 680,
		exp         = 7200,
		coin        = 90000
	};

get(3, 5) ->
	#guild_skill {
		id          = 3,
		level       = 5,
		guild_level = 3,
		value       = 900,
		exp         = 9000,
		coin        = 180000
	};

get(3, 6) ->
	#guild_skill {
		id          = 3,
		level       = 6,
		guild_level = 3,
		value       = 1220,
		exp         = 11200,
		coin        = 300000
	};

get(3, 7) ->
	#guild_skill {
		id          = 3,
		level       = 7,
		guild_level = 3,
		value       = 1510,
		exp         = 14000,
		coin        = 420000
	};

get(3, 8) ->
	#guild_skill {
		id          = 3,
		level       = 8,
		guild_level = 3,
		value       = 1830,
		exp         = 17500,
		coin        = 480000
	};

get(3, 9) ->
	#guild_skill {
		id          = 3,
		level       = 9,
		guild_level = 3,
		value       = 2100,
		exp         = 21900,
		coin        = 540000
	};

get(3, 10) ->
	#guild_skill {
		id          = 3,
		level       = 10,
		guild_level = 3,
		value       = 2437,
		exp         = 27300,
		coin        = 600000
	};

get(4, 1) ->
	#guild_skill {
		id          = 4,
		level       = 1,
		guild_level = 4,
		value       = 40,
		exp         = 500,
		coin        = 3000
	};
get(4, 2) 
  ->
	#guild_skill {
		id          = 4,
		level       = 2,
		guild_level = 4,
		value       = 70,
		exp         = 1500,
		coin        = 6000
	};

get(4, 3) ->
	#guild_skill {
		id          = 4,
		level       = 3,
		guild_level = 4,
		value       = 130,
		exp         = 4300,
		coin        = 15000
	};

get(4, 4) ->
	#guild_skill {
		id          = 4,
		level       = 4,
		guild_level = 4,
		value       = 200,
		exp         = 7200,
		coin        = 90000
	};

get(4, 5) ->
	#guild_skill {
		id          = 4,
		level       = 5,
		guild_level = 4,
		value       = 260,
		exp         = 9000,
		coin        = 180000
	};
get(4, 6) ->
	#guild_skill {
		id          = 4,
		level       = 6,
		guild_level = 4,
		value       = 350,
		exp         = 11200,
		coin        = 300000
	};

get(4, 7) ->
	#guild_skill {
		id          = 4,
		level       = 7,
		guild_level = 4,
		value       = 440,
		exp         = 14000,
		coin        = 420000
	};
get(4, 8) ->
	#guild_skill {
		id          = 4,
		level       = 8,
		guild_level = 4,
		value       = 530,
		exp         = 17500,
		coin        = 480000
	};

get(4, 9) ->
	#guild_skill {
		id          = 4,
		level       = 9,
		guild_level = 4,
		value       = 600,
		exp         = 21900,
		coin        = 540000
	};
get(4, 10) ->
	#guild_skill {
		id          = 4,
		level       = 10,
		guild_level = 4,
		value       = 702,
		exp         = 27300,
		coin        = 600000
	};

get(5, 1) ->
	#guild_skill {
		id          = 5,
		level       = 1,
		guild_level = 5,
		value       = 80,
		exp         = 500,
		coin        = 3000
	};

get(5, 2) ->
	#guild_skill {
		id          = 5,
		level       = 2,
		guild_level = 5,
		value       = 130,
		exp         = 1500,
		coin        = 6000
	};

get(5, 3) ->
	#guild_skill {
		id          = 5,
		level       = 3,
		guild_level = 5,
		value       = 230,
		exp         = 4300,
		coin        = 15000
	};

get(5, 4) ->
	#guild_skill {
		id          = 5,
		level       = 4,
		guild_level = 5,
		value       = 360,
		exp         = 7200,
		coin        = 90000
	};
get(5, 5) ->
	#guild_skill {
		id          = 5,
		level       = 5,
		guild_level = 5,
		value       = 480,
		exp         = 9000,
		coin        = 180000
	};

get(5, 6) ->
	#guild_skill {
		id          = 5,
		level       = 6,
		guild_level = 5,
		value       = 650,
		exp         = 11200,
		coin        = 300000
	};

get(5, 7) ->
	#guild_skill {
		id          = 5,
		level       = 7,
		guild_level = 5,
		value       = 810,
		exp         = 14000,
		coin        = 420000
	};

get(5, 8) ->
	#guild_skill {
		id          = 5,
		level       = 8,
		guild_level = 5,
		value       = 980,
		exp         = 17500,
		coin        = 480000
	};

get(5, 9) ->
	#guild_skill {
		id          = 5,
		level       = 9,
		guild_level = 5,
		value       = 1120,
		exp         = 21900,
		coin        = 540000
	};

get(5, 10) ->
	#guild_skill {
		id          = 5,
		level       = 10,
		guild_level = 5,
		value       = 1300,
		exp         = 27300,
		coin        = 600000
	};
get(6, 1) ->
	#guild_skill {
		id          = 6,
		level       = 1,
		guild_level = 6,
		value       = 80,
		exp         = 500,
		coin        = 3000
	};

get(6, 2) ->
	#guild_skill {
		id          = 6,
		level       = 2,
		guild_level = 6,
		value       = 130,
		exp         = 1500,
		coin        = 6000
	};

get(6, 3) ->
	#guild_skill {
		id          = 6,
		level       = 3,
		guild_level = 6,
		value       = 230,
		exp         = 4300,
		coin        = 15000
	};

get(6, 4) ->
	#guild_skill {
		id          = 6,
		level       = 4,
		guild_level = 6,
		value       = 360,
		exp         = 7200,
		coin        = 90000
	};

get(6, 5) ->
	#guild_skill {
		id          = 6,
		level       = 5,
		guild_level = 6,
		value       = 480,
		exp         = 9000,
		coin        = 180000
	};

get(6, 6) ->
	#guild_skill {
		id          = 6,
		level       = 6,
		guild_level = 6,
		value       = 650,
		exp         = 11200,
		coin        = 300000
	};

get(6, 7) ->
	#guild_skill {
		id          = 6,
		level       = 7,
		guild_level = 6,
		value       = 810,
		exp         = 14000,
		coin        = 420000
	};

get(6, 8) ->
	#guild_skill {
		id          = 6,
		level       = 8,
		guild_level = 6,
		value       = 980,
		exp         = 17500,
		coin        = 480000
	};

get(6, 9) ->
	#guild_skill {
		id          = 6,
		level       = 9,
		guild_level = 6,
		value       = 1120,
		exp         = 21900,
		coin        = 540000
	};

get(6, 10) ->
	#guild_skill {
		id          = 6,
		level       = 10,
		guild_level = 6,
		value       = 1300,
		exp         = 27300,
		coin        = 600000
	};

get(_, _) ->
	?UNDEFINED.