%% Author: dzr
%% Created: 2011-8-29
%% Description: TODO: Add description to pp_chat
-module(pp_chat).
%% pp_chat:handle(16011,4000311,[33]).
%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%
-export([handle/3]).

%% 世界聊天
handle(16000, PlayerId, Content) ->
    mod_chat:world_chat(PlayerId, Content);
	
handle(16003, PlayerId, [ReceiverName, Content]) ->
	?INFO(chat,"ReceiverName:~w, Content:~w",[ReceiverName, Content]),
    mod_chat:private_chat(PlayerId, ReceiverName, Content);

%%  发送小喇叭
handle(16004, PlayerId, Content)->
	mod_chat:send_horn(PlayerId, Content);

%% 买小喇叭
handle(16010, PlayerId, Num)->
	mod_chat:buy_horn(PlayerId, Num);

%% 场景聊天
handle(16011, PlayerId, Content) ->
    mod_chat:scene_chat(PlayerId, Content);

%% 帮派聊天
handle(16012, PlayerId, Content) ->
    mod_chat:guild_chat(PlayerId, Content);

%% 组队聊天
handle(16013, PlayerId, Content) ->
    mod_chat:team_chat(PlayerId, Content);

%% 被禁言
handle(lock_speak, PlayerId, _) ->
	{ok, BinData3} = pt_err:write(?ERR_CAN_NOT_CHAT),
	lib_send:send(PlayerId, BinData3).










