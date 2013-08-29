%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :
%%%
%%% Created : 2010-3-27
%%% -------------------------------------------------------------------
-module(mod_equip).

-include("mgeem.hrl").
-include("refining.hrl").

-export([
  handle/1,
  creat_equip/1,
  get_equip_baseinfo/1,
  cut_weapon_type/2,
  get_role_skin_change_info/3
]).

%%
%% API Functions
%%
handle({Unique, Module, Method, DataRecord, RoleID, PID,Line,_State}) ->
    case Method of
        ?EQUIP_LOAD ->
            mod_role_equip:handle({Unique, Module, Method, DataRecord, RoleID, PID, Line});
        ?EQUIP_UNLOAD ->
            mod_role_equip:handle({Unique, Module, Method, DataRecord, RoleID, PID, Line});
        ?EQUIP_LOADED_LIST ->
            do_list(Unique, Module, Method, DataRecord, RoleID, Line);
        ?EQUIP_FIX ->
            mod_equip_endurance:handle({Unique, Module, Method, DataRecord, RoleID, PID, Line});
        ?EQUIP_REINFORCE ->
            mod_qianghua:handle({Unique, Module, Method, DataRecord, RoleID, PID});
        ?EQUIP_UPGRADE ->
            mod_qianghua:handle({Unique, Module, Method, DataRecord, RoleID, PID});
        ?EQUIP_RENEWAL ->
            mod_equip_renewal:handle({Unique, Module, Method, DataRecord, RoleID, PID});
        ?EQUIP_INFO ->
            equip_info({Unique, Module, Method, DataRecord, RoleID, PID});
        ?EQUIP_JINGLIAN ->
            mod_jinglian:jinglian({Unique, Module, Method, DataRecord, RoleID, PID});
        ?EQUIP_JINGLIAN_INFO ->
            mod_jinglian:jinglian_info({Unique, Module, Method, DataRecord, RoleID, PID});
        _ ->
            nil
    end;
handle(GoodsInfo) ->
    ?ERROR_MSG("mod_equip, unknow msg: ~w", [GoodsInfo]).

cut_weapon_type(?PUT_ARM,RoleBase) ->
    RoleBase#p_role_base{weapon_type=0};
cut_weapon_type(_, RoleBase) ->
    RoleBase.

do_list(Unique, Module, Method, DataRecord, RoleID, Line) ->
    #m_equip_loaded_list_tos{roleid = Role} = DataRecord,
    Data = 
        case mod_map_role:get_role_attr(RoleID) of
            {ok, RoleAttr} ->
                EquipList = 
                    case RoleAttr#p_role_attr.equips of
                        Equips when erlang:is_list(Equips) ->
                            Equips;
                        _ ->
                            []
                    end,
                #m_equip_loaded_list_toc{roleid = Role, equips = EquipList};
            _ ->
                #m_equip_loaded_list_toc{roleid = Role, equips = []}
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Data).

equip_info({Unique, Module, Method, DataRecord, RoleID, PID}) ->
    #m_equip_info_tos{type_id_list=TypeIDList,color_list=ColorList,bind_list=BindList} = DataRecord,
    R = #m_equip_info_toc{info_list = lists:foldl(fun
      (N, Acc) ->
        Color = lists:nth(N, ColorList),
        {Quality,SubQuality} = common_misc:get_equip_quality_by_color(Color),
        CreateInfo = #r_equip_create_info{
          role_id     = RoleID,
          num         = 1,
          typeid      = lists:nth(N, TypeIDList),
          bind        = lists:nth(N, BindList),
          color       = Color,
          sub_quality = SubQuality,
          quality     = Quality
        },
        case mod_equip:creat_equip(CreateInfo) of
            {ok,[EquipGoods|_]} ->
                [EquipGoods#p_goods{id=1,bagid=0,bagposition=0}|Acc];
            {error,Reason} ->
                ?ERROR_MSG("equip_info error:RoleID=~w,Reason=~w,DataRecord=~w",[RoleID,Reason,DataRecord]),
                Acc    
        end
  end,[],lists:seq(1, erlang:length(TypeIDList)))},
    ?UNICAST_TOC(R).


%% add by caochuncheng 添加此接口
%% 获取人物新地形象
%% 返回结果 {ok,NewRoleAttr,NewSkin}或者{ok,RoleAttr,undefined}
get_role_skin_change_info(OldAttr, SlotNum, EquipType) 
when erlang:is_record(OldAttr, p_role_attr) ->
    #p_role_attr{skin=OldSkin} = OldAttr,
    case SlotNum of
        ?PUT_ARM ->
            NewSkin = OldSkin#p_skin{weapon=EquipType},
            NewAttr = OldAttr#p_role_attr{skin=NewSkin};
        ?PUT_MOUNT ->
            NewSkin = OldSkin#p_skin{mounts=EquipType},
            NewAttr = OldAttr#p_role_attr{skin=NewSkin};
        ?PUT_FASHION ->
            NewSkin = OldSkin#p_skin{fashion=EquipType},
            NewAttr = OldAttr#p_role_attr{skin=NewSkin};
        _ ->
            NewAttr = OldAttr,
            NewSkin = undefined
    end,
    {ok,NewAttr,NewSkin};

%% 获取人物新地形象
%% 返回结果 {ok,NewRoleAttr,NewSkin}或者{ok,RoleAttr,undefined}
get_role_skin_change_info(Skin, SlotNum, EquipType) ->
    case SlotNum of
        ?PUT_ARM ->
            {ok, Skin#p_skin{weapon=EquipType}};
        ?PUT_MOUNT ->
            {ok, Skin#p_skin{mounts=EquipType}};
        ?PUT_FASHION ->
            {ok, Skin#p_skin{fashion=EquipType,fashion_wing=0}};
        _ ->
            {ok, Skin}
    end.

%%创建物品
creat_equip(CreateInfo) when is_record(CreateInfo,r_equip_create_info) ->
    #r_equip_create_info{
      role_id        = RoleID,
      bag_id         = BagID,
      bagposition    = BagPos,
      num            = Num,
      typeid         = TypeID,
      bind           = Bind,
      start_time     = StartTime,
      end_time       = EndTime,
      color          = Color,
      quality        = Quality,
      % interface_type = InterfaceType,
      property       = Pro,
      rate           = Rate,
      result         = ReinforceResult,
      result_list    = ResultList,
      sub_quality    = SubQuality
    }=CreateInfo,
    case common_config_dyn:find_equip(TypeID) of
        [EquipBaseInfo] ->
            {NewStartTime,NewEndTime} = if 
              StartTime =:= 0 andalso EndTime =/= 0 ->
                {common_tool:now(),common_tool:now()+EndTime};
              true ->
                {StartTime,EndTime}
            end, 
            #p_equip_base_info{
               property   = Prop,
               sell_type  = SellType,
               sell_price = SellPrice, 
               equipname  = Name,
               endurance  = Endurance,
               colour     = InitColor
            } = EquipBaseInfo,
            NewProp = if Pro =:= undefined -> Prop;true -> Pro end,
            NewResultList = if ResultList =:= undefined -> [];true -> ResultList end, 
            NewColour = if Color =:= 0 -> InitColor;true -> Color end,
            %%时装需要取品质和颜色
            case mod_qianghua:can_qianghua(TypeID,?TYPE_EQUIP) of
                true ->
                    {NewQuality,NewSubQuality} = mod_refining_tool:get_equip_quality_by_color(NewColour);
                false ->
                    NewQuality=Quality,NewSubQuality=SubQuality
            end,
            NewUseBind = 1,
            PGoods = #p_goods{
              typeid                = TypeID,
              roleid                = RoleID ,
              bagposition           = BagPos ,
              bind                  = Bind , 
              add_property          = NewProp,
              start_time            = NewStartTime,
              end_time              = NewEndTime, 
              current_colour        = NewColour,
              quality               = NewQuality,
              current_endurance     = Endurance ,
              bagid                 = BagID, 
              type                  = ?TYPE_EQUIP,
              sell_type             = SellType,
              stones                = [], 
              sell_price            = SellPrice,
              name                  = Name,
              loadposition          = 0,
              punch_num             = 0, 
              endurance             = Endurance,
              level                 = (EquipBaseInfo#p_equip_base_info.requirement)#p_use_requirement.min_level,
              reinforce_rate        = Rate,
              reinforce_result      = ReinforceResult,
              reinforce_result_list = NewResultList,
              use_bind              = NewUseBind,
              sub_quality           = NewSubQuality,
              whole_attr            = [],
              equip_bind_attr       = []
            },
            NewPGoods = case cfg_qianghua:get_give_qianghua_level(TypeID) of
                undefined -> 
                    PGoods;
                NewReinforceResult ->
                    {QianghuaEquipInfo,_,_} = 
                        mod_qianghua:reset_equip_bind_attr(PGoods,NewReinforceResult),
                    QianghuaEquipInfo
            end,
            GoodsTmps = common_bag2:hook_create_equip(NewPGoods),
            {ok, lists:duplicate(Num,GoodsTmps#p_goods{current_num=1})};
        [] ->
            db:abort(?_LANG_ITEM_NO_TYPE_EQUIP)
    end.

get_equip_baseinfo(TypeID) ->
    case common_config_dyn:find_equip(TypeID) of
        [BaseInfo] -> 
            {ok,BaseInfo};
        [] ->
            error
    end.

