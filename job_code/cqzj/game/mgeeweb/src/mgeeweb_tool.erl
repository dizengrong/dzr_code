%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 29 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeeweb_tool).

-include("mgeeweb.hrl").

%% API
-export([
         process_not_run/1,
         json/1,
         now_nanosecond/0,
         get_int_param/2,
         get_atom_param/2,
         get_string_param/2,
         call_nodes/3
        ]).
		
-export([
         return_json/2,
         return_json_ok/1,
         return_json_error/1,
         return_string/2,
         return_xml/2
        ]).
         
-export([transfer_to_json/1,transfer_to_json/2]).

json(List) ->
    lists:flatten(rfc4627:encode({obj, List})).

%%返回XML数据 【不】自动加上xml头
return_xml({no_auto_head, XmlResult}, Req) ->
    Req:ok({"text/xml; charset=utf-8", [{"Server","MCCQ"}],XmlResult});
%%返回XML数据 自动加上xml头
return_xml({auto_head, XmlResult}, Req) ->
	XmlResult2 = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"++XmlResult,
    Req:ok({"text/xml; charset=utf-8", [{"Server","MCCQ"}], XmlResult2}).
	
return_string(StringResult, Req) ->
    Req:ok({"text/html; charset=utf-8", [{"Server","MCCQ"}],StringResult}).
return_json(List, Req) ->
    Result =(catch(common_json2:to_json(List))),
    Req:ok({"text/html; charset=utf-8", [{"Server","MCCQ"}],Result}).

return_json_ok(Req) ->
    List = [{result, ok}],
    return_json(List, Req).

return_json_error(Req) ->
    List = [{result, error}],
    return_json(List, Req).
    

process_not_run(Req) ->
    List = [{result, error}],
    return_json(List, Req).

now_nanosecond() ->
    {A, B, C} = erlang:now(),
    A * 1000000000000 + B*1000000 + C.

%%@doc 获取QueryString中的Int参数值
get_int_param(Key,QueryString)->
    Val = proplists:get_value(Key,QueryString),
    common_tool:to_integer(Val).

%%@doc 获取QueryString中的atom参数值
get_atom_param(Key,QueryString)->
    Val = proplists:get_value(Key,QueryString),
    common_tool:to_atom(Val).

%%@doc 获取QueryString中的string参数值
get_string_param(Key,QueryString)->
    proplists:get_value(Key, QueryString).


%%@doc 对所有的Node进行rpc:call 指定的MFA
call_nodes(Module,Method,Args) when is_atom(Module),is_atom(Method), is_list(Args)->
    Nodes = [node()|nodes()],
    [ rpc:call(Nod, Module, Method, Args) ||Nod<-Nodes ].


%% @doc 将Record转换为json
transfer_to_json(Rec)->
    RecName = erlang:element(1, Rec),
    transfer_to_json(RecName,Rec).


-define(TRANSFER_TO_JSON2(RecName,Rec),
        transfer_to_json(RecName,Rec)->
            FieldVals = get_record_values(Rec),
            do_list_match( record_info(fields,RecName),FieldVals,[])
        ).

%% @doc 这里必须更新所有需要进行转换的record
?TRANSFER_TO_JSON2(r_ban_chat_user,Rec);
?TRANSFER_TO_JSON2(p_goods,Rec);
?TRANSFER_TO_JSON2(p_property_add,Rec);
?TRANSFER_TO_JSON2(p_equip_bind_attr,Rec);
?TRANSFER_TO_JSON2(p_equip_five_ele,Rec);
?TRANSFER_TO_JSON2(p_equip_whole_attr,Rec);
?TRANSFER_TO_JSON2(p_skin,Rec);
?TRANSFER_TO_JSON2(p_role,Rec);
?TRANSFER_TO_JSON2(p_role_base,Rec);
?TRANSFER_TO_JSON2(p_role_fight,Rec);
?TRANSFER_TO_JSON2(p_role_attr,Rec);
?TRANSFER_TO_JSON2(p_role_pos,Rec);
?TRANSFER_TO_JSON2(p_role_ext,Rec);
?TRANSFER_TO_JSON2(p_pos,Rec);
?TRANSFER_TO_JSON2(p_actor_buf,Rec);
?TRANSFER_TO_JSON2(p_family_info,Rec);
?TRANSFER_TO_JSON2(r_family_ext,Rec);
?TRANSFER_TO_JSON2(p_family_member_info,Rec);
?TRANSFER_TO_JSON2(p_family_second_owner,Rec);
?TRANSFER_TO_JSON2(p_family_request,Rec);
?TRANSFER_TO_JSON2(p_family_invite,Rec);
?TRANSFER_TO_JSON2(p_role_pet_bag,Rec);
?TRANSFER_TO_JSON2(p_pet_id_name,Rec);
?TRANSFER_TO_JSON2(p_pet,Rec);
?TRANSFER_TO_JSON2(p_pet_skill,Rec);
?TRANSFER_TO_JSON2(r_role_vip,Rec);
?TRANSFER_TO_JSON2(r_activity_common_award,Rec);
?TRANSFER_TO_JSON2(r_activity_monster_award_one,Rec);
?TRANSFER_TO_JSON2(r_activity_person_ybc_award,Rec);
?TRANSFER_TO_JSON2(r_activity_family_award,Rec);
?TRANSFER_TO_JSON2(r_goods_create_info,Rec);
?TRANSFER_TO_JSON2(p_shop_price, Rec);
?TRANSFER_TO_JSON2(p_shop_currency, Rec);
?TRANSFER_TO_JSON2(r_rebind_role, Rec);
?TRANSFER_TO_JSON2(r_simple_role_detail, Rec);
transfer_to_json(RecName,_Rec) ->
    {error,record_not_defined,RecName}.
   

date_to_string(DateTime)->
    {{Y,M,D},{HH,MM,SS}} = DateTime,
    lists:flatten( io_lib:format("~w-~w-~w ~w:~w:~w",[Y,M,D,HH,MM,SS]) ).

time_to_string(Time)->
    {HH,MM,SS} = Time,
    lists:flatten( io_lib:format("~w:~w:~w",[HH,MM,SS]) ).

%% @doc 对列表的值进行新的配对
do_list_match([],[],Result)->
    lists:reverse(Result);
do_list_match([HName|NameList],[HVal|ValList],Result)->
    Rec = case is_tuple(HVal) of
              true->
                  case HVal of
                      {{Y,M,D},{HH,_MM,_SS}} when is_integer(Y) andalso is_integer(M) 
                                                      andalso is_integer(D) andalso is_integer(HH) ->
                          {HName,date_to_string(HVal)};
                      {HH,MM,SS}when is_integer(HH) andalso is_integer(MM)andalso is_integer(SS)   ->
                          {HName,time_to_string(HVal)};
                      _ ->
                          {HName,transfer_to_json(HVal)}
                  end;
              false-> 
                  case is_list(HVal) andalso length(HVal)>0 of
                      true->
                          do_list_match_2(HName,HVal);
                      false->
                          case HVal of
                              undefined->{HName,""};
                              []-> {HName,""};
                              _ -> {HName,HVal}
                          end
                  end
          end,
    do_list_match(NameList,ValList,[Rec|Result]).

do_list_match_2(HName,HVal)->
    case is_tuple( hd(HVal) ) of
        true->
            SubRecList = [ transfer_to_json(SubRec)||SubRec<- HVal ],
            {HName,SubRecList};
        false->
            case HVal of
                undefined->{HName,""};
                _ -> {HName,HVal}
            end
    end.

%% @doc 获取Record的所有值的列表
get_record_values(Record)->
    [_H | Values] = tuple_to_list(Record),
    Values.



