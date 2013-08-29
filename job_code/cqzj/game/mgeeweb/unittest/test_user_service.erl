%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_user_service
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(test_user_service).

%% --------------------------------------------------------------------
%% include_once files
%% --------------------------------------------------------------------
-include("mgeeweb.hrl").


-compile(export_all).
-define(OUT_FILE,"/data/test.txt").
-define(FILE_PRINT(D),file:write_file( ?OUT_FILE, list_to_binary(D), [append]), ?FILE_PRINT_LINE()).
-define(FILE_PRINT_LINE(),file:write_file( ?OUT_FILE, list_to_binary("\n"), [append])).
%%
%% Exported Functions
%%
-export([]).


%% ====================================================================
%% API Functions
%% ====================================================================
t_json()->
    
    G={p_goods,2,3,1,2,2,1,1,1,30201401,true,1290775454,undefined,1,0,
           <<231,150,190,233,163,142,230,137,135>>,10,undefined,undefined,undefined,1,21000,undefined,0,0,undefined,
           {p_property_add,0,0,2,0,0,11,17,34,48,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0},
           undefined,0,21000,undefined,
           [{p_equip_bind_attr,4,1,1,2}],1,0,undefined,undefined,[],0},
     mod_tool:transfer_to_json(p_goods,G).


t_equip(RoleId)->
    mod_user_service:getUserEquips(RoleId).

t_skin(RoleId)->
    mod_user_service:getUserSkin(RoleId).
    
t_bag(RoleId)->
    mod_user_service:getBagGoods(RoleId).
    
t_stall(RoleId)->
    mod_user_service:getStallGoods(RoleId).

t2()->
    file:delete( ?OUT_FILE ),
    Goods = [{p_goods,392,3,21,0,1,0,1,1,30401201,false,0,0,1,0,
                       <<230,131,138,233,155,183,229,188,147>>,
                       30,undefined,undefined,4,1,21350,undefined,0,0,undefined,
                       {p_property_add,0,0,0,0,0,66,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                       0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0},
                       undefined,0,23000,undefined,undefined,0,0,undefined,
                       undefined,undefined,0}],
    
    Res = [ mod_user_service:transfer_to_json(p_goods,G) ||G<- Goods],
    ?FILE_PRINT( common_json2:to_json(Res) ),
    
    ok.


t3()->
    file:delete( ?OUT_FILE ),
    
    Skin = {p_skin,2,1,1,30401201,0,0,0},
    
    %%{p_skin,[{skinid,2},{hair_type,1},{hair_color,1},{weapon,30401201},{clothes,0},{mounts,0},{assis_weapon,0}]},
    Res = mod_user_service:transfer_to_json(p_skin,Skin),
    ?FILE_PRINT( common_json2:to_json(Res) ),
    
    ok.