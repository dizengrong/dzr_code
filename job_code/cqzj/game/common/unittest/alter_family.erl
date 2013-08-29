-module(alter_family).

-compile(export_all).


alter() ->
    alter_family_ext().

alter_family_ext()->
    Fun = fun(R) ->
                  {r_family_ext, FAMILY_ID,LAST_SET_OWNER_TIME,COMMON_BOSS_CALLED,
                   COMMON_BOSS_KILLED,COMMON_BOSS_CALL_TIME,
                   LAST_YBC_FINISH_DATE,LAST_YBC_BEGIN_TIME,LAST_YBC_RESULT,
                   YBC_ID,YBC_ROLE_LIST,LAST_RESUME_TIME,LAST_CARD_USE_COUNT,
                   LAST_CARD_USE_DAY,LAST_DELIVER_DIST_POS} = R,
                  {r_family_ext, FAMILY_ID,LAST_SET_OWNER_TIME,COMMON_BOSS_CALLED,
                   COMMON_BOSS_KILLED,COMMON_BOSS_CALL_TIME,
                   LAST_YBC_FINISH_DATE,LAST_YBC_BEGIN_TIME,LAST_YBC_RESULT,
                   YBC_ID,YBC_ROLE_LIST,LAST_RESUME_TIME,LAST_CARD_USE_COUNT,
                   LAST_CARD_USE_DAY,LAST_DELIVER_DIST_POS,
                   0}
          end,
    
    AttrList = [family_id,last_set_owner_time,common_boss_called,
                common_boss_killed,common_boss_call_time,
                last_ybc_finish_date,last_ybc_begin_time,last_ybc_result,
                ybc_id,ybc_role_list,last_resume_time,last_card_use_count,
                last_card_use_day,last_deliver_dist_pos,
                common_boss_call_count],
    
    db_transform:do(db_family_ext_p, Fun, AttrList),
    db_transform:do(db_family_ext, Fun, AttrList).