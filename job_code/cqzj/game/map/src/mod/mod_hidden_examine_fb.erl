%% Author: dizengrong
%% Created: 2012-11-16
%% @doc: 这里实现的是t6项目中检验副本的隐藏关卡

-module (mod_hidden_examine_fb).

-include("mgeem.hrl").

% -compile(export_all).

-export([do_open_hidden_barrier/2, do_enter/1, 
		 check_and_do_finish_hidden_barrier/2,
		 gm_clear_hidden_barrier/1,
		 gm_open_hidden_barrier/2,
		 recalc/2, check_and_do_reset/2]).	

-define(UNICAST(RoleID, Method, Msg), 
		common_misc:unicast2_direct({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, Method, Msg)).

-define(HIDDEN_FB_TYPE_1, 	1). %% 1、宝箱：打开宝箱可以获得道具
-define(HIDDEN_FB_TYPE_2, 	2). %% 2、巢穴：清剿所有小怪获得大量经验
-define(HIDDEN_FB_TYPE_3, 	3). %% 3、挑战：杀死指定boss获得稀有道具
-define(HIDDEN_FB_TYPE_4, 	4). %% 4、增加角色属性：增加角色生命值上限
-define(HIDDEN_FB_TYPE_5, 	5). %% 5、增加金钱：获得大量金砖
-define(HIDDEN_FB_TYPE_6, 	6). %% 6、免费增加一次大富翁
-define(HIDDEN_FB_TYPE_7, 	7). %% 7、免费增加一次神游三界/月光宝盒
-define(HIDDEN_FB_TYPE_8, 	8). %% 8、免费增加一次封神榜
-define(HIDDEN_FB_TYPE_9, 	9). %% 9、消耗道具
-define(HIDDEN_FB_TYPE_10, 	10). %% 10、满星通关的宝箱奖励

-define(ERR_NOT_OPEN, 				"隐藏关卡没有开启").
-define(ERR_ALREADY_FINISHED, 		"隐藏关卡已经完成过了").
-define(ERR_AWARD_ADD_ROLE_ATTR, 	"隐藏关卡奖励添加角色属性失败").

-record(hidden_fb_conf, {
		id, 		%% 隐藏关卡id
		type, 		%% 隐藏关卡类型
		award_data  %% 奖励数据
	}).

check_and_do_reset(RoleID, HiddenExFbRec) ->
	Now = common_tool:now(),
    case common_tool:check_if_same_day(HiddenExFbRec#r_role_hidden_examine_fb.update_time, Now) of
        true -> HiddenExFbRec;
        false ->
            Fun = fun(HiddenId, Acc) ->
                HiddenFbConfRec = cfg_examine_fb:get_hidden_fb(HiddenId),
                case HiddenFbConfRec#hidden_fb_conf.type of
                    ?HIDDEN_FB_TYPE_2 -> Acc;
                    ?HIDDEN_FB_TYPE_3 -> Acc;
                    _ -> [HiddenId | Acc]
                end
            end,
			NewFinishList    = lists:foldl(Fun, [], HiddenExFbRec#r_role_hidden_examine_fb.finish_barriers), 
			NewHiddenExFbRec = HiddenExFbRec#r_role_hidden_examine_fb{
				finish_barriers = NewFinishList,
				update_time     = Now
            },
            mod_examine_fb:set_role_hidden_ex_fb_info(RoleID, NewHiddenExFbRec),
            NewHiddenExFbRec
    end.

%% 处理隐藏关卡的开启
%% BarrierID为已完成的关卡id，这个可以是普通关卡id，也可以是隐藏关卡id
do_open_hidden_barrier(RoleID, BarrierID) ->
	case cfg_examine_fb:get_open_hidden_barriers(BarrierID) of
		[] -> ignore;
		OpenHiddenBarrierIds->
			HiddenFbRec = mod_examine_fb:get_role_hidden_ex_fb_info(RoleID),
			OldOpenIds = HiddenFbRec#r_role_hidden_examine_fb.open_barriers,
			case get_new_open_hidden_ex_fb(RoleID, OldOpenIds, OpenHiddenBarrierIds) of
				[] -> ignore;
				NewIds ->
					HiddenFbRec1 = HiddenFbRec#r_role_hidden_examine_fb{
						open_barriers = OldOpenIds ++ NewIds
					},
					mod_examine_fb:set_role_hidden_ex_fb_info(RoleID, HiddenFbRec1),
					send_hidden_ex_fb_updated_notify(RoleID, HiddenFbRec1)
			end
	end.

gm_open_hidden_barrier(RoleID, HiddenBarrierID) ->
	case catch cfg_examine_fb:get_hidden_fb(HiddenBarrierID) of
		{'EXIT', _} -> "没有该隐藏关卡";
		_ -> 
			HiddenFbRec  = mod_examine_fb:get_role_hidden_ex_fb_info(RoleID),
			OldOpenIds   = HiddenFbRec#r_role_hidden_examine_fb.open_barriers,
			HiddenFbRec1 = HiddenFbRec#r_role_hidden_examine_fb{
				open_barriers = OldOpenIds ++ [HiddenBarrierID]
			},
			mod_examine_fb:set_role_hidden_ex_fb_info(RoleID, HiddenFbRec1),
			send_hidden_ex_fb_updated_notify(RoleID, HiddenFbRec1),
			"开启一个隐藏关卡"
	end.
	
gm_clear_hidden_barrier(RoleID) ->
	HiddenFbRec = #r_role_hidden_examine_fb{
		open_barriers = [],
		finish_barriers = []
	},
	mod_examine_fb:set_role_hidden_ex_fb_info(RoleID, HiddenFbRec),
	send_hidden_ex_fb_updated_notify(RoleID, HiddenFbRec).

send_hidden_ex_fb_updated_notify(RoleID, HiddenFbRec) ->
	Msg = #m_examine_fb_hidden_change_toc{
		opened_list = HiddenFbRec#r_role_hidden_examine_fb.open_barriers,
		finished_list = HiddenFbRec#r_role_hidden_examine_fb.finish_barriers
	},
	?UNICAST(RoleID, ?EXAMINE_FB_HIDDEN_CHANGE, Msg).

get_new_open_hidden_ex_fb(_RoleID, OldOpenIds, OpenHiddenBarrierIds) ->
	Fun = fun(HiddenExFbId, Acc) ->
		case lists:member(HiddenExFbId, OldOpenIds) of
			true -> Acc;
			false -> [HiddenExFbId | Acc]
		end
	end,
	lists:foldl(Fun, [], OpenHiddenBarrierIds).

%% 进入隐藏副本，根据隐藏副本的配置不同，进入的效果可以是直接领取奖励
do_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	HiddenFbRec = mod_examine_fb:get_role_hidden_ex_fb_info(RoleID),
	BarrierId   = DataIn#m_examine_fb_hidden_enter_tos.barrier_id,
	case do_enter_check(RoleID, BarrierId, HiddenFbRec) of
		{error, Reason2, check_mission} ->
			mod_examine_fb:commit_mission(RoleID, BarrierId),
			common_misc:send_common_error(RoleID, 0, Reason2);
		{error, Reason1} ->
			common_misc:send_common_error(RoleID, 0, Reason1);
		true ->
			HiddenFbConfRec = cfg_examine_fb:get_hidden_fb(BarrierId),
			Ret = case HiddenFbConfRec#hidden_fb_conf.type of
				?HIDDEN_FB_TYPE_1 ->
					BoxItemTypeId = HiddenFbConfRec#hidden_fb_conf.award_data,
					do_open_baoxiang(RoleID, BoxItemTypeId, BarrierId);
				?HIDDEN_FB_TYPE_2 -> %% 这种就是理解为再奖励一个普通关卡
					FbBarrierConf = HiddenFbConfRec#hidden_fb_conf.award_data,
					do_enter_fb(RoleID, BarrierId, FbBarrierConf, Unique, Module, Method, PID);
				?HIDDEN_FB_TYPE_3 ->
					FbBarrierConf = HiddenFbConfRec#hidden_fb_conf.award_data,
					do_enter_fb(RoleID, BarrierId, FbBarrierConf, Unique, Module, Method, PID);
				?HIDDEN_FB_TYPE_4 ->
					AttrAddId = HiddenFbConfRec#hidden_fb_conf.award_data,
					do_add_role_attr(RoleID, AttrAddId);
				?HIDDEN_FB_TYPE_5 ->
					AddSilver = HiddenFbConfRec#hidden_fb_conf.award_data,
					do_add_money(RoleID, AddSilver);
				?HIDDEN_FB_TYPE_6 ->
					Times = HiddenFbConfRec#hidden_fb_conf.award_data,
					add_random_mission_chance(RoleID, Times);
				?HIDDEN_FB_TYPE_7 ->
					Times = HiddenFbConfRec#hidden_fb_conf.award_data,
					add_shenyou_times(RoleID, Times);
				?HIDDEN_FB_TYPE_8 ->
					Times = HiddenFbConfRec#hidden_fb_conf.award_data,
					add_fengsheng_times(RoleID, Times);
				?HIDDEN_FB_TYPE_9 ->
					CostItemData = HiddenFbConfRec#hidden_fb_conf.award_data,
					do_cost_item(RoleID, CostItemData);
				?HIDDEN_FB_TYPE_10 ->
					{BoxItemTypeId, BigBarrierID} = HiddenFbConfRec#hidden_fb_conf.award_data,
					do_get_full_star_award(RoleID, BoxItemTypeId, BigBarrierID)
			end,
			% %% 做进入后消耗道具的处理
			% case (Ret == true orelse Ret == ignore) andalso CostData =/= [] of
			% 	true ->
			% 		{NeedItemTypeId, NeedNum} = CostData,
			% 		mod_bag:use_item(RoleID, NeedItemTypeId, NeedNum, ?LOG_ITEM_TYPE_USE_ENTER_HIDDEN_FB);
			% 	false -> ignore
			% end,
			case Ret of
				true ->
					Msg = #m_examine_fb_hidden_enter_toc{
						succ       = true,
						barrier_id = BarrierId
					},
					?UNICAST(RoleID, Method, Msg),
					finish_hidden_barrier(RoleID, BarrierId);
				{error, Reason2} ->
					common_misc:send_common_error(RoleID, 0, Reason2);
				ignore ->
					ignore
			end
	end.

%% 完成一个隐藏关卡BarrierId
finish_hidden_barrier(RoleID, BarrierId) ->
	HiddenFbRec = mod_examine_fb:get_role_hidden_ex_fb_info(RoleID),
	FinishedList = HiddenFbRec#r_role_hidden_examine_fb.finish_barriers,
	HiddenFbRec1 = HiddenFbRec#r_role_hidden_examine_fb{
		finish_barriers = lists:umerge(FinishedList, [BarrierId])
	},
	mod_examine_fb:set_role_hidden_ex_fb_info(RoleID, HiddenFbRec1),
	send_hidden_ex_fb_updated_notify(RoleID, HiddenFbRec1),
	%% 处理完成隐藏关卡时可能会开启的隐藏关卡
	do_open_hidden_barrier(RoleID, BarrierId).

%% 判断是否有之前隐藏关卡开启的普通关卡完成了
%% 如果完成了就可以完成所对应的隐藏关卡了
check_and_do_finish_hidden_barrier(RoleID, BarrierID) ->
	case cfg_examine_fb:examine_to_hidden_barriers(BarrierID) of
		[] -> ignore;
		HiddenBarrierId -> finish_hidden_barrier(RoleID, HiddenBarrierId)
	end.

do_enter_check(_RoleID, BarrierId, HiddenFbRec) ->
	OpenedList       = HiddenFbRec#r_role_hidden_examine_fb.open_barriers,
	FinishedList     = HiddenFbRec#r_role_hidden_examine_fb.finish_barriers,
	IsInOpenedList   = lists:member(BarrierId, OpenedList),
	IsInFinishedList = lists:member(BarrierId, FinishedList),
	%% 隐藏关卡一生只能进一次
	HiddenFbConfRec = cfg_examine_fb:get_hidden_fb(BarrierId),
	if
		IsInOpenedList == false ->
			case HiddenFbConfRec#hidden_fb_conf.type of
				?HIDDEN_FB_TYPE_2 -> {error, <<"未达到开启条件">>};
				?HIDDEN_FB_TYPE_3 -> {error, <<"未达到开启条件">>};
				_ -> {error, <<"未达到领取条件">>}
			end;
		IsInFinishedList == true ->
			case HiddenFbConfRec#hidden_fb_conf.type of
				?HIDDEN_FB_TYPE_2 -> {error, <<"已成功挑战该关卡，不可重复挑战">>, check_mission};
				?HIDDEN_FB_TYPE_3 -> {error, <<"已成功挑战该关卡，不可重复挑战">>, check_mission};
				?HIDDEN_FB_TYPE_9 -> {error, <<"障碍已清除">>};
				_ -> {error, <<"已领取过奖励了">>, check_mission}
			end;
		true -> 
		true
			% case cfg_examine_fb:get_hidden_fb_enter_condition(BarrierId) of
			% 	[] ->
			% 		{true, []};
			% 	{NeedItemTypeId, NeedNum} ->
			% 		case get_item_num(RoleID, NeedItemTypeId) >= NeedNum of
			% 			true ->  {true, {NeedItemTypeId, NeedNum}};
			% 			false -> {error, format_error({item_not_enough, {NeedItemTypeId, NeedNum}})}
			% 		end
			% end
	end.

% get_item_num(RoleID, ItemTypeID) ->
% 	{ok, Num} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, ItemTypeID),
% 	Num.

format_error({item_not_enough, {ItemTypeId, Num}}) ->
	[ItemBaseInfo] = common_config_dyn:find(item, ItemTypeId),
	"需要消耗" ++ integer_to_list(Num) ++ "个<font color=\"#FF0000\">" ++ 
	binary_to_list(ItemBaseInfo#p_item_base_info.itemname) ++ "</font>才能进入此关卡！".

do_open_baoxiang(RoleID, BoxItemTypeId, BarrierID) ->
	CreateInfoList = common_misc:get_items_create_info(RoleID, [{BoxItemTypeId, 1, 1, true}]),
	Fun = fun() -> mod_bag:create_goods(RoleID, CreateInfoList) end,
    case common_transaction:t(Fun) of
    	{aborted, _} ->
    		{error, ?_LANG_EDUCATE_FB_AWARD_BAG_POS};
    	{atomic, {ok, GoodsList}} -> 
    		common_misc:update_goods_notify({role, RoleID}, GoodsList),
    		LogType = ?LOG_ITEM_TYPE_PET_TASK_ROUND_REWARD,
    		common_item_logger:log(RoleID, GoodsList, LogType),

    		mod_examine_fb:commit_mission(RoleID, BarrierID),
    		true
    end.

do_get_full_star_award(RoleID, BoxItemTypeId, BigBarrierID) ->
    case is_full_star(RoleID, BigBarrierID) of
        false -> {error, <<"未达到整章满星通关条件，不能领取">>};
        true ->
            Award = [{BoxItemTypeId, 1, 1, true}],
            case mod_bag:add_items(RoleID, Award, ?LOG_ITEM_TYPE_EXAMINE_FULL_STAR_AWARD) of
                {true, _} -> true;
                {error, Reason2} -> {error, Reason2}
            end
    end. 

is_full_star(RoleID, BigBarrierID) ->
	{ok, RoleExamineFbInfo} = mod_examine_fb:get_role_examine_fb_info(RoleID),
	Fun = fun(BarrierID, IsFullStar) ->
        case lists:keyfind(BarrierID, #p_examine_fb_barrier.barrier_id, RoleExamineFbInfo#r_role_examine_fb.barrier_records) of
        	false -> false;
        	Record ->
        		IsFullStar andalso (Record#p_examine_fb_barrier.star_level >= 3)
       	end
    end,
    IsFullStar1 = lists:foldl(Fun, true, cfg_examine_fb:all_barriers(BigBarrierID)),
    IsFullStar1.

do_enter_fb(RoleID, _BarrierId, FbBarrierConf, Unique, _Module, _Method, PID) ->
	{ok, RoleExamineFbInfo} = mod_examine_fb:get_role_examine_fb_info(RoleID),
	mgeem_map:run(fun() -> mod_examine_fb:do_examine_fb_enter_2(
		Unique, ?EXAMINE_FB, ?EXAMINE_FB_ENTER, RoleID, PID, RoleExamineFbInfo, FbBarrierConf) end),
	%% 这个需要玩家完成所对应的关卡副本，
	%% 然后相关的后续处理会在check_and_do_finish_hidden_barrier里完成
	ignore. 

do_add_role_attr(RoleID, AttrAddId) ->
	HiddenFbRec    = mod_examine_fb:get_role_hidden_ex_fb_info(RoleID),
	AttrIdList     = HiddenFbRec#r_role_hidden_examine_fb.attr_Ids,
	NewHiddenFbRec = HiddenFbRec#r_role_hidden_examine_fb{attr_Ids = [AttrAddId | AttrIdList]},
	mod_examine_fb:set_role_hidden_ex_fb_info(RoleID, NewHiddenFbRec),
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	RoleBase2 = mod_role_attr:calc(RoleBase, '+', cfg_examine_fb:get_attr_award(AttrAddId)),
	mod_role_attr:reload_role_base(RoleBase2),
	true.
	

do_add_money(RoleID, AddSilver) ->
	LogType = ?GAIN_TYPE_SILVER_HIDDEN_FB_AWARD,
	common_bag2:add_money(RoleID, silver_bind, AddSilver, LogType),
	true.

add_fengsheng_times(RoleID, Times) ->
	mod_mirror_rnkm:add_remain_changce(RoleID, Times),
	true.

add_shenyou_times(RoleID, Times) ->
	mod_treasbox:add_silver_open_times(RoleID, Times),
	true.

add_random_mission_chance(RoleID, Times) ->
	mod_random_mission:add_chance(RoleID, Times),
	true.

do_cost_item(RoleID, {NeedItemTypeId, NeedNum}) ->
	case mod_bag:use_item(RoleID, NeedItemTypeId, NeedNum, ?LOG_ITEM_TYPE_USE_ENTER_HIDDEN_FB) of
		ok ->
			true;
		_ ->
			{error, format_error({item_not_enough, {NeedItemTypeId, NeedNum}})}
	end.

recalc(RoleBase, _RoleAttr) ->
	HiddenFbRec = mod_examine_fb:get_role_hidden_ex_fb_info(RoleBase#p_role_base.role_id),
	AttrIdList  = HiddenFbRec#r_role_hidden_examine_fb.attr_Ids,
	NewRoleBase = lists:foldl(fun
		(AttrId, RoleBaseAcc) ->
			mod_role_attr:calc(RoleBaseAcc, '+', cfg_examine_fb:get_attr_award(AttrId))
	end, RoleBase, AttrIdList),
	NewRoleBase.
