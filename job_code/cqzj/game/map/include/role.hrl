
-record(role_first_level_attr, {
                                str=0, 
                                int=0, 
                                con=0, 
                                dex=0, 
                                men=0
                               }).

-record(role_second_level_attr, {
                                 max_hp=0,
                                 max_mp=0,
                                 max_hp_rate=0,
                                 max_mp_rate=0,
                                 phy_attack_rate=0,
                                 max_phy_attack=0, 
                                 min_phy_attack=0,
                                 max_magic_attack=0, 
                                 min_magic_attack=0,
                                 magic_attack_rate=0, 
                                 phy_defence=0, 
                                 phy_defence_rate=0,
                                 magic_defence=0,
                                 magic_defence_rate=0,
                                 hp_recover_speed=0,
                                 mp_recover_speed=0,
                                 luck=0,
                                 move_speed=0,
                                 move_speed_rate=0,
                                 attack_speed=0,
                                 attack_speed_rate=0,
                                 miss=0,
                                 no_defence=0,
                                 double_attack=0,
                                 phy_anti=0,
                                 magic_anti=0,
                                 phy_hurt_rate=0,
                                 magic_hurt_rate=0,
                                 dizzy=0,
                                 poisoning=0,
                                 freeze=0,
                                 poisoning_resist=0,
                                 dizzy_resist=0,
                                 freeze_resist=0,
                                 hurt = 0,
                                 hurt_rebound = 0,
                                 hit_rate = 0,
                                 block = 0,
                                 wreck = 0,
                                 tough = 0,
                                 vigour = 0,
                                 week = 0,
                                 molder = 0,
                                 hunger = 0,
                                 bless = 0,
                                 crit = 0,
                                 bloodline = 0
                                }).

-record(role_buff, {buffid, value, start_time, total_time}).

-record(buff, {buffid, type, effect}).

-record(p_level_exp, {level, exp}).



