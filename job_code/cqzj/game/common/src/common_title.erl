%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     称号的公共方法
%%% @end
%%% Created : 2011-07-20
%%%-------------------------------------------------------------------
-module(common_title).

-include("common.hrl").
-include("common_server.hrl").
-include("office.hrl").


%% API OF TITLES
-export([
			add_title/3,
			remove_by_typeid/2,
			remove_by_titleid/2,
			get_role_sence_titles/1,
			get_role_chat_titles/1,
			send_sence_titles/1,
			get_king_name/1,
			get_default_title/0,
      recalc/2,
      hook_role_online/1,
      change_nation_title/2
		]).


%% API OF TITLES
-export([
			get_title_name_of_rank/2,
			get_title_name_of_rank/3,
			get_jingjie_name/1,
			get_jingjie/1
		]).

%%当前可用的ID和申请到的最大的ID

-define(CURENT_NEW_TITLE_ID_INFO,current_new_title_id_info).

%%添加某个单位的称号
add_title(TitleType, DestID, Info) ->
    case TitleType of
        ?TITLE_EMPEROR ->
            set_emperor(DestID);
        ?TITLE_KING ->
            set_king(DestID,Info);
        ?TITLE_WORLD_PKPOINT_RANK ->
            set_world_pkpoint_rank_title(DestID,Info);
        ?TITLE_ROLE_LEVEL_RANK ->
            set_role_level_rank_title(DestID,Info);
        ?TITLE_ROLE_GONGXUN_RANK ->
            set_role_gongxun_rank_title(DestID,Info);
        ?TITLE_EDUCATE ->
            set_educate_title(DestID,Info);
        ?TITLE_OFFICE_MINISTER ->
            set_office_minister(DestID,Info);
        ?TITLE_OFFICE_JINYIWEI ->
            set_office_jinyiwei(DestID,Info);
        ?TITLE_OFFICE_GENERAL ->
            set_office_general(DestID,Info);
        ?TITLE_FAMILY ->
            set_family_title(DestID,Info);
        ?TITLE_VIP ->
            set_vip_title(DestID, Info);
        ?TITLE_ROLE_JINGJIE ->
             set_jingjie_title(DestID,Info);
        ?TITLE_MANUAL ->
            set_role_manual_title(DestID,Info);
        ?TITLE_ROLE_GIVE_FLOWERS ->
            set_role_give_flowers(DestID,Info);
        ?TITLE_ROLE_GIVE_FLOWERS_YESTERDAY ->
            set_role_give_flowers_yesterday(DestID,Info);
        ?TITLE_ROLE_RECE_FLOWERS ->
            set_role_rece_flowers(DestID,Info);
        ?TITLE_ROLE_RECE_FLOWERS_YESTERDAY ->
            set_role_rece_flowers_yesterday(DestID,Info);
        ?TITLE_STUDENT ->
            set_student_title(DestID, Info);
		    ?TITLE_ROLE_FIGHTING_POWER ->
			      set_role_fighting_power(DestID,Info);
		    ?TITLE_ROLE_JUEWEI ->
			      set_role_juewei(DestID,Info);
        ?TITLE_HORSE_RACING ->
            set_horse_racing_title(DestID, Info);
        ?TITLE_NATION ->
            set_nation_title(DestID, Info);
        _ -> ignore
    end.

%%判断当前的称号是否已经过时了, 
%%如果过时则销毁掉, 
%%暂时用于上古战场的称号
hook_role_online(RoleID) ->
    case db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=?TITLE_NATION,role_id=RoleID,_='_'}) of
      [TitleInfo] when is_record(TitleInfo,p_title)->
        NowSec = common_tool:now(),
        if
            TitleInfo#p_title.auto_timeout andalso 
            TitleInfo#p_title.timeout_time =< NowSec ->
                common_title_srv:remove_by_typeid(?TITLE_NATION, RoleID);
            TitleInfo#p_title.auto_timeout ->
                erlang:send_after(
                    (TitleInfo#p_title.timeout_time - NowSec) * 1000,
                    erlang:self(),
                    {apply, common_title_srv, remove_by_typeid, [?TITLE_NATION, RoleID]}
                );
            true -> ignore
        end;
      _ -> ignore
    end.

send_sence_titles(RoleID) ->
    Titles = common_title:get_role_sence_titles(RoleID),
    Data = #m_title_get_role_titles_toc{titles=Titles},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?TITLE, ?TITLE_GET_ROLE_TITLES, Data).

%%根据称类型移除某个单位的称号
remove_by_typeid(TitleType, DestID) ->
    case db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=TitleType,role_id=DestID,_='_'}) of
        [] ->
            case db:dirty_match_object(?DB_SPEC_TITLE,#p_title{type=TitleType,role_id=DestID,_='_'})of
                [] ->
                    {fail,not_exist};
                [R] ->
                    db:dirty_delete_object(?DB_SPEC_TITLE,R),
                    common_hook_title:delete(DestID,R#p_title.name),
                    ok
            end;
        [R]  ->
            remove_nation(DestID),
            db:dirty_delete_object(?DB_NORMAL_TITLE,R),
            common_hook_title:delete(DestID,R#p_title.name),
            ok
    end.

%%根据称号ID删除称号，目前只用于后台的自定义称号
remove_by_titleid(TitleID,DestID) ->
     case db:dirty_read(?DB_NORMAL_TITLE,TitleID) of
         [] ->
             {fail,not_exist};
         [R] ->
              remove_nation(DestID),
              db:dirty_delete(?DB_NORMAL_TITLE,TitleID),
              common_hook_title:delete(DestID,R#p_title.name),
              ok
     end.

%%获取玩家的所有称号信息, 返回 p_title的list
get_role_sence_titles(RoleID) ->
    NormalTiles = db:dirty_match_object(?DB_NORMAL_TITLE, #p_title{role_id=RoleID,show_in_sence=true,_='_'}),
    SpecTitles = get_spec_sence_titles(RoleID),
	%% 默认称号
	{DefaultTitleName,DefaultTitleColor} = get_default_title(),
	DefaultTitle = #p_title{id=0, name=DefaultTitleName, type=0, auto_timeout=false, role_id=RoleID, 
							show_in_chat=false, show_in_sence=true, color=DefaultTitleColor},
    %% 签名称号
    case common_misc:get_dirty_role_ext(RoleID) of
        {ok, RoleExt}   ->
            if RoleExt#p_role_ext.signature =:= undefined orelse RoleExt#p_role_ext.signature =:= "" ->
                   SignatureTitle = [];
               true ->
                   Signature = common_tool:sublist_utf8(RoleExt#p_role_ext.signature, 1, 7),
                   case cfg_title:family_title_forbidden(Signature) of
                       true ->
                           SignatureTitle = [];
                       false ->
                           SignatureTitle = [#p_title{id=-1, name=Signature, type=0, auto_timeout=false, role_id=RoleID,
                                                      show_in_chat=false, show_in_sence=true, color=get_signature_title_color()}]
                   end
            end;
        _Else   ->
            SignatureTitle = []
    end,
	lists:append([[DefaultTitle],NormalTiles,SpecTitles,SignatureTitle]).

% get_achievement_title_link(RoleID) ->
%     #p_title{
%         id            = 1, 
%         name          = "选择侠名", 
%         type          = ?TITLE_ACHIEVEMENT, 
%         auto_timeout  = false, 
%         role_id       = RoleID,
%         show_in_chat  = false,
%         show_in_sence = true, 
%         color         = "0000ff"}.

get_default_title() ->
    cfg_title:get_default_title().

get_signature_title_color() ->
    cfg_title:signature_title_color().

%%获取玩家的所有聊天称号，返回p_chat_title的list
get_role_chat_titles(RoleID) ->
    NormalTiles = get_normal_chat_titles(RoleID),
    SpecTitles = get_spec_chat_titles(RoleID),
    lists:append(NormalTiles,SpecTitles).

get_normal_chat_titles(RoleID)->
    case catch db:dirty_match_object(?DB_NORMAL_TITLE, #p_title{role_id=RoleID,show_in_chat=true,_='_'}) of
        Titles when is_list(Titles) andalso length(Titles)>0->
            lists:foldl(
              fun(Title, Acc) ->
                      #p_title{id=ID, name=Name, color=Color} = Title,
                      [#p_chat_title{id=ID, name=Name, color=Color} | Acc]
                      % case Type =:= ?TITLE_VIP of
                      %     true ->
                      %         [#p_chat_title{id=ID, name="星级", color=Color} | Acc];
                      %     false ->
                      %         [#p_chat_title{id=ID, name=Name, color=Color} | Acc]
                      % end                                    
              end, [], Titles);
        _ ->
            []
    end.

%%
%%==================LOCAL FUNCTION OF KING====================
%%
get_spec_sence_titles(RoleID) ->
    db:dirty_match_object(?DB_SPEC_TITLE, #p_title{role_id=RoleID,show_in_sence=true,_='_'}).


get_spec_chat_titles(RoleID) ->
    case catch db:dirty_match_object(?DB_SPEC_TITLE, #p_title{role_id=RoleID,show_in_chat=true,_='_'}) of
        Titles when is_list(Titles) andalso length(Titles)>0->
            lists:foldl(
              fun(Title, Acc) ->
                      #p_title{id=ID, name=Name, color=Color} = Title,
                      [#p_chat_title{id=ID, name=Name, color=Color} | Acc]
              end, [], Titles);
        _ ->
            []
    end.

%%获取新的titleID，每次获取最新的1000个ID，存在进程字典
get_new_titleid() ->
	case get(?CURENT_NEW_TITLE_ID_INFO) of
		undefined ->
			CurrentID = 1,
			MaxID = 1;
		{CurrentID,MaxID} ->
			ignore
	end,
	case CurrentID >= MaxID of
		true ->
    Fun = fun() ->
                  case db:read(?DB_TITLE_COUNTER, 1, write) of
                      [] ->
                          Record = #r_title_counter{id = 1,last_title_id = 100000},
                          db:write(?DB_TITLE_COUNTER, Record, write),
								  101000;
                      [Record] ->
                          #r_title_counter{last_title_id = LastID} = Record,
								  NewRecord = Record#r_title_counter{last_title_id = LastID+1001},
                          db:write(?DB_TITLE_COUNTER, NewRecord, write),
								  LastID+1001
                  end
          end,
			{atomic,MaxID2} = db:transaction(Fun),
			CurrentID2 = MaxID2 - 1000;
		false ->
			CurrentID2 = CurrentID,
			MaxID2 = MaxID
	end,
	put(?CURENT_NEW_TITLE_ID_INFO,{CurrentID2+1,MaxID2}),
	CurrentID2.

delete_old_titles(TitleList, DBName, RankList) ->
	lists:foldr(
	  fun(Title, {DelList,ChangeList,NoChangeList}) ->
			  #p_title{role_id=RoleID, name=OldTitleName} = Title,
			  case lists:keyfind(RoleID, 1, RankList) of
				  false ->
					  db:dirty_delete_object(DBName, Title),
					  common_hook_title:change_role_cur_title(RoleID, undefined, undefined, undefined),
					  {[RoleID|DelList],ChangeList,NoChangeList};
				  {RoleID,NewTitleName} ->
					  case NewTitleName of
						  "" ->
							  db:dirty_delete_object(DBName, Title),
							  common_hook_title:change_role_cur_title(RoleID, undefined, undefined, undefined),
							  {[RoleID|DelList],ChangeList,NoChangeList};
						  _ ->
							  case NewTitleName =:= OldTitleName of
								  true ->
									  {DelList,ChangeList,[RoleID|NoChangeList]};
								  false ->
									  common_hook_title:change_role_cur_title(RoleID, undefined, undefined, undefined),
									  {DelList,[{RoleID,Title}|ChangeList],NoChangeList}
							  end
					  end
			  end
	  end,{[],[],[]},TitleList).

%%========================TILTE EMPEROR=======================
%%设置皇帝
set_emperor(RoleID) ->
    common_hook_title:change(RoleID),
    ok.


%%=========================TITLE KING=========================
    

%%直接使用FactionID为对应国家的国王称号的称号ID
get_king_titleid(FactionID) ->
    FactionID.


%%设置国王
set_king(RoleID, FactionID) ->
    TitleID = get_king_titleid(FactionID),
    case db:transaction(fun() -> t_do_set_king(RoleID, TitleID, get_king_name(FactionID)) end) of
        {atomic, Rtn} ->
            case Rtn of
                ok ->
                    ok;
                {ok, {OldRoleID,TitleName}}->
                    common_hook_title:delete(OldRoleID,TitleName)
            end,
            common_hook_title:change(RoleID),
            ok;
        {aborted, Error} ->
            {error, Error}
    end.


%%设置新的国王
t_do_set_king(RoleID, TitleID, TitleName) ->
    case db:dirty_match_object(?DB_SPEC_TITLE, #p_title{id=TitleID, _='_'}) of
        [] ->
            %%上一届没有对应的国王称号
            t_do_set_king2(RoleID, TitleID, TitleName),
            ok;
        [#p_title{role_id=OldRoleID} = TObject] ->
            case RoleID =:= OldRoleID of
                true ->
                    ok;
                false ->
                    %%取消上一次的国王的称号
                    db:delete_object(?DB_SPEC_TITLE, TObject, write),
                    t_do_set_king2(RoleID, TitleID, TitleName),
                    {ok,{OldRoleID,TitleName}}
            end
    end.


t_do_set_king2(RoleID, TitleID, TitleName) ->
    R = #p_title{id=TitleID, name=TitleName, type=?TITLE_KING, auto_timeout=false,
                 role_id=RoleID, show_in_chat=if_show_in_chat(TitleName), show_in_sence=true,color="ffff00"},
    db:write(?DB_SPEC_TITLE, R, write).
    

%%根据国家ID获取对应的国王的名称
get_king_name(FactionID) when is_integer(FactionID)->
    cfg_title:king_name(FactionID).

%%=========================TITLE ROLE_GONGXUN_RANK=========================                               

%%%%%%%%%%% 更新排行榜的头衔      %%%%%%%%%%% 
-define(SET_RANK_TITLE(RankList,TitleType,RecordName),
		List = db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=TitleType,_='_'}),
		RankList2 = lists:map(
      fun(RankInfo) ->
							  #RecordName{role_id = RoleID,title=TitleName} = RankInfo,
							 {RoleID,TitleName} 
					  end, RankList),
		{_DelList,ChangeList,NoChangeList} = delete_old_titles(List,?DB_NORMAL_TITLE, RankList2),
        lists:foreach(
        fun({RoleID,NewTitleName}) ->
              case NewTitleName =:= "" orelse lists:member(RoleID, NoChangeList) =/= false of
                  true ->
                      ignore;
                  _ ->
                      	Color = get_title_color(NewTitleName),
                      	ShowChat = if_show_in_chat(NewTitleName),
						case lists:keyfind(RoleID, 1, ChangeList) of
							{RoleID,OldTitle} ->
                                db:dirty_write(?DB_NORMAL_TITLE, OldTitle#p_title{name=NewTitleName, show_in_chat=ShowChat, color=Color}),
                          common_hook_title:exchange_title_name(RoleID,undefined,NewTitleName, Color,OldTitle#p_title.id);
								false ->
                      			TitleID = get_new_titleid(),
                      			R = #p_title{id=TitleID, name=NewTitleName, type=TitleType, auto_timeout=false, 
                                   	role_id=RoleID, show_in_chat=ShowChat, show_in_sence=true,color=Color},
														common_hook_title:exchange_title_name(RoleID,undefined,NewTitleName, Color,TitleID),
                      			db:dirty_write(?DB_NORMAL_TITLE, R)
						end,
                      common_hook_title:change(RoleID)
              end
      end,RankList2)).

set_world_pkpoint_rank_title(0,RankList) ->
    ?SET_RANK_TITLE(RankList,?TITLE_WORLD_PKPOINT_RANK,p_role_pkpoint_rank).
        
set_role_gongxun_rank_title(0,RankList) ->
    ?SET_RANK_TITLE(RankList,?TITLE_ROLE_GONGXUN_RANK,p_role_gongxun_rank).

set_role_give_flowers(0,RankList) ->
    ?SET_RANK_TITLE(RankList,?TITLE_ROLE_GIVE_FLOWERS,p_role_give_flowers_rank).

set_role_give_flowers_yesterday(0,RankList) ->
    ?SET_RANK_TITLE(RankList,?TITLE_ROLE_GIVE_FLOWERS_YESTERDAY,p_role_give_flowers_yesterday_rank).

set_role_rece_flowers(0,RankList) ->
    ?SET_RANK_TITLE(RankList,?TITLE_ROLE_RECE_FLOWERS,p_role_rece_flowers_rank).

set_role_rece_flowers_yesterday(0,RankList) ->
    ?SET_RANK_TITLE(RankList,?TITLE_ROLE_RECE_FLOWERS_YESTERDAY,p_role_rece_flowers_yesterday_rank).

set_role_fighting_power(0,RankList) ->
	?SET_RANK_TITLE(RankList,?TITLE_ROLE_FIGHTING_POWER,p_role_fighting_power_rank).

set_role_level_rank_title(0,RankList) ->
    ?SET_RANK_TITLE(RankList,?TITLE_ROLE_LEVEL_RANK,p_role_level_rank);
set_role_level_rank_title(_,Level) when is_integer(Level) ->
    ignore.

%%=========================TITLE EDUCAT=========================
set_educate_title(RoleID,{TitleName,Color}) ->
    set_simple_role_title(RoleID,?TITLE_EDUCATE,TitleName,Color).

set_family_title(RoleID,TitleName) ->
    set_simple_role_title(RoleID,?TITLE_FAMILY,TitleName,"00ffff").

set_student_title(RoleID,{TitleName,TitleColor}) ->
    case db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=?TITLE_STUDENT,role_id=RoleID,_='_'}) of
        [] ->
            OldTitleName = undefined,
            TitleID = get_new_titleid(),
            R = #p_title{id=TitleID, name=TitleName, type=?TITLE_STUDENT, auto_timeout=false, 
                         role_id=RoleID, show_in_chat=if_show_in_chat(TitleName), show_in_sence=true,color=TitleColor};
        [TitleInfo] ->
            #p_title{id=TitleID,name=OldTitleName} = TitleInfo,
            R = TitleInfo#p_title{name=TitleName, show_in_chat=if_show_in_chat(TitleName), color=TitleColor}
    end,
    db:dirty_write(?DB_NORMAL_TITLE, R),
    common_hook_title:exchange_title_name(RoleID,OldTitleName,TitleName,TitleColor,TitleID,true).


set_role_juewei(RoleID,Juewei) ->
	case cfg_title:juewei_title(Juewei) of
		false->
			next;
		Title->
			case db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=?TITLE_ROLE_JUEWEI,role_id=RoleID,_='_'}) of
				[TitleInfo] when is_record(TitleInfo,p_title)->
					TitleID=TitleInfo#p_title.id;
				_ ->
					TitleID = get_new_titleid()
			end,
			R = #p_title{id=TitleID, 
						 name=Title#r_juewei_title.title_name, 
						 color=Title#r_juewei_title.title_color, 
						 type=?TITLE_ROLE_JUEWEI, 
						 auto_timeout=false, 
						 timeout_time=0, 
						 role_id=RoleID, 
						 show_in_chat=Title#r_juewei_title.is_show_in_chat, 
						 show_in_sence=Title#r_juewei_title.is_show_in_sence},
			db:dirty_write(?DB_NORMAL_TITLE, R),
			common_hook_title:change(RoleID),
			common_hook_title:exchange_title_name(RoleID,undefined,Title#r_juewei_title.title_name,
												  Title#r_juewei_title.title_color,TitleID)
	end.

set_nation_title(RoleID, TitleTypeId) ->
  case cfg_title:nation_title(TitleTypeId) of
    false -> ignore;
    TitleRec ->
      case db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=?TITLE_NATION,role_id=RoleID,_='_'}) of
        [TitleInfo] when is_record(TitleInfo,p_title)->
          TitleID=TitleInfo#p_title.id;
        _ ->
          TitleID = get_new_titleid()
      end,
      RolePid = global:whereis_name(mgeer_role:proc_name(RoleID)),
      erlang:send_after(
          TitleRec#r_nation_title.timeout_time * 1000,
          RolePid,
          {apply, common_title_srv, remove_by_typeid, [?TITLE_NATION, RoleID]}
      ),
      common_letter:sys2p(RoleID,common_tool:to_binary(?_LANG_NATION_TITLE_GET),"上古战场邮件", [],14),
      
      R = #p_title{
         id=TitleID, 
         name=TitleRec#r_nation_title.title_name, 
         color=TitleRec#r_nation_title.title_color, 
         type=?TITLE_NATION, 
         type_id = TitleRec#r_nation_title.code,
         auto_timeout=true, 
         timeout_time=TitleRec#r_nation_title.timeout_time + common_tool:now(), 
         role_id=RoleID, 
         show_in_chat=true, 
         show_in_sence=true
      },
      db:dirty_write(?DB_NORMAL_TITLE, R),
      % add_nation_attr(?TITLE_NATION, RoleID, R),
      common_hook_title:change(RoleID),
      common_hook_title:exchange_title_name(
        RoleID,
        undefined,
        TitleRec#r_nation_title.title_name, 
        TitleRec#r_nation_title.title_color,
        TitleID
      )
  end.
	
set_jingjie_title(RoleID,Jingjie)->
    case cfg_title:jingjie_title(Jingjie) of
        false->
            next;
        Title->
            case db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=?TITLE_ROLE_JINGJIE,role_id=RoleID,_='_'}) of
                [TitleInfo] when is_record(TitleInfo,p_title)->
                    TitleID=TitleInfo#p_title.id;
                _ ->
                    TitleID = get_new_titleid()
            end,
            R = #p_title{id=TitleID, 
                         name=Title#r_jingjie_title.title_name, 
                         color=Title#r_jingjie_title.title_color, 
                         type=?TITLE_ROLE_JINGJIE, 
                         auto_timeout=false, 
                         timeout_time=0, 
                         role_id=RoleID, 
                         show_in_chat=Title#r_jingjie_title.is_show_in_chat, 
                         show_in_sence=Title#r_jingjie_title.is_show_in_sence},
            db:dirty_write(?DB_NORMAL_TITLE, R),
            common_hook_title:change(RoleID),
            common_hook_title:exchange_title_name(RoleID,undefined,Title#r_jingjie_title.title_name,
                                                  Title#r_jingjie_title.title_color,TitleID)
    end.

set_simple_role_title(RoleID,TitleType,TitleName,TitleColor) when is_integer(TitleType)->
    case db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=TitleType,role_id=RoleID,_='_'}) of
        [] ->
            OldTitleName = undefined,
            TitleID = get_new_titleid(),
            R = #p_title{id=TitleID, name=TitleName, type=TitleType, auto_timeout=false, 
                         role_id=RoleID, show_in_chat=if_show_in_chat(TitleName), show_in_sence=true,color=TitleColor};
        [TitleInfo] ->
            #p_title{id=TitleID,name=OldTitleName} = TitleInfo,
            R = TitleInfo#p_title{name=TitleName, show_in_chat=if_show_in_chat(TitleName), color=TitleColor}
    end,
    db:dirty_write(?DB_NORMAL_TITLE, R),
    common_hook_title:change(RoleID),  
    case OldTitleName of
        undefined ->
            nil;
        _ ->
            common_hook_title:exchange_title_name(RoleID,OldTitleName,TitleName,"00ffff",TitleID)
    end.

%%=========================TITLE VIP===========================
set_vip_title(RoleID, {TitleName, Color}) ->
    case db:dirty_match_object(?DB_NORMAL_TITLE, #p_title{type=?TITLE_VIP, role_id=RoleID, _='_'}) of
        [] ->
            OldTitleName = undefined,
            TitleID = get_new_titleid(),
            if TitleName =:= "" ->
            R = #p_title{id=TitleID, name=TitleName, type=?TITLE_VIP, auto_timeout=false, 
                                 role_id=RoleID, show_in_chat=true, show_in_sence=false, color=Color};
               true ->
                    R = #p_title{id=TitleID, name=TitleName, type=?TITLE_VIP, auto_timeout=false, 
                                 role_id=RoleID, show_in_chat=true, show_in_sence=true, color=Color}
            end;
        [TitleInfo] ->
            #p_title{id=TitleID, name=OldTitleName} = TitleInfo,
            if TitleName =:= "" ->
                    R = TitleInfo#p_title{name=TitleName, show_in_chat=true, color=Color};
               true ->
                    R = TitleInfo#p_title{name=TitleName, show_in_chat=true, show_in_sence=true, color=Color}
            end
    end,
    db:dirty_write(?DB_NORMAL_TITLE, R),

    common_hook_title:change(RoleID),
    if TitleName =:= "" ->
            ignore;
	   true ->
    		common_hook_title:exchange_title_name(RoleID, OldTitleName, TitleName, Color, TitleID)
	end.

%%=========================TITLE ROLE_MANUAL====================


%%=========================TITLE_OFFICE=========================
set_office_title(RoleID,FactionID,TitleType,TitleName,Color) ->
    TitleID = TitleType + FactionID,
    case db:dirty_read(?DB_SPEC_TITLE,TitleID) of
        [] ->
            OldRoleID = 0,
            R = #p_title{id=TitleID, name=TitleName, type=TitleType, auto_timeout=false, 
                         role_id=RoleID, show_in_chat=if_show_in_chat(TitleName), show_in_sence=true,color=Color};
        [TitleInfo] ->
            OldRoleID = TitleInfo#p_title.role_id,
            R = TitleInfo#p_title{role_id = RoleID}
    end,
    db:dirty_write(?DB_SPEC_TITLE, R),
    case OldRoleID =:= RoleID of
        true ->
            nil;
        false ->
            common_hook_title:change(RoleID),
            case OldRoleID of
                0 ->
                    pass;
                _ ->
                    common_hook_title:change(OldRoleID)
            end
    end.

%%=========================TITLE_OFFICE_MINISTER================
set_office_minister(RoleID,FactionID) ->
    set_office_title(RoleID,FactionID,?TITLE_OFFICE_MINISTER,?OFFICE_NAME_MINISTER,"ffc000").
   

%%=========================TITLE_OFFICE_JINYIWEI================
set_office_jinyiwei(RoleID,FactionID) ->
    set_office_title(RoleID,FactionID,?TITLE_OFFICE_JINYIWEI,?OFFICE_NAME_JINYIWEI,"00aeff").


%%=========================TITLE_OFFICE_GENERAL=================
set_office_general(RoleID,FactionID) ->
    set_office_title(RoleID,FactionID,?TITLE_OFFICE_GENERAL,?OFFICE_NAME_GENERAL,"fc00ff").

    
%%=========================TITLE MANUAL=========================
set_role_manual_title(RoleID,{Type,TitleName,TitleColor,ShowChat,ShowSence,AutoTimeOut,Time}) ->
    TitleID = get_new_titleid(),
    R = #p_title{id=TitleID, name=TitleName, color=TitleColor, type=Type, 
                 auto_timeout=AutoTimeOut, timeout_time=Time, role_id=RoleID, 
                 show_in_chat=ShowChat, show_in_sence=ShowSence},
    db:dirty_write(?DB_NORMAL_TITLE, R),
    common_hook_title:change(RoleID),
    common_hook_title:exchange_title_name(RoleID,undefined,TitleName,TitleColor,TitleID).

%%=========================HORSE RACING=========================
set_horse_racing_title(RoleID, {TitleName, Color}) ->
    if TitleName =:= "" ->
           ignore;
       true ->
           case db:dirty_match_object(?DB_NORMAL_TITLE,#p_title{type=?TITLE_HORSE_RACING,role_id=RoleID,_='_'}) of
               [TitleInfo] when is_record(TitleInfo,p_title)->
                   TitleID=TitleInfo#p_title.id;
               _ ->
                   TitleID = get_new_titleid()
           end,
           R = #p_title{id=TitleID, 
                        name=TitleName, color=Color, type=?TITLE_HORSE_RACING, auto_timeout=false, 
                        role_id=RoleID, show_in_chat=false, show_in_sence=true},
           db:dirty_write(?DB_NORMAL_TITLE, R),
           common_hook_title:exchange_title_name(RoleID, undefined, TitleName, Color, TitleID)
    end.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% 是否在聊天窗口中显示
if_show_in_chat(undefined)->
    false;
if_show_in_chat([])->
    false;
if_show_in_chat(TitleName) ->
    StrTitleName = common_tool:to_list(TitleName),
    lists:member(StrTitleName, cfg_title:show_in_chat()).

%% 获取称号颜色
get_title_color(TitleName)->
    cfg_title:title_color(TitleName).


%% 获取排行榜对应的称号名称
get_title_name_of_rank(RankType,Rank)->
    get_title_name_of_rank_2(cfg_title:rank_type(RankType), Rank).

get_title_name_of_rank(RankType,Rank,SubType)->
    get_title_name_of_rank_2(cfg_title:rank_type(RankType, SubType), Rank).


%%@doc 获取境界副本的Title
%%@return #r_jingjie_title|false
get_jingjie(Jingjie) when is_integer(Jingjie)->
    % [Titles] = common_config_dyn:find(title,hero_fb_title),
    % lists:keyfind(Jingjie, #r_jingjie_title.code, Titles).
    %% TODO:这里是配置数据删了但代码没删，先返回一个空
    false.
get_jingjie_name(Jingjie) when is_integer(Jingjie)->
    %% TODO:这里是配置数据删了但代码没删，先返回一个空
    "".


get_title_name_of_rank_2([],_Rank)->
    "";
get_title_name_of_rank_2([H|T],Rank)->
    {Min,Max,TitleName}= H,
    case Rank>=Min andalso Rank=<Max of
        true->
            TitleName;
        _ ->
            get_title_name_of_rank_2(T,Rank)
    end.

%%%%----------------------上古战场的title处理----------------
%%登陆时重新计算属性的调用接口
recalc(RoleBase, _RoleAttr) ->
    case is_nation_cur_title(RoleBase#p_role_base.role_id) of
        TypeID when is_integer(TypeID) ->
            % add_nation_attr(?TITLE_NATION, RoleBase);
            [TitleRec] = db:dirty_match_object(
              ?DB_NORMAL_TITLE,
              #p_title{
                  type=?TITLE_NATION,
                  role_id=RoleBase#p_role_base.role_id,
                  _='_'
              }),
            RoleID = RoleBase#p_role_base.role_id,
            TitleConfigRec = cfg_title:nation_title(TitleRec#p_title.type_id),
            AttrList = get_nation_attr_list(RoleID, TitleConfigRec),
            mod_role_attr:calc(RoleBase, '+', AttrList);
        _ -> RoleBase
    end.

%%role process
change_nation_title(RoleID, TitleID) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    case db:dirty_read(?DB_NORMAL_TITLE, TitleID) of
        [#p_title{type = ?TITLE_NATION} = R1] ->
            add_nation_attr(?TITLE_NATION, RoleBase, R1);
        _ -> 
          remove_nation_attr(RoleID)
          % common_hook_title:delete(RoleID)
    end.

%%判断当前的称谓时不是上古战场称谓
is_nation_cur_title(RoleID) ->
    {ok, #p_role_base{
        cur_title = TitleName
    }} = mod_map_role:get_role_base(RoleID),
    cfg_title:is_nation_title(TitleName).

add_nation_attr(?TITLE_NATION, RoleBase, TitleRec) ->
    RoleID = RoleBase#p_role_base.role_id,
    TitleConfigRec = cfg_title:nation_title(TitleRec#p_title.type_id),
    AttrList = get_nation_attr_list(RoleID, TitleConfigRec),
    mgeer_role:send_reload_base(RoleID, '+', AttrList);

    % common_hook_title:change(RoleID),
    % common_hook_title:exchange_title_name(
    %   RoleID,
    %   undefined,
    %   TitleConfigRec#r_nation_title.title_name, 
    %   TitleConfigRec#r_nation_title.title_color,
    %   TitleRec#p_title.id
    % );
add_nation_attr(_, RoleBase, _) -> RoleBase.

remove_nation(RoleID) ->
    Text = common_misc:format_lang(?_LANG_NATION_TITLE_LOST, [common_tool:seconds_to_datetime_string(common_tool:now())]),
    common_letter:sys2p(RoleID,common_tool:to_binary(Text),"上古战场邮件", [],14),
    remove_nation_attr(RoleID).

%%删除称谓时的特殊称谓处理
remove_nation_attr(RoleID) ->
    case is_nation_cur_title(RoleID) of
        TypeID when is_integer(TypeID) ->
            TitleConfigRec = cfg_title:nation_title(TypeID), 
            AttrList = get_nation_attr_list(RoleID, TitleConfigRec),
            mgeer_role:send_reload_base(RoleID, '-', AttrList);
        _ -> ignore
    end.

%%获取上古战场改变属性的列表
get_nation_attr_list(RoleID, TitleRec) ->
  {ok, #p_role_attr{category = Category}} = mod_map_role:get_role_attr(RoleID),
  get_nation_attr_list1(Category, TitleRec).

get_nation_attr_list1(1, TitleRec) ->
  [
    {#p_role_base.max_phy_attack, TitleRec#r_nation_title.attack},
    {#p_role_base.min_phy_attack, TitleRec#r_nation_title.attack},
    {#p_role_base.max_hp, TitleRec#r_nation_title.hp},
    {#p_role_base.phy_defence, TitleRec#r_nation_title.phy_def},
    {#p_role_base.magic_defence, TitleRec#r_nation_title.magic_def}
  ];
get_nation_attr_list1(3, TitleRec) ->
  [
    {#p_role_base.max_magic_attack, TitleRec#r_nation_title.attack},
    {#p_role_base.min_magic_attack, TitleRec#r_nation_title.attack},
    {#p_role_base.max_hp, TitleRec#r_nation_title.hp},
    {#p_role_base.phy_defence, TitleRec#r_nation_title.phy_def},
    {#p_role_base.magic_defence, TitleRec#r_nation_title.magic_def}
  ].
