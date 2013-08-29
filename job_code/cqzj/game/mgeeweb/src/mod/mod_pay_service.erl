-module(mod_pay_service).

-export([get/3]).

-include("mgeeweb.hrl").

-define(ADMIN_ROLE_SEND_GOLD,admin_role_send_gold).
-define(ADMIN_ROLE_SEND_SILVER,admin_role_send_silver).



get(Path,Req,DocRoot)->
    try
        do_get(Path,Req,DocRoot)
    catch
        _:Reason->
            ?ERROR_MSG("do_get error,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end.


%%赠送元宝
do_get("/send_gold/", Req, _DocRoot) ->
    do_send_gold(Req);
%%赠送钱币
do_get("/send_silver/", Req, _DocRoot) ->
    do_send_silver(Req);
do_get(Path, Req, DocRoot) ->
    ?ERROR_MSG("~ts : ~w ~w", ["未知的请求", Path, DocRoot]),
    mgeeweb_tool:return_json_error(Req).

get_param_int(Key,QueryString)->
    common_tool:to_integer( proplists:get_value(Key, QueryString) ).

get_param_string(Key, QueryString)->
    proplists:get_value(Key, QueryString).

do_send_gold(Req) ->
    Get = Req:parse_qs(),
    RoleID = get_param_int("role_id", Get),
    Number = get_param_int("number", Get),
    Reason1 = get_param_string("reason", Get),
	Reason2 = base64:decode_to_string(Reason1),
	Reason = base64:decode_to_string(Reason2),
    Bind = get_param_string("bind", Get),
    
    %% 是否是绑定的
    case Bind of
        "1" ->
            Bind2 = true;
        _ ->
            Bind2 = false
    end,
    case common_misc:is_role_online(RoleID) of
        true->
            do_send_gold_online(Req,{RoleID, Number, Bind2, Reason});
        false->
            do_send_gold_offline(Req,{RoleID, Number, Bind2, Reason})
    end.


do_send_silver(Req) ->
    Get = Req:parse_qs(),
    RoleID = get_param_int("role_id", Get),
    Number = get_param_int("number", Get),
    Reason1 = get_param_string("reason", Get),
	Reason2 = base64:decode_to_string(Reason1),
	Reason = base64:decode_to_string(Reason2),
    Bind = get_param_string("bind", Get),
    
    %% 是否是绑定的
    case Bind of
        "1" ->
            Bind2 = true;
        _ ->
            Bind2 = false
    end,
    case common_misc:is_role_online(RoleID) of
        true->
            do_send_silver_online(Req,{RoleID , Number, Bind2, Reason});
        false->
            do_send_silver_offline(Req,{RoleID , Number, Bind2, Reason})
    end.
    

%%@doc 在线赠送元宝
do_send_gold_online(Req,{RoleID , Number, Bind2, SendReason})->
    AddMoneyList = case Bind2 of
                       true-> 
                           StrBind = "绑定的",
                           [{gold_bind, Number,?GAIN_TYPE_GOLD_GIVE_FROM_GM,""}];
                       false-> 
                           StrBind = "不绑定的",
                           [{gold, Number,?GAIN_TYPE_GOLD_GIVE_FROM_GM,""}]
                   end,
    %%同时发送钱币/元宝更新的通知
    common_role_money:add(RoleID, AddMoneyList,?ADMIN_ROLE_SEND_GOLD,?ADMIN_ROLE_SEND_GOLD,true),
    receive 
        {?ADD_ROLE_MONEY_SUCC, _RoleID, _RoleAttr, ?ADMIN_ROLE_SEND_GOLD}->
            Content = common_letter:create_temp(?ADMIN_SEND_GOLD_LETTER, [Number, StrBind, SendReason]),
			?DEBUG("do_send_gold_online: SendReason=~w, Content=~w",[SendReason,Content]),
            do_send_letter(RoleID, Content),
            case Bind2 of
                true ->
                    ignore;
                false ->
                    %% 不绑定加入到累积充值
                    db:transaction(
                      fun() ->
                              case db:read(?DB_PAY_ACTIVITY_P, RoleID, write) of
                                  [] ->
                                      db:write(?DB_PAY_ACTIVITY_P, #r_pay_activity{role_id=RoleID, all_pay_gold=Number, get_first=false, 
                                                                                   accumulate_history=[]}, write);
                                  [#r_pay_activity{all_pay_gold=AllPayGold} = PayActivity] ->
                                      db:write(?DB_PAY_ACTIVITY_P, PayActivity#r_pay_activity{role_id=RoleID, all_pay_gold=AllPayGold+Number}, write)
                              end
                      end)
            end,
            mgeeweb_tool:return_json_ok(Req);
        {?ADD_ROLE_MONEY_FAILED, _RoleID, Reason, ?ADMIN_ROLE_SEND_GOLD}->
            ?ERROR_MSG("在线赠送元宝出错,Reason=~w",[Reason]),
            mgeeweb_tool:return_json_error(Req);
        {error,Error} ->
            ?ERROR_MSG("在线赠送元宝出错,Reason=~w",[Error]),
            mgeeweb_tool:return_json_error(Req)
        after 10000 ->
            ?ERROR_MSG("在线赠送元宝超时  %%%%%%%%%",[]),
            mgeeweb_tool:return_json_error(Req)
    end.

do_send_letter(RoleID, Text)->
    common_letter:sys2p(RoleID,Text,"系统信件",14).

%%@doc 在线赠送钱币
do_send_silver_online(Req,{RoleID , Number, Bind2, SendReason})->
    AddMoneyList = case Bind2 of
                       true-> 
                           StrBind = "绑定的",
                           [{silver_bind, Number,?GAIN_TYPE_SILVER_GIVE_FROM_GM,""}];
                       false-> 
                           StrBind = "不绑定的",
                           [{silver, Number,?GAIN_TYPE_SILVER_GIVE_FROM_GM,""}]
                   end,
    %%同时发送钱币/元宝更新的通知
    common_role_money:add(RoleID, AddMoneyList,?ADMIN_ROLE_SEND_SILVER,?ADMIN_ROLE_SEND_SILVER,true ),
    receive 
        {?ADD_ROLE_MONEY_SUCC, _RoleID, _RoleAttr, ?ADMIN_ROLE_SEND_SILVER}->
            StrSilver = common_tool:silver_to_string(Number),
            Content = common_letter:create_temp(?ADMIN_SEND_SILVER_LETTER, [StrSilver, StrBind, SendReason]),
            do_send_letter(RoleID, Content),
            mgeeweb_tool:return_json_ok(Req);
        {?ADD_ROLE_MONEY_FAILED, _RoleID, Reason, ?ADMIN_ROLE_SEND_SILVER}->
            ?ERROR_MSG("在线赠送钱币出错,Reason=~w",[Reason]),
            mgeeweb_tool:return_json_error(Req);
        {error,Error} ->
            ?ERROR_MSG("在线赠送钱币出错,Reason=~w",[Error]),
            mgeeweb_tool:return_json_error(Req)
        after 10000 ->
            ?ERROR_MSG("在线赠送钱币超时  %%%%%%%%%",[]),
            mgeeweb_tool:return_json_error(Req)
    end.

%%@doc 离线赠送元宝
do_send_gold_offline(Req,{RoleID , Number, Bind2, SendReason})->    
    case gen_server:call({global, mgeew_admin_server}, {admin_role, {send_gold, RoleID , Number, Bind2, SendReason}}) of
        ok ->
            mgeeweb_tool:return_json_ok(Req);
        {error, Reason} ->
            ?ERROR_MSG("离线赠送元宝出错,Reason=~w",[Reason]),
            mgeeweb_tool:return_json_error(Req)
    end.

%%@doc 离线赠送钱币
do_send_silver_offline(Req,{RoleID , Number, Bind2, SendReason})->    
    case gen_server:call({global, mgeew_admin_server}, {admin_role, {send_silver, RoleID, Number, Bind2, SendReason}}) of
        ok ->
            mgeeweb_tool:return_json_ok(Req);
        {error, Reason} ->
            ?ERROR_MSG("离线赠送钱币出错,Reason=~w",[Reason]),
            mgeeweb_tool:return_json_error(Req)
    end.
