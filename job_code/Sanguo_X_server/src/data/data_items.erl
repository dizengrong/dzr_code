-module(data_items).

-compile(export_all).

-include("common.hrl").

%% 根据npc坐标获取其坐标信息:{场景id，x坐标，y坐标}.
%% 20级大礼包，里面有各种新手必需的道具
get(1) -> 
	#cfg_item{
		cfg_ItemID      = 1,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{gold,100,1},{silver,10000,0},{5,1,1},{6,1,1},{7,1,1},{8,1,1}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 10级大礼包，里面有各种新手必需的道具
get(2) -> 
	#cfg_item{
		cfg_ItemID      = 2,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{gold,100,1},{silver,10000,0},{5,1,1},{6,1,1},{7,1,1},{8,1,1}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 1级大礼包，里面有各种新手必需的道具
get(3) -> 
	#cfg_item{
		cfg_ItemID      = 3,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{gold,100,1},{silver,10000,0},{5,1,1},{6,1,1},{7,1,1},{8,1,1}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(4) -> 
	#cfg_item{
		cfg_ItemID      = 4,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(5) -> 
	#cfg_item{
		cfg_ItemID      = 5,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(6) -> 
	#cfg_item{
		cfg_ItemID      = 6,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(7) -> 
	#cfg_item{
		cfg_ItemID      = 7,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(8) -> 
	#cfg_item{
		cfg_ItemID      = 8,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(9) -> 
	#cfg_item{
		cfg_ItemID      = 9,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(10) -> 
	#cfg_item{
		cfg_ItemID      = 10,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(11) -> 
	#cfg_item{
		cfg_ItemID      = 11,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(12) -> 
	#cfg_item{
		cfg_ItemID      = 12,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(13) -> 
	#cfg_item{
		cfg_ItemID      = 13,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(14) -> 
	#cfg_item{
		cfg_ItemID      = 14,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(15) -> 
	#cfg_item{
		cfg_ItemID      = 15,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(16) -> 
	#cfg_item{
		cfg_ItemID      = 16,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(17) -> 
	#cfg_item{
		cfg_ItemID      = 17,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(18) -> 
	#cfg_item{
		cfg_ItemID      = 18,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(19) -> 
	#cfg_item{
		cfg_ItemID      = 19,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(20) -> 
	#cfg_item{
		cfg_ItemID      = 20,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 20,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(21) -> 
	#cfg_item{
		cfg_ItemID      = 21,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 20,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(22) -> 
	#cfg_item{
		cfg_ItemID      = 22,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 20,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(23) -> 
	#cfg_item{
		cfg_ItemID      = 23,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 20,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(24) -> 
	#cfg_item{
		cfg_ItemID      = 24,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 20,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(25) -> 
	#cfg_item{
		cfg_ItemID      = 25,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 20,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(26) -> 
	#cfg_item{
		cfg_ItemID      = 26,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 20,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(27) -> 
	#cfg_item{
		cfg_ItemID      = 27,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 20,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(28) -> 
	#cfg_item{
		cfg_ItemID      = 28,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 30,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(29) -> 
	#cfg_item{
		cfg_ItemID      = 29,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 30,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(30) -> 
	#cfg_item{
		cfg_ItemID      = 30,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 30,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(31) -> 
	#cfg_item{
		cfg_ItemID      = 31,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 30,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(32) -> 
	#cfg_item{
		cfg_ItemID      = 32,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 30,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(33) -> 
	#cfg_item{
		cfg_ItemID      = 33,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 30,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(34) -> 
	#cfg_item{
		cfg_ItemID      = 34,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 30,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(35) -> 
	#cfg_item{
		cfg_ItemID      = 35,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 30,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(36) -> 
	#cfg_item{
		cfg_ItemID      = 36,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 40,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(37) -> 
	#cfg_item{
		cfg_ItemID      = 37,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 40,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(38) -> 
	#cfg_item{
		cfg_ItemID      = 38,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 40,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(39) -> 
	#cfg_item{
		cfg_ItemID      = 39,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 40,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(40) -> 
	#cfg_item{
		cfg_ItemID      = 40,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 40,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(41) -> 
	#cfg_item{
		cfg_ItemID      = 41,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 40,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(42) -> 
	#cfg_item{
		cfg_ItemID      = 42,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 40,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(43) -> 
	#cfg_item{
		cfg_ItemID      = 43,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 40,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(44) -> 
	#cfg_item{
		cfg_ItemID      = 44,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 50,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(45) -> 
	#cfg_item{
		cfg_ItemID      = 45,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 50,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(46) -> 
	#cfg_item{
		cfg_ItemID      = 46,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 50,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(47) -> 
	#cfg_item{
		cfg_ItemID      = 47,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 50,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(48) -> 
	#cfg_item{
		cfg_ItemID      = 48,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 50,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(49) -> 
	#cfg_item{
		cfg_ItemID      = 49,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 50,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(50) -> 
	#cfg_item{
		cfg_ItemID      = 50,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 50,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(51) -> 
	#cfg_item{
		cfg_ItemID      = 51,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 50,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(52) -> 
	#cfg_item{
		cfg_ItemID      = 52,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 60,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(53) -> 
	#cfg_item{
		cfg_ItemID      = 53,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 60,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(54) -> 
	#cfg_item{
		cfg_ItemID      = 54,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 60,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(55) -> 
	#cfg_item{
		cfg_ItemID      = 55,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 60,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(56) -> 
	#cfg_item{
		cfg_ItemID      = 56,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 60,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(57) -> 
	#cfg_item{
		cfg_ItemID      = 57,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 60,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(58) -> 
	#cfg_item{
		cfg_ItemID      = 58,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 60,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(59) -> 
	#cfg_item{
		cfg_ItemID      = 59,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 60,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(60) -> 
	#cfg_item{
		cfg_ItemID      = 60,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 70,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(61) -> 
	#cfg_item{
		cfg_ItemID      = 61,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 70,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(62) -> 
	#cfg_item{
		cfg_ItemID      = 62,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 70,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(63) -> 
	#cfg_item{
		cfg_ItemID      = 63,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 70,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(64) -> 
	#cfg_item{
		cfg_ItemID      = 64,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 70,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(65) -> 
	#cfg_item{
		cfg_ItemID      = 65,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 70,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(66) -> 
	#cfg_item{
		cfg_ItemID      = 66,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 70,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(67) -> 
	#cfg_item{
		cfg_ItemID      = 67,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 70,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(68) -> 
	#cfg_item{
		cfg_ItemID      = 68,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 80,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(69) -> 
	#cfg_item{
		cfg_ItemID      = 69,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 80,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(70) -> 
	#cfg_item{
		cfg_ItemID      = 70,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 80,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(71) -> 
	#cfg_item{
		cfg_ItemID      = 71,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 80,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(72) -> 
	#cfg_item{
		cfg_ItemID      = 72,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 80,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(73) -> 
	#cfg_item{
		cfg_ItemID      = 73,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 80,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(74) -> 
	#cfg_item{
		cfg_ItemID      = 74,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 80,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(75) -> 
	#cfg_item{
		cfg_ItemID      = 75,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 80,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(76) -> 
	#cfg_item{
		cfg_ItemID      = 76,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 90,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(77) -> 
	#cfg_item{
		cfg_ItemID      = 77,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 90,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(78) -> 
	#cfg_item{
		cfg_ItemID      = 78,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 90,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(79) -> 
	#cfg_item{
		cfg_ItemID      = 79,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 90,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(80) -> 
	#cfg_item{
		cfg_ItemID      = 80,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 90,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(81) -> 
	#cfg_item{
		cfg_ItemID      = 81,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 90,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(82) -> 
	#cfg_item{
		cfg_ItemID      = 82,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 90,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(83) -> 
	#cfg_item{
		cfg_ItemID      = 83,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 90,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(84) -> 
	#cfg_item{
		cfg_ItemID      = 84,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 100,
		cfg_FirstType   = 1,
		cfg_SecondType  = 2,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(85) -> 
	#cfg_item{
		cfg_ItemID      = 85,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 100,
		cfg_FirstType   = 1,
		cfg_SecondType  = 5,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(86) -> 
	#cfg_item{
		cfg_ItemID      = 86,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 100,
		cfg_FirstType   = 1,
		cfg_SecondType  = 4,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(87) -> 
	#cfg_item{
		cfg_ItemID      = 87,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 100,
		cfg_FirstType   = 1,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(88) -> 
	#cfg_item{
		cfg_ItemID      = 88,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 100,
		cfg_FirstType   = 1,
		cfg_SecondType  = 6,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(89) -> 
	#cfg_item{
		cfg_ItemID      = 89,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 100,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 2,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(90) -> 
	#cfg_item{
		cfg_ItemID      = 90,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 100,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 1,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 装备啊啊啊啊啊啊
get(91) -> 
	#cfg_item{
		cfg_ItemID      = 91,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 100,
		cfg_FirstType   = 1,
		cfg_SecondType  = 1,
		cfg_Career      = 3,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+48
get(92) -> 
	#cfg_item{
		cfg_ItemID      = 92,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 40,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+80
get(93) -> 
	#cfg_item{
		cfg_ItemID      = 93,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 80,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+127
get(94) -> 
	#cfg_item{
		cfg_ItemID      = 94,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 130,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+191
get(95) -> 
	#cfg_item{
		cfg_ItemID      = 95,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 190,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+287
get(96) -> 
	#cfg_item{
		cfg_ItemID      = 96,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 280,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+431
get(97) -> 
	#cfg_item{
		cfg_ItemID      = 97,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 430,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+637
get(98) -> 
	#cfg_item{
		cfg_ItemID      = 98,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 640,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+908
get(99) -> 
	#cfg_item{
		cfg_ItemID      = 99,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 920,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+1243
get(100) -> 
	#cfg_item{
		cfg_ItemID      = 100,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 1270,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+1593
get(101) -> 
	#cfg_item{
		cfg_ItemID      = 101,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 1600,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法攻+48
get(102) -> 
	#cfg_item{
		cfg_ItemID      = 102,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 40		%% 魔攻
		 }
	};

%% 法攻+80
get(103) -> 
	#cfg_item{
		cfg_ItemID      = 103,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 80		%% 魔攻
		 }
	};

%% 法攻+127
get(104) -> 
	#cfg_item{
		cfg_ItemID      = 104,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 130		%% 魔攻
		 }
	};

%% 法攻+191
get(105) -> 
	#cfg_item{
		cfg_ItemID      = 105,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 190		%% 魔攻
		 }
	};

%% 法攻+287
get(106) -> 
	#cfg_item{
		cfg_ItemID      = 106,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 280		%% 魔攻
		 }
	};

%% 法攻+431
get(107) -> 
	#cfg_item{
		cfg_ItemID      = 107,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 430		%% 魔攻
		 }
	};

%% 法攻+637
get(108) -> 
	#cfg_item{
		cfg_ItemID      = 108,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 640		%% 魔攻
		 }
	};

%% 法攻+908
get(109) -> 
	#cfg_item{
		cfg_ItemID      = 109,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 920		%% 魔攻
		 }
	};

%% 法攻+1243
get(110) -> 
	#cfg_item{
		cfg_ItemID      = 110,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 1270		%% 魔攻
		 }
	};

%% 法攻+1593
get(111) -> 
	#cfg_item{
		cfg_ItemID      = 111,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 1600		%% 魔攻
		 }
	};

%% 物防+26
get(112) -> 
	#cfg_item{
		cfg_ItemID      = 112,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 20,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+43
get(113) -> 
	#cfg_item{
		cfg_ItemID      = 113,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 40,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+69
get(114) -> 
	#cfg_item{
		cfg_ItemID      = 114,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 60,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+103
get(115) -> 
	#cfg_item{
		cfg_ItemID      = 115,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 100,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+155
get(116) -> 
	#cfg_item{
		cfg_ItemID      = 116,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 150,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+232
get(117) -> 
	#cfg_item{
		cfg_ItemID      = 117,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 230,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+344
get(118) -> 
	#cfg_item{
		cfg_ItemID      = 118,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 340,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+491
get(119) -> 
	#cfg_item{
		cfg_ItemID      = 119,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 500,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+671
get(120) -> 
	#cfg_item{
		cfg_ItemID      = 120,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 690,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+860
get(121) -> 
	#cfg_item{
		cfg_ItemID      = 121,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 860,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+26
get(122) -> 
	#cfg_item{
		cfg_ItemID      = 122,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 20,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+43
get(123) -> 
	#cfg_item{
		cfg_ItemID      = 123,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 40,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+69
get(124) -> 
	#cfg_item{
		cfg_ItemID      = 124,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 60,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+103
get(125) -> 
	#cfg_item{
		cfg_ItemID      = 125,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 100,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+155
get(126) -> 
	#cfg_item{
		cfg_ItemID      = 126,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 150,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+232
get(127) -> 
	#cfg_item{
		cfg_ItemID      = 127,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 230,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+344
get(128) -> 
	#cfg_item{
		cfg_ItemID      = 128,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 340,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+491
get(129) -> 
	#cfg_item{
		cfg_ItemID      = 129,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 500,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+671
get(130) -> 
	#cfg_item{
		cfg_ItemID      = 130,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 690,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+860
get(131) -> 
	#cfg_item{
		cfg_ItemID      = 131,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 860,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+36
get(132) -> 
	#cfg_item{
		cfg_ItemID      = 132,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 40,			%% 当前血量
			gd_maxHp      = 40,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+60
get(133) -> 
	#cfg_item{
		cfg_ItemID      = 133,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 70,			%% 当前血量
			gd_maxHp      = 70,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+96
get(134) -> 
	#cfg_item{
		cfg_ItemID      = 134,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 120,			%% 当前血量
			gd_maxHp      = 120,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+144
get(135) -> 
	#cfg_item{
		cfg_ItemID      = 135,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 180,			%% 当前血量
			gd_maxHp      = 180,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+216
get(136) -> 
	#cfg_item{
		cfg_ItemID      = 136,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 270,			%% 当前血量
			gd_maxHp      = 270,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+323
get(137) -> 
	#cfg_item{
		cfg_ItemID      = 137,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 400,			%% 当前血量
			gd_maxHp      = 400,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+478
get(138) -> 
	#cfg_item{
		cfg_ItemID      = 138,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 600,			%% 当前血量
			gd_maxHp      = 600,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+681
get(139) -> 
	#cfg_item{
		cfg_ItemID      = 139,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 870,			%% 当前血量
			gd_maxHp      = 870,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+932
get(140) -> 
	#cfg_item{
		cfg_ItemID      = 140,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 1200,			%% 当前血量
			gd_maxHp      = 1200,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+1195
get(141) -> 
	#cfg_item{
		cfg_ItemID      = 141,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 1500,			%% 当前血量
			gd_maxHp      = 1500,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+49
get(142) -> 
	#cfg_item{
		cfg_ItemID      = 142,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 10,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+82
get(143) -> 
	#cfg_item{
		cfg_ItemID      = 143,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 30,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+131
get(144) -> 
	#cfg_item{
		cfg_ItemID      = 144,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 40,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+197
get(145) -> 
	#cfg_item{
		cfg_ItemID      = 145,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 60,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+295
get(146) -> 
	#cfg_item{
		cfg_ItemID      = 146,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 100,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+442
get(147) -> 
	#cfg_item{
		cfg_ItemID      = 147,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 150,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+655
get(148) -> 
	#cfg_item{
		cfg_ItemID      = 148,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 220,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+934
get(149) -> 
	#cfg_item{
		cfg_ItemID      = 149,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 320,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+1278
get(150) -> 
	#cfg_item{
		cfg_ItemID      = 150,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 430,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+1638
get(151) -> 
	#cfg_item{
		cfg_ItemID      = 151,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 550,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+5
get(152) -> 
	#cfg_item{
		cfg_ItemID      = 152,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 5,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+8
get(153) -> 
	#cfg_item{
		cfg_ItemID      = 153,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 8,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+11
get(154) -> 
	#cfg_item{
		cfg_ItemID      = 154,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 11,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+18
get(155) -> 
	#cfg_item{
		cfg_ItemID      = 155,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 18,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+23
get(156) -> 
	#cfg_item{
		cfg_ItemID      = 156,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 23,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+29
get(157) -> 
	#cfg_item{
		cfg_ItemID      = 157,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 29,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+41
get(158) -> 
	#cfg_item{
		cfg_ItemID      = 158,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 39,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+57
get(159) -> 
	#cfg_item{
		cfg_ItemID      = 159,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 57,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+78
get(160) -> 
	#cfg_item{
		cfg_ItemID      = 160,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 78,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+101
get(161) -> 
	#cfg_item{
		cfg_ItemID      = 161,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 100,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+6
get(162) -> 
	#cfg_item{
		cfg_ItemID      = 162,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 5,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+10
get(163) -> 
	#cfg_item{
		cfg_ItemID      = 163,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 8,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+16
get(164) -> 
	#cfg_item{
		cfg_ItemID      = 164,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 14,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+27
get(165) -> 
	#cfg_item{
		cfg_ItemID      = 165,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 26,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+41
get(166) -> 
	#cfg_item{
		cfg_ItemID      = 166,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 39,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+60
get(167) -> 
	#cfg_item{
		cfg_ItemID      = 167,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 60,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+90
get(168) -> 
	#cfg_item{
		cfg_ItemID      = 168,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 88,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+127
get(169) -> 
	#cfg_item{
		cfg_ItemID      = 169,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 129,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+175
get(170) -> 
	#cfg_item{
		cfg_ItemID      = 170,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 178,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+224
get(171) -> 
	#cfg_item{
		cfg_ItemID      = 171,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 220,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+5
get(172) -> 
	#cfg_item{
		cfg_ItemID      = 172,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 5,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+8
get(173) -> 
	#cfg_item{
		cfg_ItemID      = 173,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 8,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+11
get(174) -> 
	#cfg_item{
		cfg_ItemID      = 174,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 11,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+18
get(175) -> 
	#cfg_item{
		cfg_ItemID      = 175,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 18,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+23
get(176) -> 
	#cfg_item{
		cfg_ItemID      = 176,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 23,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+29
get(177) -> 
	#cfg_item{
		cfg_ItemID      = 177,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 29,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+41
get(178) -> 
	#cfg_item{
		cfg_ItemID      = 178,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 39,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+57
get(179) -> 
	#cfg_item{
		cfg_ItemID      = 179,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 57,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+78
get(180) -> 
	#cfg_item{
		cfg_ItemID      = 180,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 78,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+101
get(181) -> 
	#cfg_item{
		cfg_ItemID      = 181,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 100,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(182) -> 
	#cfg_item{
		cfg_ItemID      = 182,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(183) -> 
	#cfg_item{
		cfg_ItemID      = 183,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(184) -> 
	#cfg_item{
		cfg_ItemID      = 184,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(185) -> 
	#cfg_item{
		cfg_ItemID      = 185,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(186) -> 
	#cfg_item{
		cfg_ItemID      = 186,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(187) -> 
	#cfg_item{
		cfg_ItemID      = 187,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(188) -> 
	#cfg_item{
		cfg_ItemID      = 188,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(189) -> 
	#cfg_item{
		cfg_ItemID      = 189,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(190) -> 
	#cfg_item{
		cfg_ItemID      = 190,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(191) -> 
	#cfg_item{
		cfg_ItemID      = 191,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 50000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(192) -> 
	#cfg_item{
		cfg_ItemID      = 192,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(193) -> 
	#cfg_item{
		cfg_ItemID      = 193,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(194) -> 
	#cfg_item{
		cfg_ItemID      = 194,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(195) -> 
	#cfg_item{
		cfg_ItemID      = 195,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(196) -> 
	#cfg_item{
		cfg_ItemID      = 196,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(197) -> 
	#cfg_item{
		cfg_ItemID      = 197,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(198) -> 
	#cfg_item{
		cfg_ItemID      = 198,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(199) -> 
	#cfg_item{
		cfg_ItemID      = 199,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(200) -> 
	#cfg_item{
		cfg_ItemID      = 200,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(201) -> 
	#cfg_item{
		cfg_ItemID      = 201,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(202) -> 
	#cfg_item{
		cfg_ItemID      = 202,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(203) -> 
	#cfg_item{
		cfg_ItemID      = 203,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(204) -> 
	#cfg_item{
		cfg_ItemID      = 204,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(205) -> 
	#cfg_item{
		cfg_ItemID      = 205,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 60000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(206) -> 
	#cfg_item{
		cfg_ItemID      = 206,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 75000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(207) -> 
	#cfg_item{
		cfg_ItemID      = 207,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 75000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(208) -> 
	#cfg_item{
		cfg_ItemID      = 208,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 75000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(209) -> 
	#cfg_item{
		cfg_ItemID      = 209,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 75000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(210) -> 
	#cfg_item{
		cfg_ItemID      = 210,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 75000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(211) -> 
	#cfg_item{
		cfg_ItemID      = 211,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 75000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(212) -> 
	#cfg_item{
		cfg_ItemID      = 212,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 75000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(213) -> 
	#cfg_item{
		cfg_ItemID      = 213,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 75000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(214) -> 
	#cfg_item{
		cfg_ItemID      = 214,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 100000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(215) -> 
	#cfg_item{
		cfg_ItemID      = 215,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 100000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(216) -> 
	#cfg_item{
		cfg_ItemID      = 216,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 100000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(217) -> 
	#cfg_item{
		cfg_ItemID      = 217,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 100000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(218) -> 
	#cfg_item{
		cfg_ItemID      = 218,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 100000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(219) -> 
	#cfg_item{
		cfg_ItemID      = 219,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 100000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(220) -> 
	#cfg_item{
		cfg_ItemID      = 220,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 100000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(221) -> 
	#cfg_item{
		cfg_ItemID      = 221,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 100000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(222) -> 
	#cfg_item{
		cfg_ItemID      = 222,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 125000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(223) -> 
	#cfg_item{
		cfg_ItemID      = 223,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 125000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(224) -> 
	#cfg_item{
		cfg_ItemID      = 224,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 125000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(225) -> 
	#cfg_item{
		cfg_ItemID      = 225,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 125000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(226) -> 
	#cfg_item{
		cfg_ItemID      = 226,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 125000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(227) -> 
	#cfg_item{
		cfg_ItemID      = 227,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 125000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(228) -> 
	#cfg_item{
		cfg_ItemID      = 228,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 125000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(229) -> 
	#cfg_item{
		cfg_ItemID      = 229,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 125000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(230) -> 
	#cfg_item{
		cfg_ItemID      = 230,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 150000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(231) -> 
	#cfg_item{
		cfg_ItemID      = 231,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 150000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(232) -> 
	#cfg_item{
		cfg_ItemID      = 232,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 150000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(233) -> 
	#cfg_item{
		cfg_ItemID      = 233,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 150000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(234) -> 
	#cfg_item{
		cfg_ItemID      = 234,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 150000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(235) -> 
	#cfg_item{
		cfg_ItemID      = 235,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 150000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(236) -> 
	#cfg_item{
		cfg_ItemID      = 236,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 150000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(237) -> 
	#cfg_item{
		cfg_ItemID      = 237,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 150000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(238) -> 
	#cfg_item{
		cfg_ItemID      = 238,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 175000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(239) -> 
	#cfg_item{
		cfg_ItemID      = 239,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 175000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(240) -> 
	#cfg_item{
		cfg_ItemID      = 240,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 175000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(241) -> 
	#cfg_item{
		cfg_ItemID      = 241,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 175000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(242) -> 
	#cfg_item{
		cfg_ItemID      = 242,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 175000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(243) -> 
	#cfg_item{
		cfg_ItemID      = 243,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 175000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(244) -> 
	#cfg_item{
		cfg_ItemID      = 244,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 175000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(245) -> 
	#cfg_item{
		cfg_ItemID      = 245,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 175000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(246) -> 
	#cfg_item{
		cfg_ItemID      = 246,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 200000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(247) -> 
	#cfg_item{
		cfg_ItemID      = 247,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 200000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(248) -> 
	#cfg_item{
		cfg_ItemID      = 248,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 200000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(249) -> 
	#cfg_item{
		cfg_ItemID      = 249,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 200000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(250) -> 
	#cfg_item{
		cfg_ItemID      = 250,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 200000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(251) -> 
	#cfg_item{
		cfg_ItemID      = 251,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 200000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(252) -> 
	#cfg_item{
		cfg_ItemID      = 252,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 200000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(253) -> 
	#cfg_item{
		cfg_ItemID      = 253,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 200000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(254) -> 
	#cfg_item{
		cfg_ItemID      = 254,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 250000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(255) -> 
	#cfg_item{
		cfg_ItemID      = 255,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 250000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(256) -> 
	#cfg_item{
		cfg_ItemID      = 256,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 250000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(257) -> 
	#cfg_item{
		cfg_ItemID      = 257,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 250000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(258) -> 
	#cfg_item{
		cfg_ItemID      = 258,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 250000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(259) -> 
	#cfg_item{
		cfg_ItemID      = 259,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 250000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(260) -> 
	#cfg_item{
		cfg_ItemID      = 260,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 250000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(261) -> 
	#cfg_item{
		cfg_ItemID      = 261,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 250000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(262) -> 
	#cfg_item{
		cfg_ItemID      = 262,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(263) -> 
	#cfg_item{
		cfg_ItemID      = 263,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(264) -> 
	#cfg_item{
		cfg_ItemID      = 264,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(265) -> 
	#cfg_item{
		cfg_ItemID      = 265,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(266) -> 
	#cfg_item{
		cfg_ItemID      = 266,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(267) -> 
	#cfg_item{
		cfg_ItemID      = 267,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(268) -> 
	#cfg_item{
		cfg_ItemID      = 268,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(269) -> 
	#cfg_item{
		cfg_ItemID      = 269,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(270) -> 
	#cfg_item{
		cfg_ItemID      = 270,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(271) -> 
	#cfg_item{
		cfg_ItemID      = 271,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(272) -> 
	#cfg_item{
		cfg_ItemID      = 272,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(273) -> 
	#cfg_item{
		cfg_ItemID      = 273,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(274) -> 
	#cfg_item{
		cfg_ItemID      = 274,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(275) -> 
	#cfg_item{
		cfg_ItemID      = 275,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(276) -> 
	#cfg_item{
		cfg_ItemID      = 276,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(277) -> 
	#cfg_item{
		cfg_ItemID      = 277,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(278) -> 
	#cfg_item{
		cfg_ItemID      = 278,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(279) -> 
	#cfg_item{
		cfg_ItemID      = 279,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(280) -> 
	#cfg_item{
		cfg_ItemID      = 280,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(281) -> 
	#cfg_item{
		cfg_ItemID      = 281,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(282) -> 
	#cfg_item{
		cfg_ItemID      = 282,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(283) -> 
	#cfg_item{
		cfg_ItemID      = 283,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(284) -> 
	#cfg_item{
		cfg_ItemID      = 284,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(285) -> 
	#cfg_item{
		cfg_ItemID      = 285,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(286) -> 
	#cfg_item{
		cfg_ItemID      = 286,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(287) -> 
	#cfg_item{
		cfg_ItemID      = 287,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(288) -> 
	#cfg_item{
		cfg_ItemID      = 288,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(289) -> 
	#cfg_item{
		cfg_ItemID      = 289,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(290) -> 
	#cfg_item{
		cfg_ItemID      = 290,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(291) -> 
	#cfg_item{
		cfg_ItemID      = 291,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(292) -> 
	#cfg_item{
		cfg_ItemID      = 292,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(293) -> 
	#cfg_item{
		cfg_ItemID      = 293,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(294) -> 
	#cfg_item{
		cfg_ItemID      = 294,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(295) -> 
	#cfg_item{
		cfg_ItemID      = 295,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 可兑换10000银币
get(296) -> 
	#cfg_item{
		cfg_ItemID      = 296,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 1,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 寻仙过程中产生的垃圾
get(297) -> 
	#cfg_item{
		cfg_ItemID      = 297,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 9,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 0,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 翅膀
get(298) -> 
	#cfg_item{
		cfg_ItemID      = 298,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 25,
		cfg_FirstType   = 1,
		cfg_SecondType  = 7,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 翅膀
get(299) -> 
	#cfg_item{
		cfg_ItemID      = 299,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 35,
		cfg_FirstType   = 1,
		cfg_SecondType  = 7,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 翅膀
get(300) -> 
	#cfg_item{
		cfg_ItemID      = 300,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 45,
		cfg_FirstType   = 1,
		cfg_SecondType  = 7,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 翅膀
get(301) -> 
	#cfg_item{
		cfg_ItemID      = 301,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 55,
		cfg_FirstType   = 1,
		cfg_SecondType  = 7,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 翅膀
get(302) -> 
	#cfg_item{
		cfg_ItemID      = 302,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 65,
		cfg_FirstType   = 1,
		cfg_SecondType  = 7,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 翅膀
get(303) -> 
	#cfg_item{
		cfg_ItemID      = 303,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 75,
		cfg_FirstType   = 1,
		cfg_SecondType  = 7,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 翅膀
get(304) -> 
	#cfg_item{
		cfg_ItemID      = 304,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 85,
		cfg_FirstType   = 1,
		cfg_SecondType  = 7,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 翅膀
get(305) -> 
	#cfg_item{
		cfg_ItemID      = 305,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 95,
		cfg_FirstType   = 1,
		cfg_SecondType  = 7,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 1,
		cfg_IsUpgrate   = 1,
		cfg_IsUpquality = 1,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(306) -> 
	#cfg_item{
		cfg_ItemID      = 306,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(307) -> 
	#cfg_item{
		cfg_ItemID      = 307,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(308) -> 
	#cfg_item{
		cfg_ItemID      = 308,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(309) -> 
	#cfg_item{
		cfg_ItemID      = 309,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(310) -> 
	#cfg_item{
		cfg_ItemID      = 310,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(311) -> 
	#cfg_item{
		cfg_ItemID      = 311,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(312) -> 
	#cfg_item{
		cfg_ItemID      = 312,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(313) -> 
	#cfg_item{
		cfg_ItemID      = 313,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(314) -> 
	#cfg_item{
		cfg_ItemID      = 314,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 将宝石雕刻成更厉害的宝石
get(315) -> 
	#cfg_item{
		cfg_ItemID      = 315,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 11,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+69
get(316) -> 
	#cfg_item{
		cfg_ItemID      = 316,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 60,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+114
get(317) -> 
	#cfg_item{
		cfg_ItemID      = 317,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 110,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+182
get(318) -> 
	#cfg_item{
		cfg_ItemID      = 318,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 180,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+273
get(319) -> 
	#cfg_item{
		cfg_ItemID      = 319,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 270,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+410
get(320) -> 
	#cfg_item{
		cfg_ItemID      = 320,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 400,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+615
get(321) -> 
	#cfg_item{
		cfg_ItemID      = 321,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 610,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+910
get(322) -> 
	#cfg_item{
		cfg_ItemID      = 322,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 910,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+1297
get(323) -> 
	#cfg_item{
		cfg_ItemID      = 323,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 1320,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+1775
get(324) -> 
	#cfg_item{
		cfg_ItemID      = 324,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 1820,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物攻+2275
get(325) -> 
	#cfg_item{
		cfg_ItemID      = 325,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 12,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 2280,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法攻+69
get(326) -> 
	#cfg_item{
		cfg_ItemID      = 326,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 60		%% 魔攻
		 }
	};

%% 法攻+114
get(327) -> 
	#cfg_item{
		cfg_ItemID      = 327,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 110		%% 魔攻
		 }
	};

%% 法攻+182
get(328) -> 
	#cfg_item{
		cfg_ItemID      = 328,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 180		%% 魔攻
		 }
	};

%% 法攻+273
get(329) -> 
	#cfg_item{
		cfg_ItemID      = 329,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 270		%% 魔攻
		 }
	};

%% 法攻+410
get(330) -> 
	#cfg_item{
		cfg_ItemID      = 330,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 400		%% 魔攻
		 }
	};

%% 法攻+615
get(331) -> 
	#cfg_item{
		cfg_ItemID      = 331,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 610		%% 魔攻
		 }
	};

%% 法攻+910
get(332) -> 
	#cfg_item{
		cfg_ItemID      = 332,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 910		%% 魔攻
		 }
	};

%% 法攻+1297
get(333) -> 
	#cfg_item{
		cfg_ItemID      = 333,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 1320		%% 魔攻
		 }
	};

%% 法攻+1775
get(334) -> 
	#cfg_item{
		cfg_ItemID      = 334,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 1820		%% 魔攻
		 }
	};

%% 法攻+2275
get(335) -> 
	#cfg_item{
		cfg_ItemID      = 335,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 13,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 2280		%% 魔攻
		 }
	};

%% 物防+37
get(336) -> 
	#cfg_item{
		cfg_ItemID      = 336,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 30,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+61
get(337) -> 
	#cfg_item{
		cfg_ItemID      = 337,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 60,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+98
get(338) -> 
	#cfg_item{
		cfg_ItemID      = 338,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 90,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+147
get(339) -> 
	#cfg_item{
		cfg_ItemID      = 339,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 140,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+221
get(340) -> 
	#cfg_item{
		cfg_ItemID      = 340,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 220,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+332
get(341) -> 
	#cfg_item{
		cfg_ItemID      = 341,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 330,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+492
get(342) -> 
	#cfg_item{
		cfg_ItemID      = 342,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 490,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+701
get(343) -> 
	#cfg_item{
		cfg_ItemID      = 343,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 710,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+959
get(344) -> 
	#cfg_item{
		cfg_ItemID      = 344,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 980,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 物防+1229
get(345) -> 
	#cfg_item{
		cfg_ItemID      = 345,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 14,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 1230,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+37
get(346) -> 
	#cfg_item{
		cfg_ItemID      = 346,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 30,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+61
get(347) -> 
	#cfg_item{
		cfg_ItemID      = 347,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 60,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+98
get(348) -> 
	#cfg_item{
		cfg_ItemID      = 348,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 90,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+147
get(349) -> 
	#cfg_item{
		cfg_ItemID      = 349,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 140,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+221
get(350) -> 
	#cfg_item{
		cfg_ItemID      = 350,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 220,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+332
get(351) -> 
	#cfg_item{
		cfg_ItemID      = 351,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 330,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+492
get(352) -> 
	#cfg_item{
		cfg_ItemID      = 352,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 490,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+701
get(353) -> 
	#cfg_item{
		cfg_ItemID      = 353,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 710,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+959
get(354) -> 
	#cfg_item{
		cfg_ItemID      = 354,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 980,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 法防+1229
get(355) -> 
	#cfg_item{
		cfg_ItemID      = 355,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 15,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 1229,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+52
get(356) -> 
	#cfg_item{
		cfg_ItemID      = 356,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 60,			%% 当前血量
			gd_maxHp      = 60,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+86
get(357) -> 
	#cfg_item{
		cfg_ItemID      = 357,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 100,			%% 当前血量
			gd_maxHp      = 100,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+137
get(358) -> 
	#cfg_item{
		cfg_ItemID      = 358,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 170,			%% 当前血量
			gd_maxHp      = 170,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+205
get(359) -> 
	#cfg_item{
		cfg_ItemID      = 359,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 250,			%% 当前血量
			gd_maxHp      = 250,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+308
get(360) -> 
	#cfg_item{
		cfg_ItemID      = 360,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 380,			%% 当前血量
			gd_maxHp      = 380,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+461
get(361) -> 
	#cfg_item{
		cfg_ItemID      = 361,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 570,			%% 当前血量
			gd_maxHp      = 570,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+683
get(362) -> 
	#cfg_item{
		cfg_ItemID      = 362,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 850,			%% 当前血量
			gd_maxHp      = 850,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+973
get(363) -> 
	#cfg_item{
		cfg_ItemID      = 363,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 1240,			%% 当前血量
			gd_maxHp      = 1240,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+1332
get(364) -> 
	#cfg_item{
		cfg_ItemID      = 364,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 1710,			%% 当前血量
			gd_maxHp      = 1710,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 气血+1707
get(365) -> 
	#cfg_item{
		cfg_ItemID      = 365,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 16,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 2140,			%% 当前血量
			gd_maxHp      = 2140,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+70
get(366) -> 
	#cfg_item{
		cfg_ItemID      = 366,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 20,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+117
get(367) -> 
	#cfg_item{
		cfg_ItemID      = 367,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 40,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+187
get(368) -> 
	#cfg_item{
		cfg_ItemID      = 368,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 60,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+281
get(369) -> 
	#cfg_item{
		cfg_ItemID      = 369,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 90,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+421
get(370) -> 
	#cfg_item{
		cfg_ItemID      = 370,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 140,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+632
get(371) -> 
	#cfg_item{
		cfg_ItemID      = 371,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 210,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+936
get(372) -> 
	#cfg_item{
		cfg_ItemID      = 372,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 310,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+1334
get(373) -> 
	#cfg_item{
		cfg_ItemID      = 373,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 450,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+1825
get(374) -> 
	#cfg_item{
		cfg_ItemID      = 374,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 620,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 速度+2340
get(375) -> 
	#cfg_item{
		cfg_ItemID      = 375,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 17,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 780,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+8
get(376) -> 
	#cfg_item{
		cfg_ItemID      = 376,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 8,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+13
get(377) -> 
	#cfg_item{
		cfg_ItemID      = 377,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 13,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+19
get(378) -> 
	#cfg_item{
		cfg_ItemID      = 378,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 19,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+26
get(379) -> 
	#cfg_item{
		cfg_ItemID      = 379,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 26,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+33
get(380) -> 
	#cfg_item{
		cfg_ItemID      = 380,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 33,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+42
get(381) -> 
	#cfg_item{
		cfg_ItemID      = 381,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 42,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+58
get(382) -> 
	#cfg_item{
		cfg_ItemID      = 382,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 55,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+82
get(383) -> 
	#cfg_item{
		cfg_ItemID      = 383,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 81,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+112
get(384) -> 
	#cfg_item{
		cfg_ItemID      = 384,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 111,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 暴击+144
get(385) -> 
	#cfg_item{
		cfg_ItemID      = 385,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 18,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 140,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+10
get(386) -> 
	#cfg_item{
		cfg_ItemID      = 386,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 8,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+16
get(387) -> 
	#cfg_item{
		cfg_ItemID      = 387,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 14,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+26
get(388) -> 
	#cfg_item{
		cfg_ItemID      = 388,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 24,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+38
get(389) -> 
	#cfg_item{
		cfg_ItemID      = 389,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 37,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+58
get(390) -> 
	#cfg_item{
		cfg_ItemID      = 390,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 56,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+86
get(391) -> 
	#cfg_item{
		cfg_ItemID      = 391,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 85,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+128
get(392) -> 
	#cfg_item{
		cfg_ItemID      = 392,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 126,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+182
get(393) -> 
	#cfg_item{
		cfg_ItemID      = 393,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 184,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+250
get(394) -> 
	#cfg_item{
		cfg_ItemID      = 394,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 254,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 格挡+320
get(395) -> 
	#cfg_item{
		cfg_ItemID      = 395,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 19,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 320,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+8
get(396) -> 
	#cfg_item{
		cfg_ItemID      = 396,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 1,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 8,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+13
get(397) -> 
	#cfg_item{
		cfg_ItemID      = 397,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 2,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 13,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+19
get(398) -> 
	#cfg_item{
		cfg_ItemID      = 398,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 3,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 19,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+26
get(399) -> 
	#cfg_item{
		cfg_ItemID      = 399,
		cfg_GradeLevel  = 2,
		cfg_RoleLevel   = 4,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 26,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+33
get(400) -> 
	#cfg_item{
		cfg_ItemID      = 400,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 5,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 33,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+42
get(401) -> 
	#cfg_item{
		cfg_ItemID      = 401,
		cfg_GradeLevel  = 3,
		cfg_RoleLevel   = 6,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 42,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+58
get(402) -> 
	#cfg_item{
		cfg_ItemID      = 402,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 7,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 55,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+82
get(403) -> 
	#cfg_item{
		cfg_ItemID      = 403,
		cfg_GradeLevel  = 4,
		cfg_RoleLevel   = 8,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 81,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+112
get(404) -> 
	#cfg_item{
		cfg_ItemID      = 404,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 9,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 111,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 命中+144
get(405) -> 
	#cfg_item{
		cfg_ItemID      = 405,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 10,
		cfg_FirstType   = 2,
		cfg_SecondType  = 20,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 1,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 140,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(406) -> 
	#cfg_item{
		cfg_ItemID      = 406,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 300000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(407) -> 
	#cfg_item{
		cfg_ItemID      = 407,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 300000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(408) -> 
	#cfg_item{
		cfg_ItemID      = 408,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 300000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(409) -> 
	#cfg_item{
		cfg_ItemID      = 409,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 300000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(410) -> 
	#cfg_item{
		cfg_ItemID      = 410,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 300000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(411) -> 
	#cfg_item{
		cfg_ItemID      = 411,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 300000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(412) -> 
	#cfg_item{
		cfg_ItemID      = 412,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 300000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 
get(413) -> 
	#cfg_item{
		cfg_ItemID      = 413,
		cfg_GradeLevel  = 5,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 10,
		cfg_Career      = 0,
		cfg_BuySilver   = 300000,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(414) -> 
	#cfg_item{
		cfg_ItemID      = 414,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,100000,0},{silver,50000,0},{popularity,20,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(415) -> 
	#cfg_item{
		cfg_ItemID      = 415,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,150000,0},{silver,70000,0},{popularity,40,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(416) -> 
	#cfg_item{
		cfg_ItemID      = 416,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,200000,0},{silver,100000,0},{popularity,60,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(417) -> 
	#cfg_item{
		cfg_ItemID      = 417,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,250000,0},{silver,150000,0},{popularity,80,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(418) -> 
	#cfg_item{
		cfg_ItemID      = 418,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,300000,0},{silver,180000,0},{popularity,100,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(419) -> 
	#cfg_item{
		cfg_ItemID      = 419,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,350000,0},{silver,220000,0},{popularity,120,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(420) -> 
	#cfg_item{
		cfg_ItemID      = 420,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,400000,0},{silver,260000,0},{popularity,140,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(421) -> 
	#cfg_item{
		cfg_ItemID      = 421,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,450000,0},{silver,300000,0},{popularity,160,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(422) -> 
	#cfg_item{
		cfg_ItemID      = 422,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,500000,0},{silver,350000,0},{popularity,180,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 战神塔霸主的奖励礼包
get(423) -> 
	#cfg_item{
		cfg_ItemID      = 423,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 2,
		cfg_SecondType  = 3,
		cfg_Career      = 0,
		cfg_BuySilver   = 100,
		cfg_SellSilver  = 100,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 10,
		cfg_UseEffect   = [{exp,550000,0},{silver,400000,0},{popularity,200,0}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 小喇叭
get(424) -> 
	#cfg_item{
		cfg_ItemID      = 424,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 1,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 0,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 99,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 30级大礼包，里面有各种新手必需的道具
get(425) -> 
	#cfg_item{
		cfg_ItemID      = 425,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{gold,100,1},{silver,10000,0},{5,1,1},{6,1,1},{7,1,1},{8,1,1}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 使用之后，可以将技能【背水一战】提升到二级
get(426) -> 
	#cfg_item{
		cfg_ItemID      = 426,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{skill,106001,02}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 使用之后，可以将技能【浴血狂击】提升到二级
get(427) -> 
	#cfg_item{
		cfg_ItemID      = 427,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{skill,107001,02}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 使用之后，可以将技能【暴怒冲锋】提升到二级
get(428) -> 
	#cfg_item{
		cfg_ItemID      = 428,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{skill,111001,02}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 使用之后，可以将技能【乘胜追击】提升到二级
get(429) -> 
	#cfg_item{
		cfg_ItemID      = 429,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{skill,112001,02}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 使用之后，可以将技能【雷光咒】提升到二级
get(430) -> 
	#cfg_item{
		cfg_ItemID      = 430,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{skill,116001,02}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 使用之后，可以将技能【强兵咒】提升到二级
get(431) -> 
	#cfg_item{
		cfg_ItemID      = 431,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{skill,117001,02}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 可以使角色装备的武器提升到【精良】品质
get(432) -> 
	#cfg_item{
		cfg_ItemID      = 432,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 0,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	};

%% 想一夜暴富？那就来寻宝吧！
get(433) -> 
	#cfg_item{
		cfg_ItemID      = 433,
		cfg_GradeLevel  = 1,
		cfg_RoleLevel   = 0,
		cfg_FirstType   = 3,
		cfg_SecondType  = 21,
		cfg_Career      = 0,
		cfg_BuySilver   = 0,
		cfg_SellSilver  = 0,
		cfg_BuyGold     = 0,
		cfg_IsThrow     = 1,
		cfg_IsUse       = 1,
		cfg_IsXilian    = 0,
		cfg_IsUpgrate   = 0,
		cfg_IsUpquality = 0,
		cfg_StackMax    = 1,
		cfg_UseEffect   = [{wlsd,433,1}],
	    cfg_AttrInfo   = #role_update_attri{
			gd_liliang    = 0,			%% 腕力
			gd_yuansheng  = 0,			%% 元神
			gd_tipo       = 0,			%% 体魄
			gd_minjie     = 0,			%% 敏捷	
			
			gd_speed      = 0,			%% 攻击速度
			gd_baoji      = 0,			%% 暴击
			gd_shanbi     = 0,			%% 闪避
			gd_gedang     = 0,			%% 格挡
			gd_mingzhong  = 0,			%% 命中率
			gd_zhiming    = 0,			%% 致命
			gd_xingyun    = 0,			%% 幸运
			gd_fanji      = 0,			%% 反击
			gd_pojia      = 0,			%% 破甲
			
			gd_currentHp  = 0,			%% 当前血量
			gd_maxHp      = 0,			%% 最大血量
			p_def         = 0,		%% 物理防御
			m_def         = 0,		%% 魔法防御
			p_att         = 0,		%% 攻击力
			m_att         = 0		%% 魔攻
		 }
	}.


%%================================================
%% 获取装备孔数（与装备强化等级有关） get_equip_hole_num(装备强化级别) -> 孔数
get_equip_hole_num(IntensifyLevel) when IntensifyLevel >= 13 -> 5;

get_equip_hole_num(IntensifyLevel) when IntensifyLevel >= 10 -> 4;

get_equip_hole_num(IntensifyLevel) when IntensifyLevel >= 7 -> 3;

get_equip_hole_num(IntensifyLevel) when IntensifyLevel >= 4 -> 2;

get_equip_hole_num(IntensifyLevel) when IntensifyLevel >= 1 -> 1;

get_equip_hole_num(_IntensifyLevel) -> 0.

%%================================================
%% 获取装备能镶嵌的宝石种类列表（与装备类型有关）get_item_jewel_list() -> 列表
get_item_jewel_list() ->[
		{1,12},{1,13},{1,18},{1,20},
		{2,14},{2,15},{2,16},
		{3,14},{3,15},{3,16},
		{5,14},{5,15},{5,16},
		{6,14},{6,15},{6,16},
		{4,14},{4,15},{4,17},
		{7,17},{7,18},{7,19},{7,20}
		].

%%================================================
%% 格子扩充费用：get_extend(格子类型) -> {基价, 递增价, 最高价}
%% 背包格子扩展消耗
get_extend(1) -> {0, 1, 30};

%% 仓库格子扩张消耗
get_extend(2) -> {0, 1, 10};

get_extend(_) -> undefined.

%%================================================
%% 启灵消耗：get_qiling_cost(装备类型,装备等级) -> {银币消耗, [{消耗的物品原型,数量},{物品原型,数量}]}
get_qiling_cost(1, 40) ->{96000,[{272,1}]};

get_qiling_cost(1, 50) ->{300000,[{273,1}]};

get_qiling_cost(1, 60) ->{600000,[{274,1}]};

get_qiling_cost(1, 70) ->{840000,[{275,1}]};

get_qiling_cost(1, 80) ->{960000,[{276,1}]};

get_qiling_cost(1, 90) ->{1080000,[{277,1}]};

get_qiling_cost(1, 100) ->{1200000,[{278,1}]};

get_qiling_cost(2, 40) ->{96000,[{272,1}]};

get_qiling_cost(2, 50) ->{300000,[{273,1}]};

get_qiling_cost(2, 60) ->{600000,[{274,1}]};

get_qiling_cost(2, 70) ->{840000,[{275,1}]};

get_qiling_cost(2, 80) ->{960000,[{276,1}]};

get_qiling_cost(2, 90) ->{1080000,[{277,1}]};

get_qiling_cost(2, 100) ->{1200000,[{278,1}]};

get_qiling_cost(3, 40) ->{96000,[{272,1}]};

get_qiling_cost(3, 50) ->{300000,[{273,1}]};

get_qiling_cost(3, 60) ->{600000,[{274,1}]};

get_qiling_cost(3, 70) ->{840000,[{275,1}]};

get_qiling_cost(3, 80) ->{960000,[{276,1}]};

get_qiling_cost(3, 90) ->{1080000,[{277,1}]};

get_qiling_cost(3, 100) ->{1200000,[{278,1}]};

get_qiling_cost(4, 40) ->{96000,[{272,1}]};

get_qiling_cost(4, 50) ->{300000,[{273,1}]};

get_qiling_cost(4, 60) ->{600000,[{274,1}]};

get_qiling_cost(4, 70) ->{840000,[{275,1}]};

get_qiling_cost(4, 80) ->{960000,[{276,1}]};

get_qiling_cost(4, 90) ->{1080000,[{277,1}]};

get_qiling_cost(4, 100) ->{1200000,[{278,1}]};

get_qiling_cost(5, 40) ->{96000,[{272,1}]};

get_qiling_cost(5, 50) ->{300000,[{273,1}]};

get_qiling_cost(5, 60) ->{600000,[{274,1}]};

get_qiling_cost(5, 70) ->{840000,[{275,1}]};

get_qiling_cost(5, 80) ->{960000,[{276,1}]};

get_qiling_cost(5, 90) ->{1080000,[{277,1}]};

get_qiling_cost(5, 100) ->{1200000,[{278,1}]};

get_qiling_cost(6, 40) ->{96000,[{272,1}]};

get_qiling_cost(6, 50) ->{300000,[{273,1}]};

get_qiling_cost(6, 60) ->{600000,[{274,1}]};

get_qiling_cost(6, 70) ->{840000,[{275,1}]};

get_qiling_cost(6, 80) ->{960000,[{276,1}]};

get_qiling_cost(6, 90) ->{1080000,[{277,1}]};

get_qiling_cost(6, 100) ->{1200000,[{278,1}]};

get_qiling_cost(7, 45) ->{112860,[{272,1}]};

get_qiling_cost(7, 55) ->{427500,[{273,1}]};

get_qiling_cost(7, 65) ->{684000,[{274,1}]};

get_qiling_cost(7, 75) ->{855000,[{275,1}]};

get_qiling_cost(7, 85) ->{969000,[{276,1}]};

get_qiling_cost(7, 95) ->{1140000,[{277,1}]}.


%%================================================
%% 启灵属性获得：get_qiling_attr(装备类型,装备等级) -> #role_update_attri
get_qiling_attr(1, 40) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 186,
p_def         = 0,
m_def         = 0,
p_att         = 124,
m_att         = 124
		};

get_qiling_attr(1, 50) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 255,
p_def         = 0,
m_def         = 0,
p_att         = 170,
m_att         = 170
		};

get_qiling_attr(1, 60) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 324,
p_def         = 0,
m_def         = 0,
p_att         = 216,
m_att         = 216
		};

get_qiling_attr(1, 70) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 393,
p_def         = 0,
m_def         = 0,
p_att         = 262,
m_att         = 262
		};

get_qiling_attr(1, 80) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 462,
p_def         = 0,
m_def         = 0,
p_att         = 308,
m_att         = 308
		};

get_qiling_attr(1, 90) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 531,
p_def         = 0,
m_def         = 0,
p_att         = 354,
m_att         = 354
		};

get_qiling_attr(1, 100) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 600,
p_def         = 0,
m_def         = 0,
p_att         = 400,
m_att         = 400
		};

get_qiling_attr(2, 40) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 261,
m_def         = 261,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(2, 50) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 357,
m_def         = 357,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(2, 60) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 454,
m_def         = 454,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(2, 70) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 550,
m_def         = 550,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(2, 80) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 647,
m_def         = 647,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(2, 90) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 744,
m_def         = 744,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(2, 100) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 840,
m_def         = 840,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(3, 40) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 62,
gd_pojia      = 0,

gd_maxHp      = 186,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(3, 50) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 85,
gd_pojia      = 0,

gd_maxHp      = 255,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(3, 60) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 108,
gd_pojia      = 0,

gd_maxHp      = 324,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(3, 70) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 131,
gd_pojia      = 0,

gd_maxHp      = 393,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(3, 80) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 154,
gd_pojia      = 0,

gd_maxHp      = 462,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(3, 90) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 177,
gd_pojia      = 0,

gd_maxHp      = 531,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(3, 100) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 200,
gd_pojia      = 0,

gd_maxHp      = 600,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(4, 40) ->
	#role_update_attri{ 
			     gd_speed      = 298,
gd_baoji      = 0,
gd_shanbi     = 37,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(4, 50) ->
	#role_update_attri{ 
			     gd_speed      = 408,
gd_baoji      = 0,
gd_shanbi     = 51,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(4, 60) ->
	#role_update_attri{ 
			     gd_speed      = 518,
gd_baoji      = 0,
gd_shanbi     = 65,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(4, 70) ->
	#role_update_attri{ 
			     gd_speed      = 629,
gd_baoji      = 0,
gd_shanbi     = 79,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(4, 80) ->
	#role_update_attri{ 
			     gd_speed      = 739,
gd_baoji      = 0,
gd_shanbi     = 92,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(4, 90) ->
	#role_update_attri{ 
			     gd_speed      = 850,
gd_baoji      = 0,
gd_shanbi     = 106,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(4, 100) ->
	#role_update_attri{ 
			     gd_speed      = 960,
gd_baoji      = 0,
gd_shanbi     = 120,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(5, 40) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 261,
m_def         = 261,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(5, 50) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 357,
m_def         = 357,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(5, 60) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 454,
m_def         = 454,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(5, 70) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 550,
m_def         = 550,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(5, 80) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 647,
m_def         = 647,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(5, 90) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 744,
m_def         = 744,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(5, 100) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 840,
m_def         = 840,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(6, 40) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 62,

gd_maxHp      = 186,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(6, 50) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 85,

gd_maxHp      = 255,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(6, 60) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 108,

gd_maxHp      = 324,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(6, 70) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 131,

gd_maxHp      = 393,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(6, 80) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 154,

gd_maxHp      = 462,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(6, 90) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 177,

gd_maxHp      = 531,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(6, 100) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 200,

gd_maxHp      = 600,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_qiling_attr(7, 45) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 80,
m_att         = 80
		};

get_qiling_attr(7, 55) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 144,
m_att         = 144
		};

get_qiling_attr(7, 65) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 208,
m_att         = 208
		};

get_qiling_attr(7, 75) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 272,
m_att         = 272
		};

get_qiling_attr(7, 85) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 336,
m_att         = 336
		};

get_qiling_attr(7, 95) ->
	#role_update_attri{ 
			     gd_speed      = 0,
gd_baoji      = 0,
gd_shanbi     = 0,
gd_gedang     = 0,
gd_mingzhong  = 0,
gd_zhiming    = 0,
gd_xingyun    = 0,
gd_fanji      = 0,
gd_pojia      = 0,

gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 400,
m_att         = 400
		}.


%%================================================
%% 洗炼消耗：get_xilian_cost(装备等级) -> {银币消耗, 锁定金币}
get_xilian_cost(1) ->{1000,8};

get_xilian_cost(10) ->{1500,10};

get_xilian_cost(20) ->{2000,12};

get_xilian_cost(30) ->{3000,14};

get_xilian_cost(40) ->{4000,16};

get_xilian_cost(50) ->{5000,18};

get_xilian_cost(60) ->{7000,20};

get_xilian_cost(70) ->{11000,22};

get_xilian_cost(80) ->{14000,24};

get_xilian_cost(90) ->{17000,26};

get_xilian_cost(100) ->{20000,28};

get_xilian_cost(25) ->{2500,12};

get_xilian_cost(35) ->{3500,15};

get_xilian_cost(45) ->{4500,18};

get_xilian_cost(55) ->{6000,21};

get_xilian_cost(65) ->{9000,24};

get_xilian_cost(75) ->{12500,27};

get_xilian_cost(85) ->{15500,30};

get_xilian_cost(95) ->{18500,33}.


%%================================================
%% 升级消耗：get_upgrate_cost(装备ID) -> {银币,材料}
get_upgrate_cost(4) ->{2000,[{182,1}]};

get_upgrate_cost(5) ->{2000,[{192,1}]};

get_upgrate_cost(6) ->{2000,[{202,1}]};

get_upgrate_cost(7) ->{2000,[{212,1}]};

get_upgrate_cost(8) ->{2000,[{222,1}]};

get_upgrate_cost(9) ->{2000,[{232,1}]};

get_upgrate_cost(10) ->{2000,[{242,1}]};

get_upgrate_cost(11) ->{2000,[{252,1}]};

get_upgrate_cost(12) ->{2400,[{183,1}]};

get_upgrate_cost(13) ->{2400,[{193,1}]};

get_upgrate_cost(14) ->{2400,[{203,1}]};

get_upgrate_cost(15) ->{2400,[{213,1}]};

get_upgrate_cost(16) ->{2400,[{223,1}]};

get_upgrate_cost(17) ->{2400,[{233,1}]};

get_upgrate_cost(18) ->{2400,[{243,1}]};

get_upgrate_cost(19) ->{2400,[{253,1}]};

get_upgrate_cost(20) ->{2880,[{184,1}]};

get_upgrate_cost(21) ->{2880,[{194,1}]};

get_upgrate_cost(22) ->{2880,[{204,1}]};

get_upgrate_cost(23) ->{2880,[{214,1}]};

get_upgrate_cost(24) ->{2880,[{224,1}]};

get_upgrate_cost(25) ->{2880,[{234,1}]};

get_upgrate_cost(26) ->{2880,[{244,1}]};

get_upgrate_cost(27) ->{2880,[{254,1}]};

get_upgrate_cost(28) ->{4320,[{185,1}]};

get_upgrate_cost(29) ->{4320,[{195,1}]};

get_upgrate_cost(30) ->{4320,[{205,1}]};

get_upgrate_cost(31) ->{4320,[{215,1}]};

get_upgrate_cost(32) ->{4320,[{225,1}]};

get_upgrate_cost(33) ->{4320,[{235,1}]};

get_upgrate_cost(34) ->{4320,[{245,1}]};

get_upgrate_cost(35) ->{4320,[{255,1}]};

get_upgrate_cost(36) ->{8640,[{186,1}]};

get_upgrate_cost(37) ->{8640,[{196,1}]};

get_upgrate_cost(38) ->{8640,[{206,1}]};

get_upgrate_cost(39) ->{8640,[{216,1}]};

get_upgrate_cost(40) ->{8640,[{226,1}]};

get_upgrate_cost(41) ->{8640,[{236,1}]};

get_upgrate_cost(42) ->{8640,[{246,1}]};

get_upgrate_cost(43) ->{8640,[{256,1}]};

get_upgrate_cost(44) ->{17280,[{187,1}]};

get_upgrate_cost(45) ->{17280,[{197,1}]};

get_upgrate_cost(46) ->{17280,[{207,1}]};

get_upgrate_cost(47) ->{17280,[{217,1}]};

get_upgrate_cost(48) ->{17280,[{227,1}]};

get_upgrate_cost(49) ->{17280,[{237,1}]};

get_upgrate_cost(50) ->{17280,[{247,1}]};

get_upgrate_cost(51) ->{17280,[{257,1}]};

get_upgrate_cost(52) ->{43200,[{188,1}]};

get_upgrate_cost(53) ->{43200,[{198,1}]};

get_upgrate_cost(54) ->{43200,[{208,1}]};

get_upgrate_cost(55) ->{43200,[{218,1}]};

get_upgrate_cost(56) ->{43200,[{228,1}]};

get_upgrate_cost(57) ->{43200,[{238,1}]};

get_upgrate_cost(58) ->{43200,[{248,1}]};

get_upgrate_cost(59) ->{43200,[{258,1}]};

get_upgrate_cost(60) ->{129600,[{189,1}]};

get_upgrate_cost(61) ->{129600,[{199,1}]};

get_upgrate_cost(62) ->{129600,[{209,1}]};

get_upgrate_cost(63) ->{129600,[{219,1}]};

get_upgrate_cost(64) ->{129600,[{229,1}]};

get_upgrate_cost(65) ->{129600,[{239,1}]};

get_upgrate_cost(66) ->{129600,[{249,1}]};

get_upgrate_cost(67) ->{129600,[{259,1}]};

get_upgrate_cost(68) ->{388800,[{190,1}]};

get_upgrate_cost(69) ->{388800,[{200,1}]};

get_upgrate_cost(70) ->{388800,[{210,1}]};

get_upgrate_cost(71) ->{388800,[{220,1}]};

get_upgrate_cost(72) ->{388800,[{230,1}]};

get_upgrate_cost(73) ->{388800,[{240,1}]};

get_upgrate_cost(74) ->{388800,[{250,1}]};

get_upgrate_cost(75) ->{388800,[{260,1}]};

get_upgrate_cost(76) ->{972000,[{191,1}]};

get_upgrate_cost(77) ->{972000,[{201,1}]};

get_upgrate_cost(78) ->{972000,[{211,1}]};

get_upgrate_cost(79) ->{972000,[{221,1}]};

get_upgrate_cost(80) ->{972000,[{231,1}]};

get_upgrate_cost(81) ->{972000,[{241,1}]};

get_upgrate_cost(82) ->{972000,[{251,1}]};

get_upgrate_cost(83) ->{972000,[{261,1}]};

get_upgrate_cost(298) ->{3600,[{406,1}]};

get_upgrate_cost(299) ->{6480,[{407,1}]};

get_upgrate_cost(300) ->{12960,[{408,1}]};

get_upgrate_cost(301) ->{30240,[{409,1}]};

get_upgrate_cost(302) ->{86400,[{410,1}]};

get_upgrate_cost(303) ->{259200,[{411,1}]};

get_upgrate_cost(304) ->{680400,[{412,1}]}.


%%================================================
%% 完美升级金币消耗：get_perfect_upgrate_cost(当前装备强化等级) -> 完美升级所需元宝
get_perfect_upgrate_cost(0) ->3;

get_perfect_upgrate_cost(1) ->4;

get_perfect_upgrate_cost(2) ->5;

get_perfect_upgrate_cost(3) ->6;

get_perfect_upgrate_cost(4) ->8;

get_perfect_upgrate_cost(5) ->10;

get_perfect_upgrate_cost(6) ->20;

get_perfect_upgrate_cost(7) ->60;

get_perfect_upgrate_cost(8) ->110;

get_perfect_upgrate_cost(9) ->160;

get_perfect_upgrate_cost(10) ->200;

get_perfect_upgrate_cost(11) ->250;

get_perfect_upgrate_cost(12) ->310;

get_perfect_upgrate_cost(13) ->380;

get_perfect_upgrate_cost(14) ->480;

get_perfect_upgrate_cost(15) ->600.


%%================================================
%% 获取传奇属性：get_legend_attr(装备类型,装备等级) -> #role_update_attri
get_legend_attr(1,1) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 146,
m_att         = 146
		};

get_legend_attr(1,10) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 183,
m_att         = 183
		};

get_legend_attr(1,20) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 227,
m_att         = 227
		};

get_legend_attr(1,30) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 270,
m_att         = 270
		};

get_legend_attr(1,40) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 336,
m_att         = 336
		};

get_legend_attr(1,50) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 402,
m_att         = 402
		};

get_legend_attr(1,60) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 468,
m_att         = 468
		};

get_legend_attr(1,70) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 534,
m_att         = 534
		};

get_legend_attr(1,80) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 600,
m_att         = 600
		};

get_legend_attr(1,90) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 665,
m_att         = 665
		};

get_legend_attr(1,100) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 731,
m_att         = 731
		};

get_legend_attr(2,1) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 124,
p_def         = 0,
m_def         = 109,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,10) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 140,
p_def         = 0,
m_def         = 136,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,20) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 178,
p_def         = 0,
m_def         = 168,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,30) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 218,
p_def         = 0,
m_def         = 201,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,40) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 264,
p_def         = 0,
m_def         = 250,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,50) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 310,
p_def         = 0,
m_def         = 299,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,60) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 356,
p_def         = 0,
m_def         = 347,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,70) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 401,
p_def         = 0,
m_def         = 396,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,80) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 447,
p_def         = 0,
m_def         = 445,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,90) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 493,
p_def         = 0,
m_def         = 494,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(2,100) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 539,
p_def         = 0,
m_def         = 543,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,1) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 124,
p_def         = 0,
m_def         = 109,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,10) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 140,
p_def         = 0,
m_def         = 136,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,20) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 178,
p_def         = 0,
m_def         = 168,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,30) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 218,
p_def         = 0,
m_def         = 201,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,40) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 264,
p_def         = 0,
m_def         = 250,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,50) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 310,
p_def         = 0,
m_def         = 299,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,60) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 356,
p_def         = 0,
m_def         = 347,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,70) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 401,
p_def         = 0,
m_def         = 396,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,80) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 447,
p_def         = 0,
m_def         = 445,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,90) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 493,
p_def         = 0,
m_def         = 494,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(3,100) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 539,
p_def         = 0,
m_def         = 543,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,1) ->
	#role_update_attri{
		                        gd_speed      = 123,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 109,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,10) ->
	#role_update_attri{
		                        gd_speed      = 153,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 136,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,20) ->
	#role_update_attri{
		                        gd_speed      = 190,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 168,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,30) ->
	#role_update_attri{
		                        gd_speed      = 227,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 201,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,40) ->
	#role_update_attri{
		                        gd_speed      = 282,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 250,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,50) ->
	#role_update_attri{
		                        gd_speed      = 338,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 299,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,60) ->
	#role_update_attri{
		                        gd_speed      = 393,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 347,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,70) ->
	#role_update_attri{
		                        gd_speed      = 448,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 396,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,80) ->
	#role_update_attri{
		                        gd_speed      = 504,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 445,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,90) ->
	#role_update_attri{
		                        gd_speed      = 559,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 494,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(4,100) ->
	#role_update_attri{
		                        gd_speed      = 614,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 543,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,1) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 114,
p_def         = 116,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,10) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 129,
p_def         = 145,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,20) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 164,
p_def         = 180,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,30) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 201,
p_def         = 214,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,40) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 244,
p_def         = 266,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,50) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 286,
p_def         = 319,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,60) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 328,
p_def         = 371,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,70) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 371,
p_def         = 423,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,80) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 413,
p_def         = 475,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,90) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 455,
p_def         = 527,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(5,100) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 497,
p_def         = 579,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,1) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 114,
p_def         = 116,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,10) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 129,
p_def         = 145,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,20) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 164,
p_def         = 180,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,30) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 201,
p_def         = 214,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,40) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 244,
p_def         = 266,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,50) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 286,
p_def         = 319,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,60) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 328,
p_def         = 371,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,70) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 371,
p_def         = 423,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,80) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 413,
p_def         = 475,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,90) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 455,
p_def         = 527,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(6,100) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 497,
p_def         = 579,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,15) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 147,
p_def         = 163,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,25) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 183,
p_def         = 197,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,35) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 223,
p_def         = 240,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,45) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 265,
p_def         = 293,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,55) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 307,
p_def         = 345,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,65) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 350,
p_def         = 397,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,75) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 392,
p_def         = 449,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,85) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 434,
p_def         = 501,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_legend_attr(7,95) ->
	#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 476,
p_def         = 553,
m_def         = 0,
p_att         = 0,
m_att         = 0
		}.


%%================================================
%% 获取传奇强化成长值：get_inten_attr(装备类型,装备等级) -> #role_update_attri
get_inten_attr(1,1) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 13,
m_att         = 13
		};

get_inten_attr(1,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 17,
m_att         = 17
		};

get_inten_attr(1,20) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 21,
m_att         = 21
		};

get_inten_attr(1,30) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 25,
m_att         = 25
		};

get_inten_attr(1,40) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 30,
m_att         = 30
		};

get_inten_attr(1,50) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 36,
m_att         = 36
		};

get_inten_attr(1,60) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 42,
m_att         = 42
		};

get_inten_attr(1,70) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 48,
m_att         = 48
		};

get_inten_attr(1,80) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 54,
m_att         = 54
		};

get_inten_attr(1,90) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 60,
m_att         = 60
		};

get_inten_attr(1,100) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 65,
m_att         = 65
		};

get_inten_attr(2,1) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 11,
p_def         = 0,
m_def         = 10,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 12,
p_def         = 0,
m_def         = 12,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,20) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 16,
p_def         = 0,
m_def         = 15,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,30) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 20,
p_def         = 0,
m_def         = 18,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,40) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 24,
p_def         = 0,
m_def         = 23,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,50) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 28,
p_def         = 0,
m_def         = 27,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,60) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 32,
p_def         = 0,
m_def         = 31,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,70) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 36,
p_def         = 0,
m_def         = 35,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,80) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 40,
p_def         = 0,
m_def         = 40,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,90) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 44,
p_def         = 0,
m_def         = 44,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(2,100) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 49,
p_def         = 0,
m_def         = 49,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,1) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 11,
p_def         = 0,
m_def         = 10,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 12,
p_def         = 0,
m_def         = 12,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,20) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 16,
p_def         = 0,
m_def         = 15,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,30) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 20,
p_def         = 0,
m_def         = 18,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,40) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 24,
p_def         = 0,
m_def         = 23,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,50) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 28,
p_def         = 0,
m_def         = 27,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,60) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 32,
p_def         = 0,
m_def         = 31,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,70) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 36,
p_def         = 0,
m_def         = 35,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,80) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 40,
p_def         = 0,
m_def         = 40,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,90) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 44,
p_def         = 0,
m_def         = 44,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(3,100) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 49,
p_def         = 0,
m_def         = 49,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,1) ->
#role_update_attri{
		                        gd_speed      = 10,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 7,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,10) ->
#role_update_attri{
		                        gd_speed      = 13,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 8,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,20) ->
#role_update_attri{
		                        gd_speed      = 16,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 10,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,30) ->
#role_update_attri{
		                        gd_speed      = 20,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 12,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,40) ->
#role_update_attri{
		                        gd_speed      = 25,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 15,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,50) ->
#role_update_attri{
		                        gd_speed      = 30,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 18,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,60) ->
#role_update_attri{
		                        gd_speed      = 34,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 21,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,70) ->
#role_update_attri{
		                        gd_speed      = 39,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 24,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,80) ->
#role_update_attri{
		                        gd_speed      = 44,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 27,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,90) ->
#role_update_attri{
		                        gd_speed      = 49,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 30,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(4,100) ->
#role_update_attri{
		                        gd_speed      = 55,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 33,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,1) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 10,
p_def         = 10,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 12,
p_def         = 13,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,20) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 15,
p_def         = 16,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,30) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 18,
p_def         = 19,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,40) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 22,
p_def         = 24,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,50) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 25,
p_def         = 28,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,60) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 29,
p_def         = 33,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,70) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 33,
p_def         = 38,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,80) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 37,
p_def         = 42,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,90) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 41,
p_def         = 47,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(5,100) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 45,
p_def         = 52,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,1) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 10,
p_def         = 10,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 12,
p_def         = 13,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,20) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 15,
p_def         = 16,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,30) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 18,
p_def         = 19,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,40) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 22,
p_def         = 24,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,50) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 25,
p_def         = 28,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,60) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 29,
p_def         = 33,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,70) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 33,
p_def         = 38,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,80) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 37,
p_def         = 42,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,90) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 41,
p_def         = 47,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(6,100) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 45,
p_def         = 52,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 25,
p_def         = 8,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,25) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 30,
p_def         = 10,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,35) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 37,
p_def         = 12,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,45) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 43,
p_def         = 14,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,55) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 49,
p_def         = 17,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,65) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 56,
p_def         = 19,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,75) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 62,
p_def         = 21,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,85) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 68,
p_def         = 24,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_attr(7,95) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 74,
p_def         = 26,
m_def         = 0,
p_att         = 0,
m_att         = 0
		}.


%%================================================
%% 装备升品消耗：get_upquality_cost(装备等级,装备当前品质) -> {升到下个品质所需要的银币,材料}
get_upquality_cost(1,1) ->{2000, [{279,1}]};

get_upquality_cost(10,1) ->{3000, [{279,1}]};

get_upquality_cost(20,1) ->{4000, [{279,2}]};

get_upquality_cost(30,1) ->{6000, [{279,3}]};

get_upquality_cost(40,1) ->{14000, [{279,4}]};

get_upquality_cost(50,1) ->{34000, [{279,5}]};

get_upquality_cost(60,1) ->{63280, [{279,6}]};

get_upquality_cost(70,1) ->{84380, [{279,7}]};

get_upquality_cost(80,1) ->{112500, [{279,8}]};

get_upquality_cost(90,1) ->{150000, [{279,9}]};

get_upquality_cost(100,1) ->{200000, [{279,10}]};

get_upquality_cost(1,2) ->{3000, [{280,1}]};

get_upquality_cost(10,2) ->{4500, [{280,1}]};

get_upquality_cost(20,2) ->{6000, [{280,2}]};

get_upquality_cost(30,2) ->{9000, [{280,3}]};

get_upquality_cost(40,2) ->{21000, [{280,4}]};

get_upquality_cost(50,2) ->{51000, [{280,5}]};

get_upquality_cost(60,2) ->{94920, [{280,6}]};

get_upquality_cost(70,2) ->{126560, [{280,7}]};

get_upquality_cost(80,2) ->{168750, [{280,8}]};

get_upquality_cost(90,2) ->{225000, [{280,9}]};

get_upquality_cost(100,2) ->{300000, [{280,10}]};

get_upquality_cost(1,3) ->{6000, [{281,1}]};

get_upquality_cost(10,3) ->{9000, [{281,1}]};

get_upquality_cost(20,3) ->{12000, [{281,2}]};

get_upquality_cost(30,3) ->{18000, [{281,3}]};

get_upquality_cost(40,3) ->{42000, [{281,4}]};

get_upquality_cost(50,3) ->{102000, [{281,5}]};

get_upquality_cost(60,3) ->{189840, [{281,6}]};

get_upquality_cost(70,3) ->{253130, [{281,7}]};

get_upquality_cost(80,3) ->{337500, [{281,8}]};

get_upquality_cost(90,3) ->{450000, [{281,9}]};

get_upquality_cost(100,3) ->{600000, [{281,10}]};

get_upquality_cost(1,4) ->{8000, [{282,1}]};

get_upquality_cost(10,4) ->{12000, [{282,1}]};

get_upquality_cost(20,4) ->{16000, [{282,2}]};

get_upquality_cost(30,4) ->{24000, [{282,3}]};

get_upquality_cost(40,4) ->{56000, [{282,4}]};

get_upquality_cost(50,4) ->{136000, [{282,5}]};

get_upquality_cost(60,4) ->{253130, [{282,6}]};

get_upquality_cost(70,4) ->{337500, [{282,7}]};

get_upquality_cost(80,4) ->{450000, [{282,8}]};

get_upquality_cost(90,4) ->{600000, [{282,9}]};

get_upquality_cost(100,4) ->{800000, [{282,10}]};

get_upquality_cost(25,1) ->{6000, [{279,3}]};

get_upquality_cost(35,1) ->{12000, [{279,4}]};

get_upquality_cost(45,1) ->{28800, [{279,5}]};

get_upquality_cost(55,1) ->{58370, [{279,6}]};

get_upquality_cost(65,1) ->{88600, [{279,7}]};

get_upquality_cost(75,1) ->{118130, [{279,8}]};

get_upquality_cost(85,1) ->{157500, [{279,9}]};

get_upquality_cost(95,1) ->{210000, [{279,10}]};

get_upquality_cost(25,2) ->{9000, [{280,3}]};

get_upquality_cost(35,2) ->{18000, [{280,4}]};

get_upquality_cost(45,2) ->{43200, [{280,5}]};

get_upquality_cost(55,2) ->{87550, [{280,6}]};

get_upquality_cost(65,2) ->{132890, [{280,7}]};

get_upquality_cost(75,2) ->{177190, [{280,8}]};

get_upquality_cost(85,2) ->{236250, [{280,9}]};

get_upquality_cost(95,2) ->{315000, [{280,10}]};

get_upquality_cost(25,3) ->{18000, [{281,3}]};

get_upquality_cost(35,3) ->{42000, [{281,4}]};

get_upquality_cost(45,3) ->{102000, [{281,5}]};

get_upquality_cost(55,3) ->{189840, [{281,6}]};

get_upquality_cost(65,3) ->{253130, [{281,7}]};

get_upquality_cost(75,3) ->{337500, [{281,8}]};

get_upquality_cost(85,3) ->{450000, [{281,9}]};

get_upquality_cost(95,3) ->{600000, [{281,10}]};

get_upquality_cost(25,4) ->{24000, [{282,3}]};

get_upquality_cost(35,4) ->{56000, [{282,4}]};

get_upquality_cost(45,4) ->{136000, [{282,5}]};

get_upquality_cost(55,4) ->{253130, [{282,6}]};

get_upquality_cost(65,4) ->{337500, [{282,7}]};

get_upquality_cost(75,4) ->{450000, [{282,8}]};

get_upquality_cost(85,4) ->{600000, [{282,9}]};

get_upquality_cost(95,4) ->{800000, [{282,10}]}.


%%================================================
%% 全套强化加成：get_inten_all_attr(人物等级,全套强化等级) -> #role_update_attri
get_inten_all_attr(0,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 220,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(10,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 260,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(20,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 290,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(30,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 310,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(40,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 350,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(50,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 400,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(60,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 470,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(70,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 530,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(80,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 600,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(90,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 670,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(100,8) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 730,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(0,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 370,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(10,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 430,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(20,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 480,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(30,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 520,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(40,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 590,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(50,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 670,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(60,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 780,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(70,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 890,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(80,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1000,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(90,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1110,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(100,10) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1220,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(0,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 550,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(10,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 640,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(20,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 710,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(30,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 790,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(40,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 880,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(50,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1010,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(60,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1170,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(70,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1340,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(80,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1500,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(90,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1660,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(100,12) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1830,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(0,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 760,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(10,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 880,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(20,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 980,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(30,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1090,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(40,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1210,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(50,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1390,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(60,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1610,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(70,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1850,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(80,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2070,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(90,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2290,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(100,13) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2520,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(0,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 980,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(10,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1140,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(20,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1260,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(30,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1410,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(40,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1560,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(50,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1790,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(60,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2080,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(70,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2390,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(80,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2670,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(90,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2950,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(100,14) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 3250,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(0,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1230,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(10,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1430,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(20,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1580,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(30,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1760,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(40,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 1950,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(50,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2240,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(60,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2600,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(70,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 2990,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(80,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 3340,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(90,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 3690,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_inten_all_attr(100,15) ->
#role_update_attri{
		                        gd_speed      = 0,
gd_maxHp      = 4060,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		}.


%%================================================
%% 全套强化加成：get_inten_all_rate(全套强化等级) -> {速度, 攻, 物防, 魔防}
get_inten_all_rate(8) -> {0.02, 0.02, 0.02, 0.02};

get_inten_all_rate(10) -> {0.03, 0.03, 0.03, 0.03};

get_inten_all_rate(12) -> {0.04, 0.04, 0.04, 0.04};

get_inten_all_rate(13) -> {0.06, 0.06, 0.06, 0.06};

get_inten_all_rate(14) -> {0.08, 0.08, 0.08, 0.08};

get_inten_all_rate(15) -> {0.1, 0.1, 0.1, 0.1}.


%%================================================
%% 装备品质对应系数：get_quality_rate(品质) -> 系数
get_quality_rate(1) ->0.5;

get_quality_rate(2) ->0.61;

get_quality_rate(3) ->0.73;

get_quality_rate(4) ->0.85;

get_quality_rate(5) ->1.


%%================================================
%% 装备强化对应基础成功率：get_inten_rate(装备强化等级) -> 基础强化成功率
get_inten_rate(0) ->100;

get_inten_rate(1) ->100;

get_inten_rate(2) ->90;

get_inten_rate(3) ->70;

get_inten_rate(4) ->60;

get_inten_rate(5) ->50;

get_inten_rate(6) ->40;

get_inten_rate(7) ->35;

get_inten_rate(8) ->30;

get_inten_rate(9) ->25;

get_inten_rate(10) ->20;

get_inten_rate(11) ->15;

get_inten_rate(12) ->10;

get_inten_rate(13) ->10;

get_inten_rate(14) ->8;

get_inten_rate(15) ->0.


%%================================================
%% 装备强化基础成功率上限：get_inten_max_rate(装备强化等级) -> 成功率上限
get_inten_max_rate(0) ->100;

get_inten_max_rate(1) ->100;

get_inten_max_rate(2) ->100;

get_inten_max_rate(3) ->100;

get_inten_max_rate(4) ->100;

get_inten_max_rate(5) ->80;

get_inten_max_rate(6) ->80;

get_inten_max_rate(7) ->70;

get_inten_max_rate(8) ->70;

get_inten_max_rate(9) ->60;

get_inten_max_rate(10) ->60;

get_inten_max_rate(11) ->50;

get_inten_max_rate(12) ->50;

get_inten_max_rate(13) ->50;

get_inten_max_rate(14) ->50;

get_inten_max_rate(15) ->0.


%%================================================
%% 升1点成功率的金币消耗：get_inten_uprate_cost(装备强化等级) -> 每1百分比消耗的金币
get_inten_uprate_cost(0) ->0;

get_inten_uprate_cost(1) ->0;

get_inten_uprate_cost(2) ->3;

get_inten_uprate_cost(3) ->5;

get_inten_uprate_cost(4) ->6;

get_inten_uprate_cost(5) ->7;

get_inten_uprate_cost(6) ->8;

get_inten_uprate_cost(7) ->9;

get_inten_uprate_cost(8) ->10;

get_inten_uprate_cost(9) ->11;

get_inten_uprate_cost(10) ->12;

get_inten_uprate_cost(11) ->14;

get_inten_uprate_cost(12) ->15;

get_inten_uprate_cost(13) ->18;

get_inten_uprate_cost(14) ->20;

get_inten_uprate_cost(15) ->0.


%%================================================
%% 装备洗炼属性类别：get_attr_type_list(装备类型) -> 属性种类
get_attr_type_list(1) ->[1,2,14,12,8,7,11];

get_attr_type_list(2) ->[5,3,4,10,9];

get_attr_type_list(3) ->[5,3,4,10,9];

get_attr_type_list(4) ->[6,3,4,10,9];

get_attr_type_list(5) ->[5,11,6,8,7,14];

get_attr_type_list(6) ->[5,11,6,8,7,14];

get_attr_type_list(7) ->[1,2,11,12,13].


%%================================================
%% 洗炼属性上下限：get_xilian_attr_range(星级, 等级, 属性种类) -> {属性值下限, 属性值上限}
get_xilian_attr_range(1, 1, 1) ->{2, 11};

get_xilian_attr_range(2, 1, 1) ->{12, 23};

get_xilian_attr_range(3, 1, 1) ->{24, 35};

get_xilian_attr_range(4, 1, 1) ->{36, 47};

get_xilian_attr_range(5, 1, 1) ->{48, 63};

get_xilian_attr_range(6, 1, 1) ->{64, 79};

get_xilian_attr_range(7, 1, 1) ->{80, 99};

get_xilian_attr_range(8, 1, 1) ->{100, 119};

get_xilian_attr_range(9, 1, 1) ->{120, 139};

get_xilian_attr_range(10, 1, 1) ->{140, 163};

get_xilian_attr_range(1, 10, 1) ->{8, 23};

get_xilian_attr_range(2, 10, 1) ->{24, 35};

get_xilian_attr_range(3, 10, 1) ->{36, 47};

get_xilian_attr_range(4, 10, 1) ->{48, 63};

get_xilian_attr_range(5, 10, 1) ->{64, 79};

get_xilian_attr_range(6, 10, 1) ->{80, 99};

get_xilian_attr_range(7, 10, 1) ->{100, 119};

get_xilian_attr_range(8, 10, 1) ->{120, 139};

get_xilian_attr_range(9, 10, 1) ->{140, 163};

get_xilian_attr_range(10, 10, 1) ->{164, 186};

get_xilian_attr_range(1, 20, 1) ->{25, 35};

get_xilian_attr_range(2, 20, 1) ->{36, 47};

get_xilian_attr_range(3, 20, 1) ->{48, 63};

get_xilian_attr_range(4, 20, 1) ->{64, 79};

get_xilian_attr_range(5, 20, 1) ->{80, 99};

get_xilian_attr_range(6, 20, 1) ->{100, 119};

get_xilian_attr_range(7, 20, 1) ->{120, 139};

get_xilian_attr_range(8, 20, 1) ->{140, 163};

get_xilian_attr_range(9, 20, 1) ->{164, 186};

get_xilian_attr_range(10, 20, 1) ->{187, 210};

get_xilian_attr_range(1, 30, 1) ->{27, 47};

get_xilian_attr_range(2, 30, 1) ->{48, 63};

get_xilian_attr_range(3, 30, 1) ->{64, 79};

get_xilian_attr_range(4, 30, 1) ->{80, 99};

get_xilian_attr_range(5, 30, 1) ->{100, 119};

get_xilian_attr_range(6, 30, 1) ->{120, 139};

get_xilian_attr_range(7, 30, 1) ->{140, 163};

get_xilian_attr_range(8, 30, 1) ->{164, 186};

get_xilian_attr_range(9, 30, 1) ->{187, 210};

get_xilian_attr_range(10, 30, 1) ->{211, 233};

get_xilian_attr_range(1, 40, 1) ->{23, 63};

get_xilian_attr_range(2, 40, 1) ->{64, 79};

get_xilian_attr_range(3, 40, 1) ->{80, 99};

get_xilian_attr_range(4, 40, 1) ->{100, 119};

get_xilian_attr_range(5, 40, 1) ->{120, 139};

get_xilian_attr_range(6, 40, 1) ->{140, 163};

get_xilian_attr_range(7, 40, 1) ->{164, 186};

get_xilian_attr_range(8, 40, 1) ->{187, 210};

get_xilian_attr_range(9, 40, 1) ->{211, 233};

get_xilian_attr_range(10, 40, 1) ->{234, 257};

get_xilian_attr_range(1, 50, 1) ->{39, 79};

get_xilian_attr_range(2, 50, 1) ->{80, 99};

get_xilian_attr_range(3, 50, 1) ->{100, 119};

get_xilian_attr_range(4, 50, 1) ->{120, 139};

get_xilian_attr_range(5, 50, 1) ->{140, 163};

get_xilian_attr_range(6, 50, 1) ->{164, 186};

get_xilian_attr_range(7, 50, 1) ->{187, 210};

get_xilian_attr_range(8, 50, 1) ->{211, 233};

get_xilian_attr_range(9, 50, 1) ->{234, 257};

get_xilian_attr_range(10, 50, 1) ->{258, 280};

get_xilian_attr_range(1, 60, 1) ->{59, 99};

get_xilian_attr_range(2, 60, 1) ->{100, 119};

get_xilian_attr_range(3, 60, 1) ->{120, 139};

get_xilian_attr_range(4, 60, 1) ->{140, 163};

get_xilian_attr_range(5, 60, 1) ->{164, 186};

get_xilian_attr_range(6, 60, 1) ->{187, 210};

get_xilian_attr_range(7, 60, 1) ->{211, 233};

get_xilian_attr_range(8, 60, 1) ->{234, 257};

get_xilian_attr_range(9, 60, 1) ->{258, 280};

get_xilian_attr_range(10, 60, 1) ->{281, 304};

get_xilian_attr_range(1, 70, 1) ->{79, 119};

get_xilian_attr_range(2, 70, 1) ->{120, 139};

get_xilian_attr_range(3, 70, 1) ->{140, 163};

get_xilian_attr_range(4, 70, 1) ->{164, 186};

get_xilian_attr_range(5, 70, 1) ->{187, 210};

get_xilian_attr_range(6, 70, 1) ->{211, 233};

get_xilian_attr_range(7, 70, 1) ->{234, 257};

get_xilian_attr_range(8, 70, 1) ->{258, 280};

get_xilian_attr_range(9, 70, 1) ->{281, 304};

get_xilian_attr_range(10, 70, 1) ->{305, 327};

get_xilian_attr_range(1, 80, 1) ->{89, 139};

get_xilian_attr_range(2, 80, 1) ->{140, 163};

get_xilian_attr_range(3, 80, 1) ->{164, 186};

get_xilian_attr_range(4, 80, 1) ->{187, 210};

get_xilian_attr_range(5, 80, 1) ->{211, 233};

get_xilian_attr_range(6, 80, 1) ->{234, 257};

get_xilian_attr_range(7, 80, 1) ->{258, 280};

get_xilian_attr_range(8, 80, 1) ->{281, 304};

get_xilian_attr_range(9, 80, 1) ->{305, 327};

get_xilian_attr_range(10, 80, 1) ->{328, 351};

get_xilian_attr_range(1, 90, 1) ->{113, 163};

get_xilian_attr_range(2, 90, 1) ->{164, 186};

get_xilian_attr_range(3, 90, 1) ->{187, 210};

get_xilian_attr_range(4, 90, 1) ->{211, 233};

get_xilian_attr_range(5, 90, 1) ->{234, 257};

get_xilian_attr_range(6, 90, 1) ->{258, 280};

get_xilian_attr_range(7, 90, 1) ->{281, 304};

get_xilian_attr_range(8, 90, 1) ->{305, 327};

get_xilian_attr_range(9, 90, 1) ->{328, 351};

get_xilian_attr_range(10, 90, 1) ->{352, 375};

get_xilian_attr_range(1, 100, 1) ->{126, 186};

get_xilian_attr_range(2, 100, 1) ->{187, 210};

get_xilian_attr_range(3, 100, 1) ->{211, 233};

get_xilian_attr_range(4, 100, 1) ->{234, 257};

get_xilian_attr_range(5, 100, 1) ->{258, 280};

get_xilian_attr_range(6, 100, 1) ->{281, 304};

get_xilian_attr_range(7, 100, 1) ->{305, 327};

get_xilian_attr_range(8, 100, 1) ->{328, 351};

get_xilian_attr_range(9, 100, 1) ->{352, 375};

get_xilian_attr_range(10, 100, 1) ->{376, 399};

get_xilian_attr_range(1, 1, 2) ->{2, 11};

get_xilian_attr_range(2, 1, 2) ->{12, 23};

get_xilian_attr_range(3, 1, 2) ->{24, 35};

get_xilian_attr_range(4, 1, 2) ->{36, 47};

get_xilian_attr_range(5, 1, 2) ->{48, 63};

get_xilian_attr_range(6, 1, 2) ->{64, 79};

get_xilian_attr_range(7, 1, 2) ->{80, 99};

get_xilian_attr_range(8, 1, 2) ->{100, 119};

get_xilian_attr_range(9, 1, 2) ->{120, 139};

get_xilian_attr_range(10, 1, 2) ->{140, 163};

get_xilian_attr_range(1, 10, 2) ->{8, 23};

get_xilian_attr_range(2, 10, 2) ->{24, 35};

get_xilian_attr_range(3, 10, 2) ->{36, 47};

get_xilian_attr_range(4, 10, 2) ->{48, 63};

get_xilian_attr_range(5, 10, 2) ->{64, 79};

get_xilian_attr_range(6, 10, 2) ->{80, 99};

get_xilian_attr_range(7, 10, 2) ->{100, 119};

get_xilian_attr_range(8, 10, 2) ->{120, 139};

get_xilian_attr_range(9, 10, 2) ->{140, 163};

get_xilian_attr_range(10, 10, 2) ->{164, 186};

get_xilian_attr_range(1, 20, 2) ->{25, 35};

get_xilian_attr_range(2, 20, 2) ->{36, 47};

get_xilian_attr_range(3, 20, 2) ->{48, 63};

get_xilian_attr_range(4, 20, 2) ->{64, 79};

get_xilian_attr_range(5, 20, 2) ->{80, 99};

get_xilian_attr_range(6, 20, 2) ->{100, 119};

get_xilian_attr_range(7, 20, 2) ->{120, 139};

get_xilian_attr_range(8, 20, 2) ->{140, 163};

get_xilian_attr_range(9, 20, 2) ->{164, 186};

get_xilian_attr_range(10, 20, 2) ->{187, 210};

get_xilian_attr_range(1, 30, 2) ->{27, 47};

get_xilian_attr_range(2, 30, 2) ->{48, 63};

get_xilian_attr_range(3, 30, 2) ->{64, 79};

get_xilian_attr_range(4, 30, 2) ->{80, 99};

get_xilian_attr_range(5, 30, 2) ->{100, 119};

get_xilian_attr_range(6, 30, 2) ->{120, 139};

get_xilian_attr_range(7, 30, 2) ->{140, 163};

get_xilian_attr_range(8, 30, 2) ->{164, 186};

get_xilian_attr_range(9, 30, 2) ->{187, 210};

get_xilian_attr_range(10, 30, 2) ->{211, 233};

get_xilian_attr_range(1, 40, 2) ->{23, 63};

get_xilian_attr_range(2, 40, 2) ->{64, 79};

get_xilian_attr_range(3, 40, 2) ->{80, 99};

get_xilian_attr_range(4, 40, 2) ->{100, 119};

get_xilian_attr_range(5, 40, 2) ->{120, 139};

get_xilian_attr_range(6, 40, 2) ->{140, 163};

get_xilian_attr_range(7, 40, 2) ->{164, 186};

get_xilian_attr_range(8, 40, 2) ->{187, 210};

get_xilian_attr_range(9, 40, 2) ->{211, 233};

get_xilian_attr_range(10, 40, 2) ->{234, 257};

get_xilian_attr_range(1, 50, 2) ->{39, 79};

get_xilian_attr_range(2, 50, 2) ->{80, 99};

get_xilian_attr_range(3, 50, 2) ->{100, 119};

get_xilian_attr_range(4, 50, 2) ->{120, 139};

get_xilian_attr_range(5, 50, 2) ->{140, 163};

get_xilian_attr_range(6, 50, 2) ->{164, 186};

get_xilian_attr_range(7, 50, 2) ->{187, 210};

get_xilian_attr_range(8, 50, 2) ->{211, 233};

get_xilian_attr_range(9, 50, 2) ->{234, 257};

get_xilian_attr_range(10, 50, 2) ->{258, 280};

get_xilian_attr_range(1, 60, 2) ->{59, 99};

get_xilian_attr_range(2, 60, 2) ->{100, 119};

get_xilian_attr_range(3, 60, 2) ->{120, 139};

get_xilian_attr_range(4, 60, 2) ->{140, 163};

get_xilian_attr_range(5, 60, 2) ->{164, 186};

get_xilian_attr_range(6, 60, 2) ->{187, 210};

get_xilian_attr_range(7, 60, 2) ->{211, 233};

get_xilian_attr_range(8, 60, 2) ->{234, 257};

get_xilian_attr_range(9, 60, 2) ->{258, 280};

get_xilian_attr_range(10, 60, 2) ->{281, 304};

get_xilian_attr_range(1, 70, 2) ->{79, 119};

get_xilian_attr_range(2, 70, 2) ->{120, 139};

get_xilian_attr_range(3, 70, 2) ->{140, 163};

get_xilian_attr_range(4, 70, 2) ->{164, 186};

get_xilian_attr_range(5, 70, 2) ->{187, 210};

get_xilian_attr_range(6, 70, 2) ->{211, 233};

get_xilian_attr_range(7, 70, 2) ->{234, 257};

get_xilian_attr_range(8, 70, 2) ->{258, 280};

get_xilian_attr_range(9, 70, 2) ->{281, 304};

get_xilian_attr_range(10, 70, 2) ->{305, 327};

get_xilian_attr_range(1, 80, 2) ->{89, 139};

get_xilian_attr_range(2, 80, 2) ->{140, 163};

get_xilian_attr_range(3, 80, 2) ->{164, 186};

get_xilian_attr_range(4, 80, 2) ->{187, 210};

get_xilian_attr_range(5, 80, 2) ->{211, 233};

get_xilian_attr_range(6, 80, 2) ->{234, 257};

get_xilian_attr_range(7, 80, 2) ->{258, 280};

get_xilian_attr_range(8, 80, 2) ->{281, 304};

get_xilian_attr_range(9, 80, 2) ->{305, 327};

get_xilian_attr_range(10, 80, 2) ->{328, 351};

get_xilian_attr_range(1, 90, 2) ->{113, 163};

get_xilian_attr_range(2, 90, 2) ->{164, 186};

get_xilian_attr_range(3, 90, 2) ->{187, 210};

get_xilian_attr_range(4, 90, 2) ->{211, 233};

get_xilian_attr_range(5, 90, 2) ->{234, 257};

get_xilian_attr_range(6, 90, 2) ->{258, 280};

get_xilian_attr_range(7, 90, 2) ->{281, 304};

get_xilian_attr_range(8, 90, 2) ->{305, 327};

get_xilian_attr_range(9, 90, 2) ->{328, 351};

get_xilian_attr_range(10, 90, 2) ->{352, 375};

get_xilian_attr_range(1, 100, 2) ->{126, 186};

get_xilian_attr_range(2, 100, 2) ->{187, 210};

get_xilian_attr_range(3, 100, 2) ->{211, 233};

get_xilian_attr_range(4, 100, 2) ->{234, 257};

get_xilian_attr_range(5, 100, 2) ->{258, 280};

get_xilian_attr_range(6, 100, 2) ->{281, 304};

get_xilian_attr_range(7, 100, 2) ->{305, 327};

get_xilian_attr_range(8, 100, 2) ->{328, 351};

get_xilian_attr_range(9, 100, 2) ->{352, 375};

get_xilian_attr_range(10, 100, 2) ->{376, 399};

get_xilian_attr_range(1, 1, 3) ->{2, 12};

get_xilian_attr_range(2, 1, 3) ->{13, 25};

get_xilian_attr_range(3, 1, 3) ->{26, 37};

get_xilian_attr_range(4, 1, 3) ->{38, 50};

get_xilian_attr_range(5, 1, 3) ->{51, 67};

get_xilian_attr_range(6, 1, 3) ->{68, 83};

get_xilian_attr_range(7, 1, 3) ->{84, 104};

get_xilian_attr_range(8, 1, 3) ->{105, 125};

get_xilian_attr_range(9, 1, 3) ->{126, 146};

get_xilian_attr_range(10, 1, 3) ->{147, 171};

get_xilian_attr_range(1, 10, 3) ->{15, 25};

get_xilian_attr_range(2, 10, 3) ->{26, 37};

get_xilian_attr_range(3, 10, 3) ->{38, 50};

get_xilian_attr_range(4, 10, 3) ->{51, 67};

get_xilian_attr_range(5, 10, 3) ->{68, 83};

get_xilian_attr_range(6, 10, 3) ->{84, 104};

get_xilian_attr_range(7, 10, 3) ->{105, 125};

get_xilian_attr_range(8, 10, 3) ->{126, 146};

get_xilian_attr_range(9, 10, 3) ->{147, 171};

get_xilian_attr_range(10, 10, 3) ->{172, 196};

get_xilian_attr_range(1, 20, 3) ->{27, 37};

get_xilian_attr_range(2, 20, 3) ->{38, 50};

get_xilian_attr_range(3, 20, 3) ->{51, 67};

get_xilian_attr_range(4, 20, 3) ->{68, 83};

get_xilian_attr_range(5, 20, 3) ->{84, 104};

get_xilian_attr_range(6, 20, 3) ->{105, 125};

get_xilian_attr_range(7, 20, 3) ->{126, 146};

get_xilian_attr_range(8, 20, 3) ->{147, 171};

get_xilian_attr_range(9, 20, 3) ->{172, 196};

get_xilian_attr_range(10, 20, 3) ->{197, 220};

get_xilian_attr_range(1, 30, 3) ->{35, 50};

get_xilian_attr_range(2, 30, 3) ->{51, 67};

get_xilian_attr_range(3, 30, 3) ->{68, 83};

get_xilian_attr_range(4, 30, 3) ->{84, 104};

get_xilian_attr_range(5, 30, 3) ->{105, 125};

get_xilian_attr_range(6, 30, 3) ->{126, 146};

get_xilian_attr_range(7, 30, 3) ->{147, 171};

get_xilian_attr_range(8, 30, 3) ->{172, 196};

get_xilian_attr_range(9, 30, 3) ->{197, 220};

get_xilian_attr_range(10, 30, 3) ->{221, 245};

get_xilian_attr_range(1, 40, 3) ->{47, 67};

get_xilian_attr_range(2, 40, 3) ->{68, 83};

get_xilian_attr_range(3, 40, 3) ->{84, 104};

get_xilian_attr_range(4, 40, 3) ->{105, 125};

get_xilian_attr_range(5, 40, 3) ->{126, 146};

get_xilian_attr_range(6, 40, 3) ->{147, 171};

get_xilian_attr_range(7, 40, 3) ->{172, 196};

get_xilian_attr_range(8, 40, 3) ->{197, 220};

get_xilian_attr_range(9, 40, 3) ->{221, 245};

get_xilian_attr_range(10, 40, 3) ->{246, 270};

get_xilian_attr_range(1, 50, 3) ->{58, 83};

get_xilian_attr_range(2, 50, 3) ->{84, 104};

get_xilian_attr_range(3, 50, 3) ->{105, 125};

get_xilian_attr_range(4, 50, 3) ->{126, 146};

get_xilian_attr_range(5, 50, 3) ->{147, 171};

get_xilian_attr_range(6, 50, 3) ->{172, 196};

get_xilian_attr_range(7, 50, 3) ->{197, 220};

get_xilian_attr_range(8, 50, 3) ->{221, 245};

get_xilian_attr_range(9, 50, 3) ->{246, 270};

get_xilian_attr_range(10, 50, 3) ->{271, 294};

get_xilian_attr_range(1, 60, 3) ->{74, 104};

get_xilian_attr_range(2, 60, 3) ->{105, 125};

get_xilian_attr_range(3, 60, 3) ->{126, 146};

get_xilian_attr_range(4, 60, 3) ->{147, 171};

get_xilian_attr_range(5, 60, 3) ->{172, 196};

get_xilian_attr_range(6, 60, 3) ->{197, 220};

get_xilian_attr_range(7, 60, 3) ->{221, 245};

get_xilian_attr_range(8, 60, 3) ->{246, 270};

get_xilian_attr_range(9, 60, 3) ->{271, 294};

get_xilian_attr_range(10, 60, 3) ->{295, 319};

get_xilian_attr_range(1, 70, 3) ->{85, 125};

get_xilian_attr_range(2, 70, 3) ->{126, 146};

get_xilian_attr_range(3, 70, 3) ->{147, 171};

get_xilian_attr_range(4, 70, 3) ->{172, 196};

get_xilian_attr_range(5, 70, 3) ->{197, 220};

get_xilian_attr_range(6, 70, 3) ->{221, 245};

get_xilian_attr_range(7, 70, 3) ->{246, 270};

get_xilian_attr_range(8, 70, 3) ->{271, 294};

get_xilian_attr_range(9, 70, 3) ->{295, 319};

get_xilian_attr_range(10, 70, 3) ->{320, 344};

get_xilian_attr_range(1, 80, 3) ->{106, 146};

get_xilian_attr_range(2, 80, 3) ->{147, 171};

get_xilian_attr_range(3, 80, 3) ->{172, 196};

get_xilian_attr_range(4, 80, 3) ->{197, 220};

get_xilian_attr_range(5, 80, 3) ->{221, 245};

get_xilian_attr_range(6, 80, 3) ->{246, 270};

get_xilian_attr_range(7, 80, 3) ->{271, 294};

get_xilian_attr_range(8, 80, 3) ->{295, 319};

get_xilian_attr_range(9, 80, 3) ->{320, 344};

get_xilian_attr_range(10, 80, 3) ->{345, 369};

get_xilian_attr_range(1, 90, 3) ->{121, 171};

get_xilian_attr_range(2, 90, 3) ->{172, 196};

get_xilian_attr_range(3, 90, 3) ->{197, 220};

get_xilian_attr_range(4, 90, 3) ->{221, 245};

get_xilian_attr_range(5, 90, 3) ->{246, 270};

get_xilian_attr_range(6, 90, 3) ->{271, 294};

get_xilian_attr_range(7, 90, 3) ->{295, 319};

get_xilian_attr_range(8, 90, 3) ->{320, 344};

get_xilian_attr_range(9, 90, 3) ->{345, 369};

get_xilian_attr_range(10, 90, 3) ->{370, 393};

get_xilian_attr_range(1, 100, 3) ->{146, 196};

get_xilian_attr_range(2, 100, 3) ->{197, 220};

get_xilian_attr_range(3, 100, 3) ->{221, 245};

get_xilian_attr_range(4, 100, 3) ->{246, 270};

get_xilian_attr_range(5, 100, 3) ->{271, 294};

get_xilian_attr_range(6, 100, 3) ->{295, 319};

get_xilian_attr_range(7, 100, 3) ->{320, 344};

get_xilian_attr_range(8, 100, 3) ->{345, 369};

get_xilian_attr_range(9, 100, 3) ->{370, 393};

get_xilian_attr_range(10, 100, 3) ->{394, 419};

get_xilian_attr_range(1, 1, 4) ->{2, 12};

get_xilian_attr_range(2, 1, 4) ->{13, 25};

get_xilian_attr_range(3, 1, 4) ->{26, 37};

get_xilian_attr_range(4, 1, 4) ->{38, 50};

get_xilian_attr_range(5, 1, 4) ->{51, 67};

get_xilian_attr_range(6, 1, 4) ->{68, 83};

get_xilian_attr_range(7, 1, 4) ->{84, 104};

get_xilian_attr_range(8, 1, 4) ->{105, 125};

get_xilian_attr_range(9, 1, 4) ->{126, 146};

get_xilian_attr_range(10, 1, 4) ->{147, 171};

get_xilian_attr_range(1, 10, 4) ->{15, 25};

get_xilian_attr_range(2, 10, 4) ->{26, 37};

get_xilian_attr_range(3, 10, 4) ->{38, 50};

get_xilian_attr_range(4, 10, 4) ->{51, 67};

get_xilian_attr_range(5, 10, 4) ->{68, 83};

get_xilian_attr_range(6, 10, 4) ->{84, 104};

get_xilian_attr_range(7, 10, 4) ->{105, 125};

get_xilian_attr_range(8, 10, 4) ->{126, 146};

get_xilian_attr_range(9, 10, 4) ->{147, 171};

get_xilian_attr_range(10, 10, 4) ->{172, 196};

get_xilian_attr_range(1, 20, 4) ->{27, 37};

get_xilian_attr_range(2, 20, 4) ->{38, 50};

get_xilian_attr_range(3, 20, 4) ->{51, 67};

get_xilian_attr_range(4, 20, 4) ->{68, 83};

get_xilian_attr_range(5, 20, 4) ->{84, 104};

get_xilian_attr_range(6, 20, 4) ->{105, 125};

get_xilian_attr_range(7, 20, 4) ->{126, 146};

get_xilian_attr_range(8, 20, 4) ->{147, 171};

get_xilian_attr_range(9, 20, 4) ->{172, 196};

get_xilian_attr_range(10, 20, 4) ->{197, 220};

get_xilian_attr_range(1, 30, 4) ->{35, 50};

get_xilian_attr_range(2, 30, 4) ->{51, 67};

get_xilian_attr_range(3, 30, 4) ->{68, 83};

get_xilian_attr_range(4, 30, 4) ->{84, 104};

get_xilian_attr_range(5, 30, 4) ->{105, 125};

get_xilian_attr_range(6, 30, 4) ->{126, 146};

get_xilian_attr_range(7, 30, 4) ->{147, 171};

get_xilian_attr_range(8, 30, 4) ->{172, 196};

get_xilian_attr_range(9, 30, 4) ->{197, 220};

get_xilian_attr_range(10, 30, 4) ->{221, 245};

get_xilian_attr_range(1, 40, 4) ->{47, 67};

get_xilian_attr_range(2, 40, 4) ->{68, 83};

get_xilian_attr_range(3, 40, 4) ->{84, 104};

get_xilian_attr_range(4, 40, 4) ->{105, 125};

get_xilian_attr_range(5, 40, 4) ->{126, 146};

get_xilian_attr_range(6, 40, 4) ->{147, 171};

get_xilian_attr_range(7, 40, 4) ->{172, 196};

get_xilian_attr_range(8, 40, 4) ->{197, 220};

get_xilian_attr_range(9, 40, 4) ->{221, 245};

get_xilian_attr_range(10, 40, 4) ->{246, 270};

get_xilian_attr_range(1, 50, 4) ->{58, 83};

get_xilian_attr_range(2, 50, 4) ->{84, 104};

get_xilian_attr_range(3, 50, 4) ->{105, 125};

get_xilian_attr_range(4, 50, 4) ->{126, 146};

get_xilian_attr_range(5, 50, 4) ->{147, 171};

get_xilian_attr_range(6, 50, 4) ->{172, 196};

get_xilian_attr_range(7, 50, 4) ->{197, 220};

get_xilian_attr_range(8, 50, 4) ->{221, 245};

get_xilian_attr_range(9, 50, 4) ->{246, 270};

get_xilian_attr_range(10, 50, 4) ->{271, 294};

get_xilian_attr_range(1, 60, 4) ->{74, 104};

get_xilian_attr_range(2, 60, 4) ->{105, 125};

get_xilian_attr_range(3, 60, 4) ->{126, 146};

get_xilian_attr_range(4, 60, 4) ->{147, 171};

get_xilian_attr_range(5, 60, 4) ->{172, 196};

get_xilian_attr_range(6, 60, 4) ->{197, 220};

get_xilian_attr_range(7, 60, 4) ->{221, 245};

get_xilian_attr_range(8, 60, 4) ->{246, 270};

get_xilian_attr_range(9, 60, 4) ->{271, 294};

get_xilian_attr_range(10, 60, 4) ->{295, 319};

get_xilian_attr_range(1, 70, 4) ->{85, 125};

get_xilian_attr_range(2, 70, 4) ->{126, 146};

get_xilian_attr_range(3, 70, 4) ->{147, 171};

get_xilian_attr_range(4, 70, 4) ->{172, 196};

get_xilian_attr_range(5, 70, 4) ->{197, 220};

get_xilian_attr_range(6, 70, 4) ->{221, 245};

get_xilian_attr_range(7, 70, 4) ->{246, 270};

get_xilian_attr_range(8, 70, 4) ->{271, 294};

get_xilian_attr_range(9, 70, 4) ->{295, 319};

get_xilian_attr_range(10, 70, 4) ->{320, 344};

get_xilian_attr_range(1, 80, 4) ->{106, 146};

get_xilian_attr_range(2, 80, 4) ->{147, 171};

get_xilian_attr_range(3, 80, 4) ->{172, 196};

get_xilian_attr_range(4, 80, 4) ->{197, 220};

get_xilian_attr_range(5, 80, 4) ->{221, 245};

get_xilian_attr_range(6, 80, 4) ->{246, 270};

get_xilian_attr_range(7, 80, 4) ->{271, 294};

get_xilian_attr_range(8, 80, 4) ->{295, 319};

get_xilian_attr_range(9, 80, 4) ->{320, 344};

get_xilian_attr_range(10, 80, 4) ->{345, 369};

get_xilian_attr_range(1, 90, 4) ->{121, 171};

get_xilian_attr_range(2, 90, 4) ->{172, 196};

get_xilian_attr_range(3, 90, 4) ->{197, 220};

get_xilian_attr_range(4, 90, 4) ->{221, 245};

get_xilian_attr_range(5, 90, 4) ->{246, 270};

get_xilian_attr_range(6, 90, 4) ->{271, 294};

get_xilian_attr_range(7, 90, 4) ->{295, 319};

get_xilian_attr_range(8, 90, 4) ->{320, 344};

get_xilian_attr_range(9, 90, 4) ->{345, 369};

get_xilian_attr_range(10, 90, 4) ->{370, 393};

get_xilian_attr_range(1, 100, 4) ->{146, 196};

get_xilian_attr_range(2, 100, 4) ->{197, 220};

get_xilian_attr_range(3, 100, 4) ->{221, 245};

get_xilian_attr_range(4, 100, 4) ->{246, 270};

get_xilian_attr_range(5, 100, 4) ->{271, 294};

get_xilian_attr_range(6, 100, 4) ->{295, 319};

get_xilian_attr_range(7, 100, 4) ->{320, 344};

get_xilian_attr_range(8, 100, 4) ->{345, 369};

get_xilian_attr_range(9, 100, 4) ->{370, 393};

get_xilian_attr_range(10, 100, 4) ->{394, 419};

get_xilian_attr_range(1, 1, 5) ->{2, 17};

get_xilian_attr_range(2, 1, 5) ->{18, 35};

get_xilian_attr_range(3, 1, 5) ->{36, 53};

get_xilian_attr_range(4, 1, 5) ->{54, 71};

get_xilian_attr_range(5, 1, 5) ->{72, 95};

get_xilian_attr_range(6, 1, 5) ->{96, 119};

get_xilian_attr_range(7, 1, 5) ->{120, 149};

get_xilian_attr_range(8, 1, 5) ->{150, 179};

get_xilian_attr_range(9, 1, 5) ->{180, 209};

get_xilian_attr_range(10, 1, 5) ->{210, 244};

get_xilian_attr_range(1, 10, 5) ->{10, 35};

get_xilian_attr_range(2, 10, 5) ->{36, 53};

get_xilian_attr_range(3, 10, 5) ->{54, 71};

get_xilian_attr_range(4, 10, 5) ->{72, 95};

get_xilian_attr_range(5, 10, 5) ->{96, 119};

get_xilian_attr_range(6, 10, 5) ->{120, 149};

get_xilian_attr_range(7, 10, 5) ->{150, 179};

get_xilian_attr_range(8, 10, 5) ->{180, 209};

get_xilian_attr_range(9, 10, 5) ->{210, 244};

get_xilian_attr_range(10, 10, 5) ->{245, 280};

get_xilian_attr_range(1, 20, 5) ->{23, 53};

get_xilian_attr_range(2, 20, 5) ->{54, 71};

get_xilian_attr_range(3, 20, 5) ->{72, 95};

get_xilian_attr_range(4, 20, 5) ->{96, 119};

get_xilian_attr_range(5, 20, 5) ->{120, 149};

get_xilian_attr_range(6, 20, 5) ->{150, 179};

get_xilian_attr_range(7, 20, 5) ->{180, 209};

get_xilian_attr_range(8, 20, 5) ->{210, 244};

get_xilian_attr_range(9, 20, 5) ->{245, 280};

get_xilian_attr_range(10, 20, 5) ->{281, 315};

get_xilian_attr_range(1, 30, 5) ->{36, 71};

get_xilian_attr_range(2, 30, 5) ->{72, 95};

get_xilian_attr_range(3, 30, 5) ->{96, 119};

get_xilian_attr_range(4, 30, 5) ->{120, 149};

get_xilian_attr_range(5, 30, 5) ->{150, 179};

get_xilian_attr_range(6, 30, 5) ->{180, 209};

get_xilian_attr_range(7, 30, 5) ->{210, 244};

get_xilian_attr_range(8, 30, 5) ->{245, 280};

get_xilian_attr_range(9, 30, 5) ->{281, 315};

get_xilian_attr_range(10, 30, 5) ->{316, 351};

get_xilian_attr_range(1, 40, 5) ->{45, 95};

get_xilian_attr_range(2, 40, 5) ->{96, 119};

get_xilian_attr_range(3, 40, 5) ->{120, 149};

get_xilian_attr_range(4, 40, 5) ->{150, 179};

get_xilian_attr_range(5, 40, 5) ->{180, 209};

get_xilian_attr_range(6, 40, 5) ->{210, 244};

get_xilian_attr_range(7, 40, 5) ->{245, 280};

get_xilian_attr_range(8, 40, 5) ->{281, 315};

get_xilian_attr_range(9, 40, 5) ->{316, 351};

get_xilian_attr_range(10, 40, 5) ->{352, 386};

get_xilian_attr_range(1, 50, 5) ->{59, 119};

get_xilian_attr_range(2, 50, 5) ->{120, 149};

get_xilian_attr_range(3, 50, 5) ->{150, 179};

get_xilian_attr_range(4, 50, 5) ->{180, 209};

get_xilian_attr_range(5, 50, 5) ->{210, 244};

get_xilian_attr_range(6, 50, 5) ->{245, 280};

get_xilian_attr_range(7, 50, 5) ->{281, 315};

get_xilian_attr_range(8, 50, 5) ->{316, 351};

get_xilian_attr_range(9, 50, 5) ->{352, 386};

get_xilian_attr_range(10, 50, 5) ->{387, 421};

get_xilian_attr_range(1, 60, 5) ->{69, 149};

get_xilian_attr_range(2, 60, 5) ->{150, 179};

get_xilian_attr_range(3, 60, 5) ->{180, 209};

get_xilian_attr_range(4, 60, 5) ->{210, 244};

get_xilian_attr_range(5, 60, 5) ->{245, 280};

get_xilian_attr_range(6, 60, 5) ->{281, 315};

get_xilian_attr_range(7, 60, 5) ->{316, 351};

get_xilian_attr_range(8, 60, 5) ->{352, 386};

get_xilian_attr_range(9, 60, 5) ->{387, 421};

get_xilian_attr_range(10, 60, 5) ->{422, 457};

get_xilian_attr_range(1, 70, 5) ->{99, 179};

get_xilian_attr_range(2, 70, 5) ->{180, 209};

get_xilian_attr_range(3, 70, 5) ->{210, 244};

get_xilian_attr_range(4, 70, 5) ->{245, 280};

get_xilian_attr_range(5, 70, 5) ->{281, 315};

get_xilian_attr_range(6, 70, 5) ->{316, 351};

get_xilian_attr_range(7, 70, 5) ->{352, 386};

get_xilian_attr_range(8, 70, 5) ->{387, 421};

get_xilian_attr_range(9, 70, 5) ->{422, 457};

get_xilian_attr_range(10, 70, 5) ->{458, 492};

get_xilian_attr_range(1, 80, 5) ->{109, 209};

get_xilian_attr_range(2, 80, 5) ->{210, 244};

get_xilian_attr_range(3, 80, 5) ->{245, 280};

get_xilian_attr_range(4, 80, 5) ->{281, 315};

get_xilian_attr_range(5, 80, 5) ->{316, 351};

get_xilian_attr_range(6, 80, 5) ->{352, 386};

get_xilian_attr_range(7, 80, 5) ->{387, 421};

get_xilian_attr_range(8, 80, 5) ->{422, 457};

get_xilian_attr_range(9, 80, 5) ->{458, 492};

get_xilian_attr_range(10, 80, 5) ->{493, 527};

get_xilian_attr_range(1, 90, 5) ->{144, 244};

get_xilian_attr_range(2, 90, 5) ->{245, 280};

get_xilian_attr_range(3, 90, 5) ->{281, 315};

get_xilian_attr_range(4, 90, 5) ->{316, 351};

get_xilian_attr_range(5, 90, 5) ->{352, 386};

get_xilian_attr_range(6, 90, 5) ->{387, 421};

get_xilian_attr_range(7, 90, 5) ->{422, 457};

get_xilian_attr_range(8, 90, 5) ->{458, 492};

get_xilian_attr_range(9, 90, 5) ->{493, 527};

get_xilian_attr_range(10, 90, 5) ->{528, 563};

get_xilian_attr_range(1, 100, 5) ->{180, 280};

get_xilian_attr_range(2, 100, 5) ->{281, 315};

get_xilian_attr_range(3, 100, 5) ->{316, 351};

get_xilian_attr_range(4, 100, 5) ->{352, 386};

get_xilian_attr_range(5, 100, 5) ->{387, 421};

get_xilian_attr_range(6, 100, 5) ->{422, 457};

get_xilian_attr_range(7, 100, 5) ->{458, 492};

get_xilian_attr_range(8, 100, 5) ->{493, 527};

get_xilian_attr_range(9, 100, 5) ->{528, 563};

get_xilian_attr_range(10, 100, 5) ->{564, 599};

get_xilian_attr_range(1, 1, 6) ->{1, 5};

get_xilian_attr_range(2, 1, 6) ->{6, 11};

get_xilian_attr_range(3, 1, 6) ->{12, 17};

get_xilian_attr_range(4, 1, 6) ->{18, 23};

get_xilian_attr_range(5, 1, 6) ->{24, 31};

get_xilian_attr_range(6, 1, 6) ->{32, 39};

get_xilian_attr_range(7, 1, 6) ->{40, 49};

get_xilian_attr_range(8, 1, 6) ->{50, 59};

get_xilian_attr_range(9, 1, 6) ->{60, 69};

get_xilian_attr_range(10, 1, 6) ->{70, 81};

get_xilian_attr_range(1, 10, 6) ->{7, 11};

get_xilian_attr_range(2, 10, 6) ->{12, 17};

get_xilian_attr_range(3, 10, 6) ->{18, 23};

get_xilian_attr_range(4, 10, 6) ->{24, 31};

get_xilian_attr_range(5, 10, 6) ->{32, 39};

get_xilian_attr_range(6, 10, 6) ->{40, 49};

get_xilian_attr_range(7, 10, 6) ->{50, 59};

get_xilian_attr_range(8, 10, 6) ->{60, 69};

get_xilian_attr_range(9, 10, 6) ->{70, 81};

get_xilian_attr_range(10, 10, 6) ->{82, 93};

get_xilian_attr_range(1, 20, 6) ->{12, 17};

get_xilian_attr_range(2, 20, 6) ->{18, 23};

get_xilian_attr_range(3, 20, 6) ->{24, 31};

get_xilian_attr_range(4, 20, 6) ->{32, 39};

get_xilian_attr_range(5, 20, 6) ->{40, 49};

get_xilian_attr_range(6, 20, 6) ->{50, 59};

get_xilian_attr_range(7, 20, 6) ->{60, 69};

get_xilian_attr_range(8, 20, 6) ->{70, 81};

get_xilian_attr_range(9, 20, 6) ->{82, 93};

get_xilian_attr_range(10, 20, 6) ->{94, 104};

get_xilian_attr_range(1, 30, 6) ->{18, 23};

get_xilian_attr_range(2, 30, 6) ->{24, 31};

get_xilian_attr_range(3, 30, 6) ->{32, 39};

get_xilian_attr_range(4, 30, 6) ->{40, 49};

get_xilian_attr_range(5, 30, 6) ->{50, 59};

get_xilian_attr_range(6, 30, 6) ->{60, 69};

get_xilian_attr_range(7, 30, 6) ->{70, 81};

get_xilian_attr_range(8, 30, 6) ->{82, 93};

get_xilian_attr_range(9, 30, 6) ->{94, 104};

get_xilian_attr_range(10, 30, 6) ->{105, 116};

get_xilian_attr_range(1, 40, 6) ->{24, 31};

get_xilian_attr_range(2, 40, 6) ->{32, 39};

get_xilian_attr_range(3, 40, 6) ->{40, 49};

get_xilian_attr_range(4, 40, 6) ->{50, 59};

get_xilian_attr_range(5, 40, 6) ->{60, 69};

get_xilian_attr_range(6, 40, 6) ->{70, 81};

get_xilian_attr_range(7, 40, 6) ->{82, 93};

get_xilian_attr_range(8, 40, 6) ->{94, 104};

get_xilian_attr_range(9, 40, 6) ->{105, 116};

get_xilian_attr_range(10, 40, 6) ->{117, 128};

get_xilian_attr_range(1, 50, 6) ->{31, 39};

get_xilian_attr_range(2, 50, 6) ->{40, 49};

get_xilian_attr_range(3, 50, 6) ->{50, 59};

get_xilian_attr_range(4, 50, 6) ->{60, 69};

get_xilian_attr_range(5, 50, 6) ->{70, 81};

get_xilian_attr_range(6, 50, 6) ->{82, 93};

get_xilian_attr_range(7, 50, 6) ->{94, 104};

get_xilian_attr_range(8, 50, 6) ->{105, 116};

get_xilian_attr_range(9, 50, 6) ->{117, 128};

get_xilian_attr_range(10, 50, 6) ->{129, 140};

get_xilian_attr_range(1, 60, 6) ->{41, 49};

get_xilian_attr_range(2, 60, 6) ->{50, 59};

get_xilian_attr_range(3, 60, 6) ->{60, 69};

get_xilian_attr_range(4, 60, 6) ->{70, 81};

get_xilian_attr_range(5, 60, 6) ->{82, 93};

get_xilian_attr_range(6, 60, 6) ->{94, 104};

get_xilian_attr_range(7, 60, 6) ->{105, 116};

get_xilian_attr_range(8, 60, 6) ->{117, 128};

get_xilian_attr_range(9, 60, 6) ->{129, 140};

get_xilian_attr_range(10, 60, 6) ->{141, 151};

get_xilian_attr_range(1, 70, 6) ->{152, 59};

get_xilian_attr_range(2, 70, 6) ->{60, 69};

get_xilian_attr_range(3, 70, 6) ->{70, 81};

get_xilian_attr_range(4, 70, 6) ->{82, 93};

get_xilian_attr_range(5, 70, 6) ->{94, 104};

get_xilian_attr_range(6, 70, 6) ->{105, 116};

get_xilian_attr_range(7, 70, 6) ->{117, 128};

get_xilian_attr_range(8, 70, 6) ->{129, 140};

get_xilian_attr_range(9, 70, 6) ->{141, 151};

get_xilian_attr_range(10, 70, 6) ->{152, 163};

get_xilian_attr_range(1, 80, 6) ->{164, 69};

get_xilian_attr_range(2, 80, 6) ->{70, 81};

get_xilian_attr_range(3, 80, 6) ->{82, 93};

get_xilian_attr_range(4, 80, 6) ->{94, 104};

get_xilian_attr_range(5, 80, 6) ->{105, 116};

get_xilian_attr_range(6, 80, 6) ->{117, 128};

get_xilian_attr_range(7, 80, 6) ->{129, 140};

get_xilian_attr_range(8, 80, 6) ->{141, 151};

get_xilian_attr_range(9, 80, 6) ->{152, 163};

get_xilian_attr_range(10, 80, 6) ->{164, 175};

get_xilian_attr_range(1, 90, 6) ->{176, 81};

get_xilian_attr_range(2, 90, 6) ->{82, 93};

get_xilian_attr_range(3, 90, 6) ->{94, 104};

get_xilian_attr_range(4, 90, 6) ->{105, 116};

get_xilian_attr_range(5, 90, 6) ->{117, 128};

get_xilian_attr_range(6, 90, 6) ->{129, 140};

get_xilian_attr_range(7, 90, 6) ->{141, 151};

get_xilian_attr_range(8, 90, 6) ->{152, 163};

get_xilian_attr_range(9, 90, 6) ->{164, 175};

get_xilian_attr_range(10, 90, 6) ->{176, 187};

get_xilian_attr_range(1, 100, 6) ->{188, 93};

get_xilian_attr_range(2, 100, 6) ->{94, 104};

get_xilian_attr_range(3, 100, 6) ->{105, 116};

get_xilian_attr_range(4, 100, 6) ->{117, 128};

get_xilian_attr_range(5, 100, 6) ->{129, 140};

get_xilian_attr_range(6, 100, 6) ->{141, 151};

get_xilian_attr_range(7, 100, 6) ->{152, 163};

get_xilian_attr_range(8, 100, 6) ->{164, 175};

get_xilian_attr_range(9, 100, 6) ->{176, 187};

get_xilian_attr_range(10, 100, 6) ->{188, 199};

get_xilian_attr_range(1, 1, 7) ->{1, 1};

get_xilian_attr_range(2, 1, 7) ->{2, 3};

get_xilian_attr_range(3, 1, 7) ->{4, 4};

get_xilian_attr_range(4, 1, 7) ->{5, 6};

get_xilian_attr_range(5, 1, 7) ->{7, 8};

get_xilian_attr_range(6, 1, 7) ->{9, 10};

get_xilian_attr_range(7, 1, 7) ->{11, 12};

get_xilian_attr_range(8, 1, 7) ->{13, 14};

get_xilian_attr_range(9, 1, 7) ->{15, 17};

get_xilian_attr_range(10, 1, 7) ->{18, 20};

get_xilian_attr_range(1, 10, 7) ->{3, 3};

get_xilian_attr_range(2, 10, 7) ->{4, 4};

get_xilian_attr_range(3, 10, 7) ->{5, 6};

get_xilian_attr_range(4, 10, 7) ->{7, 8};

get_xilian_attr_range(5, 10, 7) ->{9, 10};

get_xilian_attr_range(6, 10, 7) ->{11, 12};

get_xilian_attr_range(7, 10, 7) ->{13, 14};

get_xilian_attr_range(8, 10, 7) ->{15, 17};

get_xilian_attr_range(9, 10, 7) ->{18, 20};

get_xilian_attr_range(10, 10, 7) ->{21, 22};

get_xilian_attr_range(1, 20, 7) ->{4, 4};

get_xilian_attr_range(2, 20, 7) ->{5, 6};

get_xilian_attr_range(3, 20, 7) ->{7, 8};

get_xilian_attr_range(4, 20, 7) ->{9, 10};

get_xilian_attr_range(5, 20, 7) ->{11, 12};

get_xilian_attr_range(6, 20, 7) ->{13, 14};

get_xilian_attr_range(7, 20, 7) ->{15, 17};

get_xilian_attr_range(8, 20, 7) ->{18, 20};

get_xilian_attr_range(9, 20, 7) ->{21, 22};

get_xilian_attr_range(10, 20, 7) ->{23, 25};

get_xilian_attr_range(1, 30, 7) ->{6, 6};

get_xilian_attr_range(2, 30, 7) ->{7, 8};

get_xilian_attr_range(3, 30, 7) ->{9, 10};

get_xilian_attr_range(4, 30, 7) ->{11, 12};

get_xilian_attr_range(5, 30, 7) ->{13, 14};

get_xilian_attr_range(6, 30, 7) ->{15, 17};

get_xilian_attr_range(7, 30, 7) ->{18, 20};

get_xilian_attr_range(8, 30, 7) ->{21, 22};

get_xilian_attr_range(9, 30, 7) ->{23, 25};

get_xilian_attr_range(10, 30, 7) ->{26, 28};

get_xilian_attr_range(1, 40, 7) ->{8, 8};

get_xilian_attr_range(2, 40, 7) ->{9, 10};

get_xilian_attr_range(3, 40, 7) ->{11, 12};

get_xilian_attr_range(4, 40, 7) ->{13, 14};

get_xilian_attr_range(5, 40, 7) ->{15, 17};

get_xilian_attr_range(6, 40, 7) ->{18, 20};

get_xilian_attr_range(7, 40, 7) ->{21, 22};

get_xilian_attr_range(8, 40, 7) ->{23, 25};

get_xilian_attr_range(9, 40, 7) ->{26, 28};

get_xilian_attr_range(10, 40, 7) ->{29, 31};

get_xilian_attr_range(1, 50, 7) ->{10, 10};

get_xilian_attr_range(2, 50, 7) ->{11, 12};

get_xilian_attr_range(3, 50, 7) ->{13, 14};

get_xilian_attr_range(4, 50, 7) ->{15, 17};

get_xilian_attr_range(5, 50, 7) ->{18, 20};

get_xilian_attr_range(6, 50, 7) ->{21, 22};

get_xilian_attr_range(7, 50, 7) ->{23, 25};

get_xilian_attr_range(8, 50, 7) ->{26, 28};

get_xilian_attr_range(9, 50, 7) ->{29, 31};

get_xilian_attr_range(10, 50, 7) ->{32, 34};

get_xilian_attr_range(1, 60, 7) ->{12, 12};

get_xilian_attr_range(2, 60, 7) ->{13, 14};

get_xilian_attr_range(3, 60, 7) ->{15, 17};

get_xilian_attr_range(4, 60, 7) ->{18, 20};

get_xilian_attr_range(5, 60, 7) ->{21, 22};

get_xilian_attr_range(6, 60, 7) ->{23, 25};

get_xilian_attr_range(7, 60, 7) ->{26, 28};

get_xilian_attr_range(8, 60, 7) ->{29, 31};

get_xilian_attr_range(9, 60, 7) ->{32, 34};

get_xilian_attr_range(10, 60, 7) ->{35, 37};

get_xilian_attr_range(1, 70, 7) ->{14, 14};

get_xilian_attr_range(2, 70, 7) ->{15, 17};

get_xilian_attr_range(3, 70, 7) ->{18, 20};

get_xilian_attr_range(4, 70, 7) ->{21, 22};

get_xilian_attr_range(5, 70, 7) ->{23, 25};

get_xilian_attr_range(6, 70, 7) ->{26, 28};

get_xilian_attr_range(7, 70, 7) ->{29, 31};

get_xilian_attr_range(8, 70, 7) ->{32, 34};

get_xilian_attr_range(9, 70, 7) ->{35, 37};

get_xilian_attr_range(10, 70, 7) ->{38, 39};

get_xilian_attr_range(1, 80, 7) ->{17, 17};

get_xilian_attr_range(2, 80, 7) ->{18, 20};

get_xilian_attr_range(3, 80, 7) ->{21, 22};

get_xilian_attr_range(4, 80, 7) ->{23, 25};

get_xilian_attr_range(5, 80, 7) ->{26, 28};

get_xilian_attr_range(6, 80, 7) ->{29, 31};

get_xilian_attr_range(7, 80, 7) ->{32, 34};

get_xilian_attr_range(8, 80, 7) ->{35, 37};

get_xilian_attr_range(9, 80, 7) ->{38, 39};

get_xilian_attr_range(10, 80, 7) ->{40, 42};

get_xilian_attr_range(1, 90, 7) ->{20, 20};

get_xilian_attr_range(2, 90, 7) ->{21, 22};

get_xilian_attr_range(3, 90, 7) ->{23, 25};

get_xilian_attr_range(4, 90, 7) ->{26, 28};

get_xilian_attr_range(5, 90, 7) ->{29, 31};

get_xilian_attr_range(6, 90, 7) ->{32, 34};

get_xilian_attr_range(7, 90, 7) ->{35, 37};

get_xilian_attr_range(8, 90, 7) ->{38, 39};

get_xilian_attr_range(9, 90, 7) ->{40, 42};

get_xilian_attr_range(10, 90, 7) ->{43, 45};

get_xilian_attr_range(1, 100, 7) ->{22, 22};

get_xilian_attr_range(2, 100, 7) ->{23, 25};

get_xilian_attr_range(3, 100, 7) ->{26, 28};

get_xilian_attr_range(4, 100, 7) ->{29, 31};

get_xilian_attr_range(5, 100, 7) ->{32, 34};

get_xilian_attr_range(6, 100, 7) ->{35, 37};

get_xilian_attr_range(7, 100, 7) ->{38, 39};

get_xilian_attr_range(8, 100, 7) ->{40, 42};

get_xilian_attr_range(9, 100, 7) ->{43, 45};

get_xilian_attr_range(10, 100, 7) ->{46, 48};

get_xilian_attr_range(1, 1, 8) ->{1, 1};

get_xilian_attr_range(2, 1, 8) ->{2, 3};

get_xilian_attr_range(3, 1, 8) ->{4, 4};

get_xilian_attr_range(4, 1, 8) ->{5, 6};

get_xilian_attr_range(5, 1, 8) ->{7, 8};

get_xilian_attr_range(6, 1, 8) ->{9, 10};

get_xilian_attr_range(7, 1, 8) ->{11, 12};

get_xilian_attr_range(8, 1, 8) ->{13, 14};

get_xilian_attr_range(9, 1, 8) ->{15, 17};

get_xilian_attr_range(10, 1, 8) ->{18, 20};

get_xilian_attr_range(1, 10, 8) ->{3, 3};

get_xilian_attr_range(2, 10, 8) ->{4, 4};

get_xilian_attr_range(3, 10, 8) ->{5, 6};

get_xilian_attr_range(4, 10, 8) ->{7, 8};

get_xilian_attr_range(5, 10, 8) ->{9, 10};

get_xilian_attr_range(6, 10, 8) ->{11, 12};

get_xilian_attr_range(7, 10, 8) ->{13, 14};

get_xilian_attr_range(8, 10, 8) ->{15, 17};

get_xilian_attr_range(9, 10, 8) ->{18, 20};

get_xilian_attr_range(10, 10, 8) ->{21, 22};

get_xilian_attr_range(1, 20, 8) ->{4, 4};

get_xilian_attr_range(2, 20, 8) ->{5, 6};

get_xilian_attr_range(3, 20, 8) ->{7, 8};

get_xilian_attr_range(4, 20, 8) ->{9, 10};

get_xilian_attr_range(5, 20, 8) ->{11, 12};

get_xilian_attr_range(6, 20, 8) ->{13, 14};

get_xilian_attr_range(7, 20, 8) ->{15, 17};

get_xilian_attr_range(8, 20, 8) ->{18, 20};

get_xilian_attr_range(9, 20, 8) ->{21, 22};

get_xilian_attr_range(10, 20, 8) ->{23, 25};

get_xilian_attr_range(1, 30, 8) ->{6, 6};

get_xilian_attr_range(2, 30, 8) ->{7, 8};

get_xilian_attr_range(3, 30, 8) ->{9, 10};

get_xilian_attr_range(4, 30, 8) ->{11, 12};

get_xilian_attr_range(5, 30, 8) ->{13, 14};

get_xilian_attr_range(6, 30, 8) ->{15, 17};

get_xilian_attr_range(7, 30, 8) ->{18, 20};

get_xilian_attr_range(8, 30, 8) ->{21, 22};

get_xilian_attr_range(9, 30, 8) ->{23, 25};

get_xilian_attr_range(10, 30, 8) ->{26, 28};

get_xilian_attr_range(1, 40, 8) ->{8, 8};

get_xilian_attr_range(2, 40, 8) ->{9, 10};

get_xilian_attr_range(3, 40, 8) ->{11, 12};

get_xilian_attr_range(4, 40, 8) ->{13, 14};

get_xilian_attr_range(5, 40, 8) ->{15, 17};

get_xilian_attr_range(6, 40, 8) ->{18, 20};

get_xilian_attr_range(7, 40, 8) ->{21, 22};

get_xilian_attr_range(8, 40, 8) ->{23, 25};

get_xilian_attr_range(9, 40, 8) ->{26, 28};

get_xilian_attr_range(10, 40, 8) ->{29, 31};

get_xilian_attr_range(1, 50, 8) ->{10, 10};

get_xilian_attr_range(2, 50, 8) ->{11, 12};

get_xilian_attr_range(3, 50, 8) ->{13, 14};

get_xilian_attr_range(4, 50, 8) ->{15, 17};

get_xilian_attr_range(5, 50, 8) ->{18, 20};

get_xilian_attr_range(6, 50, 8) ->{21, 22};

get_xilian_attr_range(7, 50, 8) ->{23, 25};

get_xilian_attr_range(8, 50, 8) ->{26, 28};

get_xilian_attr_range(9, 50, 8) ->{29, 31};

get_xilian_attr_range(10, 50, 8) ->{32, 34};

get_xilian_attr_range(1, 60, 8) ->{12, 12};

get_xilian_attr_range(2, 60, 8) ->{13, 14};

get_xilian_attr_range(3, 60, 8) ->{15, 17};

get_xilian_attr_range(4, 60, 8) ->{18, 20};

get_xilian_attr_range(5, 60, 8) ->{21, 22};

get_xilian_attr_range(6, 60, 8) ->{23, 25};

get_xilian_attr_range(7, 60, 8) ->{26, 28};

get_xilian_attr_range(8, 60, 8) ->{29, 31};

get_xilian_attr_range(9, 60, 8) ->{32, 34};

get_xilian_attr_range(10, 60, 8) ->{35, 37};

get_xilian_attr_range(1, 70, 8) ->{14, 14};

get_xilian_attr_range(2, 70, 8) ->{15, 17};

get_xilian_attr_range(3, 70, 8) ->{18, 20};

get_xilian_attr_range(4, 70, 8) ->{21, 22};

get_xilian_attr_range(5, 70, 8) ->{23, 25};

get_xilian_attr_range(6, 70, 8) ->{26, 28};

get_xilian_attr_range(7, 70, 8) ->{29, 31};

get_xilian_attr_range(8, 70, 8) ->{32, 34};

get_xilian_attr_range(9, 70, 8) ->{35, 37};

get_xilian_attr_range(10, 70, 8) ->{38, 39};

get_xilian_attr_range(1, 80, 8) ->{17, 17};

get_xilian_attr_range(2, 80, 8) ->{18, 20};

get_xilian_attr_range(3, 80, 8) ->{21, 22};

get_xilian_attr_range(4, 80, 8) ->{23, 25};

get_xilian_attr_range(5, 80, 8) ->{26, 28};

get_xilian_attr_range(6, 80, 8) ->{29, 31};

get_xilian_attr_range(7, 80, 8) ->{32, 34};

get_xilian_attr_range(8, 80, 8) ->{35, 37};

get_xilian_attr_range(9, 80, 8) ->{38, 39};

get_xilian_attr_range(10, 80, 8) ->{40, 42};

get_xilian_attr_range(1, 90, 8) ->{20, 20};

get_xilian_attr_range(2, 90, 8) ->{21, 22};

get_xilian_attr_range(3, 90, 8) ->{23, 25};

get_xilian_attr_range(4, 90, 8) ->{26, 28};

get_xilian_attr_range(5, 90, 8) ->{29, 31};

get_xilian_attr_range(6, 90, 8) ->{32, 34};

get_xilian_attr_range(7, 90, 8) ->{35, 37};

get_xilian_attr_range(8, 90, 8) ->{38, 39};

get_xilian_attr_range(9, 90, 8) ->{40, 42};

get_xilian_attr_range(10, 90, 8) ->{43, 45};

get_xilian_attr_range(1, 100, 8) ->{22, 22};

get_xilian_attr_range(2, 100, 8) ->{23, 25};

get_xilian_attr_range(3, 100, 8) ->{26, 28};

get_xilian_attr_range(4, 100, 8) ->{29, 31};

get_xilian_attr_range(5, 100, 8) ->{32, 34};

get_xilian_attr_range(6, 100, 8) ->{35, 37};

get_xilian_attr_range(7, 100, 8) ->{38, 39};

get_xilian_attr_range(8, 100, 8) ->{40, 42};

get_xilian_attr_range(9, 100, 8) ->{43, 45};

get_xilian_attr_range(10, 100, 8) ->{46, 48};

get_xilian_attr_range(1, 1, 9) ->{2, 2};

get_xilian_attr_range(2, 1, 9) ->{3, 5};

get_xilian_attr_range(3, 1, 9) ->{6, 7};

get_xilian_attr_range(4, 1, 9) ->{8, 10};

get_xilian_attr_range(5, 1, 9) ->{11, 13};

get_xilian_attr_range(6, 1, 9) ->{14, 16};

get_xilian_attr_range(7, 1, 9) ->{17, 20};

get_xilian_attr_range(8, 1, 9) ->{21, 24};

get_xilian_attr_range(9, 1, 9) ->{25, 28};

get_xilian_attr_range(10, 1, 9) ->{29, 33};

get_xilian_attr_range(1, 10, 9) ->{5, 5};

get_xilian_attr_range(2, 10, 9) ->{6, 7};

get_xilian_attr_range(3, 10, 9) ->{8, 10};

get_xilian_attr_range(4, 10, 9) ->{11, 13};

get_xilian_attr_range(5, 10, 9) ->{14, 16};

get_xilian_attr_range(6, 10, 9) ->{17, 20};

get_xilian_attr_range(7, 10, 9) ->{21, 24};

get_xilian_attr_range(8, 10, 9) ->{25, 28};

get_xilian_attr_range(9, 10, 9) ->{29, 33};

get_xilian_attr_range(10, 10, 9) ->{34, 37};

get_xilian_attr_range(1, 20, 9) ->{7, 7};

get_xilian_attr_range(2, 20, 9) ->{8, 10};

get_xilian_attr_range(3, 20, 9) ->{11, 13};

get_xilian_attr_range(4, 20, 9) ->{14, 16};

get_xilian_attr_range(5, 20, 9) ->{17, 20};

get_xilian_attr_range(6, 20, 9) ->{21, 24};

get_xilian_attr_range(7, 20, 9) ->{25, 28};

get_xilian_attr_range(8, 20, 9) ->{29, 33};

get_xilian_attr_range(9, 20, 9) ->{34, 37};

get_xilian_attr_range(10, 20, 9) ->{38, 42};

get_xilian_attr_range(1, 30, 9) ->{10, 10};

get_xilian_attr_range(2, 30, 9) ->{11, 13};

get_xilian_attr_range(3, 30, 9) ->{14, 16};

get_xilian_attr_range(4, 30, 9) ->{17, 20};

get_xilian_attr_range(5, 30, 9) ->{21, 24};

get_xilian_attr_range(6, 30, 9) ->{25, 28};

get_xilian_attr_range(7, 30, 9) ->{29, 33};

get_xilian_attr_range(8, 30, 9) ->{34, 37};

get_xilian_attr_range(9, 30, 9) ->{38, 42};

get_xilian_attr_range(10, 30, 9) ->{43, 47};

get_xilian_attr_range(1, 40, 9) ->{13, 13};

get_xilian_attr_range(2, 40, 9) ->{14, 16};

get_xilian_attr_range(3, 40, 9) ->{17, 20};

get_xilian_attr_range(4, 40, 9) ->{21, 24};

get_xilian_attr_range(5, 40, 9) ->{25, 28};

get_xilian_attr_range(6, 40, 9) ->{29, 33};

get_xilian_attr_range(7, 40, 9) ->{34, 37};

get_xilian_attr_range(8, 40, 9) ->{38, 42};

get_xilian_attr_range(9, 40, 9) ->{43, 47};

get_xilian_attr_range(10, 40, 9) ->{48, 52};

get_xilian_attr_range(1, 50, 9) ->{16, 16};

get_xilian_attr_range(2, 50, 9) ->{17, 20};

get_xilian_attr_range(3, 50, 9) ->{21, 24};

get_xilian_attr_range(4, 50, 9) ->{25, 28};

get_xilian_attr_range(5, 50, 9) ->{29, 33};

get_xilian_attr_range(6, 50, 9) ->{34, 37};

get_xilian_attr_range(7, 50, 9) ->{38, 42};

get_xilian_attr_range(8, 50, 9) ->{43, 47};

get_xilian_attr_range(9, 50, 9) ->{48, 52};

get_xilian_attr_range(10, 50, 9) ->{53, 56};

get_xilian_attr_range(1, 60, 9) ->{20, 20};

get_xilian_attr_range(2, 60, 9) ->{21, 24};

get_xilian_attr_range(3, 60, 9) ->{25, 28};

get_xilian_attr_range(4, 60, 9) ->{29, 33};

get_xilian_attr_range(5, 60, 9) ->{34, 37};

get_xilian_attr_range(6, 60, 9) ->{38, 42};

get_xilian_attr_range(7, 60, 9) ->{43, 47};

get_xilian_attr_range(8, 60, 9) ->{48, 52};

get_xilian_attr_range(9, 60, 9) ->{53, 56};

get_xilian_attr_range(10, 60, 9) ->{57, 61};

get_xilian_attr_range(1, 70, 9) ->{24, 24};

get_xilian_attr_range(2, 70, 9) ->{25, 28};

get_xilian_attr_range(3, 70, 9) ->{29, 33};

get_xilian_attr_range(4, 70, 9) ->{34, 37};

get_xilian_attr_range(5, 70, 9) ->{38, 42};

get_xilian_attr_range(6, 70, 9) ->{43, 47};

get_xilian_attr_range(7, 70, 9) ->{48, 52};

get_xilian_attr_range(8, 70, 9) ->{53, 56};

get_xilian_attr_range(9, 70, 9) ->{57, 61};

get_xilian_attr_range(10, 70, 9) ->{62, 66};

get_xilian_attr_range(1, 80, 9) ->{28, 28};

get_xilian_attr_range(2, 80, 9) ->{29, 33};

get_xilian_attr_range(3, 80, 9) ->{34, 37};

get_xilian_attr_range(4, 80, 9) ->{38, 42};

get_xilian_attr_range(5, 80, 9) ->{43, 47};

get_xilian_attr_range(6, 80, 9) ->{48, 52};

get_xilian_attr_range(7, 80, 9) ->{53, 56};

get_xilian_attr_range(8, 80, 9) ->{57, 61};

get_xilian_attr_range(9, 80, 9) ->{62, 66};

get_xilian_attr_range(10, 80, 9) ->{67, 70};

get_xilian_attr_range(1, 90, 9) ->{33, 33};

get_xilian_attr_range(2, 90, 9) ->{34, 37};

get_xilian_attr_range(3, 90, 9) ->{38, 42};

get_xilian_attr_range(4, 90, 9) ->{43, 47};

get_xilian_attr_range(5, 90, 9) ->{48, 52};

get_xilian_attr_range(6, 90, 9) ->{53, 56};

get_xilian_attr_range(7, 90, 9) ->{57, 61};

get_xilian_attr_range(8, 90, 9) ->{62, 66};

get_xilian_attr_range(9, 90, 9) ->{67, 70};

get_xilian_attr_range(10, 90, 9) ->{71, 75};

get_xilian_attr_range(1, 100, 9) ->{37, 37};

get_xilian_attr_range(2, 100, 9) ->{38, 42};

get_xilian_attr_range(3, 100, 9) ->{43, 47};

get_xilian_attr_range(4, 100, 9) ->{48, 52};

get_xilian_attr_range(5, 100, 9) ->{53, 56};

get_xilian_attr_range(6, 100, 9) ->{57, 61};

get_xilian_attr_range(7, 100, 9) ->{62, 66};

get_xilian_attr_range(8, 100, 9) ->{67, 70};

get_xilian_attr_range(9, 100, 9) ->{71, 75};

get_xilian_attr_range(10, 100, 9) ->{76, 80};

get_xilian_attr_range(1, 1, 10) ->{1, 1};

get_xilian_attr_range(2, 1, 10) ->{2, 2};

get_xilian_attr_range(3, 1, 10) ->{3, 5};

get_xilian_attr_range(4, 1, 10) ->{6, 7};

get_xilian_attr_range(5, 1, 10) ->{8, 10};

get_xilian_attr_range(6, 1, 10) ->{11, 12};

get_xilian_attr_range(7, 1, 10) ->{13, 15};

get_xilian_attr_range(8, 1, 10) ->{16, 18};

get_xilian_attr_range(9, 1, 10) ->{19, 21};

get_xilian_attr_range(10, 1, 10) ->{22, 25};

get_xilian_attr_range(1, 10, 10) ->{4, 4};

get_xilian_attr_range(2, 10, 10) ->{5, 5};

get_xilian_attr_range(3, 10, 10) ->{6, 7};

get_xilian_attr_range(4, 10, 10) ->{8, 10};

get_xilian_attr_range(5, 10, 10) ->{11, 12};

get_xilian_attr_range(6, 10, 10) ->{13, 15};

get_xilian_attr_range(7, 10, 10) ->{16, 18};

get_xilian_attr_range(8, 10, 10) ->{19, 21};

get_xilian_attr_range(9, 10, 10) ->{22, 25};

get_xilian_attr_range(10, 10, 10) ->{26, 28};

get_xilian_attr_range(1, 20, 10) ->{5, 5};

get_xilian_attr_range(2, 20, 10) ->{6, 7};

get_xilian_attr_range(3, 20, 10) ->{8, 10};

get_xilian_attr_range(4, 20, 10) ->{11, 12};

get_xilian_attr_range(5, 20, 10) ->{13, 15};

get_xilian_attr_range(6, 20, 10) ->{16, 18};

get_xilian_attr_range(7, 20, 10) ->{19, 21};

get_xilian_attr_range(8, 20, 10) ->{22, 25};

get_xilian_attr_range(9, 20, 10) ->{26, 28};

get_xilian_attr_range(10, 20, 10) ->{29, 32};

get_xilian_attr_range(1, 30, 10) ->{7, 7};

get_xilian_attr_range(2, 30, 10) ->{8, 10};

get_xilian_attr_range(3, 30, 10) ->{11, 12};

get_xilian_attr_range(4, 30, 10) ->{13, 15};

get_xilian_attr_range(5, 30, 10) ->{16, 18};

get_xilian_attr_range(6, 30, 10) ->{19, 21};

get_xilian_attr_range(7, 30, 10) ->{22, 25};

get_xilian_attr_range(8, 30, 10) ->{26, 28};

get_xilian_attr_range(9, 30, 10) ->{29, 32};

get_xilian_attr_range(10, 30, 10) ->{33, 35};

get_xilian_attr_range(1, 40, 10) ->{10, 10};

get_xilian_attr_range(2, 40, 10) ->{11, 12};

get_xilian_attr_range(3, 40, 10) ->{13, 15};

get_xilian_attr_range(4, 40, 10) ->{16, 18};

get_xilian_attr_range(5, 40, 10) ->{19, 21};

get_xilian_attr_range(6, 40, 10) ->{22, 25};

get_xilian_attr_range(7, 40, 10) ->{26, 28};

get_xilian_attr_range(8, 40, 10) ->{29, 32};

get_xilian_attr_range(9, 40, 10) ->{33, 35};

get_xilian_attr_range(10, 40, 10) ->{36, 39};

get_xilian_attr_range(1, 50, 10) ->{12, 12};

get_xilian_attr_range(2, 50, 10) ->{13, 15};

get_xilian_attr_range(3, 50, 10) ->{16, 18};

get_xilian_attr_range(4, 50, 10) ->{19, 21};

get_xilian_attr_range(5, 50, 10) ->{22, 25};

get_xilian_attr_range(6, 50, 10) ->{26, 28};

get_xilian_attr_range(7, 50, 10) ->{29, 32};

get_xilian_attr_range(8, 50, 10) ->{33, 35};

get_xilian_attr_range(9, 50, 10) ->{36, 39};

get_xilian_attr_range(10, 50, 10) ->{40, 42};

get_xilian_attr_range(1, 60, 10) ->{15, 15};

get_xilian_attr_range(2, 60, 10) ->{16, 18};

get_xilian_attr_range(3, 60, 10) ->{19, 21};

get_xilian_attr_range(4, 60, 10) ->{22, 25};

get_xilian_attr_range(5, 60, 10) ->{26, 28};

get_xilian_attr_range(6, 60, 10) ->{29, 32};

get_xilian_attr_range(7, 60, 10) ->{33, 35};

get_xilian_attr_range(8, 60, 10) ->{36, 39};

get_xilian_attr_range(9, 60, 10) ->{40, 42};

get_xilian_attr_range(10, 60, 10) ->{43, 46};

get_xilian_attr_range(1, 70, 10) ->{18, 18};

get_xilian_attr_range(2, 70, 10) ->{19, 21};

get_xilian_attr_range(3, 70, 10) ->{22, 25};

get_xilian_attr_range(4, 70, 10) ->{26, 28};

get_xilian_attr_range(5, 70, 10) ->{29, 32};

get_xilian_attr_range(6, 70, 10) ->{33, 35};

get_xilian_attr_range(7, 70, 10) ->{36, 39};

get_xilian_attr_range(8, 70, 10) ->{40, 42};

get_xilian_attr_range(9, 70, 10) ->{43, 46};

get_xilian_attr_range(10, 70, 10) ->{47, 49};

get_xilian_attr_range(1, 80, 10) ->{21, 21};

get_xilian_attr_range(2, 80, 10) ->{22, 25};

get_xilian_attr_range(3, 80, 10) ->{26, 28};

get_xilian_attr_range(4, 80, 10) ->{29, 32};

get_xilian_attr_range(5, 80, 10) ->{33, 35};

get_xilian_attr_range(6, 80, 10) ->{36, 39};

get_xilian_attr_range(7, 80, 10) ->{40, 42};

get_xilian_attr_range(8, 80, 10) ->{43, 46};

get_xilian_attr_range(9, 80, 10) ->{47, 49};

get_xilian_attr_range(10, 80, 10) ->{50, 53};

get_xilian_attr_range(1, 90, 10) ->{25, 25};

get_xilian_attr_range(2, 90, 10) ->{26, 28};

get_xilian_attr_range(3, 90, 10) ->{29, 32};

get_xilian_attr_range(4, 90, 10) ->{33, 35};

get_xilian_attr_range(5, 90, 10) ->{36, 39};

get_xilian_attr_range(6, 90, 10) ->{40, 42};

get_xilian_attr_range(7, 90, 10) ->{43, 46};

get_xilian_attr_range(8, 90, 10) ->{47, 49};

get_xilian_attr_range(9, 90, 10) ->{50, 53};

get_xilian_attr_range(10, 90, 10) ->{54, 56};

get_xilian_attr_range(1, 100, 10) ->{28, 28};

get_xilian_attr_range(2, 100, 10) ->{29, 32};

get_xilian_attr_range(3, 100, 10) ->{33, 35};

get_xilian_attr_range(4, 100, 10) ->{36, 39};

get_xilian_attr_range(5, 100, 10) ->{40, 42};

get_xilian_attr_range(6, 100, 10) ->{43, 46};

get_xilian_attr_range(7, 100, 10) ->{47, 49};

get_xilian_attr_range(8, 100, 10) ->{50, 53};

get_xilian_attr_range(9, 100, 10) ->{54, 56};

get_xilian_attr_range(10, 100, 10) ->{57, 60};

get_xilian_attr_range(1, 1, 11) ->{2, 2};

get_xilian_attr_range(2, 1, 11) ->{3, 5};

get_xilian_attr_range(3, 1, 11) ->{6, 7};

get_xilian_attr_range(4, 1, 11) ->{8, 10};

get_xilian_attr_range(5, 1, 11) ->{11, 13};

get_xilian_attr_range(6, 1, 11) ->{14, 16};

get_xilian_attr_range(7, 1, 11) ->{17, 20};

get_xilian_attr_range(8, 1, 11) ->{21, 24};

get_xilian_attr_range(9, 1, 11) ->{25, 28};

get_xilian_attr_range(10, 1, 11) ->{29, 33};

get_xilian_attr_range(1, 10, 11) ->{5, 5};

get_xilian_attr_range(2, 10, 11) ->{6, 7};

get_xilian_attr_range(3, 10, 11) ->{8, 10};

get_xilian_attr_range(4, 10, 11) ->{11, 13};

get_xilian_attr_range(5, 10, 11) ->{14, 16};

get_xilian_attr_range(6, 10, 11) ->{17, 20};

get_xilian_attr_range(7, 10, 11) ->{21, 24};

get_xilian_attr_range(8, 10, 11) ->{25, 28};

get_xilian_attr_range(9, 10, 11) ->{29, 33};

get_xilian_attr_range(10, 10, 11) ->{34, 37};

get_xilian_attr_range(1, 20, 11) ->{7, 7};

get_xilian_attr_range(2, 20, 11) ->{8, 10};

get_xilian_attr_range(3, 20, 11) ->{11, 13};

get_xilian_attr_range(4, 20, 11) ->{14, 16};

get_xilian_attr_range(5, 20, 11) ->{17, 20};

get_xilian_attr_range(6, 20, 11) ->{21, 24};

get_xilian_attr_range(7, 20, 11) ->{25, 28};

get_xilian_attr_range(8, 20, 11) ->{29, 33};

get_xilian_attr_range(9, 20, 11) ->{34, 37};

get_xilian_attr_range(10, 20, 11) ->{38, 42};

get_xilian_attr_range(1, 30, 11) ->{10, 10};

get_xilian_attr_range(2, 30, 11) ->{11, 13};

get_xilian_attr_range(3, 30, 11) ->{14, 16};

get_xilian_attr_range(4, 30, 11) ->{17, 20};

get_xilian_attr_range(5, 30, 11) ->{21, 24};

get_xilian_attr_range(6, 30, 11) ->{25, 28};

get_xilian_attr_range(7, 30, 11) ->{29, 33};

get_xilian_attr_range(8, 30, 11) ->{34, 37};

get_xilian_attr_range(9, 30, 11) ->{38, 42};

get_xilian_attr_range(10, 30, 11) ->{43, 47};

get_xilian_attr_range(1, 40, 11) ->{13, 13};

get_xilian_attr_range(2, 40, 11) ->{14, 16};

get_xilian_attr_range(3, 40, 11) ->{17, 20};

get_xilian_attr_range(4, 40, 11) ->{21, 24};

get_xilian_attr_range(5, 40, 11) ->{25, 28};

get_xilian_attr_range(6, 40, 11) ->{29, 33};

get_xilian_attr_range(7, 40, 11) ->{34, 37};

get_xilian_attr_range(8, 40, 11) ->{38, 42};

get_xilian_attr_range(9, 40, 11) ->{43, 47};

get_xilian_attr_range(10, 40, 11) ->{48, 52};

get_xilian_attr_range(1, 50, 11) ->{16, 16};

get_xilian_attr_range(2, 50, 11) ->{17, 20};

get_xilian_attr_range(3, 50, 11) ->{21, 24};

get_xilian_attr_range(4, 50, 11) ->{25, 28};

get_xilian_attr_range(5, 50, 11) ->{29, 33};

get_xilian_attr_range(6, 50, 11) ->{34, 37};

get_xilian_attr_range(7, 50, 11) ->{38, 42};

get_xilian_attr_range(8, 50, 11) ->{43, 47};

get_xilian_attr_range(9, 50, 11) ->{48, 52};

get_xilian_attr_range(10, 50, 11) ->{53, 56};

get_xilian_attr_range(1, 60, 11) ->{20, 20};

get_xilian_attr_range(2, 60, 11) ->{21, 24};

get_xilian_attr_range(3, 60, 11) ->{25, 28};

get_xilian_attr_range(4, 60, 11) ->{29, 33};

get_xilian_attr_range(5, 60, 11) ->{34, 37};

get_xilian_attr_range(6, 60, 11) ->{38, 42};

get_xilian_attr_range(7, 60, 11) ->{43, 47};

get_xilian_attr_range(8, 60, 11) ->{48, 52};

get_xilian_attr_range(9, 60, 11) ->{53, 56};

get_xilian_attr_range(10, 60, 11) ->{57, 61};

get_xilian_attr_range(1, 70, 11) ->{24, 24};

get_xilian_attr_range(2, 70, 11) ->{25, 28};

get_xilian_attr_range(3, 70, 11) ->{29, 33};

get_xilian_attr_range(4, 70, 11) ->{34, 37};

get_xilian_attr_range(5, 70, 11) ->{38, 42};

get_xilian_attr_range(6, 70, 11) ->{43, 47};

get_xilian_attr_range(7, 70, 11) ->{48, 52};

get_xilian_attr_range(8, 70, 11) ->{53, 56};

get_xilian_attr_range(9, 70, 11) ->{57, 61};

get_xilian_attr_range(10, 70, 11) ->{62, 66};

get_xilian_attr_range(1, 80, 11) ->{28, 28};

get_xilian_attr_range(2, 80, 11) ->{29, 33};

get_xilian_attr_range(3, 80, 11) ->{34, 37};

get_xilian_attr_range(4, 80, 11) ->{38, 42};

get_xilian_attr_range(5, 80, 11) ->{43, 47};

get_xilian_attr_range(6, 80, 11) ->{48, 52};

get_xilian_attr_range(7, 80, 11) ->{53, 56};

get_xilian_attr_range(8, 80, 11) ->{57, 61};

get_xilian_attr_range(9, 80, 11) ->{62, 66};

get_xilian_attr_range(10, 80, 11) ->{67, 70};

get_xilian_attr_range(1, 90, 11) ->{33, 33};

get_xilian_attr_range(2, 90, 11) ->{34, 37};

get_xilian_attr_range(3, 90, 11) ->{38, 42};

get_xilian_attr_range(4, 90, 11) ->{43, 47};

get_xilian_attr_range(5, 90, 11) ->{48, 52};

get_xilian_attr_range(6, 90, 11) ->{53, 56};

get_xilian_attr_range(7, 90, 11) ->{57, 61};

get_xilian_attr_range(8, 90, 11) ->{62, 66};

get_xilian_attr_range(9, 90, 11) ->{67, 70};

get_xilian_attr_range(10, 90, 11) ->{71, 75};

get_xilian_attr_range(1, 100, 11) ->{37, 37};

get_xilian_attr_range(2, 100, 11) ->{38, 42};

get_xilian_attr_range(3, 100, 11) ->{43, 47};

get_xilian_attr_range(4, 100, 11) ->{48, 52};

get_xilian_attr_range(5, 100, 11) ->{53, 56};

get_xilian_attr_range(6, 100, 11) ->{57, 61};

get_xilian_attr_range(7, 100, 11) ->{62, 66};

get_xilian_attr_range(8, 100, 11) ->{67, 70};

get_xilian_attr_range(9, 100, 11) ->{71, 75};

get_xilian_attr_range(10, 100, 11) ->{76, 80};

get_xilian_attr_range(1, 1, 12) ->{2, 2};

get_xilian_attr_range(2, 1, 12) ->{3, 5};

get_xilian_attr_range(3, 1, 12) ->{6, 7};

get_xilian_attr_range(4, 1, 12) ->{8, 9};

get_xilian_attr_range(5, 1, 12) ->{10, 12};

get_xilian_attr_range(6, 1, 12) ->{13, 15};

get_xilian_attr_range(7, 1, 12) ->{16, 19};

get_xilian_attr_range(8, 1, 12) ->{20, 23};

get_xilian_attr_range(9, 1, 12) ->{24, 26};

get_xilian_attr_range(10, 1, 12) ->{27, 31};

get_xilian_attr_range(1, 10, 12) ->{5, 5};

get_xilian_attr_range(2, 10, 12) ->{6, 7};

get_xilian_attr_range(3, 10, 12) ->{8, 9};

get_xilian_attr_range(4, 10, 12) ->{10, 12};

get_xilian_attr_range(5, 10, 12) ->{13, 15};

get_xilian_attr_range(6, 10, 12) ->{16, 19};

get_xilian_attr_range(7, 10, 12) ->{20, 23};

get_xilian_attr_range(8, 10, 12) ->{24, 26};

get_xilian_attr_range(9, 10, 12) ->{27, 31};

get_xilian_attr_range(10, 10, 12) ->{32, 35};

get_xilian_attr_range(1, 20, 12) ->{7, 7};

get_xilian_attr_range(2, 20, 12) ->{8, 9};

get_xilian_attr_range(3, 20, 12) ->{10, 12};

get_xilian_attr_range(4, 20, 12) ->{13, 15};

get_xilian_attr_range(5, 20, 12) ->{16, 19};

get_xilian_attr_range(6, 20, 12) ->{20, 23};

get_xilian_attr_range(7, 20, 12) ->{24, 26};

get_xilian_attr_range(8, 20, 12) ->{27, 31};

get_xilian_attr_range(9, 20, 12) ->{32, 35};

get_xilian_attr_range(10, 20, 12) ->{36, 40};

get_xilian_attr_range(1, 30, 12) ->{9, 9};

get_xilian_attr_range(2, 30, 12) ->{10, 12};

get_xilian_attr_range(3, 30, 12) ->{13, 15};

get_xilian_attr_range(4, 30, 12) ->{16, 19};

get_xilian_attr_range(5, 30, 12) ->{20, 23};

get_xilian_attr_range(6, 30, 12) ->{24, 26};

get_xilian_attr_range(7, 30, 12) ->{27, 31};

get_xilian_attr_range(8, 30, 12) ->{32, 35};

get_xilian_attr_range(9, 30, 12) ->{36, 40};

get_xilian_attr_range(10, 30, 12) ->{41, 44};

get_xilian_attr_range(1, 40, 12) ->{12, 12};

get_xilian_attr_range(2, 40, 12) ->{13, 15};

get_xilian_attr_range(3, 40, 12) ->{16, 19};

get_xilian_attr_range(4, 40, 12) ->{20, 23};

get_xilian_attr_range(5, 40, 12) ->{24, 26};

get_xilian_attr_range(6, 40, 12) ->{27, 31};

get_xilian_attr_range(7, 40, 12) ->{32, 35};

get_xilian_attr_range(8, 40, 12) ->{36, 40};

get_xilian_attr_range(9, 40, 12) ->{41, 44};

get_xilian_attr_range(10, 40, 12) ->{45, 48};

get_xilian_attr_range(1, 50, 12) ->{15, 15};

get_xilian_attr_range(2, 50, 12) ->{16, 19};

get_xilian_attr_range(3, 50, 12) ->{20, 23};

get_xilian_attr_range(4, 50, 12) ->{24, 26};

get_xilian_attr_range(5, 50, 12) ->{27, 31};

get_xilian_attr_range(6, 50, 12) ->{32, 35};

get_xilian_attr_range(7, 50, 12) ->{36, 40};

get_xilian_attr_range(8, 50, 12) ->{41, 44};

get_xilian_attr_range(9, 50, 12) ->{45, 48};

get_xilian_attr_range(10, 50, 12) ->{49, 53};

get_xilian_attr_range(1, 60, 12) ->{19, 19};

get_xilian_attr_range(2, 60, 12) ->{20, 23};

get_xilian_attr_range(3, 60, 12) ->{24, 26};

get_xilian_attr_range(4, 60, 12) ->{27, 31};

get_xilian_attr_range(5, 60, 12) ->{32, 35};

get_xilian_attr_range(6, 60, 12) ->{36, 40};

get_xilian_attr_range(7, 60, 12) ->{41, 44};

get_xilian_attr_range(8, 60, 12) ->{45, 48};

get_xilian_attr_range(9, 60, 12) ->{49, 53};

get_xilian_attr_range(10, 60, 12) ->{54, 57};

get_xilian_attr_range(1, 70, 12) ->{23, 23};

get_xilian_attr_range(2, 70, 12) ->{24, 26};

get_xilian_attr_range(3, 70, 12) ->{27, 31};

get_xilian_attr_range(4, 70, 12) ->{32, 35};

get_xilian_attr_range(5, 70, 12) ->{36, 40};

get_xilian_attr_range(6, 70, 12) ->{41, 44};

get_xilian_attr_range(7, 70, 12) ->{45, 48};

get_xilian_attr_range(8, 70, 12) ->{49, 53};

get_xilian_attr_range(9, 70, 12) ->{54, 57};

get_xilian_attr_range(10, 70, 12) ->{58, 62};

get_xilian_attr_range(1, 80, 12) ->{26, 26};

get_xilian_attr_range(2, 80, 12) ->{27, 31};

get_xilian_attr_range(3, 80, 12) ->{32, 35};

get_xilian_attr_range(4, 80, 12) ->{36, 40};

get_xilian_attr_range(5, 80, 12) ->{41, 44};

get_xilian_attr_range(6, 80, 12) ->{45, 48};

get_xilian_attr_range(7, 80, 12) ->{49, 53};

get_xilian_attr_range(8, 80, 12) ->{54, 57};

get_xilian_attr_range(9, 80, 12) ->{58, 62};

get_xilian_attr_range(10, 80, 12) ->{63, 66};

get_xilian_attr_range(1, 90, 12) ->{31, 31};

get_xilian_attr_range(2, 90, 12) ->{32, 35};

get_xilian_attr_range(3, 90, 12) ->{36, 40};

get_xilian_attr_range(4, 90, 12) ->{41, 44};

get_xilian_attr_range(5, 90, 12) ->{45, 48};

get_xilian_attr_range(6, 90, 12) ->{49, 53};

get_xilian_attr_range(7, 90, 12) ->{54, 57};

get_xilian_attr_range(8, 90, 12) ->{58, 62};

get_xilian_attr_range(9, 90, 12) ->{63, 66};

get_xilian_attr_range(10, 90, 12) ->{67, 71};

get_xilian_attr_range(1, 100, 12) ->{35, 35};

get_xilian_attr_range(2, 100, 12) ->{36, 40};

get_xilian_attr_range(3, 100, 12) ->{41, 44};

get_xilian_attr_range(4, 100, 12) ->{45, 48};

get_xilian_attr_range(5, 100, 12) ->{49, 53};

get_xilian_attr_range(6, 100, 12) ->{54, 57};

get_xilian_attr_range(7, 100, 12) ->{58, 62};

get_xilian_attr_range(8, 100, 12) ->{63, 66};

get_xilian_attr_range(9, 100, 12) ->{67, 71};

get_xilian_attr_range(10, 100, 12) ->{72, 75};

get_xilian_attr_range(1, 1, 13) ->{2, 2};

get_xilian_attr_range(2, 1, 13) ->{3, 3};

get_xilian_attr_range(3, 1, 13) ->{4, 5};

get_xilian_attr_range(4, 1, 13) ->{6, 6};

get_xilian_attr_range(5, 1, 13) ->{7, 8};

get_xilian_attr_range(6, 1, 13) ->{9, 10};

get_xilian_attr_range(7, 1, 13) ->{11, 13};

get_xilian_attr_range(8, 1, 13) ->{14, 15};

get_xilian_attr_range(9, 1, 13) ->{16, 18};

get_xilian_attr_range(10, 1, 13) ->{19, 20};

get_xilian_attr_range(1, 10, 13) ->{3, 3};

get_xilian_attr_range(2, 10, 13) ->{4, 5};

get_xilian_attr_range(3, 10, 13) ->{6, 6};

get_xilian_attr_range(4, 10, 13) ->{7, 8};

get_xilian_attr_range(5, 10, 13) ->{9, 10};

get_xilian_attr_range(6, 10, 13) ->{11, 13};

get_xilian_attr_range(7, 10, 13) ->{14, 15};

get_xilian_attr_range(8, 10, 13) ->{16, 18};

get_xilian_attr_range(9, 10, 13) ->{19, 20};

get_xilian_attr_range(10, 10, 13) ->{21, 23};

get_xilian_attr_range(1, 20, 13) ->{5, 5};

get_xilian_attr_range(2, 20, 13) ->{6, 6};

get_xilian_attr_range(3, 20, 13) ->{7, 8};

get_xilian_attr_range(4, 20, 13) ->{9, 10};

get_xilian_attr_range(5, 20, 13) ->{11, 13};

get_xilian_attr_range(6, 20, 13) ->{14, 15};

get_xilian_attr_range(7, 20, 13) ->{16, 18};

get_xilian_attr_range(8, 20, 13) ->{19, 20};

get_xilian_attr_range(9, 20, 13) ->{21, 23};

get_xilian_attr_range(10, 20, 13) ->{24, 26};

get_xilian_attr_range(1, 30, 13) ->{6, 6};

get_xilian_attr_range(2, 30, 13) ->{7, 8};

get_xilian_attr_range(3, 30, 13) ->{9, 10};

get_xilian_attr_range(4, 30, 13) ->{11, 13};

get_xilian_attr_range(5, 30, 13) ->{14, 15};

get_xilian_attr_range(6, 30, 13) ->{16, 18};

get_xilian_attr_range(7, 30, 13) ->{19, 20};

get_xilian_attr_range(8, 30, 13) ->{21, 23};

get_xilian_attr_range(9, 30, 13) ->{24, 26};

get_xilian_attr_range(10, 30, 13) ->{27, 29};

get_xilian_attr_range(1, 40, 13) ->{8, 8};

get_xilian_attr_range(2, 40, 13) ->{9, 10};

get_xilian_attr_range(3, 40, 13) ->{11, 13};

get_xilian_attr_range(4, 40, 13) ->{14, 15};

get_xilian_attr_range(5, 40, 13) ->{16, 18};

get_xilian_attr_range(6, 40, 13) ->{19, 20};

get_xilian_attr_range(7, 40, 13) ->{21, 23};

get_xilian_attr_range(8, 40, 13) ->{24, 26};

get_xilian_attr_range(9, 40, 13) ->{27, 29};

get_xilian_attr_range(10, 40, 13) ->{30, 32};

get_xilian_attr_range(1, 50, 13) ->{10, 10};

get_xilian_attr_range(2, 50, 13) ->{11, 13};

get_xilian_attr_range(3, 50, 13) ->{14, 15};

get_xilian_attr_range(4, 50, 13) ->{16, 18};

get_xilian_attr_range(5, 50, 13) ->{19, 20};

get_xilian_attr_range(6, 50, 13) ->{21, 23};

get_xilian_attr_range(7, 50, 13) ->{24, 26};

get_xilian_attr_range(8, 50, 13) ->{27, 29};

get_xilian_attr_range(9, 50, 13) ->{30, 32};

get_xilian_attr_range(10, 50, 13) ->{33, 35};

get_xilian_attr_range(1, 60, 13) ->{13, 13};

get_xilian_attr_range(2, 60, 13) ->{14, 15};

get_xilian_attr_range(3, 60, 13) ->{16, 18};

get_xilian_attr_range(4, 60, 13) ->{19, 20};

get_xilian_attr_range(5, 60, 13) ->{21, 23};

get_xilian_attr_range(6, 60, 13) ->{24, 26};

get_xilian_attr_range(7, 60, 13) ->{27, 29};

get_xilian_attr_range(8, 60, 13) ->{30, 32};

get_xilian_attr_range(9, 60, 13) ->{33, 35};

get_xilian_attr_range(10, 60, 13) ->{36, 38};

get_xilian_attr_range(1, 70, 13) ->{15, 15};

get_xilian_attr_range(2, 70, 13) ->{16, 18};

get_xilian_attr_range(3, 70, 13) ->{19, 20};

get_xilian_attr_range(4, 70, 13) ->{21, 23};

get_xilian_attr_range(5, 70, 13) ->{24, 26};

get_xilian_attr_range(6, 70, 13) ->{27, 29};

get_xilian_attr_range(7, 70, 13) ->{30, 32};

get_xilian_attr_range(8, 70, 13) ->{33, 35};

get_xilian_attr_range(9, 70, 13) ->{36, 38};

get_xilian_attr_range(10, 70, 13) ->{39, 41};

get_xilian_attr_range(1, 80, 13) ->{18, 18};

get_xilian_attr_range(2, 80, 13) ->{19, 20};

get_xilian_attr_range(3, 80, 13) ->{21, 23};

get_xilian_attr_range(4, 80, 13) ->{24, 26};

get_xilian_attr_range(5, 80, 13) ->{27, 29};

get_xilian_attr_range(6, 80, 13) ->{30, 32};

get_xilian_attr_range(7, 80, 13) ->{33, 35};

get_xilian_attr_range(8, 80, 13) ->{36, 38};

get_xilian_attr_range(9, 80, 13) ->{39, 41};

get_xilian_attr_range(10, 80, 13) ->{42, 44};

get_xilian_attr_range(1, 90, 13) ->{20, 20};

get_xilian_attr_range(2, 90, 13) ->{21, 23};

get_xilian_attr_range(3, 90, 13) ->{24, 26};

get_xilian_attr_range(4, 90, 13) ->{27, 29};

get_xilian_attr_range(5, 90, 13) ->{30, 32};

get_xilian_attr_range(6, 90, 13) ->{33, 35};

get_xilian_attr_range(7, 90, 13) ->{36, 38};

get_xilian_attr_range(8, 90, 13) ->{39, 41};

get_xilian_attr_range(9, 90, 13) ->{42, 44};

get_xilian_attr_range(10, 90, 13) ->{45, 47};

get_xilian_attr_range(1, 100, 13) ->{23, 23};

get_xilian_attr_range(2, 100, 13) ->{24, 26};

get_xilian_attr_range(3, 100, 13) ->{27, 29};

get_xilian_attr_range(4, 100, 13) ->{30, 32};

get_xilian_attr_range(5, 100, 13) ->{33, 35};

get_xilian_attr_range(6, 100, 13) ->{36, 38};

get_xilian_attr_range(7, 100, 13) ->{39, 41};

get_xilian_attr_range(8, 100, 13) ->{42, 44};

get_xilian_attr_range(9, 100, 13) ->{45, 47};

get_xilian_attr_range(10, 100, 13) ->{48, 50};

get_xilian_attr_range(1, 1, 14) ->{3, 3};

get_xilian_attr_range(2, 1, 14) ->{4, 5};

get_xilian_attr_range(3, 1, 14) ->{6, 8};

get_xilian_attr_range(4, 1, 14) ->{9, 10};

get_xilian_attr_range(5, 1, 14) ->{11, 13};

get_xilian_attr_range(6, 1, 14) ->{14, 17};

get_xilian_attr_range(7, 1, 14) ->{18, 21};

get_xilian_attr_range(8, 1, 14) ->{22, 25};

get_xilian_attr_range(9, 1, 14) ->{26, 29};

get_xilian_attr_range(10, 1, 14) ->{30, 34};

get_xilian_attr_range(1, 10, 14) ->{5, 5};

get_xilian_attr_range(2, 10, 14) ->{6, 8};

get_xilian_attr_range(3, 10, 14) ->{9, 10};

get_xilian_attr_range(4, 10, 14) ->{11, 13};

get_xilian_attr_range(5, 10, 14) ->{14, 17};

get_xilian_attr_range(6, 10, 14) ->{18, 21};

get_xilian_attr_range(7, 10, 14) ->{22, 25};

get_xilian_attr_range(8, 10, 14) ->{26, 29};

get_xilian_attr_range(9, 10, 14) ->{30, 34};

get_xilian_attr_range(10, 10, 14) ->{35, 39};

get_xilian_attr_range(1, 20, 14) ->{8, 8};

get_xilian_attr_range(2, 20, 14) ->{9, 10};

get_xilian_attr_range(3, 20, 14) ->{11, 13};

get_xilian_attr_range(4, 20, 14) ->{14, 17};

get_xilian_attr_range(5, 20, 14) ->{18, 21};

get_xilian_attr_range(6, 20, 14) ->{22, 25};

get_xilian_attr_range(7, 20, 14) ->{26, 29};

get_xilian_attr_range(8, 20, 14) ->{30, 34};

get_xilian_attr_range(9, 20, 14) ->{35, 39};

get_xilian_attr_range(10, 20, 14) ->{40, 44};

get_xilian_attr_range(1, 30, 14) ->{10, 10};

get_xilian_attr_range(2, 30, 14) ->{11, 13};

get_xilian_attr_range(3, 30, 14) ->{14, 17};

get_xilian_attr_range(4, 30, 14) ->{18, 21};

get_xilian_attr_range(5, 30, 14) ->{22, 25};

get_xilian_attr_range(6, 30, 14) ->{26, 29};

get_xilian_attr_range(7, 30, 14) ->{30, 34};

get_xilian_attr_range(8, 30, 14) ->{35, 39};

get_xilian_attr_range(9, 30, 14) ->{40, 44};

get_xilian_attr_range(10, 30, 14) ->{45, 49};

get_xilian_attr_range(1, 40, 14) ->{13, 13};

get_xilian_attr_range(2, 40, 14) ->{14, 17};

get_xilian_attr_range(3, 40, 14) ->{18, 21};

get_xilian_attr_range(4, 40, 14) ->{22, 25};

get_xilian_attr_range(5, 40, 14) ->{26, 29};

get_xilian_attr_range(6, 40, 14) ->{30, 34};

get_xilian_attr_range(7, 40, 14) ->{35, 39};

get_xilian_attr_range(8, 40, 14) ->{40, 44};

get_xilian_attr_range(9, 40, 14) ->{45, 49};

get_xilian_attr_range(10, 40, 14) ->{50, 54};

get_xilian_attr_range(1, 50, 14) ->{17, 17};

get_xilian_attr_range(2, 50, 14) ->{18, 21};

get_xilian_attr_range(3, 50, 14) ->{22, 25};

get_xilian_attr_range(4, 50, 14) ->{26, 29};

get_xilian_attr_range(5, 50, 14) ->{30, 34};

get_xilian_attr_range(6, 50, 14) ->{35, 39};

get_xilian_attr_range(7, 50, 14) ->{40, 44};

get_xilian_attr_range(8, 50, 14) ->{45, 49};

get_xilian_attr_range(9, 50, 14) ->{50, 54};

get_xilian_attr_range(10, 50, 14) ->{55, 59};

get_xilian_attr_range(1, 60, 14) ->{21, 21};

get_xilian_attr_range(2, 60, 14) ->{22, 25};

get_xilian_attr_range(3, 60, 14) ->{26, 29};

get_xilian_attr_range(4, 60, 14) ->{30, 34};

get_xilian_attr_range(5, 60, 14) ->{35, 39};

get_xilian_attr_range(6, 60, 14) ->{40, 44};

get_xilian_attr_range(7, 60, 14) ->{45, 49};

get_xilian_attr_range(8, 60, 14) ->{50, 54};

get_xilian_attr_range(9, 60, 14) ->{55, 59};

get_xilian_attr_range(10, 60, 14) ->{60, 64};

get_xilian_attr_range(1, 70, 14) ->{25, 25};

get_xilian_attr_range(2, 70, 14) ->{26, 29};

get_xilian_attr_range(3, 70, 14) ->{30, 34};

get_xilian_attr_range(4, 70, 14) ->{35, 39};

get_xilian_attr_range(5, 70, 14) ->{40, 44};

get_xilian_attr_range(6, 70, 14) ->{45, 49};

get_xilian_attr_range(7, 70, 14) ->{50, 54};

get_xilian_attr_range(8, 70, 14) ->{55, 59};

get_xilian_attr_range(9, 70, 14) ->{60, 64};

get_xilian_attr_range(10, 70, 14) ->{65, 69};

get_xilian_attr_range(1, 80, 14) ->{29, 29};

get_xilian_attr_range(2, 80, 14) ->{30, 34};

get_xilian_attr_range(3, 80, 14) ->{35, 39};

get_xilian_attr_range(4, 80, 14) ->{40, 44};

get_xilian_attr_range(5, 80, 14) ->{45, 49};

get_xilian_attr_range(6, 80, 14) ->{50, 54};

get_xilian_attr_range(7, 80, 14) ->{55, 59};

get_xilian_attr_range(8, 80, 14) ->{60, 64};

get_xilian_attr_range(9, 80, 14) ->{65, 69};

get_xilian_attr_range(10, 80, 14) ->{70, 74};

get_xilian_attr_range(1, 90, 14) ->{34, 34};

get_xilian_attr_range(2, 90, 14) ->{35, 39};

get_xilian_attr_range(3, 90, 14) ->{40, 44};

get_xilian_attr_range(4, 90, 14) ->{45, 49};

get_xilian_attr_range(5, 90, 14) ->{50, 54};

get_xilian_attr_range(6, 90, 14) ->{55, 59};

get_xilian_attr_range(7, 90, 14) ->{60, 64};

get_xilian_attr_range(8, 90, 14) ->{65, 69};

get_xilian_attr_range(9, 90, 14) ->{70, 74};

get_xilian_attr_range(10, 90, 14) ->{75, 79};

get_xilian_attr_range(1, 100, 14) ->{39, 39};

get_xilian_attr_range(2, 100, 14) ->{40, 44};

get_xilian_attr_range(3, 100, 14) ->{45, 49};

get_xilian_attr_range(4, 100, 14) ->{50, 54};

get_xilian_attr_range(5, 100, 14) ->{55, 59};

get_xilian_attr_range(6, 100, 14) ->{60, 64};

get_xilian_attr_range(7, 100, 14) ->{65, 69};

get_xilian_attr_range(8, 100, 14) ->{70, 74};

get_xilian_attr_range(9, 100, 14) ->{75, 79};

get_xilian_attr_range(10, 100, 14) ->{80, 84};

get_xilian_attr_range(1, 15, 1) ->{2, 11};

get_xilian_attr_range(2, 15, 1) ->{12, 23};

get_xilian_attr_range(3, 15, 1) ->{24, 35};

get_xilian_attr_range(4, 15, 1) ->{36, 47};

get_xilian_attr_range(5, 15, 1) ->{48, 63};

get_xilian_attr_range(6, 15, 1) ->{64, 79};

get_xilian_attr_range(7, 15, 1) ->{80, 95};

get_xilian_attr_range(8, 15, 1) ->{96, 111};

get_xilian_attr_range(9, 15, 1) ->{112, 127};

get_xilian_attr_range(10, 15, 1) ->{128, 143};

get_xilian_attr_range(1, 25, 1) ->{15, 35};

get_xilian_attr_range(2, 25, 1) ->{36, 47};

get_xilian_attr_range(3, 25, 1) ->{48, 63};

get_xilian_attr_range(4, 25, 1) ->{64, 79};

get_xilian_attr_range(5, 25, 1) ->{80, 95};

get_xilian_attr_range(6, 25, 1) ->{96, 111};

get_xilian_attr_range(7, 25, 1) ->{112, 127};

get_xilian_attr_range(8, 25, 1) ->{128, 143};

get_xilian_attr_range(9, 25, 1) ->{144, 159};

get_xilian_attr_range(10, 25, 1) ->{160, 175};

get_xilian_attr_range(1, 35, 1) ->{23, 63};

get_xilian_attr_range(2, 35, 1) ->{64, 79};

get_xilian_attr_range(3, 35, 1) ->{80, 95};

get_xilian_attr_range(4, 35, 1) ->{96, 111};

get_xilian_attr_range(5, 35, 1) ->{112, 127};

get_xilian_attr_range(6, 35, 1) ->{128, 143};

get_xilian_attr_range(7, 35, 1) ->{144, 159};

get_xilian_attr_range(8, 35, 1) ->{160, 175};

get_xilian_attr_range(9, 35, 1) ->{176, 191};

get_xilian_attr_range(10, 35, 1) ->{192, 207};

get_xilian_attr_range(1, 45, 1) ->{45, 95};

get_xilian_attr_range(2, 45, 1) ->{96, 111};

get_xilian_attr_range(3, 45, 1) ->{112, 127};

get_xilian_attr_range(4, 45, 1) ->{128, 143};

get_xilian_attr_range(5, 45, 1) ->{144, 159};

get_xilian_attr_range(6, 45, 1) ->{160, 175};

get_xilian_attr_range(7, 45, 1) ->{176, 191};

get_xilian_attr_range(8, 45, 1) ->{192, 207};

get_xilian_attr_range(9, 45, 1) ->{208, 223};

get_xilian_attr_range(10, 45, 1) ->{224, 239};

get_xilian_attr_range(1, 55, 1) ->{77, 127};

get_xilian_attr_range(2, 55, 1) ->{128, 143};

get_xilian_attr_range(3, 55, 1) ->{144, 159};

get_xilian_attr_range(4, 55, 1) ->{160, 175};

get_xilian_attr_range(5, 55, 1) ->{176, 191};

get_xilian_attr_range(6, 55, 1) ->{192, 207};

get_xilian_attr_range(7, 55, 1) ->{208, 223};

get_xilian_attr_range(8, 55, 1) ->{224, 239};

get_xilian_attr_range(9, 55, 1) ->{240, 255};

get_xilian_attr_range(10, 55, 1) ->{256, 271};

get_xilian_attr_range(1, 65, 1) ->{272, 159};

get_xilian_attr_range(2, 65, 1) ->{160, 175};

get_xilian_attr_range(3, 65, 1) ->{176, 191};

get_xilian_attr_range(4, 65, 1) ->{192, 207};

get_xilian_attr_range(5, 65, 1) ->{208, 223};

get_xilian_attr_range(6, 65, 1) ->{224, 239};

get_xilian_attr_range(7, 65, 1) ->{240, 255};

get_xilian_attr_range(8, 65, 1) ->{256, 271};

get_xilian_attr_range(9, 65, 1) ->{272, 287};

get_xilian_attr_range(10, 65, 1) ->{288, 303};

get_xilian_attr_range(1, 75, 1) ->{304, 191};

get_xilian_attr_range(2, 75, 1) ->{192, 207};

get_xilian_attr_range(3, 75, 1) ->{208, 223};

get_xilian_attr_range(4, 75, 1) ->{224, 239};

get_xilian_attr_range(5, 75, 1) ->{240, 255};

get_xilian_attr_range(6, 75, 1) ->{256, 271};

get_xilian_attr_range(7, 75, 1) ->{272, 287};

get_xilian_attr_range(8, 75, 1) ->{288, 303};

get_xilian_attr_range(9, 75, 1) ->{304, 319};

get_xilian_attr_range(10, 75, 1) ->{320, 335};

get_xilian_attr_range(1, 85, 1) ->{336, 223};

get_xilian_attr_range(2, 85, 1) ->{224, 239};

get_xilian_attr_range(3, 85, 1) ->{240, 255};

get_xilian_attr_range(4, 85, 1) ->{256, 271};

get_xilian_attr_range(5, 85, 1) ->{272, 287};

get_xilian_attr_range(6, 85, 1) ->{288, 303};

get_xilian_attr_range(7, 85, 1) ->{304, 319};

get_xilian_attr_range(8, 85, 1) ->{320, 335};

get_xilian_attr_range(9, 85, 1) ->{336, 351};

get_xilian_attr_range(10, 85, 1) ->{352, 367};

get_xilian_attr_range(1, 95, 1) ->{368, 255};

get_xilian_attr_range(2, 95, 1) ->{256, 271};

get_xilian_attr_range(3, 95, 1) ->{272, 287};

get_xilian_attr_range(4, 95, 1) ->{288, 303};

get_xilian_attr_range(5, 95, 1) ->{304, 319};

get_xilian_attr_range(6, 95, 1) ->{320, 335};

get_xilian_attr_range(7, 95, 1) ->{336, 351};

get_xilian_attr_range(8, 95, 1) ->{352, 367};

get_xilian_attr_range(9, 95, 1) ->{368, 383};

get_xilian_attr_range(10, 95, 1) ->{384, 399};

get_xilian_attr_range(1, 15, 2) ->{400, 11};

get_xilian_attr_range(2, 15, 2) ->{12, 23};

get_xilian_attr_range(3, 15, 2) ->{24, 35};

get_xilian_attr_range(4, 15, 2) ->{36, 47};

get_xilian_attr_range(5, 15, 2) ->{48, 63};

get_xilian_attr_range(6, 15, 2) ->{64, 79};

get_xilian_attr_range(7, 15, 2) ->{80, 95};

get_xilian_attr_range(8, 15, 2) ->{96, 111};

get_xilian_attr_range(9, 15, 2) ->{112, 127};

get_xilian_attr_range(10, 15, 2) ->{128, 143};

get_xilian_attr_range(1, 25, 2) ->{144, 35};

get_xilian_attr_range(2, 25, 2) ->{36, 47};

get_xilian_attr_range(3, 25, 2) ->{48, 63};

get_xilian_attr_range(4, 25, 2) ->{64, 79};

get_xilian_attr_range(5, 25, 2) ->{80, 95};

get_xilian_attr_range(6, 25, 2) ->{96, 111};

get_xilian_attr_range(7, 25, 2) ->{112, 127};

get_xilian_attr_range(8, 25, 2) ->{128, 143};

get_xilian_attr_range(9, 25, 2) ->{144, 159};

get_xilian_attr_range(10, 25, 2) ->{160, 175};

get_xilian_attr_range(1, 35, 2) ->{176, 63};

get_xilian_attr_range(2, 35, 2) ->{64, 79};

get_xilian_attr_range(3, 35, 2) ->{80, 95};

get_xilian_attr_range(4, 35, 2) ->{96, 111};

get_xilian_attr_range(5, 35, 2) ->{112, 127};

get_xilian_attr_range(6, 35, 2) ->{128, 143};

get_xilian_attr_range(7, 35, 2) ->{144, 159};

get_xilian_attr_range(8, 35, 2) ->{160, 175};

get_xilian_attr_range(9, 35, 2) ->{176, 191};

get_xilian_attr_range(10, 35, 2) ->{192, 207};

get_xilian_attr_range(1, 45, 2) ->{208, 95};

get_xilian_attr_range(2, 45, 2) ->{96, 111};

get_xilian_attr_range(3, 45, 2) ->{112, 127};

get_xilian_attr_range(4, 45, 2) ->{128, 143};

get_xilian_attr_range(5, 45, 2) ->{144, 159};

get_xilian_attr_range(6, 45, 2) ->{160, 175};

get_xilian_attr_range(7, 45, 2) ->{176, 191};

get_xilian_attr_range(8, 45, 2) ->{192, 207};

get_xilian_attr_range(9, 45, 2) ->{208, 223};

get_xilian_attr_range(10, 45, 2) ->{224, 239};

get_xilian_attr_range(1, 55, 2) ->{240, 127};

get_xilian_attr_range(2, 55, 2) ->{128, 143};

get_xilian_attr_range(3, 55, 2) ->{144, 159};

get_xilian_attr_range(4, 55, 2) ->{160, 175};

get_xilian_attr_range(5, 55, 2) ->{176, 191};

get_xilian_attr_range(6, 55, 2) ->{192, 207};

get_xilian_attr_range(7, 55, 2) ->{208, 223};

get_xilian_attr_range(8, 55, 2) ->{224, 239};

get_xilian_attr_range(9, 55, 2) ->{240, 255};

get_xilian_attr_range(10, 55, 2) ->{256, 271};

get_xilian_attr_range(1, 65, 2) ->{272, 159};

get_xilian_attr_range(2, 65, 2) ->{160, 175};

get_xilian_attr_range(3, 65, 2) ->{176, 191};

get_xilian_attr_range(4, 65, 2) ->{192, 207};

get_xilian_attr_range(5, 65, 2) ->{208, 223};

get_xilian_attr_range(6, 65, 2) ->{224, 239};

get_xilian_attr_range(7, 65, 2) ->{240, 255};

get_xilian_attr_range(8, 65, 2) ->{256, 271};

get_xilian_attr_range(9, 65, 2) ->{272, 287};

get_xilian_attr_range(10, 65, 2) ->{288, 303};

get_xilian_attr_range(1, 75, 2) ->{304, 191};

get_xilian_attr_range(2, 75, 2) ->{192, 207};

get_xilian_attr_range(3, 75, 2) ->{208, 223};

get_xilian_attr_range(4, 75, 2) ->{224, 239};

get_xilian_attr_range(5, 75, 2) ->{240, 255};

get_xilian_attr_range(6, 75, 2) ->{256, 271};

get_xilian_attr_range(7, 75, 2) ->{272, 287};

get_xilian_attr_range(8, 75, 2) ->{288, 303};

get_xilian_attr_range(9, 75, 2) ->{304, 319};

get_xilian_attr_range(10, 75, 2) ->{320, 335};

get_xilian_attr_range(1, 85, 2) ->{336, 223};

get_xilian_attr_range(2, 85, 2) ->{224, 239};

get_xilian_attr_range(3, 85, 2) ->{240, 255};

get_xilian_attr_range(4, 85, 2) ->{256, 271};

get_xilian_attr_range(5, 85, 2) ->{272, 287};

get_xilian_attr_range(6, 85, 2) ->{288, 303};

get_xilian_attr_range(7, 85, 2) ->{304, 319};

get_xilian_attr_range(8, 85, 2) ->{320, 335};

get_xilian_attr_range(9, 85, 2) ->{336, 351};

get_xilian_attr_range(10, 85, 2) ->{352, 367};

get_xilian_attr_range(1, 95, 2) ->{368, 255};

get_xilian_attr_range(2, 95, 2) ->{256, 271};

get_xilian_attr_range(3, 95, 2) ->{272, 287};

get_xilian_attr_range(4, 95, 2) ->{288, 303};

get_xilian_attr_range(5, 95, 2) ->{304, 319};

get_xilian_attr_range(6, 95, 2) ->{320, 335};

get_xilian_attr_range(7, 95, 2) ->{336, 351};

get_xilian_attr_range(8, 95, 2) ->{352, 367};

get_xilian_attr_range(9, 95, 2) ->{368, 383};

get_xilian_attr_range(10, 95, 2) ->{384, 399};

get_xilian_attr_range(1, 15, 11) ->{1, 1};

get_xilian_attr_range(2, 15, 11) ->{2, 2};

get_xilian_attr_range(3, 15, 11) ->{3, 3};

get_xilian_attr_range(4, 15, 11) ->{4, 4};

get_xilian_attr_range(5, 15, 11) ->{5, 5};

get_xilian_attr_range(6, 15, 11) ->{6, 6};

get_xilian_attr_range(7, 15, 11) ->{7, 7};

get_xilian_attr_range(8, 15, 11) ->{8, 8};

get_xilian_attr_range(9, 15, 11) ->{9, 9};

get_xilian_attr_range(10, 15, 11) ->{10, 10};

get_xilian_attr_range(1, 25, 11) ->{2, 3};

get_xilian_attr_range(2, 25, 11) ->{4, 4};

get_xilian_attr_range(3, 25, 11) ->{5, 5};

get_xilian_attr_range(4, 25, 11) ->{6, 6};

get_xilian_attr_range(5, 25, 11) ->{7, 7};

get_xilian_attr_range(6, 25, 11) ->{8, 8};

get_xilian_attr_range(7, 25, 11) ->{9, 9};

get_xilian_attr_range(8, 25, 11) ->{10, 10};

get_xilian_attr_range(9, 25, 11) ->{11, 11};

get_xilian_attr_range(10, 25, 11) ->{12, 12};

get_xilian_attr_range(1, 35, 11) ->{3, 5};

get_xilian_attr_range(2, 35, 11) ->{6, 6};

get_xilian_attr_range(3, 35, 11) ->{7, 7};

get_xilian_attr_range(4, 35, 11) ->{8, 8};

get_xilian_attr_range(5, 35, 11) ->{9, 9};

get_xilian_attr_range(6, 35, 11) ->{10, 10};

get_xilian_attr_range(7, 35, 11) ->{11, 11};

get_xilian_attr_range(8, 35, 11) ->{12, 12};

get_xilian_attr_range(9, 35, 11) ->{13, 13};

get_xilian_attr_range(10, 35, 11) ->{14, 14};

get_xilian_attr_range(1, 45, 11) ->{4, 7};

get_xilian_attr_range(2, 45, 11) ->{8, 8};

get_xilian_attr_range(3, 45, 11) ->{9, 9};

get_xilian_attr_range(4, 45, 11) ->{10, 10};

get_xilian_attr_range(5, 45, 11) ->{11, 11};

get_xilian_attr_range(6, 45, 11) ->{12, 12};

get_xilian_attr_range(7, 45, 11) ->{13, 13};

get_xilian_attr_range(8, 45, 11) ->{14, 14};

get_xilian_attr_range(9, 45, 11) ->{15, 15};

get_xilian_attr_range(10, 45, 11) ->{16, 16};

get_xilian_attr_range(1, 55, 11) ->{7, 9};

get_xilian_attr_range(2, 55, 11) ->{10, 10};

get_xilian_attr_range(3, 55, 11) ->{11, 11};

get_xilian_attr_range(4, 55, 11) ->{12, 12};

get_xilian_attr_range(5, 55, 11) ->{13, 13};

get_xilian_attr_range(6, 55, 11) ->{14, 14};

get_xilian_attr_range(7, 55, 11) ->{15, 15};

get_xilian_attr_range(8, 55, 11) ->{16, 16};

get_xilian_attr_range(9, 55, 11) ->{17, 17};

get_xilian_attr_range(10, 55, 11) ->{18, 18};

get_xilian_attr_range(1, 65, 11) ->{12, 13};

get_xilian_attr_range(2, 65, 11) ->{14, 14};

get_xilian_attr_range(3, 65, 11) ->{15, 15};

get_xilian_attr_range(4, 65, 11) ->{16, 16};

get_xilian_attr_range(5, 65, 11) ->{17, 17};

get_xilian_attr_range(6, 65, 11) ->{18, 18};

get_xilian_attr_range(7, 65, 11) ->{19, 19};

get_xilian_attr_range(8, 65, 11) ->{20, 20};

get_xilian_attr_range(9, 65, 11) ->{21, 21};

get_xilian_attr_range(10, 65, 11) ->{22, 22};

get_xilian_attr_range(1, 75, 11) ->{14, 16};

get_xilian_attr_range(2, 75, 11) ->{17, 17};

get_xilian_attr_range(3, 75, 11) ->{18, 18};

get_xilian_attr_range(4, 75, 11) ->{19, 19};

get_xilian_attr_range(5, 75, 11) ->{20, 20};

get_xilian_attr_range(6, 75, 11) ->{21, 21};

get_xilian_attr_range(7, 75, 11) ->{22, 22};

get_xilian_attr_range(8, 75, 11) ->{23, 23};

get_xilian_attr_range(9, 75, 11) ->{24, 24};

get_xilian_attr_range(10, 75, 11) ->{25, 25};

get_xilian_attr_range(1, 85, 11) ->{16, 19};

get_xilian_attr_range(2, 85, 11) ->{20, 20};

get_xilian_attr_range(3, 85, 11) ->{21, 21};

get_xilian_attr_range(4, 85, 11) ->{22, 22};

get_xilian_attr_range(5, 85, 11) ->{23, 23};

get_xilian_attr_range(6, 85, 11) ->{24, 24};

get_xilian_attr_range(7, 85, 11) ->{25, 25};

get_xilian_attr_range(8, 85, 11) ->{26, 26};

get_xilian_attr_range(9, 85, 11) ->{27, 27};

get_xilian_attr_range(10, 85, 11) ->{28, 73};

get_xilian_attr_range(1, 95, 11) ->{18, 21};

get_xilian_attr_range(2, 95, 11) ->{22, 22};

get_xilian_attr_range(3, 95, 11) ->{23, 23};

get_xilian_attr_range(4, 95, 11) ->{24, 24};

get_xilian_attr_range(5, 95, 11) ->{25, 25};

get_xilian_attr_range(6, 95, 11) ->{26, 26};

get_xilian_attr_range(7, 95, 11) ->{27, 27};

get_xilian_attr_range(8, 95, 11) ->{28, 73};

get_xilian_attr_range(9, 95, 11) ->{74, 76};

get_xilian_attr_range(10, 95, 11) ->{77, 80};

get_xilian_attr_range(1, 15, 12) ->{2, 2};

get_xilian_attr_range(2, 15, 12) ->{2, 2};

get_xilian_attr_range(3, 15, 12) ->{3, 3};

get_xilian_attr_range(4, 15, 12) ->{4, 4};

get_xilian_attr_range(5, 15, 12) ->{5, 5};

get_xilian_attr_range(6, 15, 12) ->{6, 6};

get_xilian_attr_range(7, 15, 12) ->{7, 7};

get_xilian_attr_range(8, 15, 12) ->{8, 8};

get_xilian_attr_range(9, 15, 12) ->{9, 9};

get_xilian_attr_range(10, 15, 12) ->{10, 10};

get_xilian_attr_range(1, 25, 12) ->{3, 3};

get_xilian_attr_range(2, 25, 12) ->{4, 4};

get_xilian_attr_range(3, 25, 12) ->{5, 5};

get_xilian_attr_range(4, 25, 12) ->{6, 6};

get_xilian_attr_range(5, 25, 12) ->{7, 7};

get_xilian_attr_range(6, 25, 12) ->{8, 8};

get_xilian_attr_range(7, 25, 12) ->{9, 9};

get_xilian_attr_range(8, 25, 12) ->{10, 10};

get_xilian_attr_range(9, 25, 12) ->{11, 11};

get_xilian_attr_range(10, 25, 12) ->{12, 12};

get_xilian_attr_range(1, 35, 12) ->{5, 5};

get_xilian_attr_range(2, 35, 12) ->{6, 6};

get_xilian_attr_range(3, 35, 12) ->{7, 7};

get_xilian_attr_range(4, 35, 12) ->{8, 8};

get_xilian_attr_range(5, 35, 12) ->{9, 9};

get_xilian_attr_range(6, 35, 12) ->{10, 10};

get_xilian_attr_range(7, 35, 12) ->{11, 11};

get_xilian_attr_range(8, 35, 12) ->{12, 12};

get_xilian_attr_range(9, 35, 12) ->{13, 13};

get_xilian_attr_range(10, 35, 12) ->{14, 14};

get_xilian_attr_range(1, 45, 12) ->{6, 7};

get_xilian_attr_range(2, 45, 12) ->{8, 8};

get_xilian_attr_range(3, 45, 12) ->{9, 9};

get_xilian_attr_range(4, 45, 12) ->{10, 10};

get_xilian_attr_range(5, 45, 12) ->{11, 11};

get_xilian_attr_range(6, 45, 12) ->{12, 12};

get_xilian_attr_range(7, 45, 12) ->{13, 13};

get_xilian_attr_range(8, 45, 12) ->{14, 14};

get_xilian_attr_range(9, 45, 12) ->{15, 15};

get_xilian_attr_range(10, 45, 12) ->{16, 16};

get_xilian_attr_range(1, 55, 12) ->{8, 9};

get_xilian_attr_range(2, 55, 12) ->{10, 10};

get_xilian_attr_range(3, 55, 12) ->{11, 11};

get_xilian_attr_range(4, 55, 12) ->{12, 12};

get_xilian_attr_range(5, 55, 12) ->{13, 13};

get_xilian_attr_range(6, 55, 12) ->{14, 14};

get_xilian_attr_range(7, 55, 12) ->{15, 15};

get_xilian_attr_range(8, 55, 12) ->{16, 16};

get_xilian_attr_range(9, 55, 12) ->{17, 17};

get_xilian_attr_range(10, 55, 12) ->{18, 18};

get_xilian_attr_range(1, 65, 12) ->{12, 13};

get_xilian_attr_range(2, 65, 12) ->{14, 14};

get_xilian_attr_range(3, 65, 12) ->{15, 15};

get_xilian_attr_range(4, 65, 12) ->{16, 16};

get_xilian_attr_range(5, 65, 12) ->{17, 17};

get_xilian_attr_range(6, 65, 12) ->{18, 18};

get_xilian_attr_range(7, 65, 12) ->{19, 19};

get_xilian_attr_range(8, 65, 12) ->{20, 20};

get_xilian_attr_range(9, 65, 12) ->{21, 21};

get_xilian_attr_range(10, 65, 12) ->{22, 22};

get_xilian_attr_range(1, 75, 12) ->{15, 16};

get_xilian_attr_range(2, 75, 12) ->{17, 17};

get_xilian_attr_range(3, 75, 12) ->{18, 18};

get_xilian_attr_range(4, 75, 12) ->{19, 19};

get_xilian_attr_range(5, 75, 12) ->{20, 20};

get_xilian_attr_range(6, 75, 12) ->{21, 21};

get_xilian_attr_range(7, 75, 12) ->{22, 22};

get_xilian_attr_range(8, 75, 12) ->{23, 23};

get_xilian_attr_range(9, 75, 12) ->{24, 24};

get_xilian_attr_range(10, 75, 12) ->{25, 25};

get_xilian_attr_range(1, 85, 12) ->{18, 19};

get_xilian_attr_range(2, 85, 12) ->{20, 20};

get_xilian_attr_range(3, 85, 12) ->{21, 48};

get_xilian_attr_range(4, 85, 12) ->{49, 51};

get_xilian_attr_range(5, 85, 12) ->{52, 54};

get_xilian_attr_range(6, 85, 12) ->{55, 57};

get_xilian_attr_range(7, 85, 12) ->{58, 60};

get_xilian_attr_range(8, 85, 12) ->{61, 63};

get_xilian_attr_range(9, 85, 12) ->{64, 65};

get_xilian_attr_range(10, 85, 12) ->{66, 68};

get_xilian_attr_range(1, 95, 12) ->{47, 48};

get_xilian_attr_range(2, 95, 12) ->{49, 51};

get_xilian_attr_range(3, 95, 12) ->{52, 54};

get_xilian_attr_range(4, 95, 12) ->{55, 57};

get_xilian_attr_range(5, 95, 12) ->{58, 60};

get_xilian_attr_range(6, 95, 12) ->{61, 63};

get_xilian_attr_range(7, 95, 12) ->{64, 65};

get_xilian_attr_range(8, 95, 12) ->{66, 68};

get_xilian_attr_range(9, 95, 12) ->{69, 71};

get_xilian_attr_range(10, 95, 12) ->{72, 75};

get_xilian_attr_range(1, 15, 13) ->{1, 1};

get_xilian_attr_range(2, 15, 13) ->{2, 2};

get_xilian_attr_range(3, 15, 13) ->{3, 3};

get_xilian_attr_range(4, 15, 13) ->{4, 4};

get_xilian_attr_range(5, 15, 13) ->{5, 5};

get_xilian_attr_range(6, 15, 13) ->{6, 6};

get_xilian_attr_range(7, 15, 13) ->{7, 7};

get_xilian_attr_range(8, 15, 13) ->{8, 8};

get_xilian_attr_range(9, 15, 13) ->{9, 9};

get_xilian_attr_range(10, 15, 13) ->{10, 10};

get_xilian_attr_range(1, 25, 13) ->{2, 3};

get_xilian_attr_range(2, 25, 13) ->{4, 4};

get_xilian_attr_range(3, 25, 13) ->{5, 5};

get_xilian_attr_range(4, 25, 13) ->{6, 6};

get_xilian_attr_range(5, 25, 13) ->{7, 7};

get_xilian_attr_range(6, 25, 13) ->{8, 8};

get_xilian_attr_range(7, 25, 13) ->{9, 9};

get_xilian_attr_range(8, 25, 13) ->{10, 10};

get_xilian_attr_range(9, 25, 13) ->{11, 11};

get_xilian_attr_range(10, 25, 13) ->{12, 12};

get_xilian_attr_range(1, 35, 13) ->{4, 5};

get_xilian_attr_range(2, 35, 13) ->{6, 6};

get_xilian_attr_range(3, 35, 13) ->{7, 7};

get_xilian_attr_range(4, 35, 13) ->{8, 8};

get_xilian_attr_range(5, 35, 13) ->{9, 9};

get_xilian_attr_range(6, 35, 13) ->{10, 10};

get_xilian_attr_range(7, 35, 13) ->{11, 11};

get_xilian_attr_range(8, 35, 13) ->{12, 12};

get_xilian_attr_range(9, 35, 13) ->{13, 13};

get_xilian_attr_range(10, 35, 13) ->{14, 14};

get_xilian_attr_range(1, 45, 13) ->{6, 7};

get_xilian_attr_range(2, 45, 13) ->{8, 8};

get_xilian_attr_range(3, 45, 13) ->{9, 9};

get_xilian_attr_range(4, 45, 13) ->{10, 10};

get_xilian_attr_range(5, 45, 13) ->{11, 11};

get_xilian_attr_range(6, 45, 13) ->{12, 12};

get_xilian_attr_range(7, 45, 13) ->{13, 13};

get_xilian_attr_range(8, 45, 13) ->{14, 14};

get_xilian_attr_range(9, 45, 13) ->{15, 15};

get_xilian_attr_range(10, 45, 13) ->{16, 16};

get_xilian_attr_range(1, 55, 13) ->{8, 9};

get_xilian_attr_range(2, 55, 13) ->{10, 10};

get_xilian_attr_range(3, 55, 13) ->{11, 11};

get_xilian_attr_range(4, 55, 13) ->{12, 12};

get_xilian_attr_range(5, 55, 13) ->{13, 13};

get_xilian_attr_range(6, 55, 13) ->{14, 14};

get_xilian_attr_range(7, 55, 13) ->{15, 15};

get_xilian_attr_range(8, 55, 13) ->{16, 16};

get_xilian_attr_range(9, 55, 13) ->{17, 17};

get_xilian_attr_range(10, 55, 13) ->{18, 18};

get_xilian_attr_range(1, 65, 13) ->{12, 13};

get_xilian_attr_range(2, 65, 13) ->{14, 14};

get_xilian_attr_range(3, 65, 13) ->{15, 15};

get_xilian_attr_range(4, 65, 13) ->{16, 16};

get_xilian_attr_range(5, 65, 13) ->{17, 17};

get_xilian_attr_range(6, 65, 13) ->{18, 18};

get_xilian_attr_range(7, 65, 13) ->{19, 19};

get_xilian_attr_range(8, 65, 13) ->{20, 20};

get_xilian_attr_range(9, 65, 13) ->{21, 21};

get_xilian_attr_range(10, 65, 13) ->{22, 22};

get_xilian_attr_range(1, 75, 13) ->{15, 16};

get_xilian_attr_range(2, 75, 13) ->{17, 17};

get_xilian_attr_range(3, 75, 13) ->{18, 18};

get_xilian_attr_range(4, 75, 13) ->{19, 19};

get_xilian_attr_range(5, 75, 13) ->{20, 20};

get_xilian_attr_range(6, 75, 13) ->{21, 21};

get_xilian_attr_range(7, 75, 13) ->{22, 22};

get_xilian_attr_range(8, 75, 13) ->{23, 23};

get_xilian_attr_range(9, 75, 13) ->{24, 24};

get_xilian_attr_range(10, 75, 13) ->{25, 25};

get_xilian_attr_range(1, 85, 13) ->{18, 19};

get_xilian_attr_range(2, 85, 13) ->{20, 20};

get_xilian_attr_range(3, 85, 13) ->{21, 32};

get_xilian_attr_range(4, 85, 13) ->{33, 34};

get_xilian_attr_range(5, 85, 13) ->{35, 36};

get_xilian_attr_range(6, 85, 13) ->{37, 38};

get_xilian_attr_range(7, 85, 13) ->{39, 40};

get_xilian_attr_range(8, 85, 13) ->{41, 42};

get_xilian_attr_range(9, 85, 13) ->{43, 44};

get_xilian_attr_range(10, 85, 13) ->{45, 46};

get_xilian_attr_range(1, 95, 13) ->{31, 32};

get_xilian_attr_range(2, 95, 13) ->{33, 34};

get_xilian_attr_range(3, 95, 13) ->{35, 36};

get_xilian_attr_range(4, 95, 13) ->{37, 38};

get_xilian_attr_range(5, 95, 13) ->{39, 40};

get_xilian_attr_range(6, 95, 13) ->{41, 42};

get_xilian_attr_range(7, 95, 13) ->{43, 44};

get_xilian_attr_range(8, 95, 13) ->{45, 46};

get_xilian_attr_range(9, 95, 13) ->{47, 48};

get_xilian_attr_range(10, 95, 13) ->{49, 50}.


%%================================================
%% 获取套装属性：get_suit_attr(套装等级, 套装数量) -> #role_update_attri
get_suit_attr(40, 3) -> 
#role_update_attri{
		                        gd_speed      = 110,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(40, 4) -> 
#role_update_attri{
		                        gd_speed      = 110,
gd_maxHp      = 430,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(40, 6) -> 
#role_update_attri{
		                        gd_speed      = 110,
gd_maxHp      = 430,
p_def         = 0,
m_def         = 0,
p_att         = 150,
m_att         = 150
		};

get_suit_attr(50, 3) -> 
#role_update_attri{
		                        gd_speed      = 160,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(50, 4) -> 
#role_update_attri{
		                        gd_speed      = 160,
gd_maxHp      = 650,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(50, 6) -> 
#role_update_attri{
		                        gd_speed      = 160,
gd_maxHp      = 650,
p_def         = 0,
m_def         = 0,
p_att         = 230,
m_att         = 230
		};

get_suit_attr(60, 3) -> 
#role_update_attri{
		                        gd_speed      = 250,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(60, 4) -> 
#role_update_attri{
		                        gd_speed      = 250,
gd_maxHp      = 990,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(60, 6) -> 
#role_update_attri{
		                        gd_speed      = 250,
gd_maxHp      = 990,
p_def         = 0,
m_def         = 0,
p_att         = 340,
m_att         = 340
		};

get_suit_attr(70, 3) -> 
#role_update_attri{
		                        gd_speed      = 350,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(70, 4) -> 
#role_update_attri{
		                        gd_speed      = 350,
gd_maxHp      = 1420,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(70, 6) -> 
#role_update_attri{
		                        gd_speed      = 350,
gd_maxHp      = 1420,
p_def         = 0,
m_def         = 0,
p_att         = 490,
m_att         = 490
		};

get_suit_attr(80, 3) -> 
#role_update_attri{
		                        gd_speed      = 460,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(80, 4) -> 
#role_update_attri{
		                        gd_speed      = 460,
gd_maxHp      = 1850,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(80, 6) -> 
#role_update_attri{
		                        gd_speed      = 460,
gd_maxHp      = 1850,
p_def         = 0,
m_def         = 0,
p_att         = 640,
m_att         = 640
		};

get_suit_attr(90, 3) -> 
#role_update_attri{
		                        gd_speed      = 560,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(90, 4) -> 
#role_update_attri{
		                        gd_speed      = 560,
gd_maxHp      = 2270,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(90, 6) -> 
#role_update_attri{
		                        gd_speed      = 560,
gd_maxHp      = 2270,
p_def         = 0,
m_def         = 0,
p_att         = 780,
m_att         = 780
		};

get_suit_attr(100, 3) -> 
#role_update_attri{
		                        gd_speed      = 700,
gd_maxHp      = 0,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(100, 4) -> 
#role_update_attri{
		                        gd_speed      = 700,
gd_maxHp      = 2840,
p_def         = 0,
m_def         = 0,
p_att         = 0,
m_att         = 0
		};

get_suit_attr(100, 6) -> 
#role_update_attri{
		                        gd_speed      = 700,
gd_maxHp      = 2840,
p_def         = 0,
m_def         = 0,
p_att         = 980,
m_att         = 980
		}.


%%================================================
%% 获取强化消耗：get_inten_cost(装备等级, 强化等级) -> {升一阶的银币消耗,升级金币消耗}
get_inten_cost(1,0) ->{300,5};

get_inten_cost(1,1) ->{900,10};

get_inten_cost(1,2) ->{2500,12};

get_inten_cost(1,3) ->{6300,15};

get_inten_cost(1,4) ->{15900,18};

get_inten_cost(1,5) ->{55500,20};

get_inten_cost(1,6) ->{138800,25};

get_inten_cost(1,7) ->{277600,30};

get_inten_cost(1,8) ->{396600,40};

get_inten_cost(1,9) ->{495700,50};

get_inten_cost(1,10) ->{619700,60};

get_inten_cost(1,11) ->{729000,80};

get_inten_cost(1,12) ->{810000,100};

get_inten_cost(1,13) ->{900000,120};

get_inten_cost(1,14) ->{1000000,150};

get_inten_cost(10,0) ->{300,5};

get_inten_cost(10,1) ->{900,10};

get_inten_cost(10,2) ->{2500,12};

get_inten_cost(10,3) ->{6300,15};

get_inten_cost(10,4) ->{15900,18};

get_inten_cost(10,5) ->{55500,20};

get_inten_cost(10,6) ->{138800,25};

get_inten_cost(10,7) ->{277600,30};

get_inten_cost(10,8) ->{396600,40};

get_inten_cost(10,9) ->{495700,50};

get_inten_cost(10,10) ->{619700,60};

get_inten_cost(10,11) ->{729000,80};

get_inten_cost(10,12) ->{810000,100};

get_inten_cost(10,13) ->{900000,120};

get_inten_cost(10,14) ->{1000000,150};

get_inten_cost(20,0) ->{300,5};

get_inten_cost(20,1) ->{900,10};

get_inten_cost(20,2) ->{2500,12};

get_inten_cost(20,3) ->{6300,15};

get_inten_cost(20,4) ->{15900,18};

get_inten_cost(20,5) ->{55500,20};

get_inten_cost(20,6) ->{138800,25};

get_inten_cost(20,7) ->{277600,30};

get_inten_cost(20,8) ->{396600,40};

get_inten_cost(20,9) ->{495700,50};

get_inten_cost(20,10) ->{619700,60};

get_inten_cost(20,11) ->{729000,80};

get_inten_cost(20,12) ->{810000,100};

get_inten_cost(20,13) ->{900000,120};

get_inten_cost(20,14) ->{1000000,150};

get_inten_cost(30,0) ->{300,5};

get_inten_cost(30,1) ->{900,10};

get_inten_cost(30,2) ->{2500,12};

get_inten_cost(30,3) ->{6300,15};

get_inten_cost(30,4) ->{15900,18};

get_inten_cost(30,5) ->{55500,20};

get_inten_cost(30,6) ->{138800,25};

get_inten_cost(30,7) ->{277600,30};

get_inten_cost(30,8) ->{396600,40};

get_inten_cost(30,9) ->{495700,50};

get_inten_cost(30,10) ->{619700,60};

get_inten_cost(30,11) ->{729000,80};

get_inten_cost(30,12) ->{810000,100};

get_inten_cost(30,13) ->{900000,120};

get_inten_cost(30,14) ->{1000000,150};

get_inten_cost(40,0) ->{300,5};

get_inten_cost(40,1) ->{900,10};

get_inten_cost(40,2) ->{2500,12};

get_inten_cost(40,3) ->{6300,15};

get_inten_cost(40,4) ->{15900,18};

get_inten_cost(40,5) ->{55500,20};

get_inten_cost(40,6) ->{138800,25};

get_inten_cost(40,7) ->{277600,30};

get_inten_cost(40,8) ->{396600,40};

get_inten_cost(40,9) ->{495700,50};

get_inten_cost(40,10) ->{619700,60};

get_inten_cost(40,11) ->{729000,80};

get_inten_cost(40,12) ->{810000,100};

get_inten_cost(40,13) ->{900000,120};

get_inten_cost(40,14) ->{1000000,150};

get_inten_cost(50,0) ->{300,5};

get_inten_cost(50,1) ->{900,10};

get_inten_cost(50,2) ->{2500,12};

get_inten_cost(50,3) ->{6300,15};

get_inten_cost(50,4) ->{15900,18};

get_inten_cost(50,5) ->{55500,20};

get_inten_cost(50,6) ->{138800,25};

get_inten_cost(50,7) ->{277600,30};

get_inten_cost(50,8) ->{396600,40};

get_inten_cost(50,9) ->{495700,50};

get_inten_cost(50,10) ->{619700,60};

get_inten_cost(50,11) ->{729000,80};

get_inten_cost(50,12) ->{810000,100};

get_inten_cost(50,13) ->{900000,120};

get_inten_cost(50,14) ->{1000000,150};

get_inten_cost(60,0) ->{300,5};

get_inten_cost(60,1) ->{900,10};

get_inten_cost(60,2) ->{2500,12};

get_inten_cost(60,3) ->{6300,15};

get_inten_cost(60,4) ->{15900,18};

get_inten_cost(60,5) ->{55500,20};

get_inten_cost(60,6) ->{138800,25};

get_inten_cost(60,7) ->{277600,30};

get_inten_cost(60,8) ->{396600,40};

get_inten_cost(60,9) ->{495700,50};

get_inten_cost(60,10) ->{619700,60};

get_inten_cost(60,11) ->{729000,80};

get_inten_cost(60,12) ->{810000,100};

get_inten_cost(60,13) ->{900000,120};

get_inten_cost(60,14) ->{1000000,150};

get_inten_cost(70,0) ->{300,5};

get_inten_cost(70,1) ->{900,10};

get_inten_cost(70,2) ->{2500,12};

get_inten_cost(70,3) ->{6300,15};

get_inten_cost(70,4) ->{15900,18};

get_inten_cost(70,5) ->{55500,20};

get_inten_cost(70,6) ->{138800,25};

get_inten_cost(70,7) ->{277600,30};

get_inten_cost(70,8) ->{396600,40};

get_inten_cost(70,9) ->{495700,50};

get_inten_cost(70,10) ->{619700,60};

get_inten_cost(70,11) ->{729000,80};

get_inten_cost(70,12) ->{810000,100};

get_inten_cost(70,13) ->{900000,120};

get_inten_cost(70,14) ->{1000000,150};

get_inten_cost(80,0) ->{300,5};

get_inten_cost(80,1) ->{900,10};

get_inten_cost(80,2) ->{2500,12};

get_inten_cost(80,3) ->{6300,15};

get_inten_cost(80,4) ->{15900,18};

get_inten_cost(80,5) ->{55500,20};

get_inten_cost(80,6) ->{138800,25};

get_inten_cost(80,7) ->{277600,30};

get_inten_cost(80,8) ->{396600,40};

get_inten_cost(80,9) ->{495700,50};

get_inten_cost(80,10) ->{619700,60};

get_inten_cost(80,11) ->{729000,80};

get_inten_cost(80,12) ->{810000,100};

get_inten_cost(80,13) ->{900000,120};

get_inten_cost(80,14) ->{1000000,150};

get_inten_cost(90,0) ->{300,5};

get_inten_cost(90,1) ->{900,10};

get_inten_cost(90,2) ->{2500,12};

get_inten_cost(90,3) ->{6300,15};

get_inten_cost(90,4) ->{15900,18};

get_inten_cost(90,5) ->{55500,20};

get_inten_cost(90,6) ->{138800,25};

get_inten_cost(90,7) ->{277600,30};

get_inten_cost(90,8) ->{396600,40};

get_inten_cost(90,9) ->{495700,50};

get_inten_cost(90,10) ->{619700,60};

get_inten_cost(90,11) ->{729000,80};

get_inten_cost(90,12) ->{810000,100};

get_inten_cost(90,13) ->{900000,120};

get_inten_cost(90,14) ->{1000000,150};

get_inten_cost(100,0) ->{300,5};

get_inten_cost(100,1) ->{900,10};

get_inten_cost(100,2) ->{2500,12};

get_inten_cost(100,3) ->{6300,15};

get_inten_cost(100,4) ->{15900,18};

get_inten_cost(100,5) ->{55500,20};

get_inten_cost(100,6) ->{138800,25};

get_inten_cost(100,7) ->{277600,30};

get_inten_cost(100,8) ->{396600,40};

get_inten_cost(100,9) ->{495700,50};

get_inten_cost(100,10) ->{619700,60};

get_inten_cost(100,11) ->{729000,80};

get_inten_cost(100,12) ->{810000,100};

get_inten_cost(100,13) ->{900000,120};

get_inten_cost(100,14) ->{1000000,150};

get_inten_cost(25,0) ->{300,5};

get_inten_cost(25,1) ->{900,10};

get_inten_cost(25,2) ->{2500,12};

get_inten_cost(25,3) ->{6300,15};

get_inten_cost(25,4) ->{15900,18};

get_inten_cost(25,5) ->{55500,20};

get_inten_cost(25,6) ->{138800,25};

get_inten_cost(25,7) ->{277600,30};

get_inten_cost(25,8) ->{396600,40};

get_inten_cost(25,9) ->{495700,50};

get_inten_cost(25,10) ->{619700,60};

get_inten_cost(25,11) ->{729000,80};

get_inten_cost(25,12) ->{810000,100};

get_inten_cost(25,13) ->{900000,120};

get_inten_cost(25,14) ->{1000000,150};

get_inten_cost(35,0) ->{300,5};

get_inten_cost(35,1) ->{900,10};

get_inten_cost(35,2) ->{2500,12};

get_inten_cost(35,3) ->{6300,15};

get_inten_cost(35,4) ->{15900,18};

get_inten_cost(35,5) ->{55500,20};

get_inten_cost(35,6) ->{138800,25};

get_inten_cost(35,7) ->{277600,30};

get_inten_cost(35,8) ->{396600,40};

get_inten_cost(35,9) ->{495700,50};

get_inten_cost(35,10) ->{619700,60};

get_inten_cost(35,11) ->{729000,80};

get_inten_cost(35,12) ->{810000,100};

get_inten_cost(35,13) ->{900000,120};

get_inten_cost(35,14) ->{1000000,150};

get_inten_cost(45,0) ->{300,5};

get_inten_cost(45,1) ->{900,10};

get_inten_cost(45,2) ->{2500,12};

get_inten_cost(45,3) ->{6300,15};

get_inten_cost(45,4) ->{15900,18};

get_inten_cost(45,5) ->{55500,20};

get_inten_cost(45,6) ->{138800,25};

get_inten_cost(45,7) ->{277600,30};

get_inten_cost(45,8) ->{396600,40};

get_inten_cost(45,9) ->{495700,50};

get_inten_cost(45,10) ->{619700,60};

get_inten_cost(45,11) ->{729000,80};

get_inten_cost(45,12) ->{810000,100};

get_inten_cost(45,13) ->{900000,120};

get_inten_cost(45,14) ->{1000000,150};

get_inten_cost(55,0) ->{300,5};

get_inten_cost(55,1) ->{900,10};

get_inten_cost(55,2) ->{2500,12};

get_inten_cost(55,3) ->{6300,15};

get_inten_cost(55,4) ->{15900,18};

get_inten_cost(55,5) ->{55500,20};

get_inten_cost(55,6) ->{138800,25};

get_inten_cost(55,7) ->{277600,30};

get_inten_cost(55,8) ->{396600,40};

get_inten_cost(55,9) ->{495700,50};

get_inten_cost(55,10) ->{619700,60};

get_inten_cost(55,11) ->{729000,80};

get_inten_cost(55,12) ->{810000,100};

get_inten_cost(55,13) ->{900000,120};

get_inten_cost(55,14) ->{1000000,150};

get_inten_cost(65,0) ->{300,5};

get_inten_cost(65,1) ->{900,10};

get_inten_cost(65,2) ->{2500,12};

get_inten_cost(65,3) ->{6300,15};

get_inten_cost(65,4) ->{15900,18};

get_inten_cost(65,5) ->{55500,20};

get_inten_cost(65,6) ->{138800,25};

get_inten_cost(65,7) ->{277600,30};

get_inten_cost(65,8) ->{396600,40};

get_inten_cost(65,9) ->{495700,50};

get_inten_cost(65,10) ->{619700,60};

get_inten_cost(65,11) ->{729000,80};

get_inten_cost(65,12) ->{810000,100};

get_inten_cost(65,13) ->{900000,120};

get_inten_cost(65,14) ->{1000000,150};

get_inten_cost(75,0) ->{300,5};

get_inten_cost(75,1) ->{900,10};

get_inten_cost(75,2) ->{2500,12};

get_inten_cost(75,3) ->{6300,15};

get_inten_cost(75,4) ->{15900,18};

get_inten_cost(75,5) ->{55500,20};

get_inten_cost(75,6) ->{138800,25};

get_inten_cost(75,7) ->{277600,30};

get_inten_cost(75,8) ->{396600,40};

get_inten_cost(75,9) ->{495700,50};

get_inten_cost(75,10) ->{619700,60};

get_inten_cost(75,11) ->{729000,80};

get_inten_cost(75,12) ->{810000,100};

get_inten_cost(75,13) ->{900000,120};

get_inten_cost(75,14) ->{1000000,150};

get_inten_cost(85,0) ->{300,5};

get_inten_cost(85,1) ->{900,10};

get_inten_cost(85,2) ->{2500,12};

get_inten_cost(85,3) ->{6300,15};

get_inten_cost(85,4) ->{15900,18};

get_inten_cost(85,5) ->{55500,20};

get_inten_cost(85,6) ->{138800,25};

get_inten_cost(85,7) ->{277600,30};

get_inten_cost(85,8) ->{396600,40};

get_inten_cost(85,9) ->{495700,50};

get_inten_cost(85,10) ->{619700,60};

get_inten_cost(85,11) ->{729000,80};

get_inten_cost(85,12) ->{810000,100};

get_inten_cost(85,13) ->{900000,120};

get_inten_cost(85,14) ->{1000000,150};

get_inten_cost(95,0) ->{300,5};

get_inten_cost(95,1) ->{900,10};

get_inten_cost(95,2) ->{2500,12};

get_inten_cost(95,3) ->{6300,15};

get_inten_cost(95,4) ->{15900,18};

get_inten_cost(95,5) ->{55500,20};

get_inten_cost(95,6) ->{138800,25};

get_inten_cost(95,7) ->{277600,30};

get_inten_cost(95,8) ->{396600,40};

get_inten_cost(95,9) ->{495700,50};

get_inten_cost(95,10) ->{619700,60};

get_inten_cost(95,11) ->{729000,80};

get_inten_cost(95,12) ->{810000,100};

get_inten_cost(95,13) ->{900000,120};

get_inten_cost(95,14) ->{1000000,150}.


%%================================================
%% 洗练星星消耗：get_xilian_star_cost(装备等级, 幸运星级) -> 金币
get_xilian_star_cost(1, 1) -> 5;

get_xilian_star_cost(1, 2) -> 10;

get_xilian_star_cost(1, 3) -> 20;

get_xilian_star_cost(1, 4) -> 30;

get_xilian_star_cost(1, 5) -> 40;

get_xilian_star_cost(1, 6) -> 60;

get_xilian_star_cost(10, 1) -> 6;

get_xilian_star_cost(10, 2) -> 12;

get_xilian_star_cost(10, 3) -> 24;

get_xilian_star_cost(10, 4) -> 36;

get_xilian_star_cost(10, 5) -> 48;

get_xilian_star_cost(10, 6) -> 72;

get_xilian_star_cost(20, 1) -> 7;

get_xilian_star_cost(20, 2) -> 14;

get_xilian_star_cost(20, 3) -> 29;

get_xilian_star_cost(20, 4) -> 43;

get_xilian_star_cost(20, 5) -> 58;

get_xilian_star_cost(20, 6) -> 86;

get_xilian_star_cost(30, 1) -> 8;

get_xilian_star_cost(30, 2) -> 17;

get_xilian_star_cost(30, 3) -> 35;

get_xilian_star_cost(30, 4) -> 52;

get_xilian_star_cost(30, 5) -> 70;

get_xilian_star_cost(30, 6) -> 103;

get_xilian_star_cost(40, 1) -> 10;

get_xilian_star_cost(40, 2) -> 20;

get_xilian_star_cost(40, 3) -> 42;

get_xilian_star_cost(40, 4) -> 62;

get_xilian_star_cost(40, 5) -> 84;

get_xilian_star_cost(40, 6) -> 124;

get_xilian_star_cost(50, 1) -> 12;

get_xilian_star_cost(50, 2) -> 24;

get_xilian_star_cost(50, 3) -> 50;

get_xilian_star_cost(50, 4) -> 74;

get_xilian_star_cost(50, 5) -> 101;

get_xilian_star_cost(50, 6) -> 149;

get_xilian_star_cost(60, 1) -> 14;

get_xilian_star_cost(60, 2) -> 29;

get_xilian_star_cost(60, 3) -> 60;

get_xilian_star_cost(60, 4) -> 89;

get_xilian_star_cost(60, 5) -> 121;

get_xilian_star_cost(60, 6) -> 179;

get_xilian_star_cost(70, 1) -> 17;

get_xilian_star_cost(70, 2) -> 35;

get_xilian_star_cost(70, 3) -> 72;

get_xilian_star_cost(70, 4) -> 107;

get_xilian_star_cost(70, 5) -> 145;

get_xilian_star_cost(70, 6) -> 215;

get_xilian_star_cost(80, 1) -> 20;

get_xilian_star_cost(80, 2) -> 42;

get_xilian_star_cost(80, 3) -> 86;

get_xilian_star_cost(80, 4) -> 128;

get_xilian_star_cost(80, 5) -> 174;

get_xilian_star_cost(80, 6) -> 258;

get_xilian_star_cost(90, 1) -> 24;

get_xilian_star_cost(90, 2) -> 50;

get_xilian_star_cost(90, 3) -> 103;

get_xilian_star_cost(90, 4) -> 154;

get_xilian_star_cost(90, 5) -> 209;

get_xilian_star_cost(90, 6) -> 310;

get_xilian_star_cost(100, 1) -> 29;

get_xilian_star_cost(100, 2) -> 60;

get_xilian_star_cost(100, 3) -> 124;

get_xilian_star_cost(100, 4) -> 185;

get_xilian_star_cost(100, 5) -> 251;

get_xilian_star_cost(100, 6) -> 372;

get_xilian_star_cost(25, 1) -> 8;

get_xilian_star_cost(25, 2) -> 17;

get_xilian_star_cost(25, 3) -> 35;

get_xilian_star_cost(25, 4) -> 52;

get_xilian_star_cost(25, 5) -> 70;

get_xilian_star_cost(25, 6) -> 103;

get_xilian_star_cost(35, 1) -> 10;

get_xilian_star_cost(35, 2) -> 20;

get_xilian_star_cost(35, 3) -> 42;

get_xilian_star_cost(35, 4) -> 62;

get_xilian_star_cost(35, 5) -> 84;

get_xilian_star_cost(35, 6) -> 124;

get_xilian_star_cost(45, 1) -> 12;

get_xilian_star_cost(45, 2) -> 24;

get_xilian_star_cost(45, 3) -> 50;

get_xilian_star_cost(45, 4) -> 74;

get_xilian_star_cost(45, 5) -> 101;

get_xilian_star_cost(45, 6) -> 149;

get_xilian_star_cost(55, 1) -> 14;

get_xilian_star_cost(55, 2) -> 29;

get_xilian_star_cost(55, 3) -> 60;

get_xilian_star_cost(55, 4) -> 89;

get_xilian_star_cost(55, 5) -> 121;

get_xilian_star_cost(55, 6) -> 179;

get_xilian_star_cost(65, 1) -> 17;

get_xilian_star_cost(65, 2) -> 35;

get_xilian_star_cost(65, 3) -> 72;

get_xilian_star_cost(65, 4) -> 107;

get_xilian_star_cost(65, 5) -> 145;

get_xilian_star_cost(65, 6) -> 215;

get_xilian_star_cost(75, 1) -> 20;

get_xilian_star_cost(75, 2) -> 42;

get_xilian_star_cost(75, 3) -> 86;

get_xilian_star_cost(75, 4) -> 128;

get_xilian_star_cost(75, 5) -> 174;

get_xilian_star_cost(75, 6) -> 258;

get_xilian_star_cost(85, 1) -> 24;

get_xilian_star_cost(85, 2) -> 50;

get_xilian_star_cost(85, 3) -> 103;

get_xilian_star_cost(85, 4) -> 154;

get_xilian_star_cost(85, 5) -> 209;

get_xilian_star_cost(85, 6) -> 310;

get_xilian_star_cost(95, 1) -> 29;

get_xilian_star_cost(95, 2) -> 60;

get_xilian_star_cost(95, 3) -> 124;

get_xilian_star_cost(95, 4) -> 185;

get_xilian_star_cost(95, 5) -> 251;

get_xilian_star_cost(95, 6) -> 372.


%%================================================
%% 宝石镶嵌拆卸费用：get_inlay_cost(宝石等级) -> {镶嵌银币费用, 拆卸银币消耗}
get_inlay_cost(1) -> {1500, 1500};

get_inlay_cost(2) -> {3500, 3500};

get_inlay_cost(3) -> {5000, 5000};

get_inlay_cost(4) -> {10000, 10000};

get_inlay_cost(5) -> {25000, 25000};

get_inlay_cost(6) -> {40000, 40000};

get_inlay_cost(7) -> {60000, 60000};

get_inlay_cost(8) -> {70000, 70000};

get_inlay_cost(9) -> {80000, 80000};

get_inlay_cost(10) -> {100000, 100000}.


%%================================================
%% 升级原型变动：get_upgrate_cfgid(装备ID) -> 下个原型ID
get_upgrate_cfgid(4) -> 12;

get_upgrate_cfgid(5) -> 13;

get_upgrate_cfgid(6) -> 14;

get_upgrate_cfgid(7) -> 15;

get_upgrate_cfgid(8) -> 16;

get_upgrate_cfgid(9) -> 17;

get_upgrate_cfgid(10) -> 18;

get_upgrate_cfgid(11) -> 19;

get_upgrate_cfgid(12) -> 20;

get_upgrate_cfgid(13) -> 21;

get_upgrate_cfgid(14) -> 22;

get_upgrate_cfgid(15) -> 23;

get_upgrate_cfgid(16) -> 24;

get_upgrate_cfgid(17) -> 25;

get_upgrate_cfgid(18) -> 26;

get_upgrate_cfgid(19) -> 27;

get_upgrate_cfgid(20) -> 28;

get_upgrate_cfgid(21) -> 29;

get_upgrate_cfgid(22) -> 30;

get_upgrate_cfgid(23) -> 31;

get_upgrate_cfgid(24) -> 32;

get_upgrate_cfgid(25) -> 33;

get_upgrate_cfgid(26) -> 34;

get_upgrate_cfgid(27) -> 35;

get_upgrate_cfgid(28) -> 36;

get_upgrate_cfgid(29) -> 37;

get_upgrate_cfgid(30) -> 38;

get_upgrate_cfgid(31) -> 39;

get_upgrate_cfgid(32) -> 40;

get_upgrate_cfgid(33) -> 41;

get_upgrate_cfgid(34) -> 42;

get_upgrate_cfgid(35) -> 43;

get_upgrate_cfgid(36) -> 44;

get_upgrate_cfgid(37) -> 45;

get_upgrate_cfgid(38) -> 46;

get_upgrate_cfgid(39) -> 47;

get_upgrate_cfgid(40) -> 48;

get_upgrate_cfgid(41) -> 49;

get_upgrate_cfgid(42) -> 50;

get_upgrate_cfgid(43) -> 51;

get_upgrate_cfgid(44) -> 52;

get_upgrate_cfgid(45) -> 53;

get_upgrate_cfgid(46) -> 54;

get_upgrate_cfgid(47) -> 55;

get_upgrate_cfgid(48) -> 56;

get_upgrate_cfgid(49) -> 57;

get_upgrate_cfgid(50) -> 58;

get_upgrate_cfgid(51) -> 59;

get_upgrate_cfgid(52) -> 60;

get_upgrate_cfgid(53) -> 61;

get_upgrate_cfgid(54) -> 62;

get_upgrate_cfgid(55) -> 63;

get_upgrate_cfgid(56) -> 64;

get_upgrate_cfgid(57) -> 65;

get_upgrate_cfgid(58) -> 66;

get_upgrate_cfgid(59) -> 67;

get_upgrate_cfgid(60) -> 68;

get_upgrate_cfgid(61) -> 69;

get_upgrate_cfgid(62) -> 70;

get_upgrate_cfgid(63) -> 71;

get_upgrate_cfgid(64) -> 72;

get_upgrate_cfgid(65) -> 73;

get_upgrate_cfgid(66) -> 74;

get_upgrate_cfgid(67) -> 75;

get_upgrate_cfgid(68) -> 76;

get_upgrate_cfgid(69) -> 77;

get_upgrate_cfgid(70) -> 78;

get_upgrate_cfgid(71) -> 79;

get_upgrate_cfgid(72) -> 80;

get_upgrate_cfgid(73) -> 81;

get_upgrate_cfgid(74) -> 82;

get_upgrate_cfgid(75) -> 83;

get_upgrate_cfgid(76) -> 84;

get_upgrate_cfgid(77) -> 85;

get_upgrate_cfgid(78) -> 86;

get_upgrate_cfgid(79) -> 87;

get_upgrate_cfgid(80) -> 88;

get_upgrate_cfgid(81) -> 89;

get_upgrate_cfgid(82) -> 90;

get_upgrate_cfgid(83) -> 91;

get_upgrate_cfgid(298) -> 299;

get_upgrate_cfgid(299) -> 300;

get_upgrate_cfgid(300) -> 301;

get_upgrate_cfgid(301) -> 302;

get_upgrate_cfgid(302) -> 303;

get_upgrate_cfgid(303) -> 304;

get_upgrate_cfgid(304) -> 305.


%%================================================
%% 采集事件获取：get_collect_task(NPCID) -> 商店ID
get_collect_task(13) -> [0];

get_collect_task(14) -> [0];

get_collect_task(15) -> [0];

get_collect_task(16) -> [0];

get_collect_task(17) -> [0];

get_collect_task(119) -> [0];

get_collect_task(120) -> [0].


%%================================================
%% 采集事件获取：get_wlsd_event(藏宝图ID, RandNum) when RandNum =<几率 -> {事件类型, 数值, 是否绑定}
get_wlsd_event(433, RandNum) when RandNum =< 10 -> {0, 0, 0};

get_wlsd_event(433, RandNum) when RandNum =< 20 -> {1, 3, 0};

get_wlsd_event(433, RandNum) when RandNum =< 30 -> {1, 5, 0};

get_wlsd_event(433, RandNum) when RandNum =< 35 -> {3, 5, 0};

get_wlsd_event(433, RandNum) when RandNum =< 40 -> {3, 10, 1};

get_wlsd_event(433, RandNum) when RandNum =< 45 -> {4, 2000, 0};

get_wlsd_event(433, RandNum) when RandNum =< 50 -> {4, 1000, 0};

get_wlsd_event(433, RandNum) when RandNum =< 60 -> {4, 500, 0};

get_wlsd_event(433, RandNum) when RandNum =< 64 -> {2, 12, 0};

get_wlsd_event(433, RandNum) when RandNum =< 68 -> {2, 13, 0};

get_wlsd_event(433, RandNum) when RandNum =< 72 -> {2, 14, 0};

get_wlsd_event(433, RandNum) when RandNum =< 76 -> {2, 15, 0};

get_wlsd_event(433, RandNum) when RandNum =< 80 -> {2, 16, 0};

get_wlsd_event(433, RandNum) when RandNum =< 84 -> {2, 17, 0};

get_wlsd_event(433, RandNum) when RandNum =< 88 -> {2, 18, 0};

get_wlsd_event(433, RandNum) when RandNum =< 92 -> {2, 19, 0};

get_wlsd_event(433, RandNum) when RandNum =< 96 -> {2, 96, 0};

get_wlsd_event(433, RandNum) when RandNum =< 100 -> {2, 97, 0}.


%%================================================
%% 宝石合成：get_compose_target(原型ID)->合成目标ID;	
get_compose_target(92) -> 93;

get_compose_target(93) -> 94;

get_compose_target(94) -> 95;

get_compose_target(95) -> 96;

get_compose_target(96) -> 97;

get_compose_target(97) -> 98;

get_compose_target(98) -> 99;

get_compose_target(99) -> 100;

get_compose_target(100) -> 101;

get_compose_target(101) -> 0;

get_compose_target(102) -> 103;

get_compose_target(103) -> 104;

get_compose_target(104) -> 105;

get_compose_target(105) -> 106;

get_compose_target(106) -> 107;

get_compose_target(107) -> 108;

get_compose_target(108) -> 109;

get_compose_target(109) -> 110;

get_compose_target(110) -> 111;

get_compose_target(111) -> 0;

get_compose_target(112) -> 113;

get_compose_target(113) -> 114;

get_compose_target(114) -> 115;

get_compose_target(115) -> 116;

get_compose_target(116) -> 117;

get_compose_target(117) -> 118;

get_compose_target(118) -> 119;

get_compose_target(119) -> 120;

get_compose_target(120) -> 121;

get_compose_target(121) -> 0;

get_compose_target(122) -> 123;

get_compose_target(123) -> 124;

get_compose_target(124) -> 125;

get_compose_target(125) -> 126;

get_compose_target(126) -> 127;

get_compose_target(127) -> 128;

get_compose_target(128) -> 129;

get_compose_target(129) -> 130;

get_compose_target(130) -> 131;

get_compose_target(131) -> 0;

get_compose_target(132) -> 133;

get_compose_target(133) -> 134;

get_compose_target(134) -> 135;

get_compose_target(135) -> 136;

get_compose_target(136) -> 137;

get_compose_target(137) -> 138;

get_compose_target(138) -> 139;

get_compose_target(139) -> 140;

get_compose_target(140) -> 141;

get_compose_target(141) -> 0;

get_compose_target(142) -> 143;

get_compose_target(143) -> 144;

get_compose_target(144) -> 145;

get_compose_target(145) -> 146;

get_compose_target(146) -> 147;

get_compose_target(147) -> 148;

get_compose_target(148) -> 149;

get_compose_target(149) -> 150;

get_compose_target(150) -> 151;

get_compose_target(151) -> 0;

get_compose_target(152) -> 153;

get_compose_target(153) -> 154;

get_compose_target(154) -> 155;

get_compose_target(155) -> 156;

get_compose_target(156) -> 157;

get_compose_target(157) -> 158;

get_compose_target(158) -> 159;

get_compose_target(159) -> 160;

get_compose_target(160) -> 161;

get_compose_target(161) -> 0;

get_compose_target(162) -> 163;

get_compose_target(163) -> 164;

get_compose_target(164) -> 165;

get_compose_target(165) -> 166;

get_compose_target(166) -> 167;

get_compose_target(167) -> 168;

get_compose_target(168) -> 169;

get_compose_target(169) -> 170;

get_compose_target(170) -> 171;

get_compose_target(171) -> 0;

get_compose_target(172) -> 173;

get_compose_target(173) -> 174;

get_compose_target(174) -> 175;

get_compose_target(175) -> 176;

get_compose_target(176) -> 177;

get_compose_target(177) -> 178;

get_compose_target(178) -> 179;

get_compose_target(179) -> 180;

get_compose_target(180) -> 181;

get_compose_target(181) -> 0;

get_compose_target(316) -> 317;

get_compose_target(317) -> 318;

get_compose_target(318) -> 319;

get_compose_target(319) -> 320;

get_compose_target(320) -> 321;

get_compose_target(321) -> 322;

get_compose_target(322) -> 323;

get_compose_target(323) -> 324;

get_compose_target(324) -> 325;

get_compose_target(325) -> 0;

get_compose_target(326) -> 327;

get_compose_target(327) -> 328;

get_compose_target(328) -> 329;

get_compose_target(329) -> 330;

get_compose_target(330) -> 331;

get_compose_target(331) -> 332;

get_compose_target(332) -> 333;

get_compose_target(333) -> 334;

get_compose_target(334) -> 335;

get_compose_target(335) -> 0;

get_compose_target(336) -> 337;

get_compose_target(337) -> 338;

get_compose_target(338) -> 339;

get_compose_target(339) -> 340;

get_compose_target(340) -> 341;

get_compose_target(341) -> 342;

get_compose_target(342) -> 343;

get_compose_target(343) -> 344;

get_compose_target(344) -> 345;

get_compose_target(345) -> 0;

get_compose_target(346) -> 347;

get_compose_target(347) -> 348;

get_compose_target(348) -> 349;

get_compose_target(349) -> 350;

get_compose_target(350) -> 351;

get_compose_target(351) -> 352;

get_compose_target(352) -> 353;

get_compose_target(353) -> 354;

get_compose_target(354) -> 355;

get_compose_target(355) -> 0;

get_compose_target(356) -> 357;

get_compose_target(357) -> 358;

get_compose_target(358) -> 359;

get_compose_target(359) -> 360;

get_compose_target(360) -> 361;

get_compose_target(361) -> 362;

get_compose_target(362) -> 363;

get_compose_target(363) -> 364;

get_compose_target(364) -> 365;

get_compose_target(365) -> 0;

get_compose_target(366) -> 367;

get_compose_target(367) -> 368;

get_compose_target(368) -> 369;

get_compose_target(369) -> 370;

get_compose_target(370) -> 371;

get_compose_target(371) -> 372;

get_compose_target(372) -> 373;

get_compose_target(373) -> 374;

get_compose_target(374) -> 375;

get_compose_target(375) -> 0;

get_compose_target(376) -> 377;

get_compose_target(377) -> 378;

get_compose_target(378) -> 379;

get_compose_target(379) -> 380;

get_compose_target(380) -> 381;

get_compose_target(381) -> 382;

get_compose_target(382) -> 383;

get_compose_target(383) -> 384;

get_compose_target(384) -> 385;

get_compose_target(385) -> 0;

get_compose_target(386) -> 387;

get_compose_target(387) -> 388;

get_compose_target(388) -> 389;

get_compose_target(389) -> 390;

get_compose_target(390) -> 391;

get_compose_target(391) -> 392;

get_compose_target(392) -> 393;

get_compose_target(393) -> 394;

get_compose_target(394) -> 395;

get_compose_target(395) -> 0;

get_compose_target(396) -> 397;

get_compose_target(397) -> 398;

get_compose_target(398) -> 399;

get_compose_target(399) -> 400;

get_compose_target(400) -> 401;

get_compose_target(401) -> 402;

get_compose_target(402) -> 403;

get_compose_target(403) -> 404;

get_compose_target(404) -> 405;

get_compose_target(405) -> 0.


%%================================================
%% 宝石合成需要的个数：get_compose_num_by_level(Stone_level)->integer();	
get_compose_num_by_level(Stone_level)->
	if 
	Stone_level >= 7 -> 3;
	true-> 4
end.

%%================================================
%% 宝石合成消耗：get_compose_silver_by_level(Cfg_item_id,Stone_level)->integer;
get_compose_silver_by_level(92,1) -> 2000;

get_compose_silver_by_level(93,2) -> 5000;

get_compose_silver_by_level(94,3) -> 11000;

get_compose_silver_by_level(95,4) -> 25000;

get_compose_silver_by_level(96,5) -> 40000;

get_compose_silver_by_level(97,6) -> 60000;

get_compose_silver_by_level(98,7) -> 70000;

get_compose_silver_by_level(99,8) -> 80000;

get_compose_silver_by_level(100,9) -> 100000;

get_compose_silver_by_level(101,10) -> 0;

get_compose_silver_by_level(102,1) -> 2000;

get_compose_silver_by_level(103,2) -> 5000;

get_compose_silver_by_level(104,3) -> 11000;

get_compose_silver_by_level(105,4) -> 25000;

get_compose_silver_by_level(106,5) -> 40000;

get_compose_silver_by_level(107,6) -> 60000;

get_compose_silver_by_level(108,7) -> 70000;

get_compose_silver_by_level(109,8) -> 80000;

get_compose_silver_by_level(110,9) -> 100000;

get_compose_silver_by_level(111,10) -> 0;

get_compose_silver_by_level(112,1) -> 2000;

get_compose_silver_by_level(113,2) -> 5000;

get_compose_silver_by_level(114,3) -> 11000;

get_compose_silver_by_level(115,4) -> 25000;

get_compose_silver_by_level(116,5) -> 40000;

get_compose_silver_by_level(117,6) -> 60000;

get_compose_silver_by_level(118,7) -> 70000;

get_compose_silver_by_level(119,8) -> 80000;

get_compose_silver_by_level(120,9) -> 100000;

get_compose_silver_by_level(121,10) -> 0;

get_compose_silver_by_level(122,1) -> 2000;

get_compose_silver_by_level(123,2) -> 5000;

get_compose_silver_by_level(124,3) -> 11000;

get_compose_silver_by_level(125,4) -> 25000;

get_compose_silver_by_level(126,5) -> 40000;

get_compose_silver_by_level(127,6) -> 60000;

get_compose_silver_by_level(128,7) -> 70000;

get_compose_silver_by_level(129,8) -> 80000;

get_compose_silver_by_level(130,9) -> 100000;

get_compose_silver_by_level(131,10) -> 0;

get_compose_silver_by_level(132,1) -> 2000;

get_compose_silver_by_level(133,2) -> 5000;

get_compose_silver_by_level(134,3) -> 11000;

get_compose_silver_by_level(135,4) -> 25000;

get_compose_silver_by_level(136,5) -> 40000;

get_compose_silver_by_level(137,6) -> 60000;

get_compose_silver_by_level(138,7) -> 70000;

get_compose_silver_by_level(139,8) -> 80000;

get_compose_silver_by_level(140,9) -> 100000;

get_compose_silver_by_level(141,10) -> 0;

get_compose_silver_by_level(142,1) -> 2000;

get_compose_silver_by_level(143,2) -> 5000;

get_compose_silver_by_level(144,3) -> 11000;

get_compose_silver_by_level(145,4) -> 25000;

get_compose_silver_by_level(146,5) -> 40000;

get_compose_silver_by_level(147,6) -> 60000;

get_compose_silver_by_level(148,7) -> 70000;

get_compose_silver_by_level(149,8) -> 80000;

get_compose_silver_by_level(150,9) -> 100000;

get_compose_silver_by_level(151,10) -> 0;

get_compose_silver_by_level(152,1) -> 2000;

get_compose_silver_by_level(153,2) -> 5000;

get_compose_silver_by_level(154,3) -> 11000;

get_compose_silver_by_level(155,4) -> 25000;

get_compose_silver_by_level(156,5) -> 40000;

get_compose_silver_by_level(157,6) -> 60000;

get_compose_silver_by_level(158,7) -> 70000;

get_compose_silver_by_level(159,8) -> 80000;

get_compose_silver_by_level(160,9) -> 100000;

get_compose_silver_by_level(161,10) -> 0;

get_compose_silver_by_level(162,1) -> 2000;

get_compose_silver_by_level(163,2) -> 5000;

get_compose_silver_by_level(164,3) -> 11000;

get_compose_silver_by_level(165,4) -> 25000;

get_compose_silver_by_level(166,5) -> 40000;

get_compose_silver_by_level(167,6) -> 60000;

get_compose_silver_by_level(168,7) -> 70000;

get_compose_silver_by_level(169,8) -> 80000;

get_compose_silver_by_level(170,9) -> 100000;

get_compose_silver_by_level(171,10) -> 0;

get_compose_silver_by_level(172,1) -> 2000;

get_compose_silver_by_level(173,2) -> 5000;

get_compose_silver_by_level(174,3) -> 11000;

get_compose_silver_by_level(175,4) -> 25000;

get_compose_silver_by_level(176,5) -> 40000;

get_compose_silver_by_level(177,6) -> 60000;

get_compose_silver_by_level(178,7) -> 70000;

get_compose_silver_by_level(179,8) -> 80000;

get_compose_silver_by_level(180,9) -> 100000;

get_compose_silver_by_level(181,10) -> 0;

get_compose_silver_by_level(316,1) -> 2000;

get_compose_silver_by_level(317,2) -> 5000;

get_compose_silver_by_level(318,3) -> 11000;

get_compose_silver_by_level(319,4) -> 25000;

get_compose_silver_by_level(320,5) -> 40000;

get_compose_silver_by_level(321,6) -> 60000;

get_compose_silver_by_level(322,7) -> 70000;

get_compose_silver_by_level(323,8) -> 80000;

get_compose_silver_by_level(324,9) -> 100000;

get_compose_silver_by_level(325,10) -> 0;

get_compose_silver_by_level(326,1) -> 2000;

get_compose_silver_by_level(327,2) -> 5000;

get_compose_silver_by_level(328,3) -> 11000;

get_compose_silver_by_level(329,4) -> 25000;

get_compose_silver_by_level(330,5) -> 40000;

get_compose_silver_by_level(331,6) -> 60000;

get_compose_silver_by_level(332,7) -> 70000;

get_compose_silver_by_level(333,8) -> 80000;

get_compose_silver_by_level(334,9) -> 100000;

get_compose_silver_by_level(335,10) -> 0;

get_compose_silver_by_level(336,1) -> 2000;

get_compose_silver_by_level(337,2) -> 5000;

get_compose_silver_by_level(338,3) -> 11000;

get_compose_silver_by_level(339,4) -> 25000;

get_compose_silver_by_level(340,5) -> 40000;

get_compose_silver_by_level(341,6) -> 60000;

get_compose_silver_by_level(342,7) -> 70000;

get_compose_silver_by_level(343,8) -> 80000;

get_compose_silver_by_level(344,9) -> 100000;

get_compose_silver_by_level(345,10) -> 0;

get_compose_silver_by_level(346,1) -> 2000;

get_compose_silver_by_level(347,2) -> 5000;

get_compose_silver_by_level(348,3) -> 11000;

get_compose_silver_by_level(349,4) -> 25000;

get_compose_silver_by_level(350,5) -> 40000;

get_compose_silver_by_level(351,6) -> 60000;

get_compose_silver_by_level(352,7) -> 70000;

get_compose_silver_by_level(353,8) -> 80000;

get_compose_silver_by_level(354,9) -> 100000;

get_compose_silver_by_level(355,10) -> 0;

get_compose_silver_by_level(356,1) -> 2000;

get_compose_silver_by_level(357,2) -> 5000;

get_compose_silver_by_level(358,3) -> 11000;

get_compose_silver_by_level(359,4) -> 25000;

get_compose_silver_by_level(360,5) -> 40000;

get_compose_silver_by_level(361,6) -> 60000;

get_compose_silver_by_level(362,7) -> 70000;

get_compose_silver_by_level(363,8) -> 80000;

get_compose_silver_by_level(364,9) -> 100000;

get_compose_silver_by_level(365,10) -> 0;

get_compose_silver_by_level(366,1) -> 2000;

get_compose_silver_by_level(367,2) -> 5000;

get_compose_silver_by_level(368,3) -> 11000;

get_compose_silver_by_level(369,4) -> 25000;

get_compose_silver_by_level(370,5) -> 40000;

get_compose_silver_by_level(371,6) -> 60000;

get_compose_silver_by_level(372,7) -> 70000;

get_compose_silver_by_level(373,8) -> 80000;

get_compose_silver_by_level(374,9) -> 100000;

get_compose_silver_by_level(375,10) -> 0;

get_compose_silver_by_level(376,1) -> 2000;

get_compose_silver_by_level(377,2) -> 5000;

get_compose_silver_by_level(378,3) -> 11000;

get_compose_silver_by_level(379,4) -> 25000;

get_compose_silver_by_level(380,5) -> 40000;

get_compose_silver_by_level(381,6) -> 60000;

get_compose_silver_by_level(382,7) -> 70000;

get_compose_silver_by_level(383,8) -> 80000;

get_compose_silver_by_level(384,9) -> 100000;

get_compose_silver_by_level(385,10) -> 0;

get_compose_silver_by_level(386,1) -> 2000;

get_compose_silver_by_level(387,2) -> 5000;

get_compose_silver_by_level(388,3) -> 11000;

get_compose_silver_by_level(389,4) -> 25000;

get_compose_silver_by_level(390,5) -> 40000;

get_compose_silver_by_level(391,6) -> 60000;

get_compose_silver_by_level(392,7) -> 70000;

get_compose_silver_by_level(393,8) -> 80000;

get_compose_silver_by_level(394,9) -> 100000;

get_compose_silver_by_level(395,10) -> 0;

get_compose_silver_by_level(396,1) -> 2000;

get_compose_silver_by_level(397,2) -> 5000;

get_compose_silver_by_level(398,3) -> 11000;

get_compose_silver_by_level(399,4) -> 25000;

get_compose_silver_by_level(400,5) -> 40000;

get_compose_silver_by_level(401,6) -> 60000;

get_compose_silver_by_level(402,7) -> 70000;

get_compose_silver_by_level(403,8) -> 80000;

get_compose_silver_by_level(404,9) -> 100000;

get_compose_silver_by_level(405,10) -> 0.


%%================================================
%% 宝石转化费用：get_convert_silver_by_level(Cfg_item_id,_Stone_level)->integer;
get_convert_silver_by_level(92,1) -> 700;

get_convert_silver_by_level(93,2) -> 2300;

get_convert_silver_by_level(94,3) -> 3500;

get_convert_silver_by_level(95,4) -> 8400;

get_convert_silver_by_level(96,5) -> 15700;

get_convert_silver_by_level(97,6) -> 28300;

get_convert_silver_by_level(98,7) -> 56600;

get_convert_silver_by_level(99,8) -> 76500;

get_convert_silver_by_level(100,9) -> 203900;

get_convert_silver_by_level(101,10) -> 458800;

get_convert_silver_by_level(102,1) -> 700;

get_convert_silver_by_level(103,2) -> 2300;

get_convert_silver_by_level(104,3) -> 3500;

get_convert_silver_by_level(105,4) -> 8400;

get_convert_silver_by_level(106,5) -> 15700;

get_convert_silver_by_level(107,6) -> 28300;

get_convert_silver_by_level(108,7) -> 56600;

get_convert_silver_by_level(109,8) -> 76500;

get_convert_silver_by_level(110,9) -> 203900;

get_convert_silver_by_level(111,10) -> 458800;

get_convert_silver_by_level(112,1) -> 700;

get_convert_silver_by_level(113,2) -> 2300;

get_convert_silver_by_level(114,3) -> 3500;

get_convert_silver_by_level(115,4) -> 8400;

get_convert_silver_by_level(116,5) -> 15700;

get_convert_silver_by_level(117,6) -> 28300;

get_convert_silver_by_level(118,7) -> 56600;

get_convert_silver_by_level(119,8) -> 76500;

get_convert_silver_by_level(120,9) -> 203900;

get_convert_silver_by_level(121,10) -> 458800;

get_convert_silver_by_level(122,1) -> 700;

get_convert_silver_by_level(123,2) -> 2300;

get_convert_silver_by_level(124,3) -> 3500;

get_convert_silver_by_level(125,4) -> 8400;

get_convert_silver_by_level(126,5) -> 15700;

get_convert_silver_by_level(127,6) -> 28300;

get_convert_silver_by_level(128,7) -> 56600;

get_convert_silver_by_level(129,8) -> 76500;

get_convert_silver_by_level(130,9) -> 203900;

get_convert_silver_by_level(131,10) -> 458800;

get_convert_silver_by_level(132,1) -> 700;

get_convert_silver_by_level(133,2) -> 2300;

get_convert_silver_by_level(134,3) -> 3500;

get_convert_silver_by_level(135,4) -> 8400;

get_convert_silver_by_level(136,5) -> 15700;

get_convert_silver_by_level(137,6) -> 28300;

get_convert_silver_by_level(138,7) -> 56600;

get_convert_silver_by_level(139,8) -> 76500;

get_convert_silver_by_level(140,9) -> 203900;

get_convert_silver_by_level(141,10) -> 458800;

get_convert_silver_by_level(142,1) -> 700;

get_convert_silver_by_level(143,2) -> 2300;

get_convert_silver_by_level(144,3) -> 3500;

get_convert_silver_by_level(145,4) -> 8400;

get_convert_silver_by_level(146,5) -> 15700;

get_convert_silver_by_level(147,6) -> 28300;

get_convert_silver_by_level(148,7) -> 56600;

get_convert_silver_by_level(149,8) -> 76500;

get_convert_silver_by_level(150,9) -> 203900;

get_convert_silver_by_level(151,10) -> 458800;

get_convert_silver_by_level(152,1) -> 700;

get_convert_silver_by_level(153,2) -> 2300;

get_convert_silver_by_level(154,3) -> 3500;

get_convert_silver_by_level(155,4) -> 8400;

get_convert_silver_by_level(156,5) -> 15700;

get_convert_silver_by_level(157,6) -> 28300;

get_convert_silver_by_level(158,7) -> 56600;

get_convert_silver_by_level(159,8) -> 76500;

get_convert_silver_by_level(160,9) -> 203900;

get_convert_silver_by_level(161,10) -> 458800;

get_convert_silver_by_level(162,1) -> 700;

get_convert_silver_by_level(163,2) -> 2300;

get_convert_silver_by_level(164,3) -> 3500;

get_convert_silver_by_level(165,4) -> 8400;

get_convert_silver_by_level(166,5) -> 15700;

get_convert_silver_by_level(167,6) -> 28300;

get_convert_silver_by_level(168,7) -> 56600;

get_convert_silver_by_level(169,8) -> 76500;

get_convert_silver_by_level(170,9) -> 203900;

get_convert_silver_by_level(171,10) -> 458800;

get_convert_silver_by_level(172,1) -> 700;

get_convert_silver_by_level(173,2) -> 2300;

get_convert_silver_by_level(174,3) -> 3500;

get_convert_silver_by_level(175,4) -> 8400;

get_convert_silver_by_level(176,5) -> 15700;

get_convert_silver_by_level(177,6) -> 28300;

get_convert_silver_by_level(178,7) -> 56600;

get_convert_silver_by_level(179,8) -> 76500;

get_convert_silver_by_level(180,9) -> 203900;

get_convert_silver_by_level(181,10) -> 458800;

get_convert_silver_by_level(316,1) -> 1050;

get_convert_silver_by_level(317,2) -> 3450;

get_convert_silver_by_level(318,3) -> 5250;

get_convert_silver_by_level(319,4) -> 12600;

get_convert_silver_by_level(320,5) -> 23550;

get_convert_silver_by_level(321,6) -> 42450;

get_convert_silver_by_level(322,7) -> 84900;

get_convert_silver_by_level(323,8) -> 114750;

get_convert_silver_by_level(324,9) -> 305850;

get_convert_silver_by_level(325,10) -> 688200;

get_convert_silver_by_level(326,1) -> 1050;

get_convert_silver_by_level(327,2) -> 3450;

get_convert_silver_by_level(328,3) -> 5250;

get_convert_silver_by_level(329,4) -> 12600;

get_convert_silver_by_level(330,5) -> 23550;

get_convert_silver_by_level(331,6) -> 42450;

get_convert_silver_by_level(332,7) -> 84900;

get_convert_silver_by_level(333,8) -> 114750;

get_convert_silver_by_level(334,9) -> 305850;

get_convert_silver_by_level(335,10) -> 688200;

get_convert_silver_by_level(336,1) -> 1050;

get_convert_silver_by_level(337,2) -> 3450;

get_convert_silver_by_level(338,3) -> 5250;

get_convert_silver_by_level(339,4) -> 12600;

get_convert_silver_by_level(340,5) -> 23550;

get_convert_silver_by_level(341,6) -> 42450;

get_convert_silver_by_level(342,7) -> 84900;

get_convert_silver_by_level(343,8) -> 114750;

get_convert_silver_by_level(344,9) -> 305850;

get_convert_silver_by_level(345,10) -> 688200;

get_convert_silver_by_level(346,1) -> 1050;

get_convert_silver_by_level(347,2) -> 3450;

get_convert_silver_by_level(348,3) -> 5250;

get_convert_silver_by_level(349,4) -> 12600;

get_convert_silver_by_level(350,5) -> 23550;

get_convert_silver_by_level(351,6) -> 42450;

get_convert_silver_by_level(352,7) -> 84900;

get_convert_silver_by_level(353,8) -> 114750;

get_convert_silver_by_level(354,9) -> 305850;

get_convert_silver_by_level(355,10) -> 688200;

get_convert_silver_by_level(356,1) -> 1050;

get_convert_silver_by_level(357,2) -> 3450;

get_convert_silver_by_level(358,3) -> 5250;

get_convert_silver_by_level(359,4) -> 12600;

get_convert_silver_by_level(360,5) -> 23550;

get_convert_silver_by_level(361,6) -> 42450;

get_convert_silver_by_level(362,7) -> 84900;

get_convert_silver_by_level(363,8) -> 114750;

get_convert_silver_by_level(364,9) -> 305850;

get_convert_silver_by_level(365,10) -> 688200;

get_convert_silver_by_level(366,1) -> 1050;

get_convert_silver_by_level(367,2) -> 3450;

get_convert_silver_by_level(368,3) -> 5250;

get_convert_silver_by_level(369,4) -> 12600;

get_convert_silver_by_level(370,5) -> 23550;

get_convert_silver_by_level(371,6) -> 42450;

get_convert_silver_by_level(372,7) -> 84900;

get_convert_silver_by_level(373,8) -> 114750;

get_convert_silver_by_level(374,9) -> 305850;

get_convert_silver_by_level(375,10) -> 688200;

get_convert_silver_by_level(376,1) -> 1050;

get_convert_silver_by_level(377,2) -> 3450;

get_convert_silver_by_level(378,3) -> 5250;

get_convert_silver_by_level(379,4) -> 12600;

get_convert_silver_by_level(380,5) -> 23550;

get_convert_silver_by_level(381,6) -> 42450;

get_convert_silver_by_level(382,7) -> 84900;

get_convert_silver_by_level(383,8) -> 114750;

get_convert_silver_by_level(384,9) -> 305850;

get_convert_silver_by_level(385,10) -> 688200;

get_convert_silver_by_level(386,1) -> 1050;

get_convert_silver_by_level(387,2) -> 3450;

get_convert_silver_by_level(388,3) -> 5250;

get_convert_silver_by_level(389,4) -> 12600;

get_convert_silver_by_level(390,5) -> 23550;

get_convert_silver_by_level(391,6) -> 42450;

get_convert_silver_by_level(392,7) -> 84900;

get_convert_silver_by_level(393,8) -> 114750;

get_convert_silver_by_level(394,9) -> 305850;

get_convert_silver_by_level(395,10) -> 688200;

get_convert_silver_by_level(396,1) -> 1050;

get_convert_silver_by_level(397,2) -> 3450;

get_convert_silver_by_level(398,3) -> 5250;

get_convert_silver_by_level(399,4) -> 12600;

get_convert_silver_by_level(400,5) -> 23550;

get_convert_silver_by_level(401,6) -> 42450;

get_convert_silver_by_level(402,7) -> 84900;

get_convert_silver_by_level(403,8) -> 114750;

get_convert_silver_by_level(404,9) -> 305850;

get_convert_silver_by_level(405,10) -> 688200.


%%================================================
%% 宝石雕刻材料：get_carve_material(宝石ID)-> 材料;
get_carve_material(92) -> 306;

get_carve_material(93) -> 307;

get_carve_material(94) -> 308;

get_carve_material(95) -> 309;

get_carve_material(96) -> 310;

get_carve_material(97) -> 311;

get_carve_material(98) -> 312;

get_carve_material(99) -> 313;

get_carve_material(100) -> 314;

get_carve_material(101) -> 315;

get_carve_material(102) -> 306;

get_carve_material(103) -> 307;

get_carve_material(104) -> 308;

get_carve_material(105) -> 309;

get_carve_material(106) -> 310;

get_carve_material(107) -> 311;

get_carve_material(108) -> 312;

get_carve_material(109) -> 313;

get_carve_material(110) -> 314;

get_carve_material(111) -> 315;

get_carve_material(112) -> 306;

get_carve_material(113) -> 307;

get_carve_material(114) -> 308;

get_carve_material(115) -> 309;

get_carve_material(116) -> 310;

get_carve_material(117) -> 311;

get_carve_material(118) -> 312;

get_carve_material(119) -> 313;

get_carve_material(120) -> 314;

get_carve_material(121) -> 315;

get_carve_material(122) -> 306;

get_carve_material(123) -> 307;

get_carve_material(124) -> 308;

get_carve_material(125) -> 309;

get_carve_material(126) -> 310;

get_carve_material(127) -> 311;

get_carve_material(128) -> 312;

get_carve_material(129) -> 313;

get_carve_material(130) -> 314;

get_carve_material(131) -> 315;

get_carve_material(132) -> 306;

get_carve_material(133) -> 307;

get_carve_material(134) -> 308;

get_carve_material(135) -> 309;

get_carve_material(136) -> 310;

get_carve_material(137) -> 311;

get_carve_material(138) -> 312;

get_carve_material(139) -> 313;

get_carve_material(140) -> 314;

get_carve_material(141) -> 315;

get_carve_material(142) -> 306;

get_carve_material(143) -> 307;

get_carve_material(144) -> 308;

get_carve_material(145) -> 309;

get_carve_material(146) -> 310;

get_carve_material(147) -> 311;

get_carve_material(148) -> 312;

get_carve_material(149) -> 313;

get_carve_material(150) -> 314;

get_carve_material(151) -> 315;

get_carve_material(152) -> 306;

get_carve_material(153) -> 307;

get_carve_material(154) -> 308;

get_carve_material(155) -> 309;

get_carve_material(156) -> 310;

get_carve_material(157) -> 311;

get_carve_material(158) -> 312;

get_carve_material(159) -> 313;

get_carve_material(160) -> 314;

get_carve_material(161) -> 315;

get_carve_material(162) -> 306;

get_carve_material(163) -> 307;

get_carve_material(164) -> 308;

get_carve_material(165) -> 309;

get_carve_material(166) -> 310;

get_carve_material(167) -> 311;

get_carve_material(168) -> 312;

get_carve_material(169) -> 313;

get_carve_material(170) -> 314;

get_carve_material(171) -> 315;

get_carve_material(172) -> 306;

get_carve_material(173) -> 307;

get_carve_material(174) -> 308;

get_carve_material(175) -> 309;

get_carve_material(176) -> 310;

get_carve_material(177) -> 311;

get_carve_material(178) -> 312;

get_carve_material(179) -> 313;

get_carve_material(180) -> 314;

get_carve_material(181) -> 315;

get_carve_material(316) -> 0;

get_carve_material(317) -> 0;

get_carve_material(318) -> 0;

get_carve_material(319) -> 0;

get_carve_material(320) -> 0;

get_carve_material(321) -> 0;

get_carve_material(322) -> 0;

get_carve_material(323) -> 0;

get_carve_material(324) -> 0;

get_carve_material(325) -> 0;

get_carve_material(326) -> 0;

get_carve_material(327) -> 0;

get_carve_material(328) -> 0;

get_carve_material(329) -> 0;

get_carve_material(330) -> 0;

get_carve_material(331) -> 0;

get_carve_material(332) -> 0;

get_carve_material(333) -> 0;

get_carve_material(334) -> 0;

get_carve_material(335) -> 0;

get_carve_material(336) -> 0;

get_carve_material(337) -> 0;

get_carve_material(338) -> 0;

get_carve_material(339) -> 0;

get_carve_material(340) -> 0;

get_carve_material(341) -> 0;

get_carve_material(342) -> 0;

get_carve_material(343) -> 0;

get_carve_material(344) -> 0;

get_carve_material(345) -> 0;

get_carve_material(346) -> 0;

get_carve_material(347) -> 0;

get_carve_material(348) -> 0;

get_carve_material(349) -> 0;

get_carve_material(350) -> 0;

get_carve_material(351) -> 0;

get_carve_material(352) -> 0;

get_carve_material(353) -> 0;

get_carve_material(354) -> 0;

get_carve_material(355) -> 0;

get_carve_material(356) -> 0;

get_carve_material(357) -> 0;

get_carve_material(358) -> 0;

get_carve_material(359) -> 0;

get_carve_material(360) -> 0;

get_carve_material(361) -> 0;

get_carve_material(362) -> 0;

get_carve_material(363) -> 0;

get_carve_material(364) -> 0;

get_carve_material(365) -> 0;

get_carve_material(366) -> 0;

get_carve_material(367) -> 0;

get_carve_material(368) -> 0;

get_carve_material(369) -> 0;

get_carve_material(370) -> 0;

get_carve_material(371) -> 0;

get_carve_material(372) -> 0;

get_carve_material(373) -> 0;

get_carve_material(374) -> 0;

get_carve_material(375) -> 0;

get_carve_material(376) -> 0;

get_carve_material(377) -> 0;

get_carve_material(378) -> 0;

get_carve_material(379) -> 0;

get_carve_material(380) -> 0;

get_carve_material(381) -> 0;

get_carve_material(382) -> 0;

get_carve_material(383) -> 0;

get_carve_material(384) -> 0;

get_carve_material(385) -> 0;

get_carve_material(386) -> 0;

get_carve_material(387) -> 0;

get_carve_material(388) -> 0;

get_carve_material(389) -> 0;

get_carve_material(390) -> 0;

get_carve_material(391) -> 0;

get_carve_material(392) -> 0;

get_carve_material(393) -> 0;

get_carve_material(394) -> 0;

get_carve_material(395) -> 0;

get_carve_material(396) -> 0;

get_carve_material(397) -> 0;

get_carve_material(398) -> 0;

get_carve_material(399) -> 0;

get_carve_material(400) -> 0;

get_carve_material(401) -> 0;

get_carve_material(402) -> 0;

get_carve_material(403) -> 0;

get_carve_material(404) -> 0;

get_carve_material(405) -> 0.


%%================================================
%% 宝石雕刻费用：get_carve_silver_by_level(Cfg_iten_id,_Stone_level)->integer;
get_carve_silver_by_level(92,1) -> 8000;

get_carve_silver_by_level(93,2) -> 16000;

get_carve_silver_by_level(94,3) -> 32000;

get_carve_silver_by_level(95,4) -> 68000;

get_carve_silver_by_level(96,5) -> 130000;

get_carve_silver_by_level(97,6) -> 200000;

get_carve_silver_by_level(98,7) -> 360000;

get_carve_silver_by_level(99,8) -> 600000;

get_carve_silver_by_level(100,9) -> 800000;

get_carve_silver_by_level(101,10) -> 1000000;

get_carve_silver_by_level(102,1) -> 8000;

get_carve_silver_by_level(103,2) -> 16000;

get_carve_silver_by_level(104,3) -> 32000;

get_carve_silver_by_level(105,4) -> 68000;

get_carve_silver_by_level(106,5) -> 130000;

get_carve_silver_by_level(107,6) -> 200000;

get_carve_silver_by_level(108,7) -> 360000;

get_carve_silver_by_level(109,8) -> 600000;

get_carve_silver_by_level(110,9) -> 800000;

get_carve_silver_by_level(111,10) -> 1000000;

get_carve_silver_by_level(112,1) -> 8000;

get_carve_silver_by_level(113,2) -> 16000;

get_carve_silver_by_level(114,3) -> 32000;

get_carve_silver_by_level(115,4) -> 68000;

get_carve_silver_by_level(116,5) -> 130000;

get_carve_silver_by_level(117,6) -> 200000;

get_carve_silver_by_level(118,7) -> 360000;

get_carve_silver_by_level(119,8) -> 600000;

get_carve_silver_by_level(120,9) -> 800000;

get_carve_silver_by_level(121,10) -> 1000000;

get_carve_silver_by_level(122,1) -> 8000;

get_carve_silver_by_level(123,2) -> 16000;

get_carve_silver_by_level(124,3) -> 32000;

get_carve_silver_by_level(125,4) -> 68000;

get_carve_silver_by_level(126,5) -> 130000;

get_carve_silver_by_level(127,6) -> 200000;

get_carve_silver_by_level(128,7) -> 360000;

get_carve_silver_by_level(129,8) -> 600000;

get_carve_silver_by_level(130,9) -> 800000;

get_carve_silver_by_level(131,10) -> 1000000;

get_carve_silver_by_level(132,1) -> 8000;

get_carve_silver_by_level(133,2) -> 16000;

get_carve_silver_by_level(134,3) -> 32000;

get_carve_silver_by_level(135,4) -> 68000;

get_carve_silver_by_level(136,5) -> 130000;

get_carve_silver_by_level(137,6) -> 200000;

get_carve_silver_by_level(138,7) -> 360000;

get_carve_silver_by_level(139,8) -> 600000;

get_carve_silver_by_level(140,9) -> 800000;

get_carve_silver_by_level(141,10) -> 1000000;

get_carve_silver_by_level(142,1) -> 8000;

get_carve_silver_by_level(143,2) -> 16000;

get_carve_silver_by_level(144,3) -> 32000;

get_carve_silver_by_level(145,4) -> 68000;

get_carve_silver_by_level(146,5) -> 130000;

get_carve_silver_by_level(147,6) -> 200000;

get_carve_silver_by_level(148,7) -> 360000;

get_carve_silver_by_level(149,8) -> 600000;

get_carve_silver_by_level(150,9) -> 800000;

get_carve_silver_by_level(151,10) -> 1000000;

get_carve_silver_by_level(152,1) -> 8000;

get_carve_silver_by_level(153,2) -> 16000;

get_carve_silver_by_level(154,3) -> 32000;

get_carve_silver_by_level(155,4) -> 68000;

get_carve_silver_by_level(156,5) -> 130000;

get_carve_silver_by_level(157,6) -> 200000;

get_carve_silver_by_level(158,7) -> 360000;

get_carve_silver_by_level(159,8) -> 600000;

get_carve_silver_by_level(160,9) -> 800000;

get_carve_silver_by_level(161,10) -> 1000000;

get_carve_silver_by_level(162,1) -> 8000;

get_carve_silver_by_level(163,2) -> 16000;

get_carve_silver_by_level(164,3) -> 32000;

get_carve_silver_by_level(165,4) -> 68000;

get_carve_silver_by_level(166,5) -> 130000;

get_carve_silver_by_level(167,6) -> 200000;

get_carve_silver_by_level(168,7) -> 360000;

get_carve_silver_by_level(169,8) -> 600000;

get_carve_silver_by_level(170,9) -> 800000;

get_carve_silver_by_level(171,10) -> 1000000;

get_carve_silver_by_level(172,1) -> 8000;

get_carve_silver_by_level(173,2) -> 16000;

get_carve_silver_by_level(174,3) -> 32000;

get_carve_silver_by_level(175,4) -> 68000;

get_carve_silver_by_level(176,5) -> 130000;

get_carve_silver_by_level(177,6) -> 200000;

get_carve_silver_by_level(178,7) -> 360000;

get_carve_silver_by_level(179,8) -> 600000;

get_carve_silver_by_level(180,9) -> 800000;

get_carve_silver_by_level(181,10) -> 1000000;

get_carve_silver_by_level(316,1) -> 0;

get_carve_silver_by_level(317,2) -> 0;

get_carve_silver_by_level(318,3) -> 0;

get_carve_silver_by_level(319,4) -> 0;

get_carve_silver_by_level(320,5) -> 0;

get_carve_silver_by_level(321,6) -> 0;

get_carve_silver_by_level(322,7) -> 0;

get_carve_silver_by_level(323,8) -> 0;

get_carve_silver_by_level(324,9) -> 0;

get_carve_silver_by_level(325,10) -> 0;

get_carve_silver_by_level(326,1) -> 0;

get_carve_silver_by_level(327,2) -> 0;

get_carve_silver_by_level(328,3) -> 0;

get_carve_silver_by_level(329,4) -> 0;

get_carve_silver_by_level(330,5) -> 0;

get_carve_silver_by_level(331,6) -> 0;

get_carve_silver_by_level(332,7) -> 0;

get_carve_silver_by_level(333,8) -> 0;

get_carve_silver_by_level(334,9) -> 0;

get_carve_silver_by_level(335,10) -> 0;

get_carve_silver_by_level(336,1) -> 0;

get_carve_silver_by_level(337,2) -> 0;

get_carve_silver_by_level(338,3) -> 0;

get_carve_silver_by_level(339,4) -> 0;

get_carve_silver_by_level(340,5) -> 0;

get_carve_silver_by_level(341,6) -> 0;

get_carve_silver_by_level(342,7) -> 0;

get_carve_silver_by_level(343,8) -> 0;

get_carve_silver_by_level(344,9) -> 0;

get_carve_silver_by_level(345,10) -> 0;

get_carve_silver_by_level(346,1) -> 0;

get_carve_silver_by_level(347,2) -> 0;

get_carve_silver_by_level(348,3) -> 0;

get_carve_silver_by_level(349,4) -> 0;

get_carve_silver_by_level(350,5) -> 0;

get_carve_silver_by_level(351,6) -> 0;

get_carve_silver_by_level(352,7) -> 0;

get_carve_silver_by_level(353,8) -> 0;

get_carve_silver_by_level(354,9) -> 0;

get_carve_silver_by_level(355,10) -> 0;

get_carve_silver_by_level(356,1) -> 0;

get_carve_silver_by_level(357,2) -> 0;

get_carve_silver_by_level(358,3) -> 0;

get_carve_silver_by_level(359,4) -> 0;

get_carve_silver_by_level(360,5) -> 0;

get_carve_silver_by_level(361,6) -> 0;

get_carve_silver_by_level(362,7) -> 0;

get_carve_silver_by_level(363,8) -> 0;

get_carve_silver_by_level(364,9) -> 0;

get_carve_silver_by_level(365,10) -> 0;

get_carve_silver_by_level(366,1) -> 0;

get_carve_silver_by_level(367,2) -> 0;

get_carve_silver_by_level(368,3) -> 0;

get_carve_silver_by_level(369,4) -> 0;

get_carve_silver_by_level(370,5) -> 0;

get_carve_silver_by_level(371,6) -> 0;

get_carve_silver_by_level(372,7) -> 0;

get_carve_silver_by_level(373,8) -> 0;

get_carve_silver_by_level(374,9) -> 0;

get_carve_silver_by_level(375,10) -> 0;

get_carve_silver_by_level(376,1) -> 0;

get_carve_silver_by_level(377,2) -> 0;

get_carve_silver_by_level(378,3) -> 0;

get_carve_silver_by_level(379,4) -> 0;

get_carve_silver_by_level(380,5) -> 0;

get_carve_silver_by_level(381,6) -> 0;

get_carve_silver_by_level(382,7) -> 0;

get_carve_silver_by_level(383,8) -> 0;

get_carve_silver_by_level(384,9) -> 0;

get_carve_silver_by_level(385,10) -> 0;

get_carve_silver_by_level(386,1) -> 0;

get_carve_silver_by_level(387,2) -> 0;

get_carve_silver_by_level(388,3) -> 0;

get_carve_silver_by_level(389,4) -> 0;

get_carve_silver_by_level(390,5) -> 0;

get_carve_silver_by_level(391,6) -> 0;

get_carve_silver_by_level(392,7) -> 0;

get_carve_silver_by_level(393,8) -> 0;

get_carve_silver_by_level(394,9) -> 0;

get_carve_silver_by_level(395,10) -> 0;

get_carve_silver_by_level(396,1) -> 0;

get_carve_silver_by_level(397,2) -> 0;

get_carve_silver_by_level(398,3) -> 0;

get_carve_silver_by_level(399,4) -> 0;

get_carve_silver_by_level(400,5) -> 0;

get_carve_silver_by_level(401,6) -> 0;

get_carve_silver_by_level(402,7) -> 0;

get_carve_silver_by_level(403,8) -> 0;

get_carve_silver_by_level(404,9) -> 0;

get_carve_silver_by_level(405,10) -> 0.


%%================================================
%% get宝石雕刻目标ID：get_carve_target(Cfg_iten_id)->Target_id;
get_carve_target(92) -> 316;

get_carve_target(93) -> 317;

get_carve_target(94) -> 318;

get_carve_target(95) -> 319;

get_carve_target(96) -> 320;

get_carve_target(97) -> 321;

get_carve_target(98) -> 322;

get_carve_target(99) -> 323;

get_carve_target(100) -> 324;

get_carve_target(101) -> 325;

get_carve_target(102) -> 326;

get_carve_target(103) -> 327;

get_carve_target(104) -> 328;

get_carve_target(105) -> 329;

get_carve_target(106) -> 330;

get_carve_target(107) -> 331;

get_carve_target(108) -> 332;

get_carve_target(109) -> 333;

get_carve_target(110) -> 334;

get_carve_target(111) -> 335;

get_carve_target(112) -> 336;

get_carve_target(113) -> 337;

get_carve_target(114) -> 338;

get_carve_target(115) -> 339;

get_carve_target(116) -> 340;

get_carve_target(117) -> 341;

get_carve_target(118) -> 342;

get_carve_target(119) -> 343;

get_carve_target(120) -> 344;

get_carve_target(121) -> 345;

get_carve_target(122) -> 346;

get_carve_target(123) -> 347;

get_carve_target(124) -> 348;

get_carve_target(125) -> 349;

get_carve_target(126) -> 350;

get_carve_target(127) -> 351;

get_carve_target(128) -> 352;

get_carve_target(129) -> 353;

get_carve_target(130) -> 354;

get_carve_target(131) -> 355;

get_carve_target(132) -> 356;

get_carve_target(133) -> 357;

get_carve_target(134) -> 358;

get_carve_target(135) -> 359;

get_carve_target(136) -> 360;

get_carve_target(137) -> 361;

get_carve_target(138) -> 362;

get_carve_target(139) -> 363;

get_carve_target(140) -> 364;

get_carve_target(141) -> 365;

get_carve_target(142) -> 366;

get_carve_target(143) -> 367;

get_carve_target(144) -> 368;

get_carve_target(145) -> 369;

get_carve_target(146) -> 370;

get_carve_target(147) -> 371;

get_carve_target(148) -> 372;

get_carve_target(149) -> 373;

get_carve_target(150) -> 374;

get_carve_target(151) -> 375;

get_carve_target(152) -> 376;

get_carve_target(153) -> 377;

get_carve_target(154) -> 378;

get_carve_target(155) -> 379;

get_carve_target(156) -> 380;

get_carve_target(157) -> 381;

get_carve_target(158) -> 382;

get_carve_target(159) -> 383;

get_carve_target(160) -> 384;

get_carve_target(161) -> 385;

get_carve_target(162) -> 386;

get_carve_target(163) -> 387;

get_carve_target(164) -> 388;

get_carve_target(165) -> 389;

get_carve_target(166) -> 390;

get_carve_target(167) -> 391;

get_carve_target(168) -> 392;

get_carve_target(169) -> 393;

get_carve_target(170) -> 394;

get_carve_target(171) -> 395;

get_carve_target(172) -> 396;

get_carve_target(173) -> 397;

get_carve_target(174) -> 398;

get_carve_target(175) -> 399;

get_carve_target(176) -> 400;

get_carve_target(177) -> 401;

get_carve_target(178) -> 402;

get_carve_target(179) -> 403;

get_carve_target(180) -> 404;

get_carve_target(181) -> 405;

get_carve_target(316) -> 0;

get_carve_target(317) -> 0;

get_carve_target(318) -> 0;

get_carve_target(319) -> 0;

get_carve_target(320) -> 0;

get_carve_target(321) -> 0;

get_carve_target(322) -> 0;

get_carve_target(323) -> 0;

get_carve_target(324) -> 0;

get_carve_target(325) -> 0;

get_carve_target(326) -> 0;

get_carve_target(327) -> 0;

get_carve_target(328) -> 0;

get_carve_target(329) -> 0;

get_carve_target(330) -> 0;

get_carve_target(331) -> 0;

get_carve_target(332) -> 0;

get_carve_target(333) -> 0;

get_carve_target(334) -> 0;

get_carve_target(335) -> 0;

get_carve_target(336) -> 0;

get_carve_target(337) -> 0;

get_carve_target(338) -> 0;

get_carve_target(339) -> 0;

get_carve_target(340) -> 0;

get_carve_target(341) -> 0;

get_carve_target(342) -> 0;

get_carve_target(343) -> 0;

get_carve_target(344) -> 0;

get_carve_target(345) -> 0;

get_carve_target(346) -> 0;

get_carve_target(347) -> 0;

get_carve_target(348) -> 0;

get_carve_target(349) -> 0;

get_carve_target(350) -> 0;

get_carve_target(351) -> 0;

get_carve_target(352) -> 0;

get_carve_target(353) -> 0;

get_carve_target(354) -> 0;

get_carve_target(355) -> 0;

get_carve_target(356) -> 0;

get_carve_target(357) -> 0;

get_carve_target(358) -> 0;

get_carve_target(359) -> 0;

get_carve_target(360) -> 0;

get_carve_target(361) -> 0;

get_carve_target(362) -> 0;

get_carve_target(363) -> 0;

get_carve_target(364) -> 0;

get_carve_target(365) -> 0;

get_carve_target(366) -> 0;

get_carve_target(367) -> 0;

get_carve_target(368) -> 0;

get_carve_target(369) -> 0;

get_carve_target(370) -> 0;

get_carve_target(371) -> 0;

get_carve_target(372) -> 0;

get_carve_target(373) -> 0;

get_carve_target(374) -> 0;

get_carve_target(375) -> 0;

get_carve_target(376) -> 0;

get_carve_target(377) -> 0;

get_carve_target(378) -> 0;

get_carve_target(379) -> 0;

get_carve_target(380) -> 0;

get_carve_target(381) -> 0;

get_carve_target(382) -> 0;

get_carve_target(383) -> 0;

get_carve_target(384) -> 0;

get_carve_target(385) -> 0;

get_carve_target(386) -> 0;

get_carve_target(387) -> 0;

get_carve_target(388) -> 0;

get_carve_target(389) -> 0;

get_carve_target(390) -> 0;

get_carve_target(391) -> 0;

get_carve_target(392) -> 0;

get_carve_target(393) -> 0;

get_carve_target(394) -> 0;

get_carve_target(395) -> 0;

get_carve_target(396) -> 0;

get_carve_target(397) -> 0;

get_carve_target(398) -> 0;

get_carve_target(399) -> 0;

get_carve_target(400) -> 0;

get_carve_target(401) -> 0;

get_carve_target(402) -> 0;

get_carve_target(403) -> 0;

get_carve_target(404) -> 0;

get_carve_target(405) -> 0.


%%================================================
