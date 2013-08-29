%%%-------------------------------------------------------------------
%%% @doc
%%%     家族福利模块
%%%     注意:: 该模块属于mod_family的子模块，只能在mod_family中被调用！
%%% @end
%%% Created : 2012-07-05
%%%-------------------------------------------------------------------
-module(mod_family_welfare).
-include("mgeew.hrl").
-include("mgeew_family.hrl").

-define(WELFARE_GET,			?DEFAULT_UNIQUE, ?FAMILY_WELFARE, ?FAMILY_WELFARE_GET,   #m_family_welfare_get_toc{}).
-define(WELFARE_CHECK(IsGot),	?DEFAULT_UNIQUE, ?FAMILY_WELFARE, ?FAMILY_WELFARE_CHECK, #m_family_welfare_check_toc{is_got=IsGot}).
-define(WELFARE_ERROR(Msg),		?DEFAULT_UNIQUE, ?FAMILY_WELFARE, ?FAMILY_WELFARE_ERROR, #m_family_welfare_error_toc{mesg = Msg}).

%% API
-export([handle_info/1]).

%% ====================================================================
%% API functions
%% ====================================================================
%%领取家族福利
handle_info({_Unique, ?FAMILY_WELFARE, ?FAMILY_WELFARE_GET, _DataIn, RoleID, PID, _Line}) ->
	Date = date(),


	case get({got_welfare_date, RoleID}) of
	Date ->
		common_misc:unicast2(PID, ?WELFARE_ERROR(<<"你今天已经领取了家族福利">>));
	_ ->
		{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
		#p_role_attr{
			level = Level
		} = RoleAttr,
		case Level >= 20 of
			true ->
				State = mod_family:get_state(),
		    	FamilyLevel = State#family_state.family_info#p_family_info.level,
				mgeer_role:absend(RoleID, {mod_map_family, {get_welfare, RoleID, self(), FamilyLevel}}),
				put({got_welfare_date, RoleID}, Date),
				common_misc:unicast2(PID, ?WELFARE_GET);
			false ->
				common_misc:unicast2(PID, ?WELFARE_ERROR(<<"未达到30级,不能领取">>))
		end
	end;

%%检查是否已领取家族福利
handle_info({_Unique, ?FAMILY_WELFARE, ?FAMILY_WELFARE_CHECK, _DataIn, RoleID, PID, _Line}) ->
	IsGot = get({got_welfare_date, RoleID})==date(),
	common_misc:unicast2(PID, ?WELFARE_CHECK(IsGot));

handle_info({get_welfare_error, RoleID}) ->
	erase({got_welfare_date, RoleID}),
	common_misc:unicast({role, RoleID}, ?WELFARE_CHECK(false));

handle_info(_) ->
	ignore.

