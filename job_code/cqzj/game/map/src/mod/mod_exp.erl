%% Author: Liangliang
%% Created: 2010-4-19
%% Description: TODO: Add description to mod_exp
-module(mod_exp).

-include("mgeem.hrl").

-export([
         get_cur_level_exp/1,
         get_next_level_exp/1,
         get_new_level/2
        ]).


get_cur_level_exp(Level) ->
    case common_config_dyn:find(level, Level) of
    [RecLevelExp] ->
        RecLevelExp#p_level_exp.exp;
    _ ->
        0
    end.

get_next_level_exp(NextLevel) ->
    case common_config_dyn:find(level, NextLevel) of
    [RecLevelExp] ->
        RecLevelExp#p_level_exp.exp;
    _ ->
        0
    end.

get_new_level(Exp, OldLevel) ->
    [MaxLevel] = common_config_dyn:find(etc,max_level),
    case OldLevel >= MaxLevel of
        true ->
            {MaxLevel,0};
        _ ->
            [AutoLevelUp] = common_config_dyn:find(etc, auto_level_up),
            case OldLevel >= AutoLevelUp of
                true ->
                    {OldLevel, Exp};
                _ ->
                    case common_config_dyn:find(level, OldLevel) of
                        [RecLevelExp] ->
                            NextExp = RecLevelExp#p_level_exp.exp,
                            case Exp >= NextExp of
                                true ->
                                    get_new_level(Exp-NextExp, OldLevel + 1);
                                false ->
                                    {OldLevel,Exp}
                            end;
                        _ ->
                            {0,Exp}
                    end
            end
    end.
