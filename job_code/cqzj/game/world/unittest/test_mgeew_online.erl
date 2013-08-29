%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_mgeew_online
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_mgeew_online).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

t_split_list()->
    SrcBatchFieldValues = [[1,20111211,2011,12,11,3],
                           [2,20111211,2011,12,11,4],
                           [3,20111211,2011,12,11,4],
                           [4,20111211,2011,12,11,4],
                           [5,20111211,2011,12,11,4],
                           [6,20111211,2011,12,11,4],
                           [7,20111211,2011,12,11,4],
                           [8,20111211,2011,12,11,4]
                          ],
    
    mod_online_update_server:split_list(SrcBatchFieldValues,[]).

t_load()->
    {Year,Month,Day} = erlang:date(),
    MDate = Year*10000 + Month*100 + Day,
    WhereExpr = io_lib:format(" mdate=~w ",[MDate]),
    Sql = mod_mysql:get_esql_select(t_log_daily_online,[role_id,online_time], WhereExpr),
    {ok,ResultSet} = mod_mysql:select(Sql).

t_init_online_time()->
    SrcBatchFieldValues = [[1,20111211,2011,12,11,3],
                           [2,20111211,2011,12,11,4],
                           [3,20111211,2011,12,11,4],
                           [4,20111211,2011,12,11,4],
                           [5,20111211,2011,12,11,4],
                           [6,20111211,2011,12,11,4],
                           [7,20111211,2011,12,11,4],
                           [8,20111211,2011,12,11,4]
                          ],
    FieldNames = [ role_id,mdate,year,month,day,online_time ],
    
    BatchFieldValList = mod_online_update_server:split_list(SrcBatchFieldValues,[]),
    [ begin 
          SQL = {esql, {insert,t_log_daily_online, FieldNames,SubBatchFieldVals }},
          {ok,_} = mod_mysql:insert(SQL)
      end ||SubBatchFieldVals<-BatchFieldValList].

t_add()->
    R1 = {r_role_online,1,<<"aison01">>,<<"aison02">>,1,0,1290071558,[]},
    R2 = {r_role_online,2,<<"aison01">>,<<"aison02">>,1,0,1290071558,{192,168,1,4}},

    mgeew_online:add_online(R1),
    mgeew_online:add_online(R2),
    ok.

t_del()->
    
    mgeew_online:remove_online(1),
    mgeew_online:remove_online(2),
    
    ok.



