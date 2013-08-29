%%%----------------------------------------------------------------------
%%% @copyright 2010 mgeew (Ming Game Engine Erlang - World Server)
%%%
%%% @author odinxu, 2010-03-24
%%% @doc MGEE World Application
%%% @end
%%%----------------------------------------------------------------------

-module(mgeew).

-behaviour(application).
-include("mgeew.hrl").

-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [mgeew]).

%% --------------------------------------------------------------------
 
start() ->
    try
        ok = common_misc:start_applications(?APPS) 
    after
        %%give the error loggers some time to catch up
        timer:sleep(100)
    end.

stop() ->
    ok = common_misc:stop_applications(?APPS).


%% --------------------------------------------------------------------
start(normal, []) ->
    {ok, SupPid} = mgeew_sup:start_link(),
    lists:foreach(
      fun ({Msg, Thunk}) ->
              io:format("starting ~-32s ...", [Msg]),
              Thunk(),
              io:format("done~n");
          ({Msg, M, F, A}) ->
              io:format("starting ~-20s ...", [Msg]),
              apply(M, F, A),
              io:format("done~n")
      end,
      [
	   {"Common Role Line Map Server",
        fun() ->
                common_role_line_map:start(mgeew_sup)
        end},
       {"User Event Server",
        fun() ->
                mgeew_user_event:start()
        end},    
       {"Pay Server",
        fun() ->
                mgeew_pay_server:start()
        end},
	   {"Office Server",
        fun() ->
                mgeew_office:start()
        end},
        {"Event Server",
        fun() ->
                mgeew_event:start()
        end},
       {"System Buff",
        fun() ->
                mgeew_system_buff:start()
        end},
       {"MGEE World - Log Server",
        fun() ->
                mgeew_behavior_log_server:start(),
                mgeew_consume_log_server:start(),
                common_general_log_server:start(mgeew_sup),
                common_item_log_server:start(mgeew_sup),
        				mgeew_pet_log_server:start(),
        				mgeew_prestige_log_server:start(),
                mgeew_yueli_log_server:start(),
                mgeew_super_item_log_server:start()
        end},
       {"MGEE World Mission Log Server Init ",
        fun () ->
                mgeew_mission_log_server:start(),
                mgeew_loop_mission_log_server:start()
        end},
	   {"MGEE country_treasure Log Server Init ",
        fun () ->
                mgeew_country_treasure_log_server:start()
        end},
       {"MGEE Family Server",
        fun() ->
                mod_family_data_server:start(),
                mod_family_manager:start()
        end
       },
       {"MGEE Team Server",
        fun () ->
                mod_team_server:start()
        end},
       {"MGEE Skill_server",
        fun () ->
                mgeew_skill_server:start()
        end},
       {"MGEE Mgeew_letter_server ok Server",
        fun() ->
                mgeew_letter_server:start()
        end},
       {"MGEE Mgeew_admin_server ok Server",
        fun() ->
                mgeew_admin_server:start()
        end},
       {"MGEE Mgeew_online ok Server",
        fun() ->
                mgeew_online:start()
        end},
       {"MGEEW Money Event Server",
        fun() ->
                mgeew_money_event_server:start()
        end},
       {"Mod Friend Server",
        fun () ->
                mod_friend_server:start()
        end},
       {"Mod Broadcast Server",
        fun() ->
                db:change_table_copy_type(?DB_BROADCAST_MESSAGE,node(),ram_copies),
                mgeew_broadcast_loop_server:start_link(),
                mod_broadcast_server:start()
        end },
        {"common_title_srv init",
        fun() ->
                common_title_srv:start()
        end},
       {"Ranking Server",
        fun() ->
                mod_rankreward_server:start(),
                mgeew_ranking:start()
        end },
       {"Special Activity Server",
        fun() ->
                mgeew_special_activity:start(),
                mgeew_accgold_server:start(),
                mgeew_activity_server:start()
        end},
       {"MGEE Team Recruitment Server Init",
        fun () ->
                mgeew_team_recruitment_server:start()
        end},
       {"Activity Schedule Server",
        fun() ->
                mgeew_activity_schedule:start()
        end},
		{"Open Activity Server",
        fun() ->
                mgeew_open_activity:start()
        end},
        {"mgeew_crown_arena_server",
        fun() ->
                mod_mine_fb_manager:start(),
                mgeew_crown_arena_server:start()
        end},
	   {"mod_treasbox_manager",
        fun() ->
                mod_treasbox_manager:start()
        end},
       {"mgeew_horse_racing Init",
        fun() ->
                mgeew_horse_racing:start()
        end},
       {"mod_tower_fb_manager",
        fun() ->
                mod_tower_fb_manager:start()
        end},
	   {"mod_swl_mission_manager",
        fun() ->
                mod_swl_mission_manager:start()
        end}
      ]
     ),
    ?SYSTEM_LOG("~ts~n", ["mgeew启动成功"]),
    {ok, SupPid}.

%% --------------------------------------------------------------------
stop(_State) ->
    
    ok.

