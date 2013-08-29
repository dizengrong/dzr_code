%%%-------------------------------------------------------------------
%%% @author liuwei <>
%%% @copyright (C) 2010, liuwei
%%% @doc
%%%
%%% @end
%%% Created :11 Nov 2010 by liuwei <>
%%%-------------------------------------------------------------------
-module(mod_goods_service).

-include("mgeeweb.hrl").
-define(ETS_FILTER_LIST,ets_filter_list).
%% API
-export([
         post/3,
         create_goods/2,
         do_send_goods_by_letter/3
        ]).

%%POST方式 赠送物品
post("/send_goods/", Req, _DocRoot) ->
    try
        try_do_send_goods(Req,Req:parse_post() )
    catch
        _:Reason->
            ?ERROR_MSG("~w error,Reason=~w,stacktrace=~w",[try_do_send_goods,Reason,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end;
%%POST方式批量 赠送物品
post("/send_goods_batch/", Req, _DocRoot) ->
    try
        try_do_send_goods_batch(Req,Req:parse_post() )
    catch
        _:Reason->
            ?ERROR_MSG("~w error,Reason=~w,stacktrace=~w",[try_do_send_goods_batch,Reason,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end;
post("/send_goods_batch_by_condition/", Req, _DocRoot) ->
    try
        try_do_send_goods_batch_by_condition(Req,Req:parse_post() )
    catch
        _:Reason->
            ?ERROR_MSG("~w error,Reason=~w,stacktrace=~w",[try_do_send_goods_batch_by_condition,Reason,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end;

post(Path, Req, DocRoot) ->
    ?ERROR_MSG("~ts : ~w ~w", ["未知的请求", Path, DocRoot]),
    mgeeweb_tool:return_json_error(Req).


%%GET 方式赠送物品
%% get("/send_goods/", Req, _DocRoot) ->
%%     try_do_send_goods(Req,Req:parse_qs() );
%% get(_Path, Req, _DocRoot) ->
%%     mgeeweb_tool:return_json_error(Req).


try_do_send_goods(Req,QueryString)->
    RoleID = get_param_int("role_id", QueryString),
    RoleName = get_param_string("role_name", QueryString),
    Type = get_param_int("type", QueryString),
    TypeID = get_param_int("typeid", QueryString),
    Number = get_param_int("number", QueryString),
    BindParam = get_param_string("bind", QueryString),
    Color = get_param_int("color", QueryString),
    Quality = get_param_int("quality", QueryString),
    %%Content = get_param_string("content", QueryString),
    StartTime = get_param_int("start_time",QueryString),
    EndTime = get_param_int("end_time",QueryString),
    ItemName = get_param_string("itemname",QueryString),
    do_send_goods(Req,{RoleID,RoleName, Type, TypeID, Number, BindParam, Color, Quality, StartTime,EndTime,ItemName}).
     

try_do_send_goods_batch(Req,QueryString)->
    RoleListArg = proplists:get_value("role_list", QueryString), 
    RoleIDList = case RoleListArg of
                     "all"->
                         mod_user_service:get_all_roleids();
                     _ ->
                         StrRoleIDList = string:tokens(RoleListArg,","),
                         [common_tool:to_integer(IdR) || IdR <- StrRoleIDList]
                 end,
    Type = get_param_int("type", QueryString),
    TypeID = get_param_int("typeid", QueryString),
    Title =  base64:decode_to_string( base64:decode_to_string( proplists:get_value("title", QueryString) ) ),
    Number = get_param_int("number", QueryString),
    BindParam = get_param_string("bind", QueryString),
    Color = get_param_int("color", QueryString),
    Quality = get_param_int("quality", QueryString),
    StartTime = get_param_int("start_time",QueryString),
    EndTime = get_param_int("end_time",QueryString),
    Text1 = proplists:get_value("email_content", QueryString),
    Text2 = base64:decode_to_string(Text1),
    Content = base64:decode_to_string(Text2),
    %%GoodsList = proplists:get_value("email_goods", QueryString),
    
    mgeeweb_tool:return_json([{result,"结果请稍候在“消息管理：发送批量信件/道具结果”中查看"}],Req),
    
    do_send_goods_batch(Req, {RoleIDList, Type, TypeID, Number, BindParam, Color, Quality, Title, Content, StartTime, EndTime}).

try_do_send_goods_batch_by_condition(Req,QueryString)->
    Type = get_param_int("type", QueryString),
    TypeID = get_param_int("typeid", QueryString),
    Title =  base64:decode_to_string( base64:decode_to_string( proplists:get_value("title", QueryString) ) ),
    Number = get_param_int("number", QueryString),
    BindParam = get_param_string("bind", QueryString),
    Color = get_param_int("color", QueryString),
    Quality = get_param_int("quality", QueryString),
    StartTime = get_param_int("start_time",QueryString),
    EndTime = get_param_int("end_time",QueryString),
    Content = base64:decode_to_string( base64:decode_to_string( proplists:get_value("email_content", QueryString) ) ),

    Sex = get_param_int("sex",QueryString),
    Faction = get_param_int("faction",QueryString),
    StartLevel = get_param_int("start_level",QueryString),
    EndLevel = get_param_int("end_level",QueryString),
    StartJingjie = get_param_int("start_jingjie",QueryString),
    EndJingjie = get_param_int("end_jingjie",QueryString),
    StartJuewei = get_param_int("start_juewei",QueryString),
    EndJuewei = get_param_int("end_juewei",QueryString),
    FamilyName = get_param_string("family_name",QueryString),
    SelCmpParam = get_param_string("selected_compare",QueryString),
    SelCmpParamJingjie = get_param_string("selected_compare_jingjie",QueryString),
    SelCmpParamJuewei = get_param_string("selected_compare_juewei",QueryString),
    LastStamp = get_param_int("last_stamp",QueryString),
	
    mgeeweb_tool:return_json([{result,"结果请稍候在“消息管理：发送批量信件/道具结果”中查看"}],Req),
    
    do_send_goods_batch_by_condition(Req,{Type, TypeID, Number, BindParam, Color, Quality, Title, Content, StartTime, EndTime},{Sex,Faction,StartLevel,EndLevel,StartJingjie,EndJingjie,StartJuewei,EndJuewei,FamilyName,SelCmpParam,SelCmpParamJingjie,SelCmpParamJuewei,LastStamp}).

get_param_int(Key,QueryString)->
    common_tool:to_integer( proplists:get_value(Key, QueryString) ).

get_param_string(Key, QueryString)->
    proplists:get_value(Key, QueryString).

%%@doc 按条件批量发送道具
do_send_goods_batch_by_condition(Req,LetterElement,Condition)->
    RoleIDList = get_role_id_list_by_condition(Condition),
    {Type, TypeID, Number, BindParam, Color, Quality, Title, Content, StartTime, EndTime}=LetterElement,
    if RoleIDList =:=[] orelse RoleIDList =:=all->
            SQL = mod_mysql:get_esql_insert(t_send_batch_result,
                                    [all_count,fail_count,fail_list,log_time,title],
                                    [0,0,"无",common_tool:now(),Title]
                                   ), 
            {ok,_} = mod_mysql:insert(SQL);
       true->    
           do_send_goods_batch(Req,{RoleIDList, Type, TypeID, Number, BindParam, Color, Quality, Title, Content, StartTime, EndTime})
    end.

get_role_id_list_by_condition(Condition)->
    {Sex,Faction,StartLevel,EndLevel,StartJingjie,EndJingjie,StartJuewei,EndJuewei,FamilyName,SelCmpParam,SelCmpParamJingjie,SelCmpParamJuewei,LastStamp}=Condition,
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
            _->db:dirty_select(db_role_attr, [{MatchHead1, Guard1, ['$1']}])
        end,
    MatchHeadJingjie = #p_role_attr{role_id='$1', _='_',jingjie='$2'},
	GuardJingjie = 
        case SelCmpParamJingjie of
            ">"->[{'>','$2',EndJingjie}];
            "="->[{'=:=','$2',EndJingjie}];
            "<"->[{'<','$2',EndJingjie}];
            ">="->[{'>=','$2',EndJingjie}];
            "<="->[{'=<','$2',EndJingjie}];
            "between"->[{'>=','$2',StartJingjie},{'=<','$2',EndJingjie}];
            _->[]
        end,
    RoleIDListJingjie = 
        case GuardJingjie of
            []->all;
            _->db:dirty_select(db_role_attr, [{MatchHeadJingjie, GuardJingjie, ['$1']}])
        end,

	MatchHeadJuewei = #p_role_attr{role_id='$1', _='_',juewei='$2'},
	GuardJuewei = 
        case SelCmpParamJuewei of
            ">"->[{'>','$2',EndJuewei}];
            "="->[{'=:=','$2',EndJuewei}];
            "<"->[{'<','$2',EndJuewei}];
            ">="->[{'>=','$2',EndJuewei}];
            "<="->[{'=<','$2',EndJuewei}];
            "between"->[{'>=','$2',StartJuewei},{'=<','$2',EndJuewei}];
            _->[]
        end,
    RoleIDListJuewei = 
        case GuardJuewei of
            []->all;
            _->db:dirty_select(db_role_attr, [{MatchHeadJuewei, GuardJuewei, ['$1']}])
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
            _->db:dirty_select(db_role_base, [{MatchHead2, Guard2, ['$1']}])
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
    List = lists:foldl(
			 fun(RoleIDList,Acc)-> 
					 if RoleIDList=:=all->
							Acc;
						true->
							[RoleIDList|Acc] 
					 end 
			 end, [], [RoleIDList1,RoleIDListJingjie,RoleIDListJuewei,RoleIDList2,RoleIDList3]),
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
           %% ets:match(send_goods, {1+length(RestList),'$1'}),
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


%% filter(RoleIDList1,RoleIDList2)->
%%     if RoleIDList1=:=all andalso RoleIDList2=:=all ->
%%            all;
%%        RoleIDList1=/=all andalso RoleIDList2=:=all ->
%%            RoleIDList1;
%%        RoleIDList1=:=all andalso RoleIDList2=/=all ->
%%            RoleIDList2;
%%        RoleIDList1=/=all andalso RoleIDList2=/=all ->
%%            lists:filter(fun(A)->lists:any(fun(B)->A=:=B end,RoleIDList2) end,RoleIDList1)
%%     end.

%%@doc 批量发送道具
do_send_goods_batch(_Req,{RoleIDList, Type, TypeID, Number, BindParam, Color, Quality, Title, Content, StartTime, EndTime}) ->
    do_send_goods_batch_2(RoleIDList, Type, TypeID, Number, BindParam, Color, Quality, Title, Content, StartTime, EndTime).


do_send_goods_batch_2(RoleIDList, Type, TypeID, Number, BindParam, Color, TmpQuality, Title, Content, StartTime, EndTime) ->
    %% 判断是否为绑定
    Bind = case BindParam of
               "1"-> true;
               _ -> false
           end,
	{Quality,SubQuality} = common_misc:get_equip_quality_by_color(TmpQuality),
    CreateInfo = #r_goods_create_info{bind=Bind, type=Type, bag_id=0, type_id=TypeID, start_time=StartTime,
                                      end_time=EndTime, num=Number, color=Color, quality=Quality, 
									  sub_quality=SubQuality, punch_num=0, rate=0, result=0,
                                      interface_type=present },
    do_send_goods_by_letter_batch(RoleIDList, Title, Content,CreateInfo).


%%@doc 单独发送道具
do_send_goods(Req,{RoleID,RoleName, Type, TypeID, Number, BindParam, Color, Quality, StartTime,EndTime,ItemName}) ->
    case do_send_goods_2({RoleID,RoleName, Type, TypeID, Number,StartTime,EndTime}, BindParam, Color, Quality,ItemName) of
        ok ->
            mgeeweb_tool:return_json_ok(Req);
        _ ->
            mgeeweb_tool:return_json_error(Req)
    end.
do_send_goods_2({RoleID,RoleName, Type, TypeID, Number,StartTime,EndTime}=LogSendInfo, BindParam, Color, TmpQuality,ItemName) ->
    %% 判断是否为绑定
    Bind = case BindParam of
               "1"-> true;
               _ -> false
           end,
    Color1 =  
        case Type of
            ?TYPE_ITEM->
                [BaseInfo]=common_config_dyn:find_item(TypeID),
                BaseInfo#p_item_base_info.colour;
            ?TYPE_STONE->
                [BaseInfo]=common_config_dyn:find_stone(TypeID),
                BaseInfo#p_stone_base_info.colour;
            ?TYPE_EQUIP->
               Color
        end,
	{Quality,SubQuality} = common_misc:get_equip_quality_by_color(TmpQuality),

    Info = #r_goods_create_info{bind=Bind, type=Type, bag_id=0, type_id=TypeID, start_time=StartTime,
                                end_time=EndTime, num=Number, color=Color1, quality=Quality, sub_quality=SubQuality, 
								punch_num=0, rate=0, result=0,interface_type=present },
    
    Content = lists:flatten(io_lib:format("亲爱的[<font color=\"#FFFF00\">~s</font>]:\n      您好！\n      感谢您对我们的支持，系统赠送<font color=\"~s\">【~s】</font>×~w给您，请领取附件。",[RoleName,get_color_code(Color1),ItemName,Number])),
    case db:dirty_read(?DB_ROLE_BASE, RoleID) of
        [] ->
            ?ERROR_MSG("do_send_goods_2 error,RoleID=~w,LogSendInfo=~w",[RoleID,LogSendInfo]),
            {error,not_found};
        [#p_role_base{role_id=RoleID}] ->
            case create_goods(RoleID,Info) of
                {ok,GoodsList}->
                    do_send_goods_by_letter(RoleID,Content,GoodsList),
                    receive 
                        ok ->
                            ok;
                        {error,Reason} ->
                            ?ERROR_MSG("do_send_goods_2 error,RoleID=~w,LogSendInfo=~w",[RoleID,LogSendInfo]),
                            ?ERROR_MSG("do_send_goods_by_letter error,Reason=~w",[Reason]),
                            {error,Reason}
                        after 5000 ->
                            ?ERROR_MSG("do_send_goods_2 error,RoleID=~w,LogSendInfo=~w",[RoleID,LogSendInfo]),
                            ?ERROR_MSG("time out  %%%%%%%%%",[]),
                            {error,timeout}
                    end;
                {error,Reason}->
                    ?ERROR_MSG("create_goods error,Reason=~w",[Reason]),
                    {error,Reason}
            end
    end.

%%@doc 创建作为赠送用途的默认物品
create_goods(RoleID,Info)->
    #r_goods_create_info{bind=Bind, bag_id=BagID, type=Type, type_id=TypeID, start_time=StartTime, end_time=EndTime,
                        num=Num, color=Color, quality=Quality, sub_quality=SubQuality, punch_num=PunchNum, property=Property, rate=Rate, result=Result,
                        result_list=ResultList, interface_type=InterfaceType} = Info,
    case Type of
        ?TYPE_ITEM ->
            Info2 = #r_item_create_info{role_id=RoleID, bag_id=BagID,  num=Num, typeid=TypeID, bind=Bind,
                                        start_time=StartTime, end_time=EndTime, color=Color},
            common_bag2:create_item(Info2);
        ?TYPE_STONE ->
            Info2 = #r_stone_create_info{role_id=RoleID, bag_id=BagID,  num=Num, typeid=TypeID, bind=Bind,
                                          start_time=StartTime, end_time=EndTime},
            common_bag2:creat_stone(Info2);
        ?TYPE_EQUIP ->
            Info2 = #r_equip_create_info{role_id=RoleID, bag_id=BagID,  num=Num, typeid=TypeID, bind=Bind,
                                         start_time=StartTime, end_time=EndTime, color=Color, quality=Quality, sub_quality=SubQuality,
										 punch_num=PunchNum, property=Property, rate=Rate, result=Result, result_list=ResultList, interface_type=InterfaceType},
            common_bag2:creat_equip_without_expand(Info2)
    end.
    

%%@doc 后台通过信件赠送道具
do_send_goods_by_letter(RoleID,Content,GoodsList)->
    %%设置bagid为9999，表示后台赠送
    NewGoodsList = [ G#p_goods{id=1,bagposition=1,bagid=9999}||G<-GoodsList ],
    common_letter:send_letter_package({gm_send_goods,self(),RoleID,Content,NewGoodsList}).

%%@doc 后台通过信件批量赠送道具
do_send_goods_by_letter_batch(RoleIDList,Title, Content,CreateInfo)->
    common_letter:send_letter_package({gm_send_goods_batch, RoleIDList, Title, Content, CreateInfo}).

get_color_code(Color)->
    if Color=:=1->
           "#ffffff";
       Color=:=2->
           "#12cc95";
       Color=:=3->
           "#0d79ff";
       Color=:=4->
           "#fe00e9";
       Color=:=5->
           "#ff7e00";
       Color=:=6->
           "#FFD700";
       true->
           "#ffffff"
    end.
		
		