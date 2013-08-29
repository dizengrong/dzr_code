%% Author: xierongfeng
%% Created: 2013-1-20
%% Description:
-module(mod_qq_cache).

%%
%% Include files
%%
-include("mgeer.hrl").

%%qq open api 公共参数
-record(qq_params, {
    role_id,
    openid,
    openkey,
    pf,
	pfkey
}).

%%qq vip 信息
-record(qq_vip, {
    role_id,
	is_yellow_vip      = false, 
	is_yellow_year_vip = false, 
	yellow_vip_level   = 0
}).

-define(T_QQ_PARAMS, t_qq_params).
-define(T_QQ_VIP   , t_qq_vip).
-define(T_QQ_ROLEID, t_qq_roleid).

%%
%% Exported Functions
%%
-export([
	init/0,
 	set_params/5,
	get_params/1,
 	set_roleid/2,
 	set_vip/4,
	get_roleid/1,
	get_vip/1
 ]).

%%
%% API Functions
%%
init() ->
	ets:new(?T_QQ_PARAMS, [named_table, public, {keypos, #qq_params.role_id}]),
	ets:new(?T_QQ_VIP, 	  [named_table, public, {keypos, #qq_vip.role_id}]),
	ets:new(?T_QQ_ROLEID, [named_table, public]),
	ets:insert(?T_QQ_ROLEID, {"test", 1}).

set_params(RoleID, Openid, Openkey, Pf, Pfkey) ->
	ets:insert(?T_QQ_PARAMS, #qq_params{
		role_id = RoleID,
		openid  = Openid,
		openkey = Openkey,
		pf      = Pf,
		pfkey	= Pfkey
	}).

get_params(RoleID) ->
	case ets:lookup(?T_QQ_PARAMS, RoleID) of
		[#qq_params{
			openid  = Openid,
			openkey = Openkey,
			pf      = Pf,
			pfkey	= Pfkey
		}] ->
			{ok, Openid, Openkey, Pf, Pfkey};
		_ ->
			{ok, "Openid", "Openkey", "Pf", "Pfkey"}
	end.

set_roleid(Openid, RoleID) ->
	ets:insert(?T_QQ_ROLEID, {Openid, RoleID}).

get_roleid(Openid) ->
	case ets:lookup(?T_QQ_ROLEID, Openid) of
		[{_, RoleID}] ->
			RoleID;
		_ ->
			0
	end.

set_vip(RoleID, IsYellowVip, IsYellowYearVip, YellowVipLevel) ->
	ets:insert(?T_QQ_VIP, #qq_vip{
		role_id            = RoleID,
		is_yellow_vip      = IsYellowVip, 
		is_yellow_year_vip = IsYellowYearVip, 
		yellow_vip_level   = YellowVipLevel
	}).

get_vip(RoleID) ->
	case ets:lookup(?T_QQ_VIP, RoleID) of
		[#qq_vip{
			is_yellow_vip      = IsYellowVip, 
			is_yellow_year_vip = IsYellowYearVip,
			yellow_vip_level   = YellowVipLevel
		}] ->
			{ok, IsYellowVip, IsYellowYearVip, YellowVipLevel};
		_ ->
			{ok, false, false, 0}
	end.
