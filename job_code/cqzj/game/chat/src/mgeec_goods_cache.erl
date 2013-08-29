%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%
%%% @end
%%% Created : 23 Dec 2010 by  <>
%%%-------------------------------------------------------------------
-module(mgeec_goods_cache).

-include("mgeec.hrl").

%% API
-export([start/0, 
         start_link/0
         ]).

-export([get_cache_goods/1]).

%% gen_server callback
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% record defin
-record(state, {}).

%% 最新的道具id
-define(DICT_LAST_GOODS_ID, dict_last_goods_id).
%% 道具ID列表
-define(DICT_GOODS_ID_LIST, dict_goods_id_list).
%% 存放道具ETS
-define(ETS_GOODS_CACHE, ets_goods_cache).
%% 定时清缓冲循环
-define(MSG_CACHE_LOOP, msg_cache_loop).
%% 清除时间
-define(CLEAR_DIFF, 3600).
%% 循环时间
-define(LOOP_DIFF, 1800*1000).

%%%===================================================================
%%% API
%%%===================================================================
start() ->
    {ok, _} = supervisor:start_child(mgeec_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 transient, brutal_kill, worker, 
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

get_cache_goods(GoodsID) ->
    case ets:lookup(?ETS_GOODS_CACHE, GoodsID) of
        [] ->
            {error, goods_not_found};
        [{_, GoodsDetail}] ->
            {ok, GoodsDetail}
    end.

%% gen_server callback
init([]) ->
    %% 道具缓存
    ets:new(?ETS_GOODS_CACHE, [set, protected, named_table]),
    %% 最新道具ID
    put(?DICT_LAST_GOODS_ID, 1),
    %% 缓存ID列表
    put(?DICT_GOODS_ID_LIST, []),
    %% 定时清缓冲消息
    erlang:send_after(?LOOP_DIFF, self(), ?MSG_CACHE_LOOP),

    {ok, #state{}}.
 

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

do_handle_info(?MSG_CACHE_LOOP) ->
    do_cache_loop();
do_handle_info({insert_goods, RoleID, RoleName, Sex, GoodsName, GoodsInfo, DataIn, CPID, PID, Unique, Line, MapPID}) ->
    do_insert(RoleID, RoleName, Sex, GoodsName, GoodsInfo, DataIn, CPID, PID, Unique, Line, MapPID);
do_handle_info({bc_send_msg_world, TypeList, SubType, Content, RoleID, RoleName, Sex, GoodsList}) ->
    do_bc_send_msg_world(TypeList, SubType, Content, RoleID, RoleName, Sex, GoodsList);
do_handle_info({bc_send_msg_faction, FactionID, TypeList, SubType, Content, RoleID, RoleName, Sex, GoodsList}) ->
    do_send_msg_faction(FactionID, TypeList, SubType, Content, RoleID, RoleName, Sex, GoodsList);

do_handle_info(Info) ->
    ?ERROR_MSG("mgeec_goods_cache, unknow info: ~w", [Info]).

do_bc_send_msg_world(TypeList, SubType, Content, _RoleID, RoleName, Sex, GoodsList) when erlang:is_list(GoodsList) ->
    Content2 = wrap_broadcast_msg_include_goods(Content, RoleName, Sex, GoodsList),
    common_broadcast:bc_send_msg_world(TypeList, SubType, Content2);
do_bc_send_msg_world(TypeList, SubType, Content, _RoleID, RoleName, Sex, Goods) ->
    do_bc_send_msg_world(TypeList, SubType, Content, _RoleID, RoleName, Sex, [Goods]).

do_send_msg_faction(FactionID, TypeList, SubType, Content, _RoleID, RoleName, Sex, GoodsList) when erlang:is_list(GoodsList) ->
    Content2 = wrap_broadcast_msg_include_goods(Content, RoleName, Sex, GoodsList),
    common_broadcast:bc_send_msg_faction(FactionID, TypeList, SubType, Content2);
do_send_msg_faction(FactionID, TypeList, SubType, Content, _RoleID, RoleName, Sex, Goods) ->
    do_send_msg_faction(FactionID, TypeList, SubType, Content, _RoleID, RoleName, Sex, [Goods]).

wrap_broadcast_msg_include_goods(Content, RoleName, Sex, GoodsList) ->
    GoodsStr =
        lists:map(
          fun(GoodsInfo) ->
                  {ok, #p_goods{id=GoodsID}=GoodsInfo2} = do_insert_into_cache(GoodsInfo),
                  GoodsName = common_goods:get_notify_goods_name(GoodsInfo2),
                  io_lib:format("<a href=\"event:~w=~s=~w\"><u>~s</u></a>", [GoodsID, RoleName, Sex, GoodsName])
          end, GoodsList),
    GoodsStr2 = string:join(GoodsStr, "、"),
    re:replace(Content, "-g", GoodsStr2, [{return, list}]).

%% @doc 定时清缓冲
do_cache_loop() ->
    Now = common_tool:now(),
    GoodsList = get(?DICT_GOODS_ID_LIST),

    GoodsList2 =
        lists:foldl(
          fun({GoodsID, Time}, GoodsListT) ->
                  case Now - Time > ?CLEAR_DIFF of
                      true ->
                          ets:delete(?ETS_GOODS_CACHE, GoodsID),
                          lists:delete({GoodsID, Time}, GoodsList);
                      _ ->
                          GoodsListT
                  end
          end, GoodsList, GoodsList),
    put(?DICT_GOODS_ID_LIST, GoodsList2),
    
    erlang:send_after(?LOOP_DIFF, self(), ?MSG_CACHE_LOOP).

%% @doc 插入纪录
do_insert(RoleID, RoleName, Sex, _GoodsName, GoodsInfo, DataIn, RPID, PID, Unique, Line, MapPID) ->
    %% 特殊处理下，从商城购买的商品都没赋颜色，这里从配置读取颜色
    {ok, #p_goods{id=GoodsID}=GoodsInfo2} = do_insert_into_cache(GoodsInfo),
    GoodsName2 = common_goods:get_notify_goods_name(GoodsInfo2),
    Msg = io_lib:format("<a href=\"event:~w=~s=~w\"><u>~s</u></a>", [GoodsID, RoleName, Sex, GoodsName2]),
    Msg2 = lists:flatten(Msg),
    
    #m_goods_show_goods_tos{channel_sign=ChannelSign, to_role_name=ToRoleName, show_type=ShowType} = DataIn,
    case ChannelSign of
        %% 附近频道标记
        "bubbleChannel" ->
            DataRecord = #m_bubble_send_tos{action_type=0, msg=Msg2},
            MapPID ! {mod_map_role, {bubble_msg, RoleID, Line, DataRecord}};
        "horn" ->
            DataRecord = #m_broadcast_laba_tos{content=Msg2, laba_id=0},
            MapPID ! {Unique, ?BROADCAST, ?BROADCAST_LABA, DataRecord, RoleID, PID, Line};
        _ ->
            case ShowType of
                0 ->
                    RouterData = {?DEFAULT_UNIQUE, ?CHAT, ?CHAT_IN_CHANNEL, #m_chat_in_channel_tos{channel_sign=ChannelSign, msg=Msg2}};
                _ ->
                    RouterData = {?DEFAULT_UNIQUE, ?CHAT, ?CHAT_IN_PAIRS, #m_chat_in_pairs_tos{to_rolename=ToRoleName, show_type=ShowType, msg=Msg2}}
            end,

            RPID ! {router, RouterData},

            DataRecord = #m_goods_show_goods_toc{},
            common_misc:unicast2(PID, Unique, ?GOODS, ?GOODS_SHOW_GOODS, DataRecord)
    end,
    ok.

get_goods_id() ->
    GoodsID = get(?DICT_LAST_GOODS_ID),
    put(?DICT_LAST_GOODS_ID, GoodsID+1),
    
    {ok, GoodsID}.

%% @doc 将道具插入缓存
do_insert_into_cache(GoodsInfo) ->
    #p_goods{type=Type, typeid=TypeID, current_colour=Colour} = GoodsInfo,
    Colour2= get_goods_color(Type, TypeID, Colour),

    {ok, GoodsID} = get_goods_id(),
    GoodsInfo2 = GoodsInfo#p_goods{id=GoodsID, current_colour=Colour2},
    ets:insert(?ETS_GOODS_CACHE, {GoodsID, GoodsInfo2}),

    GoodsList = get(?DICT_GOODS_ID_LIST),
    put(?DICT_GOODS_ID_LIST, [{GoodsID, common_tool:now()}|GoodsList]),
    {ok, GoodsInfo2}.

%% @doc 获取道具颜色
get_goods_color(Type, TypeID, Colour) ->
    case Colour of
        ?COLOUR_WHITE ->
            case Type of
                ?TYPE_EQUIP ->
                    [EquipBaseInfo] = common_config_dyn:find_equip(TypeID),
                    EquipBaseInfo#p_equip_base_info.colour;
                ?TYPE_STONE ->
                    [StoneBaseInfo] = common_config_dyn:find_stone(TypeID),
                    StoneBaseInfo#p_stone_base_info.colour;
                _ ->
                    [ItemBaseInfo] = common_config_dyn:find_item(TypeID),
                    ItemBaseInfo#p_item_base_info.colour
            end;
        _ ->
            Colour
    end.
