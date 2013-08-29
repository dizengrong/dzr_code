-include("mgeem.hrl").

%% ====================================================================
%% Macro
%% ====================================================================
-define(DEFAULT_ARENA_SCORE,100).
-define(ARENA_CHALLENGE_INFO,arena_challenge_info). %%百强挑战的挑战数据
-record(r_arena_challenge_info,{arena_id,owner_id,chllg_id,money_type,chllg_money,chllg_score}). %%百强挑战的挑战数据

-define(ERR_ARENA_ID_INVALID, 101). %%不存在指定的擂台
-define(ERR_ARENA_NO_AVARIABLE_ID, 102). %%没有可用的擂台，请稍后
-define(ERR_ARENA_MAP_NOT_EXISTS, 103). %%对应的竞技场地图不存在

-define(ERR_ARENA_ROLE_STATE_IN_YBC, 202).  %%玩家处于拉镖状态
-define(ERR_ARENA_ROLE_STATE_IN_STALL, 203). %%玩家处于摆摊状态
-define(ERR_ARENA_ROLE_STATE_IN_FACTION_WAR, 204). %%玩家处于国战状态
-define(ERR_ARENA_ROLE_STATE_IN_TRANNING, 205). %%玩家处于训练状态
-define(ERR_ARENA_ROLE_STATE_IN_COLLECT, 206). %%玩家处于训练状态
-define(ERR_ARENA_ROLE_STATE_IN_FB, 207). %%玩家处于副本状态
-define(ERR_ARENA_ROLE_STATE_IN_ARENA_FB, 208). %%玩家已经处于竞技场地图中
-define(ERR_ARENA_ROLE_STATE_IN_FIGHTING, 209). %%玩家已经处于战斗状态
-define(ERR_ARENA_ROLE_STATE_INVALID, 210). %%玩家处于非法状态，不能参与竞技场活动
-define(ERR_ARENA_ROLE_LV_LIMIT, 211). %%玩家级别不够，不能参与竞技场
-define(ERR_ARENA_ROLE_NOT_IN_MAP, 212). %%玩家没有在竞技场的地图中
-define(ERR_ARENA_ROLE_TAKEPARTING, 214). %%您参与的擂台活动尚未完全结束，不能重复参加
-define(ERR_ARENA_ROLE_TAKEPART_MAX_TIMES, 215). %%玩家每天最多参加15次竞技场
-define(ERR_ARENA_ROLE_NOT_IN_TEAM, 216). %%玩家没有组队
-define(ERR_ARENA_ROLE_STATE_IN_TRADING, 217). %%玩家已经处于商贸状态
-define(ERR_ARENA_ROLE_TITLE_LIMIT, 218). %%玩家境界不够，不能参与竞技场
-define(ERR_ARENA_ROLE_STATE_IN_RECRUITMENT, 219). %%玩家已经处于招募状态
-define(ERR_ARENA_ROLE_STATE_DEAD, 220). %%玩家已经处于死亡斗状态
-define(ERR_ARENA_ROLE_STATE_IN_HORSE_RACING, 221). %%玩家在玩钦点美人

-define(ERR_ARENA_ANNOUNCE_NOT_SPECFY_ROLE, 3001).  %%指定挑战必须指定对手名称
-define(ERR_ARENA_ANNOUNCE_STATUS_USED, 3002).   %%该擂台已经被人占用
-define(ERR_ARENA_ANNOUNCE_SILVER_NOT_ENOUGH, 3003).  %%钱币不足，无法摆擂
-define(ERR_ARENA_ANNOUNCE_IN_ARENA_MAP, 3004).  %%必须退出竞技场，才能进行摆擂
-define(ERR_ARENA_ANNOUNCE_SPECIFY_ME, 3005).  %%挑战者指定失败，不能指定跟自己进行挑战
-define(ERR_ARENA_ANNOUNCE_SPECIFY_NOT_EXISTS, 3006).  %%挑战者指定失败，不存在该玩家
-define(ERR_ARENA_ANNOUNCE_SPECIFY_NOT_ONLINE, 3007).  %%该玩家不在线，不能进行挑战
-define(ERR_ARENA_ANNOUNCE_SPECIFY_LV_LIMIT, 3008).  %%对方玩家级别不够，不能指定挑战
-define(ERR_ARENA_ANNOUNCE_SPECIFY_IN_ARENA, 3009).  %%对方玩家正在竞技场中，不能指定挑战
-define(ERR_ARENA_ANNOUNCE_SPECIFY_STATE_INVALID, 3010).  %%对方玩家正在竞技场中，不能指定挑战
-define(ERR_ARENA_ANNOUNCE_NOT_TEAM_LEADER, 3011).  %%只有队长才能进行组队摆擂
-define(ERR_ARENA_ANNOUNCE_CHALLENGER_SCORE_ZERO, 3012).  %%对方擂台积分为0，不能进行挑战


-define(ERR_ARENA_CHALLENGE_STATUS_BLANK, 4001).    %%该擂台还没有摆擂
-define(ERR_ARENA_CHALLENGE_STATUS_PREPARE, 4002).    %%该擂台已处于备战状态
-define(ERR_ARENA_CHALLENGE_STATUS_FIGHT, 4003).    %%该擂台已处于战斗状态
-define(ERR_ARENA_CHALLENGE_STATUS_FINISH, 4004).   %%该擂台已处于结束状态
-define(ERR_ARENA_CHALLENGE_NOT_TEAM_LEADER, 4005).   %%只有队长才能进行组队挑战

-define(ERR_ARENA_CHALLENGE_NO_HERO_LIST, 4101).   %%只有队长才能进行组队挑战
-define(ERR_ARENA_CHALLENGE_ROLE_NOT_IN_RANK, 4102).   %%只有队长才能进行组队挑战
-define(ERR_ARENA_CHALLENGE_HIM_NOT_IN_RANK, 4103).   %%只有队长才能进行组队挑战
-define(ERR_ARENA_CHALLENGE_RANK_NUM_NOT_CORRECT, 4104).   %%只有队长才能进行组队挑战
-define(ERR_ARENA_CHALLENGE_CHLLG_MONEY_LESS_THAN_ZERO, 4105).   %%百强争霸赛的挑战金额不能小于零
-define(ERR_ARENA_CHALLENGE_CHLLG_GOLD_LESS_THAN_50, 4106).   %%百强争霸赛的挑战元宝不能小于50
-define(ERR_ARENA_CHALLENGE_CHLLG_SILVER_LESS_THAN_5, 4107).   %%百强争霸赛的挑战金币不能小于5
-define(ERR_ARENA_CHALLENGE_ROLE_NOT_ONLINE, 4108).     %%挑战对手不在线
-define(ERR_ARENA_CHALLENGE_CHLLG_GOLD_NOT_ENOUGH, 4109).     %%您的挑战元宝不足
-define(ERR_ARENA_CHALLENGE_CHLLG_SILVER_NOT_ENOUGH, 4110).     %%您的挑战金币不足
-define(ERR_ARENA_CHALLENGE_CHLLG_TIMES_OVER_MAX, 4111).        %%挑战失败，超过百强争霸赛每天最多的挑战次数
-define(ERR_ARENA_CHALLENGE_BE_CHLLGED_TIMES_OVER_MAX, 4112).     %%挑战失败，对方超过百强争霸赛每天最多的被挑战次数
-define(ERR_ARENA_INVITER_STATE_IN_YBC, 4113).  %%邀请者正在拉镖，不能参加争霸赛
-define(ERR_ARENA_INVITER_STATE_IN_STALL, 4114). %%邀请者正在摆摊，不能参加争霸赛
-define(ERR_ARENA_INVITER_STATE_IN_FACTION_WAR, 4115). %%邀请者正在国战，不能参加争霸赛
-define(ERR_ARENA_INVITER_STATE_IN_TRANNING, 4116). %%邀请者正在训练状态，不能参加争霸赛
-define(ERR_ARENA_INVITER_STATE_IN_COLLECT, 4117). %%邀请者正在训练状态，不能参加争霸赛
-define(ERR_ARENA_INVITER_STATE_IN_FB, 4118). %%邀请者正在副本中，不能参加争霸赛
-define(ERR_ARENA_INVITER_STATE_IN_ARENA_FB, 4119). %%邀请者正在擂台中，不能参加争霸赛
-define(ERR_ARENA_INVITER_STATE_INVALID, 4120). %%邀请者处于非法状态，不能参加争霸赛
-define(ERR_ARENA_INVITER_STATE_IN_TRADING, 4121). %%邀请者已经在商贸中，不能参加争霸赛
-define(ERR_ARENA_INVITER_LV_LIMIT, 4122). %%邀请者级别不够，不能参加争霸赛
-define(ERR_ARENA_INVITER_TITLE_LIMIT, 4123). %%邀请者境界不够，不能参加争霸赛
-define(ERR_ARENA_INVITER_TAKEPART_MAX_TIMES, 4124). %%邀请者每天最多被挑战5次
-define(ERR_ARENA_INVITER_STATE_DEAD, 4125). %%邀请者处于死亡状态，不能参加争霸赛
-define(ERR_ARENA_CHALLENGE_ROLE_INTERVAL, 4130). %%10秒内不要频繁挑战哦
-define(ERR_ARENA_INVITER_STATE_IN_HORSE_RACING, 4131). %%邀请者正在玩钦点美人，不能参加争霸赛



-define(ERR_ARENA_ANSWER_STATUS_BLANK, 7001).    %%该擂台还没有摆擂
-define(ERR_ARENA_ANSWER_STATUS_PREPARE, 7002).    %%该擂台已处于备战状态
-define(ERR_ARENA_ANSWER_STATUS_FIGHT, 7003).    %%该擂台已处于战斗状态
-define(ERR_ARENA_ANSWER_STATUS_FINISH, 7004).   %%该擂台已处于结束状态

-define(ERR_ARENA_WATCH_STATUS_BLANK, 8001).    %%该擂台还没有摆擂
-define(ERR_ARENA_WATCH_STATUS_FINISH, 8002).   %%该擂台已经结束，不能进入
-define(ERR_ARENA_WATCH_LV_LIMIT, 8003).   %%观众的级别限制
-define(ERR_ARENA_WATCH_TYPE_LIMIT, 8004).   %%擂台类型的限制，该类型不能观看
-define(ERR_ARENA_WATCH_TITLE_LIMIT, 8005).   %%观众的境界限制

-define(ERR_ARENA_QUIT_NOT_IN_MAP, 9001).  %%你不在竞技场，无需退出
-define(ERR_ARENA_ASSIST_SILVER_NOT_ENOUGH, 11001).   %%钱币不足，无法补血
-define(ERR_ARENA_ASSIST_NOT_IN_MAP, 11002).   %%你不在竞技场，不能补血
-define(ERR_ARENA_ASSIST_WHILE_FIGHT, 11003).   %%战斗阶段不能进行补血
-define(ERR_ARENA_WATCHER_REQ_READY, 12001).   %%观众不可以申请开战
-define(ERR_ARENA_READY_STATE_IN_FIGHT, 12003).   %%战斗已经开始，无需申请开战
-define(ERR_ARENA_READY_STATE_ERROR, 12004).   %%必须在备战阶段才能使用此功能
-define(ERR_ARENA_READY_ONLY_LEADER, 12005).   %%只有队长才能申请开战

-define(ERR_ARENA_TEAM_JOIN_STATUS_BLANK, 14001).    %%擂台尚未摆擂，不能加入
-define(ERR_ARENA_TEAM_JOIN_STATUS_FIGHT, 14002).   %%擂台正在战斗中，不能加入
-define(ERR_ARENA_TEAM_JOIN_STATUS_FINISH, 14003).   %%擂台已经结束，不能加入
-define(ERR_ARENA_TEAM_JOIN_SELF, 14004).   %%您已经摆擂，无需加入
-define(ERR_ARENA_TEAM_JOIN_FACTION_NOT_SAME, 14005).   %%必须相同国家，才能加入此队伍
-define(ERR_ARENA_TEAM_JOIN_MUST_LEAVE_TEAM, 14006).   %%必须先退出原有队伍，才能加入组队擂台
-define(ERR_ARENA_TEAM_JOIN_TEAM_MEMBER_FULL, 14007).   %%该队伍人数已满，不能加入
-define(ERR_ARENA_TEAM_JOIN_WAIT_CONFIRM, 14008).   %%请等待队长的确认
-define(ERR_ARENA_TEAM_JOIN_MEMBER_NOT_IN_LIST, 14009).   %%该队员没有在请求队列中
-define(ERR_ARENA_TEAM_JOIN_LEADER_REJECT, 14010).   %%队长拒绝了您的请求

-define(ERR_ARENA_RESULT_GET_CHLLG_MONEY, 15001).   %%获取挑战金额出错
-define(ERR_ARENA_GAIN_CHLLG_MONEY_GOLD, 15002).   %%获赠百强挑战的元宝出错
-define(ERR_ARENA_GAIN_CHLLG_MONEY_SILVER, 15003).   %%获赠百强挑战的钱币出错
-define(ERR_ARENA_DEDUCT_CHLLG_MONEY_GOLD, 15004).   %%扣除百强挑战的元宝出错
-define(ERR_ARENA_DEDUCT_CHLLG_MONEY_SILVER, 15005).   %%扣除百强挑战的钱币出错



%%擂台的类型
-define(TYPE_ONE2ONE, 1).
-define(TYPE_HERO2HERO, 2).

%%擂台的子类型
-define(SUBTYPE_ONE2ONE, 11).
-define(SUBTYPE_HERO2HERO, 21).


-define(ANNOUNCE_TYPE_OWN,1).
-define(ANNOUNCE_TYPE_CHLLG,2).


%%擂台的状态，(0:空，1：摆擂阶段，2：备战阶段，3：战斗阶段，4：已结束
-define(STATUS_BLANK, 0).
-define(STATUS_ANNOUNCE, 1).
-define(STATUS_PREPARE, 2).
-define(STATUS_FIGHT, 3).
-define(STATUS_FINISH, 4).


%%擂台的结果:0=尚未结束，1=擂主战胜，2=挑战者战胜，3=平局(战斗超时)，4=擂主备战时退出，5=挑战者备战时退出，6=擂主战斗时退出，7=挑战者战斗时退出，8=擂主摆擂时退出，9=摆擂超时，10=邀请方拒绝参战，11=邀请方不能参战
-define(RESULT_NORMAL, 0).
-define(RESULT_WIN_OWNER, 1).
-define(RESULT_WIN_CHALLENGER, 2).
-define(RESULT_DRAW, 3).
-define(RESULT_QUIT_PREPARE_OWNER, 4).
-define(RESULT_QUIT_PREPARE_CHALLENGER, 5).
-define(RESULT_QUIT_FIGHT_OWNER, 6).
-define(RESULT_QUIT_FIGHT_CHALLENGER, 7).
-define(RESULT_QUIT_ANNOUNCE, 8).
-define(RESULT_ANNOUNCE_TIMEOUT, 9).
-define(RESULT_INVITE_REJECT, 10).
-define(RESULT_INVITE_INVALID, 11).

%%参与者的角色
-define(PARTTAKE_TYPE_WATCHER, 0).      %%观众
-define(PARTTAKE_TYPE_OWNER, 1).    %%擂主
-define(PARTTAKE_TYPE_CHALLENGER, 2).   %%挑战者

%%应答挑战的类型
-define(ANSWER_ACTION_AGREE, 1).    %%同意
-define(ANSWER_ACTION_REJECT, 2).    %%拒绝
-define(ANSWER_ACTION_GIVEUP, 3).    %%放弃
-define(ANSWER_ACTION_SYS_CHECK, 999).    %%系统判断的应答

%%退出竞技场的类型
-define(QUIT_TYPE_NORMAL, 0).    %%0表示正常主动退出，1表示退出并重生，2表示清场的退出
-define(QUIT_TYPE_RELIVE, 1).   
-define(QUIT_TYPE_CLEAR, 2).  

-define(LOG_FIGHT_RESULT_WIN, 1).	%%胜败  
-define(LOG_FIGHT_RESULT_DRAW, 2).	%%平局


%%应答挑战的类型
-define(EGG_ACTION_ADD, 1).    %%彩蛋新增
-define(EGG_ACTION_DEL, 2).    %%彩蛋消失
-define(EGG_ACTION_CLEAR, 3).  %%清除所有彩蛋

%%辅助功能的类型
-define(ASSIST_ACTION_ADD_HP, 1).	%%加血
-define(ASSIST_ACTION_REQ_READY, 2).    %%申请立即开展

%%指名摆擂的烈性
-define(SPECIFY_TYPE_NO, 0).   %%无
-define(SPECIFY_TYPE_YES, 1).  %%单人擂台的指名挑战


%%加入队伍的类型
-define(JOIN_TEAM_OWNER, 1).	%%加入擂主方
-define(JOIN_TEAM_CHALLENGER, 2).    %%加入挑战方


