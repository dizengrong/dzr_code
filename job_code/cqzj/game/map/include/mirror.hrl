-define(WORK_TICK, 200).

-record(ai_driver, {id, time, interval, msg}).

-record(ai_state, {actor_type, 
				   actor_id,
				   role_id,
				   enemy_id,
				   work_time=0, 
				   active=false,
				   stop_driver, 
				   follow_driver, 
				   attack_driver, 
				   skill1_driver,
				   skill2_driver,
				   skill3_driver,
				   skill4_driver,
				   skill5_driver,
				   skill6_driver,
				   skill7_driver,
				   skill8_driver,
				   skill9_driver,
				   skill10_driver,
				   skill11_driver,
				   skill12_driver,
				   skill13_driver,
				   skill14_driver,
				   skill15_driver, 
				   msgs=[]}).
