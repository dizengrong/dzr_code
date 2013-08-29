-module(mod_refining).

-include_lib("eunit/include/eunit.hrl").
-include("mgeem.hrl").
-include("refining.hrl").

%%对角色模块的接口---------------
-export([handle/1]).

%%对其它模块的接口---------------
-export([equip_colour_quality_add/5,
         equip_random_add_property/1,
         do_refining_deduct_fee/3,
         do_refining_deduct_gold/4,
         do_refining_deduct_fee_notify/2,
         do_refining_deduct_gold_notify/2,
		 get_refining_fee/2,
		 get_refining_fee/3,
		 get_refining_fee/4,
		 get_equip_level_by_jingjie/1,
         change_main_property/5,
         get_equip_reinforce_new_grade/2,
         get_random_number/3]).
-export([format_value/2]).

%% 天工炉新接口处理
handle({Unique,?REFINING,?REFINING_FIRING,DataIn,RoleID,PID,Line,_State})->
    mod_refining_firing:do_handle_info({Unique,?REFINING,?REFINING_FIRING,DataIn,RoleID,PID,Line});
handle({Unique,?REFINING,?REFINING_FIRING_AUTO,DataIn,RoleID,PID,Line,_State})->
	mod_refining_firing_auto:do_handle_info({Unique,?REFINING,?REFINING_FIRING_AUTO,DataIn,RoleID,PID,Line});

handle({_, ?REFINING, ?REFINING_INBAG_LIST, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_inbag_list_tos) ->
    do_inbag_list(Msg);
handle({_, ?REFINING, ?REFINING_INFO, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_info_tos) ->
    do_goods_info(Msg);
handle({_, ?REFINING, ?REFINING_DESTROY, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_destroy_tos) ->
    do_destroy(Msg);
handle({_, ?REFINING, ?REFINING_SWAP, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_swap_tos) ->
    do_swap(Msg);
handle({_, ?REFINING, ?REFINING_DIVIDE, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_divide_tos) ->
    do_divide(Msg);
handle({_, ?REFINING, ?REFINING_REINFORCE_EQUIP, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_reinforce_equip_tos) ->
    do_reinforce_equip(Msg);
handle({Unique, ?REFINING, ?REFINING_COMPOSE, DataIn, RoleID, _Pid, Line, _State})
  when is_record(DataIn, m_refining_compose_tos) ->
    do_compose(Unique, ?REFINING, ?REFINING_COMPOSE, DataIn, RoleID, Line);
handle({Unique, ?REFINING, ?REFINING_PUNCH, DataIn, RoleID, _Pid, Line, _State}) ->
    do_punch(Unique, ?REFINING, ?REFINING_PUNCH, DataIn, RoleID, Line);
handle({_, ?REFINING, ?REFINING_INLAY, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_inlay_tos) ->
    do_inlay(Msg);
handle({_, ?REFINING, ?REFINING_UNLOAD, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_unload_tos) ->
    do_unload(Msg);

%% 装备洗炼
handle({_, ?REFINING, ?REFINING_EQUIP_BIND, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_refining_equip_bind_tos) ->
    mod_refining_bind:handle(Msg);

%% 炼制功能处理
handle({Unique, ?REFINING, ?REFINING_FORGING, DataIn, RoleID, Pid, Line, _State}) ->
    mod_refining_forging:do_handle_info({Unique, ?REFINING, ?REFINING_FORGING, DataIn, RoleID, Pid, Line});

handle({_,Module,Method,_,_,_,_,_}) ->
    ?DEBUG("Other~ Module:~w,Method:~w",[Module,Method]).

do_inbag_list({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_refining_inbag_list_tos{bagid = BagID} = DataIn,
    R = case mod_refining_bag:get_goods_by_bag_id(RoleID,BagID) of
            GoodsList when is_list(GoodsList) ->
                #m_refining_inbag_list_toc{bagid = BagID, goods = GoodsList};
            _ ->
                #m_refining_inbag_list_toc{bagid = BagID, goods = []}
        end,
    ?DEV("~ts,DataRecord=~w",["查询天工炉列表返回数据",R]),
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_goods_info({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_refining_info_tos{id = GoodsID} = DataIn,
    R = case mod_refining_bag:get_goods_by_bag_id_goods_id(RoleID,?REFINING_BAGID,GoodsID) of
            {ok,Info} ->
                #m_refining_info_toc{info = Info};
            _ ->
                #m_refining_info_toc{info = undefined}   
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_destroy({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_refining_destroy_tos{id = GoodsID} = DataIn,
    R = case db:transaction(
               fun() ->
                       case mod_bag:get_goods_by_id(RoleID, GoodsID) of
                           {ok, GoodsInfo} ->
                               mod_bag:delete_goods(RoleID, GoodsID),
                               hook_prop:hook(decreate, [GoodsInfo]),
                               %% add by caochuncheng 添加商贸hook
                               mod_trading:hook_t_drop_trading_bill_item(RoleID,GoodsInfo#p_goods.typeid),
                               {ok, GoodsID,GoodsInfo};
                           _ ->
                               db:abort(?_LANG_SYSTEM_ERROR)
                       end
               end)
        of
            {aborted, Reason} when is_binary(Reason)->
                #m_refining_destroy_toc{succ = false,reason = Reason};
            {aborted, Reason} ->
                ?DEBUG("destroy_goods transaction fail, reason = ~p", [Reason]),
                #m_refining_destroy_toc{succ = false,reason = ?_LANG_SYSTEM_ERROR};
            {atomic, {ok, _GoodsID,GoodsInfo2}} ->
                catch do_destroy_item_logger(RoleID,GoodsInfo2),
                %% add by caochuncheng 玩家商贸商票销毁处理
                catch mod_trading:hook_drop_trading_bill_item(RoleID,GoodsInfo2#p_goods.typeid),
                %%catch mod_educate_fb:hook_role_drop_goods(RoleID,GoodsInfo2),
                #m_refining_destroy_toc{succ = true,id = GoodsID}

        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%% 玩家天工炉手动丢弃物品日志信息
do_destroy_item_logger(RoleId,Goods) ->
    common_item_logger:log(RoleId,Goods,?LOG_ITEM_TYPE_SHOU_DONG_DIU_QI).


%%@doc 确认装备是否可以放入天工炉
t_assert_can_swap(#p_goods{type=GoodsType}=GoodsInfo) when (GoodsType=:=?TYPE_EQUIP)->
    ConfSlotNum = get_equip_slotnum(GoodsInfo),
    if
        ConfSlotNum=:=?PUT_MOUNT->
            db:abort((<<"不能将坐骑放入天工炉中">>));
        true ->
            ok
    end;
t_assert_can_swap(_GoodsInfo) ->
    ok.

%%@doc 获取装备的位置
get_equip_slotnum(EquipGoods)->
    EquipTypeId = EquipGoods#p_goods.typeid,
    {ok,#p_equip_base_info{slot_num=ConfSlotNum}} = mod_equip:get_equip_baseinfo(EquipTypeId),
    ConfSlotNum.

do_swap({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_refining_swap_tos{id1 = GoodsID1, position2 = Position2, bagid2 = BagID2} = DataIn,
    case mod_bag:get_goods_by_id(RoleID, GoodsID1) of
        {error, _} ->
            R = #m_refining_swap_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR};
        {ok, GoodsInfo} ->
            case mod_bag:check_bags_times_up(GoodsInfo#p_goods.bagid,BagID2,RoleID,Position2) of
                true->
                    case db:transaction(
                           fun() ->
                                   t_assert_can_swap(GoodsInfo),
                                   {ok, _, Goods2} = ReturnVal = mod_bag:swap_goods(GoodsID1, Position2, BagID2, RoleID),
                                   t_assert_can_swap(Goods2),
                                   ReturnVal
                           end)
                        of
                        {aborted, Reason}when is_binary(Reason) ->
                            R = #m_refining_swap_toc{succ = false, reason = Reason};
                        {aborted, Reason} ->
                            ?ERROR_MSG("swap_goods transaction fail, reason = ~p", [Reason]),
                            R = #m_refining_swap_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR};
                        {atomic, {ok, none, Goods2}} ->
                            hook_prop:hook(create, [Goods2]),
                            R = #m_refining_swap_toc{succ = true,  goods1=GoodsInfo#p_goods{id=0}, goods2 = Goods2};
                        {atomic, {ok, Goods1,Goods2}} ->
                            hook_prop:hook(create, [Goods1]),
                            hook_prop:hook(create, [Goods2]),
                            R = #m_refining_swap_toc{succ = true, goods1 = Goods1, goods2 = Goods2}
                    end;
                false->
                    R = #m_refining_swap_toc{succ = false, reason=?_LANG_ITEM_MOVE_EXTAND_BAG_TIMES_UP}
            end    
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_divide({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_refining_divide_tos{id = GoodsID, num = DivideNum, 
                        bagid = BagID, bagposition = NewPosition} = DataIn,
    R = case db:transaction(
               fun() ->
                       mod_bag:divide_goods(GoodsID, DivideNum, NewPosition, BagID, RoleID)
               end)
        of
            {aborted, Reason} when is_binary(Reason)->
                #m_refining_divide_toc{succ = false, reason = Reason};
            {aborted, Reason} ->
                ?DEBUG("divide_goods transaction fail, reason = ~p", [Reason]),
                #m_refining_divide_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR};
            {atomic, {ok, none, Goods1}} ->
                #m_refining_divide_toc{succ = true, goods1 = Goods1};
            {atomic, {ok, Goods1,Goods2}} ->
                #m_refining_divide_toc{succ = true,  goods1 = Goods1, goods2 = Goods2}
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%装备强化-----------------------------------------------------------------------------------------    
do_reinforce_equip({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_refining_reinforce_equip_tos{bagid= BagID, equipid=EquipID} = DataIn,
    R =  case mod_refining_bag:get_goods_by_bag_id(RoleID,BagID) of
             [] ->
                 do_reinforce_equip_error(?_LANG_REINFORCE_PLACED);
             GoodsList when is_list(GoodsList) ->
                 do_reinforce_equip2(GoodsList,EquipID)
         end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_reinforce_equip2(GoodsList,EquipID) ->
    ExtractGoods = extract_reinforce_goods(GoodsList,EquipID),
    ?DEV("Goods:~p",[ExtractGoods]),
    case check_reinforce_goods(ExtractGoods) of
        {ok, CheckGoods} ->
            do_reinforce_equip3(CheckGoods);
        {error,Reason} ->
            do_reinforce_equip_error(Reason)
    end.
     
do_reinforce_equip3({E,S}=CheckGoods) -> 
    ?DEBUG("do_reinforce_equip3, checkgoods: ~w", [CheckGoods]),
    case db:transaction(
           fun() ->
                   Result = random_reinforce(E,S),   
                   ?DEBUG("result:~p",[Result]),
                   t_reinforce_equip(Result,CheckGoods)
           end) 
    of
        {aborted, Reason}
          when is_binary(Reason)->
            do_reinforce_equip_error(Reason);
        {aborted, Reason} ->
            ?ERROR_MSG("~ts:~p",["装备镶嵌错误",Reason]),
            do_reinforce_equip_error(?_LANG_SYSTEM_ERROR);
        {atomic, {Succ,Equip,Stuff,Prompt}} ->
            #p_goods{roleid = RoleId} = Equip,
            %% 道具消费日志
            common_item_logger:log(RoleId,Stuff,1,?LOG_ITEM_TYPE_QIANG_HUA_SHI_QU),
            common_item_logger:log(RoleId,Equip,1,?LOG_ITEM_TYPE_QIANG_HUA_HUO_DE),
            do_refining_deduct_fee_notify(RoleId,{role,RoleId}),
            #m_refining_reinforce_equip_toc{succ=Succ, 
                                            equip=Equip,
                                            stuff=Stuff, 
                                            prompt=Prompt}
    end.

do_reinforce_equip_error(Prompt) ->
    #m_refining_reinforce_equip_toc{
              succ = false, 
              equip = undefined,
              stuff = undefined, 
              prompt = Prompt
    }.
    
extract_reinforce_goods(GoodsList,EquipID) ->
    F = fun(Goods,{Other,Stuff,Equip})->
                ID = Goods#p_goods.id,
                J = get_stuff_level(Goods#p_goods.typeid),
                if ID =:= EquipID ->
                        NewEquip = 
                            if Goods#p_goods.reinforce_result =/= undefined ->
                                    Goods;
                               true ->
                                    Goods#p_goods{reinforce_result=0}
                            end,     
                        {Other,Stuff,[NewEquip|Equip]};
                   J =/= undefined ->
                        {Other,[Goods|Stuff],Equip};
                   true ->
                        {[Goods|Other],Stuff,Equip}
                end
        end,
    lists:foldl(F, {[],[],[]}, GoodsList).

check_reinforce_goods({[],_,_}=R) ->
    ?DEBUG("check_reinforce_goods, r: ~w", [R]),
    check_reinforce_goods2({nil,nil}, R);
check_reinforce_goods(_) ->
    {error,?_LANG_REINFORCE_HAS_OTHER}.

%%@doc 确认是否为正常的装备
assert_normal_equip(#p_goods{type=GoodsType}=GoodsInfo) when (GoodsType=:=?TYPE_EQUIP)->
    %%判断是否为坐骑、时装
    ConfSlotNum = get_equip_slotnum(GoodsInfo),
            if
                ConfSlotNum=:=?PUT_MOUNT->
                    {error,?_LANG_REINFORCE_MOUNT_ERROR};
                ConfSlotNum=:=?PUT_FASHION->
                    {error,?_LANG_REINFORCE_FASHION_ERROR};
                ConfSlotNum =:= ?PUT_ADORN ->
                    {error,?_LANG_REINFORCE_ADORN_ERROR};
                ConfSlotNum =:= ?PUT_JINGJIE ->
                    {error,?_LANG_REINFORCE_ADORN_ERROR};
                ConfSlotNum =:= ?PUT_SHENQI ->
                    {error,?_LANG_REINFORCE_ADORN_ERROR};
                ConfSlotNum =:= ?PUT_MARRY ->
                    {error,?_LANG_REINFORCE_ADORN_ERROR};
                true ->
                    ok
            end;
assert_normal_equip(_GoodsInfo) ->
    ok.

check_reinforce_goods2({nil,CStuff},{_,_,Equip}=R) ->
    case Equip of
        [] ->
            ?DEBUG("check_reinforce_goods2, no equip", []),
            {error, ?_LANG_REINFORCE_NO_EQUIP};          
        [CEquip] ->
            Level = CEquip#p_goods.reinforce_result div 10,
            Grade = CEquip#p_goods.reinforce_result rem 10,
            case assert_normal_equip(CEquip) of
                ok->
                    if CEquip#p_goods.bagposition =/= 5 ->
                           {error,?_LANG_REINFORCE_POS_NOT_5};
                       Level =:= ?REINFORCE_MAX_LEVEL andalso
                           Grade =:= ?REINFORCE_MAX_GRADE ->
                           ?DEBUG("check_reinforce_goods2, equip level full", []),
                           {error, ?_LANG_REINFORCE_NO_UPGRADE};
                       true ->
                           check_reinforce_goods2({CEquip,CStuff},R)
                    end;
                {error,Reason2}->
                    {error,Reason2}
            end;
        _  ->
            ?DEBUG("check_reinforce_goods2, no equip", []),
            {error, ?_LANG_REINFORCE_CAN_NOT_MANY_EQUIP}
    end;  
check_reinforce_goods2({CEquip,nil},{_,Stuff,_}) ->
    ReincorceLevel = CEquip#p_goods.reinforce_result div 10,
    F = fun(Goods, _) ->
                Level = get_stuff_level(Goods#p_goods.typeid),
                if  Level =:= ReincorceLevel orelse
                    Level =:= ReincorceLevel+1  ->
                        throw({ok,Goods});
                    true ->
                        not_meet_stuff
                end   
        end,
    case catch lists:foldl(F, not_stuff, Stuff) of 
        not_stuff-> 
            ?DEBUG("check_reinforce_goods2, no stuff", []),
            {error, ?_LANG_REINFORCE_PLACED_STUFF};
        not_meet_stuff ->
            {error, ?_LANG_REINFORCE_PLACED_MEET_STUFF};
        {ok, CStuff} ->
            {ok,{CEquip,CStuff}}
    end.
       
random_reinforce(Equip,Stuff) ->
    %% NewGrade = common_tool:random(1, 6),
    NewLevel = get_stuff_level(Stuff#p_goods.typeid),
    NewGrade = get_equip_reinforce_new_grade(Equip,NewLevel),
    ?DEV("NewGrade:~w",[NewGrade]),
    OldLevel = Equip#p_goods.reinforce_result div 10,
    OldGrade = Equip#p_goods.reinforce_result rem 10,
    if OldLevel+1 =/= NewLevel andalso
       OldGrade =:= ?REINFORCE_MAX_GRADE ->
            {error,?_LANG_REINFORCE_SAWP_STUFF};
       true ->
            NewLevel*10 + NewGrade
    end.
            
t_reinforce_equip({error,Reason},_) ->
    db:abort(Reason);
t_reinforce_equip(Result ,{Equip,Stuff}) ->
    ?DEBUG("Stuff:~w,Equip:~w",[Stuff,Equip]),
    MaterialLevel = get_stuff_level(Stuff#p_goods.typeid),
    MaterialBind = Stuff#p_goods.bind,
    {ok,[Data]} = mod_bag:decrease_goods(Equip#p_goods.roleid,[{Stuff,1}]),
    Data2 = 
        case Data of
            undefined ->
                Stuff;
            _ ->
                Data
        end,
    t_reinforce_equip2(Result, Equip, Data2, MaterialLevel, MaterialBind).

t_reinforce_equip2(Result, Equip, Stuff, MaterialLevel, MaterialBind) ->
    RefiningFee =#r_refining_fee{type = equip_reinforce_fee,
                                 equip_level = Equip#p_goods.level,
                                 material_level = MaterialLevel,
                                 refining_index = Equip#p_goods.refining_index,
                                 punch_num = Equip#p_goods.punch_num,
                                 stone_num = Equip#p_goods.stone_num,
                                 equip_color = Equip#p_goods.current_colour,
                                 equip_quality = Equip#p_goods.quality},
    case get_refining_fee(RefiningFee) of
        {ok,Fee} ->
            t_reinforce_equip3(Result, Equip, Stuff,Fee, MaterialBind);
        {error,Error} ->
            db:abort(Error)
    end.
t_reinforce_equip3(Result, Equip, Stuff,Fee, MaterialBind) ->
    ?DEBUG("t_reinforce_equip3, equip: ~w", [Equip]),
    RoleId = Equip#p_goods.roleid,
    EquipConsume = #r_equip_consume{type = reinforce,
                                    consume_type = ?CONSUME_TYPE_SILVER_EQUIP_REINFORCE,
                                    consume_desc = ""},
    case catch do_refining_deduct_fee(RoleId,Fee,EquipConsume) of
        {error,Error} ->
             db:abort(Error);
        _ ->
            t_reinforce_equip4(Result, Equip, Stuff, MaterialBind)
    end.
%% 处理当材料是洗炼时的，装备不洗炼时，装备洗炼处理
t_reinforce_equip4(Result,Equip,Stuff,MaterialBind) ->
    if MaterialBind ->
            case mod_refining_bind:do_equip_bind_for_reinforce(Equip) of
                {error,ErrorCode} ->
                    ?INFO_MSG("~ts,ErrorCode=~w",["装备强化时，当材料是洗炼的，装备是不洗炼时，处理洗炼出错，只是做洗炼处理，没有附加属性",ErrorCode]),
                    NewEquip = Equip#p_goods{bind=true},
                    t_reinforce_equip5(Result,NewEquip,Stuff);
                {ok,BindGoods} ->
                    t_reinforce_equip5(Result,BindGoods,Stuff)
            end;
       true ->
            t_reinforce_equip5(Result,Equip,Stuff)
    end.

t_reinforce_equip5(Result,Equip,Stuff)
  when Equip#p_goods.reinforce_result > Result ->
    {false, Equip,Stuff,?_LANG_REINFORCE_USED_PROTECT};
t_reinforce_equip5(Result,Equip,Stuff) ->
    t_reinforce_equip6(Result, Equip, Stuff).

t_reinforce_equip6(Result, Equip, Stuff)
  when Equip#p_goods.reinforce_result =:= Result ->
    %% Level = Result div 10,
    %% Grade = Result rem 10,
    %% Prompt = [ common_tool:to_list(<<"强化失败，">>),
    %%            common_tool:to_list(Equip#p_goods.name),
    %%            common_tool:to_list(<<"的">>),
    %%            erlang:integer_to_list(Level),
    %%            common_tool:to_list(<<"级强化保持">>),
    %%            erlang:integer_to_list(Grade),
    %%            common_tool:to_list(<<"星不变">>)],
    Prompt = ?_LANG_REINFORCE_USED_PROTECT,
    NewEquip = Equip#p_goods{reinforce_result = Result},  
    {false,NewEquip,Stuff,Prompt};
t_reinforce_equip6(Result, Equip, Stuff) ->
    Level = Result div 10,
    Grade = Result rem 10,
    Prompt = lists:flatten(io_lib:format(?_LANG_REINFORCE_SUCC,
                                         [common_tool:to_list(Equip#p_goods.name),
                                          erlang:integer_to_list(Level),
                                          erlang:integer_to_list(Grade)])),
    OldResult = Equip#p_goods.reinforce_result,
    OldResultList = Equip#p_goods.reinforce_result_list,
    if is_list(OldResultList) andalso is_integer(OldResult) ->
            NewEquip = Equip#p_goods{reinforce_result = Result,
                                     reinforce_result_list=[OldResult|OldResultList]};
       is_integer(OldResult) ->
            NewEquip = Equip#p_goods{reinforce_result = Result,
                                     reinforce_result_list=[OldResult]};
       true ->
            NewEquip = Equip#p_goods{reinforce_result = Result,
                                     reinforce_result_list=[]}
    end,            
    t_reinforce_equip7(true,OldResult,Level,Grade,NewEquip,Stuff,Prompt).
t_reinforce_equip7(Succ,OldResult, Level,Grade,Equip,Stuff,Prompt) ->
    OldLevel = OldResult div 10,
    OldRate = get_rate(OldLevel,OldResult rem 10),
    Rate = get_rate(Level,Grade),
    case change_equip_property(Equip, Rate, OldLevel=:=Level, OldRate) of
        error ->
            db:abort(?_LANG_REINFORCE_USED_PROTECT);
        NewEquip ->
            %% 计算装备精炼系数
            NewEquip2 = 
                case common_misc:do_calculate_equip_refining_index(NewEquip) of
                    {error,ErrorCode} ->
                        ?DEBUG("~ts,RefiningIndexErrorCode=~w",["计算装备精炼系数出错",ErrorCode]),
                        NewEquip;
                    {ok, RIGoods} ->
                        RIGoods
                end,
            mod_bag:update_goods(NewEquip2#p_goods.roleid,NewEquip2),
            {Succ, NewEquip2, Stuff, Prompt}
    end.

get_rate(Level,Grade) ->
    [List] = common_config_dyn:find(refining,reinforce_rate),
    proplists:get_value({Level,Grade}, List). 

get_stuff_level(StuffType) ->
    [List] = common_config_dyn:find(refining,reinforce_stuff),
    proplists:get_value(StuffType, List).

change_equip_property(Equip, Rate, SameLevel, OldRate) ->
    #p_goods{
              typeid = TypeID,
              reinforce_rate = TotalRate,
              add_property = Pro      
            }=Equip,
    case mod_equip:get_equip_baseinfo(TypeID) of
        {ok, BaseInfo} ->
            #p_equip_base_info{
          property=BasePro
         }= BaseInfo,
            #p_property_add{
              main_property = MainProperty
             }= BasePro,
            Pro = change_equip_property_1(Pro),
            case TotalRate of
                undefined ->
                    NewPro=change_main_property(MainProperty,Pro,BasePro,0,Rate),
                    Equip#p_goods{
                      reinforce_rate = Rate,
                      add_property = NewPro 
                     };
                TotalRate ->
                    {NewTotalRate, NewRate} =
                        case SameLevel of
                            true ->
                                {TotalRate+Rate-OldRate, Rate-OldRate};
                            false ->
                                {TotalRate+Rate, Rate}
                        end,
                    ?DEBUG("newtotalrate: ~w, newrate: ~w", [NewTotalRate, NewRate]),
                    NewPro=change_main_property(MainProperty,Pro,BasePro,TotalRate,NewTotalRate),
                    Equip#p_goods{
                      reinforce_rate = NewTotalRate,
                      add_property = NewPro 
                     }
            end;
        error ->
            error
    end.

change_equip_property_1(undefined) ->
    #p_property_add{
       blood=0,
       max_physic_att=0,
       min_physic_att=0,
       max_magic_att=0,
       min_magic_att=0,
       physic_def=0,
       magic_def=0};
change_equip_property_1(Pro) ->
    Pro.

change_main_property(?REFINING_BLOOD,Pro,BasePro,TotalRate, Rate) ->
    Pro#p_property_add{
        blood = round(BasePro#p_property_add.blood *Rate/10000)
      + Pro#p_property_add.blood - round(BasePro#p_property_add.blood * TotalRate/10000)
     };
change_main_property(?REFINING_PHYSIC_ATT,Pro,BasePro,TotalRate, Rate) ->
    Max = round(BasePro#p_property_add.max_physic_att *Rate/10000)
    + Pro#p_property_add.max_physic_att - round(BasePro#p_property_add.max_physic_att * TotalRate/10000),
    Poor = Max - Pro#p_property_add.max_physic_att,
    Min = Pro#p_property_add.min_physic_att + Poor,
    Pro#p_property_add{
        max_physic_att = Max,
        min_physic_att = Min
     };
change_main_property(?REFINING_MAGIC_ATT,Pro,BasePro,TotalRate, Rate) ->
    Max = round(BasePro#p_property_add.max_magic_att * Rate/10000)
    + Pro#p_property_add.max_magic_att - round(BasePro#p_property_add.max_magic_att * TotalRate/10000),
    Poor = Max - Pro#p_property_add.max_magic_att,
    Min = Pro#p_property_add.min_magic_att + Poor,
    Pro#p_property_add{
        max_magic_att = Max,
        min_magic_att = Min
     };
change_main_property(?REFINING_PHYSIC_DEF,Pro,BasePro,TotalRate, Rate) ->
    Pro#p_property_add{
        physic_def = round(BasePro#p_property_add.physic_def *Rate/10000)
      + Pro#p_property_add.physic_def - round(BasePro#p_property_add.physic_def * TotalRate/10000)
     };
change_main_property(?REFINING_MAGIC_DEF,Pro,BasePro,TotalRate, Rate) ->
    Pro#p_property_add{
        magic_def = round(BasePro#p_property_add.magic_def *Rate/10000)
      + Pro#p_property_add.magic_def - round(BasePro#p_property_add.magic_def * TotalRate/10000)
     }.

%%材料合成-----------------------------------------------------------------------------------------

do_compose(Unique, Module, Method, DataIn, RoleID, Line) ->
    ?DEBUG("mod_refining, do_compose, datain: ~w, roleid: ~w", [DataIn, RoleID]),
    ComposeType = DataIn#m_refining_compose_tos.compose_type,
    ?DEBUG("mod_refining, do_compose, composetype: ~w", [ComposeType]),
    case list_goods(RoleID, ?REFINING_BAGID) of
        {error, Reason} ->
            do_compose_error(Unique, Module, Method, RoleID, Reason, Line);
        GoodsList ->
            do_compose2(Unique, Module, Method, RoleID, ComposeType, GoodsList, Line)
    end.
do_compose2(Unique, Module, Method, RoleID, ComposeType, GoodsList, Line) ->
    ?DEBUG("mod_refining, composetype: ~w, goodslist: ~w", [ComposeType, GoodsList]),
    case if_can_compose(GoodsList, ComposeType) of
        {false, Reason} ->
            do_compose_error(Unique, Module, Method, RoleID, Reason, Line);
        {true, NextLevelID, TotalNum, BindNum} ->
            Div = get_div(ComposeType),
            do_compose3(Unique, Module, Method, RoleID, ComposeType, GoodsList, NextLevelID, TotalNum, BindNum, Div, Line)
    end.
do_compose3(Unique, Module, Method, RoleID, ComposeType, GoodsList, NextLevelID, TotalNum, BindNum, Div, Line) ->
    ?DEBUG("do_compose3, nextlevelid: ~w, totalnum: ~w, bindnum: ~w", [NextLevelID, TotalNum, BindNum]),
    {RestNormal, RestBind, NormalNum, BindNum2} = calc_rest_item(TotalNum, BindNum, ComposeType),
    ?DEBUG("do_compose, restnormal: ~w, restbind: ~w, normalnum: ~w, bindnum: ~w",
           [RestNormal, RestBind, NormalNum, BindNum2]),
    random:seed(now()),
    {GenNormalNum, GenBindNum} = calc_generate_num(NormalNum, BindNum2, ComposeType, Div, 0, 0),
    case db:transaction(
           fun() ->
                   t_do_compose(RoleID, GoodsList, NextLevelID, GenNormalNum, GenBindNum, RestNormal, RestBind)
           end)
    of 
        {aborted, Reason} ->
            case Reason of 
                {bag_error,{not_enough_pos,_BagID}} ->
                    R2 = ?_LANG_COMPOSE_SPACE_NOT_MEET,
                    do_compose_error(Unique, Module, Method, RoleID, R2, Line);
                {throw,{error,R}} ->
                    do_compose_error(Unique, Module, Method, RoleID, R, Line);
                _ ->
                    ?DEBUG("~ts,Reason=~w",["材料合成失败",Reason]),
                    do_compose_error(Unique, Module, Method, RoleID, Reason, Line)
            end;
        {atomic, {NormalGoodsList, BindGoodsList}} ->
            ?DEBUG("do_compose, succ", []),
            DataRecord = 
                if NormalGoodsList =:= undefined andalso BindGoodsList =:= undefined ->
                        #m_refining_compose_toc{succ = false, reason = ?_LANG_COMPOSE_COMPOSE_ERROR};
                   true ->
                        #m_refining_compose_toc{succ = true}
                end,
            catch do_compose4(RoleID,GoodsList,NextLevelID),
            common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord)
    end.
do_compose4(RoleID,GoodsList,NextLevelID) ->
    NewGoodsList = mod_refining_bag:get_goods_by_bag_id(RoleID,?REFINING_BAGID),
    [OldGoods] = mod_equip_build:count_class_equip_build_goods(GoodsList,[]),
    NewGoodsList2 = mod_equip_build:count_class_equip_build_goods(NewGoodsList,[]),
    if NewGoodsList2 =:= [] ->
            %% 道具消费日志
            common_item_logger:log(RoleID,OldGoods#p_equip_build_goods.type_id, 
                                          OldGoods#p_equip_build_goods.current_num,
                                   undefined,?LOG_ITEM_TYPE_HE_CHENG_SHI_QU),
            ignore;
       erlang:length(NewGoodsList2) =:= 1 ->
            [NewGoods] = NewGoodsList2,
            %% 道具消费日志
            common_item_logger:log(RoleID,OldGoods#p_equip_build_goods.type_id, 
                                          OldGoods#p_equip_build_goods.current_num,
                                   undefined,?LOG_ITEM_TYPE_HE_CHENG_SHI_QU),
            common_item_logger:log(RoleID,NewGoods#p_equip_build_goods.type_id, 
                                          NewGoods#p_equip_build_goods.current_num,
                                   undefined,?LOG_ITEM_TYPE_HE_CHENG_HUO_DE);
       erlang:length(NewGoodsList2) =:= 2 ->
            [NewGoods] = [R || R <- NewGoodsList2,R#p_equip_build_goods.type_id =:= NextLevelID],
            [OldGoods2] = [R || R <- NewGoodsList2,R#p_equip_build_goods.type_id =/= NextLevelID],
            OldNum = OldGoods#p_equip_build_goods.current_num - OldGoods2#p_equip_build_goods.current_num,
            %% 道具消费日志
            common_item_logger:log(RoleID,OldGoods#p_equip_build_goods.type_id, 
                                          OldNum,
                                   undefined,?LOG_ITEM_TYPE_HE_CHENG_SHI_QU),
            common_item_logger:log(RoleID,NewGoods#p_equip_build_goods.type_id, 
                                          NewGoods#p_equip_build_goods.current_num,
                                   undefined,?LOG_ITEM_TYPE_HE_CHENG_HUO_DE);
       true ->
            ignore
    end.
    
do_compose_error(Unique, Module, Method, RoleID, Reason, Line) ->
    Reason2 = 
        if is_binary(Reason) ->
                Reason;
           true ->
                ?DEBUG("do_compose_error, reason: ~w", [Reason]),
                ?_LANG_COMPOSE_COMPOSE_ERROR
        end,
    DataRecord = #m_refining_compose_toc{succ = false, reason = Reason2},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord).

t_do_compose(RoleID, GoodsList, NextLevelID, GenNormalNum, GenBindNum, RestNormal, RestBind) ->
    ?DEBUG("mod_refining, t_do_compose, gennormalnum: ~w, genbindnum: ~w", [GenNormalNum, GenBindNum]),
    [H | _] = GoodsList,
    TypeID = H#p_goods.typeid,
    DeleteGoodsIds = [R#p_goods.id || R <- GoodsList],
    mod_bag:delete_goods(RoleID,DeleteGoodsIds),
    Type =
        case common_config_dyn:find_item(NextLevelID) of
            [_Item] ->
                ?TYPE_ITEM;
            [] ->
                case common_config_dyn:find_stone(NextLevelID) of
                    [_Stone] ->
                        ?TYPE_STONE;
                    [] ->
                        db:abort("can't find goods")
                end
        end,
    t_do_compose2(RoleID, NextLevelID, GenNormalNum, GenBindNum, Type, RestNormal, RestBind, TypeID).
      
t_do_compose2(RoleID, NextLevelID, GenNormalNum, GenBindNum, Type, RestNormal, RestBind, TypeID) ->
    {ok,NormalGoods} =
        case GenNormalNum =:= 0 of
            false ->
                CreateInfo1 = #r_goods_create_info{type=Type,bag_id=?REFINING_BAGID,
                                              type_id=NextLevelID,num=GenNormalNum,bind=false},
                mod_bag:create_goods(RoleID,?REFINING_BAGID,CreateInfo1);
            true ->
                {ok,undefined}
        end,
    {ok,BindGoods} =
        case GenBindNum =:= 0 of
            false ->
                CreateInfo2 = #r_goods_create_info{type=Type,bag_id=?REFINING_BAGID,
                                                  type_id=NextLevelID,num=GenBindNum,bind=true},
                mod_bag:create_goods(RoleID,?REFINING_BAGID,CreateInfo2);
            true ->
                {ok,undefined}
        end,
    t_do_compose3(RoleID, TypeID, Type, RestNormal, RestBind),
    {NormalGoods, BindGoods}.
t_do_compose3(RoleID, TypeID, Type, RestNormal, RestBind) ->
    ?DEBUG("t_do_compose3, goodsid: ~w", [TypeID]),
    case RestNormal =:= 0 of
        true ->
            ok;
        false ->
            CreateInfo1 = #r_goods_create_info{type=Type,bag_id=?REFINING_BAGID,
                                              type_id=TypeID,num=RestNormal,bind=false},
            mod_bag:create_goods(RoleID,?REFINING_BAGID,CreateInfo1)
    end,
    case RestBind =:= 0 of
        true ->
            ok;
        false ->
            CreateInfo2 = #r_goods_create_info{type=Type,bag_id=?REFINING_BAGID,
                                              type_id=TypeID,num=RestBind,bind=true},
            mod_bag:create_goods(RoleID,?REFINING_BAGID,CreateInfo2)
    end.   

get_div(ComposeType) ->
    case ComposeType of
        1 ->
            5;
        2 ->
            4;
        3 ->
            3
    end.
%%装备打孔-------------------------------------------------------------------------------------         

do_punch(Unique, Module, Method, DataIn, RoleID, Line) ->
    ?DEBUG("mod_refining, do_punch, datain: ~w, roleid: ~w", [DataIn, RoleID]),
    case list_goods(RoleID, ?REFINING_BAGID) of
        {error, Reason} ->
            do_punch_error(Unique, Module, Method, RoleID, Reason, Line);
        GoodsList ->
            do_punch2(Unique, Module, Method, RoleID, GoodsList, Line)
    end.
do_punch2(Unique, Module, Method, RoleID, GoodsList, Line) ->
    ?DEBUG("mod_refining, do_punch2, goodslist: ~w", [GoodsList]),
    case if_can_punch(GoodsList) of
        {false, Reason} ->
            do_punch_error(Unique, Module, Method, RoleID, Reason, Line);
        {true, Equip, Rune} ->
            ?DEBUG("mod_refining, do_punch2, equip: ~w, rune: ~w", [Equip, Rune]),
            case db:transaction(
              fun() ->
                      t_do_punch(RoleID, Equip, Rune)
              end) 
            of
                {aborted, Reason} when is_binary(Reason)->
                    do_punch_error(Unique, Module, Method, RoleID, Reason, Line);
                {aborted, _} ->
                    do_punch_error(Unique, Module, Method, RoleID, ?_LANG_SYSTEM_ERROR, Line);
                {atomic, _} ->
                    ?DEBUG("mod_refining, do_punch2, succ", []),
                    DataRecord = #m_refining_punch_toc{succ = true},
                    do_refining_deduct_fee_notify(RoleID,{line, Line, RoleID}),
                    [RuneGoods] = mod_equip_build:count_class_equip_build_goods(Rune,[]),
                    %% 道具消费日志
                    catch common_item_logger:log(RoleID,RuneGoods#p_equip_build_goods.type_id, 
                                                        1,
                                                 undefined,?LOG_ITEM_TYPE_KAI_KONG_SHI_QU),
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord)
                    
            end
    end.

do_punch_error(Unique, Module, Method, RoleID, Reason, Line) ->
    ?DEBUG("mod_refining, do_punch_error, reason: ~w", [Reason]),
    DataRecord = #m_refining_punch_toc{succ = false, reason = Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord).

t_do_punch(RoleID, Equip, Rune) ->
    ?DEBUG("mod_refining, t_do_punch, roleid: ~w, equip: ~w, rune: ~w", [RoleID, Equip, Rune]),
    Item = get_min_pos_goods(Rune),
    Bind = Item#p_goods.bind,
    ?DEBUG("mod_refining, t_do_punch, item: ~w", [Item]),
    mod_bag:decrease_goods(RoleID,[{Item,1}]),
    Tmp =
        case Bind of
            true ->
                case mod_refining_bind:do_equip_bind_for_punch(Equip) of
                    {error,ErrorCode} ->
                        ?INFO_MSG("~ts,ErrorCode=~w",["装备打孔时，材料是洗炼的，装备不洗炼，洗炼出错，一般洗炼处理",ErrorCode]),
                        Equip#p_goods{bind = true};
                    {ok,BindGoods} ->
                        BindGoods
                end;
            false ->
                Equip
        end,
    PunchNum = Equip#p_goods.punch_num,
    NewEquip = Tmp#p_goods{punch_num = PunchNum + 1},
    MaterialLevel = Item#p_goods.level,
    t_do_punch2(RoleID, NewEquip, Rune,MaterialLevel).

t_do_punch2(RoleID, Equip, Rune,MaterialLevel) ->
    ?DEBUG("~ts,MaterialLevel=~w",["装备打孔费用计算",MaterialLevel]),
    RefiningFee =#r_refining_fee{type = equip_punch_fee,
                                 equip_level = Equip#p_goods.level,
                                 material_level = MaterialLevel,
                                 material_number = 1,
                                 refining_index = Equip#p_goods.refining_index,
                                 punch_num = Equip#p_goods.punch_num,
                                 stone_num = Equip#p_goods.stone_num,
                                 equip_color = Equip#p_goods.current_colour,
                                 equip_quality = Equip#p_goods.quality},
    case get_refining_fee(RefiningFee) of
        {ok,Fee} ->
            t_do_punch3(RoleID, Equip, Rune, Fee);
        {error,Error} ->
            db:abort(Error)
    end.
t_do_punch3(RoleID, Equip, _Rune, Fee) ->
    %% 扣费
    EquipConsume = #r_equip_consume{type = punch,          
                                    consume_type = ?CONSUME_TYPE_SILVER_EQUIP_PUNCH,
                                    consume_desc = ""},
    case catch do_refining_deduct_fee(RoleID,Fee,EquipConsume) of
        {error,Error} ->
            db:abort(Error);
        _ ->
            next
    end,
    %% 计算装备精炼系数
    Equip2 = 
        case common_misc:do_calculate_equip_refining_index(Equip) of
            {error,ErrorCode} ->
                ?DEBUG("~ts,RefiningIndexErrorCode=~w",["计算装备精炼系数出错",ErrorCode]),
                Equip;
            {ok, RIGoods} ->
                RIGoods
        end,
    mod_bag:update_goods(RoleID,Equip2).

get_min_pos_goods(GoodsList) ->
    Fun =
        fun(Goods, {Index, Mindex, MinPos}) ->
                Pos = Goods#p_goods.bagposition,   
                case Pos < MinPos of
                    true ->
                        {Index + 1, Index, Pos};
                    false ->
                        {Index + 1, Mindex, MinPos}
                end
        end,
    {_, Min, _} = lists:foldl(Fun, {1, 0, 10}, GoodsList),
    ?DEBUG("mod_refining, get_min_pos_goods, min: ~w", [Min]),
    lists:nth(Min, GoodsList).

if_can_punch(GoodsList) ->
    ?DEBUG("mod_refining, if_can_punch, goodslist: ~w", [GoodsList]),
    Fun = fun(Goods, {Equip, Rune}) ->
                  case Goods#p_goods.type of
                      3 ->
                          {[Goods | Equip], Rune};
                      _ ->
                          {Equip, [Goods | Rune]}
                  end
          end,
    {Equip, Rune} = lists:foldl(Fun, {[], []}, GoodsList),
    if_can_punch2(Equip, Rune).

if_can_punch2([], _) ->
     {false, ?_LANG_PUNCH_POS_NOT_5};
if_can_punch2([E],Rune) ->
    PunchNum = E#p_goods.punch_num,
    BagPos = E#p_goods.bagposition,
    ?DEBUG("mod_refining, if_can_punch2, punchnum: ~w, bagpos: ~w", [PunchNum, BagPos]),
    if BagPos =/= 5 ->
            {false, ?_LANG_PUNCH_POS_NOT_5};
       PunchNum >= ?MAX_PUNCH_NUM ->
            {false, ?_LANG_PUNCH_MAX_HOLE};
       true ->
            TypeID = E#p_goods.typeid,
            [BaseInfo] = common_config_dyn:find_equip(TypeID),
            EquipKind = BaseInfo#p_equip_base_info.kind,
            ?DEBUG("mod_refining, if_can_punch2, equipkind: ~w", [EquipKind]),
            [PunchList] = common_config_dyn:find(refining,punch_kind_list),
            ?DEBUG("mod_refining, if_can_punch2, punchlist: ~w", [PunchList]),
            case lists:member(EquipKind, PunchList) of
                true ->
                    if_can_punch3(E, Rune);
                false ->
                    ?DEBUG("mod_refining, if_can_punch2, not in punchlist", []),
                    {false, ?_LANG_PUNCH_CANT_PUNCH}
            end
    end;
if_can_punch2(_,_) ->
    ?DEBUG("mod_refining, if_can_punch2, equip error", []),
    {false, ?_LANG_PUNCH_MULTI_EQUIP}.

if_can_punch3(_, []) ->
    ?DEBUG("mod_refining, if_can_punch3, can't find rune", []),
    {false, ?_LANG_PUNCH_INTO_SYMBOL};
if_can_punch3(Equip, Rune) ->
    ?DEBUG("mod_refining, if_can_punch3, equip: ~w, rune: ~w", [Equip, Rune]),
    PunchNum = Equip#p_goods.punch_num,
    [#p_goods{typeid=TypeID}|_]= Rune,
    Level = get_rune_symbol_level(TypeID),
    Rune2 = [Record || Record <- Rune, Record#p_goods.typeid =/= TypeID],
    if not is_integer(Level) ->
            {false, ?_LANG_PUNCH_INTO_SYMBOL};
       Level < PunchNum+1 ->
            {false, ?_LANG_PUNCH_CANT_PUNCH};
       Rune2 =:= [] ->
            {true,Equip,Rune};
       true ->
            ?DEBUG("mod_refining, if_can_punch3, more than one rune", []),
            {false, ?_LANG_PUNCH_INTO_OTHER}
    end.
%% if_can_punch4(Equip, Rune) ->
%%     ?DEBUG("mod_refining, if_can_punch4, equip: ~w, rune: ~w", [Equip, Rune]),
%%     PunchNum = Equip#p_goods.punch_num,
%%     [#p_goods{typeid=TypeID}| _T] = Rune,
%%     Level = get_rune_symbol_level(TypeID),
%%     ?DEBUG("mod_refining, if_can_punch4, level: ~w, nextnum: ~w", [Level, PunchNum+1]),
%%     case  Level < PunchNum+1 of
%%         false ->
%%             {true, Equip, Rune};
%%         true ->
%%             {false, ?_LANG_PUNCH_CANT_PUNCH}
%%     end.

get_rune_symbol_level(SymbolType) ->
    [List] = common_config_dyn:find(refining,rune_symbol),
    proplists:get_value(SymbolType, List).


calc_rest_item(TotalNum, BindNum, ComposeType) ->    
    ?DEBUG("calc_rest_num, totalnum: ~w, bindnum: ~w", [TotalNum, BindNum]),
    Div = get_div(ComposeType),
    case TotalNum rem Div of
        0 ->
            {0, 0, TotalNum - BindNum, BindNum};
        Mod ->
            case BindNum > TotalNum - Mod of
                false ->
                    {Mod, 0, TotalNum - BindNum - Mod, BindNum};
                true ->
                    {TotalNum - BindNum, BindNum - (TotalNum - Mod),
                     0, TotalNum - Mod}
            end
    end.

calc_generate_num(0, 0, _ComposeType, _Div, GenNormal, GenBind) ->
    {GenNormal, GenBind};
calc_generate_num(NormalNum, BindNum, ComposeType, Div, GenNormal, GenBind) ->    
    {RestNormal, RestBind} = calc_rest_num(NormalNum, BindNum, Div),
    ?DEBUG("calc_generate_num, resttotal: ~w, restbind: ~w", [RestNormal, RestBind]),
    case if_succ(ComposeType) of
        false ->
            ?DEBUG("gen, false", []),
            calc_generate_num(RestNormal, RestBind, ComposeType, Div, GenNormal, GenBind);
        true ->
            ?DEBUG("gen, true", []),
            case BindNum > 0 of
                true ->
                    calc_generate_num(RestNormal, RestBind, ComposeType, Div, GenNormal, GenBind + 1);
                false ->
                    calc_generate_num(RestNormal, RestBind, ComposeType, Div, GenNormal + 1, GenBind)
            end
    end.

calc_rest_num(NormalNum, BindNum, Div) ->
    case BindNum > 0 of
        true ->
            case BindNum - Div > 0 of
                true ->
                    {NormalNum, BindNum - Div};
                false ->
                    Tmp = Div - BindNum,
                    case NormalNum - Tmp =< 0 of
                        true ->
                            {0,0};
                        false ->
                            {NormalNum - Tmp, 0}
                    end
            end;
        false ->
            case NormalNum - Div =< 0 of
                true ->
                    {0, 0};
                false ->
                    {NormalNum - Div, 0}
            end
    end.

list_goods(RoleID, BagID) ->
    ?DEBUG("list_goods, roleid: ~w, bagid: ~w", [RoleID, BagID]),
    case mod_refining_bag:get_goods_by_bag_id(RoleID,BagID) of
        [] ->
            {error, ?_LANG_COMPOSE_INTO_GOODS};
        GoodsList when is_list(GoodsList) ->
            ?DEBUG("GoodsList = ~w",[GoodsList]),
            GoodsList
    end.

if_can_compose(GoodsList, ComposeType) ->
    {TotalNum, BindNum} = check_total_bind_num(GoodsList),
    ?DEBUG("if_can_compose, totalnum: ~w, bindnum: ~w", [TotalNum, BindNum]),
    case ComposeType > 3 orelse ComposeType < 1 of
        true ->
            {false, ?_LANG_COMPOSE_ERROR_TYPE};
        false ->
            Div = get_div(ComposeType),
            case TotalNum >= Div of
                true ->
                    if_can_compose2(GoodsList, TotalNum, BindNum);
                _ ->
                    {false, ?_LANG_COMPOSE_NOT_ENOUGH_NUM}
            end
    end.
if_can_compose2(GoodsList, TotalNum, BindNum) ->
    ?DEBUG("mod_refining, if_can_compose2, goodslist: ~w", [GoodsList]),
    case GoodsList of
        [] ->
            {false, ?_LANG_COMPOSE_NO_GOODS};
        [Goods] ->
            [Goods] = GoodsList,
            TypeID = Goods#p_goods.typeid,
            if_can_compose3(TypeID, TotalNum, BindNum);
        [Goods | _T] ->
            TypeID = Goods#p_goods.typeid,
            case [Record || Record <- GoodsList,Record#p_goods.typeid =/= TypeID] of
                [] ->
                    case [Record || Record <- GoodsList,Record#p_goods.type =:= 3] of
                        [] ->
                            if_can_compose3(TypeID,TotalNum,BindNum);
                        _ ->
                            {false,?_LANG_COMPOSE_EQUIP_NOT_CAN}
                    end;
                _ ->
                    ?DEBUG("if_can_compose2, false", []),
                    {false, ?_LANG_COMPOSE_MORE_THAN_ONE_KIND}
            end
    end.
if_can_compose3(TypeID, TotalNum, BindNum) ->
    ?DEBUG("mod_refining, if_can_compose3, typeid: ~w", [TypeID]),
    case common_config_dyn:find(compose,TypeID) of
        [NextLevelID] ->
            {true, NextLevelID, TotalNum, BindNum};
        _ ->
            {false, ?_LANG_COMPOSE_CANT_COMPOSE}
    end.

%%获取物品总数及洗炼数量
check_total_bind_num(GoodsList) ->
    ?DEBUG("mod_refining, check_bind, goodslist: ~w", [GoodsList]),
    Fun =
        fun(Goods, {Sum, BindNum}) ->
                Bind = Goods#p_goods.bind,
                Num = Goods#p_goods.current_num,
                case Bind of
                    true ->
                        {Sum + Num, BindNum + Num};
                    false ->
                        {Sum + Num, BindNum}
                end
        end,
    lists:foldl(Fun, {0, 0}, GoodsList).

if_succ(ComposeType) ->
    Probability =
        case ComposeType of
            ?FIVE_TO_ONE ->
                100;
            ?FOUR_TO_ONE ->
                80;
            ?THREE_TO_ONE ->
                60;
            _ ->
                0
        end,
    case Probability of
        0 ->
            false;
        100 ->
            true;
        _ ->
            if_succ2(Probability)
    end.
if_succ2(Probability) ->
    Rand = random(100),
    case Rand =< Probability of
        true ->
            true;
        false ->
            false
    end.

%%宝石的镶嵌-----------------------------------------------------------------------------------
do_inlay({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_refining_inlay_tos{bagid= BagID, equipid=EquipID} = DataIn, 
    R = case mod_refining_bag:get_goods_by_bag_id(RoleID,BagID) of
            [] ->
                do_inlay_error(?_LANG_INLAY_POS_NOT_5);
            GoodsList when is_list(GoodsList) ->
                do_inlay2(GoodsList,EquipID)
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_inlay2(GoodsList,EquipID) ->
    ExtractGoods = extract_inlay_goods(GoodsList,EquipID),
    ?DEBUG("Goods:~p",[ExtractGoods]),
    case check_inlay_goods(ExtractGoods) of
        {ok, CheckGoods} ->
            do_inlay3(CheckGoods);
        {error,Reason} ->
            do_inlay_error(Reason)
    end.

do_inlay3(CheckGoods) -> 
    F = fun() ->
                t_inlay(CheckGoods)
        end,
    case db:transaction(F) of
        {aborted, Reason} when is_binary(Reason)->
            do_inlay_error(Reason);
        {aborted, Reason} ->
            ?ERROR_MSG("~ts:~w",["宝石镶嵌错误",Reason]),
            do_inlay_error(?_LANG_SYSTEM_ERROR);
        {atomic, {Equip,Stone,Symbol}} ->
            RoleId = Equip#p_goods.roleid,
            do_refining_deduct_fee_notify(RoleId,{role,RoleId}),
            %% 成就系统添加hook
            common_mod_hook:hook_refining_inlay(RoleId),
            %% 道具消费日志
            catch common_item_logger:log(RoleId,Stone,1,?LOG_ITEM_TYPE_XIANG_QIAN_SHI_QU),
            catch common_item_logger:log(RoleId,Symbol,1,?LOG_ITEM_TYPE_XIANG_QIAN_SHI_QU),
            if Stone#p_goods.current_num =< 0 ->
                    #m_refining_inlay_toc{succ=true, 
                                          equip=Equip,
                                          symbol=Symbol};
               true ->                
                    #m_refining_inlay_toc{succ=true, 
                                          equip=Equip,
                                          stone=Stone, 
                                          symbol=Symbol}
            end
    end.

do_inlay_error(Reason) ->
    #m_refining_inlay_toc{
                succ = false, 
                reason = Reason
               }.

extract_inlay_goods(GoodsList,EquipID) ->
    F = fun(Goods, {Stone,Equip,Symbol,Other}) ->
                ID = Goods#p_goods.id,
                J = get_inlay_symbol_level(Goods#p_goods.typeid),
                if
                    ID =:= EquipID ->
                        {Stone,[Goods|Equip],Symbol,Other};
                    J =/= undefined ->
                        {Stone,Equip,[Goods|Symbol],Other};
                    Goods#p_goods.type =:= 2 ->
                        {[Goods|Stone],Equip,Symbol,Other};
                    true ->
                        {Stone,Equip,Symbol,[Goods|Other]}
                end
        end,
    lists:foldl(F, {[],[],[],[]}, GoodsList).

check_inlay_goods({_,_,_,[]}=R) ->
    check_inlay_goods2({nil,nil,nil},R);
check_inlay_goods(_) ->
    {error,?_LANG_INLAY_HAS_OTHER}.

check_inlay_goods2({nil,CStone,CSymbol},{_,Equip,_,_}=R) ->
    case Equip of
        [] ->
            {error, ?_LANG_INLAY_POS_NOT_5};
        [CEquip] ->          
            if 
                CEquip#p_goods.bagposition =/= 5 ->
                    {error, ?_LANG_INLAY_POS_NOT_5};
                CEquip#p_goods.punch_num =:= undefined ->
                    {error, ?_LANG_INLAY_HOLE_FULL};
                CEquip#p_goods.stone_num =:= undefined ->
                    NewEquip = CEquip#p_goods{stone_num=0},
                    check_inlay_goods2({NewEquip,CStone,CSymbol},R);
                CEquip#p_goods.punch_num  < CEquip#p_goods.stone_num ->
                    {error, ?_LANG_INLAY_HOLE_FULL};
                CEquip#p_goods.punch_num  =:= CEquip#p_goods.stone_num ->
                    {error, ?_LANG_INLAY_HOLE_FULL};
                true ->
                    check_inlay_goods2({CEquip,CStone,CSymbol},R)
            end;
        _ ->
            {error, ?_LANG_INLAY_CAN_NOT_MANY_EQUIP}
    end;
check_inlay_goods2({CEquip,nil,CSymbol},{Stone,_,_,_}=R) ->
    case Stone of
        [] ->
            {error, ?_LANG_INLAY_NO_STONE};
        [CStone] ->
            case check_stone_can_inlay(CEquip,CStone) of
                ok ->
                    check_inlay_goods2({CEquip,CStone,CSymbol},R);
                {error,Reason} ->
                    {error, Reason}
            end;
        _ ->
            {error, ?_LANG_INLAY_CAN_NOT_MANY_STONE}
    end;
check_inlay_goods2({CEquip,CStone,nil},{_,_,Symbol,_}) ->
    case check_symbol(CEquip, Symbol) of
        {error, Reason} ->
            {error, Reason};
        {ok, CSymbol} ->
            {ok,{CEquip,CStone,CSymbol}}
    end.

check_stone_can_inlay(Equip,Stone) ->
    case mod_equip:get_equip_baseinfo(Equip#p_goods.typeid) of
        {ok, EquipBI} ->
            case mod_stone:get_stone_baseinfo(Stone#p_goods.typeid) of
                {ok, StoneBI} ->
                    ?DEBUG("StoneBI:~w",[StoneBI]),
                    Slot = EquipBI#p_equip_base_info.slot_num,
                    List = StoneBI#p_stone_base_info.embe_equip_list,
                    Kind = StoneBI#p_stone_base_info.kind,
                    Stones = Equip#p_goods.stones,
                    check_stone_can_inlay2(Slot, List, Kind, Stones);
                error ->
                    {error,?_LANG_SYSTEM_ERROR}
            end;
        error ->
            {error,?_LANG_SYSTEM_ERROR}
    end.

check_stone_can_inlay2(Slot, List, Kind, Stones)
  when is_integer(Slot) andalso
       is_integer(Kind) andalso
       is_list(List) ->
    ?DEBUG("Slot:~w,List:~w,Kind:~w,Stones:~w",[Slot,List,Kind,Stones]),
    F = fun(Stone,Acc) ->
                case mod_stone:get_stone_baseinfo(Stone#p_goods.typeid) of
                    {ok, StoneBI} ->
                        if StoneBI#p_stone_base_info.kind =:= Kind ->
                                throw({error,?_LANG_INLAY_WITH_TYPE});
                           true ->
                                Acc
                        end;
                    error ->
                        throw({error,?_LANG_SYSTEM_ERROR})
                end
        end,
    case lists:member(Slot,List) of
        false ->
            {error,?_LANG_INLAY_STONE_NOT_CAN_INLAY};
        true -> 
            (catch lists:foldl(F,ok,if is_list(Stones) -> Stones;true -> [] end))
    end;              
check_stone_can_inlay2(_, _, _, _) ->
    {error, ?_LANG_INLAY_STONE_NOT_CAN_INLAY}.

check_symbol(_, []) ->
    {error, ?_LANG_INLAY_NOT_SYMBOL};
check_symbol(Equip, [H|[]]) ->
    Level = get_inlay_symbol_level(H#p_goods.typeid),
    ?DEBUG("Level:~w,Num:~w",[Level,Equip#p_goods.stone_num]),
    case Equip#p_goods.stone_num+1 > Level of
        false ->
            {ok, H};
        true ->
            {error, ?_LANG_INLAY_HAS_OTHER_SYMBOL}
    end;
check_symbol(Equip, [H|T]) -> 
    Level = get_inlay_symbol_level(H#p_goods.typeid),
    ?DEBUG("Level:~w,Num:~w",[Level,Equip#p_goods.stone_num]),
    case Equip#p_goods.stone_num+1 > Level of
        false ->
            check_symbol(Equip,T);
        true ->
            {error, ?_LANG_INLAY_HAS_OTHER_SYMBOL}
    end.

t_inlay({Equip, Stone, Symbol}) ->
    StoneID = Stone#p_goods.typeid,
    case mod_stone:get_stone_baseinfo(StoneID) of
        error ->
            db:abort(?_LANG_SYSTEM_ERROR);
        {ok, BaseInfo} ->
            ?DEV("Equip:~w",[Equip]),
            {BasePro, Pro} = t_inlay_1(BaseInfo, Equip),
            t_inlay2(Pro, BasePro, Equip, Stone, Symbol)
    end.

t_inlay_1(BaseInfo,Equip)
  when is_record(BaseInfo, p_stone_base_info)->
    t_inlay_1_1(BaseInfo#p_stone_base_info.level_prop, Equip#p_goods.add_property).

t_inlay_1_1(Pro, BasePro) 
  when is_record(Pro, p_property_add), is_record(BasePro, p_property_add)->
    {Pro, BasePro}.

t_inlay2(Pro,BasePro,Equip,Stone,Symbol) ->
    SeatList =
        case get_main_property_seat(BasePro#p_property_add.main_property) of
            SeatR when is_integer(SeatR) andalso SeatR > 1 ->
                [SeatR];
            SeatR when is_list(SeatR) ->
                SeatR;
            _ ->
                db:abort(?_LANG_INLAY_STONE_NOT_CAN_INLAY)
        end,
    ?DEBUG("Pro:~w BasePro:~w",[Pro,BasePro]),
    NewPro = lists:foldl(
               fun(Seat,AccPro) ->
                       R = t_inlay2_1(erlang:element(Seat, AccPro),erlang:element(Seat,BasePro)),
                       Pro1 =erlang:setelement(Seat, AccPro, R),
                       ?DEBUG("Pro1:~w R:~w",[Pro1,R]),
                       Pro1
               end,Pro,SeatList),
    ?DEBUG("NewPro:~w",[NewPro]),
    t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol).
        

%% t_inlay2(?REFINING_DIZZY,Pro,BasePro,Equip,Stone,Symbol) -> 
%%     R = t_inlay2_1(Pro#p_property_add.dizzy, BasePro#p_property_add.dizzy),
%%     NewPro = Pro#p_property_add{dizzy = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(?REFINING_DIZZY_RESIST,Pro,BasePro,Equip,Stone,Symbol) -> 
%%     R = t_inlay2_1(Pro#p_property_add.dizzy_resist, BasePro#p_property_add.dizzy_resist),
%%     NewPro = Pro#p_property_add{dizzy_resist = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(?REFINING_POISONING,Pro,BasePro,Equip,Stone,Symbol) -> 
%%     R = t_inlay2_1(Pro#p_property_add.poisoning, BasePro#p_property_add.poisoning),
%%     NewPro = Pro#p_property_add{poisoning = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(?REFINING_POISONING_RESIST,Pro,BasePro,Equip,Stone,Symbol) -> 
%%     R = t_inlay2_1(Pro#p_property_add.poisoning_resist, BasePro#p_property_add.poisoning_resist),
%%     NewPro = Pro#p_property_add{poisoning_resist = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(?REFINING_FREEZE,Pro,BasePro,Equip,Stone,Symbol) -> 
%%     R = t_inlay2_1(Pro#p_property_add.freeze, BasePro#p_property_add.freeze),
%%     NewPro = Pro#p_property_add{freeze = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(?REFINING_PREEZE_RESIST,Pro,BasePro,Equip,Stone,Symbol) -> 
%%     R = t_inlay2_1(Pro#p_property_add.freeze_resist, BasePro#p_property_add.freeze_resist),
%%     NewPro = Pro#p_property_add{freeze_resist = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(?REFINING_HURT,Pro,BasePro,Equip,Stone,Symbol) -> 
%%     R = t_inlay2_1(Pro#p_property_add.hurt, BasePro#p_property_add.hurt),
%%     NewPro = Pro#p_property_add{hurt = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(?REFINING_HURT_SHIFT,Pro,BasePro,Equip,Stone,Symbol) -> 
%%     R = t_inlay2_1(Pro#p_property_add.hurt_shift, BasePro#p_property_add.hurt_shift),
%%     NewPro = Pro#p_property_add{hurt_shift = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(?REFINING_DEAD_ATTACK,Pro,BasePro,Equip,Stone,Symbol) ->
%%     R = t_inlay2_1(Pro#p_property_add.dead_attack, BasePro#p_property_add.dead_attack),
%%     NewPro = Pro#p_property_add{dead_attack = R},
%%     t_inlay3(Equip#p_goods{add_property = NewPro}, Stone, Symbol);

%% t_inlay2(_,_,_,_,_,_) ->
%%     db:abort(?_LANG_INLAY_STONE_NOT_INLAY).

t_inlay2_1(R1, R2)
  when is_integer(R1),is_integer(R2)->
    R1+R2.

t_inlay3(Equip, Stone, Symbol) ->
    ?DEV("NewEquip:~w",[Equip]),
    CanInlayStone = Stone#p_goods{current_num=1},
    NotInlayStone = Stone#p_goods{current_num = Stone#p_goods.current_num-1},
    if NotInlayStone#p_goods.current_num =< 0 ->
            mod_bag:delete_goods(Equip#p_goods.roleid,NotInlayStone#p_goods.id);
       true ->
            mod_bag:update_goods(Equip#p_goods.roleid,NotInlayStone)
    end,
    {NewInlayStone, NewEquip} = t_inlay3_1(Equip, CanInlayStone),
    t_inlay4(NewInlayStone, NewEquip, NotInlayStone, Symbol).

t_inlay3_1(Equip, Stone) ->
    %% 已经镶嵌在装备的宝石 id置为0
    NewStone = Stone#p_goods{
                 %% id = 0,
                 %% bagid = 0,
                 %% bagposition = 0,
                 roleid = Equip#p_goods.roleid,
                 embe_pos = Equip#p_goods.stone_num+1,
                 embe_equipid = Equip#p_goods.id
                },
    Stones = case Equip#p_goods.stones of
                 StonesT when erlang:is_list(StonesT) ->
                     StonesT;
                 _ ->
                     []
             end,
    NewEquip = Equip#p_goods{
                 stone_num = Equip#p_goods.stone_num+1,
                 stones = lists:reverse([NewStone|lists:reverse(Stones)])
                },
    {NewStone,NewEquip}.

t_inlay4(InalyStone, Equip, Stone, Symbol) ->
    RefiningFee =#r_refining_fee{type = equip_inlay_fee,
                                 equip_level = Equip#p_goods.level,
                                 refining_index = Equip#p_goods.refining_index,
                                 punch_num = Equip#p_goods.punch_num,
                                 stone_num = Equip#p_goods.stone_num,
                                 equip_color = Equip#p_goods.current_colour,
                                 equip_quality = Equip#p_goods.quality},
    case get_refining_fee(RefiningFee) of
        {ok,Fee} ->
            t_inlay5(InalyStone, Equip, Stone, Symbol, Fee);
        {error,Error} ->
            db:abort(Error)
    end.
t_inlay5(_InalyStone, Equip, Stone, Symbol, Fee) ->
    %% 扣费
    RoleId = Equip#p_goods.roleid,
    EquipConsume = #r_equip_consume{type = inlay,
                                    consume_type = ?CONSUME_TYPE_SILVER_EQUIP_INLAY,
                                    consume_desc = ""},
    case catch do_refining_deduct_fee(RoleId,Fee,EquipConsume) of
        {error,Error} ->
             db:abort(Error);
        _ ->
            next
    end,
    MatrailBind1 = Stone#p_goods.bind,
    MatrailBind2 = Symbol#p_goods.bind,
    NewEquip = 
        if MatrailBind1 orelse MatrailBind2 ->
                case mod_refining_bind:do_equip_bind_for_inlay(Equip) of
                    {error,ErrorCode} ->
                        ?INFO_MSG("~ts,ErrorCode=~w",["装备镶嵌时，材料是洗炼的，装备不洗炼，洗炼出错，一般洗炼处理",ErrorCode]),
                        Equip#p_goods{bind = true};
                    {ok,BindGoods} ->
                        BindGoods
                end;
           true ->
                Equip
        end,
    {ok, [NewSymbol]} = mod_bag:decrease_goods(Equip#p_goods.roleid,[{Symbol,1}]),
    NewSymbol2 = 
        case NewSymbol of
            undefined ->
                Symbol;
            _ ->
                NewSymbol
        end,
    mod_bag:update_goods(RoleId,[NewEquip]),
    ?DEBUG("~ts,~p",["宝石镶嵌后的详细信息如下",NewEquip]),
    {NewEquip, Stone, NewSymbol2}.

get_inlay_symbol_level(SymbolType) ->
    [List] = common_config_dyn:find(refining,inlay_symbol),
    proplists:get_value(SymbolType, List).

%%装备宝石的拆卸---------------------------------------------------------------------------------------------
do_unload({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_refining_unload_tos{bagid= BagID, equipid=EquipID} = DataIn, 
    R = case mod_refining_bag:get_goods_by_bag_id(RoleID,BagID) of
            [] ->
                do_unload_error(?_LANG_UNLOAD_POS_NOT_5);
            GoodsList when is_list(GoodsList) ->
                do_unload2(GoodsList,EquipID)
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_unload2(GoodsList,EquipID) ->
    ExtractGoods = extract_unload_goods(GoodsList,EquipID),
    ?DEBUG("Goods:~p",[ExtractGoods]),
    case check_unload_goods(ExtractGoods) of
        {ok, CheckGoods} ->
            Data = do_unload3(CheckGoods),
            catch do_unload_use_item_logger(ExtractGoods,Data),
            Data;
        {error,Reason} ->
            do_unload_error(Reason)
    end.
do_unload_use_item_logger(ExtractGoods,Data) ->
    {Symbol,[Equip],_Other} = ExtractGoods,
    RoleId = Equip#p_goods.roleid,
    #m_refining_unload_toc{stones=NewStones} = Data,
    ?DEBUG("~ts,Symbol=~w,NewStones=~w",["宝石拆卸时，记录道具消费日志为",Symbol,NewStones]),
    if Symbol =:= [] ->
            ignore;
       true ->
            [OldGoods] = mod_equip_build:count_class_equip_build_goods(Symbol,[]),
            GoodsNum = 
                if OldGoods#p_equip_build_goods.current_num >= 4 ->
                        4;
                   true ->
                        OldGoods#p_equip_build_goods.current_num
                end,
            %% 道具消费日志
            common_item_logger:log(RoleId,OldGoods#p_equip_build_goods.type_id, 
                                          GoodsNum,
                                   undefined,?LOG_ITEM_TYPE_CHAI_XIE_SHI_QU)
    end,
    lists:foreach(
      fun(Stone) ->
              %% 道具消费日志
              common_item_logger:log(RoleId,Stone#p_goods.typeid, 
                                            Stone#p_goods.current_num,
                                     undefined,?LOG_ITEM_TYPE_CHAI_XIE_HUO_DE)
      end,NewStones).

do_unload3(CheckGoods) ->
    case db:transaction(
           fun() ->
                   t_unload(CheckGoods)
           end)
    of
       {aborted, Reason} ->
            do_unload_error(Reason);
       {atomic,Data} ->
            ?DEV("UNLOAD DATA:~w",[Data]),
            {Equip, _SymbolList} = CheckGoods,
            RoleId = Equip#p_goods.roleid,
            do_refining_deduct_fee_notify(RoleId,{role,RoleId}),
            Data
    end.

do_unload_error(Reason)when is_binary(Reason) ->
    #m_refining_unload_toc{succ=false, reason=Reason};
do_unload_error(Reason) ->
    Desc = 
        case Reason of
            {bag_error,{not_enough_pos,_BagID}} ->
                ?_LANG_UNLOAD_POS_NOT_ENOUGH;
            _ ->
                ?_LANG_UNLOAD_ERROR
        end,
    ?DEBUG("~ts：~w",["装备宝石拆卸错误，原因",Reason]),
    #m_refining_unload_toc{succ=false, reason=Desc}.

extract_unload_goods(GoodsList,EquipID) ->
    F = fun(Goods, {Symbol,Equip,Other}) ->
                ID = Goods#p_goods.id,
                TypeID = Goods#p_goods.typeid,
                if
                    ID =:= EquipID ->
                        {Symbol,[Goods|Equip],Other};
                    TypeID =:= ?REFINING_UNLOAD_SYMBOL ->
                        {[Goods|Symbol],Equip,Other};
                    true ->
                        {Symbol,Equip,[Goods|Other]}
                end
        end,
    lists:foldl(F, {[],[],[]}, GoodsList).

check_unload_goods({Symbol,Equip,[]}) ->
    case Equip of
        [] ->
            {error, ?_LANG_UNLOAD_POS_NOT_5};
        [CEquip] ->
            if CEquip#p_goods.bagposition =/= 5 ->
                    {error, ?_LANG_UNLOAD_POS_NOT_5};
               CEquip#p_goods.stones =:= [] ->
                    {error, ?_LANG_UNLOAD_DO_NOT_UNLOAD};
               erlang:is_list(CEquip#p_goods.stones) ->
                    check_unload_goods2(CEquip, Symbol);
               true  ->
                    {error, ?_LANG_UNLOAD_DO_NOT_UNLOAD}
            end;         
        _ ->
            {error, ?_LANG_UNLOAD_CAN_NOT_MANY_EQUIP}
    end;
check_unload_goods(_) ->
    {error, ?_LANG_UNLOAD_HAS_OTHER}.

check_unload_goods2(Equip, SymbolList) ->
    L = lists:filter(
          fun(Symbol)->
                  Symbol#p_goods.current_num > 1
          end, 
          SymbolList),
    case length(L)+Equip#p_goods.stone_num < 9 of
        true ->
            {ok, {Equip, SymbolList}};
        false ->
            {error, ?_LANG_UNLOAD_POS_NOT_ENOUGH} 
    end.

random_unload(SymbolList)
  when is_list(SymbolList)->
    SNum = lists:foldl(
             fun(Goods,Num)
                   when is_integer(Goods#p_goods.current_num) ->
                     Num + Goods#p_goods.current_num;
                (_,Num) ->
                     Num
             end,0, SymbolList),
    case get_demote_symbol_rate(SNum) of
        undefined ->
            {true,4};
        Reat ->
            {common_tool:random(1,100) < Reat,SNum}
    end.

t_unload({Equip, SymbolList}) ->
    {Tag, Num} = random_unload(SymbolList),
    NewList = 
        if SymbolList =/= [] ->
                [H|_T] = SymbolList,
                {ok,_DelGoodsList,_UpdateGoddsList} = 
                    mod_equip_change:do_transaction_consume_goods(Equip#p_goods.roleid,[?REFINING_BAGID],H#p_goods.typeid,Num),
                mod_refining_bag:get_goods_by_bag_id_and_item_id(Equip#p_goods.roleid,?REFINING_BAGID,H#p_goods.typeid);
           true ->
                []
        end,
    {Deplete, Delete} = t_acc_unload_symbol(SymbolList,NewList),
    Stones = Equip#p_goods.stones,
    t_unload2(Tag, Equip, Deplete, Delete, Stones).
t_unload2(Tag, Equip, Deplete, Delete, Stones) ->
    RefiningFee =#r_refining_fee{type = equip_unload_fee,
                                 equip_level = Equip#p_goods.level,
                                 refining_index = Equip#p_goods.refining_index,
                                 punch_num = Equip#p_goods.punch_num,
                                 stone_num = Equip#p_goods.stone_num,
                                 equip_color = Equip#p_goods.current_colour,
                                 equip_quality = Equip#p_goods.quality},
    case get_refining_fee(RefiningFee) of
        {ok,Fee} ->
            t_unload3(Tag, Equip, Deplete, Delete, Stones, Fee);
        {error,Error} ->
            db:abort(Error)
    end.
t_unload3(Tag, Equip, Deplete, Delete, Stones, Fee) ->
    RoleId = Equip#p_goods.roleid,
    EquipConsume = #r_equip_consume{type = unload,
                                    consume_type = ?CONSUME_TYPE_SILVER_EQUIP_UNLOAD,
                                    consume_desc = ""},
    case catch do_refining_deduct_fee(RoleId,Fee,EquipConsume) of
        {error,Error} ->
            db:abort(Error);
        _ ->
            t_unload4(Tag, Equip, Deplete, Delete, Stones)
    end.

t_unload4(false, Equip, Deplete, Delete, Stones) ->
    {NewEquip,DemoteStone, DeleteStone,Reason} = 
        t_demote_unload_stone(Equip,Stones),
    %% 拆卸时装备存在
    mod_bag:update_goods(NewEquip#p_goods.roleid,NewEquip),
    #m_refining_unload_toc{
               succ=false,
               equip=NewEquip,
               deplete_symbol=Deplete,
               delete_symbol=Delete,
               stones=DemoteStone,
               delete_stones=DeleteStone,
               reason=Reason};
t_unload4(true, Equip,  Deplete, Delete, Stones) ->
    {NewEquip, NewStones} = t_normal_unload_stone(Equip, Stones),
    ?DEV("Equip:~w,NewEquip:~w",[Equip,NewEquip]),
    mod_bag:update_goods(NewEquip#p_goods.roleid,NewEquip),
    #m_refining_unload_toc{
               succ=true,
               equip=NewEquip,
               deplete_symbol=Deplete,
               delete_symbol=Delete,
               stones=NewStones,
               delete_stones=undefined}.

t_acc_unload_symbol(List1,List2) ->
    {Change,Delete,_} = 
        lists:foldl(
          fun(Goods1,{AccChange,AccDelete,[_Goods2|T]}) ->
                  if Goods1 =:= undefined ->
                          {AccChange,[_Goods2|AccDelete],T};
                     true ->
                          {[Goods1|AccChange],AccDelete,T}
                  end
          end,{[],[],List1},List2),
    {Change,Delete}.

-ifdef(TEST).
t_acc_unload_symbol_test() ->
    List1 = [1,2,3,4,5,6,7,8],
    List2 = [1,undefined,3,4,undefined,6,7,undefined],
    ?assert({[1,3,4,6,7],[2,5,7]} = t_acc_unload_symbol(List1,List2)).
-endif.

%%正常拆卸宝石
t_normal_unload_stone(Equip, StoneList) -> 
    ?DEV("EQUIP:~w,StoneList:~w",[Equip, StoneList]),
    InitEquip = Equip#p_goods{stone_num=0,stones=[]},
    F = fun(Stone,{AccEquip,AccStoneList}) ->
                ?DEV("Stone:~wACCEQUIP:~w,AccStoneList:~w",[Stone,AccEquip,AccStoneList]),
                {ok, BaseInfo}= mod_stone:get_stone_baseinfo(Stone#p_goods.typeid),
                NewEquip = t_unload_cut_equip_property(AccEquip,BaseInfo),
                NewStone = Stone#p_goods{
                             embe_pos = 0,
                             embe_equipid = 0,
                             stone_num = 0},
                {ok,[NewStone2]} = mod_bag:create_goods_by_p_goods(AccEquip#p_goods.roleid,?REFINING_BAGID,NewStone),
                ?DEV("NewEquip:~w,List:~w",[NewEquip, [NewStone2|AccStoneList]]),
                {NewEquip, [NewStone2|AccStoneList]}
        end,
    lists:foldl(F, {InitEquip,[]}, StoneList).

%%降级拆卸宝石
t_demote_unload_stone(Equip,StoneList) ->
    ?DEBUG("Stone List:~w",[StoneList]),
    F = fun(Stone,{AccEquip,Demote, Delete,Reason}) ->
                {NewEquip,NewDemote,NewDelete,NewReason} = 
                    t_handle_demote_stone(AccEquip,Stone,Demote,Delete),
                case Delete of
                    [] ->
                        {NewEquip,NewDemote, NewDelete,NewReason};
                    _ ->
                        {NewEquip,NewDemote, NewDelete,Reason}
                end
        end,
    lists:foldl(F, {Equip#p_goods{stones=[],stone_num=0},[],[],""}, StoneList).

t_handle_demote_stone(Equip,Stone,Demote,Delete) ->
    case mod_stone:get_stone_baseinfo(Stone#p_goods.typeid) of
        error ->
            db:abort(?_LANG_SYSTEM_ERROR);
        {ok, BaseInfo} ->
            [StoneLevelLinkList] = common_config_dyn:find(refining,stone_level_link),
            PreTypeId = 
                lists:foldl(
                  fun(SubStoneLevelLinkList,AccPreTypeId) ->
                          case ( AccPreTypeId =:= -1
                                 andalso lists:member(Stone#p_goods.typeid,SubStoneLevelLinkList) ) of
                              true ->
                                  case Stone#p_goods.level - 1 > 0 of
                                      true ->
                                          lists:nth(Stone#p_goods.level - 1,SubStoneLevelLinkList);
                                      false ->
                                          0
                                  end;
                              false->
                                  AccPreTypeId
                          end
                  end,-1,StoneLevelLinkList),
            NewEquip = t_unload_cut_equip_property(Equip,BaseInfo),
            case common_config_dyn:find_stone(PreTypeId) of
                [R] ->
                    {NewEquip,[t_handle_demote_stone2(R,Stone)|Demote],Delete,?_LANG_UNLOAD_STONE_DEMOTE};
                _ ->
                    {NewEquip,Demote,[Stone|Delete],?_LANG_UNLOAD_STONE_DESTROY}
            end
    end.

t_handle_demote_stone2(R, Stone) ->
    #p_stone_base_info{
       typeid = TypeID,
       stonename = Name,
       colour = Colour,
       level_prop = Pro,
       level = Level,
       sell_type = SellType,
       sell_price = SellPrice
    } = R,
    NewStone = Stone#p_goods{
       typeid = TypeID,
       name = Name,
       current_colour = Colour,
       add_property = Pro,
       level = Level,
       sell_type = SellType,
       sell_price = SellPrice              
    },
    {ok,[NewStone2]} = mod_bag:create_goods_by_p_goods(Stone#p_goods.roleid,?REFINING_BAGID,NewStone),
    NewStone2.

t_unload_cut_equip_property(Equip,BaseInfo)
  when is_record(BaseInfo, p_stone_base_info)->
    BasePro = BaseInfo#p_stone_base_info.level_prop,
    t_unload_cut_equip_property2(Equip#p_goods.add_property,BasePro,Equip).

t_unload_cut_equip_property2(Pro, BasePro, Equip) ->
    SeatList =
        case get_main_property_seat(BasePro#p_property_add.main_property) of
            SeatR when is_integer(SeatR) andalso SeatR > 1 ->
                [SeatR];
            SeatR when is_list(SeatR) ->
                SeatR;
            _ ->
                db:abort(?_LANG_INLAY_STONE_NOT_CAN_INLAY)
        end,
    NewPro = lists:foldl(
               fun(Seat,AccPro) ->
                       R = erlang:element(Seat, AccPro)-erlang:element(Seat,BasePro),
                       erlang:setelement(Seat, AccPro, R)
               end,Pro,SeatList),
    Equip#p_goods{add_property = NewPro}.

get_demote_symbol_rate(Num) ->
    [List] = common_config_dyn:find(refining,random_rate_symbol),
    proplists:get_value(Num, List).

%%---------------------------------------------------------------------------------
get_main_property_seat(Main) ->
    [List] = common_config_dyn:find(refining,main_property),
    R = proplists:get_value(Main, List),
    ?DEBUG("Main:~w Sate:~w",[Main, R]),
    R.


%%装备通过颜色与品质属性加成-------------------------------------------------------------------------------------------y
%%GoodsType : new 新增装备，mod 改造装备
equip_colour_quality_add(GoodsType,Goods,NewColour,NewQuality,NewSubQuality)
  when Goods#p_goods.type =:= 3 ->
    case mod_equip:get_equip_baseinfo(Goods#p_goods.typeid) of
        error ->
            error;
        {ok, BaseInfo} ->
            equip_colour_quality_add2(GoodsType,Goods,BaseInfo,NewColour,NewQuality,NewSubQuality)
    end;
equip_colour_quality_add(_GoodsType,Goods,_NewColour,_NewQuality,_NewSubQuality) ->
    Goods.

equip_colour_quality_add2(GoodsType,Goods,BaseInfo,_DelNewColour,NewQuality,NewSubQuality) ->
    Pro = Goods#p_goods.add_property,
    BasePro = BaseInfo#p_equip_base_info.property,
    case GoodsType of 
        new ->
            %%Colour = Goods#p_goods.current_colour,
            Colour = mod_refining_tool:get_equip_color_by_quality(Goods#p_goods.quality,Goods#p_goods.sub_quality),
            Quality = Goods#p_goods.quality,
            SubQuality =  Goods#p_goods.sub_quality,
            {ok, ColourProbability, QualityProbability} = get_colour_quality(Colour,Quality,SubQuality),
            NewPro1 = add_property(BasePro#p_property_add.main_property,Pro,BasePro,ColourProbability,QualityProbability,add),
            Goods#p_goods{add_property=NewPro1,current_colour = Colour, quality = Quality,
                          sub_quality = SubQuality,quality_rate = QualityProbability};
        _ ->
            OldColour = mod_refining_tool:get_equip_color_by_quality(Goods#p_goods.quality,Goods#p_goods.sub_quality),
            OldQuality = Goods#p_goods.quality,
            OldSubQuality = Goods#p_goods.sub_quality,
            NewColour = mod_refining_tool:get_equip_color_by_quality(NewQuality,NewSubQuality),
            {ok, OldColourProbability, OldQualityProbability} = get_colour_quality(OldColour,OldQuality,OldSubQuality),
            {ok, NewColourProbability, NewQualityProbability} = get_colour_quality(NewColour,NewQuality,NewSubQuality),
            ResetPro1 = add_property(BasePro#p_property_add.main_property,Pro,BasePro,OldColourProbability,OldQualityProbability,del),
            NewPro1 = add_property(BasePro#p_property_add.main_property,ResetPro1,BasePro,NewColourProbability,NewQualityProbability,add),
            Goods#p_goods{add_property=NewPro1,current_colour = NewColour, quality = NewQuality,
                          sub_quality = NewSubQuality,quality_rate = NewQualityProbability}
    end.

get_colour_quality(Colour,Quality,SubQuality) ->
    {
      ok,
      get_colour_add_property(Colour),
      get_quality_add_property(Quality,SubQuality)
    }.

get_colour_add_property(Colour) ->
    [List] = common_config_dyn:find(refining,colour_add_property),
    proplists:get_value(Colour, List).

get_quality_add_property(Quality,SubQuality) ->
    [List] = common_config_dyn:find(refining,quality_add_property),
    case lists:foldl(
           fun({Quality2,SubQuality2,QualityProbabilityT},{AccFlag,Acc}) ->
                   case (AccFlag =:= false andalso Quality2 =:= Quality andalso SubQuality2 =:= SubQuality) of
                       true ->
                           {true,QualityProbabilityT};
                       false ->
                           {AccFlag,Acc}
                   end
           end,{false,0},List) of
        {true,QualityProbabilityT} ->
            QualityProbabilityT;
        _ ->
            0
    end.

%% OpType del 删除，add添加
add_property(?REFINING_BLOOD,Pro,BasePro,{_Main,Dodge,DeadAttack,NoDefence},Quality,OpType) ->
    case OpType of 
        add ->
            Pro#p_property_add{
              blood = round(BasePro#p_property_add.blood * (Quality)/10000)+
                  Pro#p_property_add.blood,
              dodge = Dodge + Pro#p_property_add.dodge,
              dead_attack =  DeadAttack + Pro#p_property_add.dead_attack,
              no_defence = NoDefence + Pro#p_property_add.no_defence
             };
        del ->
            Pro#p_property_add{
              blood = Pro#p_property_add.blood - 
                  round(BasePro#p_property_add.blood * (Quality)/10000),
              dodge = Pro#p_property_add.dodge - Dodge,
              dead_attack = Pro#p_property_add.dead_attack - DeadAttack,
              no_defence = Pro#p_property_add.no_defence -NoDefence
             }
    end;
add_property(?REFINING_PHYSIC_ATT,Pro,BasePro,{_Main,Dodge,DeadAttack,NoDefence},Quality,OpType) ->
    Value = round(BasePro#p_property_add.max_physic_att * (Quality)/10000),
    case OpType of 
        add ->
            Pro#p_property_add{
              max_physic_att = Pro#p_property_add.max_physic_att + Value,
              min_physic_att = Pro#p_property_add.min_physic_att + Value,
              dodge = Dodge + Pro#p_property_add.dodge,
              dead_attack = DeadAttack + Pro#p_property_add.dead_attack,
              no_defence = NoDefence + Pro#p_property_add.no_defence
             };
        del ->
            Pro#p_property_add{
              max_physic_att = Pro#p_property_add.max_physic_att - Value,
              min_physic_att = Pro#p_property_add.min_physic_att - Value,
              dodge = Pro#p_property_add.dodge - Dodge,
              dead_attack = Pro#p_property_add.dead_attack - DeadAttack,
              no_defence = Pro#p_property_add.no_defence -NoDefence
             }
    end;
add_property(?REFINING_MAGIC_ATT,Pro,BasePro,{_Main,Dodge,DeadAttack,NoDefence},Quality,OpType) ->
    Value = round(BasePro#p_property_add.max_magic_att * (Quality)/10000),
    case OpType of 
        add ->
            Pro#p_property_add{
              max_magic_att = Pro#p_property_add.max_magic_att + Value,
              min_magic_att = Pro#p_property_add.min_magic_att + Value,
              dodge = Pro#p_property_add.dodge + Dodge,
              dead_attack = Pro#p_property_add.dead_attack + DeadAttack,
              no_defence =Pro#p_property_add.no_defence + NoDefence
             };
        del ->
            Pro#p_property_add{
              max_magic_att = Pro#p_property_add.max_magic_att - Value,
              min_magic_att = Pro#p_property_add.min_magic_att - Value,
              dodge = Pro#p_property_add.dodge - Dodge,
              dead_attack = Pro#p_property_add.dead_attack - DeadAttack,
              no_defence =Pro#p_property_add.no_defence - NoDefence
             }
    end;
add_property(?REFINING_PHYSIC_DEF,Pro,BasePro,{_Main,Dodge,DeadAttack,NoDefence},Quality,OpType) ->
    case OpType of 
        add ->
            Pro#p_property_add{
              physic_def = round(BasePro#p_property_add.physic_def * (Quality)/10000)+
                     Pro#p_property_add.physic_def,
              dodge = Dodge + Pro#p_property_add.dodge,
              dead_attack = DeadAttack + Pro#p_property_add.dead_attack,
              no_defence = NoDefence + Pro#p_property_add.no_defence
             };
        del ->
             Pro#p_property_add{
               physic_def = Pro#p_property_add.physic_def - 
                   round(BasePro#p_property_add.physic_def * (Quality)/10000),
               dodge = Pro#p_property_add.dodge - Dodge,
               dead_attack = Pro#p_property_add.dead_attack - DeadAttack,
               no_defence = Pro#p_property_add.no_defence - NoDefence
             }
    end;
add_property(?REFINING_MAGIC_DEF,Pro,BasePro,{_Main,Dodge,DeadAttack,NoDefence},Quality,OpType) ->
    case OpType of 
        add ->
            Pro#p_property_add{
              magic_def = round(BasePro#p_property_add.magic_def * (Quality)/10000)+
                  Pro#p_property_add.magic_def,
              dodge = Dodge +  Pro#p_property_add.dodge,
              dead_attack = DeadAttack + Pro#p_property_add.dead_attack,
              no_defence = NoDefence + Pro#p_property_add.no_defence
             };
        del ->
            Pro#p_property_add{
              magic_def = Pro#p_property_add.magic_def - 
                  round(BasePro#p_property_add.magic_def * (Quality)/10000),
              dodge = Pro#p_property_add.dodge - Dodge,
              dead_attack = Pro#p_property_add.dead_attack - DeadAttack,
              no_defence = Pro#p_property_add.no_defence - NoDefence
             }
    end.

random(N) ->
    random:uniform(N).


%% 天工炉操作费用处理
%% 参数，RoleId用户Id，Fee 钱币费用，单位文，EquipConsume 消费日志记录 结构为r_equip_consume
%% 返回boolean 是否使用了铜钱 
do_refining_deduct_fee(RoleId,Fee,EquipConsume) ->
    ?DEBUG("~ts,RoleId=~w,Fee=~w,EquipConsume=~w",["操作扣费",RoleId,Fee,EquipConsume]),
    case mod_map_role:get_role_attr(RoleId) of
        {ok,RoleAttr} ->
            SilverBind = RoleAttr#p_role_attr.silver_bind,
            Silver = RoleAttr#p_role_attr.silver,
            if (SilverBind + Silver) < Fee ->
                    erlang:throw({error,?_LANG_REFINING_ENOUGH_MONEY});
               true ->
                    next
            end,
            if SilverBind < Fee ->
                    NewSilver = Silver - (Fee - SilverBind),
                    if NewSilver < 0 ->
                            ?ERROR_MSG("~ts",["角色不够钱币打造"]),
                            erlang:throw({error,?_LANG_REFINING_ENOUGH_MONEY});
                       true ->
                            NewRoleAttr = RoleAttr#p_role_attr{silver_bind=0,silver=NewSilver },
                            mod_map_role:set_role_attr(RoleId,NewRoleAttr),
                            common_consume_logger:use_silver({RoleId, SilverBind, (Fee - SilverBind),
                                                              EquipConsume#r_equip_consume.consume_type,
                                                              EquipConsume#r_equip_consume.consume_desc}),
                            ok
                    end;
               true ->
                    NewSilverBind = SilverBind - Fee,
                    NewRoleAttr = RoleAttr#p_role_attr{silver_bind=NewSilverBind},
                    mod_map_role:set_role_attr(RoleId,NewRoleAttr),
                    common_consume_logger:use_silver({RoleId, Fee, 0,
                                                      EquipConsume#r_equip_consume.consume_type,
                                                      EquipConsume#r_equip_consume.consume_desc}),
                    ok
            end,
			SilverBind > 0;
        {error,Error} ->
            ?ERROR_MSG("~ts,Error=~w",["查询角色有的钱币时出错",Error]),
            erlang:throw({error,?_LANG_REFINING_DEDUCT_FEE_ERROR})
    end.

%% 返回boolean 是否使用了礼券
do_refining_deduct_gold(RoleId,3,Fee,EquipConsume) ->
	case mod_map_role:get_role_attr(RoleId) of
		{ok,RoleAttr} ->
            Gold = RoleAttr#p_role_attr.gold,
            if Gold < Fee ->
                    erlang:throw({error,?_LANG_REFINING_ENOUGH_GOLD});
               true ->
                    next
            end,
			common_consume_logger:use_gold({RoleId, 0, Fee,
											EquipConsume#r_equip_consume.consume_type,
											EquipConsume#r_equip_consume.consume_desc}),
			NewGold = Gold - Fee,
			NewRoleAttr = RoleAttr#p_role_attr{gold=NewGold},
			mod_map_role:set_role_attr(RoleId,NewRoleAttr),
			%% 是否使用了礼券
			true;
		{error,_Error} ->
			erlang:throw({error,?_LANG_REFINING_DEDUCT_FEE_ERROR})
	end;
do_refining_deduct_gold(RoleId, _, Fee,EquipConsume) ->
	case mod_map_role:get_role_attr(RoleId) of
		{ok,RoleAttr} ->
            GoldBind = RoleAttr#p_role_attr.gold_bind,
            Gold = RoleAttr#p_role_attr.gold,
            if (GoldBind + Gold) < Fee ->
                    erlang:throw({error,?_LANG_REFINING_ENOUGH_GOLD});
               true ->
                    next
            end,
            if GoldBind < Fee ->
                    NewGold = Gold - (Fee - GoldBind),
                    if NewGold < 0 ->
                            ?ERROR_MSG("~ts",["角色不够钱币打造"]),
                            erlang:throw({error,?_LANG_REFINING_ENOUGH_GOLD});
                       true ->
                            common_consume_logger:use_gold({RoleId, GoldBind, (Fee - GoldBind),
                                                              EquipConsume#r_equip_consume.consume_type,
                                                              EquipConsume#r_equip_consume.consume_desc}),
                            NewRoleAttr = RoleAttr#p_role_attr{gold_bind=0,gold=NewGold },
                            mod_map_role:set_role_attr(RoleId,NewRoleAttr),
                            ok
                    end;
               true ->
                    common_consume_logger:use_gold({RoleId, Fee, 0,
                                                      EquipConsume#r_equip_consume.consume_type,
                                                      EquipConsume#r_equip_consume.consume_desc}),
                    NewGoldBind = GoldBind - Fee,
                    NewRoleAttr = RoleAttr#p_role_attr{gold_bind=NewGoldBind},
                    mod_map_role:set_role_attr(RoleId,NewRoleAttr),
                    ok
            end,
			%% 是否使用了礼券
			GoldBind > 0;
		{error,_Error} ->
			erlang:throw({error,?_LANG_REFINING_DEDUCT_FEE_ERROR})
	end.



%% 天工炉操作扣费成功的消息通知
%% UnicastArg 可以是下面几种情况
%% {role, RoleId}
%% {line, Line, RoleId}
%% {socket, Line, Socket}
do_refining_deduct_fee_notify(RoleId,UnicastArg) ->
    case mod_map_role:get_role_attr(RoleId) of
        {ok, RoleAttr} ->
            AttrChangeList = [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value = RoleAttr#p_role_attr.silver},
                              #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value = RoleAttr#p_role_attr.silver_bind}],
            common_misc:role_attr_change_notify(UnicastArg,RoleId,AttrChangeList);
        {error ,R} ->
            ?ERROR_MSG("~ts,Reason=~w",["获取角色属性出错，天工炉操作成功之后无法通知前端钱币变化情况",R])
    end.
do_refining_deduct_gold_notify(RoleId,UnicastArg) ->
    case mod_map_role:get_role_attr(RoleId) of
        {ok, RoleAttr} ->
            AttrChangeList = [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value = RoleAttr#p_role_attr.gold},
                              #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value = RoleAttr#p_role_attr.gold_bind}],
            common_misc:role_attr_change_notify(UnicastArg,RoleId,AttrChangeList);
        {error ,R} ->
            ?ERROR_MSG("~ts,Reason=~w",["获取角色属性出错，天工炉操作成功之后无法通知前端元宝变化情况",R])
    end.
%% 获取强化，打孔，合成，镶嵌，拆卸的费用
%% 装备品质改造，更改签名，五行改造，装备升级，装备分解费用
%% 装备费用计算记录
%% type 计逄费用类型,fee_formula费用计算公式
%% equip_level 装备级别 material_level 材料级别 material_number 材料数量 refining_index 精炼系数
%% stone_num 宝石数量 punch_num 装备打孔数 equip_color 装备颜色 equip_quality 装备品质
%% -record(r_refining_fee,{type,fee_formula,equip_level = 1,material_level = 1,material_number = 1,
%%                        refining_index = 1,punch_num = 1,stone_num = 1,equip_color = 1,equip_quality = 1}).
%%锻造操作所需的费用
get_refining_fee(Type,EquipGoods) ->
	get_refining_fee(Type,EquipGoods, 1, 1).

get_refining_fee(Type,EquipGoods, MaterialLevel) ->
	get_refining_fee(Type,EquipGoods, MaterialLevel, 1).

get_refining_fee(Type,EquipGoods, MaterialLevel, MaterialNum) ->
	EquipBaseInfo = 
		case mod_equip:get_equip_baseinfo(EquipGoods#p_goods.typeid) of
			error ->
				erlang:throw({error,?_LANG_SYSTEM_ERROR,0});
			{ok, BaseInfo} ->
				BaseInfo
		end,
	%% 获得装备等级，如没有装备境界，则读取装备的等级限制
	#p_equip_base_info{requirement=Req}=EquipBaseInfo,
	EquipLevel = 
		case Req#p_use_requirement.min_jingjie > 0 of
			true ->
				get_equip_level_by_jingjie(Req#p_use_requirement.min_jingjie);
			false ->
				EquipGoods#p_goods.level
		end,
	RefiningFee =#r_refining_fee{type = Type,
								 equip_level = EquipLevel,
								 material_level = MaterialLevel,
                                 material_number = MaterialNum,
								 refining_index = EquipGoods#p_goods.refining_index,
								 punch_num = format_value(EquipGoods#p_goods.punch_num,1),
								 stone_num = format_value(EquipGoods#p_goods.stone_num,1),
								 equip_color = format_value(EquipGoods#p_goods.current_colour,1),
								 equip_quality = format_value(EquipGoods#p_goods.quality,1)},
	Fee = 
		case get_refining_fee(RefiningFee) of
			{ok,FeeT} ->
				FeeT;
			{error,FeeError} ->
				erlang:throw({error,FeeError,0})
		end,
	Fee.

get_refining_fee(RefiningFee)when erlang:is_record(RefiningFee,r_refining_fee) ->
    #r_refining_fee{type = Type} = RefiningFee,
    case common_config_dyn:find(refining,Type) of
        [FeeFormula] ->
            RefiningFee2 = RefiningFee#r_refining_fee{fee_formula = FeeFormula},
            do_refining_fee_eval(RefiningFee2);
        _ ->
            {error,?_LANG_REFINING_FEE_RULE_ERROR}
    end;
get_refining_fee(RefiningFee) ->
    ?DEBUG("~ts, RefiningFee=~w",["计算费用出错",RefiningFee]),
    {error,?_LANG_REFINING_FEE_RULE_ERROR}.

format_value(Value,DefaultValue) ->
    case erlang:is_integer(Value) andalso Value =:= 0 of 
        true ->
            DefaultValue;
        _ ->
            Value
    end.

do_refining_fee_eval(RefiningFee) ->
    ?DEBUG("~ts,RefiningFee=~w",["计算费用",RefiningFee]),
    case catch do_refining_fee_eval2(RefiningFee) of
        {error,Error} ->
            ?ERROR_MSG("~ts,Error=~w",["计算天工炉操作费用出错",Error]),
            {error,Error};
        {ok,ResultFee} ->
            {ok,ResultFee}
    end.
do_refining_fee_eval2(RefiningFee) ->
    #r_refining_fee{
                     fee_formula = FeeFormula,
                     equip_level = EquipLevel,
                     material_level = MaterialLevel,
                     material_number = MaterialNumber,
                     refining_index = RefiningIndex,
                     punch_num = PunchNum,
                     stone_num = StoneNum,
                     equip_color = EquipColor,
                     equip_quality = EquipQuality} = RefiningFee,
    Tokens = 
    case erl_scan:string(FeeFormula) of
        {ok,TTokens,_Endline} ->
            TTokens;
        ScanError ->
            ?ERROR_MSG("~ts,Error=~w",["计算天工炉操作费用scan出错",ScanError]),
            erlang:throw({error,?_LANG_REFINING_FEE_RULE_ERROR})
    end,
    Exprlist = 
    case erl_parse:parse_exprs(Tokens) of
        {ok, TExprlist} ->
            TExprlist;
        {error, ParseError} ->
            ?ERROR_MSG("~ts,Error=~w",["计算天工炉操作费用parse出错",ParseError]),
            erlang:throw({error,?_LANG_REFINING_FEE_RULE_ERROR})
    end,
    Bindings1 = erl_eval:new_bindings(),
    Bindings2 = erl_eval:add_binding('EquipLevel',EquipLevel,Bindings1),
    Bindings3 = erl_eval:add_binding('MaterialLevel',MaterialLevel,Bindings2),
    Bindings4 = erl_eval:add_binding('MaterialNumber',MaterialNumber,Bindings3),
    Bindings5 = erl_eval:add_binding('RefiningIndex',RefiningIndex,Bindings4),
    Bindings6 = erl_eval:add_binding('PunchNum',PunchNum,Bindings5),
    Bindings7 = erl_eval:add_binding('EquipColor',EquipColor,Bindings6),
    Bindings8 = erl_eval:add_binding('EquipQuality',EquipQuality,Bindings7),
    Bindings9 = erl_eval:add_binding('StoneNum',StoneNum,Bindings8),
    {_,Value,_} = erl_eval:exprs(Exprlist,Bindings9),
    ?DEBUG("~ts,RefiningFee=~w,Value=~w",["根据计算费用的公式计算的结果为",RefiningFee,Value]),
    {ok,common_tool:ceil(Value)}.
    
%% 根据装备的境界要求得出相对应的装备等级，用于计算锻造的费用
get_equip_level_by_jingjie(Jingjie) ->
	case common_config_dyn:find(refining,{equip_jingjie, Jingjie}) of
        [Level] ->
			Level;
        _ ->
            1
	end.

%% 根据强化星级概率配置计算出本次获取的星级是多少
%% 返回 0,1,2,3,4,5,6
get_equip_reinforce_new_grade(Equip,StuffLevel) ->
    case common_config_dyn:find(refining,reinforce_grade_probability) of
        [ReinforceGradeList] ->  
            get_equip_reinforce_new_grade2(Equip,StuffLevel,ReinforceGradeList);
        _ ->
            1
    end.
get_equip_reinforce_new_grade2(Equip,StuffLevel,ReinforceGradeList) ->
    case Equip#p_goods.reinforce_result =:= 0 of
        true ->
            OldLevel = 1,OldGrade = 0;
        _ ->
            OldLevel = Equip#p_goods.reinforce_result div 10,
            OldGrade = Equip#p_goods.reinforce_result rem 10
    end,
    ?DEV("StuffLevel=~w,OldLevel=~w,OldGrade=~w",[StuffLevel,OldLevel,OldGrade]),
    case lists:keyfind({OldLevel,OldGrade},1,ReinforceGradeList) of
        false ->
            1;
        {{OldLevel,OldGrade},GradeList} ->
            get_equip_reinforce_new_grade3(Equip,GradeList)
    end.
get_equip_reinforce_new_grade3(_Equip,GradeList) ->
    Grade = get_random_number(GradeList,0,1),
    if Grade >= 6 ->
            6;
       true ->
            Grade
    end.

%% 根据 [1,2,3,4,5,6] 格式的概率配置
%% 随机计算命中那一个概率
%% SumNumber 为 0 即计算 DataList 的总和为SumNumber
%% 返回计算命中概率的数据下标，如果不有命中即返回 DefaultValue
get_random_number([],_SumNumber,DefaultValue) ->
    DefaultValue;
get_random_number(DataList,SumNumber,DefaultValue) ->
	Length = erlang:length(DataList),
	Sum = 
		if SumNumber =:= 0->
			   lists:sum(DataList);
		   true ->
			   SumNumber
		end,
	case Sum =< 0 of
		true ->
			DefaultValue;
		false ->            
			RandomNumber = random:uniform(Sum),
			LenList = lists:seq(1,Length,1),
			get_random_number2(LenList,DataList,RandomNumber,false, DefaultValue)
	end.

get_random_number2([],_DataList,_RandomNumber,_Flag, Result) ->
    Result;
get_random_number2(_LenList,_DataList,_RandomNumber,true,Result) ->
    Result;
get_random_number2([H|T],DataList,RandomNumber,Flag,Result) ->
    Value = lists:nth(H,DataList),
    V1 = if (H - 1) > 0 ->
                 get_sum_lists_by_index(H - 1,DataList);
            true ->
                 0
         end,
    V2 = get_sum_lists_by_index(H,DataList),
    if Value =/= 0 
       andalso RandomNumber > V1
       andalso RandomNumber =< V2 ->
            get_random_number2(T,DataList,RandomNumber,true,H);
       true ->
            get_random_number2(T,DataList,RandomNumber,Flag,Result)
    end.
get_sum_lists_by_index(Index,DataList) ->
    SubList = lists:sublist(DataList,Index),
    lists:foldl(fun(V,Acc) ->
                        Acc + V
                end,0,SubList).

%%新建装备时，调用这个函数得到随机属性和随机属性值
equip_random_add_property(Equip)when Equip#p_goods.type =:= 3 ->
    [BaseInfo] = common_config_dyn:find_equip(Equip#p_goods.typeid),
    #p_equip_base_info{slot_num=SlotNum,kind=Kind}=BaseInfo,
    RandomList = get_colour_random_add_property({SlotNum,Kind,Equip#p_goods.current_colour}),
    {NewPro,_RandomProList} = add_random_property(RandomList,Equip#p_goods.add_property,[]),
    Equip#p_goods{add_property=NewPro}.%%,
                  %%random_pro_list=lists:append(RandomProList,Equip#p_goods.random_pro_list)}.

get_colour_random_add_property({_SlotNum,_Kind,_Colour}=Key) ->
    [List] = common_config_dyn:find(refining,colour_random_add_property),
    {Max,RandomList} = proplists:get_value(Key,List),
    case length(RandomList) =:= Max of
        true ->
            RandomList;
        false ->
            random_colour_property_list(Max,[],RandomList)
    end.

random_colour_property_list(0,L,_) ->
    L;
random_colour_property_list(Num,L,RandomL) ->
    Sum = lists:foldl(fun({_,R,_},Acc) -> Acc+R end,0,RandomL),
    RandomR = random:uniform(Sum),
    F = fun({_,R,_}=Result,AccR) ->
                if AccR+R < RandomR ->
                        AccR+R;
                   true ->
                        throw({ok,Result})
                end
        end,
    {ok,{Key,_,_}} = {ok,Re} = (catch lists:foldl(F,0,RandomL)),
    random_colour_property_list(Num-1,[Re|L],lists:keydelete(Key,1,RandomL)).

add_random_property([],Property,RandomProList) ->
    {Property,RandomProList};
add_random_property([{power,_,{Min,Max}}|T],Property,RandomProList) ->
    Value = random_property_value(Min,Max),
    NewPower = Property#p_property_add.power+Value,
    add_random_property(T,Property#p_property_add{power = NewPower},
                        [{#p_property_add.power,Value}|RandomProList]);
add_random_property([{agile,_,{Min,Max}}|T],Property,RandomProList) ->
    Value = random_property_value(Min,Max),
    NewAgile = Property#p_property_add.agile+Value,
    add_random_property(T,Property#p_property_add{agile = NewAgile},
                       [{#p_property_add.agile,Value}|RandomProList]);
add_random_property([{brain,_,{Min,Max}}|T],Property,RandomProList) ->
    Value = random_property_value(Min,Max),
    NewBrain = Property#p_property_add.brain+Value,
    add_random_property(T,Property#p_property_add{brain = NewBrain},
                        [{#p_property_add.brain,Value}|RandomProList]);
add_random_property([{spirit,_,{Min,Max}}|T],Property,RandomProList) ->
    Value = random_property_value(Min,Max),
    NewSpirit = Property#p_property_add.spirit+Value,
    add_random_property(T,Property#p_property_add{spirit = NewSpirit},
                        [{#p_property_add.spirit,Value}|RandomProList]);
add_random_property([{vitality,_,{Min,Max}}|T],Property,RandomProList) ->
    Value = random_property_value(Min,Max),
    NewVitality = Property#p_property_add.vitality+Value,
    add_random_property(T,Property#p_property_add{vitality = NewVitality},
                        [{#p_property_add.vitality,Value}|RandomProList]).

random_property_value(Max,Max) ->
    Max;
random_property_value(Min,Max) ->
    RList = lists:seq(1,abs(Max-Min)),
    lists:nth(random:uniform(Max-Min),RList).
