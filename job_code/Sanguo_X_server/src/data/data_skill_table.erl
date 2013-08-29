
-module(data_skill_table).
-compile(export_all).

-include("common.hrl").

-spec get(SkillId :: integer(), Level :: integer()) -> #battle_skill{} | ?UNDEFINED.
	
get(100, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 100,	
		level  = 1,
		target = enemy,
		param  = {1}    
	};

get(101, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 101,	
		level  = 1,
		target = self,
		param  = {0.3}    
	};

get(102, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 102,	
		level  = 1,
		target = self,
		param  = {0.3}    
	};

get(103, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 103,	
		level  = 1,
		target = self,
		param  = {0.1}    
	};

get(104, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 1,
		target = enemy,
		param  = {0.4}    
	};

get(104, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 2,
		target = enemy,
		param  = {0.43}    
	};

get(104, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 3,
		target = enemy,
		param  = {0.47}    
	};

get(104, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 4,
		target = enemy,
		param  = {0.51}    
	};

get(104, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 5,
		target = enemy,
		param  = {0.55}    
	};

get(104, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 6,
		target = enemy,
		param  = {0.59}    
	};

get(104, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 7,
		target = enemy,
		param  = {0.63}    
	};

get(104, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 8,
		target = enemy,
		param  = {0.67}    
	};

get(104, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 9,
		target = enemy,
		param  = {0.71}    
	};

get(104, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 104,	
		level  = 10,
		target = enemy,
		param  = {0.75}    
	};

get(105, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 1,
		target = friend,
		param  = {0.08}    
	};

get(105, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 2,
		target = friend,
		param  = {0.1}    
	};

get(105, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 3,
		target = friend,
		param  = {0.12}    
	};

get(105, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 4,
		target = friend,
		param  = {0.14}    
	};

get(105, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 5,
		target = friend,
		param  = {0.17}    
	};

get(105, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 6,
		target = friend,
		param  = {0.21}    
	};

get(105, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 7,
		target = friend,
		param  = {0.25}    
	};

get(105, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 8,
		target = friend,
		param  = {0.29}    
	};

get(105, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 9,
		target = friend,
		param  = {0.34}    
	};

get(105, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 105,	
		level  = 10,
		target = friend,
		param  = {0.4}    
	};

get(106, 1) -> 
	#battle_skill {
		hp     = 0.1,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 1,
		target = enemy,
		param  = {1.1}    
	};

get(106, 2) -> 
	#battle_skill {
		hp     = 0.09,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 2,
		target = enemy,
		param  = {1.13}    
	};

get(106, 3) -> 
	#battle_skill {
		hp     = 0.08,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 3,
		target = enemy,
		param  = {1.15}    
	};

get(106, 4) -> 
	#battle_skill {
		hp     = 0.07,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 4,
		target = enemy,
		param  = {1.18}    
	};

get(106, 5) -> 
	#battle_skill {
		hp     = 0.06,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 5,
		target = enemy,
		param  = {1.22}    
	};

get(106, 6) -> 
	#battle_skill {
		hp     = 0.05,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 6,
		target = enemy,
		param  = {1.26}    
	};

get(106, 7) -> 
	#battle_skill {
		hp     = 0.04,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 7,
		target = enemy,
		param  = {1.31}    
	};

get(106, 8) -> 
	#battle_skill {
		hp     = 0.03,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 8,
		target = enemy,
		param  = {1.36}    
	};

get(106, 9) -> 
	#battle_skill {
		hp     = 0.02,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 9,
		target = enemy,
		param  = {1.42}    
	};

get(106, 10) -> 
	#battle_skill {
		hp     = 0.01,       
		mp     = 0,
		cd     = 2,     
		id     = 106,	
		level  = 10,
		target = enemy,
		param  = {1.5}    
	};

get(107, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 1,
		target = enemy,
		param  = {1,0.35}    
	};

get(107, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 2,
		target = enemy,
		param  = {1,0.37}    
	};

get(107, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 3,
		target = enemy,
		param  = {1,0.39}    
	};

get(107, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 4,
		target = enemy,
		param  = {1,0.41}    
	};

get(107, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 5,
		target = enemy,
		param  = {1,0.43}    
	};

get(107, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 6,
		target = enemy,
		param  = {1,0.46}    
	};

get(107, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 7,
		target = enemy,
		param  = {1,0.49}    
	};

get(107, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 8,
		target = enemy,
		param  = {1,0.52}    
	};

get(107, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 9,
		target = enemy,
		param  = {1,0.55}    
	};

get(107, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 107,	
		level  = 10,
		target = enemy,
		param  = {1,0.58}    
	};

get(108, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 1,
		target = self,
		param  = {0.05}    
	};

get(108, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 2,
		target = self,
		param  = {0.06}    
	};

get(108, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 3,
		target = self,
		param  = {0.07}    
	};

get(108, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 4,
		target = self,
		param  = {0.08}    
	};

get(108, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 5,
		target = self,
		param  = {0.09}    
	};

get(108, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 6,
		target = self,
		param  = {0.1}    
	};

get(108, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 7,
		target = self,
		param  = {0.11}    
	};

get(108, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 8,
		target = self,
		param  = {0.12}    
	};

get(108, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 9,
		target = self,
		param  = {0.13}    
	};

get(108, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 108,	
		level  = 10,
		target = self,
		param  = {0.15}    
	};

get(109, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 1,
		target = enemy,
		param  = {0.8,0.5,0,0}    
	};

get(109, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 2,
		target = enemy,
		param  = {0.8,0.55,0,0}    
	};

get(109, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 3,
		target = enemy,
		param  = {0.8,0.60,0,0}    
	};

get(109, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 4,
		target = enemy,
		param  = {0.8,0.6,0.15,0}    
	};

get(109, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 5,
		target = enemy,
		param  = {0.8,0.6,0.28,0}    
	};

get(109, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 6,
		target = enemy,
		param  = {0.8,0.6,0.35,0}    
	};

get(109, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 7,
		target = enemy,
		param  = {0.8,0.6,0.35,0.10}    
	};

get(109, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 8,
		target = enemy,
		param  = {0.8,0.6,0.35,0.16}    
	};

get(109, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 9,
		target = enemy,
		param  = {0.8,0.6,0.35,0.23}    
	};

get(109, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 109,	
		level  = 10,
		target = enemy,
		param  = {0.8,0.6,0.35,0.3}    
	};

get(110, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 1,
		target = enemy,
		param  = {0.6}    
	};

get(110, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 2,
		target = enemy,
		param  = {0.62}    
	};

get(110, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 3,
		target = enemy,
		param  = {0.64}    
	};

get(110, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 4,
		target = enemy,
		param  = {0.66}    
	};

get(110, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 5,
		target = enemy,
		param  = {0.68}    
	};

get(110, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 6,
		target = enemy,
		param  = {0.7}    
	};

get(110, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 7,
		target = enemy,
		param  = {0.72}    
	};

get(110, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 8,
		target = enemy,
		param  = {0.74}    
	};

get(110, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 9,
		target = enemy,
		param  = {0.76}    
	};

get(110, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 110,	
		level  = 10,
		target = enemy,
		param  = {0.79}    
	};

get(111, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 1,
		target = enemy,
		param  = {1,0.08,2}    
	};

get(111, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 2,
		target = enemy,
		param  = {1,0.11,2}    
	};

get(111, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 3,
		target = enemy,
		param  = {1,0.14,2}    
	};

get(111, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 4,
		target = enemy,
		param  = {1,0.17,2}    
	};

get(111, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 5,
		target = enemy,
		param  = {1,0.2,2}    
	};

get(111, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 6,
		target = enemy,
		param  = {1,0.23,3}    
	};

get(111, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 7,
		target = enemy,
		param  = {1,0.26,3}    
	};

get(111, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 8,
		target = enemy,
		param  = {1,0.29,3}    
	};

get(111, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 9,
		target = enemy,
		param  = {1,0.32,3}    
	};

get(111, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 111,	
		level  = 10,
		target = enemy,
		param  = {1,0.35,3}    
	};

get(112, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 1,
		target = enemy,
		param  = {1,0.3}    
	};

get(112, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 2,
		target = enemy,
		param  = {1,0.35}    
	};

get(112, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 3,
		target = enemy,
		param  = {1,0.4}    
	};

get(112, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 4,
		target = enemy,
		param  = {1,0.45}    
	};

get(112, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 5,
		target = enemy,
		param  = {1,0.5}    
	};

get(112, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 6,
		target = enemy,
		param  = {1,0.55}    
	};

get(112, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 7,
		target = enemy,
		param  = {1,0.6}    
	};

get(112, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 8,
		target = enemy,
		param  = {1,0.65}    
	};

get(112, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 9,
		target = enemy,
		param  = {1,0.7}    
	};

get(112, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 112,	
		level  = 10,
		target = enemy,
		param  = {1,0.75}    
	};

get(113, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 1,
		target = enemy,
		param  = {1.00,0}    
	};

get(113, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 2,
		target = enemy,
		param  = {1.02,0}    
	};

get(113, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 3,
		target = enemy,
		param  = {1.04,0}    
	};

get(113, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 4,
		target = enemy,
		param  = {1.06,0}    
	};

get(113, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 5,
		target = enemy,
		param  = {1.08,0}    
	};

get(113, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 6,
		target = enemy,
		param  = {1.10,0}    
	};

get(113, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 7,
		target = enemy,
		param  = {1.12,0}    
	};

get(113, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 8,
		target = enemy,
		param  = {1.14,0}    
	};

get(113, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 9,
		target = enemy,
		param  = {1.16,0}    
	};

get(113, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 113,	
		level  = 10,
		target = enemy,
		param  = {1.20,0}    
	};

get(114, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 1,
		target = enemy,
		param  = {0.9}    
	};

get(114, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 2,
		target = enemy,
		param  = {0.95}    
	};

get(114, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 3,
		target = enemy,
		param  = {1}    
	};

get(114, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 4,
		target = enemy,
		param  = {1.03}    
	};

get(114, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 5,
		target = enemy,
		param  = {1.06}    
	};

get(114, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 6,
		target = enemy,
		param  = {1.09}    
	};

get(114, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 7,
		target = enemy,
		param  = {1.12}    
	};

get(114, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 8,
		target = enemy,
		param  = {1.15}    
	};

get(114, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 9,
		target = enemy,
		param  = {1.18}    
	};

get(114, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 114,	
		level  = 10,
		target = enemy,
		param  = {1.21}    
	};

get(115, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 1,
		target = enemy,
		param  = {1,0.3,100}    
	};

get(115, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 2,
		target = enemy,
		param  = {1,0.3,200}    
	};

get(115, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 3,
		target = enemy,
		param  = {1,0.3,350}    
	};

get(115, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 4,
		target = enemy,
		param  = {1,0.3,500}    
	};

get(115, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 5,
		target = enemy,
		param  = {1,0.3,650}    
	};

get(115, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 6,
		target = enemy,
		param  = {1,0.3,800}    
	};

get(115, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 7,
		target = enemy,
		param  = {1,0.3,1000}    
	};

get(115, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 8,
		target = enemy,
		param  = {1,0.3,1200}    
	};

get(115, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 9,
		target = enemy,
		param  = {1,0.3,1400}    
	};

get(115, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 1,     
		id     = 115,	
		level  = 10,
		target = enemy,
		param  = {1,0.3,1600}    
	};

get(116, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 1,
		target = enemy,
		param  = {1,0.09}    
	};

get(116, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 2,
		target = enemy,
		param  = {1,0.11}    
	};

get(116, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 3,
		target = enemy,
		param  = {1,0.13}    
	};

get(116, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 4,
		target = enemy,
		param  = {1,0.15}    
	};

get(116, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 5,
		target = enemy,
		param  = {1,0.17}    
	};

get(116, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 6,
		target = enemy,
		param  = {1,0.19}    
	};

get(116, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 7,
		target = enemy,
		param  = {1,0.21}    
	};

get(116, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 8,
		target = enemy,
		param  = {1,0.23}    
	};

get(116, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 9,
		target = enemy,
		param  = {1,0.25}    
	};

get(116, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 2,     
		id     = 116,	
		level  = 10,
		target = enemy,
		param  = {1,0.28}    
	};

get(117, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 1,
		target = enemy,
		param  = {1.1,0.1}    
	};

get(117, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 2,
		target = enemy,
		param  = {1.1,0.13}    
	};

get(117, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 3,
		target = enemy,
		param  = {1.1,0.16}    
	};

get(117, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 4,
		target = enemy,
		param  = {1.1,0.19}    
	};

get(117, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 5,
		target = enemy,
		param  = {1.1,0.22}    
	};

get(117, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 6,
		target = enemy,
		param  = {1.1,0.25}    
	};

get(117, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 7,
		target = enemy,
		param  = {1.1,0.28}    
	};

get(117, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 8,
		target = enemy,
		param  = {1.1,0.31}    
	};

get(117, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 9,
		target = enemy,
		param  = {1.1,0.34}    
	};

get(117, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 3,     
		id     = 117,	
		level  = 10,
		target = enemy,
		param  = {1.1,0.38}    
	};

get(118, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 1,
		target = enemy,
		param  = {0.75}    
	};

get(118, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 2,
		target = enemy,
		param  = {0.78}    
	};

get(118, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 3,
		target = enemy,
		param  = {0.8}    
	};

get(118, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 4,
		target = enemy,
		param  = {0.83}    
	};

get(118, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 5,
		target = enemy,
		param  = {0.86}    
	};

get(118, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 6,
		target = enemy,
		param  = {0.89}    
	};

get(118, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 7,
		target = enemy,
		param  = {0.92}    
	};

get(118, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 8,
		target = enemy,
		param  = {0.95}    
	};

get(118, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 9,
		target = enemy,
		param  = {0.97}    
	};

get(118, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 4,     
		id     = 118,	
		level  = 10,
		target = enemy,
		param  = {1}    
	};

get(201, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 1,
		target = self,
		param  = {0.2,0.4}    
	};

get(201, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 2,
		target = self,
		param  = {0.24,0.4}    
	};

get(201, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 3,
		target = self,
		param  = {0.28,0.4}    
	};

get(201, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 4,
		target = self,
		param  = {0.32,0.4}    
	};

get(201, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 5,
		target = self,
		param  = {0.36,0.4}    
	};

get(201, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 6,
		target = self,
		param  = {0.4,0.4}    
	};

get(201, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 7,
		target = self,
		param  = {0.45,0.4}    
	};

get(201, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 8,
		target = self,
		param  = {0.5,0.4}    
	};

get(201, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 9,
		target = self,
		param  = {0.55,0.4}    
	};

get(201, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 201,	
		level  = 10,
		target = self,
		param  = {0.6,0.4}    
	};

get(202, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 1,
		target = self,
		param  = {0.05,0.08}    
	};

get(202, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 2,
		target = self,
		param  = {0.065,0.08}    
	};

get(202, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 3,
		target = self,
		param  = {0.08,0.08}    
	};

get(202, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 4,
		target = self,
		param  = {0.095,0.08}    
	};

get(202, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 5,
		target = self,
		param  = {0.11,0.08}    
	};

get(202, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 6,
		target = self,
		param  = {0.125,0.08}    
	};

get(202, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 7,
		target = self,
		param  = {0.14,0.08}    
	};

get(202, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 8,
		target = self,
		param  = {0.16,0.08}    
	};

get(202, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 9,
		target = self,
		param  = {0.18,0.08}    
	};

get(202, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 202,	
		level  = 10,
		target = self,
		param  = {0.2,0.08}    
	};

get(203, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 1,
		target = self,
		param  = {0.052,0.9,0.4}    
	};

get(203, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 2,
		target = self,
		param  = {0.074,0.9,0.4}    
	};

get(203, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 3,
		target = self,
		param  = {0.096,0.9,0.4}    
	};

get(203, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 4,
		target = self,
		param  = {0.118,0.9,0.4}    
	};

get(203, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 5,
		target = self,
		param  = {0.14,0.9,0.4}    
	};

get(203, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 6,
		target = self,
		param  = {0.162,0.9,0.4}    
	};

get(203, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 7,
		target = self,
		param  = {0.184,0.9,0.4}    
	};

get(203, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 8,
		target = self,
		param  = {0.206,0.9,0.4}    
	};

get(203, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 9,
		target = self,
		param  = {0.228,0.9,0.4}    
	};

get(203, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 203,	
		level  = 10,
		target = self,
		param  = {0.25,0.9,0.4}    
	};

get(204, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(204, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(204, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(204, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(204, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(204, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(204, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(204, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(204, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(204, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 204,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(205, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 1,
		target = self,
		param  = {0.08,0.06}    
	};

get(205, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 2,
		target = self,
		param  = {0.1,0.08}    
	};

get(205, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 3,
		target = self,
		param  = {0.12,0.10}    
	};

get(205, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 4,
		target = self,
		param  = {0.14,0.12}    
	};

get(205, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 5,
		target = self,
		param  = {0.16,0.14}    
	};

get(205, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 6,
		target = self,
		param  = {0.18,0.16}    
	};

get(205, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 7,
		target = self,
		param  = {0.2,0.18}    
	};

get(205, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 8,
		target = self,
		param  = {0.22,0.21}    
	};

get(205, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 9,
		target = self,
		param  = {0.24,0.23}    
	};

get(205, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 205,	
		level  = 10,
		target = self,
		param  = {0.26,0.25}    
	};

get(206, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 1,
		target = self,
		param  = {0.06,0.06}    
	};

get(206, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 2,
		target = self,
		param  = {0.08,0.08}    
	};

get(206, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 3,
		target = self,
		param  = {0.1,0.10}    
	};

get(206, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 4,
		target = self,
		param  = {0.12,0.12}    
	};

get(206, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 5,
		target = self,
		param  = {0.14,0.14}    
	};

get(206, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 6,
		target = self,
		param  = {0.16,0.16}    
	};

get(206, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 7,
		target = self,
		param  = {0.18,0.18}    
	};

get(206, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 8,
		target = self,
		param  = {0.2,0.20}    
	};

get(206, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 9,
		target = self,
		param  = {0.22,0.22}    
	};

get(206, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 206,	
		level  = 10,
		target = self,
		param  = {0.25,0.25}    
	};

get(207, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 1,
		target = self,
		param  = {10,0.08}    
	};

get(207, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 2,
		target = self,
		param  = {12,0.10}    
	};

get(207, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 3,
		target = self,
		param  = {14,0.12}    
	};

get(207, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 4,
		target = self,
		param  = {16,0.14}    
	};

get(207, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 5,
		target = self,
		param  = {18,0.16}    
	};

get(207, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 6,
		target = self,
		param  = {20,0.18}    
	};

get(207, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 7,
		target = self,
		param  = {22,0.21}    
	};

get(207, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 8,
		target = self,
		param  = {24,0.24}    
	};

get(207, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 9,
		target = self,
		param  = {27,0.27}    
	};

get(207, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 207,	
		level  = 10,
		target = self,
		param  = {30,0.3}    
	};

get(208, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(208, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(208, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(208, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(208, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(208, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(208, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(208, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(208, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(208, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 208,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(209, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(209, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(209, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(209, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(209, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(209, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(209, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(209, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(209, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(209, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 209,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(210, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(210, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(210, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(210, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(210, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(210, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(210, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(210, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(210, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(210, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 210,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(211, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(211, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(211, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(211, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(211, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(211, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(211, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(211, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(211, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(211, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 211,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(212, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(212, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(212, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(212, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(212, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(212, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(212, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(212, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(212, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(212, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 212,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(213, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(213, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(213, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(213, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(213, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(213, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(213, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(213, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(213, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(213, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 213,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(214, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 1,
		target = self,
		param  = {5}    
	};

get(214, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 2,
		target = self,
		param  = {10}    
	};

get(214, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 3,
		target = self,
		param  = {15}    
	};

get(214, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 4,
		target = self,
		param  = {20}    
	};

get(214, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 5,
		target = self,
		param  = {25}    
	};

get(214, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 6,
		target = self,
		param  = {30}    
	};

get(214, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 7,
		target = self,
		param  = {35}    
	};

get(214, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 8,
		target = self,
		param  = {40}    
	};

get(214, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 9,
		target = self,
		param  = {45}    
	};

get(214, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 214,	
		level  = 10,
		target = self,
		param  = {50}    
	};

get(215, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 1,
		target = self,
		param  = {0.2}    
	};

get(215, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 2,
		target = self,
		param  = {0.2}    
	};

get(215, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 3,
		target = self,
		param  = {0.2}    
	};

get(215, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 4,
		target = self,
		param  = {0.2}    
	};

get(215, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 5,
		target = self,
		param  = {0.2}    
	};

get(215, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 6,
		target = self,
		param  = {0.2}    
	};

get(215, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 7,
		target = self,
		param  = {0.2}    
	};

get(215, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 8,
		target = self,
		param  = {0.2}    
	};

get(215, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 9,
		target = self,
		param  = {0.2}    
	};

get(215, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 215,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(216, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(216, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(216, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(216, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(216, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(216, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(216, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(216, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(216, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(216, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 216,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(217, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(217, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(217, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(217, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(217, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(217, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(217, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(217, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(217, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(217, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 217,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(218, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(218, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(218, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(218, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(218, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(218, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(218, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(218, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(218, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(218, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 218,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(219, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(219, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(219, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(219, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(219, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(219, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(219, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(219, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(219, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(219, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 219,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(220, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(220, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(220, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(220, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(220, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(220, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(220, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(220, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(220, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(220, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 220,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(221, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(221, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(221, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(221, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(221, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(221, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(221, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(221, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(221, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(221, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 221,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(222, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 1,
		target = self,
		param  = {}    
	};

get(222, 2) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 2,
		target = self,
		param  = {}    
	};

get(222, 3) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 3,
		target = self,
		param  = {}    
	};

get(222, 4) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 4,
		target = self,
		param  = {}    
	};

get(222, 5) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 5,
		target = self,
		param  = {}    
	};

get(222, 6) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 6,
		target = self,
		param  = {}    
	};

get(222, 7) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 7,
		target = self,
		param  = {}    
	};

get(222, 8) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 8,
		target = self,
		param  = {}    
	};

get(222, 9) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 9,
		target = self,
		param  = {}    
	};

get(222, 10) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 0,
		cd     = 0,     
		id     = 222,	
		level  = 10,
		target = self,
		param  = {}    
	};

get(223, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 223,	
		level  = 1,
		target = enemy,
		param  = {0.3}    
	};

get(224, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 224,	
		level  = 1,
		target = enemy,
		param  = {0.4}    
	};

get(225, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 225,	
		level  = 1,
		target = self,
		param  = {0.5}    
	};

get(226, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 226,	
		level  = 1,
		target = enemy,
		param  = {0.9,0.25}    
	};

get(227, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 227,	
		level  = 1,
		target = enemy,
		param  = {0.9,1}    
	};

get(228, 1) -> 
	#battle_skill {
		hp     = 0.15,       
		mp     = 100,
		cd     = 0,     
		id     = 228,	
		level  = 1,
		target = enemy,
		param  = {1.5}    
	};

get(229, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 229,	
		level  = 1,
		target = enemy,
		param  = {1,0.4}    
	};

get(230, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 230,	
		level  = 1,
		target = enemy,
		param  = {1.6}    
	};

get(231, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 231,	
		level  = 1,
		target = enemy,
		param  = {0.9}    
	};

get(232, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 232,	
		level  = 1,
		target = enemy,
		param  = {1}    
	};

get(233, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 233,	
		level  = 1,
		target = enemy,
		param  = {}    
	};

get(234, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 234,	
		level  = 1,
		target = enemy,
		param  = {0.3,1}    
	};

get(235, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 235,	
		level  = 1,
		target = enemy,
		param  = {0.6}    
	};

get(236, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 236,	
		level  = 1,
		target = enemy,
		param  = {0.7}    
	};

get(237, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 237,	
		level  = 1,
		target = enemy,
		param  = {1.5,0.3,25}    
	};

get(238, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 238,	
		level  = 1,
		target = enemy,
		param  = {1,0.8}    
	};

get(239, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 239,	
		level  = 1,
		target = enemy,
		param  = {0.15,1}    
	};

get(240, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 240,	
		level  = 1,
		target = enemy,
		param  = {0.3,1,1}    
	};

get(241, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 241,	
		level  = 1,
		target = enemy,
		param  = {0.9,0.5,0.5}    
	};

get(242, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 242,	
		level  = 1,
		target = friend,
		param  = {20}    
	};

get(243, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 243,	
		level  = 1,
		target = friend,
		param  = {0.4,0.2,0.2}    
	};

get(244, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 244,	
		level  = 1,
		target = friend,
		param  = {}    
	};

get(245, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 245,	
		level  = 1,
		target = friend,
		param  = {0.3,0.3}    
	};

get(246, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 246,	
		level  = 1,
		target = friend,
		param  = {}    
	};

get(247, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 247,	
		level  = 1,
		target = friend,
		param  = {}    
	};

get(248, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 248,	
		level  = 1,
		target = friend,
		param  = {0.17}    
	};

get(249, 1) -> 
	#battle_skill {
		hp     = 0.05,       
		mp     = 100,
		cd     = 1,     
		id     = 249,	
		level  = 1,
		target = enemy,
		param  = {1.25}    
	};

get(250, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 3,     
		id     = 250,	
		level  = 1,
		target = self,
		param  = {0.09}    
	};

get(251, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 251,	
		level  = 1,
		target = enemy,
		param  = {0.8,0.6,0.28}    
	};

get(252, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 252,	
		level  = 1,
		target = enemy,
		param  = {0.68}    
	};

get(253, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 253,	
		level  = 1,
		target = enemy,
		param  = {1,0.35}    
	};

get(254, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 254,	
		level  = 1,
		target = enemy,
		param  = {1,0.75}    
	};

get(255, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 255,	
		level  = 1,
		target = enemy,
		param  = {1.2,0.21}    
	};

get(256, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 256,	
		level  = 1,
		target = enemy,
		param  = {1.21}    
	};

get(257, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 257,	
		level  = 1,
		target = enemy,
		param  = {0.17}    
	};

get(258, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 258,	
		level  = 1,
		target = enemy,
		param  = {1.1,0.22}    
	};

get(259, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 259,	
		level  = 1,
		target = enemy,
		param  = {0.85}    
	};

get(260, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 260,	
		level  = 1,
		target = enemy,
		param  = {0.5}    
	};

get(261, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 1,     
		id     = 261,	
		level  = 1,
		target = enemy,
		param  = {2}    
	};

get(262, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 262,	
		level  = 1,
		target = enemy,
		param  = {1}    
	};

get(263, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 263,	
		level  = 1,
		target = enemy,
		param  = {0.5,2}    
	};

get(264, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 264,	
		level  = 1,
		target = enemy,
		param  = {0.9,0.5,0.5}    
	};

get(265, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 265,	
		level  = 1,
		target = enemy,
		param  = {1,0.99,1}    
	};

get(266, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 266,	
		level  = 1,
		target = enemy,
		param  = {1}    
	};

get(267, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 267,	
		level  = 1,
		target = enemy,
		param  = {1,0.5}    
	};

get(268, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 268,	
		level  = 1,
		target = enemy,
		param  = {1,0.2}    
	};

get(269, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 269,	
		level  = 1,
		target = enemy,
		param  = {}    
	};

get(270, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 270,	
		level  = 1,
		target = enemy,
		param  = {1,2}    
	};

get(271, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 271,	
		level  = 1,
		target = friend,
		param  = {0.5}    
	};

get(272, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 272,	
		level  = 1,
		target = enemy,
		param  = {1}    
	};

get(273, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 273,	
		level  = 1,
		target = enemy,
		param  = {3}    
	};

get(274, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 274,	
		level  = 1,
		target = self,
		param  = {0.5}    
	};

get(275, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 275,	
		level  = 1,
		target = friend,
		param  = {0.5,2}    
	};

get(276, 1) -> 
	#battle_skill {
		hp     = 0.2,       
		mp     = 100,
		cd     = 4,     
		id     = 276,	
		level  = 1,
		target = enemy,
		param  = {1.5}    
	};

get(277, 1) -> 
	#battle_skill {
		hp     = 0.2,       
		mp     = 100,
		cd     = 0,     
		id     = 277,	
		level  = 1,
		target = enemy,
		param  = {0.3}    
	};

get(278, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 4,     
		id     = 278,	
		level  = 1,
		target = enemy,
		param  = {0.5,2}    
	};

get(279, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 4,     
		id     = 279,	
		level  = 1,
		target = enemy,
		param  = {2}    
	};

get(280, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 4,     
		id     = 280,	
		level  = 1,
		target = enemy,
		param  = {1.2}    
	};

get(281, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 4,     
		id     = 281,	
		level  = 1,
		target = enemy,
		param  = {1.2}    
	};

get(282, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 282,	
		level  = 1,
		target = enemy,
		param  = {0.3,2}    
	};

get(283, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 283,	
		level  = 1,
		target = enemy,
		param  = {0.1}    
	};

get(284, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 284,	
		level  = 1,
		target = enemy,
		param  = {0.1}    
	};

get(285, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 285,	
		level  = 1,
		target = enemy,
		param  = {0.5}    
	};

get(286, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 286,	
		level  = 1,
		target = enemy,
		param  = {0.5,2}    
	};

get(287, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 287,	
		level  = 1,
		target = enemy,
		param  = {2}    
	};

get(288, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 288,	
		level  = 1,
		target = enemy,
		param  = {1.2}    
	};

get(289, 1) -> 
	#battle_skill {
		hp     = 0,       
		mp     = 100,
		cd     = 0,     
		id     = 289,	
		level  = 1,
		target = enemy,
		param  = {1.2}    
	};


get(_, _) ->
	#battle_skill {
		hp     = 0,			   
		mp     = 0,   
		cd     = 0,
		id     = 1,
		level  = 0,
		target = enemy   
	}.