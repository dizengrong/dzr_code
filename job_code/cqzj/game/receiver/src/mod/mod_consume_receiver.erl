%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     在Reeiver模块中记录中央后台的消费日志
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mod_consume_receiver).


%% API
-export([write_gold_log/3]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeerec.hrl").
%% ====================================================================
%% API Functions
%% ====================================================================
write_gold_log(AgentID, GameID, Record)->
    ?DEBUG("Record=~w",[Record]),
	#b_consume_gold_tos{role_id=RoleId, role_name=RoleName, account_name=AccountName, 
                       level=Level, gold_bind=UseBind, gold_unbind=UseUnbind, 
                       mtime=MTime, mtype=MType, mdetail=_MDetail, itemid=ItemId, amount=ItemAmount} = Record,
    {Year,Month,Day,Hour} = get_datetime_from_seconds(MTime),
    Mdatetime = common_tool:datetime_to_seconds({{Year,Month,Day},{0,0,0}}),
    
    ItemName = 
    if ItemId>30000000 ->
           case common_config_dyn:find_equip(ItemId) of
               []->"";
               [EquipInfo]->EquipInfo#p_equip_base_info.equipname
           end;
       ItemId>20000000 ->
           case common_config_dyn:find_stone(ItemId) of
               []->"";
               [StoneInfo]->StoneInfo#p_stone_base_info.stonename
           end;
       ItemId>10000000 ->
           case common_config_dyn:find_item(ItemId) of
               []->"";
               [ItemInfo]->ItemInfo#p_item_base_info.itemname
           end;
        true->
            ""
    end,
    
    SQL = mod_mysql:get_esql_insert(t_log_gold,
                                    [agent_id,server_id,role_id,role_name,account_name,role_level,gold_bind,gold_unbind,
                                     mtime,mtype,item_id,item_name,amount,year,month,day,hour,mdatetime],
                                    [AgentID,GameID,RoleId,RoleName,AccountName,Level,UseBind, UseUnbind, 
                                      MTime, MType, ItemId,ItemName,ItemAmount,Year,Month,Day,Hour, Mdatetime]
            ),
    {ok,_} = mod_mysql:insert(SQL).


get_datetime_from_seconds(MTime)->
	IntervalTime = calendar:datetime_to_gregorian_seconds({{1970,1,1}, {8,0,0}}),
	{{Year,Month,Day},{Hour,_,_}} = calendar:gregorian_seconds_to_datetime( IntervalTime+ MTime),
	{Year,Month,Day,Hour} .

