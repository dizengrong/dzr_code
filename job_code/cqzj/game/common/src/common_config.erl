%%%-------------------------------------------------------------------
%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 27 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_config).

-include("common.hrl").

%% API
-export([
         is_debug_sql/0,
         is_account_case_sensitive/0,
         get_host_info/0,
         get_line_start_port/0,
         get_line_acceptor_num/0,
         get_login_port/0,
         get_login_acceptor_num/0,
         get_receiver_http_host/0,
         get_receiver_host/0,
         get_chat_config/0,
         get_root_config_file_path/1,
         get_map_config_dir/0,
         get_world_config_file_path/1,
         get_map_config_file_path/1,
         get_map_jump_config/0,
         get_event_config/0,
         get_mysql_config/0,
         get_warofking_config/0,
         is_debug/0,
         get_map_info_config/0,
         get_mission_setting/0,
         get_mission_file_path/0,
         get_behavior_node_name/0,
         get_levelexps/0,
         get_map_slave_num/0,
         get_map_slave_weight_list/0,
         get_receiver_host_acceptor_num/0,
         get_level_channel_list/0,
         get_open_day/0,
         get_opened_days/0,
         is_fcm_open/0,
         get_driver_config/0,
         get_agent_name/0,
         get_agent_id/0,
         get_line_auth_key/0,
         get_fcm_validation_key/0,
         get_fcm_validation_url/0,
         chk_module_method_open/2,
         is_activity_pay_first_open/0,
         set_activity_pay_first_flag/1,
         is_client_stat_open/0,
         get_log_level/0,
         get_super_key/0,
         get_server_dir/0,
         get_logs_dir/0,
         get_mnesia_dir/0,
         get_server_id/0,
         get_server_name/0,
         get_node_name/1,
         get_security_node_name/0,
         get_map_master_node/0,
         get_db_node_name/0,
         get_stop_prepare_second/0,
         get_stop_prepare_msg/0,
         is_live_start/0,
		 is_merge/0,
         get_check_name_url/0
        ]).

get_mnesia_dir() ->
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    "/data/database/cqzj_" ++ AgentName ++ "_" ++ ServerName ++ "/".


get_super_key() ->
    [Val] = common_config_dyn:find_common(line_super_key),
    Val.    

get_log_level() ->
    [Val] = common_config_dyn:find_common(log_level),
    Val.

%% 是否活动是否打开了
is_activity_pay_first_open() ->
    case db:dirty_read(?DB_CONFIG_SYSTEM_P, open_pay_first) of
        [] ->
            false;
        [#r_config_system{value=Value}] ->
            case Value of
                true ->
                    true;
                _ ->
                    false
            end
    end.

%% 控制首充活动开关
set_activity_pay_first_flag(Flag) ->
    case Flag of
        true ->
            db:transaction(
              fun() ->
                      db:write(?DB_CONFIG_SYSTEM_P, {r_config_system, open_pay_first, true}, write)
              end);
        _ ->
            db:transaction(
              fun() ->
                      db:write(?DB_CONFIG_SYSTEM_P, {r_config_system, open_pay_first, false}, write)
              end)
    end.

%% 判断某个模块是否打开了
chk_module_method_open(Module, Method) ->
	case common_config_dyn:find(module_method_close, Module) of
		[] ->
			case common_config_dyn:find(module_method_close, {Module, Method}) of
				[] ->
					true;
				[Reason] ->
					{false, Reason}
			end;
		[Reason] ->
			{false, Reason}
	end.

%% 获取防沉迷验证的地址
get_fcm_validation_url() ->
    [Val] = common_config_dyn:find_common(fcm_validation_url),
    Val.

get_fcm_validation_key() ->
    [Val] = common_config_dyn:find_common(fcm_validation_key),
    Val.

%% 获取代理商名字    
get_agent_name() ->
    [Val] = common_config_dyn:find_common(agent_name),
    Val.

%% 获取游戏服ID
get_agent_id() ->
    [Val] = common_config_dyn:find_common(agent_id),
    Val.
get_server_id() ->
    [Val] = common_config_dyn:find_common(server_id),
    Val.
get_server_name() ->
    [Val] = common_config_dyn:find_common(server_server),
    Val.
%% 获得停止分线之前的广播时间，单位为秒
get_stop_prepare_second() ->
    [Val] = common_config_dyn:find(etc, stop_prepare_second),
    Val.

get_stop_prepare_msg() ->
    [Val] = common_config_dyn:find(etc, stop_prepare_msg),
    Val.
%% 获取开服日志 {{Year, Month, Day}, {Hour, Min, Sec}}
get_open_day() ->
    [Val] = common_config_dyn:find_common(server_start_datetime),
    Val.

%% 获得当前为开服第几天，如果今天是6月28日，开服日期为6月28日，则今天为开服第一天，返回1
get_opened_days() ->
    {Date, _} = get_open_day(),
    {Date2, _} = erlang:localtime(),
    erlang:abs( calendar:date_to_gregorian_days(Date) - calendar:date_to_gregorian_days(Date2) ) + 1.

%% 判断防沉迷是否打开，直接从数据库中读取
is_fcm_open() ->
    case db:dirty_read(?DB_CONFIG_SYSTEM_P, fcm) of
        [] ->
            false;
        [#r_config_system{value=Value}] ->
            case Value of
                true ->
                    true;
                _ ->
                    false
            end
    end.

%%@doc 设置为true可以输出erlang的sql语句
is_debug_sql()->
    false.

%%@doc 判断是否账户名大小写敏感
is_account_case_sensitive()->
    get_agent_name() =:= "kaixin001".


is_debug() ->
    [Val] = common_config_dyn:find(common, is_debug),
    Val.

get_line_auth_key() ->
    [Val] = common_config_dyn:find(common, line_auth_key),
    Val.

get_receiver_host_acceptor_num() ->
    [Val] = common_config_dyn:find_common(receiver_host_acceptor_num),
    Val.

    
get_map_slave_num() ->
    HostInfoConfig = get_host_info(),
    case lists:keyfind(map_slave_num, 1, HostInfoConfig) of
        {map_slave_num, SlaveNum} when is_integer(SlaveNum)->
            SlaveNum;
        _ ->
            3
    end.

get_map_slave_weight_list() ->   
    HostInfoConfig = get_host_info(),
    lists:foldl(
      fun(Item, Result) ->
              Name = erlang:element(1, Item),
              case Name of
                  map_slave_weight -> 
                      [Item|Result];
                  _ ->
                      Result
              end
      end, [], HostInfoConfig).

get_server_dir() ->
    {ok, [[ServerDir]]} = init:get_argument(server_dir),
    ServerDir.
get_logs_dir() ->
    {ok, [[LogsDir]]} = init:get_argument(logs_dir),
    LogsDir.
get_levelexps() ->
    {ok, [LevelExps]} = file:consult(lists:concat([get_server_dir(), "config/level.config"])),
    LevelExps.

%%读取事件配置文件
get_event_config() ->
    EventConfigFile = lists:concat([get_server_dir(), "config/event.config"]),
    {ok, EventConfig} = file:consult(EventConfigFile),
    EventConfig.

get_warofking_config() ->
    Config = ?MODULE:get_event_config(),
    proplists:get_value(mod_event_warofking, Config).


get_mysql_config() ->
    [Val] = common_config_dyn:find_common(mysql_config),
    Val.

%%获得当前所有分线的配置信息
get_host_info() ->
    HostInfoConfigFile = lists:concat([get_server_dir(), "setting/host_info.config"]),
    {ok, HostInfoConfig} = file:consult(HostInfoConfigFile),
    HostInfoConfig.

get_login_port() ->
    HostInfoConfig = get_host_info(),
    {login_port, LoginPort} = lists:keyfind(login_port, 1, HostInfoConfig),
    LoginPort.

get_login_acceptor_num() ->
    HostInfoConfig = get_host_info(),
    {login_acceptor_num, LoginAcceptorNum} = lists:keyfind(login_acceptor_num, 1, HostInfoConfig),
    LoginAcceptorNum.

get_line_start_port() ->
    HostInfoConfig = get_host_info(),
    {line_start_port, LineStartPort} = lists:keyfind(line_start_port, 1, HostInfoConfig),
    LineStartPort.

get_line_acceptor_num() ->
    HostInfoConfig = get_host_info(),
    {line_acceptor_num, LineAcceptorNum} = lists:keyfind(line_acceptor_num, 1, HostInfoConfig),
    LineAcceptorNum.

get_receiver_host() ->
    RecvHostList = common_config_dyn:find_common(receiver_host),
    lists:foldl(
      fun(RecvHost,Result)->
              {Host,Post} = RecvHost,
              [{receiver_host,Host,Post}|Result]
              end, [], RecvHostList).

get_receiver_http_host() ->
    HostInfoConfig = get_host_info(),
    lists:keyfind(receiver_web, 1, HostInfoConfig).
   
get_behavior_node_name() ->
    HostInfoConfig = get_host_info(),
    {behavior_node, BehaviorNodeName} = lists:keyfind(behavior_node, 1, HostInfoConfig),
    BehaviorNodeName.
     
get_node_name(ShortNodeName) ->
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    lists:concat([ShortNodeName,"_",AgentName,"_",ServerName,"@"]).
%% 一台多服只开一个security 节点
get_security_node_name() ->
    lists:concat(["mgees@"]).

get_db_node_name() ->
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    lists:foldl(
      fun(Node, Acc) ->
              Node2 = erlang:atom_to_list(Node),
              case string:str(Node2, lists:concat(["mgeed_",AgentName,"_",ServerName,"@"])) =:= 1 of
                  true ->
                      Node;
                  _ ->
                      Acc
              end
      end, erlang:node(), [erlang:node() | erlang:nodes()]).

get_map_master_node() ->
    [MasterMapHost] = common_config_dyn:find_common(master_host),
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    common_tool:list_to_atom(lists:concat(["mgeem_", AgentName, "_", ServerName, "@", MasterMapHost])).

get_chat_config() ->
    HostInfoConfig = get_host_info(),
    lists:keyfind(chat_config, 1, HostInfoConfig).
get_root_config_file_path(ConfigName) ->
    lists:concat([get_server_dir(),"config/", ConfigName ,".config"]).
get_map_config_dir() ->
    lists:concat([get_server_dir(), "config/map/mcm/"]).
get_map_config_file_path(shop_npcs) ->
    lists:concat([get_server_dir(), "config/map/shop_npcs.config"]);
get_map_config_file_path(shop_price_time) ->
    lists:concat([get_server_dir(), "config/map/shop_price_time.config"]);
get_map_config_file_path(shop_shops) ->
    lists:concat([get_server_dir(), "config/map/shop_shops.config"]);
get_map_config_file_path(shop_test) ->
    lists:concat([get_server_dir(), "config/map/shop_test.config"]);
get_map_config_file_path(collect) ->
    lists:concat([get_server_dir(), "config/map/collect_base_info.config"]);
get_map_config_file_path(country_treasure) ->
    lists:concat([get_server_dir(), "config/map/country_treasure.config"]);
get_map_config_file_path(ConfigName) ->
    lists:concat([get_server_dir(),"config/map/", ConfigName ,".config"]).

  
%% 获得地图跳转点信息
get_map_jump_config() ->  
    FilePath = lists:concat([get_server_dir(), "config/map_jump.config"]),
    {ok, JumpList} = file:consult(FilePath),
    JumpList.

get_level_channel_list() ->
    FilePath = lists:concat([get_server_dir(), "config/level_channel.config"]),
    {ok, LevelChannelList} = file:consult(FilePath),
    LevelChannelList.

get_driver_config() ->
    FilePath = lists:concat([get_server_dir(), "config/driver.config"]),
    {ok, ConfigList} = file:consult(FilePath),
    ConfigList.
   
get_mission_file_path() ->
    lists:concat([get_server_dir(), "config/mission/"]).

%% 所有world模块配置文件路径
get_world_config_file_path(broadcast_admin) ->
    lists:concat([get_server_dir(), "config/map/broadcast_admin_data.config"]);
get_world_config_file_path(ConfigName) ->
    lists:concat([get_server_dir(),"config/map/", ConfigName ,".config"]).

get_map_info_config() ->
    ConfigFile = lists:concat([get_server_dir(), "config/map_info.config"]),
    {ok, List} = file:consult(ConfigFile),
    List.

get_mission_setting() ->
    MissionDataDir = get_mission_file_path(),
    {ok, DataList} = file:consult(MissionDataDir ++ "mission_setting.config"),
    DataList.

is_client_stat_open()->
	case common_config_dyn:find(stat,button) of
		[true]->true;
		_->false
	end.
		
is_live_start()->
    case init:get_argument(action) of
        {ok,[["live"]]}->
            true;
        Info->
            Info
    end.
%% 本服务器是否是合服后的服务器
is_merge() ->
    case common_config_dyn:find(common, is_merged) of
        [true] ->
            true;
        _ ->
            false
    end.
%% 查检玩家名字是否合法
get_check_name_url() ->
    [Val] = common_config_dyn:find(common, check_name_url),
    Val.