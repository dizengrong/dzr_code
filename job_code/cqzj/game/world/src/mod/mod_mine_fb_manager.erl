%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     金矿之战的Manager-Server
%%% @end
%%%-------------------------------------------------------------------
-module(mod_mine_fb_manager).
-behaviour(gen_server).


-export([
         start/0,
         start_link/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).



%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

%% ====================================================================
%% Macro
%% ====================================================================
-define(CONFIG_NAME,mine_fb).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).
-define(ALL_MINE_PLACE_LIST,all_mine_place_list).
-define(ALL_MINER_DIG_LIST,all_miner_dig_list).
-define(INIT_MINER_DATA_LIST,init_miner_data_list).




%% ====================================================================
%% API functions
%% ====================================================================



%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, 30000, worker, [?MODULE]}).
    

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:process_flag(trap_exit, true),
    init_mine_list(),
    {ok, []}.
 
 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call(Call, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Call, State),
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


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

get_mine_site_list()->
    SiteList = get(?ALL_MINE_PLACE_LIST),
    SiteList.

init_mine_list()->
    [MaxPlaceID] = ?find_config(max_place_id),
    [MaxMinerNum] = ?find_config(max_miner_num),
    
    DbMinerList = list_db_miner(),
    put(?INIT_MINER_DATA_LIST,DbMinerList),
    
    MinerDigInfoList = [ #r_miner_dig_info{role_id=RoleID,place_id=PlaceID,miner_level=MinerLv}  ||
                                          #r_miner_data{role_id=RoleID,miner_place_id=PlaceID,miner_level=MinerLv} <-DbMinerList ],
    put(?ALL_MINER_DIG_LIST,MinerDigInfoList),
    
    PlaceIdList = lists:seq(1, MaxPlaceID),
    PlaceList = [ #p_mine_place{place_id=PlaceID,cur_miner_num=0,max_miner_num=MaxMinerNum} ||PlaceID<- PlaceIdList ],
    {ok,NewPlaceList} = update_place_list(PlaceList,MinerDigInfoList),
    put(?ALL_MINE_PLACE_LIST,NewPlaceList),
    ok.


update_place_list(PlaceList,[])->
    {ok,PlaceList};
update_place_list(PlaceList,[H|T])->
    #r_miner_dig_info{place_id=PlaceID} = H,
    #p_mine_place{cur_miner_num=CurNum} = OldMinePlace = lists:keyfind(PlaceID, #p_mine_place.place_id, PlaceList),
    NewMinePlace = OldMinePlace#p_mine_place{cur_miner_num=CurNum+1},
    PlaceList2 = lists:keystore(PlaceID, #p_mine_place.place_id, PlaceList, NewMinePlace),
    update_place_list(PlaceList2,T).

list_db_miner()->
    Pattern = #r_miner_data{_='_'},
    db:dirty_match_object(?DB_MINER_DATA_P,Pattern).

do_handle_call({get_place_miner_list, PlaceID}) ->
    case get(?INIT_MINER_DATA_LIST) of
        undefined->
            {ok,[]};
        MinerList->
            PlaceMinerList = [ MinerData ||#r_miner_data{miner_place_id=MinerPlaceID}=MinerData<-MinerList,MinerPlaceID=:=PlaceID ],
            {ok,PlaceMinerList}
    end;
do_handle_call(_) ->
    error.


do_handle_info({_Unique, ?MINE_FB, _Method, _DataIn, _RoleID, _Pid, _Line}=Info) ->
    do_handle_method(Info);
do_handle_info({dig_start,MinerDigInfo}) -> %%开始挖矿
    do_dig_start(MinerDigInfo);
do_handle_info({dig_end,RoleID,PlaceID}) ->   %%结束挖矿
    do_dig_end(RoleID,PlaceID);
do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

do_handle_method({_, ?MINE_FB, ?MINE_FB_LIST, _, _RoleID, _Pid, _Line}=Info) ->
    do_mine_fb_list(Info);
do_handle_method(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

%%开始挖矿
do_dig_start(MinerDigInfo) when is_record(MinerDigInfo,r_miner_dig_info)->
    #r_miner_dig_info{role_id=RoleID,place_id=PlaceID} = MinerDigInfo,
    
    %%所有矿山列表
    SiteList = get(?ALL_MINE_PLACE_LIST),
    case lists:keyfind(PlaceID, #p_mine_place.place_id, SiteList) of
        false->
            ignore;
        PlaceRec->
            #p_mine_place{cur_miner_num=CurNum} = PlaceRec,
            NewPlaceRec = PlaceRec#p_mine_place{cur_miner_num=CurNum+1},
            SiteList2=lists:keystore(PlaceID, #p_mine_place.place_id, SiteList, NewPlaceRec),
            put(?ALL_MINE_PLACE_LIST,SiteList2)
    end,
    
    %%所有矿工列表
    case get(?ALL_MINER_DIG_LIST) of
        undefined->
            put(?ALL_MINER_DIG_LIST,[MinerDigInfo]);
        List->
            put(?ALL_MINER_DIG_LIST,[MinerDigInfo|lists:keydelete(RoleID, #r_miner_dig_info.role_id, List)])
    end.

%%结束挖矿
do_dig_end(RoleID,PlaceID)->
    %%所有矿工列表
    case get(?ALL_MINER_DIG_LIST) of
        undefined->
            ignore;
        List->
            put(?ALL_MINER_DIG_LIST,lists:keydelete(RoleID, #r_miner_dig_info.role_id, List))
    end,
    
    %%所有矿山列表
    SiteList = get(?ALL_MINE_PLACE_LIST),
    case lists:keyfind(PlaceID, #p_mine_place.place_id, SiteList) of
        false->
            ignore;
        #p_mine_place{cur_miner_num=0}->
            ignore;
        PlaceRec->
            #p_mine_place{cur_miner_num=CurNum} = PlaceRec,
            NewPlaceRec = PlaceRec#p_mine_place{cur_miner_num=CurNum-1},
            SiteList2=lists:keystore(PlaceID, #p_mine_place.place_id, SiteList, NewPlaceRec),
            put(?ALL_MINE_PLACE_LIST,SiteList2)
    end.
     


%% @interface 显示矿山地图的列表
do_mine_fb_list({Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
    case catch check_do_mine_fb_list(RoleID) of
        {ok,SiteList}->
            MyPlaceID = get_miner_place_id(RoleID),
            R2 = #m_mine_fb_list_toc{place_list=SiteList,miner_place_id=MyPlaceID},
            ?UNICAST_TOC(R2);
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_list_toc{err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

check_do_mine_fb_list(_RoleID)->
    SiteList = get_mine_site_list(),
    {ok,SiteList}.
  
get_miner_place_id(RoleID)->
    case get(?ALL_MINER_DIG_LIST) of
        undefined->
            0;
        List ->
            case lists:keyfind(RoleID, #r_miner_dig_info.role_id, List) of
                #r_miner_dig_info{place_id=MyPlaceID}->
                    MyPlaceID;
                _ ->
                    0
            end
    end.
                
  

