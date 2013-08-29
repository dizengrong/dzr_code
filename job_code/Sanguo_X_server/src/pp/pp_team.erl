%% Author: cjr
%% Created: 2011-9-22
%% Description: 
-module(pp_team).

-export([handle/3]).

-include("common.hrl").

handle(30000, Id, Npc_id) ->
	?INFO(team, "creating team in ~w",[Npc_id]),
	mod_team:create_team(Id,Npc_id);
	

handle(30001, Id, {Ops_code,Name}) ->
	case Ops_code of
		0	->
			?INFO(team, "~w invite ~w", [Id, Name]),
			mod_team:invite(Id,Name);
		1	->
			?INFO(team, "~w request to add to team ~w", [Id,Name]),
			mod_team:add_team(Id,Name)
	end;
	

handle(30002, Id, {Result,Team_lead_id}) ->
	case Result of 
		%% 0 accept, 1 reject
		0->
			mod_team:accept_invite(Id,Team_lead_id);
		_->
			?INFO(team, "reject invitation to team, nothing to do.",[])
	end,
			
	ok;

handle(30006, Id, {Result,Team_mate_id}) ->
	case Result of 
		%% 0 accept, 1 reject
		0->
			?INFO(team,"leader id ~w approve ~w to add to team",[Id, Team_mate_id]),
			mod_team:approve(Id,Team_mate_id);
		_->
			?INFO(team, "reject add to team, nothing to do.",[])
	end,
	ok;

handle(30003, Id, _) ->
	mod_team:resign_lead(Id),
	ok;

handle(30005, Id, {Op_code}) ->
%% 副本外：
%% 	C1解散/踢出队伍
%% 	C2 主动离开副本
%% 副本内：
%% 	C1，C2,主动离开副本
%% CMSG_TEAM_LEAVE					=30004			
%% byte：		操作 0 离开 1 解散 2踢出
	case Op_code of
		0->
			?INFO(team,"team mate leave scene"),
			mod_team:leave_scene(Id);
		1->
			?INFO(team,"team lead dismiss team"),
			mod_team:dismiss(Id);
		2->
			?INFO(team,"team lead fire his team mate"),
			mod_team:fire(Id);
		_->
			?ERR(team, "Unknown ops code",[])
	end,
	ok;

handle(30009, Id, {Scene_code}) ->
	mod_team:get_team_list(Id,Scene_code),
	ok;

handle(30011, Id, {}) ->
	mod_team:team_chat_window(Id),
	ok;

handle(30012, Id, {Content}) ->
	mod_team:team_chat(Id,Content),
	ok;

handle(30013, Id, {}) ->
	mod_team:team_drop_items(Id),
	ok;

handle(30020, Id, {Scene_id}) ->
	mod_team:enter_dungeon(Id,Scene_id),
	ok;

handle(num, _Player_status, data) ->
	ok.