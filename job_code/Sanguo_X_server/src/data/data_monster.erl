-module(data_monster).

-compile(export_all).

-include("monster.hrl").

%% 返回所有有野外怪的场景
get_all_scene() ->
	[1100, 1300, 1500].


%%================================================
%% 返回场景中的所有野外怪
get_scene_monster(1100) ->
	[15, 26, 5, 16, 27, 6, 17, 28, 7, 18, 29, 8, 19, 30, 9, 20, 31, 10, 21, 32, 11, 22, 1, 12, 23, 2, 13, 24, 3, 14, 25, 4];

get_scene_monster(1300) ->
	[72, 83, 62, 73, 84, 63, 74, 85, 64, 75, 86, 65, 76, 87, 66, 77, 88, 67, 78, 89, 68, 79, 58, 90, 69, 80, 59, 70, 81, 60, 71, 82, 61];

get_scene_monster(1500) ->
	[128, 139, 118, 129, 140, 119, 130, 141, 120, 131, 142, 121, 132, 143, 122, 133, 144, 123, 134, 145, 124, 135, 146, 125, 136, 115, 147, 126, 137, 116, 127, 138, 117].


%%================================================
%%  获取野外怪详细数据 
get_monster(1100, 1) ->
	#monster{
	coord_x   = 27, 	
		coord_y   = 47, 	 
		id        = 1,         
		group_id  = 1, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 2) ->
	#monster{
	coord_x   = 27, 	
		coord_y   = 48, 	 
		id        = 2,         
		group_id  = 1, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 3) ->
	#monster{
	coord_x   = 31, 	
		coord_y   = 51, 	 
		id        = 3,         
		group_id  = 1, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 4) ->
	#monster{
	coord_x   = 29, 	
		coord_y   = 53, 	 
		id        = 4,         
		group_id  = 1, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 5) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 46, 	 
		id        = 5,         
		group_id  = 2, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 6) ->
	#monster{
	coord_x   = 72, 	
		coord_y   = 46, 	 
		id        = 6,         
		group_id  = 2, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 7) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 44, 	 
		id        = 7,         
		group_id  = 2, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 8) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 50, 	 
		id        = 8,         
		group_id  = 2, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 9) ->
	#monster{
	coord_x   = 166, 	
		coord_y   = 26, 	 
		id        = 9,         
		group_id  = 3, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 10) ->
	#monster{
	coord_x   = 164, 	
		coord_y   = 29, 	 
		id        = 10,         
		group_id  = 3, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 11) ->
	#monster{
	coord_x   = 169, 	
		coord_y   = 28, 	 
		id        = 11,         
		group_id  = 3, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 12) ->
	#monster{
	coord_x   = 167, 	
		coord_y   = 31, 	 
		id        = 12,         
		group_id  = 3, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 13) ->
	#monster{
	coord_x   = 154, 	
		coord_y   = 99, 	 
		id        = 13,         
		group_id  = 4, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 14) ->
	#monster{
	coord_x   = 158, 	
		coord_y   = 100, 	 
		id        = 14,         
		group_id  = 4, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 15) ->
	#monster{
	coord_x   = 154, 	
		coord_y   = 97, 	 
		id        = 15,         
		group_id  = 4, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 16) ->
	#monster{
	coord_x   = 155, 	
		coord_y   = 104, 	 
		id        = 16,         
		group_id  = 4, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 17) ->
	#monster{
	coord_x   = 75, 	
		coord_y   = 78, 	 
		id        = 17,         
		group_id  = 5, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 18) ->
	#monster{
	coord_x   = 72, 	
		coord_y   = 80, 	 
		id        = 18,         
		group_id  = 5, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 19) ->
	#monster{
	coord_x   = 79, 	
		coord_y   = 83, 	 
		id        = 19,         
		group_id  = 5, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 20) ->
	#monster{
	coord_x   = 76, 	
		coord_y   = 79, 	 
		id        = 20,         
		group_id  = 5, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 21) ->
	#monster{
	coord_x   = 9, 	
		coord_y   = 96, 	 
		id        = 21,         
		group_id  = 7, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 22) ->
	#monster{
	coord_x   = 16, 	
		coord_y   = 97, 	 
		id        = 22,         
		group_id  = 7, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 23) ->
	#monster{
	coord_x   = 12, 	
		coord_y   = 99, 	 
		id        = 23,         
		group_id  = 7, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 24) ->
	#monster{
	coord_x   = 15, 	
		coord_y   = 100, 	 
		id        = 24,         
		group_id  = 7, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 25) ->
	#monster{
	coord_x   = 16, 	
		coord_y   = 141, 	 
		id        = 25,         
		group_id  = 6, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 26) ->
	#monster{
	coord_x   = 19, 	
		coord_y   = 138, 	 
		id        = 26,         
		group_id  = 6, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 27) ->
	#monster{
	coord_x   = 19, 	
		coord_y   = 143, 	 
		id        = 27,         
		group_id  = 6, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 28) ->
	#monster{
	coord_x   = 23, 	
		coord_y   = 141, 	 
		id        = 28,         
		group_id  = 6, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 29) ->
	#monster{
	coord_x   = 99, 	
		coord_y   = 127, 	 
		id        = 29,         
		group_id  = 8, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 30) ->
	#monster{
	coord_x   = 99, 	
		coord_y   = 130, 	 
		id        = 30,         
		group_id  = 8, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 31) ->
	#monster{
	coord_x   = 95, 	
		coord_y   = 130, 	 
		id        = 31,         
		group_id  = 8, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1100, 32) ->
	#monster{
	coord_x   = 98, 	
		coord_y   = 133, 	 
		id        = 32,         
		group_id  = 8, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 58) ->
	#monster{
	coord_x   = 27, 	
		coord_y   = 47, 	 
		id        = 58,         
		group_id  = 16, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 59) ->
	#monster{
	coord_x   = 27, 	
		coord_y   = 48, 	 
		id        = 59,         
		group_id  = 16, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 60) ->
	#monster{
	coord_x   = 31, 	
		coord_y   = 51, 	 
		id        = 60,         
		group_id  = 16, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 61) ->
	#monster{
	coord_x   = 29, 	
		coord_y   = 53, 	 
		id        = 61,         
		group_id  = 16, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 62) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 46, 	 
		id        = 62,         
		group_id  = 17, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 63) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 46, 	 
		id        = 63,         
		group_id  = 17, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 64) ->
	#monster{
	coord_x   = 72, 	
		coord_y   = 44, 	 
		id        = 64,         
		group_id  = 17, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 65) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 50, 	 
		id        = 65,         
		group_id  = 17, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 66) ->
	#monster{
	coord_x   = 166, 	
		coord_y   = 26, 	 
		id        = 66,         
		group_id  = 18, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 67) ->
	#monster{
	coord_x   = 164, 	
		coord_y   = 28, 	 
		id        = 67,         
		group_id  = 18, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 68) ->
	#monster{
	coord_x   = 169, 	
		coord_y   = 29, 	 
		id        = 68,         
		group_id  = 18, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 69) ->
	#monster{
	coord_x   = 167, 	
		coord_y   = 31, 	 
		id        = 69,         
		group_id  = 18, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 70) ->
	#monster{
	coord_x   = 154, 	
		coord_y   = 99, 	 
		id        = 70,         
		group_id  = 19, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 71) ->
	#monster{
	coord_x   = 158, 	
		coord_y   = 100, 	 
		id        = 71,         
		group_id  = 19, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 72) ->
	#monster{
	coord_x   = 154, 	
		coord_y   = 97, 	 
		id        = 72,         
		group_id  = 19, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 73) ->
	#monster{
	coord_x   = 155, 	
		coord_y   = 104, 	 
		id        = 73,         
		group_id  = 19, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 74) ->
	#monster{
	coord_x   = 75, 	
		coord_y   = 78, 	 
		id        = 74,         
		group_id  = 20, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 75) ->
	#monster{
	coord_x   = 72, 	
		coord_y   = 80, 	 
		id        = 75,         
		group_id  = 20, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 76) ->
	#monster{
	coord_x   = 79, 	
		coord_y   = 83, 	 
		id        = 76,         
		group_id  = 20, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 77) ->
	#monster{
	coord_x   = 76, 	
		coord_y   = 79, 	 
		id        = 77,         
		group_id  = 20, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 78) ->
	#monster{
	coord_x   = 9, 	
		coord_y   = 96, 	 
		id        = 78,         
		group_id  = 21, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 79) ->
	#monster{
	coord_x   = 16, 	
		coord_y   = 97, 	 
		id        = 79,         
		group_id  = 21, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 80) ->
	#monster{
	coord_x   = 12, 	
		coord_y   = 99, 	 
		id        = 80,         
		group_id  = 21, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 81) ->
	#monster{
	coord_x   = 15, 	
		coord_y   = 100, 	 
		id        = 81,         
		group_id  = 21, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 82) ->
	#monster{
	coord_x   = 16, 	
		coord_y   = 141, 	 
		id        = 82,         
		group_id  = 22, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 83) ->
	#monster{
	coord_x   = 19, 	
		coord_y   = 138, 	 
		id        = 83,         
		group_id  = 22, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 84) ->
	#monster{
	coord_x   = 19, 	
		coord_y   = 143, 	 
		id        = 84,         
		group_id  = 22, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 85) ->
	#monster{
	coord_x   = 23, 	
		coord_y   = 141, 	 
		id        = 85,         
		group_id  = 22, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 86) ->
	#monster{
	coord_x   = 124, 	
		coord_y   = 144, 	 
		id        = 86,         
		group_id  = 23, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 87) ->
	#monster{
	coord_x   = 121, 	
		coord_y   = 146, 	 
		id        = 87,         
		group_id  = 23, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 88) ->
	#monster{
	coord_x   = 129, 	
		coord_y   = 147, 	 
		id        = 88,         
		group_id  = 23, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 89) ->
	#monster{
	coord_x   = 126, 	
		coord_y   = 146, 	 
		id        = 89,         
		group_id  = 24, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1300, 90) ->
	#monster{
	coord_x   = 99, 	
		coord_y   = 127, 	 
		id        = 90,         
		group_id  = 25, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 115) ->
	#monster{
	coord_x   = 27, 	
		coord_y   = 47, 	 
		id        = 115,         
		group_id  = 34, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 116) ->
	#monster{
	coord_x   = 27, 	
		coord_y   = 48, 	 
		id        = 116,         
		group_id  = 34, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 117) ->
	#monster{
	coord_x   = 31, 	
		coord_y   = 51, 	 
		id        = 117,         
		group_id  = 34, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 118) ->
	#monster{
	coord_x   = 29, 	
		coord_y   = 53, 	 
		id        = 118,         
		group_id  = 34, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 119) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 46, 	 
		id        = 119,         
		group_id  = 35, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 120) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 46, 	 
		id        = 120,         
		group_id  = 35, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 121) ->
	#monster{
	coord_x   = 72, 	
		coord_y   = 44, 	 
		id        = 121,         
		group_id  = 35, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 122) ->
	#monster{
	coord_x   = 69, 	
		coord_y   = 50, 	 
		id        = 122,         
		group_id  = 35, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 123) ->
	#monster{
	coord_x   = 166, 	
		coord_y   = 26, 	 
		id        = 123,         
		group_id  = 36, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 124) ->
	#monster{
	coord_x   = 164, 	
		coord_y   = 28, 	 
		id        = 124,         
		group_id  = 36, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 125) ->
	#monster{
	coord_x   = 169, 	
		coord_y   = 29, 	 
		id        = 125,         
		group_id  = 36, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 126) ->
	#monster{
	coord_x   = 167, 	
		coord_y   = 31, 	 
		id        = 126,         
		group_id  = 36, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 127) ->
	#monster{
	coord_x   = 154, 	
		coord_y   = 99, 	 
		id        = 127,         
		group_id  = 37, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 128) ->
	#monster{
	coord_x   = 158, 	
		coord_y   = 100, 	 
		id        = 128,         
		group_id  = 37, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 129) ->
	#monster{
	coord_x   = 154, 	
		coord_y   = 97, 	 
		id        = 129,         
		group_id  = 37, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 130) ->
	#monster{
	coord_x   = 155, 	
		coord_y   = 104, 	 
		id        = 130,         
		group_id  = 37, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 131) ->
	#monster{
	coord_x   = 75, 	
		coord_y   = 78, 	 
		id        = 131,         
		group_id  = 38, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 132) ->
	#monster{
	coord_x   = 72, 	
		coord_y   = 80, 	 
		id        = 132,         
		group_id  = 38, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 133) ->
	#monster{
	coord_x   = 79, 	
		coord_y   = 83, 	 
		id        = 133,         
		group_id  = 38, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 134) ->
	#monster{
	coord_x   = 76, 	
		coord_y   = 79, 	 
		id        = 134,         
		group_id  = 38, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 135) ->
	#monster{
	coord_x   = 9, 	
		coord_y   = 96, 	 
		id        = 135,         
		group_id  = 39, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 136) ->
	#monster{
	coord_x   = 16, 	
		coord_y   = 97, 	 
		id        = 136,         
		group_id  = 39, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 137) ->
	#monster{
	coord_x   = 12, 	
		coord_y   = 99, 	 
		id        = 137,         
		group_id  = 39, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 138) ->
	#monster{
	coord_x   = 15, 	
		coord_y   = 100, 	 
		id        = 138,         
		group_id  = 39, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 139) ->
	#monster{
	coord_x   = 16, 	
		coord_y   = 141, 	 
		id        = 139,         
		group_id  = 40, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 140) ->
	#monster{
	coord_x   = 19, 	
		coord_y   = 138, 	 
		id        = 140,         
		group_id  = 40, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 141) ->
	#monster{
	coord_x   = 19, 	
		coord_y   = 143, 	 
		id        = 141,         
		group_id  = 41, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 142) ->
	#monster{
	coord_x   = 23, 	
		coord_y   = 141, 	 
		id        = 142,         
		group_id  = 41, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 143) ->
	#monster{
	coord_x   = 124, 	
		coord_y   = 144, 	 
		id        = 143,         
		group_id  = 42, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 144) ->
	#monster{
	coord_x   = 121, 	
		coord_y   = 146, 	 
		id        = 144,         
		group_id  = 42, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 145) ->
	#monster{
	coord_x   = 129, 	
		coord_y   = 147, 	 
		id        = 145,         
		group_id  = 42, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 146) ->
	#monster{
	coord_x   = 126, 	
		coord_y   = 146, 	 
		id        = 146,         
		group_id  = 42, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(1500, 147) ->
	#monster{
	coord_x   = 99, 	
		coord_y   = 127, 	 
		id        = 147,         
		group_id  = 43, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 500) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 500,         
		group_id  = 71, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 501) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 501,         
		group_id  = 72, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 502) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 502,         
		group_id  = 73, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 503) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 503,         
		group_id  = 74, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 504) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 504,         
		group_id  = 75, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 505) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 505,         
		group_id  = 76, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 506) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 506,         
		group_id  = 77, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 507) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 507,         
		group_id  = 78, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 508) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 508,         
		group_id  = 79, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 509) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 509,         
		group_id  = 80, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 510) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 510,         
		group_id  = 81, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 511) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 511,         
		group_id  = 82, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 512) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 512,         
		group_id  = 83, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 513) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 513,         
		group_id  = 84, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 514) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 514,         
		group_id  = 85, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 515) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 515,         
		group_id  = 86, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 516) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 516,         
		group_id  = 87, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 517) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 517,         
		group_id  = 88, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 518) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 518,         
		group_id  = 89, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 519) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 519,         
		group_id  = 90, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 520) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 520,         
		group_id  = 91, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 521) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 521,         
		group_id  = 92, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 522) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 522,         
		group_id  = 93, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 523) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 523,         
		group_id  = 94, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 524) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 524,         
		group_id  = 95, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 525) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 525,         
		group_id  = 96, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 526) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 526,         
		group_id  = 97, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 527) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 527,         
		group_id  = 98, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 528) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 528,         
		group_id  = 99, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 529) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 529,         
		group_id  = 100, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 530) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 530,         
		group_id  = 101, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 531) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 531,         
		group_id  = 102, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 532) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 532,         
		group_id  = 103, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 533) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 533,         
		group_id  = 104, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 534) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 534,         
		group_id  = 105, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 535) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 535,         
		group_id  = 106, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 536) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 536,         
		group_id  = 107, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 537) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 537,         
		group_id  = 108, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 538) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 538,         
		group_id  = 109, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 539) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 539,         
		group_id  = 110, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 540) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 540,         
		group_id  = 111, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 541) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 541,         
		group_id  = 112, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 542) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 542,         
		group_id  = 113, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 543) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 543,         
		group_id  = 114, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 544) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 544,         
		group_id  = 115, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 545) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 545,         
		group_id  = 116, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 546) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 546,         
		group_id  = 117, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 547) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 547,         
		group_id  = 118, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 548) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 548,         
		group_id  = 119, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 549) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 549,         
		group_id  = 120, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 550) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 550,         
		group_id  = 121, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 551) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 551,         
		group_id  = 122, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 552) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 552,         
		group_id  = 123, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 553) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 553,         
		group_id  = 124, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 554) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 554,         
		group_id  = 125, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 555) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 555,         
		group_id  = 126, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 556) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 556,         
		group_id  = 127, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 557) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 557,         
		group_id  = 128, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 558) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 558,         
		group_id  = 129, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 559) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 559,         
		group_id  = 130, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 560) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 560,         
		group_id  = 131, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 561) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 561,         
		group_id  = 132, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 562) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 562,         
		group_id  = 133, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 563) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 563,         
		group_id  = 134, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 564) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 564,         
		group_id  = 135, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 565) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 565,         
		group_id  = 136, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 566) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 566,         
		group_id  = 137, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 567) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 567,         
		group_id  = 138, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 568) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 568,         
		group_id  = 139, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 569) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 569,         
		group_id  = 140, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 570) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 570,         
		group_id  = 141, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 571) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 571,         
		group_id  = 142, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 572) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 572,         
		group_id  = 143, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 573) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 573,         
		group_id  = 144, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 574) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 574,         
		group_id  = 145, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 575) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 575,         
		group_id  = 146, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 576) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 576,         
		group_id  = 147, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 577) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 577,         
		group_id  = 148, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 578) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 578,         
		group_id  = 149, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 579) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 579,         
		group_id  = 150, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 580) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 580,         
		group_id  = 151, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 581) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 581,         
		group_id  = 152, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 582) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 582,         
		group_id  = 153, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 583) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 583,         
		group_id  = 154, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 584) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 584,         
		group_id  = 155, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 585) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 585,         
		group_id  = 156, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 586) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 586,         
		group_id  = 157, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 587) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 587,         
		group_id  = 158, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 588) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 588,         
		group_id  = 159, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 589) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 589,         
		group_id  = 160, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 590) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 590,         
		group_id  = 161, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 591) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 591,         
		group_id  = 162, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 592) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 592,         
		group_id  = 163, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 593) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 593,         
		group_id  = 164, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 594) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 594,         
		group_id  = 165, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 595) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 595,         
		group_id  = 166, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 596) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 596,         
		group_id  = 167, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 597) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 597,         
		group_id  = 168, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 598) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 598,         
		group_id  = 169, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 599) ->
	#monster{
	coord_x   = 22, 	
		coord_y   = 62, 	 
		id        = 599,         
		group_id  = 170, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 600) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 600,         
		group_id  = 181, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 601) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 601,         
		group_id  = 182, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 602) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 602,         
		group_id  = 183, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 603) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 603,         
		group_id  = 184, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 604) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 604,         
		group_id  = 185, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 605) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 605,         
		group_id  = 186, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 606) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 606,         
		group_id  = 187, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 607) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 607,         
		group_id  = 188, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 608) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 608,         
		group_id  = 189, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 609) ->
	#monster{
	coord_x   = 0, 	
		coord_y   = 0, 	 
		id        = 609,         
		group_id  = 190, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 610) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 610,         
		group_id  = 171, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 611) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 611,         
		group_id  = 172, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 612) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 612,         
		group_id  = 173, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 613) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 613,         
		group_id  = 174, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 614) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 614,         
		group_id  = 175, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 615) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 615,         
		group_id  = 176, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 616) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 616,         
		group_id  = 177, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 617) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 617,         
		group_id  = 178, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 618) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 618,         
		group_id  = 179, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3100, 619) ->
	#monster{
	coord_x   = 25, 	
		coord_y   = 67, 	 
		id        = 619,         
		group_id  = 180, 
		type      = 0,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	};

get_monster(3000, 653) ->
	#monster{
	coord_x   = 62, 	
		coord_y   = 32, 	 
		id        = 653,         
		group_id  = 1000, 
		type      = 1,       
		category  = 2, 
		radius    = 3,
		full_path = {}      
	}.


%%================================================
