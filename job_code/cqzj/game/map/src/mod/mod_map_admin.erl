% Author: liuwei
%% Created: 2010-5-13
%% Description: TODO: Add description to mod_goods
-module(mod_map_admin).

-include("mgeem.hrl").


-export([
         handle/2
        ]).

%%========================API  FUNCTION========================
%%@doc后台赠送道具
%%  该方法目前只支持在线赠送，已废除
handle({send_goods, Pid, Data},_State) ->
    Reply = do_gift(Data),
    Pid ! Reply.
      


%%======================LOCAL FUNCTION=========================
do_gift(Data) ->
    {RoleID,TypeID,Type, Num,Bind, EndTime,Qua,Color,Hole,RateList,_RoleName} = Data,
    ?ERROR_MSG("Type:~w,TypeID:~w~n",[Type,TypeID]),
    CreateInfo = #r_goods_create_info{bind=Bind,type=Type, type_id=TypeID, start_time=common_tool:now(), 
                                      end_time=EndTime, num=Num, color=Color,quality=Qua,
                                      punch_num=Hole,interface_type=present},
    NewCreateInfo = 
        if Type =:= ?TYPE_EQUIP ->
                [ReinforceRateList] = common_config_dyn:find(refining,reinforce_rate),
                [BaseInfo] = common_config_dyn:find_equip(TypeID),
                BasePro = BaseInfo#p_equip_base_info.property,
                MainP = BasePro#p_property_add.main_property,
                {_,List,Max} =
                    lists:foldl(
                      fun(R,{AccNum,AccList,_AccMax})
                            when R > 0 ->
                              {AccNum+1,[AccNum*10+R|AccList],AccNum*10+R};
                         (_,{AccNum,AccList,AccMax})->
                              {AccNum+1,AccList,AccMax}
                      end,{1,[],0},RateList), 
                ReinforceLevel = Max div 10,
                ReinforceGrade = Max rem 10,
                {_,ReinforceGradeRate} = lists:keyfind({ReinforceLevel,ReinforceGrade},1,ReinforceRateList),
                CreateInfo#r_goods_create_info{
                  property=mod_refining:change_main_property(MainP,#p_property_add{_ = 0},BasePro,0,ReinforceGradeRate),
                  rate=ReinforceGradeRate,result=Max,result_list=List};
           true ->
                CreateInfo
        end,
    case db:transaction(fun() -> mod_bag:create_goods(RoleID,NewCreateInfo) end) of
        {atomic, GoodsList} ->
            common_misc:new_goods_notify({role, RoleID},GoodsList),
            ok;
        {aborted, Reason}when is_binary(Reason) ->
            {error,Reason};
        {aborted, Reason} ->
            ?ERROR_MSG("=====Gift Goods Error:~w~n=====",[Reason]),
            {error,?_LANG_SYSTEM_ERROR}
    end.

    
