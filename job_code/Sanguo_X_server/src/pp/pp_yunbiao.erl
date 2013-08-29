%%-------------------------------------------------------
%% @Module : pp_yunbiao
%% @Author : 
%% @Description : 
%%-------------------------------------------------------

-module(pp_yunbiao).
-export([handle/3]).

-include("common.hrl").

%%handle client request yunbiao message
handle(26000, AccountID, _)->
	mod_yunbiao:request_yunbiao_message(AccountID),
	ok;

handle(26001, AccountID, [])->
	?INFO(yunbiao,"handle 26000 Id:~w",[AccountID]),
	mod_yunbiao:request_jixing_message(AccountID);

handle(26003, AccountID, [])->
	mod_yunbiao:refresh_biaoche_type(AccountID);

handle(26004, AccountID, [])->
	mod_yunbiao:onekey_refresh_biaoche_type(AccountID);

handle(26005, AccountID, [])->
	?INFO(yunbiao,"handle 26005,Id:~w",[AccountID]),
	mod_yunbiao:zhuan_yun(AccountID);

handle(26006, AccountID, [NpcId])->
	mod_yunbiao:start_yunbiao_task(AccountID, NpcId);

handle(26007, AccountID, [NpcId])->
	mod_yunbiao:commit_yunbiao_task(AccountID, NpcId);	

handle(26008, AccountID, [RobId])->
	mod_yunbiao:rob_yun_biao(AccountID, RobId);

handle(26010, AccountID, [])->
	mod_yunbiao:client_request_yun_biao_state(AccountID);

handle(26011, AccountID, [NpcId])->
	?INFO(yunbiao, "back to yun biao NpcId:~w",[NpcId]),
	mod_yunbiao:client_request_continue_to_yun_biao(AccountID, NpcId);

handle(_, _Status, _) ->
	ok.






