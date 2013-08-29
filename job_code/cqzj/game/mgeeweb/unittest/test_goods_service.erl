%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_mod_user_service
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(test_goods_service).

%% --------------------------------------------------------------------
%% include_once files
%% --------------------------------------------------------------------
-include("mgeeweb.hrl").


-compile(export_all).
%%
%% Exported Functions
%%
-export([]).


%% ====================================================================
%% API Functions
%% ====================================================================


t_send(RoleID2)->
    %%TODO: Type2
    Info = #r_goods_create_info{bind=true, type=?TYPE_ITEM, type_id=10200009, start_time=common_tool:now(),
                                end_time=0, num=1, color=1, quality=1, punch_num=0, rate=0, result=0,
                                interface_type=present },
    case mod_goods_service:create_goods(RoleID2,Info) of
        {ok,GoodsList}->
            mod_goods_service:do_send_goods_by_letter(RoleID2,GoodsList);
        {error,Reason}->
            ?ERROR_MSG("creat_stone error,Reason=~w",[Reason]),
            error
    end.


