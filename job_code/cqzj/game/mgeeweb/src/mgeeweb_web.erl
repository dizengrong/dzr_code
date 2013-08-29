-module(mgeeweb_web).

-export([start/1, stop/0, loop/2]).

%% External API

start(Options) ->
    {DocRoot, Options1} = get_option(docroot, Options),
    Loop = fun (Req) ->
                   ?MODULE:loop(Req, DocRoot)
           end,
    mochiweb_http:start([{name, ?MODULE}, {loop, Loop} | Options1]).

stop() ->
    mochiweb_http:stop(?MODULE).

loop(Req, DocRoot) ->    
    "/" ++ Path = Req:get(path),
    Method = Req:get(method),
    case Method of
        'GET'  ->
            mgeeweb_get:handle(Path, Req, DocRoot);
        'POST' ->
            mgeeweb_post:handle(Path, Req, DocRoot)
    end.
   

%% Internal API

get_option(Option, Options) ->
    {proplists:get_value(Option, Options), proplists:delete(Option, Options)}.

