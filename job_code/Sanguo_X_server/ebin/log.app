%%%-----------------------------------
%%% @Module  : client
%%% @Author  : liaoxiaobo
%%% @Email   : liaoxb1231@163.com
%%% @Created : 2011-08-09
%%% @Modify  : 2011-08-09
%%% @Description:  
%%%-----------------------------------

{   
    application, log,
    [   
        {description, "This is log test."},   
        {vsn, "1.0a"},   
        {modules,
		[]},   
        {registered, [log_sup]},
        {applications, [kernel, stdlib]},   
        {mod, {log_app, []}},   
        {start_phases, []}   
    ]   
}.  