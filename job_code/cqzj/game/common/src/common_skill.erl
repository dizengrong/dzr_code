-module(common_skill).
-include("common.hrl").
-include("common_server.hrl").

-export([get_actor_buf_by_id/4]).

get_actor_buf_by_id(RoleID,SrcActorID, SrcActorType, BuffDetail) ->
    #p_buf{
            buff_id=BuffID,
            buff_type=BuffType,
            value=Value,
            last_value=LastValue
          } = BuffDetail,

    BeginTime = common_tool:now(),

    #p_actor_buf{
                  buff_id=BuffID,
                  buff_type=BuffType,
                  actor_id=RoleID,
                  actor_type=?TYPE_ROLE,
                  from_actor_id=SrcActorID,
                  from_actor_type=get_dest_type(SrcActorType),
                  remain_time=LastValue,
                  start_time=BeginTime,
                  end_time=BeginTime+LastValue,
                  value=Value
                }.

get_dest_type(ActorType) ->
    case ActorType of
        role ->
            ?TYPE_ROLE;
        monster ->
            ?TYPE_MONSTER;
        pet ->
            ?TYPE_PET;
        _ ->
            ?TYPE_OTHER
    end.
