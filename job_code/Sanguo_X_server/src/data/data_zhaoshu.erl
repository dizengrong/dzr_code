-module(data_zhaoshu).

-compile(export_all).



%% get_cost(诏书类型) -> 消耗的金币
get_open_cost(1) -> 10;
get_open_cost(2) -> 50;
get_open_cost(3) -> 200.

%%================================================
%% get_rand_junwei(诏书类型, 随机数) -> 随机得到的点数
get_rand_junwei(1,N) when N =< 70 -> 1;

get_rand_junwei(1,N) when N =< 90 -> 2;

get_rand_junwei(1,N) when N =< 100 -> 3;

get_rand_junwei(2,N) when N =< 70 -> 5;

get_rand_junwei(2,N) when N =< 90 -> 10;

get_rand_junwei(2,N) when N =< 100 -> 15;

get_rand_junwei(3,N) when N =< 70 -> 20;

get_rand_junwei(3,N) when N =< 90 -> 30;

get_rand_junwei(3,N) when N =< 100 -> 60.


%%================================================
