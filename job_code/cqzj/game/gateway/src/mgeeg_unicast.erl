%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-26
%%% -------------------------------------------------------------------
-module(mgeeg_unicast).

-behaviour(gen_server).
-include("mgeeg.hrl").
-export([
         start/1,
         start_link/1,
         process_name/1
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {}).

start(Line) ->
    Name = process_name(Line),
    {ok, _} = supervisor:start_child(
                mgeeg_sup, 
                {Name, {?MODULE, start_link, [Name]}, permanent, 10000, worker, [?MODULE]}).

start_link(Name) ->
    gen_server:start_link({global, Name}, ?MODULE, [], []).
%% --------------------------------------------------------------------
    

%% --------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{}}.


%% --------------------------------------------------------------------

handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~w from ~w", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.


handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~w", [Msg]),
    {noreply, State}.


handle_info({role,RoleID,Pid, _Sock}, State) ->
    put(RoleID, Pid),
    {noreply, State};


handle_info({erase,RoleID,Pid}, State) ->
    erase(RoleID),
    erase(Pid),
    {noreply, State};


%%@natsuki 
%%{admin_send_single,32323,{kick,he_is_guilty}}
handle_info({admin_send_single,RoleId,Message},State)->
    Pid = get(RoleId),
    case Message of
	{kick,Reason} ->
	    catch Pid ! {admin_message,{kick,Reason}},
	    {noreply,State};
        _->
	    {noreply,State}
    end;

handle_info({message, RoleID, Unique, Module, Method, DataRecord}, State) ->
    Pid = get(RoleID),
    catch Pid ! {message, Unique, Module, Method, DataRecord},
    {noreply, State};

handle_info({send_single, RoleID, Unique, Module, Method, DataRecord}, State) ->
    Pid = get(RoleID),
    catch Pid ! {message, Unique, Module, Method, DataRecord},
    {noreply, State};

handle_info({kick_role, RoleID, Reason}, State) ->
    case get(RoleID) of
        undefined ->
            ignore;
        Pid ->
            catch erlang:exit(Pid, Reason)
    end,
    {noreply, State};


handle_info({send_multi, UnicastList}, State) when is_list(UnicastList) ->
    lists:foreach(
        fun(Record) ->
            #r_unicast{unique=Unique, module=Module, method=Method, roleid=RoleID, record=DataRecord} = Record,
                Pid = get(RoleID),
                catch Pid ! {message, Unique, Module, Method, DataRecord}
        end,
        UnicastList
    ),
    {noreply, State};


handle_info({inet_reply, _Sock, _Result}, State) ->
    {noreply, State};


%% -- 原broadcast的功能
handle_info({send, RoleIDList, Unique, Module, Method, DataRecord}, State) ->
    broadcast(RoleIDList, Unique, Module, Method, DataRecord),
    {noreply, State};


handle_info({send, RoleIDListPrior, RoleIDList2, Unique, Module, Method, DataRecord}, State) ->
    broadcast(RoleIDListPrior, Unique, Module, Method, DataRecord),
    broadcast(RoleIDList2, Unique, Module, Method, DataRecord),
    {noreply, State};


handle_info(Info, State) ->
    ?INFO_MSG("unexpected info ~w", [Info]),
    {noreply, State}.


terminate(Reason, State) ->
    ?INFO_MSG("~w terminate : ~w, ~w", [self(), Reason, State]),
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------


process_name(Line) ->
   lists:concat([unicast_server_, Line]).

broadcast(List, Unique, Module, Method, DataRecord) 
  when is_list(List) andalso erlang:length(List) > 0 ->
    List2 = lists:foldl(
              fun(RoleID, Acc) ->
                      case erlang:get(RoleID) of
                          PID when erlang:is_pid(PID) ->
                              [PID | Acc];
                          _ ->
                              Acc
                      end
              end, [], List),
    case erlang:length(List2) > 0 of
        true ->
            case catch mgeeg_packet:packet_encode(Unique, Module, Method, DataRecord) of
                {'EXIT', Reason} ->
                    ?ERROR_MSG("~ts ~w", ["分线编码包出错", {DataRecord, Reason}]);
                Binary ->
                    lists:foreach(
                      fun(PID) ->
                              PID ! {binary, Binary}
                      end, List2)
            end;
        false ->
            ignore
    end;

broadcast(List, Unique, Module, Method, DataRecord) ->
    ?DEBUG("~ts: ~w ~w ~w ~w ~w", ["！！！忽略的广播", List, Unique, Module, Method, DataRecord]),
    ignore.
