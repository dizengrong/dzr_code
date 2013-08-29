%% Author: dizengrong@gmail.com
%% Created: 2011-8-19
%% Description: 场景
-module(pt_11).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([read/2, write/2, write_cell_other_data/2]).

%%=============================================================================
%% read
%%=============================================================================

%% player move
read(11000, <<Size:16, PosList/binary>>) ->
	{ok, read_pos_list(Size, PosList)};

%% clienet was in the scene and want to get other players in his view
read(11001, <<SceneId:16>>) ->
	{ok, SceneId};

read(11003, <<X:16, Y:16>>) ->
    {ok, {X, Y}};

read(11004, <<SceneId:16>>) ->
    {ok, SceneId};

read(11005, <<SceneId:16>>) ->
    {ok, SceneId};

read(11008, _) ->
    {ok, []};

read(11012, <<Code:8>>) ->
    {ok, Code};

read(11014, <<SceneId:16>>) ->
    {ok, SceneId};

read(11016, <<SceneID:16, X:16, Y:16>>) ->
	{ok, {SceneID, X, Y}};

%% 向野外怪发起战斗(11404) C->S
%% CMSG_BATTLE_ATTACK_FIELD_MONSTER = 11404, // 向野外怪发起战斗
%% int16: 怪物进度id
read(11404, <<Scene_id:16,Monster_id:16>>) ->
    {ok, {Scene_id,Monster_id}};

    
read(Cmd, _R) ->
	?ERR(scene, "客户端协议号未匹配:~w", [Cmd]),
    {error, protocal_no_match}.



%%=============================================================================
%% write
%%=============================================================================

%% player move
write(11000, [PlayerId, PosList]) ->
	Size = length(PosList),
	BinPosList = write_pos_list(Size, PosList),
	Data = <<PlayerId:32, Size:16, BinPosList/binary>>,
    {ok, pt:pack(11000, Data)};

write(11001, PlayerCells) when is_list(PlayerCells)->
	Size = length(PlayerCells),
	BinPlayerCells = write_player_cell_list(Size, PlayerCells),
	Data = <<Size:16, BinPlayerCells/binary>>,
    {ok, pt:pack(11001, Data)};


write(11002, IdList) ->
	Size = length(IdList),
	PlayerOut = pt:write_id_list(Size, IdList, 32),
	Data = <<Size:16, PlayerOut/binary>>,
    {ok, pt:pack(11002, Data)};
 
write(11004, [SceneId, X, Y]) ->
	Data = <<SceneId:16, X:16, Y:16>>,
    {ok, pt:pack(11004, Data)};

%% 重置玩家坐标    
write(11008, {X, Y}) ->
    {ok, pt:pack(11008, <<X:16, Y:16>>)};

write(11012, OpenedMapList) ->
	Size1 = length(OpenedMapList),
	Data1 = pt:write_id_list(Size1, OpenedMapList, 16), 
	{ok, pt:pack(11012, <<Size1:16, Data1/binary>>)};

write(11013, OpenedMapList) ->
	Size1 = length(OpenedMapList),
	Data1 = pt:write_id_list(Size1, OpenedMapList, 16), 
	{ok, pt:pack(11013, <<Size1:16, Data1/binary>>)};

write(11014, PetRec) ->
	Bin = write_pet(PetRec),
	{ok, pt:pack(11014, Bin)};

write(11050, StringData) ->
	{ok, pt:pack(11050, pt:write_string(StringData))};

write(11051, {PlayerId, StateFlag, StateData}) ->
	{ok, pt:pack(11051, <<PlayerId:32, 
						  StateFlag:8, 
						  (pt:write_string(StateData))/binary>>)};

write(11052, {PlayerId, DataList}) ->
	Bin = write_equip_wing_horse(DataList),
	{ok, pt:pack(11052, <<PlayerId:32, 
						  Bin/binary>>)};

write(11053, {PlayerId, PetRec}) ->
	{ok, pt:pack(11053, <<PlayerId:32, (write_pet(PetRec))/binary>>)};

write(11054, {PlayerId, {IsShow, HorseEqiup}}) ->
	{ok, pt:pack(11054, <<PlayerId:32, IsShow:32, HorseEqiup:32>>)};

%% SMSG_MONSTER_VIEW_IN = 11400, // 野外怪进入视野
%% Array:怪物数量
%%   int:            怪物进度id
%%   int:            怪物组合id
%%   int16:              初始X坐标
%%   int16:            初始Y坐标
%%   int8:        状态标志位
%%   Array:        路径点数量
%%     int16:    X坐标
%%     int16:    Y坐标

write(11400, MonsterList) ->
    Size = length(MonsterList),
	BinMonsters = write_monster_list(MonsterList),
	Data = <<Size:16, BinMonsters/binary>>,
    {ok, pt:pack(11400, Data)};


%% 野外怪移动广播(11401) S->C
%% SMSG_MONSTER_MOVE = 11401, // 怪物移动广播
%% 
%% int:        怪物进度id
%% Array:      路径点数量
%%   int16:     X坐标
%%   int16:    Y坐标
write(11401, Monster) ->
    Size = length(Monster#monster.path),
	BinPosList = write_pos_list(Size, Monster#monster.path),
%% 	Data = <<(Monster#monster.id):32, 
%% 			 (Monster#monster.coord_x):16, 
%% 			 (Monster#monster.coord_y):16, Size:16, BinPosList/binary>>,
 	Data = <<(Monster#monster.id):32, 
 			 Size:16, BinPosList/binary>>,


    {ok, pt:pack(11401, Data)};


%% 野外怪移出视野(11402) S->C
%% SMSG_MONSTER_VIEW_OUT = 11402, // 怪物移出视野
%% 
%% 
%% Array:          怪物数量
%%   int:    怪物进度id
write(11402, MonsterIdList) ->
	Size = length(MonsterIdList),
	MonsterOut = pt:write_id_list(Size, MonsterIdList, 32),
	Data = <<Size:16, MonsterOut/binary>>,
    {ok, pt:pack(11402, Data)};

write(11403, Monster) ->
	Data = <<(Monster#monster.id):32,
			 (Monster#monster.state):8>>,
    {ok, pt:pack(11403, Data)};

%% 场景内野外怪(11404) S->C
%% Array:怪物数量
%%   int:            怪物进度id
%%   int:            怪物组合id
%%   int16:          初始X坐标
%%   int16:          初始Y坐标
%%   int8:        状态标志位
write(11405, MonsterList) ->
	Size = length(MonsterList),
	F = fun(Monster)->
		<<(Monster#monster.id):32,
			 (Monster#monster.group_id):32,
			 (Monster#monster.coord_x):16,
			 (Monster#monster.coord_y):16,
			 0:8>>
	end,
	Bin = list_to_binary([F(Mon)||Mon<-MonsterList]),
	
    {ok, pt:pack(11405, <<Size:16, Bin/binary>>)}.



%%=============================================================================
%% local function
%%=============================================================================
write_pet(PetRec) ->
	<<(PetRec#pet.show_state):8,
	  (PetRec#pet.level):8,
	  (PetRec#pet.show_id):32,
	  (pt:write_string(PetRec#pet.name))/binary>>.

read_pos_list(0, <<>>) ->
	[];
read_pos_list(Size, <<X:16, Y:16, Rest/binary>>) ->
	[{X, Y} | read_pos_list(Size - 1, Rest)].

write_pos_list(0, []) ->
	<<>>;
write_pos_list(Size, [{X, Y} | Rest]) ->
	Bin = write_pos_list(Size - 1, Rest),
	<<X:16, Y:16, Bin/binary>>.

write_player_cell_list(0, _)->
	<<>>;
write_player_cell_list(Size, [PlayerCell | Rest]) ->
	RestData = write_player_cell_list(Size - 1, Rest),
	BinNickName = pt:write_string(PlayerCell#player_cell.nickname),
	case PlayerCell#player_cell.path of
		[] -> 
			PathData = <<0:16>>;
		PosList ->
			Size1 = length(PosList),
			BinPosList = write_pos_list(Size1, PosList),
			PathData = <<Size1:16, BinPosList/binary>>
	end,
	BinState = pt:write_string(scene:write_app_string(PlayerCell)),
	
	BinEquipWingHorse = write_equip_wing_horse(
		[{wing, PlayerCell#player_cell.wing_data}, 
		 {horse, PlayerCell#player_cell.horse_data},
		 {weapon, PlayerCell#player_cell.equip_data#equip_info.weapon},
		 {kaijia, PlayerCell#player_cell.equip_data#equip_info.kaijia},
		 {pifeng, PlayerCell#player_cell.equip_data#equip_info.pifeng},
		 {shoes, PlayerCell#player_cell.equip_data#equip_info.shoes},
		 {ring, PlayerCell#player_cell.equip_data#equip_info.ring}]),
	case PlayerCell#player_cell.title of
		0 -> Val1 = [];
		N1 -> Val1 = [{title, N1}]
	end,
	case PlayerCell#player_cell.guild_lv of
		0 -> Val3 = [];
		N2 -> Val3 = [{guild_lv, N2}, {guild_name, PlayerCell#player_cell.guild_name}]
	end,
	OtherData = [{role_rank, PlayerCell#player_cell.role_rank}, {level, PlayerCell#player_cell.level}] ++ Val1 ++ Val3,
			
	BinVal = pt:write_string(write_cell_other_data(OtherData, "")),

	Data = <<(PlayerCell#player_cell.player_id):32, 
			 (PlayerCell#player_cell.role_id):16,
			 BinNickName/binary,
			 (PlayerCell#player_cell.x):16,
			 (PlayerCell#player_cell.y):16,
			 PathData/binary,

			 BinVal/binary,
			 (PlayerCell#player_cell.state):8,
			 BinState/binary,
			 BinEquipWingHorse/binary>>,
	<<RestData/binary, Data/binary>>. 
%% 类别定义：
%%    坐骑：1，翅膀：2，武器：3，铠甲：4，披风：5，鞋子：6，戒指：7
write_equip_wing_horse(DataList) ->
	write_equip_wing_horse(DataList, <<(length(DataList)):16>>).
write_equip_wing_horse([{wing, Datat} | Rest], Packet) ->
	write_equip_wing_horse(Rest, <<Packet/binary, 2:8, Datat:32>>);
write_equip_wing_horse([{horse, Datat} | Rest], Packet) ->
	write_equip_wing_horse(Rest, <<Packet/binary, 1:8, Datat:32>>);	
write_equip_wing_horse([{weapon, Datat} | Rest], Packet) ->
	write_equip_wing_horse(Rest, <<Packet/binary, 3:8, Datat:32>>);
write_equip_wing_horse([{kaijia, Datat} | Rest], Packet) ->
	write_equip_wing_horse(Rest, <<Packet/binary, 4:8, Datat:32>>);
write_equip_wing_horse([{pifeng, Datat} | Rest], Packet) ->
	write_equip_wing_horse(Rest, <<Packet/binary, 5:8, Datat:32>>);
write_equip_wing_horse([{shoes, Datat} | Rest], Packet) ->
	write_equip_wing_horse(Rest, <<Packet/binary, 6:8, Datat:32>>);
write_equip_wing_horse([{ring, Datat} | Rest], Packet) ->
	write_equip_wing_horse(Rest, <<Packet/binary, 7:8, Datat:32>>);
write_equip_wing_horse([], Packet) -> Packet.


write_cell_other_data([{title, Val} | Rest], ReturnVal) ->
	write_cell_other_data(Rest, "1:" ++ integer_to_list(Val) ++ "," ++ ReturnVal);
write_cell_other_data([{level, Val} | Rest], ReturnVal) ->
	write_cell_other_data(Rest, "2:" ++ integer_to_list(Val) ++ "," ++ ReturnVal);	
write_cell_other_data([{guild_lv, Val} | Rest], ReturnVal) ->
	write_cell_other_data(Rest, "3:" ++ integer_to_list(Val) ++ "," ++ ReturnVal);	
write_cell_other_data([{guild_name, Val} | Rest], ReturnVal) ->
	write_cell_other_data(Rest, "4:" ++ Val ++ "," ++ ReturnVal);
write_cell_other_data([{role_rank, Val} | Rest], ReturnVal) ->
	write_cell_other_data(Rest, "5:" ++ integer_to_list(Val) ++ ReturnVal);
write_cell_other_data([], ReturnVal) -> ReturnVal.

write_monster_list([]) -> <<>>;
write_monster_list([Monster | Rest]) -> 
	RestData = write_monster_list(Rest),
	Data = <<(Monster#monster.id):32,
			 (Monster#monster.group_id):32,
			 (Monster#monster.coord_x):16,
			 (Monster#monster.coord_y):16,
			 0:8>>,
	case Monster#monster.path of
		[] -> 
			Data1 = <<Data/binary, 0:16>>;
		PosList ->
			Size1 = length(PosList),
			BinPosList = write_pos_list(Size1, PosList),
			Data1 = <<Data/binary, Size1:16, BinPosList/binary>>
	end,
	<<RestData/binary, Data1/binary>>.
			 



	