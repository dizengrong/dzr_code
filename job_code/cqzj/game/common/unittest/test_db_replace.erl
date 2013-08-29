%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_db_replace).

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

t()->
    G = #p_monster{hit_rate=1},
    G.

t_replace()->
    SQL=
        "REPLACE INTO `db_account_p`(`account_name`,`create_time`,`role_num`) VALUES ('ai04',1298455114,1),('ai06',1298455006,1)",
    mod_mysql:insert(SQL).

t_replace2()->
        Tab = db_account_p,
        Queues = [["ai04",1298455224,1],["ai06",1298455006,1]],
        %%
        FieldNames = [ account_name,create_time,role_num ],
        BatchFieldValues = Queues,
        SQL = {esql, {replace,Tab, FieldNames,BatchFieldValues }},
        {ok,_} = mod_mysql:insert(SQL).

tm_replace1()->
    R1 = #r_account{account_name="ai01",create_time=1298455224, role_num=1},
    db:dirty_write(db_account,R1).
    
tm_replace2()->
    FieldNames = [ account_name,create_time,role_num ],
    BatchFieldValuesList = [["ai01",1298455111,1],
                            ["ai02",1298455111,1],
                            ["ai03",1298455111,1],
                            ["ai04",1298455111,1],
                            ["ai05",1298455111,1],
                            ["ai06",1298455222,1],
                            ["ai07",1298455222,1],
                            ["ai08",1298455222,1],
                            ["ai09",1298455222,1],
                            ["ai10",1298455222,1]],
    
    mod_mysql:batch_replace(db_account_p,FieldNames,BatchFieldValuesList,5).



tm_replace3()->
    R1 = #r_account{account_name="ai01",create_time=1298455333, role_num=1},
    db:dirty_write(db_account,R1),
    R2 = #r_account{account_name="ai01",create_time=1298455555, role_num=1},
    db:dirty_write(db_account,R2),
    db:dirty_delete(db_account,"ai01").
    

t_insert()->
    SQL=
        "INSERT INTO `db_account_p`(`account_name`,`create_time`,`role_num`) VALUES ('ai04',1298455004,1),('ai05',1298455005,1)",
    mod_mysql:insert(SQL).


