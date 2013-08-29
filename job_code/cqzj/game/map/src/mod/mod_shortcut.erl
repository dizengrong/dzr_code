%%% -------------------------------------------------------------------
%%% Author  : Luo.JCheng
%%% Description :
%%%
%%% Created : 2010-7-9
%%% -------------------------------------------------------------------
-module(mod_shortcut).

-include("mgeem.hrl").

-export([handle/1,handle/2, shortcut_init/3]).

-export([
         set_role_shortcut_bar/2,
         get_role_shortcut_bar/1,
         erase_role_shortcut_bar/1]).

-define(role_shortcut_bar, role_shortcut_bar).

%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle({Unique, ?SHORTCUT, ?SHORTCUT_UPDATE=Method, DataIn, RoleID, _PID, Line})->
    do_update(Unique, ?SHORTCUT, Method,DataIn, RoleID, Line);
handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

%% @doc 获取角色快捷栏

get_role_shortcut_bar(RoleId) ->
    erlang:get({?role_shortcut_bar, RoleId}).

set_role_shortcut_bar(RoleId, Shortcut) ->
    erlang:put({?role_shortcut_bar, RoleId}, Shortcut).

erase_role_shortcut_bar(RoleId) ->
    erlang:erase({?role_shortcut_bar, RoleId}).

%%初始化快捷栏。。。
shortcut_init(RoleID, Category, Client) ->
	case get_role_shortcut_bar(RoleID) of
		undefined ->
			Selected = if 
				Category == 1; Category == 2 ->
					1;
				true ->
					3
			end,
			ShortcutList = [#p_shortcut{type=1,id=Selected,name=""}
				|[#p_shortcut{type=0,id=0,name=""}||_<-lists:seq(1, 7)]];
		ShortcutInfo ->
			#r_shortcut_bar{shortcut_list=ShortcutList, selected=Selected} = ShortcutInfo
	end,
	DataRecord = #m_shortcut_init_toc{shortcut_list=ShortcutList, selected=Selected},
	common_misc:unicast2(Client, ?DEFAULT_UNIQUE, ?SHORTCUT, ?SHORTCUT_INIT, DataRecord).

%%快捷栏更新
do_update(_Unique, _Module, _Method, DataIn, RoleID, _Line) ->
    #m_shortcut_update_tos{shortcut_list=ShortcutList, selected=Selected} = DataIn,
    case if_illegal(ShortcutList) of
        true ->
            ShortcutInfo = #r_shortcut_bar{roleid=RoleID, shortcut_list=ShortcutList, selected=Selected},
            set_role_shortcut_bar(RoleID, ShortcutInfo);
        false ->
            ok
    end.      

if_illegal(ShortcutList) ->
    lists:all(
      fun(Shortcut) ->
              is_record(Shortcut, p_shortcut)
      end, ShortcutList).
