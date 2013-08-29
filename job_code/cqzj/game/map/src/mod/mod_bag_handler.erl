%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     背包操作的外部接口的Handler
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mod_bag_handler).


%% API
-export([
         handle/2
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").


%% ====================================================================
%% API Functions
%% ====================================================================
handle({ReceiverPID,Func,Args,ReplyMsgTag},_State) ->
    Reply = try
                do_handle(Func,Args)
            catch
                _:Reason->
                    ?ERROR_MSG("do_handle for ~w error,Reason=~w,stacktrace=~w",[ReplyMsgTag,Reason,erlang:get_stacktrace()]),
                    {error,Reason}
            end,
    ReceiverPID ! {ReplyMsgTag,Reply}.

do_handle(get_bag_goods_list,[Arg1])->
    mod_bag:get_bag_goods_list(Arg1) ;

do_handle(Func,Args)->
    ?ERROR_MSG("~w do_handle未知消息,Func=~w,Args=~w",[?MODULE,Func,Args]),
    {error,bad_args}.


