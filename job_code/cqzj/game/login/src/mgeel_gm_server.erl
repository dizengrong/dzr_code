%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     专门为GM提供的Global Server
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mgeel_gm_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeel.hrl").

%% API
-export([start/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).
-export([]).

-define(IP_GM,{127,0,0,1}). %%GM注册账号使用的IP地址
-record(state, {}).


%%%===================================================================

start() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).


%% ====================================================================
%% Server functions
%% 		gen_server callbacks
%% ====================================================================
%%--------------------------------------------------------------------
init([]) ->
    ?DEBUG("~w init",[?MODULE]),
    {ok, #state{}}.
    
%%--------------------------------------------------------------------
handle_call(Request, _From, State) ->
    Reply = do_handle_call(Request),
    {reply, Reply, State}.
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.
%%--------------------------------------------------------------------

handle_info(_Info, State) ->
    {noreply, State}.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================


%% ====================================================================
%% Local Functions
%% ====================================================================
do_handle_call({create_gm_role,{AccountName,RoleName,FactionID,Sex,HeadID}})->
    create_gm_role(AccountName,RoleName,FactionID,Sex,HeadID);
do_handle_call(OtherRequest)->
    ?ERROR_MSG("request not match,Request=~w",[OtherRequest]),
    error.


%%@doc 后台创建GM的角色
create_gm_role(AccountName,RoleName,FactionID,Sex,HeadID)->
    BinAccName = common_tool:to_binary(AccountName),
    create_gm_role2(BinAccName,RoleName,FactionID,Sex,HeadID).
create_gm_role2(AccountName,RoleName,FactionID,Sex,HeadID)->
    case check_has_role(AccountName) of
        true->
            #m_role_add_toc{succ=false,reason=?_LANG_ACCOUNT_ALREADY_EXISTS_ROLE};
        _ ->
            HairType = 1,
            HairColor = 1,
            ReqRecord = #m_role_add_tos{role_name=RoleName, sex=Sex, head=HeadID, faction_id=FactionID,
                                        hair_type=HairType, hair_color=HairColor},
            case mgeel_account_server:add_role(true,AccountName,ReqRecord) of
                ok ->
                    #m_role_add_toc{succ=true};
                Error ->
                    #m_role_add_toc{succ=false,reason=Error}
            end
    end.

%%检查该账号是否已存在角色
check_has_role(AccountName)->
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{account_name = AccountName, _='_'}) of
        [] ->
            false;
        _ ->
            true
    end.


