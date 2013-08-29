-module(mod_bag_SUITE).

%% Note: This directive should only be used in test suites.
-compile(export_all).

-include("ct.hrl").
-include("mgeew.hrl").

%%--------------------------------------------------------------------
%% Test server callback functions
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% Function: suite() -> DefaultData
%% DefaultData: [tuple()]  
%% Description: Require variables and set default values for the suite
%%--------------------------------------------------------------------
suite() -> [
{timetrap,{minutes,1}},
{require,domain}
            ].

%%--------------------------------------------------------------------
%% Function: init_per_suite(Config) -> Config
%% Config: [tuple()]
%%   A list of key/value pairs, holding the test case configuration.
%% Description: Initiation before the whole suite
%%
%% Note: This function is free to add any key/value pairs to the Config
%% variable, but should NOT alter/remove any existing entries.
%%--------------------------------------------------------------------

init_per_suite(Config) ->
    List = ets:match(ct_attributes, '$1'),
    io:format("codepath =  ~n~p~n ", [code:get_path()]),
    %%这里不能用?config获取，因为完全不是一回事
    io:format("domain = ~n~p~n ", [ct:get_config(domain)]),
    io:format("..init  testsuit...config = ~p~n", [ Config]),
    common_bag:init_bag(111111),
    %%这里返回的值将作为参数传给后面的每个case
    [{roleid,111111}|Config].

%%--------------------------------------------------------------------
%% Function: end_per_suite(Config) -> _
%% Config: [tuple()]
%%   A list of key/value pairs, holding the test case configuration.
%% Description: Cleanup after the whole suite
%%--------------------------------------------------------------------
end_per_suite(_Config) ->
    ok.

%% init per test
init_per_testcase(Name, Config) ->
    io:format("..init  testcase........~n~p.~p~n", [Name, Config]),
    case Name of
        test1 ->
            %%读取当前suite需要的在mod_bag_SUITE_data目录下的数据文件
            DirPath = filename:join(?config(data_dir,Config), "equip.config"),
            {ok,List} = file:consult(DirPath),
            io:format("^^^^^^^^^^^^^& ~n ~p ~n  ^^^^^^^^^&", [List]);
        test2 ->
            Fun = fun() ->
                          common_bag:bag_position_used({?config(roleid,Config),1,3})
                  end,
            case db:transaction(Fun) of
                {atomic, _} ->
                    Config;
                {aborted, Reason} ->
                    {skip, Reason}
            end;
        _ ->
            nil
    end,
    Config.

end_per_testcase(Name, Config) ->
    io:format("...end  testcase........~n~p~p~n", [Name, Config]),
    ok.
%%--------------------------------------------------------------------
%% Function: all() -> TestCases
%% TestCases: [Case] 
%% Case: atom()
%%   Name of a test case.
%% Description: Returns a list of all test cases in this test suite
%%--------------------------------------------------------------------      
all() -> 
    [
		test1,
		test2,
		test3
	].

%%-------------------------------------------------------------------------
%% Test cases starts here.
%%-------------------------------------------------------------------------

    
test1(Config) ->
    RoleID = ?config(roleid,Config),
    Ret = common_bag:get_bag_content(RoleID,1),
    io:format("roleid = ~w , bagid = ~w , content = ~w",[RoleID,1,Ret]),
    ok.
   

test2(Config) ->
    RoleID = ?config(roleid,Config),
    Fun = fun() ->
                  PostList = common_bag:get_muti_empty_bag_pos(RoleID,10),
                  io:format("roleid = ~w  , PosList = ~w",[RoleID,PostList]),
                  common_bag:bag_muti_position_used(RoleID,PostList),
                  PostList2 = common_bag:get_muti_empty_bag_pos(RoleID,5),
                  io:format("roleid = ~w  , PosList2 = ~w",[RoleID,PostList2]),	
                  common_bag:bag_muti_position_empty(RoleID,PostList),
                  PostList3 = common_bag:get_muti_empty_bag_pos(RoleID,10),
                  io:format("roleid = ~w  , PosList2 = ~w",[RoleID,PostList3])
          end,
    db:transaction(Fun),
    ct:comment(".................i'm a comment ~~~~~~~~~~~n"),
    ok.

test3() ->
    [
     {timetrap, {seconds, 1}}
    ].

test3(_Config) ->
    %%测试超时后会自动退出
    timer:sleep(2000),
    ok.
    
