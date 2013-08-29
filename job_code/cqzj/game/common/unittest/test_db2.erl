%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_db2).

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

now2() ->
    {A, B, C} = erlang:now(),
    A * 1000000000 + B*1000 + C div 1000.

t_clean()->
	Tabs = [db_role_attr_p,db_role_base_p,db_role_faction_p],
	[ mnesia:clear_table(E) || E <- Tabs],
	Tabs2 = [db_role_attr,db_role_base,db_role_faction],
	[ mnesia:clear_table(E) || E <- Tabs2],

	ok.

db_size(DbTable)->
	{ok,[[1,TabSize]]} = mod_mysql:select( lists:concat(["select 1,count(1) from ",DbTable]) ),
	?INFO("~nNow=~w,TabSize=~w~n",[now2(),TabSize]),
	ok.
	


t_w(From,Count)->
	t_w(0,From,Count).

t_w(Type,From,Count)->
	
	Tabs = case Type of
			   1->[db_role_attr];
			   2->[db_role_base];
			   3->[db_role_faction];
			   0-> [db_role_attr,db_role_base,db_role_faction]
		   end,
	
	lists:foreach(fun(Tab)-> 
						  TabSize = mnesia:table_info(Tab,size),
						  {Time, _Value} = timer:tc(test_db2, test_write, [Tab,From,Count]),
						  ?INFO("~nNow=~w",[now2()]),
						  ?INFO("~nTable=~w,Count=~w,TabSize=~p,test_write cost ~w ms(~w sec)",[Tab,Count,TabSize,Time/1000,Time/1000000]),
						  ok
				  end, Tabs).

t_w2(Type,From,Count)->
	
	Tabs = case Type of
			   1->[db_role_attr];
			   2->[db_role_base];
			   3->[db_role_faction];
			   0-> [db_role_attr,db_role_base,db_role_faction]
		   end,
	
	lists:foreach(fun(Tab)-> 
						  spawn(fun()->
										TabSize = mnesia:table_info(Tab,size),
										{Time, _Value} = timer:tc(test_db2, test_write, [Tab,From,Count]),
										?INFO("~nNow=~w",[now2()]),
										?INFO("~nTable=~w,Count=~w,TabSize=~p,test_write cost ~w ms(~w sec)",[Tab,Count,TabSize,Time/1000,Time/1000000])
										
								end),
						  ok
				  end, Tabs).


t_r()->
	t_r(0).

t_r(Type)->
	Tabs = case Type of
			   1->[db_role_attr];
			   2->[db_role_base];
			   3->[db_role_faction];
			   0-> [db_role_attr,db_role_base,db_role_faction]
		   end,
	lists:foreach(fun(Tab)-> 
						  TabSize = mnesia:table_info(Tab,size),
						  {Time, _Value} = timer:tc(test_db2, test_load, [Tab]),
						  ?INFO("~nNow=~w",[now2()]),
						  ?INFO("~nTable=~w,TabSize=~p,test_load cost ~w ms(~w sec)",[Tab,TabSize,Time/1000,Time/1000000]),
						  ok
				  end, Tabs).

%% @spec test_write/3
test_write(db_role_attr,From,Count)->
	Record = {p_role_attr,1,<<"aison01">>,10,0,1,0,[],
              [{p_goods,36,3,1,0,1,0,1,1,30105102,true,0,0,1,0,
                        <<230,156,157,233,152,179,233,147,160,239,188,136,231,148,
                          183,239,188,137>>,
                        1,undefined,undefined,3,1,20000,undefined,0,0,undefined,
                        {p_property_add,0,0,0,0,0,0,0,0,0,11,11,0,10,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0},
                        undefined,0,20000,undefined,
                        [{p_equip_bind_attr,8,1,1,10}],
                        1,0,undefined,undefined,undefined,0},
               {p_goods,3,3,1,0,1,0,1,1,30101101,true,0,0,1,0,
                        <<230,156,157,233,152,179,229,136,128>>,
                        1,undefined,undefined,4,1,20000,undefined,0,0,undefined,
                        {p_property_add,0,0,0,0,0,18,27,19,26,0,0,50,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0},
                        undefined,0,20000,undefined,
                        [{p_equip_bind_attr,7,1,1,50}],
                        1,0,undefined,undefined,undefined,0},
			   {p_goods,3,3,1,0,1,0,1,1,30101101,true,0,0,1,0,
                        <<230,156,157,233,152,179,229,136,128>>,
                        1,undefined,undefined,4,1,20000,undefined,0,0,undefined,
                        {p_property_add,0,0,0,0,0,18,27,19,26,0,0,50,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0},
                        undefined,0,20000,undefined,
                        [{p_equip_bind_attr,7,1,1,50}],
                        1,0,undefined,undefined,undefined,0},
			   {p_goods,3,3,1,0,1,0,1,1,30101101,true,0,0,1,0,
                        <<230,156,157,233,152,179,229,136,128>>,
                        1,undefined,undefined,4,1,20000,undefined,0,0,undefined,
                        {p_property_add,0,0,0,0,0,18,27,19,26,0,0,50,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0},
                        undefined,0,20000,undefined,
                        [{p_equip_bind_attr,7,1,1,50}],
                        1,0,undefined,undefined,undefined,0},
			   {p_goods,3,3,1,0,1,0,1,1,30101101,true,0,0,1,0,
                        <<230,156,157,233,152,179,229,136,128>>,
                        1,undefined,undefined,4,1,20000,undefined,0,0,undefined,
                        {p_property_add,0,0,0,0,0,18,27,19,26,0,0,50,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0},
                        undefined,0,20000,undefined,
                        [{p_equip_bind_attr,7,1,1,50}],
                        1,0,undefined,undefined,undefined,0},
               {p_goods,34,3,1,0,1,0,1,1,30109101,true,0,0,1,0,
                        <<230,156,157,233,152,179,231,155,190>>,
                        1,undefined,undefined,5,1,20000,undefined,0,0,undefined,
                        {p_property_add,0,0,0,0,0,0,0,0,0,8,8,50,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0},
                        undefined,0,20000,undefined,
                        [{p_equip_bind_attr,7,1,1,50}],
                        1,0,undefined,undefined,undefined,0}],
              0,0,0,[],
              {p_skin,1,1,1,30101101,30105102,0,30109101},
              2000,2000,1,500,7990,20000,2998400,true,0,0,[],0,[],false,0},
	[ db:dirty_write(?DB_ROLE_ATTR, erlang:setelement(2, Record, E)) || E <- lists:seq(From, (From+Count)) ],
	ok;
test_write(db_role_base,From,Count)->
	Record = {p_role_base,1,<<"">>,<<"">>,1,1289359988,0,
              1,1,0,0,[],1175,72,0,0,0,0,0,0,0,0,0,0,1,0,38,29,27,20,20,
              20,3,1,0,160,1000,100,0,2,100,0,0,undefined,4,0,0,false,101,
              [{p_actor_buf,9013,7200,1,1,1,1,1289360403,1289367603,1000,
                            3000}],
              0,0,
              [1],
              0,0,0,0,0,0,0,0},
	[ db:dirty_write(?DB_ROLE_BASE, change_role_base_record(Record, E)) || E <- lists:seq(From, (From+Count)) ],
	ok;

test_write(db_role_faction,From,Count)->
	Record = {r_role_faction,1,2},
	[ db:dirty_write(?DB_ROLE_FACTION, erlang:setelement(2, Record, E)) || E <- lists:seq(From, (From+Count)) ],
	ok.

change_role_base_record(R0, E)->
	Name = list_to_binary( lists:concat(["aison",E]) ),
	R1 = erlang:setelement(2, R0, E),
	R2 = erlang:setelement(3, R1, Name),
	R3 = erlang:setelement(4, R2, Name),
	R4 = erlang:setelement(9, R3, E),
	R5 = erlang:setelement(11, R4, E),
	R5.


%% @spec test_load/1
test_load(db_role_attr=Tab)->
	db:load_whole_table(?DB_ROLE_ATTR_P,Tab),
	ok;
test_load(db_role_base=Tab)->
	db:load_whole_table(?DB_ROLE_BASE_P,Tab),
	ok;
test_load(db_role_faction=Tab)->
	db:load_whole_table(?DB_ROLE_FACTION_P,Tab),
	ok.





