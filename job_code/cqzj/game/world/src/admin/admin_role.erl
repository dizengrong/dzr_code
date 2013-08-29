%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%     离线方式赠送元宝、钱币
%%% @end
%%% Created :  7 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(admin_role).

-include("mgeew.hrl").

%% API
-export([
         handle_call/1
        ]).

-define(ADMIN_ROLE_SEND_GOLD, "系统赠送了你 ~p [~s]元宝，原因为:~s。请点开背包查收。").

-define(ADMIN_ROLE_SILVER_UNIT_DING,"锭").
-define(ADMIN_ROLE_SILVER_UNIT_LIANG,"两").
-define(ADMIN_ROLE_SILVER_UNIT_WEN,"文").

handle_call(Info) ->
    do_handle_call(Info).


do_handle_call({send_gold, RoleID, Number, Bind, Reason}) ->
    do_send_gold(RoleID, Number, Bind, Reason);

do_handle_call({send_silver, RoleID, Number, Bind, Reason}) ->
    do_send_silver(RoleID, Number, Bind, Reason);

do_handle_call({send_email_batch, Title,RoleIDList,Text,GoodsList}) ->
    do_send_email_batch(Title,RoleIDList,Text,GoodsList);


do_handle_call(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知消息", Info]).


%%@doc 赠送元宝
do_send_gold(RoleID, Number, Bind, Reason) ->
    case db:transaction(fun() -> t_send_gold(RoleID, Number, Bind) end) of
        {atomic, {RoleID, NewGold}} ->
            %%通过客户端界面更新，信件通知玩家
            case Bind of
                false ->
                    Content = common_letter:create_temp(?ADMIN_SEND_GOLD_LETTER, [Number, "不绑定的", Reason]),
                    R = #m_role2_attr_change_toc{roleid=RoleID, 
                                                 changes=[#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, 
                                                                              new_value=NewGold}
                                                         ]};
                _ ->
                    Content = common_letter:create_temp(?ADMIN_SEND_GOLD_LETTER, [Number, "绑定的", Reason]),
                    R = #m_role2_attr_change_toc{roleid=RoleID, 
                                                 changes=[#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, 
                                                                              new_value=NewGold}
                                                         ]}
            end,
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, R),
            common_letter:sys2p(RoleID, Content,"系统奖励",5),
            ok;
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    {error, Error};
                false ->
                    ?ERROR_MSG("~ts:~w", ["赠送元宝出错", Error]),
                    {error, ?_LANG_ADMIN_SYSTEM_ERROR_WHEN_SEND_GOLD}
            end
    end.

t_send_gold(RoleID, Number, Bind) ->
     [RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID, write),
     case Bind of
         false ->
             NewGold = RoleAttr#p_role_attr.gold+Number,
             common_consume_logger:gain_gold({RoleID, 0, Number, ?GAIN_TYPE_GOLD_GIVE_FROM_GM, ""}),
             db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{gold=NewGold}, write);
         _ ->
             NewGold = RoleAttr#p_role_attr.gold_bind+Number,
             common_consume_logger:gain_gold({RoleID, Number, 0, ?GAIN_TYPE_GOLD_GIVE_FROM_GM, ""}),
             db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{gold_bind=NewGold}, write)
     end,
     {RoleID, NewGold}.


%%@doc 赠送钱币
do_send_silver(RoleID, Number, Bind, Reason) ->
	Str = common_tool:silver_to_string(Number),
    case db:transaction(fun() -> t_send_silver(RoleID, Number, Bind) end) of
        {atomic, {RoleID, NewGold}} ->
            %%通过客户端界面更新，信件通知玩家
            case Bind of
                false ->
                    Content = common_letter:create_temp(?ADMIN_SEND_SILVER_LETTER, [Str, "不绑定的", Reason]),
                    R = #m_role2_attr_change_toc{roleid=RoleID, 
                                                 changes=[#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, 
                                                                              new_value=NewGold}
                                                         ]};
                _ ->
                    Content = common_letter:create_temp(?ADMIN_SEND_SILVER_LETTER, [Str, "绑定的", Reason]),
                    R = #m_role2_attr_change_toc{roleid=RoleID, 
                                                 changes=[#p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, 
                                                                              new_value=NewGold}
                                                         ]}
            end,
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, R),
            common_letter:sys2p(RoleID, Content, "系统奖励",5),
            ok;
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    {error, Error};
                false ->
                    ?ERROR_MSG("~ts:~w", ["赠送钱币出错", Error]),
                    {error, ?_LANG_ADMIN_SYSTEM_ERROR_WHEN_SEND_GOLD}
            end
    end.

t_send_silver(RoleID, Number, Bind) ->
    [RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID, write),
    case Bind of
        false ->
            NewSilver = RoleAttr#p_role_attr.silver+Number,
            common_consume_logger:gain_silver({RoleID, 0, Number, ?GAIN_TYPE_SILVER_GIVE_FROM_GM, ""}),
            db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{silver=NewSilver}, write);
        _ ->
            NewSilver = RoleAttr#p_role_attr.silver_bind+Number,
            common_consume_logger:gain_silver({RoleID, Number, 0, ?GAIN_TYPE_SILVER_GIVE_FROM_GM, ""}),
            db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{silver_bind=NewSilver}, write)
    end,
    {RoleID, NewSilver}.

do_send_email_batch( Title,RoleIDList,Text,GoodsList ) ->
    case mgeew_letter_server:broadcast_sys_letter({Title,RoleIDList,Text,GoodsList}) of
        {error,_} ->
             error;
         _ ->
             ok
    end.