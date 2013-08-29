%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     
%%% @end
%%% Created : 2011-01-10
%%%-------------------------------------------------------------------
-module(mod_map_slice).
-include("mgeem.hrl").

%% API
-export([get_by_slice_list/2,init_by_slice/3]).
-export([update_by_slice/4,update_by_slice/5]).
-export([update_by_slice_list/4,update_by_slice_list/5]).
-export([add_by_slice/3]).
-export([remove_by_slice/3,remove_by_slice/4]).

%%@doc 
get_by_slice_list(AllSlice,Key)->
    lists:foldl(
      fun(SliceName, Acc) ->
              case get({Key,SliceName}) of
                  undefined ->
                      Acc;
                  FarmList ->
                      common_tool:combine_lists(FarmList, Acc)
              end
      end, [], AllSlice).

-define(BroadcastInsenceArgs,{RoleID,Module,Method,RecordData}).
-define(SliceListArgs,{SliceList,Module,Method,RecordData}).


%%@doc 
update_by_slice_list(?SliceListArgs,Key,ObjectID,NewVal)->
    update_by_slice_list(?SliceListArgs,Key,ObjectID,NewVal,2).
update_by_slice_list(?SliceListArgs,Key,ObjectID,NewVal,Index)->
    lists:foreach(fun(SliceName)-> 
                          case get({Key,SliceName}) of
                              undefined ->
                                  ignore;
                              ObjectList ->
                                  List2 = lists:keyreplace(ObjectID, Index, ObjectList, NewVal),
                                  put({Key,SliceName},List2)
                          end
                  end, SliceList),
    RoleList = mgeem_map:get_all_in_sence_user_by_slice_list(SliceList),
    mgeem_map:broadcast(RoleList, ?DEFAULT_UNIQUE, Module, Method, RecordData).

%%@doc 
update_by_slice(?BroadcastInsenceArgs,Key,ObjectID,NewVal)->
    update_by_slice(?BroadcastInsenceArgs,Key,ObjectID,NewVal,2).
update_by_slice(?BroadcastInsenceArgs,Key,ObjectID,NewVal,Index)->
    State = mgeem_map:get_state(),
    SliceName = do_get_slice_name(RoleID,State),
    
    case get({Key,SliceName}) of
        undefined ->
            ignore;
        ObjectList ->
            List2 = lists:keyreplace(ObjectID, Index, ObjectList, NewVal),
            put({Key,SliceName},List2)
    end, 
    mgeem_map:do_broadcast_insence([{role, RoleID}], Module, Method, RecordData, State).

%%@doc
init_by_slice(AllSlice,Key,ValList)->
    lists:foreach(fun(SliceName)-> 
                          put({Key,SliceName},ValList)
                  end, AllSlice).
%%@doc 
add_by_slice(?BroadcastInsenceArgs,Key,NewVal)->
    State = mgeem_map:get_state(),
    SliceName = do_get_slice_name(RoleID,State),
    
    case get({Key,SliceName}) of
        undefined ->
            put({Key,SliceName},[NewVal]);
        ObjectList ->
            List2 = [ NewVal|ObjectList ],
            put({Key,SliceName},List2)
    end,
    mgeem_map:do_broadcast_insence([{role, RoleID}], Module, Method, RecordData, State).

%%@doc 
remove_by_slice(?BroadcastInsenceArgs,Key,ObjectID)->
    remove_by_slice(?BroadcastInsenceArgs,Key,ObjectID,2).
remove_by_slice(?BroadcastInsenceArgs,Key,ObjectID,Index)->
    State = mgeem_map:get_state(),
SliceName = do_get_slice_name(RoleID,State),

    case get({Key,SliceName}) of
        undefined ->
            ignore;
        ObjectList ->
            List2 = lists:keydelete(ObjectID, Index, ObjectList),
            put({Key,SliceName},List2)
    end,
    mgeem_map:do_broadcast_insence([{role, RoleID}], Module, Method, RecordData, State).


%% ====================================================================
%% Internal functions
%% ====================================================================

do_get_slice_name(RoleID,State)->
    {TX, TY} = mod_map_actor:get_actor_txty_by_id(RoleID, role),
    State = mgeem_map:get_state(),
    OffsetX = State#map_state.offsetx,
    OffsetY = State#map_state.offsety,
    mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY).


