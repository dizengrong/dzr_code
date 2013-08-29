-module(data_achieve).

-compile(export_all).



%% 根据编号获取类型列表：get_notify_list(类别编号)  -> 列表
get_notify_list(0)  -> [{1,12},{7,6},{5,10},{5,8},{5,3},{5,2},{5,1},{4,12},{4,9},{4,8},{4,7},{3,7},{4,6},{4,3},{3,10},{3,11},{7,7},{7,8},{3,12},{1,2},{1,3},{1,4},{8,8},{1,6},{1,7},{1,8},{1,9},{1,10},{8,7},{5,9},{8,6},{8,5},{8,3},{8,2}];

get_notify_list(1)  -> [{1,1},{8,1},{2,1}];

get_notify_list(2)  -> [{2,2},{2,4},{2,3}];

get_notify_list(3)  -> [{2,5},{2,6},{2,7},{2,8}];

get_notify_list(4)  -> [{2,9},{2,10}];

get_notify_list(5)  -> [{3,1},{3,2},{3,3},{3,4}];

get_notify_list(6)  -> [{3,6},{3,5}];

get_notify_list(7)  -> [{3,9},{3,8}];

get_notify_list(8)  -> [{4,2},{4,1}];

get_notify_list(9)  -> [{4,4},{4,5}];

get_notify_list(10)  -> [{4,10},{4,11}];

get_notify_list(11)  -> [{5,5},{5,4},{5,6},{5,7}];

get_notify_list(12)  -> [{6,2},{6,1},{6,4}];

get_notify_list(13)  -> [{6,3},{6,5},{6,6}];

get_notify_list(14)  -> [{6,7},{6,8},{6,9}];

get_notify_list(15)  -> [{6,10},{6,11},{6,12}];

get_notify_list(16)  -> [{7,2},{7,1},{7,3},{1,5}];

get_notify_list(17)  -> [{8,4},{7,5},{7,4}];

get_notify_list(18)  -> [{7,9},{7,12},{7,11},{7,10}];

get_notify_list(19)  -> [{1,11},{8,9}];

get_notify_list(20)  -> [{2,11},{2,12}].


%%================================================
%% 模型1目标：get_target_1(成就大类ID, 成就小类ID)  -> 需求数量
get_target_1(1, 1)  -> 20;

get_target_1(1, 4)  -> 2;

get_target_1(1, 10)  -> 1;

get_target_1(2, 1)  -> 40;

get_target_1(2, 5)  -> 5;

get_target_1(2, 6)  -> 10;

get_target_1(2, 7)  -> 17;

get_target_1(2, 8)  -> 19;

get_target_1(2, 9)  -> 10;

get_target_1(2, 10)  -> 20;

get_target_1(3, 12)  -> 1;

get_target_1(4, 1)  -> 50;

get_target_1(4, 2)  -> 200;

get_target_1(4, 6)  -> 2000;

get_target_1(4, 9)  -> 10000;

get_target_1(4, 10)  -> 5;

get_target_1(4, 11)  -> 10;

get_target_1(5, 4)  -> 3;

get_target_1(5, 5)  -> 5;

get_target_1(5, 6)  -> 8;

get_target_1(5, 7)  -> 10;

get_target_1(6, 1)  -> 200;

get_target_1(6, 2)  -> 300;

get_target_1(6, 4)  -> 400;

get_target_1(6, 7)  -> 5;

get_target_1(6, 8)  -> 8;

get_target_1(6, 9)  -> 10;

get_target_1(6, 10)  -> 1;

get_target_1(6, 11)  -> 1;

get_target_1(6, 12)  -> 1;

get_target_1(7, 4)  -> 6;

get_target_1(7, 5)  -> 12;

get_target_1(7, 6)  -> 30;

get_target_1(7, 8)  -> 10;

get_target_1(8, 1)  -> 100;

get_target_1(8, 2)  -> 10;

get_target_1(8, 3)  -> 100000000;

get_target_1(8, 4)  -> 18;

get_target_1(8, 5)  -> 100000;

get_target_1(8, 7)  -> 6.


%%================================================
%% 模型2目标：get_target_2(成就大类ID, 成就小类ID)  -> 需求数量
get_target_2(1, 2)  -> 1;

get_target_2(1, 3)  -> 1;

get_target_2(1, 7)  -> 1;

get_target_2(1, 8)  -> 1;

get_target_2(1, 9)  -> 1;

get_target_2(1, 11)  -> 1;

get_target_2(3, 5)  -> 50;

get_target_2(3, 6)  -> 200;

get_target_2(3, 7)  -> 100;

get_target_2(3, 8)  -> 50;

get_target_2(3, 9)  -> 300;

get_target_2(3, 10)  -> 200;

get_target_2(3, 11)  -> 150;

get_target_2(4, 3)  -> 50;

get_target_2(4, 4)  -> 1;

get_target_2(4, 5)  -> 999;

get_target_2(4, 8)  -> 600;

get_target_2(5, 1)  -> 5;

get_target_2(5, 2)  -> 10;

get_target_2(5, 3)  -> 20;

get_target_2(5, 8)  -> 50;

get_target_2(5, 9)  -> 20;

get_target_2(5, 10)  -> 500;

get_target_2(7, 7)  -> 1;

get_target_2(8, 6)  -> 50;

get_target_2(8, 8)  -> 300;

get_target_2(8, 9)  -> 1000.


%%================================================
%% 模型3目标：get_target_3(成就大类ID, 成就小类ID)  -> 需求编号,需求数量
get_target_3(1, 5)  -> {1,3};

get_target_3(2, 2)  -> {2,60};

get_target_3(2, 3)  -> {3,80};

get_target_3(2, 4)  -> {4,90};

get_target_3(2, 11)  -> {10,15};

get_target_3(2, 12)  -> {10,30};

get_target_3(4, 7)  -> {0,200};

get_target_3(4, 12)  -> {0,10};

get_target_3(6, 3)  -> {3,200};

get_target_3(6, 5)  -> {3,300};

get_target_3(6, 6)  -> {4,400};

get_target_3(7, 1)  -> {6,7};

get_target_3(7, 2)  -> {8,10};

get_target_3(7, 3)  -> {12,13}.


%%================================================
%% 模型4目标：get_target_4(成就大类ID, 成就小类ID)  -> 需求编号,需求数量
get_target_4(7, 9)  -> {20,4};

get_target_4(7, 10)  -> {40,6};

get_target_4(7, 11)  -> {60,8};

get_target_4(7, 12)  -> {30,9}.


%%================================================
%% 模型5目标：get_target_5(成就大类ID, 成就小类ID)  -> 需求数量
get_target_5(1, 6)  -> 9999;

get_target_5(1, 12)  -> 9999;

get_target_5(3, 1)  -> 9999;

get_target_5(3, 2)  -> 9999;

get_target_5(3, 3)  -> 9999;

get_target_5(3, 4)  -> 9999.


%%================================================
%% 成就点数获取：get_point(成就大类ID, 成就小类ID)  -> 成就点数
get_point(1, 1)  -> 2;

get_point(1, 2)  -> 3;

get_point(1, 3)  -> 3;

get_point(1, 4)  -> 3;

get_point(1, 5)  -> 2;

get_point(1, 6)  -> 2;

get_point(1, 7)  -> 2;

get_point(1, 8)  -> 5;

get_point(1, 9)  -> 3;

get_point(1, 10)  -> 2;

get_point(1, 11)  -> 3;

get_point(1, 12)  -> 10;

get_point(2, 1)  -> 2;

get_point(2, 2)  -> 3;

get_point(2, 3)  -> 5;

get_point(2, 4)  -> 10;

get_point(2, 5)  -> 3;

get_point(2, 6)  -> 5;

get_point(2, 7)  -> 5;

get_point(2, 8)  -> 8;

get_point(2, 9)  -> 3;

get_point(2, 10)  -> 5;

get_point(2, 11)  -> 8;

get_point(2, 12)  -> 10;

get_point(3, 1)  -> 3;

get_point(3, 2)  -> 3;

get_point(3, 3)  -> 5;

get_point(3, 4)  -> 5;

get_point(3, 5)  -> 3;

get_point(3, 6)  -> 5;

get_point(3, 7)  -> 5;

get_point(3, 8)  -> 3;

get_point(3, 9)  -> 10;

get_point(3, 10)  -> 5;

get_point(3, 11)  -> 10;

get_point(3, 12)  -> 10;

get_point(4, 1)  -> 5;

get_point(4, 2)  -> 10;

get_point(4, 3)  -> 3;

get_point(4, 4)  -> 2;

get_point(4, 5)  -> 10;

get_point(4, 6)  -> 3;

get_point(4, 7)  -> 5;

get_point(4, 8)  -> 2;

get_point(4, 9)  -> 5;

get_point(4, 10)  -> 2;

get_point(4, 11)  -> 5;

get_point(4, 12)  -> 10;

get_point(5, 1)  -> 3;

get_point(5, 2)  -> 5;

get_point(5, 3)  -> 10;

get_point(5, 4)  -> 3;

get_point(5, 5)  -> 5;

get_point(5, 6)  -> 8;

get_point(5, 7)  -> 10;

get_point(5, 8)  -> 10;

get_point(5, 9)  -> 7;

get_point(5, 10)  -> 12;

get_point(6, 1)  -> 3;

get_point(6, 2)  -> 5;

get_point(6, 3)  -> 5;

get_point(6, 4)  -> 5;

get_point(6, 5)  -> 10;

get_point(6, 6)  -> 15;

get_point(6, 7)  -> 5;

get_point(6, 8)  -> 8;

get_point(6, 9)  -> 10;

get_point(6, 10)  -> 5;

get_point(6, 11)  -> 8;

get_point(6, 12)  -> 10;

get_point(7, 1)  -> 5;

get_point(7, 2)  -> 7;

get_point(7, 3)  -> 10;

get_point(7, 4)  -> 10;

get_point(7, 5)  -> 8;

get_point(7, 6)  -> 5;

get_point(7, 7)  -> 5;

get_point(7, 8)  -> 5;

get_point(7, 9)  -> 8;

get_point(7, 10)  -> 10;

get_point(7, 11)  -> 12;

get_point(7, 12)  -> 20;

get_point(8, 1)  -> 10;

get_point(8, 2)  -> 12;

get_point(8, 3)  -> 20;

get_point(8, 4)  -> 20;

get_point(8, 5)  -> 20;

get_point(8, 6)  -> 20;

get_point(8, 7)  -> 13;

get_point(8, 8)  -> 15;

get_point(8, 9)  -> 20.


%%================================================
%% 成就点数获取：get_award(成就大类ID, 成就小类ID)  -> {银币,绑定元宝,道具,军功}
get_award(1, 1)  -> {2000,0,[{12,1,1}],0};

get_award(1, 2)  -> {2000,0,[],0};

get_award(1, 3)  -> {2000,0,[],0};

get_award(1, 4)  -> {3000,0,[{15,1,0}],0};

get_award(1, 5)  -> {5000,0,[],0};

get_award(1, 6)  -> {3000,0,[],0};

get_award(1, 7)  -> {3000,0,[],0};

get_award(1, 8)  -> {3000,0,[{289,2,0}],20};

get_award(1, 9)  -> {2000,0,[],0};

get_award(1, 10)  -> {3000,0,[],0};

get_award(1, 11)  -> {5000,0,[{22,1,0}],0};

get_award(1, 12)  -> {20000,10,[],10};

get_award(2, 1)  -> {3000,0,[{98,1,1},{109,1,0}],0};

get_award(2, 2)  -> {4500,0,[],0};

get_award(2, 3)  -> {7500,10,[],0};

get_award(2, 4)  -> {15000,0,[],0};

get_award(2, 5)  -> {4500,0,[],30};

get_award(2, 6)  -> {7500,0,[{193,1,0},{203,1,1}],0};

get_award(2, 7)  -> {7500,0,[],0};

get_award(2, 8)  -> {12000,20,[],20};

get_award(2, 9)  -> {4500,0,[],0};

get_award(2, 10)  -> {7500,0,[],0};

get_award(2, 11)  -> {12000,0,[],15};

get_award(2, 12)  -> {30000,20,[],0};

get_award(3, 1)  -> {6000,0,[],0};

get_award(3, 2)  -> {6000,0,[],0};

get_award(3, 3)  -> {10000,0,[],0};

get_award(3, 4)  -> {10000,10,[],0};

get_award(3, 5)  -> {6000,0,[],0};

get_award(3, 6)  -> {10000,20,[],0};

get_award(3, 7)  -> {10000,0,[],0};

get_award(3, 8)  -> {6000,0,[],35};

get_award(3, 9)  -> {50000,15,[],0};

get_award(3, 10)  -> {10000,0,[],0};

get_award(3, 11)  -> {50000,10,[],0};

get_award(3, 12)  -> {50000,30,[],0};

get_award(4, 1)  -> {12500,0,[],0};

get_award(4, 2)  -> {25000,0,[],0};

get_award(4, 3)  -> {7500,0,[],40};

get_award(4, 4)  -> {5000,0,[],0};

get_award(4, 5)  -> {25000,0,[],0};

get_award(4, 6)  -> {7500,0,[],0};

get_award(4, 7)  -> {12500,10,[],0};

get_award(4, 8)  -> {5000,0,[],0};

get_award(4, 9)  -> {12500,10,[],0};

get_award(4, 10)  -> {5000,0,[],0};

get_award(4, 11)  -> {12500,0,[],20};

get_award(4, 12)  -> {50000,0,[],0};

get_award(5, 1)  -> {6000,0,[],0};

get_award(5, 2)  -> {10000,0,[],0};

get_award(5, 3)  -> {20000,20,[],0};

get_award(5, 4)  -> {6000,0,[],0};

get_award(5, 5)  -> {10000,0,[],10};

get_award(5, 6)  -> {16000,0,[],0};

get_award(5, 7)  -> {20000,0,[],0};

get_award(5, 8)  -> {20000,20,[],0};

get_award(5, 9)  -> {14000,0,[],0};

get_award(5, 10)  -> {24000,0,[],0};

get_award(6, 1)  -> {15000,10,[],0};

get_award(6, 2)  -> {25000,10,[],0};

get_award(6, 3)  -> {25000,0,[],30};

get_award(6, 4)  -> {25000,0,[],0};

get_award(6, 5)  -> {50000,0,[],0};

get_award(6, 6)  -> {75000,20,[],0};

get_award(6, 7)  -> {25000,0,[],0};

get_award(6, 8)  -> {40000,0,[],0};

get_award(6, 9)  -> {50000,20,[],0};

get_award(6, 10)  -> {25000,0,[],0};

get_award(6, 11)  -> {40000,0,[],0};

get_award(6, 12)  -> {50000,0,[],0};

get_award(7, 1)  -> {25000,0,[],15};

get_award(7, 2)  -> {35000,0,[],0};

get_award(7, 3)  -> {50000,30,[],0};

get_award(7, 4)  -> {50000,0,[],0};

get_award(7, 5)  -> {40000,30,[],0};

get_award(7, 6)  -> {25000,0,[],0};

get_award(7, 7)  -> {25000,0,[],0};

get_award(7, 8)  -> {25000,0,[],0};

get_award(7, 9)  -> {40000,0,[],0};

get_award(7, 10)  -> {50000,0,[],0};

get_award(7, 11)  -> {60000,0,[],0};

get_award(7, 12)  -> {100000,0,[],0};

get_award(8, 1)  -> {50000,0,[],0};

get_award(8, 2)  -> {60000,20,[],0};

get_award(8, 3)  -> {100000,15,[{289,99,1}],0};

get_award(8, 4)  -> {100000,30,[],0};

get_award(8, 5)  -> {100000,0,[],0};

get_award(8, 6)  -> {100000,20,[],0};

get_award(8, 7)  -> {65000,0,[],0};

get_award(8, 8)  -> {75000,0,[],0};

get_award(8, 9)  -> {100000,0,[],0}.


%%================================================
%% 成就称号获取：get_title(成就大类ID, 成就小类ID) -> 成就称号
get_title(1, 1) -> 0;

get_title(1, 2) -> 0;

get_title(1, 3) -> 0;

get_title(1, 4) -> 0;

get_title(1, 5) -> 0;

get_title(1, 6) -> 0;

get_title(1, 7) -> 0;

get_title(1, 8) -> 1;

get_title(1, 9) -> 0;

get_title(1, 10) -> 0;

get_title(1, 11) -> 0;

get_title(1, 12) -> 2;

get_title(2, 1) -> 0;

get_title(2, 2) -> 0;

get_title(2, 3) -> 3;

get_title(2, 4) -> 0;

get_title(2, 5) -> 0;

get_title(2, 6) -> 0;

get_title(2, 7) -> 0;

get_title(2, 8) -> 4;

get_title(2, 9) -> 0;

get_title(2, 10) -> 0;

get_title(2, 11) -> 0;

get_title(2, 12) -> 5;

get_title(3, 1) -> 0;

get_title(3, 2) -> 0;

get_title(3, 3) -> 0;

get_title(3, 4) -> 0;

get_title(3, 5) -> 0;

get_title(3, 6) -> 6;

get_title(3, 7) -> 0;

get_title(3, 8) -> 0;

get_title(3, 9) -> 7;

get_title(3, 10) -> 0;

get_title(3, 11) -> 8;

get_title(3, 12) -> 9;

get_title(4, 1) -> 0;

get_title(4, 2) -> 10;

get_title(4, 3) -> 0;

get_title(4, 4) -> 0;

get_title(4, 5) -> 0;

get_title(4, 6) -> 0;

get_title(4, 7) -> 11;

get_title(4, 8) -> 0;

get_title(4, 9) -> 12;

get_title(4, 10) -> 0;

get_title(4, 11) -> 0;

get_title(4, 12) -> 13;

get_title(5, 1) -> 0;

get_title(5, 2) -> 0;

get_title(5, 3) -> 14;

get_title(5, 4) -> 0;

get_title(5, 5) -> 0;

get_title(5, 6) -> 0;

get_title(5, 7) -> 0;

get_title(5, 8) -> 15;

get_title(5, 9) -> 0;

get_title(5, 10) -> 16;

get_title(6, 1) -> 0;

get_title(6, 2) -> 0;

get_title(6, 3) -> 0;

get_title(6, 4) -> 0;

get_title(6, 5) -> 0;

get_title(6, 6) -> 17;

get_title(6, 7) -> 0;

get_title(6, 8) -> 0;

get_title(6, 9) -> 18;

get_title(6, 10) -> 0;

get_title(6, 11) -> 0;

get_title(6, 12) -> 0;

get_title(7, 1) -> 0;

get_title(7, 2) -> 0;

get_title(7, 3) -> 19;

get_title(7, 4) -> 0;

get_title(7, 5) -> 0;

get_title(7, 6) -> 20;

get_title(7, 7) -> 0;

get_title(7, 8) -> 0;

get_title(7, 9) -> 0;

get_title(7, 10) -> 0;

get_title(7, 11) -> 0;

get_title(7, 12) -> 21;

get_title(8, 1) -> 22;

get_title(8, 2) -> 0;

get_title(8, 3) -> 0;

get_title(8, 4) -> 23;

get_title(8, 5) -> 24;

get_title(8, 6) -> 25;

get_title(8, 7) -> 0;

get_title(8, 8) -> 26;

get_title(8, 9) -> 27.


%%================================================
