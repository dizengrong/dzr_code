%%%-------------------------------------------------------------------
%%% @author liuwei <>
%%% @copyright (C) 2010, liuwei
%%% @doc
%%%
%%% @end
%%% Created : 11 Nov 2010 by liuwei <>
%%%-------------------------------------------------------------------
-module(mod_email_service).

-include("mgeeweb.hrl").
-define(ETS_FILTER_LIST,ets_filter_list_email).
%% API
-export([
         post/3
        ]).


%%发信
post("/send_email", Req, _DocRoot) ->
    do_send_email(Req);

%%批量发信
post("/send_email_batch", Req, _DocRoot) ->
    do_send_email_batch(Req);

post(Path, Req, DocRoot) ->
    ?ERROR_MSG("~ts : ~w ~w", ["未知的请求", Path, DocRoot]),
    mgeeweb_tool:return_json_error(Req).

do_send_email(Req) ->
    QueryString = Req:parse_post(),
    RoleID = proplists:get_value("role_id", QueryString),
    RoleID1 = common_tool:to_integer(RoleID),
    Content = proplists:get_value("content", QueryString),
    Content1 = base64:decode_to_string(Content),
    Content2 = base64:decode_to_string(Content1),
    Title = proplists:get_value("title", QueryString),
    Title1 = base64:decode_to_string(Title),
    Title2 = base64:decode_to_string(Title1),
    ?DEBUG("base64 Content=~w, Content1=~w, Content2=~w",[Content,Content1,Content2]),
    Info = {gm_personal_letter,Title2,Content2,RoleID1},
    case common_letter:send_letter_package(Info) of
       ok ->
            mgeeweb_tool:return_json_ok(Req);
        _ ->
            mgeeweb_tool:return_json_error(Req)
    end.

get_param_int(Key,QueryString)->
    common_tool:to_integer( proplists:get_value(Key, QueryString) ).

get_param_string(Key, QueryString)->
    proplists:get_value(Key, QueryString).

do_send_email_batch(Req) ->
    QueryString = Req:parse_post(),
    RoleListArg = proplists:get_value("role_list", QueryString), 
    RoleIDList = case RoleListArg of
                     undefined ->
                         Sex = get_param_int("sex",QueryString),
						 
                         Faction = get_param_int("faction",QueryString),
                         StartLevel = get_param_int("start_level",QueryString),
                         EndLevel = get_param_int("end_level",QueryString),
                         FamilyName = get_param_string("family_name",QueryString),
                         SelCmpParam = get_param_string("selected_compare",QueryString),
                         LastStamp = get_param_int("last_stamp",QueryString),
                         Status = get_param_int("status",QueryString),
                         get_role_id_list_by_condition({Sex,Faction,StartLevel,EndLevel,FamilyName,SelCmpParam,LastStamp,Status});
                     _->
                         StrRoleIDList = string:tokens(RoleListArg,","),
                         [common_tool:to_integer(IdR) || IdR <- StrRoleIDList]
                 end,
    Title =  base64:decode_to_string( base64:decode_to_string( proplists:get_value("email_title", QueryString) ) ),
    Text1 = proplists:get_value("email_content", QueryString),
    Text2 = base64:decode_to_string(Text1),
    Content = base64:decode_to_string(Text2),
    if RoleIDList =:=[] orelse RoleIDList =:=all->
           SQL = mod_mysql:get_esql_insert(t_send_batch_result,
                                           [all_count,fail_count,fail_list,log_time,title],
                                           [0,0,"无",common_tool:now(),Title]
                                          ), 
           {ok,_} = mod_mysql:insert(SQL);
       true-> 
           common_letter:send_letter_package({send,Title,RoleIDList,Content,[]})
    end,
    mgeeweb_tool:return_json_ok(Req).

get_role_id_list_by_condition(Condition)->
    {Sex,Faction,StartLevel,EndLevel,FamilyName,SelCmpParam,LastStamp,Status}=Condition,
    MatchHead1 = #p_role_attr{role_id='$1', _='_',level='$2'},
    Guard1 = 
        case SelCmpParam of
            ">"->[{'>','$2',EndLevel}];
            "="->[{'=:=','$2',EndLevel}];
            "<"->[{'<','$2',EndLevel}];
            ">="->[{'>=','$2',EndLevel}];
            "<="->[{'=<','$2',EndLevel}];
            "between"->[{'>=','$2',StartLevel},{'=<','$2',EndLevel}];
            _->[]
        end,
    RoleIDList1 = 
        case Guard1 of
            []->all;
            _->db:dirty_select(db_role_attr_p, [{MatchHead1, Guard1, ['$1']}])
        end,
    MatchHead2 = #p_role_base{role_id='$1', _='_',sex='$2',faction_id='$3',family_name='$4'},
    Guard2_1=
        case Sex of
            0->[];
            _->[{'=:=','$2',Sex}]
        end,
    Guard2_2=
        case Faction of
            0->Guard2_1;
            _->[{'=:=','$3',Faction}|Guard2_1]
        end,
    Guard2=
        case FamilyName of
            []->Guard2_2;
            _->[{'=:=','$4',FamilyName}|Guard2_2]
        end,
    RoleIDList2 = 
        case Guard2 of
            []->all;
            _->db:dirty_select(db_role_base_p, [{MatchHead2, Guard2, ['$1']}])
        end,
    MatchHead3 = #p_role_ext{role_id='$1', _='_',last_login_time='$2'},
    Guard3=
        case LastStamp of
            0->[];
            _->[{'>','$2',LastStamp}]
        end,
    RoleIDList3 = 
        case Guard3 of
            []->all;
            _->db:dirty_select(db_role_ext, [{MatchHead3, Guard3, ['$1']}])
        end,
    
    RoleIDList4 = 
        case Status of
            0->all;
            1->db:dirty_all_keys(?DB_USER_ONLINE)
        end,
    
    List = lists:foldl(fun(RoleIDList,Acc)-> if RoleIDList=:=all->Acc;true->[RoleIDList|Acc] end end, [], [RoleIDList1,RoleIDList2,RoleIDList3,RoleIDList4]),
    RoleIDList5=lists_filter(List),
    RoleIDList5.

lists_filter([])->[];
lists_filter([FList|RList])->
    {SmallList,_SmallCount,RestList} = 
        lists:foldl(fun(TmpRoleIDList,{TmpSmallList,TmpSmallCount,TmpRestList})->
                            TmpCount = length(TmpRoleIDList),
                            if TmpCount=<TmpSmallCount ->{TmpRoleIDList,TmpCount,[TmpSmallList|TmpRestList]};
                               true->{TmpSmallList,TmpSmallCount,[TmpRoleIDList|TmpRestList]}
                            end
                    end, {FList,length(FList),[]}, RList),
    if SmallList=/=[] ->
           ets:new(?ETS_FILTER_LIST, [named_table, set, private]),
           lists:foreach(fun(RoleID)->ets:insert(?ETS_FILTER_LIST,{RoleID,1}) end,SmallList),
           lists:foreach(fun(TmpRoleIDList)-> 
                                 lists:foreach(fun(TmpRoleID)->
                                                       case ets:lookup(?ETS_FILTER_LIST,TmpRoleID) of
                                                           [{_, _}] ->
                                                               ets:update_counter(?ETS_FILTER_LIST,TmpRoleID,{2,1});
                                                           _->ignore
                                                       end
                                               end,TmpRoleIDList)
                         end, RestList),
           MatchHead = {'$1', '$2'},
           Guard = [{'=:=','$2',1+length(RestList)}],
           Result = ['$1'],
           RoleIDList = 
           case ets:select(?ETS_FILTER_LIST,[{MatchHead, Guard, Result}]) of
               '$end_of_table'->[];
               _RoleIDList->_RoleIDList
           end,
           ets:delete(?ETS_FILTER_LIST),
           RoleIDList;
    true->
            []
end.

