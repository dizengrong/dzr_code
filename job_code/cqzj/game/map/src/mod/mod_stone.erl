%% Author: liuwei
%% Created: 2010-4-21
%% Description: TODO: Add description to new_stone
-module(mod_stone).

-include("mgeem.hrl").

-export([
         handle/1,
         creat_stone/1,
         get_stone_baseinfo/1
        ]).

handle({_Unique, _Module, Method, _DataRecord, _RoleID, _Pid, _Line}) -> 
    case Method of
        _ ->
            nil
    end.

creat_stone(CreatInfo) when erlang:is_record(CreatInfo,r_stone_create_info) ->
    case common_bag2:creat_stone(CreatInfo) of
        {ok,GoodsList}->
            {ok,GoodsList};
        {error,Reason}->
            ?ERROR_MSG("creat_stone error,Reason=~w",[Reason]),
            db:abort(?_LANG_ITEM_NO_TYPE_STONE)
    end.

get_stone_baseinfo(TypeID) ->
    case common_config_dyn:find_stone(TypeID) of
        [BaseInfo] -> 
            {ok,BaseInfo};
        [] ->
            error
    end.
