%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test for common_config2
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_config2).

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

t_beam(Count,1)  ->
    {Time,_Value} = timer:tc(?MODULE, do_beam_1, [Count]),
    ?INFO("Cost~w~n",[Time/1000]),
    ok;
t_beam(Count,2) ->
    {Time,_Value} = timer:tc(?MODULE, do_beam_2, [Count]),
    ?INFO("Cost~w~n",[Time/1000]),
    ok.

do_beam_1(Count)->
    [ begin 
          common_config_dyn:find_stone(20200005)
      end
      ||_C<- lists:seq(1, Count) ],
    ok.

do_beam_2(Count)->
    [ begin 
          common_config_dyn:find(stone,20200005)
      end
      ||_C<- lists:seq(1, Count) ],
    ok.



t_ets(Count)->
    {Time,_Value} = timer:tc(?MODULE, do_ets, [Count]),
    ?INFO("Cost~w~n",[Time/1000]),
    ok.

do_ets(Count)->
    [ begin 
          ets:lookup(stone_baseinfo_map,20200005)
      end
      ||_C<- lists:seq(1, Count) ],
    ok.


t_atom(Count)->
    {Time,_Value} = timer:tc(?MODULE, do_atom, [Count]),
    ?INFO("Cost~w~n",[Time/1000]),
    ok.

do_atom(Count)->
    [ begin 
          common_tool:to_atom( codegen_name("team") ),
          common_tool:to_atom( codegen_name("item") )
      end
      ||_C<- lists:seq(1, Count) ],
    ok.

codegen_name(Name)->
    lists:concat([Name,"_config_codegen"]).


t_init()->
    ok.

t_gen()->
    ConfigModuleName = "team_config_codegen",
    {ok,[RecList]} = file:consult("D:/WORK_SPACE/WORK_SRC/ming2.mge/trunk/config/map/team.config"),
    KeyValues = RecList,
    do_load_gen_src(ConfigModuleName,KeyValues),
    ok.


do_load_gen_src(ConfigModuleName,KeyValues)->
    try
        Src = common_config_code:gen_src(ConfigModuleName,KeyValues),
        file:write_file("d:/test.txt", list_to_binary(Src)),
        {Mod, Code} = dynamic_compile:from_string( Src ),
        code:load_binary(Mod, ConfigModuleName ++ ".erl", Code)
    catch
        Type:Reason -> ?INFO("Error compiling ~w: Type=~w,Reason=~w, stacktrace=~w~n", [ConfigModuleName, Type, Reason, erlang:get_stacktrace()])
    end.

