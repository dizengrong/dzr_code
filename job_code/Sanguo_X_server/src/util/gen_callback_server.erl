-module(gen_callback_server).

-behaviour(gen_server).

%% -include("gen_callback_server.hrl").
-include("common.hrl").

-export([behaviour_info/1]).

-export([
    start_link/4,
    start_link/3,
    start/4,
    start/3,
    do_sync/2,
    do_sync/3,
    do_async/2,
    do_async/3,
    do/4,
    do/5,
    reply_cb/1,
    receive_cb/2,
    client_reply_cb/1,
    mixed_reply_cb/1
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-record(state,
    {
        options     :: [atom() | tuple()],
        name        :: cb_server_name(),
        cb_module   :: module(),
        cb_state    :: any(),
        info_cb     :: function() | {function(), any()}
    }).

-define(CB(State), (State#state.cb_module)).
-define(DEFAULT_RPC_TIMEOUT, 5000).

behaviour_info(callbacks) ->
    [
        {init,          1},
        {handle_action, 2},
        {handle_info,   2},
        {terminate,     2},
        {code_change,   3}
    ].

-spec start_link(module(), any(), [tuple() | atom]) -> {ok, pid()} | ignore | {error, any()}.
start_link(CBModule, CBArgs, Options) ->
    {Opts, NewOptions} = get_cb_options(Options),
    gen_server:start_link(?MODULE, [CBModule, {Opts}, CBArgs], NewOptions).

-spec start_link(gen_server_name(), module(), any(), [tuple() | atom]) -> {ok, pid()} | ignore | {error, any()}.
start_link(Name, CBModule, CBArgs, Options) ->
    {Opts, NewOptions} = get_cb_options(Options),
    gen_server:start_link(Name, ?MODULE, [CBModule, {Name, Opts}, CBArgs], NewOptions).

-spec start(module(), any(), [tuple() | atom]) -> {ok, pid()} | ignore | {error, any()}.
start(CBModule, CBArgs, Options) ->
    {Opts, NewOptions} = get_cb_options(Options),
    gen_server:start(?MODULE, [CBModule, {Opts}, CBArgs], NewOptions).

-spec start(gen_server_name(), module(), any(), [tuple() | atom]) -> {ok, pid()} | ignore | {error, any()}.
start(Name, CBModule, CBArgs, Options) ->
    {Opts, NewOptions} = get_cb_options(Options),
    gen_server:start(Name, ?MODULE, [CBModule, {Name, Opts}, CBArgs], NewOptions).

-spec do(gen_server_ref(), any(), cb_func(), cb_func()) -> any().
do(Target, Msg, RemoteCBFunc, LocalCBFunc) ->
    do(Target, Msg, RemoteCBFunc, LocalCBFunc, ?DEFAULT_RPC_TIMEOUT).

-spec do(gen_server_ref(), any(), cb_func(), cb_func(), timeout()) -> any().
do(Target, Msg, RemoteCBFunc, LocalCBFunc, Timeout) ->
    MsgRef = make_ref(),
    %% TODO: monitor the target process even though we're using gen_server:cast(...)
    gen_server:cast(Target, {gen_callback_msg, self(), MsgRef, Msg, RemoteCBFunc}),
    call_recv_cb(LocalCBFunc, MsgRef, Timeout).

-spec reply_cb(#cb_event{}) -> ok.
reply_cb(CBEvent) ->
    ReplyTo = CBEvent#cb_event.reply_to,
    Reply   = CBEvent#cb_event.cb_arg,
    Replier = CBEvent#cb_event.sent_from,
    MsgRef  = CBEvent#cb_event.msg_ref,
    ReplyTo ! {gen_callback_reply, MsgRef, Reply, Replier},
    ok.

-spec receive_cb(#cb_event{}, timeout()) -> any().
receive_cb(CBEvent, Timeout) ->
    MsgRef = CBEvent#cb_event.msg_ref,
    receive
        {gen_callback_reply, MsgRef, Reply, _Replier} ->
            Reply
    after 
        Timeout ->
            error(timeout)
    end.

-spec client_reply_cb(#cb_event{}) -> ok.
client_reply_cb(CBEvent) ->
    Reply = CBEvent#cb_event.cb_arg,
    {Senders, Protocol} = CBEvent#cb_event.context,
    case Reply of
        {ok, ClientRepContent} ->
            PTMod = get_pt_mod(Protocol),
            {ok, Packet} = PTMod:write(Protocol, ClientRepContent),
            lib_send:send(Senders, Packet);
        ok ->
            void;
        {error, quiet} ->
            void;
        {error, ErrCode} ->
			mod_err:send_error(pid, Senders, Protocol, ErrCode)
    end,
    ok.

-spec mixed_reply_cb(#cb_event{}) -> ok.
mixed_reply_cb(CBEvent) ->
    Reply = CBEvent#cb_event.cb_arg,
    {Senders, Protocol} = CBEvent#cb_event.context,
    case Reply of
        {ok, RepContent, ClientRepContent} ->
            reply_cb(CBEvent#cb_event{cb_arg = RepContent}),
            PTMod = get_pt_mod(Protocol),
            {ok, Packet} = PTMod:write(Protocol, ClientRepContent),
            lib_send:send(Senders, Packet);
        {ok, RepContent} ->
            reply_cb(CBEvent#cb_event{cb_arg = RepContent});
        {error, quiet} ->
            reply_cb(CBEvent#cb_event{cb_arg = ok});        %% TODO: 这里的 ok 改成更合适的返回值
        {error, ErrCode} ->
            reply_cb(CBEvent#cb_event{cb_arg = ok}),
			mod_err:send_error(pid, Senders, Protocol, ErrCode)
    end,
    ok.

-spec do_sync(gen_server_ref(), any()) -> any().
do_sync(Target, Msg) ->
    do(Target, Msg, fun reply_cb/1, fun receive_cb/2).

-spec do_sync(gen_server_ref(), any(), timeout()) -> any().
do_sync(Target, Msg, Timeout) ->
    do(Target, Msg, fun reply_cb/1, fun receive_cb/2, Timeout).

-spec do_async(gen_server_ref(), any()) -> ok.
do_async(Target, Msg) ->
    do(Target, Msg, none, none).

-spec do_async(gen_server_ref(), any(), cb_func()) -> ok.
do_async(Target, Msg, RemoteCBFunc) ->
    do(Target, Msg, RemoteCBFunc, none).

%% gen_server callbacks
init(Args) ->
    [CBModule, NameOpts, CBArgs | _] = Args,
    case CBModule:init(CBArgs) of
        {ok, DummyState} ->
            NewState = make_new_state(NameOpts, CBModule, DummyState),
            {ok, NewState};

        {ok, DummyState, Timeout} ->
            NewState = make_new_state(NameOpts, CBModule, DummyState),
            {ok, NewState, Timeout};

        Other ->
            Other
    end.

handle_call(_Msg, _From, State) ->
    %% Intentionally left blank....
    {noreply, State}.

handle_cast({gen_callback_msg, Originator, MsgRef, CBMsg, CBFunc}, State) ->
    case ?CB(State):handle_action(CBMsg, State#state.cb_state) of
        {reply, CBArg, NewCBState} ->
            call_rep_cb(CBFunc, Originator, CBArg, MsgRef, State#state.name),
            {noreply, State#state{cb_state = NewCBState}};
        {reply, CBArg, NewCBState, Timeout} ->
            call_rep_cb(CBFunc, Originator, CBArg, MsgRef, State#state.name),
            {noreply, State#state{cb_state = NewCBState}, Timeout};
        %% 这里支持 noreply，让进程可以制止回调函数的执行；
        %% 但是实际使用时应该尽量都 reply，让调用者来决定是否要执行回调函数
        {noreply, NewCBState} ->
            {noreply, State#state{cb_state = NewCBState}};
        {noreply, NewCBState, Timeout} ->
            {noreply, State#state{cb_state = NewCBState}, Timeout};
        {stop, Reason, CBArg, NewCBState} ->
            call_rep_cb(CBFunc, Originator, CBArg, MsgRef, State#state.name),
            {stop, Reason, State#state{cb_state = NewCBState}};
        {stop, Reason, NewCBState} ->
            {stop, Reason, State#state{cb_state = NewCBState}}
    end.

handle_info(Info, State) ->
    case ?CB(State):handle_info(Info, State#state.cb_state) of
        %% 这里支持 reply，让 handle_info 之后可以多加一个回调的钩子；
        %% 但是实际使用时应该尽量都 noreply，因为 handle_info 本身应该是完全异步的，
        %% 把该干的事情在 handle_info 里干完就好了
        {reply, CBArg, NewCBState} ->
            call_info_cb(State#state.info_cb, Info, CBArg, State#state.name),
            {noreply, State#state{cb_state = NewCBState}};
        {reply, CBArg, NewCBState, Timeout} ->
            call_info_cb(State#state.info_cb, Info, CBArg, State#state.name),
            {noreply, State#state{cb_state = NewCBState}, Timeout};
        {noreply, NewCBState} ->
            {noreply, State#state{cb_state = NewCBState}};
        {noreply, NewCBState, Timeout} ->
            {noreply, State#state{cb_state = NewCBState}, Timeout};
        {stop, Reason, CBArg, NewCBState} ->
            call_info_cb(State#state.info_cb, Info, CBArg, State#state.name),
            {stop, Reason, State#state{cb_state = NewCBState}};
        {stop, Reason, NewCBState} ->
            {stop, Reason, State#state{cb_state = NewCBState}}
    end.

terminate(Reason, State) ->
    ?CB(State):terminate(Reason, State#state.cb_state).

code_change(OldVsn, State, Extra) ->
    {ok, NewCBState} = ?CB(State):code_change(OldVsn, State#state.cb_state, Extra),
    {ok, State#state{cb_state = NewCBState}}.




%% Local functions
get_cb_options(Options) ->
    case lists:keytake(callback_opts, 1, Options) of
        {value, {_, Opts}, NewOptList} ->
            {Opts, NewOptList};
        false ->
            {[], Options}
    end.

call_recv_cb(RecvCBFunc, MsgRef, Timeout) ->
    NewCBEvent = #cb_event{msg_ref = MsgRef},
    case RecvCBFunc of
        {F, Context} when is_function(F, 2) -> 
            F(NewCBEvent#cb_event{context = Context}, Timeout);
        F when is_function(F, 2) ->
            F(NewCBEvent, Timeout);
        none ->
            ok;
        _ ->
            error(invalid_callback)
    end.

call_rep_cb(RepCBFunc, Originator, CBArg, MsgRef, SelfName) ->
    NewCBEvent = 
        #cb_event{
            reply_to  = Originator,
            cb_arg    = CBArg,
            msg_ref   = MsgRef,
            sent_from = SelfName
        },
    case RepCBFunc of
        {F, Context} when is_function(F, 1) -> 
            F(NewCBEvent#cb_event{context = Context});
        F when is_function(F, 1) ->
            F(NewCBEvent);
        none ->
            void;
        _ ->
            error(invalid_callback)
    end.

call_info_cb(InfoCBFunc, Info, CBArg, SelfName) ->
    NewCBEvent =
        #cb_event{
            cb_arg    = CBArg,
            sent_from = SelfName
        },
    case InfoCBFunc of
        {F, Context} when is_function(F, 2) ->
            F(Info, NewCBEvent#cb_event{context = Context});
        F when is_function(F, 2) ->
            F(Info, NewCBEvent);
        none ->
            void;
        _ ->
            error(invalid_callback)
    end.

get_pt_mod(Protocol) ->
    PTSuffix = lists:sublist(integer_to_list(Protocol), 2),
    list_to_atom("pt_" ++ PTSuffix).

make_new_state(NameOpts, CBModule, DummyState) ->
    case NameOpts of
        {Name, Opts} ->
            {_, InfoCB} = get_option(info_cb, Opts, {info_cb, none}),
            #state{
                name      = {Name, node()},
                options   = Opts,
                cb_module = CBModule,
                cb_state  = DummyState,
                info_cb   = InfoCB
            };
        {Opts} ->
            {_, InfoCB} = get_option(info_cb, Opts, {info_cb, none}),
            #state{
                name      = self(),
                options   = Opts,
                cb_module = CBModule,
                cb_state  = DummyState,
                info_cb   = InfoCB
            }
    end.

get_option(_, [], DefVal) -> DefVal;
get_option(Op, [H | RestOpList], DefVal) when is_atom(Op) ->
	case check_option(Op, H) of
		true -> H;
		_ -> get_option(Op, RestOpList, DefVal)
	end.

check_option(Op, Op)      -> true;
check_option(Op, {Op, _}) -> true;
check_option(_, _)        -> false.
