-module (role_util).

-include("common.hrl").

-export([role_update_attri_add/2, role_update_attri_add/1]).


%% 两个role_update_attri记录相加的方法
-spec role_update_attri_add(#role_update_attri{}, #role_update_attri{}) ->
	#role_update_attri{}.
role_update_attri_add(Rec1, Rec2) ->
	#role_update_attri{
		gd_liliang    = Rec1#role_update_attri.gd_liliang + Rec2#role_update_attri.gd_liliang,
		gd_yuansheng  = Rec1#role_update_attri.gd_yuansheng + Rec2#role_update_attri.gd_yuansheng,
		gd_tipo       = Rec1#role_update_attri.gd_tipo + Rec2#role_update_attri.gd_tipo,
		gd_minjie     = Rec1#role_update_attri.gd_minjie + Rec2#role_update_attri.gd_minjie,
		gd_speed      = Rec1#role_update_attri.gd_speed + Rec2#role_update_attri.gd_speed,
		gd_baoji      = Rec1#role_update_attri.gd_baoji + Rec2#role_update_attri.gd_baoji,
		gd_shanbi     = Rec1#role_update_attri.gd_shanbi + Rec2#role_update_attri.gd_shanbi,
		gd_gedang     = Rec1#role_update_attri.gd_gedang + Rec2#role_update_attri.gd_gedang,
		gd_mingzhong  = Rec1#role_update_attri.gd_mingzhong + Rec2#role_update_attri.gd_mingzhong,
		gd_zhiming    = Rec1#role_update_attri.gd_zhiming + Rec2#role_update_attri.gd_zhiming,
		gd_xingyun    = Rec1#role_update_attri.gd_xingyun + Rec2#role_update_attri.gd_xingyun,
		gd_fanji      = Rec1#role_update_attri.gd_fanji + Rec2#role_update_attri.gd_fanji,
		gd_pojia      = Rec1#role_update_attri.gd_pojia + Rec2#role_update_attri.gd_pojia,
		gd_currentHp  = Rec1#role_update_attri.gd_currentHp + Rec2#role_update_attri.gd_currentHp,
		gd_maxHp      = Rec1#role_update_attri.gd_maxHp + Rec2#role_update_attri.gd_maxHp,
		p_def         = Rec1#role_update_attri.p_def + Rec2#role_update_attri.p_def,
		m_def         = Rec1#role_update_attri.m_def + Rec2#role_update_attri.m_def,
		p_att         = Rec1#role_update_attri.p_att + Rec2#role_update_attri.p_att,
		m_att         = Rec1#role_update_attri.m_att + Rec2#role_update_attri.m_att
	}.

%% 参数为role_update_attri记录的列表，且至少要有2个记录
role_update_attri_add([Rec1, Rec2 | AttriList]) ->
	role_update_attri_add_help(AttriList, role_update_attri_add(Rec1, Rec2)).

role_update_attri_add_help([], Rec) -> Rec;
role_update_attri_add_help([Rec1 | Rest], Rec) ->
	role_update_attri_add_help(Rest, role_update_attri_add(Rec1, Rec)).
