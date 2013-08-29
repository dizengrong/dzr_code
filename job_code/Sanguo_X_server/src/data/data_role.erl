-module(data_role).

-compile(export_all).

-include("common.hrl").

%% 获取武将记录
get(1) ->
	 #role{
		key                = {0, 1},	
		gd_roleRank        = 1,
		gd_name            = "虎卫男",		
		gd_careerID        = 1,	
		gd_roleSex         = 1,
		
		gd_liliang         = 45,		
		gd_yuansheng       = 45,
		gd_tipo            = 53,		 
		gd_minjie          = 15,
		
		gd_liliangTalent   = 35,
		gd_yuanshengTalent = 32,
		gd_tipoTalent      = 50,
		gd_minjieTalent    = 15,
		
		gd_mingzhong       = 60,
		gd_shanbi          = 40,	
		gd_baoji           = 40,
		gd_xingyun         = 60,
		gd_zhiming         = 22,
		gd_gedang          = 60,	
		gd_fanji           = 20,
		gd_pojia           = 15,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [106001,107001,108001,105001,104001,101001],
		star_lv           =  0
};

get(2) ->
	 #role{
		key                = {0, 2},	
		gd_roleRank        = 1,
		gd_name            = "虎卫女",		
		gd_careerID        = 1,	
		gd_roleSex         = 2,
		
		gd_liliang         = 45,		
		gd_yuansheng       = 45,
		gd_tipo            = 53,		 
		gd_minjie          = 15,
		
		gd_liliangTalent   = 35,
		gd_yuanshengTalent = 32,
		gd_tipoTalent      = 50,
		gd_minjieTalent    = 15,
		
		gd_mingzhong       = 60,
		gd_shanbi          = 40,	
		gd_baoji           = 40,
		gd_xingyun         = 60,
		gd_zhiming         = 22,
		gd_gedang          = 60,	
		gd_fanji           = 20,
		gd_pojia           = 15,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [106001,107001,108001,105001,104001,101001],
		star_lv           =  0
};

get(3) ->
	 #role{
		key                = {0, 3},	
		gd_roleRank        = 1,
		gd_name            = "猛将男",		
		gd_careerID        = 2,	
		gd_roleSex         = 1,
		
		gd_liliang         = 50,		
		gd_yuansheng       = 40,
		gd_tipo            = 43,		 
		gd_minjie          = 35,
		
		gd_liliangTalent   = 40,
		gd_yuanshengTalent = 32,
		gd_tipoTalent      = 40,
		gd_minjieTalent    = 25,
		
		gd_mingzhong       = 70,
		gd_shanbi          = 30,	
		gd_baoji           = 45,
		gd_xingyun         = 55,
		gd_zhiming         = 36,
		gd_gedang          = 30,	
		gd_fanji           = 30,
		gd_pojia           = 30,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [111001,112001,113001,110001,109001,102001],
		star_lv           =  0
};

get(4) ->
	 #role{
		key                = {0, 4},	
		gd_roleRank        = 1,
		gd_name            = "猛将女",		
		gd_careerID        = 2,	
		gd_roleSex         = 2,
		
		gd_liliang         = 50,		
		gd_yuansheng       = 40,
		gd_tipo            = 43,		 
		gd_minjie          = 35,
		
		gd_liliangTalent   = 40,
		gd_yuanshengTalent = 32,
		gd_tipoTalent      = 40,
		gd_minjieTalent    = 25,
		
		gd_mingzhong       = 70,
		gd_shanbi          = 30,	
		gd_baoji           = 45,
		gd_xingyun         = 55,
		gd_zhiming         = 36,
		gd_gedang          = 30,	
		gd_fanji           = 30,
		gd_pojia           = 30,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [111001,112001,113001,110001,109001,102001],
		star_lv           =  0
};

get(5) ->
	 #role{
		key                = {0, 5},	
		gd_roleRank        = 1,
		gd_name            = "军师男",		
		gd_careerID        = 3,	
		gd_roleSex         = 1,
		
		gd_liliang         = 40,		
		gd_yuansheng       = 50,
		gd_tipo            = 37,		 
		gd_minjie          = 33,
		
		gd_liliangTalent   = 30,
		gd_yuanshengTalent = 40,
		gd_tipoTalent      = 35,
		gd_minjieTalent    = 20,
		
		gd_mingzhong       = 65,
		gd_shanbi          = 35,	
		gd_baoji           = 56,
		gd_xingyun         = 40,
		gd_zhiming         = 58,
		gd_gedang          = 21,	
		gd_fanji           = 36,
		gd_pojia           = 20,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [116001,117001,118001,115001,114001,103001],
		star_lv           =  0
};

get(6) ->
	 #role{
		key                = {0, 6},	
		gd_roleRank        = 1,
		gd_name            = "军师女",		
		gd_careerID        = 3,	
		gd_roleSex         = 2,
		
		gd_liliang         = 40,		
		gd_yuansheng       = 50,
		gd_tipo            = 37,		 
		gd_minjie          = 33,
		
		gd_liliangTalent   = 30,
		gd_yuanshengTalent = 40,
		gd_tipoTalent      = 35,
		gd_minjieTalent    = 20,
		
		gd_mingzhong       = 65,
		gd_shanbi          = 35,	
		gd_baoji           = 56,
		gd_xingyun         = 40,
		gd_zhiming         = 58,
		gd_gedang          = 21,	
		gd_fanji           = 36,
		gd_pojia           = 20,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [116001,117001,118001,115001,114001,103001],
		star_lv           =  0
};

get(7) ->
	 #role{
		key                = {0, 7},	
		gd_roleRank        = 0,
		gd_name            = "马云禄",		
		gd_careerID        = 1,	
		gd_roleSex         = 2,
		
		gd_liliang         = 21,		
		gd_yuansheng       = 21,
		gd_tipo            = 27,		 
		gd_minjie          = 16,
		
		gd_liliangTalent   = 20,
		gd_yuanshengTalent = 20,
		gd_tipoTalent      = 25,
		gd_minjieTalent    = 15,
		
		gd_mingzhong       = 50,
		gd_shanbi          = 25,	
		gd_baoji           = 30,
		gd_xingyun         = 58,
		gd_zhiming         = 8,
		gd_gedang          = 30,	
		gd_fanji           = 8,
		gd_pojia           = 8,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [225001],
		star_lv           =  1
};

get(8) ->
	 #role{
		key                = {0, 8},	
		gd_roleRank        = 0,
		gd_name            = "华雄",		
		gd_careerID        = 2,	
		gd_roleSex         = 1,
		
		gd_liliang         = 26,		
		gd_yuansheng       = 16,
		gd_tipo            = 22,		 
		gd_minjie          = 21,
		
		gd_liliangTalent   = 25,
		gd_yuanshengTalent = 15,
		gd_tipoTalent      = 20,
		gd_minjieTalent    = 20,
		
		gd_mingzhong       = 58,
		gd_shanbi          = 20,	
		gd_baoji           = 33,
		gd_xingyun         = 53,
		gd_zhiming         = 18,
		gd_gedang          = 18,	
		gd_fanji           = 30,
		gd_pojia           = 30,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [230001],
		star_lv           =  1
};

get(9) ->
	 #role{
		key                = {0, 9},	
		gd_roleRank        = 0,
		gd_name            = "徐庶",		
		gd_careerID        = 3,	
		gd_roleSex         = 1,
		
		gd_liliang         = 16,		
		gd_yuansheng       = 27,
		gd_tipo            = 19,		 
		gd_minjie          = 23,
		
		gd_liliangTalent   = 15,
		gd_yuanshengTalent = 25,
		gd_tipoTalent      = 15,
		gd_minjieTalent    = 25,
		
		gd_mingzhong       = 53,
		gd_shanbi          = 23,	
		gd_baoji           = 38,
		gd_xingyun         = 50,
		gd_zhiming         = 30,
		gd_gedang          = 8,	
		gd_fanji           = 18,
		gd_pojia           = 8,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [240001],
		star_lv           =  1
};

get(10) ->
	 #role{
		key                = {0, 10},	
		gd_roleRank        = 0,
		gd_name            = "周仓",		
		gd_careerID        = 1,	
		gd_roleSex         = 1,
		
		gd_liliang         = 34,		
		gd_yuansheng       = 33,
		gd_tipo            = 42,		 
		gd_minjie          = 26,
		
		gd_liliangTalent   = 32,
		gd_yuanshengTalent = 32,
		gd_tipoTalent      = 40,
		gd_minjieTalent    = 24,
		
		gd_mingzhong       = 54,
		gd_shanbi          = 29,	
		gd_baoji           = 34,
		gd_xingyun         = 62,
		gd_zhiming         = 12,
		gd_gedang          = 48,	
		gd_fanji           = 12,
		gd_pojia           = 12,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [226001],
		star_lv           =  2
};

get(11) ->
	 #role{
		key                = {0, 11},	
		gd_roleRank        = 0,
		gd_name            = "袁绍",		
		gd_careerID        = 2,	
		gd_roleSex         = 1,
		
		gd_liliang         = 42,		
		gd_yuansheng       = 25,
		gd_tipo            = 34,		 
		gd_minjie          = 34,
		
		gd_liliangTalent   = 40,
		gd_yuanshengTalent = 24,
		gd_tipoTalent      = 32,
		gd_minjieTalent    = 32,
		
		gd_mingzhong       = 62,
		gd_shanbi          = 24,	
		gd_baoji           = 37,
		gd_xingyun         = 57,
		gd_zhiming         = 29,
		gd_gedang          = 29,	
		gd_fanji           = 48,
		gd_pojia           = 48,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [233001],
		star_lv           =  2
};

get(12) ->
	 #role{
		key                = {0, 12},	
		gd_roleRank        = 0,
		gd_name            = "夏侯惇",		
		gd_careerID        = 1,	
		gd_roleSex         = 1,
		
		gd_liliang         = 34,		
		gd_yuansheng       = 33,
		gd_tipo            = 42,		 
		gd_minjie          = 26,
		
		gd_liliangTalent   = 32,
		gd_yuanshengTalent = 32,
		gd_tipoTalent      = 40,
		gd_minjieTalent    = 24,
		
		gd_mingzhong       = 58,
		gd_shanbi          = 33,	
		gd_baoji           = 38,
		gd_xingyun         = 66,
		gd_zhiming         = 12,
		gd_gedang          = 48,	
		gd_fanji           = 12,
		gd_pojia           = 12,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [229001],
		star_lv           =  2
};

get(13) ->
	 #role{
		key                = {0, 13},	
		gd_roleRank        = 0,
		gd_name            = "鲁肃",		
		gd_careerID        = 3,	
		gd_roleSex         = 1,
		
		gd_liliang         = 26,		
		gd_yuansheng       = 42,
		gd_tipo            = 30,		 
		gd_minjie          = 37,
		
		gd_liliangTalent   = 24,
		gd_yuanshengTalent = 40,
		gd_tipoTalent      = 24,
		gd_minjieTalent    = 40,
		
		gd_mingzhong       = 60,
		gd_shanbi          = 30,	
		gd_baoji           = 45,
		gd_xingyun         = 57,
		gd_zhiming         = 48,
		gd_gedang          = 12,	
		gd_fanji           = 29,
		gd_pojia           = 12,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [238001],
		star_lv           =  2
};

get(14) ->
	 #role{
		key                = {0, 14},	
		gd_roleRank        = 0,
		gd_name            = "曹丕",		
		gd_careerID        = 4,	
		gd_roleSex         = 1,
		
		gd_liliang         = 80,		
		gd_yuansheng       = 100,
		gd_tipo            = 64,		 
		gd_minjie          = 78,
		
		gd_liliangTalent   = 28,
		gd_yuanshengTalent = 32,
		gd_tipoTalent      = 30,
		gd_minjieTalent    = 38,
		
		gd_mingzhong       = 60,
		gd_shanbi          = 44,	
		gd_baoji           = 44,
		gd_xingyun         = 63,
		gd_zhiming         = 15,
		gd_gedang          = 15,	
		gd_fanji           = 15,
		gd_pojia           = 15,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [244001],
		star_lv           =  3
};

get(15) ->
	 #role{
		key                = {0, 15},	
		gd_roleRank        = 0,
		gd_name            = "徐晃",		
		gd_careerID        = 1,	
		gd_roleSex         = 1,
		
		gd_liliang         = 50,		
		gd_yuansheng       = 49,
		gd_tipo            = 64,		 
		gd_minjie          = 38,
		
		gd_liliangTalent   = 48,
		gd_yuanshengTalent = 48,
		gd_tipoTalent      = 60,
		gd_minjieTalent    = 36,
		
		gd_mingzhong       = 62,
		gd_shanbi          = 37,	
		gd_baoji           = 42,
		gd_xingyun         = 70,
		gd_zhiming         = 18,
		gd_gedang          = 72,	
		gd_fanji           = 18,
		gd_pojia           = 18,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [223001],
		star_lv           =  3
};

get(16) ->
	 #role{
		key                = {0, 16},	
		gd_roleRank        = 0,
		gd_name            = "魏延",		
		gd_careerID        = 2,	
		gd_roleSex         = 1,
		
		gd_liliang         = 62,		
		gd_yuansheng       = 37,
		gd_tipo            = 52,		 
		gd_minjie          = 50,
		
		gd_liliangTalent   = 60,
		gd_yuanshengTalent = 36,
		gd_tipoTalent      = 48,
		gd_minjieTalent    = 48,
		
		gd_mingzhong       = 68,
		gd_shanbi          = 30,	
		gd_baoji           = 43,
		gd_xingyun         = 63,
		gd_zhiming         = 43,
		gd_gedang          = 43,	
		gd_fanji           = 72,
		gd_pojia           = 72,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [231001],
		star_lv           =  3
};

get(17) ->
	 #role{
		key                = {0, 17},	
		gd_roleRank        = 0,
		gd_name            = "黄月英",		
		gd_careerID        = 3,	
		gd_roleSex         = 2,
		
		gd_liliang         = 38,		
		gd_yuansheng       = 64,
		gd_tipo            = 44,		 
		gd_minjie          = 55,
		
		gd_liliangTalent   = 36,
		gd_yuanshengTalent = 60,
		gd_tipoTalent      = 36,
		gd_minjieTalent    = 60,
		
		gd_mingzhong       = 66,
		gd_shanbi          = 36,	
		gd_baoji           = 51,
		gd_xingyun         = 63,
		gd_zhiming         = 72,
		gd_gedang          = 18,	
		gd_fanji           = 43,
		gd_pojia           = 18,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [236001],
		star_lv           =  3
};

get(18) ->
	 #role{
		key                = {0, 18},	
		gd_roleRank        = 0,
		gd_name            = "黄忠",		
		gd_careerID        = 2,	
		gd_roleSex         = 1,
		
		gd_liliang         = 94,		
		gd_yuansheng       = 56,
		gd_tipo            = 77,		 
		gd_minjie          = 76,
		
		gd_liliangTalent   = 90,
		gd_yuanshengTalent = 54,
		gd_tipoTalent      = 72,
		gd_minjieTalent    = 72,
		
		gd_mingzhong       = 88,
		gd_shanbi          = 50,	
		gd_baoji           = 63,
		gd_xingyun         = 83,
		gd_zhiming         = 65,
		gd_gedang          = 65,	
		gd_fanji           = 108,
		gd_pojia           = 108,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [234001],
		star_lv           =  5
};

get(19) ->
	 #role{
		key                = {0, 19},	
		gd_roleRank        = 0,
		gd_name            = "大乔",		
		gd_careerID        = 3,	
		gd_roleSex         = 2,
		
		gd_liliang         = 58,		
		gd_yuansheng       = 95,
		gd_tipo            = 67,		 
		gd_minjie          = 83,
		
		gd_liliangTalent   = 54,
		gd_yuanshengTalent = 90,
		gd_tipoTalent      = 54,
		gd_minjieTalent    = 90,
		
		gd_mingzhong       = 86,
		gd_shanbi          = 56,	
		gd_baoji           = 71,
		gd_xingyun         = 83,
		gd_zhiming         = 108,
		gd_gedang          = 27,	
		gd_fanji           = 65,
		gd_pojia           = 27,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [239001],
		star_lv           =  5
};

get(20) ->
	 #role{
		key                = {0, 20},	
		gd_roleRank        = 0,
		gd_name            = "郭嘉",		
		gd_careerID        = 4,	
		gd_roleSex         = 1,
		
		gd_liliang         = 144,		
		gd_yuansheng       = 180,
		gd_tipo            = 115,		 
		gd_minjie          = 140,
		
		gd_liliangTalent   = 50,
		gd_yuanshengTalent = 58,
		gd_tipoTalent      = 54,
		gd_minjieTalent    = 68,
		
		gd_mingzhong       = 80,
		gd_shanbi          = 64,	
		gd_baoji           = 64,
		gd_xingyun         = 83,
		gd_zhiming         = 27,
		gd_gedang          = 27,	
		gd_fanji           = 27,
		gd_pojia           = 27,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [246001],
		star_lv           =  5
};

get(21) ->
	 #role{
		key                = {0, 21},	
		gd_roleRank        = 0,
		gd_name            = "张辽",		
		gd_careerID        = 1,	
		gd_roleSex         = 1,
		
		gd_liliang         = 67,		
		gd_yuansheng       = 66,
		gd_tipo            = 85,		 
		gd_minjie          = 51,
		
		gd_liliangTalent   = 64,
		gd_yuanshengTalent = 64,
		gd_tipoTalent      = 80,
		gd_minjieTalent    = 48,
		
		gd_mingzhong       = 78,
		gd_shanbi          = 53,	
		gd_baoji           = 58,
		gd_xingyun         = 86,
		gd_zhiming         = 24,
		gd_gedang          = 96,	
		gd_fanji           = 24,
		gd_pojia           = 24,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [224001],
		star_lv           =  3.5
};

get(22) ->
	 #role{
		key                = {0, 22},	
		gd_roleRank        = 0,
		gd_name            = "关羽",		
		gd_careerID        = 2,	
		gd_roleSex         = 1,
		
		gd_liliang         = 83,		
		gd_yuansheng       = 50,
		gd_tipo            = 69,		 
		gd_minjie          = 67,
		
		gd_liliangTalent   = 80,
		gd_yuanshengTalent = 48,
		gd_tipoTalent      = 64,
		gd_minjieTalent    = 64,
		
		gd_mingzhong       = 85,
		gd_shanbi          = 47,	
		gd_baoji           = 60,
		gd_xingyun         = 80,
		gd_zhiming         = 58,
		gd_gedang          = 58,	
		gd_fanji           = 96,
		gd_pojia           = 96,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [235001],
		star_lv           =  4
};

get(23) ->
	 #role{
		key                = {0, 23},	
		gd_roleRank        = 0,
		gd_name            = "貂蝉",		
		gd_careerID        = 3,	
		gd_roleSex         = 2,
		
		gd_liliang         = 51,		
		gd_yuansheng       = 85,
		gd_tipo            = 59,		 
		gd_minjie          = 74,
		
		gd_liliangTalent   = 48,
		gd_yuanshengTalent = 80,
		gd_tipoTalent      = 48,
		gd_minjieTalent    = 80,
		
		gd_mingzhong       = 83,
		gd_shanbi          = 53,	
		gd_baoji           = 68,
		gd_xingyun         = 80,
		gd_zhiming         = 96,
		gd_gedang          = 24,	
		gd_fanji           = 58,
		gd_pojia           = 24,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [241001],
		star_lv           =  4.2
};

get(24) ->
	 #role{
		key                = {0, 24},	
		gd_roleRank        = 0,
		gd_name            = "诸葛亮",		
		gd_careerID        = 4,	
		gd_roleSex         = 1,
		
		gd_liliang         = 128,		
		gd_yuansheng       = 160,
		gd_tipo            = 102,		 
		gd_minjie          = 125,
		
		gd_liliangTalent   = 45,
		gd_yuanshengTalent = 51,
		gd_tipoTalent      = 48,
		gd_minjieTalent    = 61,
		
		gd_mingzhong       = 77,
		gd_shanbi          = 61,	
		gd_baoji           = 61,
		gd_xingyun         = 80,
		gd_zhiming         = 24,
		gd_gedang          = 24,	
		gd_fanji           = 24,
		gd_pojia           = 24,	
		
		gd_roleLevel       = 1,
		gd_maxHp           = 0,
		gd_currentHp       = 0,
		gd_skill           = [242001],
		star_lv           =  3.8
}.


%%================================================
%% 获取所有非主角武将id
get_all_id() -> 
	[7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24].


%%================================================
%% 获取武将的招募条件，返回：{官阶需求, 君威需求, 银币需求}
requirement(7) -> {1, 0, 100};

requirement(8) -> {2, 0, 5000};

requirement(9) -> {2, 0, 8000};

requirement(10) -> {4, 0, 20000};

requirement(11) -> {4, 0, 40000};

requirement(12) -> {7, 0, 80000};

requirement(13) -> {7, 0, 90000};

requirement(14) -> {7, 0, 100000};

requirement(15) -> {10, 0, 120000};

requirement(16) -> {10, 0, 150000};

requirement(17) -> {10, 0, 180000};

requirement(18) -> {13, 0, 230000};

requirement(19) -> {13, 0, 280000};

requirement(20) -> {13, 0, 300000};

requirement(21) -> {0, 680, 0};

requirement(22) -> {0, 3880, 0};

requirement(23) -> {0, 6380, 0};

requirement(24) -> {0, 1980, 0}.


%%================================================
%% 升级时4个基础属性的成长值和气血成长值
get_base_attri_added(1) -> [1.5, 1.3, 3, 2, 16];

get_base_attri_added(2) -> [1.5, 1.3, 3, 2, 16];

get_base_attri_added(3) -> [2, 1.2, 2, 2, 12];

get_base_attri_added(4) -> [2, 1.2, 2, 2, 12];

get_base_attri_added(5) -> [1.4, 2.3, 1.8, 2, 10];

get_base_attri_added(6) -> [1.4, 2.3, 1.8, 2, 10];

get_base_attri_added(7) -> [0, 0, 0, 0, 15];

get_base_attri_added(8) -> [0, 0, 0, 0, 9];

get_base_attri_added(9) -> [0, 0, 0, 0, 8];

get_base_attri_added(10) -> [0, 0, 0, 0, 17];

get_base_attri_added(11) -> [0, 0, 0, 0, 11];

get_base_attri_added(12) -> [0, 0, 0, 0, 20];

get_base_attri_added(13) -> [0, 0, 0, 0, 10];

get_base_attri_added(14) -> [0, 0, 0, 0, 12];

get_base_attri_added(15) -> [0, 0, 0, 0, 25];

get_base_attri_added(16) -> [0, 0, 0, 0, 16];

get_base_attri_added(17) -> [0, 0, 0, 0, 12];

get_base_attri_added(18) -> [0, 0, 0, 0, 20];

get_base_attri_added(19) -> [0, 0, 0, 0, 16];

get_base_attri_added(20) -> [0, 0, 0, 0, 16];

get_base_attri_added(21) -> [0, 0, 0, 0, 30];

get_base_attri_added(22) -> [0, 0, 0, 0, 19];

get_base_attri_added(23) -> [0, 0, 0, 0, 15];

get_base_attri_added(24) -> [0, 0, 0, 0, 16].


%%================================================
%% 返回：{培养总和的平均值，奖励值，下一个标识}
foster_flag(1) -> {100, 10, 2};

foster_flag(2) -> {200, 20, 3};

foster_flag(3) -> {300, 30, 4};

foster_flag(4) -> {400, 40, 5};

foster_flag(5) -> {500, 50, 6};

foster_flag(6) -> {600, 60, 7};

foster_flag(7) -> {700, 70, 8};

foster_flag(8) -> {800, 90, 8}.


%%================================================
%% 返回：培养概率记录
foster_rate(1) ->
	#foster_rate{
		liliang   = 95,
		yuansheng = 85,
		tipo      = 100,
		minjie    = 80
	};

foster_rate(2) ->
	#foster_rate{
		liliang   = 100,
		yuansheng = 80,
		tipo      = 85,
		minjie    = 95
	};

foster_rate(3) ->
	#foster_rate{
		liliang   = 80,
		yuansheng = 100,
		tipo      = 80,
		minjie    = 100
	};

foster_rate(4) ->
	#foster_rate{
		liliang   = 80,
		yuansheng = 100,
		tipo      = 80,
		minjie    = 80
	}.


%%================================================
%% 
%% 最大血量
%% 力量：A1，元神：A2，体魄：A3，敏捷：A4,力量天赋：B1，元神天赋：B2，体魄天赋：B3，敏捷天赋：B4
get_added_hp(A3,B3) -> 10.938*A3*(1+0.003*B3).

%% 物理攻击
%% 力量：A1，元神：A2，体魄：A3，敏捷：A4,力量天赋：B1，元神天赋：B2，体魄天赋：B3，敏捷天赋：B4
get_added_p_att(A1,B1) -> 4.375*A1*(1+0.003*B1).

%% 物理防御
%% 力量：A1，元神：A2，体魄：A3，敏捷：A4,力量天赋：B1，元神天赋：B2，体魄天赋：B3，敏捷天赋：B4
get_added_p_def(A1,B1) -> 7.875*A1*(1+0.003*B1).

%% 法术攻击
%% 力量：A1，元神：A2，体魄：A3，敏捷：A4,力量天赋：B1，元神天赋：B2，体魄天赋：B3，敏捷天赋：B4
get_added_m_att(A2,B2) -> 4.375*A2*(1+0.003*B2).

%% 法术防御
%% 力量：A1，元神：A2，体魄：A3，敏捷：A4,力量天赋：B1，元神天赋：B2，体魄天赋：B3，敏捷天赋：B4
get_added_m_def(A2,B2) -> 7.875*A2*(1+0.003*B2).

%% 速度
%% 力量：A1，元神：A2，体魄：A3，敏捷：A4,力量天赋：B1，元神天赋：B2，体魄天赋：B3，敏捷天赋：B4
get_added_speed(A4,B4) -> 3.15*A4*(1+0.003*B4).


%%================================================
%% 根据总经验获取对应的等级
get_level(TotalExp) when TotalExp >= 2300633028 -> 100;

get_level(TotalExp) when TotalExp >= 2158408068 -> 99;

get_level(TotalExp) when TotalExp >= 2025827748 -> 98;

get_level(TotalExp) when TotalExp >= 1902623268 -> 97;

get_level(TotalExp) when TotalExp >= 1788535428 -> 96;

get_level(TotalExp) when TotalExp >= 1679324460 -> 95;

get_level(TotalExp) when TotalExp >= 1574858364 -> 94;

get_level(TotalExp) when TotalExp >= 1475005140 -> 93;

get_level(TotalExp) when TotalExp >= 1379632788 -> 92;

get_level(TotalExp) when TotalExp >= 1288609308 -> 91;

get_level(TotalExp) when TotalExp >= 1201802700 -> 90;

get_level(TotalExp) when TotalExp >= 1119080964 -> 89;

get_level(TotalExp) when TotalExp >= 1040671452 -> 88;

get_level(TotalExp) when TotalExp >= 966430164 -> 87;

get_level(TotalExp) when TotalExp >= 896213100 -> 86;

get_level(TotalExp) when TotalExp >= 829876260 -> 85;

get_level(TotalExp) when TotalExp >= 767275644 -> 84;

get_level(TotalExp) when TotalExp >= 708267252 -> 83;

get_level(TotalExp) when TotalExp >= 652707084 -> 82;

get_level(TotalExp) when TotalExp >= 600454020 -> 81;

get_level(TotalExp) when TotalExp >= 551366940 -> 80;

get_level(TotalExp) when TotalExp >= 505307604 -> 79;

get_level(TotalExp) when TotalExp >= 462143532 -> 78;

get_level(TotalExp) when TotalExp >= 421748004 -> 77;

get_level(TotalExp) when TotalExp >= 384000060 -> 76;

get_level(TotalExp) when TotalExp >= 348781620 -> 75;

get_level(TotalExp) when TotalExp >= 315977484 -> 74;

get_level(TotalExp) when TotalExp >= 285475332 -> 73;

get_level(TotalExp) when TotalExp >= 257165724 -> 72;

get_level(TotalExp) when TotalExp >= 230944980 -> 71;

get_level(TotalExp) when TotalExp >= 206715180 -> 70;

get_level(TotalExp) when TotalExp >= 184381284 -> 69;

get_level(TotalExp) when TotalExp >= 163851132 -> 68;

get_level(TotalExp) when TotalExp >= 145032564 -> 67;

get_level(TotalExp) when TotalExp >= 127839180 -> 66;

get_level(TotalExp) when TotalExp >= 112184580 -> 65;

get_level(TotalExp) when TotalExp >= 97982364 -> 64;

get_level(TotalExp) when TotalExp >= 85149012 -> 63;

get_level(TotalExp) when TotalExp >= 73603884 -> 62;

get_level(TotalExp) when TotalExp >= 63266340 -> 61;

get_level(TotalExp) when TotalExp >= 54058620 -> 60;

get_level(TotalExp) when TotalExp >= 45905844 -> 59;

get_level(TotalExp) when TotalExp >= 38656740 -> 58;

get_level(TotalExp) when TotalExp >= 32253228 -> 57;

get_level(TotalExp) when TotalExp >= 26639868 -> 56;

get_level(TotalExp) when TotalExp >= 21763860 -> 55;

get_level(TotalExp) when TotalExp >= 17572404 -> 54;

get_level(TotalExp) when TotalExp >= 14012700 -> 53;

get_level(TotalExp) when TotalExp >= 11031948 -> 52;

get_level(TotalExp) when TotalExp >= 8577348 -> 51;

get_level(TotalExp) when TotalExp >= 6596100 -> 50;

get_level(TotalExp) when TotalExp >= 5073636 -> 49;

get_level(TotalExp) when TotalExp >= 3988908 -> 48;

get_level(TotalExp) when TotalExp >= 3232332 -> 47;

get_level(TotalExp) when TotalExp >= 2853084 -> 46;

get_level(TotalExp) when TotalExp >= 2488836 -> 45;

get_level(TotalExp) when TotalExp >= 2139588 -> 44;

get_level(TotalExp) when TotalExp >= 1802340 -> 43;

get_level(TotalExp) when TotalExp >= 1591560 -> 42;

get_level(TotalExp) when TotalExp >= 1389780 -> 41;

get_level(TotalExp) when TotalExp >= 1197000 -> 40;

get_level(TotalExp) when TotalExp >= 1068480 -> 39;

get_level(TotalExp) when TotalExp >= 946960 -> 38;

get_level(TotalExp) when TotalExp >= 832440 -> 37;

get_level(TotalExp) when TotalExp >= 724920 -> 36;

get_level(TotalExp) when TotalExp >= 657720 -> 35;

get_level(TotalExp) when TotalExp >= 595520 -> 34;

get_level(TotalExp) when TotalExp >= 538320 -> 33;

get_level(TotalExp) when TotalExp >= 486120 -> 32;

get_level(TotalExp) when TotalExp >= 438920 -> 31;

get_level(TotalExp) when TotalExp >= 396720 -> 30;

get_level(TotalExp) when TotalExp >= 359520 -> 29;

get_level(TotalExp) when TotalExp >= 324720 -> 28;

get_level(TotalExp) when TotalExp >= 292240 -> 27;

get_level(TotalExp) when TotalExp >= 262000 -> 26;

get_level(TotalExp) when TotalExp >= 233920 -> 25;

get_level(TotalExp) when TotalExp >= 207920 -> 24;

get_level(TotalExp) when TotalExp >= 183920 -> 23;

get_level(TotalExp) when TotalExp >= 161840 -> 22;

get_level(TotalExp) when TotalExp >= 141600 -> 21;

get_level(TotalExp) when TotalExp >= 123120 -> 20;

get_level(TotalExp) when TotalExp >= 106320 -> 19;

get_level(TotalExp) when TotalExp >= 91120 -> 18;

get_level(TotalExp) when TotalExp >= 77440 -> 17;

get_level(TotalExp) when TotalExp >= 65200 -> 16;

get_level(TotalExp) when TotalExp >= 54320 -> 15;

get_level(TotalExp) when TotalExp >= 44720 -> 14;

get_level(TotalExp) when TotalExp >= 36320 -> 13;

get_level(TotalExp) when TotalExp >= 29040 -> 12;

get_level(TotalExp) when TotalExp >= 22800 -> 11;

get_level(TotalExp) when TotalExp >= 17520 -> 10;

get_level(TotalExp) when TotalExp >= 13120 -> 9;

get_level(TotalExp) when TotalExp >= 9520 -> 8;

get_level(TotalExp) when TotalExp >= 6640 -> 7;

get_level(TotalExp) when TotalExp >= 4400 -> 6;

get_level(TotalExp) when TotalExp >= 2720 -> 5;

get_level(TotalExp) when TotalExp >= 1520 -> 4;

get_level(TotalExp) when TotalExp >= 720 -> 3;

get_level(TotalExp) when TotalExp >= 240 -> 2;

get_level(TotalExp) when TotalExp >= 0 -> 1.


%%================================================
%% 角色威望加成
get_weiwang_attri(1) -> 
			#role_update_attri{ 
			     gd_speed      = 71,
gd_maxHp      = 204,
p_def         = 147,
m_def         = 147,
p_att         = 0,
m_att         = 0
		};

get_weiwang_attri(2) -> 
			#role_update_attri{ 
			     gd_speed      = 176,
gd_maxHp      = 508,
p_def         = 366,
m_def         = 366,
p_att         = 0,
m_att         = 0
		};

get_weiwang_attri(3) -> 
			#role_update_attri{ 
			     gd_speed      = 351,
gd_maxHp      = 1016,
p_def         = 732,
m_def         = 732,
p_att         = 0,
m_att         = 0
		};

get_weiwang_attri(4) -> 
			#role_update_attri{ 
			     gd_speed      = 527,
gd_maxHp      = 1524,
p_def         = 1098,
m_def         = 1098,
p_att         = 0,
m_att         = 0
		};

get_weiwang_attri(5) -> 
			#role_update_attri{ 
			     gd_speed      = 702,
gd_maxHp      = 2032,
p_def         = 1463,
m_def         = 1463,
p_att         = 0,
m_att         = 0
		}.


%%================================================
%% get_up_talent_cost(平均天赋) -> 消耗的银币
get_up_talent_cost(0) -> 3747;

get_up_talent_cost(1) -> 3767;

get_up_talent_cost(2) -> 3784;

get_up_talent_cost(3) -> 3805;

get_up_talent_cost(4) -> 3822;

get_up_talent_cost(5) -> 3842;

get_up_talent_cost(6) -> 3862;

get_up_talent_cost(7) -> 3879;

get_up_talent_cost(8) -> 3900;

get_up_talent_cost(9) -> 3920;

get_up_talent_cost(10) -> 3941;

get_up_talent_cost(11) -> 3961;

get_up_talent_cost(12) -> 3978;

get_up_talent_cost(13) -> 3998;

get_up_talent_cost(14) -> 4019;

get_up_talent_cost(15) -> 4039;

get_up_talent_cost(16) -> 4060;

get_up_talent_cost(17) -> 4080;

get_up_talent_cost(18) -> 4100;

get_up_talent_cost(19) -> 4121;

get_up_talent_cost(20) -> 4141;

get_up_talent_cost(21) -> 4896;

get_up_talent_cost(22) -> 4924;

get_up_talent_cost(23) -> 4948;

get_up_talent_cost(24) -> 4972;

get_up_talent_cost(25) -> 4996;

get_up_talent_cost(26) -> 5024;

get_up_talent_cost(27) -> 5048;

get_up_talent_cost(28) -> 5072;

get_up_talent_cost(29) -> 5100;

get_up_talent_cost(30) -> 5124;

get_up_talent_cost(31) -> 5148;

get_up_talent_cost(32) -> 5176;

get_up_talent_cost(33) -> 5200;

get_up_talent_cost(34) -> 5228;

get_up_talent_cost(35) -> 5252;

get_up_talent_cost(36) -> 5280;

get_up_talent_cost(37) -> 5308;

get_up_talent_cost(38) -> 5332;

get_up_talent_cost(39) -> 5360;

get_up_talent_cost(40) -> 5388;

get_up_talent_cost(41) -> 5416;

get_up_talent_cost(42) -> 5440;

get_up_talent_cost(43) -> 5468;

get_up_talent_cost(44) -> 5496;

get_up_talent_cost(45) -> 5524;

get_up_talent_cost(46) -> 5552;

get_up_talent_cost(47) -> 5580;

get_up_talent_cost(48) -> 5608;

get_up_talent_cost(49) -> 5636;

get_up_talent_cost(50) -> 5664;

get_up_talent_cost(51) -> 5692;

get_up_talent_cost(52) -> 5720;

get_up_talent_cost(53) -> 5748;

get_up_talent_cost(54) -> 5780;

get_up_talent_cost(55) -> 5808;

get_up_talent_cost(56) -> 5836;

get_up_talent_cost(57) -> 5868;

get_up_talent_cost(58) -> 5896;

get_up_talent_cost(59) -> 5924;

get_up_talent_cost(60) -> 5956;

get_up_talent_cost(61) -> 5984;

get_up_talent_cost(62) -> 6016;

get_up_talent_cost(63) -> 6044;

get_up_talent_cost(64) -> 6076;

get_up_talent_cost(65) -> 6124;

get_up_talent_cost(66) -> 6176;

get_up_talent_cost(67) -> 6224;

get_up_talent_cost(68) -> 6276;

get_up_talent_cost(69) -> 6324;

get_up_talent_cost(70) -> 6376;

get_up_talent_cost(71) -> 6428;

get_up_talent_cost(72) -> 6480;

get_up_talent_cost(73) -> 6532;

get_up_talent_cost(74) -> 6584;

get_up_talent_cost(75) -> 6636;

get_up_talent_cost(76) -> 6692;

get_up_talent_cost(77) -> 6744;

get_up_talent_cost(78) -> 6800;

get_up_talent_cost(79) -> 6852;

get_up_talent_cost(80) -> 6908;

get_up_talent_cost(81) -> 6964;

get_up_talent_cost(82) -> 7020;

get_up_talent_cost(83) -> 7076;

get_up_talent_cost(84) -> 7136;

get_up_talent_cost(85) -> 7192;

get_up_talent_cost(86) -> 7252;

get_up_talent_cost(87) -> 7308;

get_up_talent_cost(88) -> 7368;

get_up_talent_cost(89) -> 7428;

get_up_talent_cost(90) -> 7488;

get_up_talent_cost(91) -> 7548;

get_up_talent_cost(92) -> 7608;

get_up_talent_cost(93) -> 7668;

get_up_talent_cost(94) -> 7732;

get_up_talent_cost(95) -> 7792;

get_up_talent_cost(96) -> 7856;

get_up_talent_cost(97) -> 7920;

get_up_talent_cost(98) -> 7984;

get_up_talent_cost(99) -> 8048;

get_up_talent_cost(100) -> 8112;

get_up_talent_cost(101) -> 8180;

get_up_talent_cost(102) -> 8244;

get_up_talent_cost(103) -> 8312;

get_up_talent_cost(104) -> 8380;

get_up_talent_cost(105) -> 8444;

get_up_talent_cost(106) -> 8512;

get_up_talent_cost(107) -> 8584;

get_up_talent_cost(108) -> 8652;

get_up_talent_cost(109) -> 8720;

get_up_talent_cost(110) -> 8792;

get_up_talent_cost(111) -> 8864;

get_up_talent_cost(112) -> 8936;

get_up_talent_cost(113) -> 9008;

get_up_talent_cost(114) -> 9080;

get_up_talent_cost(115) -> 9152;

get_up_talent_cost(116) -> 9224;

get_up_talent_cost(117) -> 9300;

get_up_talent_cost(118) -> 9376;

get_up_talent_cost(119) -> 9452;

get_up_talent_cost(120) -> 9528;

get_up_talent_cost(121) -> 9604;

get_up_talent_cost(122) -> 9680;

get_up_talent_cost(123) -> 9760;

get_up_talent_cost(124) -> 9840;

get_up_talent_cost(125) -> 9916;

get_up_talent_cost(126) -> 9996;

get_up_talent_cost(127) -> 10076;

get_up_talent_cost(128) -> 10160;

get_up_talent_cost(129) -> 10240;

get_up_talent_cost(130) -> 10324;

get_up_talent_cost(131) -> 10408;

get_up_talent_cost(132) -> 10492;

get_up_talent_cost(133) -> 10576;

get_up_talent_cost(134) -> 10660;

get_up_talent_cost(135) -> 10748;

get_up_talent_cost(136) -> 10832;

get_up_talent_cost(137) -> 10920;

get_up_talent_cost(138) -> 11008;

get_up_talent_cost(139) -> 11096;

get_up_talent_cost(140) -> 11188;

get_up_talent_cost(141) -> 11276;

get_up_talent_cost(142) -> 11368;

get_up_talent_cost(143) -> 11460;

get_up_talent_cost(144) -> 11552;

get_up_talent_cost(145) -> 11644;

get_up_talent_cost(146) -> 11740;

get_up_talent_cost(147) -> 11836;

get_up_talent_cost(148) -> 11928;

get_up_talent_cost(149) -> 12024;

get_up_talent_cost(150) -> 12124;

get_up_talent_cost(151) -> 12220;

get_up_talent_cost(152) -> 12320;

get_up_talent_cost(153) -> 12420;

get_up_talent_cost(154) -> 12520;

get_up_talent_cost(155) -> 12620;

get_up_talent_cost(156) -> 12720;

get_up_talent_cost(157) -> 12824;

get_up_talent_cost(158) -> 12928;

get_up_talent_cost(159) -> 13032;

get_up_talent_cost(160) -> 13136;

get_up_talent_cost(161) -> 13244;

get_up_talent_cost(162) -> 13348;

get_up_talent_cost(163) -> 13456;

get_up_talent_cost(164) -> 13564;

get_up_talent_cost(165) -> 13676;

get_up_talent_cost(166) -> 13784;

get_up_talent_cost(167) -> 13896;

get_up_talent_cost(168) -> 14008;

get_up_talent_cost(169) -> 14120;

get_up_talent_cost(170) -> 14236;

get_up_talent_cost(171) -> 14352;

get_up_talent_cost(172) -> 14464;

get_up_talent_cost(173) -> 14584;

get_up_talent_cost(174) -> 14700;

get_up_talent_cost(175) -> 14820;

get_up_talent_cost(176) -> 14940;

get_up_talent_cost(177) -> 15060;

get_up_talent_cost(178) -> 15180;

get_up_talent_cost(179) -> 15304;

get_up_talent_cost(180) -> 15428;

get_up_talent_cost(181) -> 15552;

get_up_talent_cost(182) -> 15676;

get_up_talent_cost(183) -> 15804;

get_up_talent_cost(184) -> 15928;

get_up_talent_cost(185) -> 16060;

get_up_talent_cost(186) -> 16188;

get_up_talent_cost(187) -> 16320;

get_up_talent_cost(188) -> 16448;

get_up_talent_cost(189) -> 16584;

get_up_talent_cost(190) -> 16716;

get_up_talent_cost(191) -> 16852;

get_up_talent_cost(192) -> 16988;

get_up_talent_cost(193) -> 17124;

get_up_talent_cost(194) -> 17260;

get_up_talent_cost(195) -> 17400;

get_up_talent_cost(196) -> 17540;

get_up_talent_cost(197) -> 17684;

get_up_talent_cost(198) -> 17824;

get_up_talent_cost(199) -> 17968;

get_up_talent_cost(200) -> 18116;

get_up_talent_cost(201) -> 18260;

get_up_talent_cost(202) -> 18408;

get_up_talent_cost(203) -> 18556;

get_up_talent_cost(204) -> 18704;

get_up_talent_cost(205) -> 18856;

get_up_talent_cost(206) -> 19008;

get_up_talent_cost(207) -> 19160;

get_up_talent_cost(208) -> 19316;

get_up_talent_cost(209) -> 19472;

get_up_talent_cost(210) -> 19628;

get_up_talent_cost(211) -> 19788;

get_up_talent_cost(212) -> 19948;

get_up_talent_cost(213) -> 20108;

get_up_talent_cost(214) -> 20272;

get_up_talent_cost(215) -> 20432;

get_up_talent_cost(216) -> 20600;

get_up_talent_cost(217) -> 20764;

get_up_talent_cost(218) -> 20932;

get_up_talent_cost(219) -> 21100;

get_up_talent_cost(220) -> 21272;

get_up_talent_cost(221) -> 21444;

get_up_talent_cost(222) -> 21616;

get_up_talent_cost(223) -> 21788;

get_up_talent_cost(224) -> 21964;

get_up_talent_cost(225) -> 22144;

get_up_talent_cost(226) -> 22320;

get_up_talent_cost(227) -> 22500;

get_up_talent_cost(228) -> 22684;

get_up_talent_cost(229) -> 22864;

get_up_talent_cost(230) -> 23048;

get_up_talent_cost(231) -> 23236;

get_up_talent_cost(232) -> 23424;

get_up_talent_cost(233) -> 23612;

get_up_talent_cost(234) -> 23804;

get_up_talent_cost(235) -> 23996;

get_up_talent_cost(236) -> 24188;

get_up_talent_cost(237) -> 24384;

get_up_talent_cost(238) -> 24580;

get_up_talent_cost(239) -> 24776;

get_up_talent_cost(240) -> 24976;

get_up_talent_cost(241) -> 25180;

get_up_talent_cost(242) -> 25384;

get_up_talent_cost(243) -> 25588;

get_up_talent_cost(244) -> 25792;

get_up_talent_cost(245) -> 26000;

get_up_talent_cost(246) -> 26212;

get_up_talent_cost(247) -> 26424;

get_up_talent_cost(248) -> 26636;

get_up_talent_cost(249) -> 26852;

get_up_talent_cost(250) -> 27068;

get_up_talent_cost(251) -> 27284;

get_up_talent_cost(252) -> 27504;

get_up_talent_cost(253) -> 27728;

get_up_talent_cost(254) -> 27952;

get_up_talent_cost(255) -> 28176;

get_up_talent_cost(256) -> 28404;

get_up_talent_cost(257) -> 28632;

get_up_talent_cost(258) -> 28864;

get_up_talent_cost(259) -> 29096;

get_up_talent_cost(260) -> 29332;

get_up_talent_cost(261) -> 29568;

get_up_talent_cost(262) -> 29804;

get_up_talent_cost(263) -> 30044;

get_up_talent_cost(264) -> 30288;

get_up_talent_cost(265) -> 30532;

get_up_talent_cost(266) -> 30780;

get_up_talent_cost(267) -> 31028;

get_up_talent_cost(268) -> 31276;

get_up_talent_cost(269) -> 31528;

get_up_talent_cost(270) -> 31784;

get_up_talent_cost(271) -> 32040;

get_up_talent_cost(272) -> 32300;

get_up_talent_cost(273) -> 32560;

get_up_talent_cost(274) -> 32820;

get_up_talent_cost(275) -> 33088;

get_up_talent_cost(276) -> 33352;

get_up_talent_cost(277) -> 33620;

get_up_talent_cost(278) -> 33892;

get_up_talent_cost(279) -> 34168;

get_up_talent_cost(280) -> 34440;

get_up_talent_cost(281) -> 34720;

get_up_talent_cost(282) -> 35000;

get_up_talent_cost(283) -> 35280;

get_up_talent_cost(284) -> 35568;

get_up_talent_cost(285) -> 35852;

get_up_talent_cost(286) -> 36144;

get_up_talent_cost(287) -> 36432;

get_up_talent_cost(288) -> 36728;

get_up_talent_cost(289) -> 37024;

get_up_talent_cost(290) -> 37324;

get_up_talent_cost(291) -> 37624;

get_up_talent_cost(292) -> 37928;

get_up_talent_cost(293) -> 38232;

get_up_talent_cost(294) -> 38540;

get_up_talent_cost(295) -> 38852;

get_up_talent_cost(296) -> 39164;

get_up_talent_cost(297) -> 39480;

get_up_talent_cost(298) -> 39800;

get_up_talent_cost(299) -> 40120;

get_up_talent_cost(300) -> 40444;

get_up_talent_cost(301) -> 40772;

get_up_talent_cost(302) -> 41100;

get_up_talent_cost(303) -> 41432;

get_up_talent_cost(304) -> 41764;

get_up_talent_cost(305) -> 42100;

get_up_talent_cost(306) -> 42440;

get_up_talent_cost(307) -> 42784;

get_up_talent_cost(308) -> 43128;

get_up_talent_cost(309) -> 43476;

get_up_talent_cost(310) -> 43828;

get_up_talent_cost(311) -> 44180;

get_up_talent_cost(312) -> 44536;

get_up_talent_cost(313) -> 44896;

get_up_talent_cost(314) -> 45256;

get_up_talent_cost(315) -> 45624;

get_up_talent_cost(316) -> 45992;

get_up_talent_cost(317) -> 46360;

get_up_talent_cost(318) -> 46736;

get_up_talent_cost(319) -> 47112;

get_up_talent_cost(320) -> 47492;

get_up_talent_cost(321) -> 47876;

get_up_talent_cost(322) -> 48260;

get_up_talent_cost(323) -> 48652;

get_up_talent_cost(324) -> 49044;

get_up_talent_cost(325) -> 49440;

get_up_talent_cost(326) -> 49836;

get_up_talent_cost(327) -> 50240;

get_up_talent_cost(328) -> 50644;

get_up_talent_cost(329) -> 51052;

get_up_talent_cost(330) -> 51464;

get_up_talent_cost(331) -> 51880;

get_up_talent_cost(332) -> 52296;

get_up_talent_cost(333) -> 52720;

get_up_talent_cost(334) -> 53144;

get_up_talent_cost(335) -> 53572;

get_up_talent_cost(336) -> 54004;

get_up_talent_cost(337) -> 54440;

get_up_talent_cost(338) -> 54880;

get_up_talent_cost(339) -> 55320;

get_up_talent_cost(340) -> 55768;

get_up_talent_cost(341) -> 56216;

get_up_talent_cost(342) -> 56672;

get_up_talent_cost(343) -> 57128;

get_up_talent_cost(344) -> 57588;

get_up_talent_cost(345) -> 58052;

get_up_talent_cost(346) -> 58520;

get_up_talent_cost(347) -> 58992;

get_up_talent_cost(348) -> 59468;

get_up_talent_cost(349) -> 59948;

get_up_talent_cost(350) -> 60432;

get_up_talent_cost(351) -> 60920;

get_up_talent_cost(352) -> 61412;

get_up_talent_cost(353) -> 61908;

get_up_talent_cost(354) -> 62404;

get_up_talent_cost(355) -> 62908;

get_up_talent_cost(356) -> 63416;

get_up_talent_cost(357) -> 63928;

get_up_talent_cost(358) -> 64444;

get_up_talent_cost(359) -> 64964;

get_up_talent_cost(360) -> 65488;

get_up_talent_cost(361) -> 66016;

get_up_talent_cost(362) -> 66548;

get_up_talent_cost(363) -> 67084;

get_up_talent_cost(364) -> 67624;

get_up_talent_cost(365) -> 68172;

get_up_talent_cost(366) -> 68720;

get_up_talent_cost(367) -> 69276;

get_up_talent_cost(368) -> 69832;

get_up_talent_cost(369) -> 70396;

get_up_talent_cost(370) -> 70964;

get_up_talent_cost(371) -> 71536;

get_up_talent_cost(372) -> 72112;

get_up_talent_cost(373) -> 72696;

get_up_talent_cost(374) -> 73280;

get_up_talent_cost(375) -> 73872;

get_up_talent_cost(376) -> 74468;

get_up_talent_cost(377) -> 75068;

get_up_talent_cost(378) -> 75672;

get_up_talent_cost(379) -> 76284;

get_up_talent_cost(380) -> 76900;

get_up_talent_cost(381) -> 77520;

get_up_talent_cost(382) -> 78144;

get_up_talent_cost(383) -> 78776;

get_up_talent_cost(384) -> 79408;

get_up_talent_cost(385) -> 80048;

get_up_talent_cost(386) -> 80696;

get_up_talent_cost(387) -> 81348;

get_up_talent_cost(388) -> 82004;

get_up_talent_cost(389) -> 82664;

get_up_talent_cost(390) -> 83332;

get_up_talent_cost(391) -> 84004;

get_up_talent_cost(392) -> 84680;

get_up_talent_cost(393) -> 85364;

get_up_talent_cost(394) -> 86052;

get_up_talent_cost(395) -> 86744;

get_up_talent_cost(396) -> 87444;

get_up_talent_cost(397) -> 88148;

get_up_talent_cost(398) -> 88860;

get_up_talent_cost(399) -> 89576;

get_up_talent_cost(400) -> 90300;

get_up_talent_cost(401) -> 91028;

get_up_talent_cost(402) -> 91760;

get_up_talent_cost(403) -> 92500;

get_up_talent_cost(404) -> 93248;

get_up_talent_cost(405) -> 94000;

get_up_talent_cost(406) -> 94756;

get_up_talent_cost(407) -> 95524;

get_up_talent_cost(408) -> 96292;

get_up_talent_cost(409) -> 97068;

get_up_talent_cost(410) -> 97852;

get_up_talent_cost(411) -> 98640;

get_up_talent_cost(412) -> 99436;

get_up_talent_cost(413) -> 100240;

get_up_talent_cost(414) -> 101048;

get_up_talent_cost(415) -> 101860;

get_up_talent_cost(416) -> 102684;

get_up_talent_cost(417) -> 103512;

get_up_talent_cost(418) -> 104344;

get_up_talent_cost(419) -> 105188;

get_up_talent_cost(420) -> 106036;

get_up_talent_cost(421) -> 106892;

get_up_talent_cost(422) -> 107752;

get_up_talent_cost(423) -> 108620;

get_up_talent_cost(424) -> 109496;

get_up_talent_cost(425) -> 110380;

get_up_talent_cost(426) -> 111272;

get_up_talent_cost(427) -> 112168;

get_up_talent_cost(428) -> 113072;

get_up_talent_cost(429) -> 113984;

get_up_talent_cost(430) -> 114904;

get_up_talent_cost(431) -> 115832;

get_up_talent_cost(432) -> 116764;

get_up_talent_cost(433) -> 117708;

get_up_talent_cost(434) -> 118656;

get_up_talent_cost(435) -> 119612;

get_up_talent_cost(436) -> 120576;

get_up_talent_cost(437) -> 121548;

get_up_talent_cost(438) -> 122528;

get_up_talent_cost(439) -> 123520;

get_up_talent_cost(440) -> 124516;

get_up_talent_cost(441) -> 125520;

get_up_talent_cost(442) -> 126532;

get_up_talent_cost(443) -> 127552;

get_up_talent_cost(444) -> 128580;

get_up_talent_cost(445) -> 129616;

get_up_talent_cost(446) -> 130660;

get_up_talent_cost(447) -> 131716;

get_up_talent_cost(448) -> 132776;

get_up_talent_cost(449) -> 133848;

get_up_talent_cost(450) -> 134928;

get_up_talent_cost(451) -> 136016;

get_up_talent_cost(452) -> 137112;

get_up_talent_cost(453) -> 138220;

get_up_talent_cost(454) -> 139332;

get_up_talent_cost(455) -> 140456;

get_up_talent_cost(456) -> 141588;

get_up_talent_cost(457) -> 142732;

get_up_talent_cost(458) -> 143884;

get_up_talent_cost(459) -> 145044;

get_up_talent_cost(460) -> 146212;

get_up_talent_cost(461) -> 147392;

get_up_talent_cost(462) -> 148580;

get_up_talent_cost(463) -> 149780;

get_up_talent_cost(464) -> 150988;

get_up_talent_cost(465) -> 152204;

get_up_talent_cost(466) -> 153432;

get_up_talent_cost(467) -> 154668;

get_up_talent_cost(468) -> 155916;

get_up_talent_cost(469) -> 157172;

get_up_talent_cost(470) -> 158440;

get_up_talent_cost(471) -> 159720;

get_up_talent_cost(472) -> 161008;

get_up_talent_cost(473) -> 162304;

get_up_talent_cost(474) -> 163616;

get_up_talent_cost(475) -> 164932;

get_up_talent_cost(476) -> 166264;

get_up_talent_cost(477) -> 167604;

get_up_talent_cost(478) -> 168956;

get_up_talent_cost(479) -> 170320;

get_up_talent_cost(480) -> 171692;

get_up_talent_cost(481) -> 173076;

get_up_talent_cost(482) -> 174472;

get_up_talent_cost(483) -> 175880;

get_up_talent_cost(484) -> 177300;

get_up_talent_cost(485) -> 178728;

get_up_talent_cost(486) -> 180168;

get_up_talent_cost(487) -> 181624;

get_up_talent_cost(488) -> 183088;

get_up_talent_cost(489) -> 184564;

get_up_talent_cost(490) -> 186052;

get_up_talent_cost(491) -> 187552;

get_up_talent_cost(492) -> 189064;

get_up_talent_cost(493) -> 190588;

get_up_talent_cost(494) -> 192128;

get_up_talent_cost(495) -> 193676;

get_up_talent_cost(496) -> 195240;

get_up_talent_cost(497) -> 196812;

get_up_talent_cost(498) -> 198400;

get_up_talent_cost(499) -> 200000.


%%================================================
%% get_foster_cost(平均属性) -> 消耗的银币
get_foster_cost(0) -> 2038;

get_foster_cost(1) -> 2168;

get_foster_cost(2) -> 2306;

get_foster_cost(3) -> 2453;

get_foster_cost(4) -> 2610;

get_foster_cost(5) -> 2777;

get_foster_cost(6) -> 2954;

get_foster_cost(7) -> 3143;

get_foster_cost(8) -> 3344;

get_foster_cost(9) -> 3557;

get_foster_cost(10) -> 3784;

get_foster_cost(11) -> 4026;

get_foster_cost(12) -> 4283;

get_foster_cost(13) -> 4556;

get_foster_cost(14) -> 4847;

get_foster_cost(15) -> 5156;

get_foster_cost(16) -> 5485;

get_foster_cost(17) -> 5835;

get_foster_cost(18) -> 6207;

get_foster_cost(19) -> 6603;

get_foster_cost(20) -> 7024;

get_foster_cost(21) -> 7044;

get_foster_cost(22) -> 7064;

get_foster_cost(23) -> 7088;

get_foster_cost(24) -> 7108;

get_foster_cost(25) -> 7128;

get_foster_cost(26) -> 7152;

get_foster_cost(27) -> 7172;

get_foster_cost(28) -> 7196;

get_foster_cost(29) -> 7216;

get_foster_cost(30) -> 7236;

get_foster_cost(31) -> 7260;

get_foster_cost(32) -> 7280;

get_foster_cost(33) -> 7304;

get_foster_cost(34) -> 7324;

get_foster_cost(35) -> 7348;

get_foster_cost(36) -> 7368;

get_foster_cost(37) -> 7392;

get_foster_cost(38) -> 7412;

get_foster_cost(39) -> 7436;

get_foster_cost(40) -> 7460;

get_foster_cost(41) -> 7480;

get_foster_cost(42) -> 7504;

get_foster_cost(43) -> 7528;

get_foster_cost(44) -> 7548;

get_foster_cost(45) -> 7572;

get_foster_cost(46) -> 7596;

get_foster_cost(47) -> 7616;

get_foster_cost(48) -> 7640;

get_foster_cost(49) -> 7664;

get_foster_cost(50) -> 7688;

get_foster_cost(51) -> 7708;

get_foster_cost(52) -> 7732;

get_foster_cost(53) -> 7756;

get_foster_cost(54) -> 7780;

get_foster_cost(55) -> 7804;

get_foster_cost(56) -> 7824;

get_foster_cost(57) -> 7848;

get_foster_cost(58) -> 7872;

get_foster_cost(59) -> 7896;

get_foster_cost(60) -> 7920;

get_foster_cost(61) -> 7944;

get_foster_cost(62) -> 7968;

get_foster_cost(63) -> 7992;

get_foster_cost(64) -> 8016;

get_foster_cost(65) -> 8040;

get_foster_cost(66) -> 8064;

get_foster_cost(67) -> 8088;

get_foster_cost(68) -> 8112;

get_foster_cost(69) -> 8136;

get_foster_cost(70) -> 8164;

get_foster_cost(71) -> 8188;

get_foster_cost(72) -> 8212;

get_foster_cost(73) -> 8236;

get_foster_cost(74) -> 8260;

get_foster_cost(75) -> 8284;

get_foster_cost(76) -> 8312;

get_foster_cost(77) -> 8336;

get_foster_cost(78) -> 8360;

get_foster_cost(79) -> 8384;

get_foster_cost(80) -> 8412;

get_foster_cost(81) -> 8436;

get_foster_cost(82) -> 8460;

get_foster_cost(83) -> 8488;

get_foster_cost(84) -> 8512;

get_foster_cost(85) -> 8540;

get_foster_cost(86) -> 8564;

get_foster_cost(87) -> 8588;

get_foster_cost(88) -> 8616;

get_foster_cost(89) -> 8640;

get_foster_cost(90) -> 8668;

get_foster_cost(91) -> 8692;

get_foster_cost(92) -> 8720;

get_foster_cost(93) -> 8748;

get_foster_cost(94) -> 8772;

get_foster_cost(95) -> 8800;

get_foster_cost(96) -> 8824;

get_foster_cost(97) -> 8852;

get_foster_cost(98) -> 8880;

get_foster_cost(99) -> 8904;

get_foster_cost(100) -> 8932;

get_foster_cost(101) -> 8960;

get_foster_cost(102) -> 8984;

get_foster_cost(103) -> 9012;

get_foster_cost(104) -> 9040;

get_foster_cost(105) -> 9068;

get_foster_cost(106) -> 9096;

get_foster_cost(107) -> 9120;

get_foster_cost(108) -> 9148;

get_foster_cost(109) -> 9176;

get_foster_cost(110) -> 9204;

get_foster_cost(111) -> 9232;

get_foster_cost(112) -> 9260;

get_foster_cost(113) -> 9288;

get_foster_cost(114) -> 9316;

get_foster_cost(115) -> 9344;

get_foster_cost(116) -> 9372;

get_foster_cost(117) -> 9400;

get_foster_cost(118) -> 9428;

get_foster_cost(119) -> 9456;

get_foster_cost(120) -> 9484;

get_foster_cost(121) -> 9512;

get_foster_cost(122) -> 9544;

get_foster_cost(123) -> 9572;

get_foster_cost(124) -> 9600;

get_foster_cost(125) -> 9628;

get_foster_cost(126) -> 9656;

get_foster_cost(127) -> 9688;

get_foster_cost(128) -> 9716;

get_foster_cost(129) -> 9744;

get_foster_cost(130) -> 9776;

get_foster_cost(131) -> 9804;

get_foster_cost(132) -> 9832;

get_foster_cost(133) -> 9864;

get_foster_cost(134) -> 9892;

get_foster_cost(135) -> 9924;

get_foster_cost(136) -> 9952;

get_foster_cost(137) -> 9984;

get_foster_cost(138) -> 10012;

get_foster_cost(139) -> 10044;

get_foster_cost(140) -> 10072;

get_foster_cost(141) -> 10104;

get_foster_cost(142) -> 10132;

get_foster_cost(143) -> 10164;

get_foster_cost(144) -> 10196;

get_foster_cost(145) -> 10224;

get_foster_cost(146) -> 10256;

get_foster_cost(147) -> 10288;

get_foster_cost(148) -> 10316;

get_foster_cost(149) -> 10348;

get_foster_cost(150) -> 10380;

get_foster_cost(151) -> 10412;

get_foster_cost(152) -> 10444;

get_foster_cost(153) -> 10472;

get_foster_cost(154) -> 10504;

get_foster_cost(155) -> 10536;

get_foster_cost(156) -> 10568;

get_foster_cost(157) -> 10600;

get_foster_cost(158) -> 10632;

get_foster_cost(159) -> 10664;

get_foster_cost(160) -> 10696;

get_foster_cost(161) -> 10728;

get_foster_cost(162) -> 10760;

get_foster_cost(163) -> 10792;

get_foster_cost(164) -> 10824;

get_foster_cost(165) -> 10860;

get_foster_cost(166) -> 10892;

get_foster_cost(167) -> 10924;

get_foster_cost(168) -> 10956;

get_foster_cost(169) -> 10988;

get_foster_cost(170) -> 11024;

get_foster_cost(171) -> 11056;

get_foster_cost(172) -> 11088;

get_foster_cost(173) -> 11124;

get_foster_cost(174) -> 11156;

get_foster_cost(175) -> 11188;

get_foster_cost(176) -> 11224;

get_foster_cost(177) -> 11256;

get_foster_cost(178) -> 11292;

get_foster_cost(179) -> 11324;

get_foster_cost(180) -> 11360;

get_foster_cost(181) -> 11392;

get_foster_cost(182) -> 11428;

get_foster_cost(183) -> 11460;

get_foster_cost(184) -> 11496;

get_foster_cost(185) -> 11532;

get_foster_cost(186) -> 11564;

get_foster_cost(187) -> 11600;

get_foster_cost(188) -> 11636;

get_foster_cost(189) -> 11672;

get_foster_cost(190) -> 11704;

get_foster_cost(191) -> 11740;

get_foster_cost(192) -> 11776;

get_foster_cost(193) -> 11812;

get_foster_cost(194) -> 11848;

get_foster_cost(195) -> 11884;

get_foster_cost(196) -> 11920;

get_foster_cost(197) -> 11956;

get_foster_cost(198) -> 11988;

get_foster_cost(199) -> 12028;

get_foster_cost(200) -> 12064;

get_foster_cost(201) -> 12100;

get_foster_cost(202) -> 12136;

get_foster_cost(203) -> 12172;

get_foster_cost(204) -> 12208;

get_foster_cost(205) -> 12244;

get_foster_cost(206) -> 12280;

get_foster_cost(207) -> 12320;

get_foster_cost(208) -> 12356;

get_foster_cost(209) -> 12392;

get_foster_cost(210) -> 12432;

get_foster_cost(211) -> 12468;

get_foster_cost(212) -> 12504;

get_foster_cost(213) -> 12544;

get_foster_cost(214) -> 12580;

get_foster_cost(215) -> 12620;

get_foster_cost(216) -> 12656;

get_foster_cost(217) -> 12696;

get_foster_cost(218) -> 12732;

get_foster_cost(219) -> 12772;

get_foster_cost(220) -> 12808;

get_foster_cost(221) -> 12848;

get_foster_cost(222) -> 12888;

get_foster_cost(223) -> 12924;

get_foster_cost(224) -> 12964;

get_foster_cost(225) -> 13004;

get_foster_cost(226) -> 13044;

get_foster_cost(227) -> 13080;

get_foster_cost(228) -> 13120;

get_foster_cost(229) -> 13160;

get_foster_cost(230) -> 13200;

get_foster_cost(231) -> 13240;

get_foster_cost(232) -> 13280;

get_foster_cost(233) -> 13320;

get_foster_cost(234) -> 13360;

get_foster_cost(235) -> 13400;

get_foster_cost(236) -> 13440;

get_foster_cost(237) -> 13480;

get_foster_cost(238) -> 13520;

get_foster_cost(239) -> 13560;

get_foster_cost(240) -> 13604;

get_foster_cost(241) -> 13644;

get_foster_cost(242) -> 13684;

get_foster_cost(243) -> 13724;

get_foster_cost(244) -> 13768;

get_foster_cost(245) -> 13808;

get_foster_cost(246) -> 13852;

get_foster_cost(247) -> 13892;

get_foster_cost(248) -> 13932;

get_foster_cost(249) -> 13976;

get_foster_cost(250) -> 14016;

get_foster_cost(251) -> 14060;

get_foster_cost(252) -> 14100;

get_foster_cost(253) -> 14144;

get_foster_cost(254) -> 14188;

get_foster_cost(255) -> 14228;

get_foster_cost(256) -> 14272;

get_foster_cost(257) -> 14316;

get_foster_cost(258) -> 14360;

get_foster_cost(259) -> 14400;

get_foster_cost(260) -> 14444;

get_foster_cost(261) -> 14488;

get_foster_cost(262) -> 14532;

get_foster_cost(263) -> 14576;

get_foster_cost(264) -> 14620;

get_foster_cost(265) -> 14664;

get_foster_cost(266) -> 14708;

get_foster_cost(267) -> 14752;

get_foster_cost(268) -> 14796;

get_foster_cost(269) -> 14840;

get_foster_cost(270) -> 14884;

get_foster_cost(271) -> 14932;

get_foster_cost(272) -> 14976;

get_foster_cost(273) -> 15020;

get_foster_cost(274) -> 15064;

get_foster_cost(275) -> 15112;

get_foster_cost(276) -> 15156;

get_foster_cost(277) -> 15204;

get_foster_cost(278) -> 15248;

get_foster_cost(279) -> 15292;

get_foster_cost(280) -> 15340;

get_foster_cost(281) -> 15384;

get_foster_cost(282) -> 15432;

get_foster_cost(283) -> 15480;

get_foster_cost(284) -> 15524;

get_foster_cost(285) -> 15572;

get_foster_cost(286) -> 15620;

get_foster_cost(287) -> 15664;

get_foster_cost(288) -> 15712;

get_foster_cost(289) -> 15760;

get_foster_cost(290) -> 15808;

get_foster_cost(291) -> 15856;

get_foster_cost(292) -> 15904;

get_foster_cost(293) -> 15952;

get_foster_cost(294) -> 16000;

get_foster_cost(295) -> 16048;

get_foster_cost(296) -> 16096;

get_foster_cost(297) -> 16144;

get_foster_cost(298) -> 16192;

get_foster_cost(299) -> 16240;

get_foster_cost(300) -> 16288;

get_foster_cost(301) -> 16340;

get_foster_cost(302) -> 16388;

get_foster_cost(303) -> 16436;

get_foster_cost(304) -> 16488;

get_foster_cost(305) -> 16536;

get_foster_cost(306) -> 16584;

get_foster_cost(307) -> 16636;

get_foster_cost(308) -> 16684;

get_foster_cost(309) -> 16736;

get_foster_cost(310) -> 16788;

get_foster_cost(311) -> 16836;

get_foster_cost(312) -> 16888;

get_foster_cost(313) -> 16940;

get_foster_cost(314) -> 16988;

get_foster_cost(315) -> 17040;

get_foster_cost(316) -> 17092;

get_foster_cost(317) -> 17144;

get_foster_cost(318) -> 17196;

get_foster_cost(319) -> 17248;

get_foster_cost(320) -> 17300;

get_foster_cost(321) -> 17352;

get_foster_cost(322) -> 17404;

get_foster_cost(323) -> 17456;

get_foster_cost(324) -> 17508;

get_foster_cost(325) -> 17560;

get_foster_cost(326) -> 17612;

get_foster_cost(327) -> 17668;

get_foster_cost(328) -> 17720;

get_foster_cost(329) -> 17772;

get_foster_cost(330) -> 17828;

get_foster_cost(331) -> 17880;

get_foster_cost(332) -> 17932;

get_foster_cost(333) -> 17988;

get_foster_cost(334) -> 18040;

get_foster_cost(335) -> 18096;

get_foster_cost(336) -> 18152;

get_foster_cost(337) -> 18204;

get_foster_cost(338) -> 18260;

get_foster_cost(339) -> 18316;

get_foster_cost(340) -> 18368;

get_foster_cost(341) -> 18424;

get_foster_cost(342) -> 18480;

get_foster_cost(343) -> 18536;

get_foster_cost(344) -> 18592;

get_foster_cost(345) -> 18648;

get_foster_cost(346) -> 18704;

get_foster_cost(347) -> 18760;

get_foster_cost(348) -> 18816;

get_foster_cost(349) -> 18872;

get_foster_cost(350) -> 18932;

get_foster_cost(351) -> 18988;

get_foster_cost(352) -> 19044;

get_foster_cost(353) -> 19100;

get_foster_cost(354) -> 19160;

get_foster_cost(355) -> 19216;

get_foster_cost(356) -> 19276;

get_foster_cost(357) -> 19332;

get_foster_cost(358) -> 19392;

get_foster_cost(359) -> 19448;

get_foster_cost(360) -> 19508;

get_foster_cost(361) -> 19568;

get_foster_cost(362) -> 19624;

get_foster_cost(363) -> 19684;

get_foster_cost(364) -> 19744;

get_foster_cost(365) -> 19804;

get_foster_cost(366) -> 19864;

get_foster_cost(367) -> 19924;

get_foster_cost(368) -> 19984;

get_foster_cost(369) -> 20044;

get_foster_cost(370) -> 20104;

get_foster_cost(371) -> 20164;

get_foster_cost(372) -> 20224;

get_foster_cost(373) -> 20284;

get_foster_cost(374) -> 20344;

get_foster_cost(375) -> 20408;

get_foster_cost(376) -> 20468;

get_foster_cost(377) -> 20528;

get_foster_cost(378) -> 20592;

get_foster_cost(379) -> 20652;

get_foster_cost(380) -> 20716;

get_foster_cost(381) -> 20780;

get_foster_cost(382) -> 20840;

get_foster_cost(383) -> 20904;

get_foster_cost(384) -> 20968;

get_foster_cost(385) -> 21028;

get_foster_cost(386) -> 21092;

get_foster_cost(387) -> 21156;

get_foster_cost(388) -> 21220;

get_foster_cost(389) -> 21284;

get_foster_cost(390) -> 21348;

get_foster_cost(391) -> 21412;

get_foster_cost(392) -> 21476;

get_foster_cost(393) -> 21540;

get_foster_cost(394) -> 21604;

get_foster_cost(395) -> 21672;

get_foster_cost(396) -> 21736;

get_foster_cost(397) -> 21800;

get_foster_cost(398) -> 21868;

get_foster_cost(399) -> 21932;

get_foster_cost(400) -> 22000;

get_foster_cost(401) -> 22064;

get_foster_cost(402) -> 22132;

get_foster_cost(403) -> 22196;

get_foster_cost(404) -> 22264;

get_foster_cost(405) -> 22332;

get_foster_cost(406) -> 22400;

get_foster_cost(407) -> 22468;

get_foster_cost(408) -> 22532;

get_foster_cost(409) -> 22600;

get_foster_cost(410) -> 22668;

get_foster_cost(411) -> 22736;

get_foster_cost(412) -> 22808;

get_foster_cost(413) -> 22876;

get_foster_cost(414) -> 22944;

get_foster_cost(415) -> 23012;

get_foster_cost(416) -> 23084;

get_foster_cost(417) -> 23152;

get_foster_cost(418) -> 23220;

get_foster_cost(419) -> 23292;

get_foster_cost(420) -> 23360;

get_foster_cost(421) -> 23432;

get_foster_cost(422) -> 23500;

get_foster_cost(423) -> 23572;

get_foster_cost(424) -> 23644;

get_foster_cost(425) -> 23716;

get_foster_cost(426) -> 23788;

get_foster_cost(427) -> 23856;

get_foster_cost(428) -> 23928;

get_foster_cost(429) -> 24000;

get_foster_cost(430) -> 24072;

get_foster_cost(431) -> 24148;

get_foster_cost(432) -> 24220;

get_foster_cost(433) -> 24292;

get_foster_cost(434) -> 24364;

get_foster_cost(435) -> 24440;

get_foster_cost(436) -> 24512;

get_foster_cost(437) -> 24584;

get_foster_cost(438) -> 24660;

get_foster_cost(439) -> 24732;

get_foster_cost(440) -> 24808;

get_foster_cost(441) -> 24884;

get_foster_cost(442) -> 24956;

get_foster_cost(443) -> 25032;

get_foster_cost(444) -> 25108;

get_foster_cost(445) -> 25184;

get_foster_cost(446) -> 25260;

get_foster_cost(447) -> 25336;

get_foster_cost(448) -> 25412;

get_foster_cost(449) -> 25488;

get_foster_cost(450) -> 25564;

get_foster_cost(451) -> 25640;

get_foster_cost(452) -> 25720;

get_foster_cost(453) -> 25796;

get_foster_cost(454) -> 25872;

get_foster_cost(455) -> 25952;

get_foster_cost(456) -> 26028;

get_foster_cost(457) -> 26108;

get_foster_cost(458) -> 26188;

get_foster_cost(459) -> 26264;

get_foster_cost(460) -> 26344;

get_foster_cost(461) -> 26424;

get_foster_cost(462) -> 26504;

get_foster_cost(463) -> 26584;

get_foster_cost(464) -> 26664;

get_foster_cost(465) -> 26744;

get_foster_cost(466) -> 26824;

get_foster_cost(467) -> 26904;

get_foster_cost(468) -> 26984;

get_foster_cost(469) -> 27068;

get_foster_cost(470) -> 27148;

get_foster_cost(471) -> 27228;

get_foster_cost(472) -> 27312;

get_foster_cost(473) -> 27392;

get_foster_cost(474) -> 27476;

get_foster_cost(475) -> 27560;

get_foster_cost(476) -> 27640;

get_foster_cost(477) -> 27724;

get_foster_cost(478) -> 27808;

get_foster_cost(479) -> 27892;

get_foster_cost(480) -> 27976;

get_foster_cost(481) -> 28060;

get_foster_cost(482) -> 28144;

get_foster_cost(483) -> 28228;

get_foster_cost(484) -> 28316;

get_foster_cost(485) -> 28400;

get_foster_cost(486) -> 28484;

get_foster_cost(487) -> 28572;

get_foster_cost(488) -> 28656;

get_foster_cost(489) -> 28744;

get_foster_cost(490) -> 28828;

get_foster_cost(491) -> 28916;

get_foster_cost(492) -> 29004;

get_foster_cost(493) -> 29092;

get_foster_cost(494) -> 29176;

get_foster_cost(495) -> 29264;

get_foster_cost(496) -> 29352;

get_foster_cost(497) -> 29440;

get_foster_cost(498) -> 29532;

get_foster_cost(499) -> 29620;

get_foster_cost(500) -> 29708;

get_foster_cost(501) -> 29796;

get_foster_cost(502) -> 29888;

get_foster_cost(503) -> 29976;

get_foster_cost(504) -> 30068;

get_foster_cost(505) -> 30160;

get_foster_cost(506) -> 30248;

get_foster_cost(507) -> 30340;

get_foster_cost(508) -> 30432;

get_foster_cost(509) -> 30524;

get_foster_cost(510) -> 30616;

get_foster_cost(511) -> 30708;

get_foster_cost(512) -> 30800;

get_foster_cost(513) -> 30892;

get_foster_cost(514) -> 30984;

get_foster_cost(515) -> 31080;

get_foster_cost(516) -> 31172;

get_foster_cost(517) -> 31264;

get_foster_cost(518) -> 31360;

get_foster_cost(519) -> 31452;

get_foster_cost(520) -> 31548;

get_foster_cost(521) -> 31644;

get_foster_cost(522) -> 31740;

get_foster_cost(523) -> 31836;

get_foster_cost(524) -> 31928;

get_foster_cost(525) -> 32024;

get_foster_cost(526) -> 32124;

get_foster_cost(527) -> 32220;

get_foster_cost(528) -> 32316;

get_foster_cost(529) -> 32412;

get_foster_cost(530) -> 32512;

get_foster_cost(531) -> 32608;

get_foster_cost(532) -> 32708;

get_foster_cost(533) -> 32804;

get_foster_cost(534) -> 32904;

get_foster_cost(535) -> 33004;

get_foster_cost(536) -> 33104;

get_foster_cost(537) -> 33200;

get_foster_cost(538) -> 33300;

get_foster_cost(539) -> 33400;

get_foster_cost(540) -> 33504;

get_foster_cost(541) -> 33604;

get_foster_cost(542) -> 33704;

get_foster_cost(543) -> 33804;

get_foster_cost(544) -> 33908;

get_foster_cost(545) -> 34008;

get_foster_cost(546) -> 34112;

get_foster_cost(547) -> 34216;

get_foster_cost(548) -> 34316;

get_foster_cost(549) -> 34420;

get_foster_cost(550) -> 34524;

get_foster_cost(551) -> 34628;

get_foster_cost(552) -> 34732;

get_foster_cost(553) -> 34836;

get_foster_cost(554) -> 34940;

get_foster_cost(555) -> 35048;

get_foster_cost(556) -> 35152;

get_foster_cost(557) -> 35256;

get_foster_cost(558) -> 35364;

get_foster_cost(559) -> 35472;

get_foster_cost(560) -> 35576;

get_foster_cost(561) -> 35684;

get_foster_cost(562) -> 35792;

get_foster_cost(563) -> 35900;

get_foster_cost(564) -> 36008;

get_foster_cost(565) -> 36116;

get_foster_cost(566) -> 36224;

get_foster_cost(567) -> 36332;

get_foster_cost(568) -> 36444;

get_foster_cost(569) -> 36552;

get_foster_cost(570) -> 36664;

get_foster_cost(571) -> 36772;

get_foster_cost(572) -> 36884;

get_foster_cost(573) -> 36996;

get_foster_cost(574) -> 37104;

get_foster_cost(575) -> 37216;

get_foster_cost(576) -> 37328;

get_foster_cost(577) -> 37440;

get_foster_cost(578) -> 37556;

get_foster_cost(579) -> 37668;

get_foster_cost(580) -> 37780;

get_foster_cost(581) -> 37896;

get_foster_cost(582) -> 38008;

get_foster_cost(583) -> 38124;

get_foster_cost(584) -> 38236;

get_foster_cost(585) -> 38352;

get_foster_cost(586) -> 38468;

get_foster_cost(587) -> 38584;

get_foster_cost(588) -> 38700;

get_foster_cost(589) -> 38816;

get_foster_cost(590) -> 38932;

get_foster_cost(591) -> 39052;

get_foster_cost(592) -> 39168;

get_foster_cost(593) -> 39284;

get_foster_cost(594) -> 39404;

get_foster_cost(595) -> 39524;

get_foster_cost(596) -> 39640;

get_foster_cost(597) -> 39760;

get_foster_cost(598) -> 39880;

get_foster_cost(599) -> 40000;

get_foster_cost(600) -> 40200;

get_foster_cost(601) -> 40004;

get_foster_cost(602) -> 40604;

get_foster_cost(603) -> 40808;

get_foster_cost(604) -> 41012;

get_foster_cost(605) -> 41216;

get_foster_cost(606) -> 41420;

get_foster_cost(607) -> 41628;

get_foster_cost(608) -> 41836;

get_foster_cost(609) -> 42044;

get_foster_cost(610) -> 42256;

get_foster_cost(611) -> 42468;

get_foster_cost(612) -> 42680;

get_foster_cost(613) -> 42892;

get_foster_cost(614) -> 43108;

get_foster_cost(615) -> 43324;

get_foster_cost(616) -> 43540;

get_foster_cost(617) -> 43756;

get_foster_cost(618) -> 43976;

get_foster_cost(619) -> 44196;

get_foster_cost(620) -> 44416;

get_foster_cost(621) -> 44640;

get_foster_cost(622) -> 44864;

get_foster_cost(623) -> 45088;

get_foster_cost(624) -> 45312;

get_foster_cost(625) -> 45540;

get_foster_cost(626) -> 45768;

get_foster_cost(627) -> 45996;

get_foster_cost(628) -> 46224;

get_foster_cost(629) -> 46456;

get_foster_cost(630) -> 46688;

get_foster_cost(631) -> 46920;

get_foster_cost(632) -> 47156;

get_foster_cost(633) -> 47392;

get_foster_cost(634) -> 47628;

get_foster_cost(635) -> 47868;

get_foster_cost(636) -> 48108;

get_foster_cost(637) -> 48348;

get_foster_cost(638) -> 48588;

get_foster_cost(639) -> 48832;

get_foster_cost(640) -> 49076;

get_foster_cost(641) -> 49320;

get_foster_cost(642) -> 49568;

get_foster_cost(643) -> 49816;

get_foster_cost(644) -> 50064;

get_foster_cost(645) -> 50316;

get_foster_cost(646) -> 50568;

get_foster_cost(647) -> 50820;

get_foster_cost(648) -> 51072;

get_foster_cost(649) -> 51328;

get_foster_cost(650) -> 51584;

get_foster_cost(651) -> 51844;

get_foster_cost(652) -> 52104;

get_foster_cost(653) -> 52364;

get_foster_cost(654) -> 52624;

get_foster_cost(655) -> 52888;

get_foster_cost(656) -> 53152;

get_foster_cost(657) -> 53420;

get_foster_cost(658) -> 53684;

get_foster_cost(659) -> 53956;

get_foster_cost(660) -> 54224;

get_foster_cost(661) -> 54496;

get_foster_cost(662) -> 54768;

get_foster_cost(663) -> 55040;

get_foster_cost(664) -> 55316;

get_foster_cost(665) -> 55592;

get_foster_cost(666) -> 55872;

get_foster_cost(667) -> 56152;

get_foster_cost(668) -> 56432;

get_foster_cost(669) -> 56712;

get_foster_cost(670) -> 56996;

get_foster_cost(671) -> 57280;

get_foster_cost(672) -> 57568;

get_foster_cost(673) -> 57856;

get_foster_cost(674) -> 58144;

get_foster_cost(675) -> 58436;

get_foster_cost(676) -> 58728;

get_foster_cost(677) -> 59020;

get_foster_cost(678) -> 59316;

get_foster_cost(679) -> 59612;

get_foster_cost(680) -> 59912;

get_foster_cost(681) -> 60212;

get_foster_cost(682) -> 60512;

get_foster_cost(683) -> 60816;

get_foster_cost(684) -> 61120;

get_foster_cost(685) -> 61424;

get_foster_cost(686) -> 61732;

get_foster_cost(687) -> 62040;

get_foster_cost(688) -> 62352;

get_foster_cost(689) -> 62664;

get_foster_cost(690) -> 62976;

get_foster_cost(691) -> 63292;

get_foster_cost(692) -> 63608;

get_foster_cost(693) -> 63924;

get_foster_cost(694) -> 64244;

get_foster_cost(695) -> 64564;

get_foster_cost(696) -> 64888;

get_foster_cost(697) -> 65212;

get_foster_cost(698) -> 65540;

get_foster_cost(699) -> 65868;

get_foster_cost(700) -> 66196;

get_foster_cost(701) -> 66528;

get_foster_cost(702) -> 66860;

get_foster_cost(703) -> 67192;

get_foster_cost(704) -> 67528;

get_foster_cost(705) -> 67868;

get_foster_cost(706) -> 68208;

get_foster_cost(707) -> 68548;

get_foster_cost(708) -> 68892;

get_foster_cost(709) -> 69236;

get_foster_cost(710) -> 69580;

get_foster_cost(711) -> 69928;

get_foster_cost(712) -> 70280;

get_foster_cost(713) -> 70632;

get_foster_cost(714) -> 70984;

get_foster_cost(715) -> 71340;

get_foster_cost(716) -> 71696;

get_foster_cost(717) -> 72052;

get_foster_cost(718) -> 72412;

get_foster_cost(719) -> 72776;

get_foster_cost(720) -> 73140;

get_foster_cost(721) -> 73504;

get_foster_cost(722) -> 73872;

get_foster_cost(723) -> 74244;

get_foster_cost(724) -> 74612;

get_foster_cost(725) -> 74988;

get_foster_cost(726) -> 75360;

get_foster_cost(727) -> 75740;

get_foster_cost(728) -> 76116;

get_foster_cost(729) -> 76496;

get_foster_cost(730) -> 76880;

get_foster_cost(731) -> 77264;

get_foster_cost(732) -> 77652;

get_foster_cost(733) -> 78040;

get_foster_cost(734) -> 78428;

get_foster_cost(735) -> 78820;

get_foster_cost(736) -> 79216;

get_foster_cost(737) -> 79612;

get_foster_cost(738) -> 80008;

get_foster_cost(739) -> 80408;

get_foster_cost(740) -> 80812;

get_foster_cost(741) -> 81216;

get_foster_cost(742) -> 81620;

get_foster_cost(743) -> 82032;

get_foster_cost(744) -> 82440;

get_foster_cost(745) -> 82852;

get_foster_cost(746) -> 83268;

get_foster_cost(747) -> 83684;

get_foster_cost(748) -> 84100;

get_foster_cost(749) -> 84520;

get_foster_cost(750) -> 84944;

get_foster_cost(751) -> 85368;

get_foster_cost(752) -> 85796;

get_foster_cost(753) -> 86224;

get_foster_cost(754) -> 86656;

get_foster_cost(755) -> 87088;

get_foster_cost(756) -> 87524;

get_foster_cost(757) -> 87964;

get_foster_cost(758) -> 88404;

get_foster_cost(759) -> 88844;

get_foster_cost(760) -> 89288;

get_foster_cost(761) -> 89736;

get_foster_cost(762) -> 90184;

get_foster_cost(763) -> 90636;

get_foster_cost(764) -> 91088;

get_foster_cost(765) -> 91544;

get_foster_cost(766) -> 92000;

get_foster_cost(767) -> 92460;

get_foster_cost(768) -> 92924;

get_foster_cost(769) -> 93388;

get_foster_cost(770) -> 93856;

get_foster_cost(771) -> 94324;

get_foster_cost(772) -> 94796;

get_foster_cost(773) -> 95268;

get_foster_cost(774) -> 95748;

get_foster_cost(775) -> 96224;

get_foster_cost(776) -> 96704;

get_foster_cost(777) -> 97188;

get_foster_cost(778) -> 97676;

get_foster_cost(779) -> 98164;

get_foster_cost(780) -> 98656;

get_foster_cost(781) -> 99148;

get_foster_cost(782) -> 99644;

get_foster_cost(783) -> 100140;

get_foster_cost(784) -> 100644;

get_foster_cost(785) -> 101144;

get_foster_cost(786) -> 101652;

get_foster_cost(787) -> 102160;

get_foster_cost(788) -> 102672;

get_foster_cost(789) -> 103184;

get_foster_cost(790) -> 103700;

get_foster_cost(791) -> 104220;

get_foster_cost(792) -> 104740;

get_foster_cost(793) -> 105264;

get_foster_cost(794) -> 105788;

get_foster_cost(795) -> 106320;

get_foster_cost(796) -> 106848;

get_foster_cost(797) -> 107384;

get_foster_cost(798) -> 107920;

get_foster_cost(799) -> 108460.


%%================================================
%% 根据职业id获取天赋提升概率record
get_talent_up_rate(1) -> 
	#talent_rate{
		liliang   = 95,
		yuansheng = 85,
		tipo      = 100,
		minjie    = 80
	};

get_talent_up_rate(2) -> 
	#talent_rate{
		liliang   = 100,
		yuansheng = 80,
		tipo      = 85,
		minjie    = 95
	};

get_talent_up_rate(3) -> 
	#talent_rate{
		liliang   = 80,
		yuansheng = 100,
		tipo      = 80,
		minjie    = 100
	};

get_talent_up_rate(4) -> 
	#talent_rate{
		liliang   = 80,
		yuansheng = 100,
		tipo      = 80,
		minjie    = 80
	}.


%%================================================
