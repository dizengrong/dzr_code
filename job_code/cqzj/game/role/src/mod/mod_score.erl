%% Author: dizengrong
%% Created: 2012-12-27
%% @doc: 这里实现的是t6项目中的积分兑换模块

-module (mod_score).
-include("mgeer.hrl").

%% export for role_misc callback
-export([init/2, delete/1]).

-export([handle/1, gain_score_notify/3, gain_score_notify/4, 
		 decrease_score_without_check/3,decrease_score_without_check/6]).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SCORE, Method, Msg)).

init(RoleID, ScoreRec) ->
	case is_record(ScoreRec, p_score) of
		false ->
			ScoreRec1 = #p_score{};
		_ ->
			ScoreRec1 = ScoreRec
	end,
	mod_role_tab:put(RoleID, ?ROLE_SCORE, ScoreRec1).

delete(RoleID) ->
	mod_role_tab:erase(RoleID, ?ROLE_SCORE).

%% 其他功能模块调用这个来增加积分
gain_score_notify(RoleID, ScoreType,LogType) ->
	gain_score_notify(RoleID, 1, ScoreType,LogType).
gain_score_notify(RoleID, AddScore, ScoreType,LogType) ->
	ScoreRec   = mod_role_tab:get(RoleID, ?ROLE_SCORE),
	FieldIndex = score_field_index(ScoreType),
	Score      = erlang:element(FieldIndex, ScoreRec),
	ScoreRec1  = erlang:setelement(FieldIndex, ScoreRec, Score + AddScore),
	case LogType of
		{LgType,Detail} ->
			do_log_score(RoleID,1,-AddScore,Score + AddScore,LgType,Detail,[]);
		_ ->
			do_log_score(RoleID,1,-AddScore,Score + AddScore,LogType,"",[])
	end,
	mod_role_tab:put(RoleID, ?ROLE_SCORE, ScoreRec1),
	send_score_info_to_client(RoleID, ScoreRec1).

decrease_score_without_check(RoleID, MinusScore, ScoreType) ->
	{ok,ScoreRec1} = decrease_score(RoleID, MinusScore, ScoreType),
	send_score_info_to_client(RoleID, ScoreRec1).

decrease_score(RoleID, MinusScore, ScoreType) ->
	ScoreRec   = mod_role_tab:get(RoleID, ?ROLE_SCORE),
	FieldIndex = score_field_index(ScoreType),
	Score      = erlang:element(FieldIndex, ScoreRec),
	ScoreRec1  = erlang:setelement(FieldIndex, ScoreRec, Score - MinusScore),
	mod_role_tab:put(RoleID, ?ROLE_SCORE, ScoreRec1),
	{ok,ScoreRec1}.

decrease_score_without_check(RoleID, SingleDeductNum, Amount, ScoreType,LogType,ItemList) ->
	MinusScore = SingleDeductNum*Amount,
	{ok,ScoreRec} = decrease_score(RoleID, MinusScore, ScoreType),
	FieldIndex = score_field_index(ScoreType),
	RemainScore      = erlang:element(FieldIndex, ScoreRec),
	case LogType of
		{LgType,Detail} ->
			do_log_score(RoleID,SingleDeductNum,Amount,RemainScore,LgType,Detail,ItemList);
		_ ->
			do_log_score(RoleID,SingleDeductNum,Amount,RemainScore,LogType,"",ItemList)
	end,
	send_score_info_to_client(RoleID, ScoreRec).
		
	

handle({_Unique, _Module, ?SCORE_INFO, _DataIn, RoleID, _PID, _Line}) ->
	ScoreRec = mod_role_tab:get(RoleID, ?ROLE_SCORE),
	send_score_info_to_client(RoleID, ScoreRec).

send_score_info_to_client(RoleID, ScoreRec) ->
	Msg = #m_score_info_toc{data = ScoreRec},
	?MOD_UNICAST(RoleID, ?SCORE_INFO, Msg).

	
do_log_score(RoleID,SingleDeductNum, Amount,RemainScore,Optye,Detail,ItemList)->
	UseScore = SingleDeductNum*Amount,
	PropList = lists:foldl(fun(#r_simple_prop{prop_id=PropID,prop_type=PropType,prop_num=_PropNum},AccIn) ->
								   [[{prop_id,PropID},{prop_type,PropType},{prop_num,Amount}]|AccIn]
						   end, [], ItemList),
	PropJson = common_json2:to_json(PropList),
	{ok,#p_role_attr{role_id=RoleID,role_name=RoleName}} = mod_map_role:get_role_attr(RoleID),
	ScoreUseRecord = #r_score_use_log{
									  role_id   = RoleID,
									  role_name = RoleName,
									  use_score  = UseScore,
									  remain_score = RemainScore,
									  item_info = PropJson,
									  type  = Optye,
									  detail      = Detail,
									  time      = common_tool:now()
									 },
	common_general_log_server:log_use_score(ScoreUseRecord).

score_field_index(?SCORE_TYPE_XUNBAO) 	-> #p_score.xunbao;
score_field_index(?SCORE_TYPE_YUEGUANG) -> #p_score.yueguang;
score_field_index(?SCORE_TYPE_JINGJI) 	-> #p_score.jingji;
score_field_index(?SCORE_TYPE_DADAN) 	-> #p_score.dadan;
score_field_index(?SCORE_TYPE_GUARD) 	-> #p_score.guard.
