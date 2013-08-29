-module(test_boss_logger).
-compile(export_all).
-include("common.hrl").
-export([
         test_boss_logger/0,
	 test_personal_ybc_logger/0,
	 test_family_ybc_logger/0
        ]).


test_boss_logger()->
    ItemList = [
                   #r_log_boss_item_drop{item_typeid = 65646,color=3 ,quality = 0},
                   #r_log_boss_item_drop{item_typeid = 45464, quality  = 0,color=2},
                   #r_log_boss_item_drop{item_typeid = 34343,color=4}
                ],
    BossLog = #r_log_boss_state{
                    boss_id = 5,
                    boss_state = 2,
                    mtime = common_tool:now(),
                    drop_item = ItemList,
                    last_hurt_player = 2121210
                 },
    common_general_log_server:log_boss(BossLog).



test_personal_ybc_logger()->
    A = #r_personal_ybc_log{role_id=101,start_time=2454545405,ybc_color=5,final_state=2,end_time=1587965482},
    common_general_log_server:log_personal_ybc(A),
    common_general_log_server:log_personal_ybc(A),
    common_general_log_server:log_personal_ybc(A).
    
    


test_family_ybc_logger()->
    A = #r_family_ybc_log{
      family_id = 1245,
      ybc_no = 1231,
      mtime = 12948048989,
      content = "niceboat"
     },
    common_general_log_server:log_family_ybc(A).
