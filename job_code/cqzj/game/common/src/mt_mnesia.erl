%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     运维瑞士军刀，for mnesia
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mt_mnesia).

%%
%% Include files
%%
-include("mnesia.hrl").
-include("all_pb.hrl").

-compile(export_all).
-define( DEBUG(F,D),io:format(F, D) ).
-define(ERROR_MSG(Format, Args),
        common_logger:error_msg( node(), ?MODULE,?LINE,Format, Args)).

%%
%% Exported Functions
%%
-export([]).
-export([show_tables/0,show_tables_notempty/0]).
-export([show_table/1,show_schema/1,show_schema/0]).

%%
%% API Functions
%%
-define(DEFAULT_DATA_DIR,"/data/").

%%@doc 将mneisa表的数据转存到DETS表中
dump_to_dets()->
    TabList = [?DB_ROLE_EXT_P,?DB_ROLE_BAG_P],
    [ dump_to_dets(Tab)||Tab<-TabList ].

dump_to_dets(SourceTab)->
    dump_to_dets(SourceTab,"/data/").

dump_to_dets(SourceTab,DirPath) ->
    dump_to_dets(SourceTab,to_dets_name(SourceTab),DirPath).

dump_to_dets(SourceTab,DetsName,DirPath) ->
    dump_to_dets(SourceTab,DetsName,DirPath,2).
dump_to_dets(SourceTab,DetsName,DirPath,KeyPos) when is_atom(SourceTab),is_atom(DetsName),is_integer(KeyPos)->
    FileName = DirPath ++ DetsName,
    Pattern = get_whole_table_match_pattern(SourceTab),
    RecList = mnesia:dirty_match_object(SourceTab, Pattern),
    dets:open_file(DetsName, [{file,FileName},{type,set},{keypos, KeyPos}]),
    [ dets:insert(DetsName, Rec) ||Rec<- RecList],  
    dets:close(DetsName),
    ok.

to_dets_name(SourceTab) when is_atom(SourceTab)->
    erlang:list_to_atom( lists:concat([ets,"_",SourceTab]) ).

%%@doc 显示DETS表的数据
show_dets(SourceTab)->
    show_dets("/data/"++to_dets_name(SourceTab),SourceTab).
show_dets(FileName,SourceTab) when is_atom(SourceTab)->
    Pattern = get_whole_table_match_pattern(SourceTab),
    {ok,DetsName} = dets:open_file(FileName),
    RecList = dets:match_object(DetsName, Pattern),
    dets:close(DetsName),
    {ok,RecList}.

%%@doc 修复个别玩家DB_ROLE_EXT表丢失数据的问题
fix_db_role_ext()->
    AllRoleIDList = get_all_role_id_list(role_attr),
    [ fix_db_role_ext_2(RoleID)||RoleID<-AllRoleIDList ],
    ok.
fix_db_role_ext_2(RoleID)->
    case db:dirty_read(?DB_ROLE_ATTR_P,RoleID) of
        [#p_role_attr{role_name=RoleName}]->
            case db:dirty_read(?DB_ROLE_EXT_P,RoleID) of
                [_RoleExt]->
                    ignore;
                []->
                    ?ERROR_MSG("RoleID=~w",[RoleID]),
                    Now = common_tool:now(),
                    RoleExt = #p_role_ext{role_id=RoleID,last_login_time=Now,last_offline_time=Now,role_name=RoleName ,sex=1},
                    db:dirty_write(?DB_ROLE_EXT,RoleExt),
                    db:dirty_write(?DB_ROLE_EXT_P,RoleExt)
            end;
        []->
            ignore
    end.


%%@doc 修复有问题的Mnesia表
fix_bad_tabs()->
    fix_bad_tabs([?DB_ROLE_EXT_P,?DB_ROLE_BAG_P]).

fix_bad_tabs(TabList)->
    [ fix_bad_tabs_2(Tab)||Tab<-TabList ].

fix_bad_tabs_2(SourceTab) when SourceTab=:=?DB_ROLE_BAG_P->
    {ok,DetsName} = dets:open_file("/data/"++to_dets_name(SourceTab)),
    
    RoleBagBasicList = db:dirty_match_object(?DB_ROLE_BAG_BASIC_P,#r_role_bag_basic{_='_'} ),
    lists:foreach(
      fun(E)-> 
              #r_role_bag_basic{role_id=RoleID,bag_basic_list=BagBasicList} = E,
              %%去掉扩展背包
              NormalBagBasicList = lists:filter(fun(E2)-> element(1,E2)<2 orelse element(1,E2)>4 end, BagBasicList),
              [begin
                   {BagID,_BagTypeID,_OutUseTime,_Rows,_Clowns,_GridNumber} = RoleBag,
                   case db:dirty_read(SourceTab, {RoleID,BagID}) of
                       []->
                           %%fix data
                           case dets:lookup(DetsName, {RoleID,BagID}) of
                               [Rec1] -> db:dirty_write(SourceTab, Rec1);
                               []-> ignore
                           end;
                       [_BagInfo]->
                           ok
                   end 
               end || RoleBag<-NormalBagBasicList]
      end, RoleBagBasicList),
    dets:close(DetsName),
    {ok,SourceTab};
fix_bad_tabs_2(SourceTab) when SourceTab=:=?DB_ROLE_EXT_P->
    {ok,DetsName} = dets:open_file("/data/"++to_dets_name(SourceTab)),
    
    AllRoleIDList = get_all_role_id_list(),
    lists:foreach(
      fun(RoleID)-> 
              case db:dirty_read(?DB_ROLE_EXT, RoleID) of
                  []->
                      %%fix data
                      case dets:lookup(DetsName, RoleID) of
                          [Rec1] -> 
                              db:dirty_write(?DB_ROLE_EXT,Rec1);
                          []-> ignore
                      end;
                  [_BagInfo]->
                      ok
              end 
      end, AllRoleIDList),
    dets:close(DetsName),
    {ok,SourceTab}.

get_all_role_id_list(role_attr)->
    MatchHead = #p_role_attr{role_id='$1', _='_'},
    db:dirty_select(?DB_ROLE_ATTR_P, [{MatchHead, [], ['$1']}]).

get_all_role_id_list()->
    MatchHead = #p_role_base{role_id='$1', _='_'},
    db:dirty_select(?DB_ROLE_BASE_P, [{MatchHead, [], ['$1']}]).

show_tables_notempty()->
	Tabs = show_tables(),
    List = lists:filter(fun({_Tab,Size})->
                         Size>0
                 end, Tabs),
    sort_list(List).

show_tables()->
	Tabs = mnesia:system_info(tables),
    List = [ {SourceTab,mnesia:table_info(SourceTab,size)} || SourceTab <- Tabs ],
    sort_list(List).

sort_list(List)->
    lists:sort(fun({_Tab1,Size1}, {_Tab2,Size2}) -> Size1>Size2 end, List).

show_schema()->
	show_schema("/data/database/cqzj/schema.DAT").
show_schema(SchemaFilePath)->
	TmpSchemaFile = "/tmp/tmpSchema.DAT",
	TmpOutFile = "/tmp/tmpOut.txt",
	
	file:delete(TmpOutFile),
	file:copy(SchemaFilePath,TmpSchemaFile),
	{ok, N} = dets:open_file(schema, [{file, TmpSchemaFile },{repair,false}, 
									  {keypos, 2}]),
	F = fun(X) -> 
				io:format("~p~n", [X]), 
				Str = io_lib:format("~p~n", [X]),
				file:write_file(TmpOutFile, list_to_binary(Str), [append]), continue end,
	dets:traverse(N, F),
	file:delete(TmpSchemaFile),
	dets:close(N).

%% 获取指定表的所有数据
%% mt_mnesia:show_table(db_map_online).
show_table(SourceTable)->
	Pattern = get_whole_table_match_pattern(SourceTable),
    Res = mnesia:dirty_match_object(SourceTable, Pattern),
	Res.

%% 根据Set表的key去查询对应记录。
%% 例如获取某地图的人数
show_table(SourceTable,Key)->
    Pattern = get_whole_table_match_pattern(SourceTable),
    Res = mnesia:dirty_match_object(SourceTable, Pattern),
    case is_list(Res) andalso length(Res)>0 of
        true->
            lists:keyfind(Key, 2, Res);
        _ ->
            Res
    end.

get_whole_table_match_pattern(SourceTable) ->
    A = mnesia:table_info(SourceTable, attributes),
    RecordName = mnesia:table_info(SourceTable, record_name),
    lists:foldl(
      fun(_, Acc) ->
              erlang:append_element(Acc, '_')
      end, {RecordName}, A).
