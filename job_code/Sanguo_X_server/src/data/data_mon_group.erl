-module(data_mon_group).
-compile(export_all).

-include("common.hrl").


%% MonsterPos :: [{ID, Pos}]

get(1) ->
	#mon_group {
		id    = 1,
		level = 1,
		type  = soldier, 
		pos   = [{1, 1}, {1, 5}],  
		pts   = 0,
		items = [],
		exp   = 100
	};
	
get(2) ->
	#mon_group {
		id    = 2,
		level = 3,
		type  = soldier, 
		pos   = [{2, 2}, {2, 3}, {2, 4}],  
		pts   = 0,
		items = [],
		exp   = 120
	};
	
get(3) ->
	#mon_group {
		id    = 3,
		level = 5,
		type  = soldier, 
		pos   = [{3, 1}, {3, 3}, {3, 5}],  
		pts   = 0,
		items = [],
		exp   = 180
	};
	
get(4) ->
	#mon_group {
		id    = 4,
		level = 8,
		type  = soldier, 
		pos   = [{4, 2}, {4, 4}, {4, 6}],  
		pts   = 0,
		items = [],
		exp   = 200
	};
	
get(5) ->
	#mon_group {
		id    = 5,
		level = 10,
		type  = soldier, 
		pos   = [{5, 1}, {5, 3}, {5, 5}],  
		pts   = 0,
		items = [],
		exp   = 250
	};
	
get(6) ->
	#mon_group {
		id    = 6,
		level = 12,
		type  = soldier, 
		pos   = [{6, 1}, {6, 2}, {6, 4}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(7) ->
	#mon_group {
		id    = 7,
		level = 15,
		type  = soldier, 
		pos   = [{7, 2}, {7, 3}, {7, 4}],  
		pts   = 0,
		items = [],
		exp   = 350
	};
	
get(8) ->
	#mon_group {
		id    = 8,
		level = 18,
		type  = soldier, 
		pos   = [{8, 3}, {8, 5}, {8, 6}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(9) ->
	#mon_group {
		id    = 9,
		level = 20,
		type  = soldier, 
		pos   = [{9, 2}, {9, 4}, {9, 6}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 600
	};
	
get(10) ->
	#mon_group {
		id    = 10,
		level = 23,
		type  = soldier, 
		pos   = [{10, 2}, {10, 3}, {10, 5}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 600
	};
	
get(11) ->
	#mon_group {
		id    = 11,
		level = 25,
		type  = soldier, 
		pos   = [{11, 1}, {9, 4}, {11, 6}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(12) ->
	#mon_group {
		id    = 12,
		level = 28,
		type  = soldier, 
		pos   = [{9, 1}, {12, 2}, {9, 5}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 1000
	};
	
get(13) ->
	#mon_group {
		id    = 13,
		level = 29,
		type  = soldier, 
		pos   = [{11, 1}, {13, 3}, {11, 5}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 1300
	};
	
get(14) ->
	#mon_group {
		id    = 14,
		level = 29,
		type  = boss, 
		pos   = [{491, 1}, {14, 2}, {492, 3}, {493, 5}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 1600
	};
	
get(15) ->
	#mon_group {
		id    = 15,
		level = 30,
		type  = soldier, 
		pos   = [{10, 1}, {15, 2}, {10, 5}],  
		pts   = 0,
		items = [],
		exp   = 5000
	};
	
get(16) ->
	#mon_group {
		id    = 16,
		level = 30,
		type  = soldier, 
		pos   = [{16, 3}, {16, 5}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(17) ->
	#mon_group {
		id    = 17,
		level = 30,
		type  = soldier, 
		pos   = [{17, 2}, {17, 4}, {17, 6}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(18) ->
	#mon_group {
		id    = 18,
		level = 31,
		type  = soldier, 
		pos   = [{18, 1}, {18, 3}, {18, 5}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(19) ->
	#mon_group {
		id    = 19,
		level = 31,
		type  = soldier, 
		pos   = [{19, 2}, {19, 4}, {19, 6}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(20) ->
	#mon_group {
		id    = 20,
		level = 32,
		type  = soldier, 
		pos   = [{20, 3}, {20, 4}, {20, 5}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(21) ->
	#mon_group {
		id    = 21,
		level = 32,
		type  = soldier, 
		pos   = [{21, 1}, {21, 5}, {21, 6}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(22) ->
	#mon_group {
		id    = 22,
		level = 33,
		type  = soldier, 
		pos   = [{16, 2}, {22, 3}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(23) ->
	#mon_group {
		id    = 23,
		level = 34,
		type  = soldier, 
		pos   = [{23, 3}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(24) ->
	#mon_group {
		id    = 24,
		level = 33,
		type  = soldier, 
		pos   = [{24, 2}, {24, 4}, {24, 6}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(25) ->
	#mon_group {
		id    = 25,
		level = 34,
		type  = soldier, 
		pos   = [{25, 2}, {25, 5}, {25, 6}],  
		pts   = 0,
		items = [],
		exp   = 300
	};
	
get(26) ->
	#mon_group {
		id    = 26,
		level = 36,
		type  = soldier, 
		pos   = [{26, 1}, {26, 3}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(27) ->
	#mon_group {
		id    = 27,
		level = 36,
		type  = soldier, 
		pos   = [{27, 2}, {27, 3}, {27, 4}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(28) ->
	#mon_group {
		id    = 28,
		level = 37,
		type  = soldier, 
		pos   = [{28, 3}, {28, 4}, {28, 5}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(29) ->
	#mon_group {
		id    = 29,
		level = 37,
		type  = soldier, 
		pos   = [{29, 2}, {29, 4}, {29, 6}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(30) ->
	#mon_group {
		id    = 30,
		level = 38,
		type  = soldier, 
		pos   = [{27, 1}, {27, 3}, {30, 5}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 1200
	};
	
get(31) ->
	#mon_group {
		id    = 31,
		level = 38,
		type  = soldier, 
		pos   = [{31, 2}, {26, 4}, {26, 5}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 1500
	};
	
get(32) ->
	#mon_group {
		id    = 32,
		level = 39,
		type  = soldier, 
		pos   = [{26, 2}, {32, 3}, {26, 6}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 1600
	};
	
get(33) ->
	#mon_group {
		id    = 33,
		level = 40,
		type  = boss, 
		pos   = [{494, 1}, {495, 2}, {33, 3}, {496, 4}, {497, 6}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 5500
	};
	
get(34) ->
	#mon_group {
		id    = 34,
		level = 41,
		type  = soldier, 
		pos   = [{34, 2}, {34, 4}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(35) ->
	#mon_group {
		id    = 35,
		level = 41,
		type  = soldier, 
		pos   = [{35, 2}, {35, 3}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(36) ->
	#mon_group {
		id    = 36,
		level = 42,
		type  = soldier, 
		pos   = [{36, 1}, {36, 3}, {36, 5}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(37) ->
	#mon_group {
		id    = 37,
		level = 42,
		type  = soldier, 
		pos   = [{37, 2}, {37, 3}, {37, 4}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(38) ->
	#mon_group {
		id    = 38,
		level = 42,
		type  = soldier, 
		pos   = [{38, 1}, {38, 3}, {38, 5}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(39) ->
	#mon_group {
		id    = 39,
		level = 43,
		type  = soldier, 
		pos   = [{39, 2}, {39, 4}, {39, 6}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(40) ->
	#mon_group {
		id    = 40,
		level = 43,
		type  = soldier, 
		pos   = [{40, 1}, {40, 3}, {40, 6}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(41) ->
	#mon_group {
		id    = 41,
		level = 44,
		type  = soldier, 
		pos   = [{41, 2}, {41, 4}, {41, 5}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(42) ->
	#mon_group {
		id    = 42,
		level = 44,
		type  = soldier, 
		pos   = [{42, 1}, {42, 2}, {42, 6}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(43) ->
	#mon_group {
		id    = 43,
		level = 44,
		type  = soldier, 
		pos   = [{43, 3}, {43, 5}],  
		pts   = 0,
		items = [],
		exp   = 500
	};
	
get(44) ->
	#mon_group {
		id    = 44,
		level = 45,
		type  = soldier, 
		pos   = [{44, 2}, {44, 3}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(45) ->
	#mon_group {
		id    = 45,
		level = 45,
		type  = soldier, 
		pos   = [{45, 1}, {45, 2}, {45, 4}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(46) ->
	#mon_group {
		id    = 46,
		level = 46,
		type  = soldier, 
		pos   = [{46, 3}, {46, 5}, {46, 6}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(47) ->
	#mon_group {
		id    = 47,
		level = 46,
		type  = soldier, 
		pos   = [{47, 1}, {47, 2}, {47, 4}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 1300
	};
	
get(48) ->
	#mon_group {
		id    = 48,
		level = 47,
		type  = soldier, 
		pos   = [{47, 1}, {48, 2}, {47, 4}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 1600
	};
	
get(49) ->
	#mon_group {
		id    = 49,
		level = 48,
		type  = soldier, 
		pos   = [{46, 1}, {49, 3}, {46, 5}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 1800
	};
	
get(50) ->
	#mon_group {
		id    = 50,
		level = 48,
		type  = soldier, 
		pos   = [{50, 2}, {47, 4}, {47, 6}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 2000
	};
	
get(51) ->
	#mon_group {
		id    = 51,
		level = 49,
		type  = boss, 
		pos   = [{498, 1}, {499, 2}, {500, 3}, {501, 4}, {51, 5}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 7000
	};
	
get(52) ->
	#mon_group {
		id    = 52,
		level = 49,
		type  = soldier, 
		pos   = [{52, 2}, {52, 4}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(53) ->
	#mon_group {
		id    = 53,
		level = 50,
		type  = soldier, 
		pos   = [{53, 1}, {53, 3}, {53, 5}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(54) ->
	#mon_group {
		id    = 54,
		level = 51,
		type  = soldier, 
		pos   = [{54, 2}, {54, 4}, {54, 6}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(55) ->
	#mon_group {
		id    = 55,
		level = 52,
		type  = soldier, 
		pos   = [{55, 3}, {55, 5}, {55, 6}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(56) ->
	#mon_group {
		id    = 56,
		level = 53,
		type  = soldier, 
		pos   = [{56, 1}, {56, 2}, {56, 4}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(57) ->
	#mon_group {
		id    = 57,
		level = 55,
		type  = soldier, 
		pos   = [{57, 3}, {57, 5}, {57, 6}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(58) ->
	#mon_group {
		id    = 58,
		level = 55,
		type  = soldier, 
		pos   = [{58, 1}, {58, 2}, {58, 4}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(59) ->
	#mon_group {
		id    = 59,
		level = 56,
		type  = soldier, 
		pos   = [{59, 3}, {59, 5}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(60) ->
	#mon_group {
		id    = 60,
		level = 57,
		type  = soldier, 
		pos   = [{60, 2}, {60, 3}, {60, 5}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(61) ->
	#mon_group {
		id    = 61,
		level = 58,
		type  = soldier, 
		pos   = [{61, 1}, {61, 3}, {61, 6}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(62) ->
	#mon_group {
		id    = 62,
		level = 59,
		type  = soldier, 
		pos   = [{62, 2}, {62, 4}, {62, 5}],  
		pts   = 0,
		items = [],
		exp   = 600
	};
	
get(63) ->
	#mon_group {
		id    = 63,
		level = 61,
		type  = soldier, 
		pos   = [{63, 2}, {63, 3}, {63, 6}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(64) ->
	#mon_group {
		id    = 64,
		level = 63,
		type  = soldier, 
		pos   = [{64, 2}, {64, 3}, {64, 4}, {64, 6}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(65) ->
	#mon_group {
		id    = 65,
		level = 65,
		type  = soldier, 
		pos   = [{65, 1}, {65, 4}, {65, 5}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(66) ->
	#mon_group {
		id    = 66,
		level = 66,
		type  = soldier, 
		pos   = [{66, 3}, {66, 4}, {66, 5}],  
		pts   = 0,
		items = [{279,1,0.1},{293,1,0.1}],
		exp   = 800
	};
	
get(67) ->
	#mon_group {
		id    = 67,
		level = 67,
		type  = soldier, 
		pos   = [{65, 2}, {65, 3}, {67, 6}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 2000
	};
	
get(68) ->
	#mon_group {
		id    = 68,
		level = 68,
		type  = soldier, 
		pos   = [{66, 1}, {66, 3}, {68, 5}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 2000
	};
	
get(69) ->
	#mon_group {
		id    = 69,
		level = 69,
		type  = soldier, 
		pos   = [{66, 2}, {69, 3}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 2200
	};
	
get(70) ->
	#mon_group {
		id    = 70,
		level = 70,
		type  = boss, 
		pos   = [{503, 2}, {504, 3}, {505, 4}, {70, 5}, {506, 6}],  
		pts   = 0,
		items = [{286,1,0.2},{280,1,0.1},{279,1,0.1}],
		exp   = 8000
	};
	
get(71) ->
	#mon_group {
		id    = 71,
		level = 31,
		type  = soldier, 
		pos   = [{72, 1}, {71, 2}, {74, 3}, {73, 4}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{262,1,0.1}],
		exp   = 2390
	};
	
get(72) ->
	#mon_group {
		id    = 72,
		level = 32,
		type  = soldier, 
		pos   = [{76, 2}, {78, 3}, {75, 5}, {77, 6}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{262,1,0.1}],
		exp   = 2410
	};
	
get(73) ->
	#mon_group {
		id    = 73,
		level = 33,
		type  = soldier, 
		pos   = [{82, 1}, {83, 2}, {80, 3}, {81, 4}, {79, 5}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{262,1,0.1}],
		exp   = 2440
	};
	
get(74) ->
	#mon_group {
		id    = 74,
		level = 34,
		type  = soldier, 
		pos   = [{85, 1}, {84, 2}, {86, 3}, {87, 4}, {88, 5}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{262,1,0.1}],
		exp   = 2460
	};
	
get(75) ->
	#mon_group {
		id    = 75,
		level = 35,
		type  = boss, 
		pos   = [{90, 1}, {91, 2}, {93, 3}, {92, 4}, {89, 5}, {94, 6}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{212,1,0.1},{262,1,0.1}],
		exp   = 2490
	};
	
get(76) ->
	#mon_group {
		id    = 76,
		level = 36,
		type  = soldier, 
		pos   = [{96, 2}, {97, 3}, {95, 5}, {98, 6}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{212,1,0.1},{262,1,0.1}],
		exp   = 2510
	};
	
get(77) ->
	#mon_group {
		id    = 77,
		level = 37,
		type  = soldier, 
		pos   = [{99, 1}, {100, 2}, {101, 4}, {102, 5}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{212,1,0.1},{202,1,0.1},{262,1,0.1}],
		exp   = 2540
	};
	
get(78) ->
	#mon_group {
		id    = 78,
		level = 38,
		type  = soldier, 
		pos   = [{104, 1}, {105, 2}, {106, 3}, {103, 4}, {107, 5}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{212,1,0.1},{202,1,0.1},{262,1,0.1}],
		exp   = 2560
	};
	
get(79) ->
	#mon_group {
		id    = 79,
		level = 39,
		type  = soldier, 
		pos   = [{110, 1}, {115, 2}, {112, 3}, {109, 4}, {108, 5}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{212,1,0.1},{202,1,0.1},{222,1,0.1},{262,1,0.1}],
		exp   = 2590
	};
	
get(80) ->
	#mon_group {
		id    = 80,
		level = 40,
		type  = boss, 
		pos   = [{117, 1}, {118, 2}, {115, 3}, {114, 4}, {113, 5}, {116, 6}],  
		pts   = 0,
		items = [{182,1,0.1},{192,1,0.1},{232,1,0.1},{242,1,0.1},{252,1,0.1},{212,1,0.1},{202,1,0.1},{222,1,0.1},{262,1,0.1}],
		exp   = 2610
	};
	
get(81) ->
	#mon_group {
		id    = 81,
		level = 41,
		type  = soldier, 
		pos   = [{119, 1}, {120, 2}, {122, 3}, {121, 5}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{263,1,0.1}],
		exp   = 2640
	};
	
get(82) ->
	#mon_group {
		id    = 82,
		level = 41,
		type  = soldier, 
		pos   = [{125, 1}, {126, 3}, {124, 4}, {123, 5}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{263,1,0.1}],
		exp   = 2670
	};
	
get(83) ->
	#mon_group {
		id    = 83,
		level = 42,
		type  = soldier, 
		pos   = [{129, 1}, {128, 2}, {129, 3}, {129, 4}, {127, 5}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{263,1,0.1}],
		exp   = 2690
	};
	
get(84) ->
	#mon_group {
		id    = 84,
		level = 42,
		type  = soldier, 
		pos   = [{135, 2}, {136, 3}, {133, 4}, {132, 5}, {134, 6}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{263,1,0.1}],
		exp   = 2720
	};
	
get(85) ->
	#mon_group {
		id    = 85,
		level = 43,
		type  = boss, 
		pos   = [{138, 1}, {139, 2}, {140, 3}, {141, 4}, {137, 5}, {142, 6}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{213,1,0.1},{263,1,0.1}],
		exp   = 2750
	};
	
get(86) ->
	#mon_group {
		id    = 86,
		level = 43,
		type  = soldier, 
		pos   = [{144, 1}, {145, 2}, {143, 3}, {146, 4}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{213,1,0.1},{263,1,0.1}],
		exp   = 2780
	};
	
get(87) ->
	#mon_group {
		id    = 87,
		level = 44,
		type  = soldier, 
		pos   = [{147, 1}, {148, 2}, {149, 3}, {150, 5}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{213,1,0.1},{203,1,0.1},{263,1,0.1}],
		exp   = 2800
	};
	
get(88) ->
	#mon_group {
		id    = 88,
		level = 44,
		type  = soldier, 
		pos   = [{152, 1}, {154, 3}, {151, 5}, {153, 6}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{213,1,0.1},{203,1,0.1},{263,1,0.1}],
		exp   = 2830
	};
	
get(89) ->
	#mon_group {
		id    = 89,
		level = 45,
		type  = soldier, 
		pos   = [{158, 1}, {157, 2}, {159, 3}, {156, 4}, {155, 5}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{213,1,0.1},{203,1,0.1},{223,1,0.1},{263,1,0.1}],
		exp   = 2860
	};
	
get(90) ->
	#mon_group {
		id    = 90,
		level = 45,
		type  = boss, 
		pos   = [{161, 1}, {160, 2}, {163, 3}, {162, 4}, {164, 5}, {165, 6}],  
		pts   = 0,
		items = [{183,1,0.1},{193,1,0.1},{233,1,0.1},{243,1,0.1},{253,1,0.1},{213,1,0.1},{203,1,0.1},{223,1,0.1},{263,1,0.1}],
		exp   = 2890
	};
	
get(91) ->
	#mon_group {
		id    = 91,
		level = 46,
		type  = soldier, 
		pos   = [{166, 1}, {167, 2}, {168, 3}, {169, 4}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{264,1,0.1}],
		exp   = 2920
	};
	
get(92) ->
	#mon_group {
		id    = 92,
		level = 46,
		type  = soldier, 
		pos   = [{171, 1}, {170, 2}, {172, 3}, {173, 4}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{264,1,0.1}],
		exp   = 2950
	};
	
get(93) ->
	#mon_group {
		id    = 93,
		level = 47,
		type  = soldier, 
		pos   = [{176, 1}, {177, 2}, {178, 3}, {174, 4}, {175, 5}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{264,1,0.1}],
		exp   = 2980
	};
	
get(94) ->
	#mon_group {
		id    = 94,
		level = 47,
		type  = soldier, 
		pos   = [{183, 2}, {180, 3}, {181, 4}, {179, 5}, {182, 6}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{264,1,0.1}],
		exp   = 3010
	};
	
get(95) ->
	#mon_group {
		id    = 95,
		level = 48,
		type  = boss, 
		pos   = [{188, 1}, {189, 2}, {186, 3}, {185, 4}, {184, 5}, {187, 6}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{214,1,0.1},{264,1,0.1}],
		exp   = 3040
	};
	
get(96) ->
	#mon_group {
		id    = 96,
		level = 48,
		type  = soldier, 
		pos   = [{193, 3}, {192, 4}, {190, 5}, {191, 6}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{214,1,0.1},{264,1,0.1}],
		exp   = 3070
	};
	
get(97) ->
	#mon_group {
		id    = 97,
		level = 49,
		type  = soldier, 
		pos   = [{195, 1}, {196, 2}, {194, 3}, {197, 5}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{214,1,0.1},{204,1,0.1},{264,1,0.1}],
		exp   = 3100
	};
	
get(98) ->
	#mon_group {
		id    = 98,
		level = 49,
		type  = soldier, 
		pos   = [{198, 1}, {199, 2}, {200, 3}, {201, 4}, {202, 5}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{214,1,0.1},{204,1,0.1},{264,1,0.1}],
		exp   = 3130
	};
	
get(99) ->
	#mon_group {
		id    = 99,
		level = 50,
		type  = soldier, 
		pos   = [{205, 2}, {204, 3}, {203, 4}, {206, 5}, {207, 6}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{214,1,0.1},{204,1,0.1},{224,1,0.1},{264,1,0.1}],
		exp   = 3160
	};
	
get(100) ->
	#mon_group {
		id    = 100,
		level = 50,
		type  = boss, 
		pos   = [{211, 1}, {209, 2}, {210, 3}, {212, 4}, {208, 5}, {213, 6}],  
		pts   = 0,
		items = [{184,1,0.1},{194,1,0.1},{234,1,0.1},{244,1,0.1},{254,1,0.1},{214,1,0.1},{204,1,0.1},{224,1,0.1},{264,1,0.1}],
		exp   = 3200
	};
	
get(101) ->
	#mon_group {
		id    = 101,
		level = 51,
		type  = soldier, 
		pos   = [{217, 1}, {214, 2}, {215, 3}, {216, 5}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{265,1,0.1}],
		exp   = 3550
	};
	
get(102) ->
	#mon_group {
		id    = 102,
		level = 51,
		type  = soldier, 
		pos   = [{221, 2}, {220, 3}, {218, 5}, {219, 6}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{265,1,0.1}],
		exp   = 4030
	};
	
get(103) ->
	#mon_group {
		id    = 103,
		level = 52,
		type  = soldier, 
		pos   = [{226, 1}, {223, 2}, {224, 3}, {225, 4}, {222, 5}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{265,1,0.1}],
		exp   = 4590
	};
	
get(104) ->
	#mon_group {
		id    = 104,
		level = 52,
		type  = soldier, 
		pos   = [{227, 1}, {228, 2}, {231, 3}, {229, 4}, {230, 5}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{265,1,0.1}],
		exp   = 5210
	};
	
get(105) ->
	#mon_group {
		id    = 105,
		level = 53,
		type  = boss, 
		pos   = [{233, 1}, {234, 2}, {235, 3}, {236, 4}, {232, 5}, {237, 6}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{215,1,0.1},{265,1,0.1}],
		exp   = 5920
	};
	
get(106) ->
	#mon_group {
		id    = 106,
		level = 53,
		type  = soldier, 
		pos   = [{241, 2}, {240, 3}, {239, 4}, {238, 5}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{215,1,0.1},{265,1,0.1}],
		exp   = 6730
	};
	
get(107) ->
	#mon_group {
		id    = 107,
		level = 54,
		type  = soldier, 
		pos   = [{244, 1}, {242, 2}, {243, 3}, {245, 5}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{215,1,0.1},{205,1,0.1},{265,1,0.1}],
		exp   = 7080
	};
	
get(108) ->
	#mon_group {
		id    = 108,
		level = 54,
		type  = soldier, 
		pos   = [{248, 1}, {247, 2}, {246, 3}, {250, 4}, {249, 5}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{215,1,0.1},{205,1,0.1},{265,1,0.1}],
		exp   = 7450
	};
	
get(109) ->
	#mon_group {
		id    = 109,
		level = 55,
		type  = soldier, 
		pos   = [{253, 1}, {252, 2}, {255, 3}, {254, 4}, {251, 5}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{215,1,0.1},{205,1,0.1},{225,1,0.1},{265,1,0.1}],
		exp   = 7850
	};
	
get(110) ->
	#mon_group {
		id    = 110,
		level = 55,
		type  = boss, 
		pos   = [{257, 1}, {258, 2}, {259, 3}, {260, 4}, {261, 5}, {256, 6}],  
		pts   = 0,
		items = [{185,1,0.1},{195,1,0.1},{235,1,0.1},{245,1,0.1},{255,1,0.1},{215,1,0.1},{205,1,0.1},{225,1,0.1},{265,1,0.1}],
		exp   = 10330
	};
	
get(111) ->
	#mon_group {
		id    = 111,
		level = 56,
		type  = soldier, 
		pos   = [{265, 2}, {266, 3}, {263, 4}, {262, 5}, {264, 6}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{266,1,0.1}],
		exp   = 13770
	};
	
get(112) ->
	#mon_group {
		id    = 112,
		level = 56,
		type  = soldier, 
		pos   = [{271, 2}, {270, 3}, {267, 4}, {268, 5}, {269, 6}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{266,1,0.1}],
		exp   = 14970
	};
	
get(113) ->
	#mon_group {
		id    = 113,
		level = 57,
		type  = soldier, 
		pos   = [{272, 1}, {273, 2}, {274, 3}, {275, 4}, {276, 5}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{266,1,0.1}],
		exp   = 15760
	};
	
get(114) ->
	#mon_group {
		id    = 114,
		level = 57,
		type  = soldier, 
		pos   = [{278, 1}, {277, 2}, {279, 3}, {280, 4}, {281, 5}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{266,1,0.1}],
		exp   = 16550
	};
	
get(115) ->
	#mon_group {
		id    = 115,
		level = 58,
		type  = boss, 
		pos   = [{283, 1}, {284, 2}, {285, 3}, {286, 4}, {282, 5}, {287, 6}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{216,1,0.1},{266,1,0.1}],
		exp   = 16880
	};
	
get(116) ->
	#mon_group {
		id    = 116,
		level = 58,
		type  = soldier, 
		pos   = [{291, 1}, {292, 2}, {288, 4}, {289, 5}, {290, 6}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{216,1,0.1},{266,1,0.1}],
		exp   = 17900
	};
	
get(117) ->
	#mon_group {
		id    = 117,
		level = 59,
		type  = soldier, 
		pos   = [{297, 1}, {294, 2}, {295, 3}, {296, 4}, {293, 5}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{216,1,0.1},{206,1,0.1},{266,1,0.1}],
		exp   = 18970
	};
	
get(118) ->
	#mon_group {
		id    = 118,
		level = 59,
		type  = soldier, 
		pos   = [{299, 1}, {298, 2}, {300, 3}, {301, 4}, {302, 5}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{216,1,0.1},{206,1,0.1},{266,1,0.1}],
		exp   = 19350
	};
	
get(119) ->
	#mon_group {
		id    = 119,
		level = 60,
		type  = soldier, 
		pos   = [{306, 2}, {307, 3}, {303, 4}, {304, 5}, {305, 6}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{216,1,0.1},{206,1,0.1},{226,1,0.1},{266,1,0.1}],
		exp   = 19740
	};
	
get(120) ->
	#mon_group {
		id    = 120,
		level = 60,
		type  = boss, 
		pos   = [{310, 1}, {309, 2}, {311, 3}, {308, 4}, {312, 5}, {313, 6}],  
		pts   = 0,
		items = [{186,1,0.1},{196,1,0.1},{236,1,0.1},{246,1,0.1},{256,1,0.1},{216,1,0.1},{206,1,0.1},{226,1,0.1},{266,1,0.1}],
		exp   = 20330
	};
	
get(121) ->
	#mon_group {
		id    = 121,
		level = 61,
		type  = soldier, 
		pos   = [{317, 1}, {318, 2}, {316, 4}, {315, 5}, {314, 6}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{267,1,0.1}],
		exp   = 20980
	};
	
get(122) ->
	#mon_group {
		id    = 122,
		level = 61,
		type  = soldier, 
		pos   = [{323, 2}, {322, 3}, {319, 4}, {320, 5}, {321, 6}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{267,1,0.1}],
		exp   = 22030
	};
	
get(123) ->
	#mon_group {
		id    = 123,
		level = 62,
		type  = soldier, 
		pos   = [{324, 1}, {325, 2}, {326, 3}, {327, 4}, {328, 5}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{267,1,0.1}],
		exp   = 23130
	};
	
get(124) ->
	#mon_group {
		id    = 124,
		level = 62,
		type  = soldier, 
		pos   = [{332, 1}, {331, 2}, {330, 3}, {333, 4}, {329, 5}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{267,1,0.1}],
		exp   = 24290
	};
	
get(125) ->
	#mon_group {
		id    = 125,
		level = 63,
		type  = boss, 
		pos   = [{337, 1}, {338, 2}, {339, 3}, {335, 4}, {334, 5}, {336, 6}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{217,1,0.1},{267,1,0.1}],
		exp   = 25500
	};
	
get(126) ->
	#mon_group {
		id    = 126,
		level = 63,
		type  = soldier, 
		pos   = [{341, 1}, {342, 2}, {340, 3}, {344, 4}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{217,1,0.1},{267,1,0.1}],
		exp   = 25760
	};
	
get(127) ->
	#mon_group {
		id    = 127,
		level = 64,
		type  = soldier, 
		pos   = [{348, 2}, {349, 3}, {345, 4}, {346, 5}, {347, 6}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{217,1,0.1},{207,1,0.1},{267,1,0.1}],
		exp   = 26020
	};
	
get(128) ->
	#mon_group {
		id    = 128,
		level = 64,
		type  = soldier, 
		pos   = [{351, 1}, {350, 2}, {352, 3}, {353, 4}, {354, 5}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{217,1,0.1},{207,1,0.1},{267,1,0.1}],
		exp   = 26280
	};
	
get(129) ->
	#mon_group {
		id    = 129,
		level = 65,
		type  = soldier, 
		pos   = [{356, 1}, {359, 2}, {357, 3}, {358, 4}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{217,1,0.1},{207,1,0.1},{227,1,0.1},{267,1,0.1}],
		exp   = 27590
	};
	
get(130) ->
	#mon_group {
		id    = 130,
		level = 65,
		type  = boss, 
		pos   = [{363, 1}, {364, 2}, {365, 3}, {361, 4}, {360, 5}, {362, 6}],  
		pts   = 0,
		items = [{187,1,0.1},{197,1,0.1},{237,1,0.1},{247,1,0.1},{257,1,0.1},{217,1,0.1},{207,1,0.1},{227,1,0.1},{267,1,0.1}],
		exp   = 29260
	};
	
get(131) ->
	#mon_group {
		id    = 131,
		level = 66,
		type  = soldier, 
		pos   = [{370, 2}, {369, 3}, {368, 4}, {367, 5}, {366, 6}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{268,1,0.1}],
		exp   = 31350
	};
	
get(132) ->
	#mon_group {
		id    = 132,
		level = 66,
		type  = soldier, 
		pos   = [{373, 1}, {372, 2}, {375, 3}, {374, 4}, {371, 5}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{268,1,0.1}],
		exp   = 32290
	};
	
get(133) ->
	#mon_group {
		id    = 133,
		level = 67,
		type  = soldier, 
		pos   = [{376, 1}, {377, 2}, {378, 3}, {380, 4}, {379, 5}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{268,1,0.1}],
		exp   = 33260
	};
	
get(134) ->
	#mon_group {
		id    = 134,
		level = 67,
		type  = soldier, 
		pos   = [{384, 1}, {385, 2}, {383, 4}, {382, 5}, {381, 6}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{268,1,0.1}],
		exp   = 34260
	};
	
get(135) ->
	#mon_group {
		id    = 135,
		level = 68,
		type  = boss, 
		pos   = [{387, 1}, {388, 2}, {389, 3}, {390, 4}, {386, 5}, {391, 6}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{218,1,0.1},{268,1,0.1}],
		exp   = 35290
	};
	
get(136) ->
	#mon_group {
		id    = 136,
		level = 68,
		type  = soldier, 
		pos   = [{393, 1}, {392, 2}, {396, 3}, {394, 5}, {395, 6}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{218,1,0.1},{268,1,0.1}],
		exp   = 35460
	};
	
get(137) ->
	#mon_group {
		id    = 137,
		level = 69,
		type  = soldier, 
		pos   = [{397, 1}, {398, 2}, {399, 3}, {400, 4}, {401, 5}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{218,1,0.1},{208,1,0.1},{268,1,0.1}],
		exp   = 35640
	};
	
get(138) ->
	#mon_group {
		id    = 138,
		level = 69,
		type  = soldier, 
		pos   = [{402, 1}, {406, 2}, {403, 4}, {404, 5}, {405, 6}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{218,1,0.1},{208,1,0.1},{268,1,0.1}],
		exp   = 35820
	};
	
get(139) ->
	#mon_group {
		id    = 139,
		level = 70,
		type  = soldier, 
		pos   = [{407, 1}, {408, 2}, {410, 3}, {409, 4}, {411, 6}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{218,1,0.1},{208,1,0.1},{228,1,0.1},{268,1,0.1}],
		exp   = 36000
	};
	
get(140) ->
	#mon_group {
		id    = 140,
		level = 70,
		type  = boss, 
		pos   = [{413, 1}, {417, 2}, {414, 3}, {415, 4}, {412, 5}, {416, 6}],  
		pts   = 0,
		items = [{188,1,0.1},{198,1,0.1},{238,1,0.1},{248,1,0.1},{258,1,0.1},{218,1,0.1},{208,1,0.1},{228,1,0.1},{268,1,0.1}],
		exp   = 40520
	};
	
get(141) ->
	#mon_group {
		id    = 141,
		level = 71,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 41240
	};
	
get(142) ->
	#mon_group {
		id    = 142,
		level = 72,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 41650
	};
	
get(143) ->
	#mon_group {
		id    = 143,
		level = 73,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 42070
	};
	
get(144) ->
	#mon_group {
		id    = 144,
		level = 74,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 42490
	};
	
get(145) ->
	#mon_group {
		id    = 145,
		level = 75,
		type  = boss, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 42920
	};
	
get(146) ->
	#mon_group {
		id    = 146,
		level = 76,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 43350
	};
	
get(147) ->
	#mon_group {
		id    = 147,
		level = 77,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 43780
	};
	
get(148) ->
	#mon_group {
		id    = 148,
		level = 78,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 44220
	};
	
get(149) ->
	#mon_group {
		id    = 149,
		level = 79,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 44660
	};
	
get(150) ->
	#mon_group {
		id    = 150,
		level = 80,
		type  = boss, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 45110
	};
	
get(151) ->
	#mon_group {
		id    = 151,
		level = 81,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 45200
	};
	
get(152) ->
	#mon_group {
		id    = 152,
		level = 82,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 45650
	};
	
get(153) ->
	#mon_group {
		id    = 153,
		level = 83,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 46110
	};
	
get(154) ->
	#mon_group {
		id    = 154,
		level = 84,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 46570
	};
	
get(155) ->
	#mon_group {
		id    = 155,
		level = 85,
		type  = boss, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 47040
	};
	
get(156) ->
	#mon_group {
		id    = 156,
		level = 86,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 47510
	};
	
get(157) ->
	#mon_group {
		id    = 157,
		level = 87,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 47740
	};
	
get(158) ->
	#mon_group {
		id    = 158,
		level = 88,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 47980
	};
	
get(159) ->
	#mon_group {
		id    = 159,
		level = 89,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 48220
	};
	
get(160) ->
	#mon_group {
		id    = 160,
		level = 90,
		type  = boss, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 48460
	};
	
get(161) ->
	#mon_group {
		id    = 161,
		level = 91,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 66200
	};
	
get(162) ->
	#mon_group {
		id    = 162,
		level = 92,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 66540
	};
	
get(163) ->
	#mon_group {
		id    = 163,
		level = 93,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 66870
	};
	
get(164) ->
	#mon_group {
		id    = 164,
		level = 94,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 67200
	};
	
get(165) ->
	#mon_group {
		id    = 165,
		level = 95,
		type  = boss, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 67540
	};
	
get(166) ->
	#mon_group {
		id    = 166,
		level = 96,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 67740
	};
	
get(167) ->
	#mon_group {
		id    = 167,
		level = 97,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 68080
	};
	
get(168) ->
	#mon_group {
		id    = 168,
		level = 98,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 68280
	};
	
get(169) ->
	#mon_group {
		id    = 169,
		level = 99,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 68630
	};
	
get(170) ->
	#mon_group {
		id    = 170,
		level = 100,
		type  = boss, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 68690
	};
	
get(171) ->
	#mon_group {
		id    = 171,
		level = 30,
		type  = soldier, 
		pos   = [{418, 1}, {419, 2}, {421, 3}, {420, 5}],  
		pts   = 0,
		items = [],
		exp   = 2500
	};
	
get(172) ->
	#mon_group {
		id    = 172,
		level = 40,
		type  = soldier, 
		pos   = [{422, 1}, {423, 2}, {425, 3}, {424, 5}],  
		pts   = 0,
		items = [],
		exp   = 3500
	};
	
get(173) ->
	#mon_group {
		id    = 173,
		level = 46,
		type  = soldier, 
		pos   = [{426, 1}, {427, 2}, {428, 4}, {429, 5}],  
		pts   = 0,
		items = [],
		exp   = 4000
	};
	
get(174) ->
	#mon_group {
		id    = 174,
		level = 52,
		type  = soldier, 
		pos   = [{430, 1}, {431, 2}, {433, 3}, {432, 5}],  
		pts   = 0,
		items = [],
		exp   = 7000
	};
	
get(175) ->
	#mon_group {
		id    = 175,
		level = 58,
		type  = soldier, 
		pos   = [{438, 1}, {437, 3}, {434, 4}, {435, 5}, {436, 6}],  
		pts   = 0,
		items = [],
		exp   = 10000
	};
	
get(176) ->
	#mon_group {
		id    = 176,
		level = 64,
		type  = soldier, 
		pos   = [{442, 2}, {443, 3}, {441, 4}, {439, 5}, {440, 6}],  
		pts   = 0,
		items = [],
		exp   = 16000
	};
	
get(177) ->
	#mon_group {
		id    = 177,
		level = 70,
		type  = soldier, 
		pos   = [{448, 2}, {447, 3}, {445, 4}, {444, 5}, {446, 6}],  
		pts   = 0,
		items = [],
		exp   = 22000
	};
	
get(178) ->
	#mon_group {
		id    = 178,
		level = 80,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 30000
	};
	
get(179) ->
	#mon_group {
		id    = 179,
		level = 85,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 40000
	};
	
get(180) ->
	#mon_group {
		id    = 180,
		level = 90,
		type  = soldier, 
		pos   = [],  
		pts   = 0,
		items = [],
		exp   = 50000
	};
	
get(181) ->
	#mon_group {
		id    = 181,
		level = 40,
		type  = boss, 
		pos   = [{450, 1}, {449, 2}, {453, 3}, {451, 4}, {452, 5}, {454, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(182) ->
	#mon_group {
		id    = 182,
		level = 45,
		type  = boss, 
		pos   = [{456, 1}, {455, 2}, {458, 3}, {457, 4}, {459, 5}, {460, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(183) ->
	#mon_group {
		id    = 183,
		level = 50,
		type  = boss, 
		pos   = [{462, 1}, {461, 2}, {463, 3}, {464, 4}, {465, 5}, {466, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(184) ->
	#mon_group {
		id    = 184,
		level = 55,
		type  = boss, 
		pos   = [{468, 1}, {467, 2}, {472, 3}, {470, 4}, {471, 5}, {469, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(185) ->
	#mon_group {
		id    = 185,
		level = 60,
		type  = boss, 
		pos   = [{474, 1}, {475, 2}, {476, 3}, {473, 4}, {477, 5}, {478, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(186) ->
	#mon_group {
		id    = 186,
		level = 65,
		type  = boss, 
		pos   = [{484, 1}, {483, 2}, {482, 3}, {481, 4}, {480, 5}, {479, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(187) ->
	#mon_group {
		id    = 187,
		level = 70,
		type  = boss, 
		pos   = [{490, 1}, {489, 2}, {488, 3}, {487, 4}, {485, 5}, {486, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(188) ->
	#mon_group {
		id    = 188,
		level = 70,
		type  = boss, 
		pos   = [{490, 1}, {489, 2}, {488, 3}, {487, 4}, {485, 5}, {486, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(189) ->
	#mon_group {
		id    = 189,
		level = 70,
		type  = boss, 
		pos   = [{490, 1}, {489, 2}, {488, 3}, {487, 4}, {485, 5}, {486, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(190) ->
	#mon_group {
		id    = 190,
		level = 70,
		type  = boss, 
		pos   = [{490, 1}, {489, 2}, {488, 3}, {487, 4}, {485, 5}, {486, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(200) ->
	#mon_group {
		id    = 200,
		level = 20,
		type  = soldier, 
		pos   = [{507, 2}, {508, 3}, {507, 4}, {508, 5}, {507, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(201) ->
	#mon_group {
		id    = 201,
		level = 23,
		type  = soldier, 
		pos   = [{508, 1}, {507, 2}, {508, 3}, {508, 4}, {509, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(202) ->
	#mon_group {
		id    = 202,
		level = 25,
		type  = soldier, 
		pos   = [{509, 1}, {509, 2}, {508, 3}, {509, 4}, {507, 5}, {508, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(203) ->
	#mon_group {
		id    = 203,
		level = 28,
		type  = soldier, 
		pos   = [{509, 1}, {510, 2}, {509, 3}, {507, 4}, {507, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(204) ->
	#mon_group {
		id    = 204,
		level = 29,
		type  = soldier, 
		pos   = [{507, 1}, {507, 2}, {511, 3}, {509, 4}, {509, 5}, {509, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(205) ->
	#mon_group {
		id    = 205,
		level = 29,
		type  = boss, 
		pos   = [{513, 1}, {512, 2}, {514, 3}, {515, 4}, {516, 5}, {517, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(206) ->
	#mon_group {
		id    = 206,
		level = 36,
		type  = soldier, 
		pos   = [{518, 1}, {519, 2}, {518, 3}, {519, 4}, {518, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(207) ->
	#mon_group {
		id    = 207,
		level = 36,
		type  = soldier, 
		pos   = [{519, 1}, {519, 2}, {518, 3}, {519, 4}, {518, 5}, {519, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(208) ->
	#mon_group {
		id    = 208,
		level = 37,
		type  = soldier, 
		pos   = [{518, 2}, {519, 3}, {520, 4}, {520, 5}, {520, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(209) ->
	#mon_group {
		id    = 209,
		level = 37,
		type  = soldier, 
		pos   = [{521, 1}, {521, 2}, {519, 3}, {520, 4}, {520, 5}, {521, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(210) ->
	#mon_group {
		id    = 210,
		level = 38,
		type  = soldier, 
		pos   = [{521, 1}, {521, 2}, {520, 3}, {519, 4}, {522, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(211) ->
	#mon_group {
		id    = 211,
		level = 38,
		type  = soldier, 
		pos   = [{520, 1}, {523, 2}, {520, 3}, {519, 4}, {519, 5}, {519, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(212) ->
	#mon_group {
		id    = 212,
		level = 39,
		type  = soldier, 
		pos   = [{522, 1}, {523, 2}, {524, 3}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(213) ->
	#mon_group {
		id    = 213,
		level = 40,
		type  = boss, 
		pos   = [{527, 1}, {526, 2}, {530, 3}, {528, 4}, {525, 5}, {529, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(214) ->
	#mon_group {
		id    = 214,
		level = 45,
		type  = soldier, 
		pos   = [{532, 1}, {531, 2}, {531, 3}, {532, 4}, {532, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(215) ->
	#mon_group {
		id    = 215,
		level = 45,
		type  = soldier, 
		pos   = [{532, 1}, {533, 2}, {533, 3}, {532, 4}, {532, 5}, {532, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(216) ->
	#mon_group {
		id    = 216,
		level = 46,
		type  = soldier, 
		pos   = [{532, 1}, {533, 3}, {531, 4}, {531, 5}, {532, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(217) ->
	#mon_group {
		id    = 217,
		level = 46,
		type  = soldier, 
		pos   = [{533, 1}, {534, 2}, {534, 3}, {534, 4}, {532, 5}, {534, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(218) ->
	#mon_group {
		id    = 218,
		level = 47,
		type  = soldier, 
		pos   = [{541, 1}, {532, 2}, {532, 3}, {533, 4}, {533, 5}, {532, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(219) ->
	#mon_group {
		id    = 219,
		level = 48,
		type  = soldier, 
		pos   = [{533, 1}, {536, 2}, {533, 3}, {534, 4}, {534, 5}, {533, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(220) ->
	#mon_group {
		id    = 220,
		level = 48,
		type  = soldier, 
		pos   = [{537, 1}, {534, 2}, {536, 3}, {534, 4}, {531, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(221) ->
	#mon_group {
		id    = 221,
		level = 49,
		type  = boss, 
		pos   = [{539, 1}, {540, 2}, {541, 3}, {542, 4}, {538, 5}, {543, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(222) ->
	#mon_group {
		id    = 222,
		level = 61,
		type  = soldier, 
		pos   = [{544, 2}, {544, 3}, {544, 4}, {545, 5}, {545, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(223) ->
	#mon_group {
		id    = 223,
		level = 63,
		type  = soldier, 
		pos   = [{545, 1}, {545, 2}, {544, 3}, {545, 4}, {545, 5}, {546, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(224) ->
	#mon_group {
		id    = 224,
		level = 65,
		type  = soldier, 
		pos   = [{547, 1}, {547, 2}, {547, 3}, {546, 4}, {546, 5}, {545, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(225) ->
	#mon_group {
		id    = 225,
		level = 66,
		type  = soldier, 
		pos   = [{544, 1}, {547, 2}, {544, 3}, {547, 4}, {547, 5}, {547, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(226) ->
	#mon_group {
		id    = 226,
		level = 67,
		type  = soldier, 
		pos   = [{545, 1}, {548, 2}, {545, 3}, {547, 4}, {547, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(227) ->
	#mon_group {
		id    = 227,
		level = 68,
		type  = soldier, 
		pos   = [{545, 1}, {545, 2}, {546, 3}, {549, 4}, {546, 5}, {547, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(228) ->
	#mon_group {
		id    = 228,
		level = 69,
		type  = soldier, 
		pos   = [{549, 2}, {550, 3}, {544, 4}, {545, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(229) ->
	#mon_group {
		id    = 229,
		level = 70,
		type  = boss, 
		pos   = [{552, 1}, {551, 2}, {553, 3}, {554, 4}, {555, 5}, {556, 6}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(1000) ->
	#mon_group {
		id    = 1000,
		level = 100,
		type  = boss, 
		pos   = [{1000, 5}],  
		pts   = 0,
		items = [],
		exp   = 0
	};
	
get(230) ->
	#mon_group {
		id    = 230,
		level = 40,
		type  = boss, 
		pos   = [{558, 1}, {559, 2}, {558, 3}, {557, 4}, {557, 5}, {557, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(231) ->
	#mon_group {
		id    = 231,
		level = 40,
		type  = boss, 
		pos   = [{561, 1}, {562, 2}, {561, 3}, {560, 4}, {560, 5}, {560, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(232) ->
	#mon_group {
		id    = 232,
		level = 40,
		type  = boss, 
		pos   = [{564, 1}, {565, 2}, {564, 3}, {563, 4}, {563, 5}, {563, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(233) ->
	#mon_group {
		id    = 233,
		level = 40,
		type  = boss, 
		pos   = [{567, 1}, {568, 2}, {567, 3}, {566, 4}, {566, 5}, {566, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(234) ->
	#mon_group {
		id    = 234,
		level = 40,
		type  = boss, 
		pos   = [{570, 1}, {571, 2}, {570, 3}, {569, 4}, {569, 5}, {569, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(235) ->
	#mon_group {
		id    = 235,
		level = 40,
		type  = boss, 
		pos   = [{573, 1}, {574, 2}, {573, 3}, {572, 4}, {572, 5}, {572, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(236) ->
	#mon_group {
		id    = 236,
		level = 40,
		type  = boss, 
		pos   = [{576, 1}, {577, 2}, {576, 3}, {575, 4}, {575, 5}, {575, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(237) ->
	#mon_group {
		id    = 237,
		level = 40,
		type  = boss, 
		pos   = [{579, 1}, {580, 2}, {579, 3}, {578, 4}, {578, 5}, {578, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(238) ->
	#mon_group {
		id    = 238,
		level = 40,
		type  = boss, 
		pos   = [{582, 1}, {583, 2}, {582, 3}, {581, 4}, {581, 5}, {581, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(239) ->
	#mon_group {
		id    = 239,
		level = 40,
		type  = boss, 
		pos   = [{585, 1}, {586, 2}, {585, 3}, {584, 4}, {584, 5}, {584, 6}],  
		pts   = 0,
		items = [],
		exp   = 6000
	};
	
get(240) ->
	#mon_group {
		id    = 240,
		level = 50,
		type  = boss, 
		pos   = [{587, 1}, {587, 2}, {588, 3}, {588, 4}, {589, 5}, {587, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(241) ->
	#mon_group {
		id    = 241,
		level = 50,
		type  = boss, 
		pos   = [{590, 1}, {590, 2}, {591, 3}, {591, 4}, {592, 5}, {590, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(242) ->
	#mon_group {
		id    = 242,
		level = 50,
		type  = boss, 
		pos   = [{593, 1}, {593, 2}, {594, 3}, {594, 4}, {595, 5}, {593, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(243) ->
	#mon_group {
		id    = 243,
		level = 50,
		type  = boss, 
		pos   = [{596, 1}, {596, 2}, {597, 3}, {597, 4}, {598, 5}, {596, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(244) ->
	#mon_group {
		id    = 244,
		level = 50,
		type  = boss, 
		pos   = [{599, 1}, {599, 2}, {600, 3}, {600, 4}, {601, 5}, {599, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(245) ->
	#mon_group {
		id    = 245,
		level = 50,
		type  = boss, 
		pos   = [{602, 1}, {602, 2}, {603, 3}, {603, 4}, {604, 5}, {602, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(246) ->
	#mon_group {
		id    = 246,
		level = 50,
		type  = boss, 
		pos   = [{605, 1}, {605, 2}, {606, 3}, {606, 4}, {607, 5}, {605, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(247) ->
	#mon_group {
		id    = 247,
		level = 50,
		type  = boss, 
		pos   = [{608, 1}, {608, 2}, {609, 3}, {609, 4}, {610, 5}, {608, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(248) ->
	#mon_group {
		id    = 248,
		level = 50,
		type  = boss, 
		pos   = [{611, 1}, {611, 2}, {612, 3}, {612, 4}, {613, 5}, {611, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(249) ->
	#mon_group {
		id    = 249,
		level = 50,
		type  = boss, 
		pos   = [{614, 1}, {614, 2}, {615, 3}, {615, 4}, {616, 5}, {614, 6}],  
		pts   = 0,
		items = [],
		exp   = 8000
	};
	
get(250) ->
	#mon_group {
		id    = 250,
		level = 55,
		type  = boss, 
		pos   = [{617, 1}, {619, 2}, {617, 3}, {618, 4}, {618, 5}, {618, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(251) ->
	#mon_group {
		id    = 251,
		level = 55,
		type  = boss, 
		pos   = [{620, 1}, {622, 2}, {620, 3}, {621, 4}, {621, 5}, {621, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(252) ->
	#mon_group {
		id    = 252,
		level = 55,
		type  = boss, 
		pos   = [{623, 1}, {625, 2}, {623, 3}, {624, 4}, {624, 5}, {624, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(253) ->
	#mon_group {
		id    = 253,
		level = 55,
		type  = boss, 
		pos   = [{626, 1}, {628, 2}, {626, 3}, {627, 4}, {627, 5}, {627, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(254) ->
	#mon_group {
		id    = 254,
		level = 55,
		type  = boss, 
		pos   = [{629, 1}, {631, 2}, {629, 3}, {630, 4}, {630, 5}, {630, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(255) ->
	#mon_group {
		id    = 255,
		level = 55,
		type  = boss, 
		pos   = [{632, 1}, {634, 2}, {632, 3}, {633, 4}, {633, 5}, {633, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(256) ->
	#mon_group {
		id    = 256,
		level = 55,
		type  = boss, 
		pos   = [{635, 1}, {637, 2}, {635, 3}, {636, 4}, {636, 5}, {636, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(257) ->
	#mon_group {
		id    = 257,
		level = 55,
		type  = boss, 
		pos   = [{638, 1}, {640, 2}, {638, 3}, {639, 4}, {639, 5}, {639, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(258) ->
	#mon_group {
		id    = 258,
		level = 55,
		type  = boss, 
		pos   = [{641, 1}, {643, 2}, {641, 3}, {642, 4}, {642, 5}, {642, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(259) ->
	#mon_group {
		id    = 259,
		level = 55,
		type  = boss, 
		pos   = [{644, 1}, {646, 2}, {644, 3}, {645, 4}, {645, 5}, {645, 6}],  
		pts   = 0,
		items = [],
		exp   = 10700
	};
	
get(260) ->
	#mon_group {
		id    = 260,
		level = 60,
		type  = boss, 
		pos   = [{647, 1}, {647, 2}, {648, 3}, {648, 4}, {649, 5}, {648, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(261) ->
	#mon_group {
		id    = 261,
		level = 60,
		type  = boss, 
		pos   = [{650, 1}, {650, 2}, {651, 3}, {651, 4}, {652, 5}, {651, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(262) ->
	#mon_group {
		id    = 262,
		level = 60,
		type  = boss, 
		pos   = [{653, 1}, {653, 2}, {654, 3}, {654, 4}, {655, 5}, {654, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(263) ->
	#mon_group {
		id    = 263,
		level = 60,
		type  = boss, 
		pos   = [{656, 1}, {656, 2}, {657, 3}, {657, 4}, {658, 5}, {657, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(264) ->
	#mon_group {
		id    = 264,
		level = 60,
		type  = boss, 
		pos   = [{659, 1}, {659, 2}, {660, 3}, {660, 4}, {661, 5}, {660, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(265) ->
	#mon_group {
		id    = 265,
		level = 60,
		type  = boss, 
		pos   = [{662, 1}, {662, 2}, {663, 3}, {663, 4}, {664, 5}, {663, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(266) ->
	#mon_group {
		id    = 266,
		level = 60,
		type  = boss, 
		pos   = [{665, 1}, {665, 2}, {666, 3}, {666, 4}, {667, 5}, {666, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(267) ->
	#mon_group {
		id    = 267,
		level = 60,
		type  = boss, 
		pos   = [{668, 1}, {668, 2}, {669, 3}, {669, 4}, {670, 5}, {669, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(268) ->
	#mon_group {
		id    = 268,
		level = 60,
		type  = boss, 
		pos   = [{671, 1}, {671, 2}, {672, 3}, {672, 4}, {673, 5}, {672, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(269) ->
	#mon_group {
		id    = 269,
		level = 60,
		type  = boss, 
		pos   = [{674, 1}, {674, 2}, {675, 3}, {675, 4}, {676, 5}, {675, 6}],  
		pts   = 0,
		items = [],
		exp   = 14300
	};
	
get(270) ->
	#mon_group {
		id    = 270,
		level = 65,
		type  = boss, 
		pos   = [{679, 1}, {677, 2}, {678, 3}, {677, 4}, {678, 5}, {677, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(271) ->
	#mon_group {
		id    = 271,
		level = 65,
		type  = boss, 
		pos   = [{682, 1}, {680, 2}, {681, 3}, {680, 4}, {681, 5}, {680, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(272) ->
	#mon_group {
		id    = 272,
		level = 65,
		type  = boss, 
		pos   = [{685, 1}, {683, 2}, {684, 3}, {683, 4}, {684, 5}, {683, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(273) ->
	#mon_group {
		id    = 273,
		level = 65,
		type  = boss, 
		pos   = [{688, 1}, {686, 2}, {687, 3}, {686, 4}, {687, 5}, {686, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(274) ->
	#mon_group {
		id    = 274,
		level = 65,
		type  = boss, 
		pos   = [{691, 1}, {689, 2}, {690, 3}, {689, 4}, {690, 5}, {689, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(275) ->
	#mon_group {
		id    = 275,
		level = 65,
		type  = boss, 
		pos   = [{694, 1}, {692, 2}, {693, 3}, {692, 4}, {693, 5}, {692, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(276) ->
	#mon_group {
		id    = 276,
		level = 65,
		type  = boss, 
		pos   = [{697, 1}, {695, 2}, {696, 3}, {695, 4}, {696, 5}, {695, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(277) ->
	#mon_group {
		id    = 277,
		level = 65,
		type  = boss, 
		pos   = [{700, 1}, {698, 2}, {699, 3}, {698, 4}, {699, 5}, {698, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(278) ->
	#mon_group {
		id    = 278,
		level = 65,
		type  = boss, 
		pos   = [{703, 1}, {701, 2}, {702, 3}, {701, 4}, {702, 5}, {701, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(279) ->
	#mon_group {
		id    = 279,
		level = 65,
		type  = boss, 
		pos   = [{706, 1}, {704, 2}, {705, 3}, {704, 4}, {705, 5}, {704, 6}],  
		pts   = 0,
		items = [],
		exp   = 19000
	};
	
get(280) ->
	#mon_group {
		id    = 280,
		level = 70,
		type  = boss, 
		pos   = [{707, 1}, {708, 2}, {707, 3}, {708, 4}, {709, 5}, {707, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(281) ->
	#mon_group {
		id    = 281,
		level = 70,
		type  = boss, 
		pos   = [{710, 1}, {711, 2}, {710, 3}, {711, 4}, {712, 5}, {710, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(282) ->
	#mon_group {
		id    = 282,
		level = 70,
		type  = boss, 
		pos   = [{713, 1}, {714, 2}, {713, 3}, {714, 4}, {715, 5}, {713, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(283) ->
	#mon_group {
		id    = 283,
		level = 70,
		type  = boss, 
		pos   = [{716, 1}, {717, 2}, {716, 3}, {717, 4}, {718, 5}, {716, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(284) ->
	#mon_group {
		id    = 284,
		level = 70,
		type  = boss, 
		pos   = [{719, 1}, {720, 2}, {719, 3}, {720, 4}, {721, 5}, {719, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(285) ->
	#mon_group {
		id    = 285,
		level = 70,
		type  = boss, 
		pos   = [{722, 1}, {723, 2}, {722, 3}, {723, 4}, {724, 5}, {722, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(286) ->
	#mon_group {
		id    = 286,
		level = 70,
		type  = boss, 
		pos   = [{725, 1}, {726, 2}, {725, 3}, {726, 4}, {727, 5}, {725, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(287) ->
	#mon_group {
		id    = 287,
		level = 70,
		type  = boss, 
		pos   = [{728, 1}, {729, 2}, {728, 3}, {729, 4}, {730, 5}, {728, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(288) ->
	#mon_group {
		id    = 288,
		level = 70,
		type  = boss, 
		pos   = [{731, 1}, {732, 2}, {731, 3}, {732, 4}, {733, 5}, {731, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	
get(289) ->
	#mon_group {
		id    = 289,
		level = 70,
		type  = boss, 
		pos   = [{734, 1}, {735, 2}, {734, 3}, {735, 4}, {736, 5}, {734, 6}],  
		pts   = 0,
		items = [],
		exp   = 25400
	};
	

get(_) ->
	?UNDEFINED.

