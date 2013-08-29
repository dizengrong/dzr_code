%%%----------------------------------------------------------------------
%%% File    : mgeev.erl
%%% Author  : Liangliang
%%% Purpose : MGEE application
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeem).

-behaviour(application).
-include("mgeem.hrl").
-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [mgeem]).

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
    {ok, SupPid} = mgeem_sup:start_link(),
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
       {"Refining Forging Config init",
        fun() ->
                mod_forging_config:init()
        end},
       {"Trading Config init",
        fun() ->
                mod_trading_config:init()
        end},
       {"Init Shop Config",
        fun() ->
                mod_shop:init()
        end},
       {"Init Equip Build Server Config",
        fun() ->
                mod_equip_build:init_ets()
        end},
       {"Init Drop ID ETS Table",
        fun() ->
                mod_map_drop:init()
        end},
	   {"mod_stall_server",
        fun() ->
                mod_stall_server:start()
        end},
       {"MGEE MAP Router Server",
        fun () ->
                mgeem_router:start(),
                mgeem_map_sup:start()
        end},
       {"Start Maps",
    	fun() ->
                start_maps()
    	end},
       {"MGEE MAP Skill Init",
        fun () ->
                mod_skill_manager:start()
        end},
       {"MGEE MAP Exchange Init",
        fun() ->
                mod_exchange:init()
        end},
       {"MGEEM Persistent Server",
        fun() ->
                mgeem_persistent:start()
        end},
	     {"MGEE MAP Singleton Server",
        fun () ->
                mod_arena_manager:start()
        end},
       {"MGEEM Event Server",
        fun() ->
                mgeem_event:start()
        end},
  	   {"Mirror Ranking Match",
  		fun() ->
  				mod_mirror_rnkm:start()
  		end},
  	   {"Mirror Ranking Match",
  		fun() ->
  				mod_mirror_clgm:start()
  		end},
  		{"FAMILY IDOL",
  		fun() ->
  				mod_map_fml_idol:start()
  		end},
      {"mod_wantbuy_server",
        fun() ->
                mod_wantbuy_server:start()
        end},
  		{"WORSHIP",
  		fun() ->
  				mod_role_worship:start()
  		end},
	   {"Egg Shop Server",
		fun() ->
				mod_egg_shop_server:start()
		end}
        ]),
    ?SYSTEM_LOG("~ts~n", ["mgeem启动成功"]),
    {ok, SupPid}.

%% --------------------------------------------------------------------
stop(_State) ->
    ok.

start_maps() -> 
    %%预创建的地图
    PreMainMapIdList = [10001, 10250, 10260, 10261, 10262, 10263, ?COUNTRY_TREASURE_MAP_ID],
    [PreFbMapIdList] = common_config_dyn:find(etc,prestart_fb_map_id_list),
    lists:foreach(fun(MapID) ->
    	mod_map_loader:create_map(MapID)
    end, PreMainMapIdList ++ PreFbMapIdList ++ cfg_single_fb:multi_player_fb_maps()),
    %% 开始创建地图，前面已经创建好几张压力较大的地图了
    mod_map_loader:auto_create_maps(),    
    mod_map_loader:create_family_maps(),
    %%提前创建晶矿战的地图
    mod_mine_fb:init_miner_maps(),
    ?SYSTEM_LOG("~ts~n", ["地图预创建完成"]),
    ok.