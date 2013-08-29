%%% -------------------------------------------------------------------
%%% Author  : liurisheng
%%% Description :
%%%
%%% Created : 2010-8-13
%%% -------------------------------------------------------------------
-module(mgeew_admin_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start/0, start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================
start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 permanent, infinity, supervisor, 
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, []}.

%% --------------------------------------------------------------------
handle_call(Request,_From, State) ->
    Reply = do_handle_call(Request),
    {reply, Reply, State}.

%% --------------------------------------------------------------------

handle_cast(Msg, State) ->
    ?ERROR_MSG("unknow cast ~w", [Msg]),
    {noreply, State}.
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(Reason, State) ->
    ?ERROR_MSG("mgeew_role terminate ~w ~w", [Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ====================================================================
%% Local Functions
%% ====================================================================

do_handle_call({Module, Info}) ->
    Module:handle_call(Info);
do_handle_call(Request) ->
    ?ERROR_MSG("unknow call ~w from ~w", [Request]),
    error.

do_handle_info({clear_buff, RoleID})->
    do_clear_buff(RoleID);
do_handle_info({gen_map_goway, MapIDList,TimeGapHour,MaxLevel}=Info)->
    ?ERROR_MSG("Info=~w",[Info]),
    gen_map_goaway_data(MapIDList,TimeGapHour,MaxLevel);
do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.
 
    
%%清除指定角色身上的BUFF
do_clear_buff(RoleID) ->
    case db:transaction(
           fun() ->
                   t_do_clear_buff(RoleID)
           end)
    of
        {atomic, _} ->
            ok;
        {aborted, R} ->
            ?DEBUG("do_clear_buff, r: ~w", [R]),
            ok
    end.

t_do_clear_buff(RoleID) ->
    [RoleBase] = db:read(?DB_ROLE_BASE, RoleID, write),
    db:write(?DB_ROLE_BASE, RoleBase#p_role_base{buffs=[]}, write).



%%----------------------------------------------------
%%生成地图流失率数据
gen_map_goaway_data(MapIDList,TimeGapHour,MaxLevel) when is_integer(TimeGapHour)->
    ?ERROR_MSG("{MapIDList,TimeGapHour,MaxLevel}=~w",[{MapIDList,TimeGapHour,MaxLevel}]),
    Now = common_tool:now(),
    LastGapTime = Now - TimeGapHour*3600,
    
    MatchHead = #p_role_ext{role_id='$1', _='_',last_offline_time='$2'},
    Guard = [{'<','$2',LastGapTime}],
    AllRoleIDList = db:dirty_select(db_role_ext, [{MatchHead, Guard, ['$1']}]),
    ?ERROR_MSG("生成地图流失率数据,AllRoleIDList length=~w",[length(AllRoleIDList)] ),
    RoleIDList2 = lists:filter(fun(RoleID)->
                                   case db:dirty_read(db_role_attr,RoleID) of
                                       [#p_role_attr{level=RoleLevel}]->
                                           RoleLevel=<MaxLevel;
                                       _ ->
                                           false
                                   end
                               end, AllRoleIDList),
    ?ERROR_MSG("生成地图流失率数据,match length=~w",[length(RoleIDList2)] ),
    List2 = lists:foldl(fun(RoleID,AccIn)->
                            gen_map_goaway_data_2(RoleID,MapIDList,AccIn)
                        end, [], RoleIDList2),
    Tab = t_map_liushi,
    try
      case List2 of
          []->
              no_data;
          _ ->
              SQL = mod_mysql:get_esql_delete(Tab, [] ),
              {ok,_} = mod_mysql:delete(SQL),
              
              QueuesInsert = [[Level,MapID,Tx,Ty,N]||{{Level,MapID,Tx,Ty},N}<-List2],
              FieldNames = [level,map_id,tx,ty,num],
              mod_mysql:batch_insert(Tab, FieldNames, QueuesInsert, 3000)
      end
    catch
        _:Reason->
          ?ERROR_MSG("gen_map_goaway_data error,reason:~w  stack:~w",[Reason,erlang:get_stacktrace()])
    end.

gen_map_goaway_data_2(RoleID,MapIDList,AccIn)->
    case db:dirty_read(db_role_pos,RoleID) of
        [#p_role_pos{pos=#p_pos{tx=Tx,ty=Ty},map_id=MapID}]-> 
            case db:dirty_read(db_role_attr,RoleID) of
                [#p_role_attr{level=RoleLevel}] ->
                    Key = {RoleLevel,MapID,Tx,Ty},
                    gen_map_goaway_data_3(MapID,MapIDList,AccIn,Key);
                _ ->
                    AccIn
            end;
        _ ->
            AccIn
    end.
gen_map_goaway_data_3(MapID,MapIDList,AccIn,Key)->
    case lists:member(MapID, MapIDList) of
        true->
            case lists:keyfind(Key, 1, AccIn) of
                {Key,N}->
                    lists:keystore(Key, 1, AccIn, {Key,N+1});
                _ ->
                    [{Key,1}|AccIn]
            end;
        _ ->
            AccIn
    end.


