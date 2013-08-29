-record(r_msg,{unique, module,method,data, roleid, pid, line, state}).
-record(educate_config,{npc,invite_time,invite_ets,title,expel,dropout,range,teacher_gift,student_gift,graduate_level,educate_level,gift_start_level,dropout_moral_rate, expel_moral_rate,moral_exp,gift1_rate,gift2_rate}).

-define(GET_FACTION(FactionID),case FactionID of 1 -> "<font color=\"#00FF00\">西夏</font>";2 -> "<font color=\"#F600FF\">南诏</font>";3 -> "<font color=\"#00CCFF\">东周</font>" end).

-define(EDUCATE_HELP_TIME_AND_DEAD_POS,educate_help_time_and_dead_pos).
%%不接受求助信息的持续时间
-define(IGNORE_LAST_TIME,5*60).

-define(EDUCATE_CALL_HELP_MESSEGE,"你的~s[<font color=\"#ffff00\">~s</font>]正被袭击，是否前往救援？本消息5分钟内不会重复。").