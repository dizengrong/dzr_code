%% @author author <author@example.com>
%% @copyright YYYY author.

%% @doc Supervisor for the mgeeweb application.

-module(mgeeweb_sup).
-author('author <author@example.com>').

-behaviour(supervisor).

%% External exports
-export([start_link/0, upgrade/0]).

%% supervisor callbacks
-export([init/1]).

%% @spec start_link() -> ServerRet
%% @doc API for starting the supervisor.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% @spec upgrade() -> ok
%% @doc Add processes if necessary.
upgrade() ->
    {ok, {_, Specs}} = init([]),

    Old = sets:from_list(
            [Name || {Name, _, _, _} <- supervisor:which_children(?MODULE)]),
    New = sets:from_list([Name || {Name, _, _, _, _, _} <- Specs]),
    Kill = sets:subtract(Old, New),

    sets:fold(fun (Id, ok) ->
                      supervisor:terminate_child(?MODULE, Id),
                      supervisor:delete_child(?MODULE, Id),
                      ok
              end, ok, Kill),

    [supervisor:start_child(?MODULE, Spec) || Spec <- Specs],
    ok.

%% @spec init([]) -> SupervisorTree
%% @doc supervisor callback.
init([]) ->
    Ip = case os:getenv("MOCHIWEB_IP") of false -> "127.0.0.1"; Any -> Any end,
    % Ip = "192.168.4.250",
    [Port] = common_config_dyn:find_common(erlang_web_port),
    WebConfig = [
         {ip, Ip},
                 {port, Port},
                 %%{docroot, mgeeweb_deps:local_path(["priv", "www"])}],
                 {docroot, string:strip(os:cmd("pwd"), both, $\n) ++ "/priv/www"}],
    Web = {mgeeweb_web,
           {mgeeweb_web, start, [WebConfig]},
           permanent, 5000, worker, dynamic},

    Processes = [Web],
    {ok, {{one_for_one, 10, 10}, Processes}}.


%%
%% Tests
%%
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).
-endif.
