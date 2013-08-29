%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_common_item_logger
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_common_item_logger).

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
t_clog()->
    Record = #r_item_log{role_id=1,role_level=3,action=?LOG_ITEM_TYPE_SHI_QU_HUO_DE,
                         item_id=11400007,
                         amount=1,equip_id=0,color=1,
                         fineness=0,start_time=common_tool:now(),end_time=0},
    
    R11 = Record#r_item_log{action=?LOG_ITEM_TYPE_SHI_QU_HUO_DE,item_id=30,amount=1},
    R12 = Record#r_item_log{action=?LOG_ITEM_TYPE_SHI_QU_HUO_DE,item_id=30,amount=2},
    R13 = Record#r_item_log{action=?LOG_ITEM_TYPE_SHI_QU_HUO_DE,item_id=30,amount=3},
    
    R21 = Record#r_item_log{action=?LOG_ITEM_TYPE_SHI_YONG_SHI_QU,item_id=31,amount=1},
    R22 = Record#r_item_log{action=?LOG_ITEM_TYPE_SHI_YONG_SHI_QU,item_id=31,amount=2},
    R23 = Record#r_item_log{action=?LOG_ITEM_TYPE_SHI_YONG_SHI_QU,item_id=31,amount=3},
    R24 = Record#r_item_log{action=?LOG_ITEM_TYPE_SHI_QU_HUO_DE,item_id=30,amount=4},
    
    R31 = Record#r_item_log{action=?LOG_ITEM_TYPE_GET_SYSTEM,item_id=30,amount=1},
    R32 = Record#r_item_log{action=?LOG_ITEM_TYPE_GET_SYSTEM,item_id=30,amount=1},
    R33 = Record#r_item_log{action=?LOG_ITEM_TYPE_GET_SYSTEM,item_id=30,amount=1},
  
    
    common_item_logger:log(R11 ),
    common_item_logger:log(R12 ),
    common_item_logger:log(R13 ),
    common_item_logger:log(R21 ),
    common_item_logger:log(R22 ),
    common_item_logger:log(R23 ),
    common_item_logger:log(R24 ),
    common_item_logger:log(R31 ),
    common_item_logger:log(R32 ),
    common_item_logger:log(R33 ),
    ok.

