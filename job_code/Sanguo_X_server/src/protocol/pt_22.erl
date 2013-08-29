-module (pt_22).

-include("common.hrl").

-export([read/2, write/2]).


%% =========================== 种植协议 ===========================
read(22000, <<PlayerId:32>>) -> 
	{ok, PlayerId};

read(22001, <<LandId:8>>) -> 
	{ok, LandId};

read(22002, <<LandId:8, SeedType:8, RoleId:16>>) -> 
	{ok, {LandId, SeedType, RoleId}};

read(22003, <<SeedType:8>>) -> 
	{ok, SeedType};

read(22004, <<LandId:8>>) -> 
	{ok, LandId};

read(22005, <<LandId:8>>) -> 
	{ok, LandId};

read(22006, _) -> 
	{ok, []};

read(22007, <<LandId:8, FriendId:32>>) -> 
	{ok, {LandId, FriendId}};
read(22008, _) -> 
    {ok,[]};   		

%% ============================= end =============================

%% =========================== 奴隶协议 ===========================
read(22100, <<PlayerId:32>>) -> 
	{ok, PlayerId};

read(22101, <<Pos:8>>) -> 
	{ok, Pos};

read(22102, _) -> 
	{ok, []};

read(22103, <<PlayerId:32>>) -> 
	{ok, PlayerId};

read(22104, <<FriendId:32>>) -> 
	{ok, FriendId};

read(22105, _) -> 
	{ok, []};

read(22106, <<Pos:8>>) -> 
	{ok, Pos};

read(22107, <<WorkType:8>>) -> 
	{ok, WorkType};

read(22108, _) -> 
	{ok, []}.			

%% ============================= end =============================


write(22000, {PlayerId, LandRecList,PlayerName,EmployID}) ->
	Bin = write_land(util:unixtime(), LandRecList, <<>>),
    NameBinary = pt:write_string(PlayerName),
	{ok, pt:pack(22000, <<PlayerId:32,NameBinary/binary,EmployID:16,(length(LandRecList)):16, Bin/binary>>)};

write(22003, {ExpSeedQuality, SilSeedQuality}) ->
	{ok, pt:pack(22003, <<ExpSeedQuality:8, SilSeedQuality:8>>)};

write(22006, FriendWaterInfoList) ->
	Bin = write_friend_water_info(FriendWaterInfoList, <<>>),
	{ok, pt:pack(22006, <<(length(FriendWaterInfoList)):16, Bin/binary>>)};

write(22007, {SilverForWater,OwnerId,IsCanWater}) ->
    ?INFO(land,"play water get SiverForWater is ~w",[SilverForWater]),
    {ok, pt:pack(22007, <<SilverForWater:32,OwnerId:32,IsCanWater:8>>)};

write(22100, {PlayerId, SlaveOwnerDetailRec, SlaveDetailList}) ->
	Bin = write_slaves(SlaveDetailList, <<>>),
	{ok, pt:pack(22100, <<PlayerId:32, 
						  (SlaveOwnerDetailRec#slave_owner_detail.id):32,
						  (pt:write_string(SlaveOwnerDetailRec#slave_owner_detail.name))/binary,
						  (length(SlaveDetailList)):16, Bin/binary>>)};

write(22102, NonSlaveRecs) ->
	Bin = write_non_slaves(NonSlaveRecs, <<>>),
	{ok, pt:pack(22102, <<(length(NonSlaveRecs)):16, Bin/binary>>)};

write(22107, {LeftWorkTimes, LeftCd}) ->
	{ok, pt:pack(22107, <<LeftWorkTimes:8, LeftCd:32>>)}.	

%% =======================================================
%% =======================================================
write_friend_water_info([], Bin) -> Bin;
write_friend_water_info([{FriendId, FriendName, HasCanWaterLand} | Rest], Bin) ->
	HasCanWaterLand1 = case HasCanWaterLand of true -> 1; false -> 0 end,
	BinName = pt:write_string(FriendName),
	Bin1 = <<FriendId:32,
			 BinName/binary,
			 HasCanWaterLand1:8,
			 Bin/binary>>,
	write_friend_water_info(Rest, Bin1).

write_land(_Now, [], Bin) -> Bin;
write_land(Now, [LandRec | Rest], Bin) ->
	{_, LandId} = LandRec#land.key,
	LeftCd = LandRec#land.cd_time - Now,
	case LeftCd < 0 of
		true -> LeftCd1 = 0;
		_    -> LeftCd1 = LeftCd
	end,
	Bin1 = <<LandId:8,
			 (LandRec#land.state):8,
			 LeftCd1:32,
			 (LandRec#land.seed_type):8,
			 (LandRec#land.seed_quality):8,
			 (LandRec#land.watering_times):8,
			 Bin/binary>>,
	write_land(Now, Rest, Bin1).

write_slaves([], Bin) -> Bin;
write_slaves([SlaveDetailRec | Rest], Bin) ->
	Name = pt:write_string(SlaveDetailRec#slave_detail.slave_name),
	Bin1 = <<(SlaveDetailRec#slave_detail.pos):8,
			 (SlaveDetailRec#slave_detail.slave_id):32,
			 (SlaveDetailRec#slave_detail.slave_level):16,
			 Name/binary,
			 (SlaveDetailRec#slave_detail.taxes):32,
			 (SlaveDetailRec#slave_detail.end_time):32,
			 Bin/binary>>,
	write_slaves(Rest, Bin1).

write_non_slaves([], Bin) -> Bin;
write_non_slaves([NonSlaveRec | Rest], Bin) ->
	Name = pt:write_string(NonSlaveRec#non_slave_detail.name),
	Bin1 = <<(NonSlaveRec#non_slave_detail.id):32,
			 (NonSlaveRec#non_slave_detail.level):16,
			 Name/binary, 
			 (NonSlaveRec#non_slave_detail.career):8, 
			 Bin/binary>>,
	write_non_slaves(Rest, Bin1).

