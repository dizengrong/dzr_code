-module(mod_mcm_parser).

-define(BORN_TILE, 3).
-define(NPC_TILE, 4).
-define(MONSTER_TILE, 5).
-define(COLLECTION_TILE, 6).

-define(CORRECT_VALUE_MAP, 10000000).

-export([start/0, start/2]).

-import(string, [join/2]).
-import(lists, [concat/1]).

start() ->
	start("/data/mcqzj/config/map/mcm/", "/data/mcqzj/config/src/").

start(SrcDir, DestDir) ->
	{ok, FileList} = file:list_dir(SrcDir),
	McmFiles = [FileName||FileName<-FileList, 
		filename:extension(FileName) == ".mcm"],
	write_mcm_module(McmFiles, DestDir),
	lists:foreach(fun
		(McmFile) ->
			parse_file(SrcDir++McmFile, DestDir)
	end, McmFiles).
	
write_mcm_module(McmFiles, DestDir) ->
	MapIDs = [re:replace(File, ".mcm", "", [{return, list}])||File<-McmFiles],
	Src = [
		"-module(mcm).\n\n",
		"-define(MAP_TYPE_NORMAL, 0).\n\n",
		"-define(MAP_TYPE_COPY, 1).\n\n",	
		"-export([get_mod/1,get_all/0,get_copy/0,get_common/0]).\n\n",
		"-export([map_type/1,grid_width/1,grid_height/1,offset_x/1,offset_y/1]).\n\n",
		"-export([is_walkable/2,safe_type/2,is_common/1,is_copy/1]).\n\n",
		"-export([jump_tiles/1,stall_tiles/1,reado_tiles/1,born_tiles/1,npc_tiles/1,monster_tiles/1,collection_tiles/1]).\n\n",
		join(["get_mod("++MapID++")-> mcm_"++MapID||MapID<-MapIDs], ";\n")++".\n\n",
		"get_all() -> ["++join([concat(["mcm_", MapID])||MapID<-MapIDs], ",")++"].\n\n",
		"get_copy() -> [M||M<-get_all(), M:map_type() == 1].\n\n",
		"get_common() -> [M||M<-get_all(), M:map_type() == 0].\n\n",
		"map_type(MapID) -> (get_mod(MapID)):map_type().\n\n",
		"is_copy(MapID) -> (get_mod(MapID)):is_copy().\n\n",
		"is_common(MapID) -> (get_mod(MapID)):is_common().\n\n",
		"grid_width(MapID) -> (get_mod(MapID)):grid_width().\n\n",
		"grid_height(MapID) -> (get_mod(MapID)):grid_height().\n\n",
		"offset_x(MapID) -> (get_mod(MapID)):offset_x().\n\n",
		"offset_y(MapID) -> (get_mod(MapID)):offset_y().\n\n",
		"is_walkable(MapID, Tile) -> (get_mod(MapID)):is_walkable(Tile).\n\n",
		"safe_type(MapID, Tile) -> (get_mod(MapID)):safe_type(Tile).\n\n",
		"jump_tiles(MapID) -> (get_mod(MapID)):jump_tiles().\n\n",
		"stall_tiles(MapID) -> (get_mod(MapID)):stall_tiles().\n\n",
		"reado_tiles(MapID) -> (get_mod(MapID)):reado_tiles().\n\n",
		"born_tiles(MapID) -> (get_mod(MapID)):born_tiles().\n\n",
		"npc_tiles(MapID) -> (get_mod(MapID)):npc_tiles().\n\n",
		"monster_tiles(MapID) -> (get_mod(MapID)):monster_tiles().\n\n",
		"collection_tiles(MapID) -> (get_mod(MapID)):collection_tiles().\n\n"
	],
	file:write_file(DestDir ++"/mcm.erl", Src).

parse_file(McmFile, DestDir) ->
	{ok, Bin} = file:read_file(McmFile),
    <<MapID:32, MapType:32, _MapName:256, _:256, 
	  TileRow:32, TileCol:32, ElementNum:32, JumpPointNum:32, 
	  OffsetX:32, OffsetY:32, TW:32, TH:32, Data/binary>> = zlib:uncompress(Bin),
	File = concat([DestDir,"/mcm_",MapID,".erl"]),
	Src0 = concat([
		"-module(mcm_",MapID,").\n\n",
		"-compile([export_all]).\n\n",
		"map_id() -> ",MapID,".\n\n",
		"map_type() -> ",MapType,".\n\n",
		"grid_width() -> ",TW,".\n\n",
		"grid_height() -> ",TH,".\n\n",
		"offset_x() -> ",OffsetX-?CORRECT_VALUE_MAP,".\n\n",
		"offset_y() -> ",OffsetY-?CORRECT_VALUE_MAP,".\n\n",
		"is_walkable(Tile) -> safe_type(Tile) /= undefined.\n\n",
		"is_common() -> map_type() == 0.\n\n",
		"is_copy() -> map_type() == 1.\n\n"
	]),
    DataTileLength = 8*TileRow*TileCol,
    <<DataTile:DataTileLength/bitstring, DataRemain/binary>> = Data,
	{SafeType, StallTiles, ReadoTiles} = parse_safe_type(DataTile, 0, 0, TileCol, [], [], []),
	{DataRemain2, ElemTiles} = parse_elem_tiles(DataRemain, ElementNum, []),
	JumpTiles = parse_jump_tile(DataRemain2, JumpPointNum, []),
	Src1 = safe_type_src(SafeType),
	Src2 = jump_tiles_src(JumpTiles),
	Src3 = stall_tiles_src(StallTiles),
	Src4 = reado_tiles_src(ReadoTiles),
	Src5 = born_tiles_src([{Tx, TY}||{born_tile, Tx, TY}<-ElemTiles]),
	Src6 = npc_tiles_src([{ID, IndexTX, IndexTY}||{npc_tile, ID, IndexTX, IndexTY}<-ElemTiles]),
	Src7 = monster_tiles_src([{ID, IndexTX, IndexTY}||{monster_tile, ID, IndexTX, IndexTY}<-ElemTiles]),
	Src8 = collection_tiles_src([{ID, IndexTX, IndexTY}||{collection_tile, ID, IndexTX, IndexTY}<-ElemTiles]),
	file:write_file(File, [Src0, Src1, Src2, Src3, Src4, Src5, Src6, Src7, Src8]).
	
parse_safe_type(<<>>, _TX, _TY, _TileCol, SafeType, StallTiles, ReadoTiles) ->
	{SafeType, StallTiles, ReadoTiles};
parse_safe_type(DataBin, TX, TY, TileCol, SafeType, StallTiles, ReadoTiles) ->
	<<_YuLiu:1, Arena:1, Sell:1, AllSafe:1, Safe:1, 
	  _Run:1, _Alpha:1, Exist:1, DataRemain/binary>> = DataBin,
	{NewSafeType, NewStallTiles, NewReadoTiles} = if Exist =:= 1 ->
			{
				if Safe =:= 1 andalso AllSafe =:= 1 ->
					   [{TX, TY, absolute_safe}|SafeType];
				   Safe =:= 1  ->
					   [{TX, TY, safe}|SafeType];
				   true ->
					   [{TX, TY, not_safe}|SafeType]
				end,
				if Sell =:= 1 ->
					   [{TX, TY}|StallTiles];
				   true ->
					   StallTiles
				end,
				if Arena =:= 1 ->
					   [{TX, TY}|ReadoTiles];
				   true ->
					   ReadoTiles
				end
			};
		true ->
			{SafeType, StallTiles, ReadoTiles}
	end,
	if 
	TY + 1 >= TileCol ->
		parse_safe_type(DataRemain, TX+1, 0, TileCol, NewSafeType, NewStallTiles, NewReadoTiles);
	true ->
		parse_safe_type(DataRemain, TX, TY+1, TileCol, NewSafeType, NewStallTiles, NewReadoTiles)
	end.

parse_elem_tiles(RemainData, 0, ElemTiles) ->
	{RemainData, ElemTiles};
parse_elem_tiles(DataBin, ElementNum, ElemTiles) ->
	<< ID:32, IndexTX:32, IndexTY:32, Type:32, Link:32, DataRemain/bitstring>> = DataBin,
	LinkLen = 8*Link,
	<<_:LinkLen/bitstring, DataRemain2/bitstring>> = DataRemain,
	NewElemTiles = case Type of
		?BORN_TILE ->
			[{born_tile, IndexTX, IndexTY}|ElemTiles];
		?NPC_TILE ->
			[{npc_tile, ID, IndexTX, IndexTY}|ElemTiles];
		?MONSTER_TILE ->
			[{monster_tile, ID, IndexTX, IndexTY}|ElemTiles];
		?COLLECTION_TILE ->
			[{collection_tile, ID, IndexTX, IndexTY}|ElemTiles];
		_ ->
			ElemTiles
	end,
	parse_elem_tiles(DataRemain2, ElementNum-1, NewElemTiles).

parse_jump_tile(_DataBin, 0, JumpTiles) ->
	JumpTiles;
parse_jump_tile( DataBin, JumpPointNum, JumpTiles) ->
    <<_ID:32, IndexTX:32, IndexTY:32,TargetMapID:32, 
	  TIndexTX:32, TIndexTY:32, _HW:32, _YL:32, _WL:32, 
	  _MinLevel:32, _MaxLevel:32, Link:32, DataRemain/bitstring>> = DataBin,
    LinkLen = 8*Link,
    <<_:LinkLen/bitstring, DataRemain2/bitstring>> = DataRemain,
	NewJumpTiles = [{TargetMapID, IndexTX, IndexTY, TIndexTX, TIndexTY}|JumpTiles],
    parse_jump_tile(DataRemain2, JumpPointNum - 1, NewJumpTiles).

safe_type_src(SafeTypeLst) ->
	join([concat(["safe_type({",TX,",",TY,"}) -> ",SafeType])||{TX, TY, SafeType}<-SafeTypeLst], ";\n")++";\nsafe_type(_) -> undefined.\n\n".

jump_tiles_src(JumpTiles) ->
	"jump_tiles() -> ["++join([concat(["{",ToMapID,",",FromTX,",",FromTY,",",ToTX,",",ToTY,"}"])||{ToMapID,FromTX,FromTY,ToTX,ToTY}<-JumpTiles], ",")++"].\n\n".

stall_tiles_src(StallTiles) ->
	"stall_tiles() -> ["++join([concat(["{",TX,",",TY,"}"])||{TX,TY}<-StallTiles], ",")++"].\n\n".

reado_tiles_src(ReadoTiles) ->
	"reado_tiles() -> ["++join([concat(["{",TX,",",TY,"}"])||{TX,TY}<-ReadoTiles], ",")++"].\n\n".

born_tiles_src(BornTiles) ->
	"born_tiles() -> ["++join([concat(["{",TX,",",TY,"}"])||{TX,TY}<-BornTiles], ",")++"].\n\n".

npc_tiles_src(NpcTiles) ->
	"npc_tiles() -> ["++join([concat(["{",ID,",",TX,",",TY,"}"])||{ID,TX,TY}<-NpcTiles], ",")++"].\n\n".

monster_tiles_src(MonsterTiles) ->
	"monster_tiles() -> ["++join([concat(["{",ID,",",TX,",",TY,"}"])||{ID,TX,TY}<-MonsterTiles], ",")++"].\n\n".

collection_tiles_src(CollectionTiles) ->
	"collection_tiles() -> ["++join([concat(["{",ID,",",TX,",",TY,"}"])||{ID,TX,TY}<-CollectionTiles], ",")++"].\n\n".