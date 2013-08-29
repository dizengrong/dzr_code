%% Author:xierongfeng
%% Created: 2013-2-24
%% Description:
-module(mof_undefined).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([handle/6]).

%%
%% API Functions
%%
handle(_Caster, _Target, _Tile, _SkillBaseInfo, _SkillLevelInfo, _MapState) ->
	{error, <<"配置错误">>}.
