%%%-------------------------------------------------------------------
%%% @author  Liangliang <Liangliang@gmail.com>
%%% @doc 处理玩家发出的摆摊请求，该模块只能被mgeem_map调用！！
%%%
%%% @end
%%% Created :  1 Jun 2010 by  <Liangliang@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_map_stall).

-include("mgeem.hrl").

%% API
-export([
         handle_info/1
        ]).

-export([
         if_pos_can_stall/3,
         check_point/2,
         add_doll/3,
         remove_doll/1,
         update_doll/4,
         cancel_doll/2
        ]).


%%亲自摆摊模式
-define(STALL_MODE_SELF, 0).
%%托管摆摊模式
-define(STALL_MODE_AUTO, 1).
-define(doll,doll).

%%%===================================================================
%%% 一个格子上是否有摊位 get({doll, {TX, TY}} -> sure 有摊位
%%                                             mark 打了标志
%%%===================================================================


%%%===================================================================
%%% API
%%%===================================================================

handle_info({stall_sure, TX, TY, RoleID, RoleName, Name, Mode}) ->
    do_stall_sure(TX, TY, RoleID, RoleName, Name, Mode);
%%RB用于广播给其他玩家
handle_info({stall_finish, TX, TY, RoleID, RoleName, Name, Mode, RB}) ->
    do_stall_finish(TX, TY, RoleID, RoleName, Name, Mode, RB);
handle_info({stall_update, TX, TY, RoleID, RoleName, Mode, Name, OldMode}) ->
    do_stall_update(TX, TY, RoleID, RoleName, Mode, Name, OldMode).

%%目前只有摆摊模式的更新
do_stall_update(TX, TY, RoleID, RoleName, Mode, Name, OldMode) ->
    Pos = #p_pos{tx = TX, ty = TY},
    OldStall = #p_map_doll{role_id = RoleID, role_name = RoleName, doll_name = Name, doll_type=?DOLL_TYPE_STALL, mode = OldMode, pos = Pos},
    case OldMode of
        ?STALL_MODE_AUTO ->
            Stall2 = OldStall;
        _ ->
            Stall2 = OldStall#p_map_doll{mode = Mode}
    end,
    update_doll(TX, TY, OldStall,Stall2),
    
    R = #m_stall_request_toc{return_self=false, stall_info=Stall2},
    mgeem_map:do_broadcast_insence([{role, RoleID}], ?STALL, ?STALL_REQUEST, R, mgeem_map:get_state()).

%%摆摊成功后，将摊位的简介信息写入到进程字典中去
do_stall_sure(TX, TY, RoleID, RoleName, Name, Mode) ->
    %%打上标记，进行广播，加入到某个slice里面去
    Pos = #p_pos{tx=TX, ty=TY},
    Stall = #p_map_doll{role_id=RoleID, role_name=RoleName, doll_name=Name, doll_type=?DOLL_TYPE_STALL, mode=Mode, pos=Pos},
    add_doll(TX,TY,Stall),
     
    %%需要广播通知
    R = #m_stall_request_toc{return_self=false, stall_info=Stall},
    mgeem_map:do_broadcast_insence([{role, RoleID}], ?STALL, ?STALL_REQUEST, R, mgeem_map:get_state()),
    ok.


%%摆摊结束后，应该清理掉摊位信息，将之前的标记也去掉
do_stall_finish(TX, TY, RoleID, RoleName, Name, Mode, RB) ->
    %%?DEV("~ts", ["玩家摊位结束"]),
    Pos = #p_pos{tx=TX, ty=TY},
    Stall = #p_map_doll{role_id=RoleID, role_name=RoleName, doll_name=Name, doll_type=?DOLL_TYPE_STALL, mode=Mode, pos=Pos},
    remove_doll(Stall),
    
    %RegName = lists:concat([mgeew_role_, RoleID]),
    mgeem_map:do_broadcast_insence_by_txty(TX, TY, ?STALL, ?STALL_FINISH, RB, mgeem_map:get_state()).

%%%%@doc  木偶对象的一些操作方法
add_doll(TX,TY,NewStall)->    
    put({?doll, {TX, TY}}, sure),
    mgeem_map:add_slice_doll(TX, TY, NewStall),
    ok.

remove_doll(OldStall)->
    #p_map_doll{pos=#p_pos{tx=TX, ty=TY}} = OldStall,
    erase({?doll, {TX, TY}}),
    mgeem_map:remove_slice_doll(TX, TY, OldStall),
    ok.

update_doll(TX, TY, OldStall,NewStall)->
    mgeem_map:remove_slice_doll(TX, TY, OldStall),
    mgeem_map:add_slice_doll(TX, TY, NewStall),
    ok.


%%@doc 清理掉之前打上的标记
cancel_doll(TX, TY)->
    erase({?doll, {TX, TY}}).

%%@doc 检查某个点是否有摊位或者摊位标志
check_point(X, Y) ->
    case get({?doll, {X, Y}}) of
        undefined ->
            false;
        _ ->
            true
    end.

%%@doc 检查当前点能否摆摊
if_pos_can_stall(MapID, TX, TY) ->
	lists:member({TX, TY}, mcm:stall_tiles(MapID)).

