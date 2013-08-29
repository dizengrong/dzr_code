%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     在Receiver模块中记录中央后台的GM相关数据(包括GM投诉/GM评分)
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mod_gm_receiver).


%% API
-export([write_complaint_log/3,write_evaluate_log/3]).
-export([write_notice_reply_log/3]).
-export([]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeerec_inc.hrl").
-include("behavior_common.hrl").


%% ====================================================================
%% API Functions
%% ====================================================================

%%@doc 记录玩家的GM投诉消息

write_complaint_log(AgentID,GameID,Record)->
    ?DEBUG("RECORD=~w~n",[Record]),
    #adm_gm_complaint{account_name=AccountName, role_id=RoleId, role_name=RoleName, pay_amount=PayAmount, 
                    level=Level, mtime=MTime, mtype=MType, mtitle=MTitle, content=Content} = Record,
    SQL= mod_mysql:get_esql_insert(t_player_complaint,
                                   [agent_id,server_id,account_name,role_id,role_name,pay_amount,level,mtime,mtype,mtitle,content],
                                   [AgentID,GameID,AccountName,RoleId,RoleName,PayAmount,Level,MTime,MType,MTitle,Content]
                                  ),
    {ok,_} = mod_mysql:insert(SQL).

%%@doc 记录玩家的GM评分消息
write_evaluate_log(AgentID, GameID, Record)->
    ?DEBUG("Record=~w",[Record]),
    #adm_gm_evaluate{reply_id=ReplyId, mark=Mark} = Record,
    WhereExpr = io_lib:format("`agent_id`=~w and `server_id`=~w and `id`=~w ", [AgentID,GameID,ReplyId]),
    SQL = mod_mysql:get_esql_update(t_gm_reply,[{evaluate,Mark}],WhereExpr),
    
    {ok,_} = mod_mysql:update(SQL).
  
%%@doc 记录GM回复的通知
write_notice_reply_log(AgentID, GameID, Record)->
    ?DEBUG("Record=~w",[Record]),
    #adm_gm_notify_reply{reply_id=ReplyId, succ=Succ,reason=Reason} = Record,
    
    case Succ of
        true->
            ignore;
        false->
            WhereExpr = io_lib:format("`agent`=~w and `server_id`=~w and `id`=~w ", [AgentID,GameID,ReplyId]),
            SQL = mod_mysql:get_esql_update(t_gm_reply,[{success, common_mysql_misc:to_tinyint(Succ)},
                                                        {reason,Reason} ],WhereExpr),
            
            {ok,_} = mod_mysql:update(SQL)
    end.
  


