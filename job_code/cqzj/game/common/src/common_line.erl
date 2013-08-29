%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  3 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_line).

%% API
-export([get_exit_info/1]).

get_exit_info(Key) ->
    ErrorList = [
                 {shutdown, {10001, "服务器维护"}},
                 {login_again, {10002, "账号在别处登录"}},
                 {not_valid_client, {10003, "系统错误"}},
                 {error_auth_packet, {10004, "认证出错"}},
                 {error_auth_key, {10005, "认证信息过期"}},
                 {fcm_kick_off, {10006, "您已进入不健康游戏时间，请您暂离游戏进行适当休息和运动，合理安排您的游戏时间"}},
                 {world_register_failed, {10007, "系统维护中"}},
                 {mgeem_router_not_found, {10008, "系统维护中"}},
                 {mgeew_role_register_not_run, {10009, "系统维护中"}},
                 {too_many_packet, {10010, "您的网络不稳定，已断开服务器连接"}},
                 {no_heartbeat, {10011, "您的网络不稳定，已从服务器断开连接"}},
                 {etimedout, {10023, "发送数据超时"}},
                 {tcp_error, {10012, "您的网络不稳定，已从服务器断开连接"}},
                 {tcp_closed, {10013, "服务器维护"}},
                 {admin_kick, {10014, "您触犯游戏守则，被管理员踢下线"}},
                 {tcp_send_error, {10015, "您的网络不稳定，已从服务器断开连接"}},
                 {fcm_kick_off_not_enough_off_time, {10017, "您的累计下线时间不满5小时，为了保证您能正常游戏，请您稍后登陆"}},
                 {enter_map_failed, {10016, "系统维护中"}},
                 {bag_data_error, {10018, "背包数据异常，请联系GM！"}},
                 {login_again_timeout, {10019, "重复登陆时等待上一个玩家下线超时"}},
                 {login_again_error, {10020, "重复登录时出错"}},
                 {no_heartbeat, {10021, "2分钟无心跳"}},
                 {walk_error_pos, {10022, "位置不合法，如果重登后再次出现请使用传送符传送到其他位置"}},
                 {account_data_error, {10024, "账户数据异常，请联系GM！"}},
				 {too_many_relogin, {10025, "您今天的重登次数超过游戏限制，请联系GM！"}},
				 {login_at_the_same_time, {10026, "您的账号正在同时登录，若有问题请联系GM"}}
		],
    lists:keyfind(Key, 1, ErrorList).
