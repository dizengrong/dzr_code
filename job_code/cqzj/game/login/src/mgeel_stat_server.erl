%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mgeel_stat_server  跟玩家统计行为相关的Server 
%%% @end
%%% Created : 2010-12-15
%%%-------------------------------------------------------------------
-module(mgeel_stat_server).
-behaviour(gen_server).
-record(state,{}).


-export([start/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(ETS_STAT_BUTTON,ets_stat_button). %%玩家的统按钮计行为
-define(ETS_STAT_PK_MODE,ets_stat_pk_mode). %%玩家改变战斗模式的行为
-define(ETS_STAT_EXCHANGE_EQUIP,ets_stat_exchange_equip). %%玩家买(攻/防)装备的行为
-define(ETS_STAT_BIG_FACE,ets_stat_big_face).

%%定时发消息进行持久化
-define(DUMP_INTERVAL, 60 * 1000).
-define(MSG_DUMP_LOG, dump_stat_data).
-define(IS_STAT_OPEN,true).

%% 记录pk模式等级区间
-define(LOG_PK_MODE_MODIFY_LEVEL,[11, 21, 31, 41, 51, 61, 71, 81, 91, 101]).

%% 地图节点的pk模式类型
-define(PK_PEACE, 0). %和平模式
-define(PK_ALL, 1). %全体模式
-define(PK_TEAM, 2). %组队模式
-define(PK_FAMILY, 3). %家族模式
-define(PK_FACTION, 4). %国家模式
-define(PK_MASTER, 5). %善恶模式

%% 防具shopid列表
-define(ARMOR_SHOP,[20107,20108,20109,20110]).
%% 武器shopid列表
-define(WEAPON_SHOP,[20103,20104,20105,20106,20112]).

-define(ARMOR_TYPE,0). %%防具
-define(WEAPON_TYPE,1). %%武器

-define(BUTTON_KEY,button).
-define(PKMODE_KEY,pkmode).
-define(EXCHANGE_KEY,exchange).
-define(BIGFACE_KEY,bigface).

-define(EXCHANGE_BUY,1).
-define(EXCHANGE_SALE,0).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeel.hrl").

%% ====================================================================
%% External functions
%% ====================================================================

start()  ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    ets:new(?ETS_STAT_BUTTON, [named_table, set, protected]),
    ets:new(?ETS_STAT_PK_MODE, [named_table, set, protected]),
    ets:new(?ETS_STAT_EXCHANGE_EQUIP, [named_table, set, protected]),
    ets:new(?ETS_STAT_BIG_FACE, [named_table, set, protected]),

	erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG),

	
	State = #state{},
	{ok, State}.

%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
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


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

do_handle_info({_Unique, ?STAT, ?STAT_BUTTON, DataRecord, RoleID, _PID, _Line}) ->
	case common_config_dyn:find(stat,?BUTTON_KEY) of
		[true]->
			#m_stat_button_tos{use_type=UseType,btn_key=BtnKey} = DataRecord,
			case common_misc:get_dirty_role_attr(RoleID) of
				{ok, RoleAttr} ->
					#p_role_attr{level=Level} = RoleAttr,
					case Level<25 of
						true->
							addButtonStat(BtnKey,1,UseType);
						_ ->
							addButtonStat(BtnKey,2,UseType)
					end;
				_ ->
					ignore
			end;
		_->
			ignore
	end;
%% 记录pk模式
do_handle_info({pk_mode_modify,RoleID,PKMode})->
	case common_config_dyn:find(stat,?PKMODE_KEY) of
		[true]->
			case db:dirty_read(?DB_ROLE_ATTR,RoleID) of
				[]->
					ignore;
				[RoleAttr]->
					case get_level_range(?LOG_PK_MODE_MODIFY_LEVEL,RoleAttr#p_role_attr.level) of
						{ok,none}->ignore;
						{ok,LevelRange}->
							do_log_pk_mode_modify(LevelRange,PKMode)
					end
			end;
		_->
			ignore
	end;

%% 记录大表情
do_handle_info({big_face,Msg})->
    case common_config_dyn:find(stat,?BIGFACE_KEY) of
        [true]->
            do_log_big_face(Msg);
        _->
            ignore
    end;

%%记录买卖装备
do_handle_info({equip_shop_buy,ShopID,TypeID})->
	case common_config_dyn:find(stat,?EXCHANGE_KEY) of
		[true]->
			?DEBUG("ShopID=====~w   TypeID======~w~n",[ShopID,TypeID]),
			case lists:any(fun(_ShopID)->ShopID=:=_ShopID end,?ARMOR_SHOP) of
				true->
					do_log_equip_buy(?ARMOR_TYPE,TypeID);
				false->
					ignore
			end,
			case lists:any(fun(_ShopID)->ShopID=:=_ShopID end,?WEAPON_SHOP) of
				true->
					do_log_equip_buy(?WEAPON_TYPE,TypeID);
				false->
					ignore
			end;
		_->
			ignore
	end;
do_handle_info({equip_shop_sale,SaleList})->
	?DEBUG("equip_shop_sale,SaleList=~w~n",[SaleList]);
do_handle_info(?MSG_DUMP_LOG)->
	case ?IS_STAT_OPEN of
		true->
            do_dump_stat_data(?BUTTON_KEY),
            do_dump_stat_data(?PKMODE_KEY),
            do_dump_stat_data(?EXCHANGE_KEY),
            do_dump_stat_data(?BIGFACE_KEY);
		_ ->
			ignore
	end,
	
	erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);

do_handle_info(Info)->
	?ERROR_MSG("receive unknown message,Info=~w",[Info]),
	ignore.

-define(TRY_DUMP_STAT_DATA(Tab,TransformFun),
        try
          case common_config_dyn:find(stat,Key) of
              [true]->
                  case ets:tab2list(Tab) of
                      []->
                          ignore;
                      ValList ->
                          Queues = TransformFun,
                          do_dump_to_mysql(Key,Queues)
                  end;
              _ ->
                  ignore
          end
        catch
            _:Reason1->
              ?ERROR_MSG("写在线用户数失败,Reason=~w", [Reason1])
        end).

%%@doc 将统计数据，每分钟保存到db中
do_dump_stat_data(?BUTTON_KEY=Key)->
    ?TRY_DUMP_STAT_DATA( 
    ?ETS_STAT_BUTTON,
    [ [BtnKey,LevelType,UseType,Num] || {{BtnKey,LevelType,UseType},Num} <-ValList ]
    );
do_dump_stat_data(?PKMODE_KEY=Key)->
    ?TRY_DUMP_STAT_DATA( 
    ?ETS_STAT_PK_MODE,
    [ [LevelRange,PK_PEACE,PK_ALL,PK_TEAM,PK_FAMILY,PK_FACTION,PK_MASTER] || {LevelRange,{PK_PEACE,PK_ALL,PK_TEAM,PK_FAMILY,PK_FACTION,PK_MASTER}} <-ValList ]
    );

do_dump_stat_data(?EXCHANGE_KEY=Key)->
    ?TRY_DUMP_STAT_DATA( 
    ?ETS_STAT_EXCHANGE_EQUIP,
    [ [TypeID,EQUIP_TYPE,EXCHANGE,Num] || {{TypeID,EQUIP_TYPE,EXCHANGE},Num} <-ValList ]
    );

do_dump_stat_data(?BIGFACE_KEY=Key)->
    ?TRY_DUMP_STAT_DATA( 
    ?ETS_STAT_BIG_FACE,
    [ [Msg,Num] || {Msg,Num} <-ValList ]
    ).

-define(TRY_DUMP_TO_MYSQL(Tab),
        try
          BatchFieldValues = Queues,
          mod_mysql:batch_replace(Tab,FieldNames,BatchFieldValues,3000)
        catch
            _:Reason->
              ?ERROR_MSG("插入玩家统计数据出错,Tab=~w,Reason=~w,stacktrace=~w",[Tab,Reason,erlang:get_stacktrace()])
        end).

do_dump_to_mysql(?BUTTON_KEY,Queues)->
    FieldNames = [ btn_key,level_type,use_type,num ],
    ?TRY_DUMP_TO_MYSQL( t_stat_button );

do_dump_to_mysql(?PKMODE_KEY,Queues)->
    FieldNames = [ pkmode_key,pk_peace,pk_all,pk_team,pk_family,pk_faction,pk_master],
    ?TRY_DUMP_TO_MYSQL( t_stat_pk_mode );

do_dump_to_mysql(?EXCHANGE_KEY,Queues)->
    FieldNames = [ type_id,equip_type,exchange,num],
    ?TRY_DUMP_TO_MYSQL( t_stat_exchange );

do_dump_to_mysql(?BIGFACE_KEY,Queues)->
    FieldNames = [ face,num],
    ?TRY_DUMP_TO_MYSQL( t_stat_big_face ).
 
  
%%增加按钮统计的数据
addButtonStat(BtnKey,LevelType,UseType)->
    Key = {BtnKey,LevelType,UseType},
    case ets:lookup(?ETS_STAT_BUTTON, Key) of
        []->
            ets:insert(?ETS_STAT_BUTTON, {Key,1});
        [{Key,Num}] ->
            ets:insert(?ETS_STAT_BUTTON, {Key,Num+1})
    end.

%% 记录pkmode
do_log_pk_mode_modify(LevelRange,PKMode)->
	Value1 = case ets:lookup(?ETS_STAT_PK_MODE, LevelRange) of
				 []->
					 {0,0,0,0,0,0};
				 [{LevelRange,_Value}] ->
					 _Value
			 end,
	{PK_PEACE,PK_ALL,PK_TEAM,PK_FAMILY,PK_FACTION,PK_MASTER}=Value1,
	Value2 =  case PKMode of
						 ?PK_PEACE->
							 {PK_PEACE+1,PK_ALL,PK_TEAM,PK_FAMILY,PK_FACTION,PK_MASTER};
						 ?PK_ALL->
							 {PK_PEACE,PK_ALL+1,PK_TEAM,PK_FAMILY,PK_FACTION,PK_MASTER};
						 ?PK_TEAM->
							 {PK_PEACE,PK_ALL,PK_TEAM+1,PK_FAMILY,PK_FACTION,PK_MASTER};
						 ?PK_FAMILY->
							 {PK_PEACE,PK_ALL,PK_TEAM,PK_FAMILY+1,PK_FACTION,PK_MASTER};
						 ?PK_FACTION->
							 {PK_PEACE,PK_ALL,PK_TEAM,PK_FAMILY,PK_FACTION+1,PK_MASTER};
						 ?PK_MASTER->
							 {PK_PEACE,PK_ALL,PK_TEAM,PK_FAMILY,PK_FACTION,PK_MASTER+1};
						 _->
							 {PK_PEACE,PK_ALL,PK_TEAM,PK_FAMILY,PK_FACTION,PK_MASTER}
					 end,
	?DEBUG("VALUE2=====~w~n",[Value2]),
	ets:insert(?ETS_STAT_PK_MODE, {LevelRange,Value2}).

do_log_big_face(Msg1)->
    Msg = common_tool:to_integer(Msg1),
    Value1 = case ets:lookup(?ETS_STAT_BIG_FACE, Msg) of
                 []->
                     0;
                 [{Msg,_Value}] ->
                     _Value
             end,
    Value2= Value1+1,
    ?DEBUG("VALUE2=====~w~n",[Value2]),
    ets:insert(?ETS_STAT_BIG_FACE, {Msg,Value2}).

%% 获取等级所在范围
get_level_range([],_Level)->
	{ok,none};
get_level_range([L|R],Level)->
	case Level<L of
		true -> 
			{ok,L};
		false->
			get_level_range(R,Level)
	end.

%% 将买物品行为记录到ets
do_log_equip_buy(EQUIP_TYPE,TypeID)->
	?DEBUG("EQUIP_TYPE==~w,TypeID==~w~n",[EQUIP_TYPE,TypeID]),
	Key = {TypeID,EQUIP_TYPE,?EXCHANGE_BUY},
	case ets:lookup(?ETS_STAT_EXCHANGE_EQUIP, Key) of
		[]->
			ets:insert(?ETS_STAT_EXCHANGE_EQUIP, {Key,1});
		[{Key,Num}] ->
			ets:insert(?ETS_STAT_EXCHANGE_EQUIP, {Key,Num+1})
	end.
