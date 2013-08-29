-module(coverage).

-compile(export_all).


%%usage
%%修改
%% get_test_node
%% get_test_file
%% 指向要修改的测试的文件
%%运行 erl -name cover001@%LOCAL_IP% -s coverage -setcookie %COOKIE%
%%按一下回车开始测试
%%按另一下回车，获取测试结果
%%测试结果，放在../../*.COVER.html中

get_test_node()->
	'sg_0@127.0.0.1'.	
	

get_test_file()->
	[mod_dazuo].

get_search_path_option()->
	[
		{"",""},
		{"ebin","src/data"},
		{"ebin","src/data_storage"},	
		{"ebin","src/gen_cache"},
		{"ebin","src/log"},
		{"ebin","src/main_control"},
		{"ebin","src/pp"},
		{"ebin","src/protocol"},
		{"ebin","src/system"},
		{"ebin","src/system/fengdi"},
		{"ebin","src/system/items"},
		{"ebin","src/system/player"},
		{"ebin","src/system/role"},
		{"ebin","src/system/scene"},
		{"ebin","src/system/xunxian"},
		{"ebin","src/util"}
	].


start()->
	%%use this ets to save file info, to quickly find the source code path
	net_adm:ping(get_test_node()),

	ets:new(file_info,[public,named_table]),
	cover:start(get_test_node()),
	cover_compile(),
	
%% 	io:read("Press any key to dump analyze file"),
	{ok,[Term]} = io:fread("Input filename to be imported, or just enter 's' to skip\n","~s"),
	if 
		length(Term) > 2	->
			Result = cover:import(Term),
			io:format("import coverage file ~s, result ~w~n",[Term,Result]);
		true->
			io:format("enter ~s, didn't import file~n",[Term])
	end,

	io:fread("Press enter to dump analyze file\n",""),
	
	dump_analyze_file(),
	io:fread("Press enter to quit\n","").

cover_compile()->
	File_list = get_test_file(),
	F = fun(File)->
		{Src_file,_} = filename:find_src(File,get_search_path_option()),
		ets:insert(file_info,{File,Src_file}),	
	
		Ret = cover:compile_beam(File),
		io:format("cover compile ~p~n",[Ret])
	end,
	lists:foreach(F, File_list).


dump_analyze_file()->
	%%1.get the source code to the beam file
	%%2.since the cover will only try to find source code in either 
	%%	the same folder or the ../src folder, I will fetch the source code and 
	%%  copy them to the same folder as beam, then remove them after analyze
	File_infos = ets:tab2list(file_info),

	{{YY,MM,DD},{H,M,S}} = calendar:local_time(),
	Log_folder = io_lib:format("../../coverage/coverage_~b_~b_~b.~b.~b.~b",[YY,MM,DD,H,M,S]), 
	file:make_dir(Log_folder),

	F = fun({File,Src_file})->
		File_str = atom_to_list(File),
		%%file info in format {sd_networking,"e:/ErlangWorkspace/Dragon2Server/src/sd_networking"}
		%%we need to add the extention for them
		io:format("processing ~p, ~p~n", [File_str,Src_file]),
		
		file:copy(Src_file++".erl", "./" ++ File_str ++ ".erl"),

		cover:analyse_to_file(File,Log_folder++"/"++File_str++".cover.html",  [html]),
		file:delete(File_str++".erl")
		
	end,
	lists:foreach(F,File_infos),

	%%dump export file if merge needed.
	cover:export(Log_folder++"/export.coverdata"),
	io:format("export file ~s/export.coverdata, for future coverage merge analyze~n",[Log_folder]).
	
