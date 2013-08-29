%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_json2
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_json2).

%%
%% Include files
%%
-compile(export_all).
-include("common.hrl").
-define(OUT_FILE,"/data/test.txt").
-define(FILE_PRINT(D),file:write_file( ?OUT_FILE, list_to_binary(D), [append]), ?FILE_PRINT_LINE()).
-define(FILE_PRINT_LINE(),file:write_file( ?OUT_FILE, list_to_binary("\n"), [append])).


%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

test_rfc4627()->
    Version = "1.2.3",
    Result = lists:flatten(rfc4627:encode({obj, [{"erlang_version", common_tool:to_binary(Version)}]})),
    ?PRINT("Result=~p~n",[Result]),
    
    R2 = rfc4627:encode({obj, [{"erlang_version", common_tool:to_binary(Version)}]}),
    ?PRINT("R2=~p~n",[R2]),
    ok.

t1()->
    file:delete(?OUT_FILE),
    JSonList=[{role_id,1},
                                                     {role_name,"aison01"},
                                                     {time_start,1290513078},
                                                     {time_end,1290514878},
                                                     {duration,30},
                                                     {reason,
                                                      [231,142,169,229,174,
                                                       182,91,97,105,115,111,
                                                       110,48,49,93,229,155,
                                                       160,229,143,145,229,
                                                       184,131,228,184,141,
                                                       230,150,135,230,152,
                                                       142,228,191,161,230,
                                                       129,175,239,188,140,
                                                       232,162,171,231,179,
                                                       187,231,187,159,231,
                                                       166,129,232,168,128,51,
                                                       48,229,136,134,233,146,
                                                       159,227,128,130]},
                                                     {type,0}],
    Val = common_json2:to_json(JSonList),
    ?FILE_PRINT(Val).

t2()->
    List = [231,142,169,229,174,
                                                       182,91,97,105,115,111,
                                                       110,48,49,93,229,155,
                                                       160,229,143,145,229,
                                                       184,131,228,184,141,
                                                       230,150,135,230,152,
                                                       142,228,191,161,230,
                                                       129,175,239,188,140,
                                                       232,162,171,231,179,
                                                       187,231,187,159,231,
                                                       166,129,232,168,128,51,
                                                       48,229,136,134,233,146,
                                                       159,227,128,130],
    ?PRINT("A=~w",[io_lib:char_list(List)] ),
    ?PRINT("B=~w",[io_lib:unicode_char_list(List)] ).

t3()->
    List = [97,98,99],
    ?PRINT("A=~w",[io_lib:char_list(List)] ),
    ?PRINT("B=~w",[io_lib:unicode_char_list(List)] ).
    


    
    

