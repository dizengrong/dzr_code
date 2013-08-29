%% 宠物的基本信息配置数据
%% 宠物 性格 

%%  1).			%% 淘气   	增加闪避   
%%  2).			%% 粗暴   	增加暴击   
%%  3).			%% 认真   	增加命中   
%%  4).			%% 倔强   	增加坚韧   
%%  5).			%% 稳重   	增加体质   
%%  6).			%% 勇敢   	增加力量   
%%  7).			%% 坚定   	增加定力   
%%  8).			%% 固执   	增加筋骨   
%%  9).			%% 冷静   	增加智力   
%%  10).		%% 坚忍   	伤害减免   
%%  11).		%% 狂妄   	伤害加成   
%%  12).		%% 反叛   	攻击加成   
%%  13).		%% 木讷   	防御加成   
%%  14).		%% 开朗   	心情增加 

-module (cfg_pet).
-compile(export_all).

%% 计算宠物二级属性的公式
%% Period: 阶数, TotalAptitude: 为对应的总资质, 
%% Con: 体质, Str: 力量或智力, Dex: 筋骨或定力
<?py for item in attr_func: ?>
${item[0]}(${item[1]}) -> trunc(${item[2]}).
<?py #endfor ?>


-record(p_pet_base_info, {
		type_id,					%% 类型
		pet_name,					%% 名称
		carry_level,				%% 可携带等级
		attack_type,				%% 攻击类型，物理:1, 魔法:2
		category_type,				%% 职业类型，"1，水族","2，兽族","3，鸟族","4，龙族"
		default_trick  = [], 		%% 默认神技
		base_str       = [0,0],		%% 力量区间
		base_int2      = [0,0],		%% 智力区间
		base_con       = [1,2],		%% 体质区间
		base_dex       = [1,2],		%% 敏捷区间 物理防 
		base_men       = [1,2],		%% 精神区间  法术防御
		heti_skill,					%% 合体技
		character,					%% 性格
		init_level     = 1,  		%% 初始等级
		init_aptitudes = [],  		%% 初始固定资质[生命资质, 物防资质, 魔防资质, 物攻资质, 魔攻资质]
		add_attack     = 0,			%% 宠物出生时加的攻击 		
		add_phy_def    = 0,			%% 宠物出生时加的物防
		add_magic_def  = 0,			%% 宠物出生时加的法防
		add_hp         = 0			%% 宠物出生时加的血
	}).

<?py for pet in pets: ?>
get_base_info(${pet[0]}) ->
	#p_pet_base_info{
		type_id        = ${pet[0]},
		pet_name       = <<"${pet[1]}">>,
		carry_level    = ${pet[2]},
		attack_type    = ${pet[3]},
		category_type  = ${pet[4]},
		
		base_str       = ${pet[5]},
		base_int2      = ${pet[6]},
		base_dex       = ${pet[7]},
		base_men       = ${pet[8]},
		base_con       = ${pet[9]},
		heti_skill     = ${pet[10]},
		character      = ${pet[11]},
		init_level     = ${pet[12]},
		init_aptitudes = ${pet[13]},
		add_attack     = ${pet[14]},
		add_phy_def    = ${pet[15]},
		add_magic_def  = ${pet[16]},
		add_hp         = ${pet[17]}
	};

<?py #endfor ?>
get_base_info(_) -> [].

%% 宠物可附身的个数上限配置
%% get_max_hidden(角色等级, 星级等级) -> 附身上限
<?py for data in max_hidden: ?>
get_max_hidden(Rolelv, VipLv) when Rolelv >= ${data[0]} orelse VipLv >= ${data[1]} -> ${data[2]};
<?py #endfor ?>
get_max_hidden(_, _) -> 0.


<?py for data in misc: ?>
%% ${data[2]}
${data[0]}() -> ${data[1]}.
<?py #endfor ?>

%% 宠物归元后得到啥物品
<?py for data in pet_back: ?>
back_to_card(${data[0]}) -> ${data[1]};
<?py #endfor ?>
%% 下面这个表示不能进行归元
back_to_card(_) -> [].
