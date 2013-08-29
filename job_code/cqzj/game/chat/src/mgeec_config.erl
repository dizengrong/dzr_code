-module(mgeec_config).

-behavior(gen_server).

-include("mgeec.hrl").

-export([start/0, start_link/0, init/1]).

-export([get_config/1, load_config/1]).

-export([handle_info/2, handle_cast/2, handle_call/3, terminate/2, code_change/3]).

start() ->
    supervisor:start_child(mgeec_sup, 
                           {?MODULE, {?MODULE, start_link, []},
                            transient, infinity, supervisor, [?MODULE]}).

start_link() ->
    {ok, _Pid} = gen_server:start_link(?MODULE, [], []).

init([]) ->
    ets:new(?ETS_CONFIG, [set, named_table, public]),

    do_insert_level_channel(),
    {ok, none}.

get_config(Key) ->
    [Config] = ets:lookup(?ETS_CONFIG, Key),
    Config.

load_config(level_channel) ->
    List = common_config:get_level_channel_list(),
    ets:insert(?ETS_CONFIG, {level_channel, List}),
    List;
load_config(_) ->
    false.


handle_info(_Info, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_info)", Info]),
    {noreply, State}.

handle_cast(_Info, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_cast)", Info]),
    {noreply, State}.
   
handle_call(_Info, _From, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_call)", Info]),
    {reply, ok, State}.

terminate(_Reason, _State) ->
    %%?DEV("~ts:~w", ["配置进程即将关闭", Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

do_insert_level_channel() ->
    
    List = load_config(level_channel),

    try
        lists:foreach(
          fun({_Min, _Max, ID, Name}) ->
                  lists:foreach(
                    fun(FactionID) ->
                            ChannelSign = mgeec_misc:get_level_channel_pname(ID, FactionID),
                            case  db:dirty_read(?DB_CHAT_CHANNELS, ChannelSign) of
                                [] ->
                                    NewChannelInfo = #p_channel_info{channel_sign=ChannelSign, 
                                                                     channel_type=?CHANNEL_TYPE_LEVEL,
                                                                     channel_name=Name,
                                                                     online_num=0, 
                                                                     total_num=0},
                                    db:dirty_write(?DB_CHAT_CHANNELS, NewChannelInfo);
                                _ ->
                                    ignore
                            end
                    end, lists:seq(1, 3))
          end, List)
    catch 
        _:Error ->
            ?ERROR_MSG("~ts:~w", ["查找频道信息出错", Error]),
            ok
    end.
