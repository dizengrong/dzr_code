%%%----------------------------------------------------------------------
%%% @copyright 2010 mgeew (Ming Game Engine Erlang - World Server)
%%%
%%% @author odinxu, 2010-03-24
%%% @doc 
%%% @end
%%%----------------------------------------------------------------------

%% 宗族拉镖状态
-define(FAMILY_YBC_STATUS_NOT_BEGIN, 0).
-define(FAMILY_YBC_STATUS_PUBLISHING, 1).
-define(FAMILY_YBC_STATUS_DOING, 2).

%% 宗族地图的MapID
-define(DEFAULT_FAMILY_ID,10300).

%% assart_farm_size, 宗族已开垦的田地数目
-record(family_state, {family_info, family_members, invites, requests, ext_info,assart_farm_size}).

-define(ISOPEN_FAMILY_LETTER,false).

-define(COMMON_FAMILY_LETTER(RoleID, Content, Title, Day),
        case ?ISOPEN_FAMILY_LETTER of
            true->
               common_letter:sys2p(RoleID, Content, Title, Day);
            _->
               ignore
        end).