 %%%-----------------------------------
%%% @Module  : sd_reader
%%% @Email   : dizengrong@gmail.com
%%% @Created : 2011.08.1
%%% @Description: 读取客户端
%%%-----------------------------------
-module(sg_reader).
-export([start_link/0, init/0]).
-include("common.hrl").

-define(TCP_TIMEOUT, 1000). % 解析协议超时时间
-define(HEART_TIMEOUT, 60000). % 心跳包超时时间
-define(HEART_TIMEOUT_TIME, 5). % 心跳包超时次数
-define(HEADER_LENGTH, 4). % 消息头长度

%%记录客户端进程
-record(client, {
            player     = #player_status{},	%% 玩家进程相关信息
            login      = 0,
            id         = 0,
            accname    = none,
            fcm        = 0,                 %% 默认不防
            timeout    = 0,                 %% 超时次数
            is_online_relogin = false,      %% 是否是在线顶号
            stay_alive = 60000     %% 当玩家断开连接不超过1min钟登陆时可以继续上次的状态
     }).

start_link() ->
    {ok, proc_lib:spawn_link(?MODULE, init, [])}.

%%gen_server init
%%Host:主机IP
%%Port:端口
init() ->
    process_flag(trap_exit, true),
	?INFO(sd_reader,"creating new process"),
    Client = #client{
                player  = none,
                login   = 0,
                accname = none,
                timeout = 0
            },
    receive
        {go, Socket} ->
            login_parse_packet(Socket, Client);
		{exit,From,Reason}->
			?DEBUG(sd_reader,"exit from ~w, reason ~w",[From,Reason]);
		Other->
			?ERR(sd_reader,"unknown message ~w",[Other])
    end.

parse_qq_header(Socket) ->
    Ref = async_recv(Socket, 1, ?HEART_TIMEOUT),
    receive
        {inet_async, Socket, Ref, {ok, <<Char:8>>}} ->
            case Char == $\r of
                true ->
                    Ref1 = async_recv(Socket, 3, ?HEART_TIMEOUT),
                    receive
                        {inet_async, Socket, Ref1, {ok, <<Char1:8, Char2:8, Char3:8>>}} ->
                            case Char1 == $\n andalso Char2 == $\r andalso Char3 == $\n of 
                                true -> end_of_parse_qq_header;
                                false -> parse_qq_header(Socket)
                            end
                    end;
                false ->
                    parse_qq_header(Socket)
            end
    end.

%%接收来自客户端的数据 - 先处理登陆
%%Socket：socket id
%%Client: client记录
login_parse_packet(Socket, Client) ->
    Ref = async_recv(Socket, ?HEADER_LENGTH, ?HEART_TIMEOUT),
    receive
        %%flash安全沙箱
        {inet_async, Socket, Ref, {ok, ?FL_POLICY_REQ}} ->
			?INFO(sd_reader,"policy reuest "),
            Len = 23 - ?HEADER_LENGTH,
            async_recv(Socket, Len, ?TCP_TIMEOUT),
            gen_tcp:send(Socket, ?FL_POLICY_FILE),
            gen_tcp:close(Socket);
        {inet_async, Socket, Ref, {ok, <<"GET ">>}} ->
            parse_qq_header(Socket),
            login_parse_packet(Socket, Client);
        %%登陆处理
        {inet_async, Socket, Ref, {ok, <<Len:16, Cmd:16>>}} ->
            BodyLen = Len - ?HEADER_LENGTH,
            case BodyLen > 0 of
                true ->
                    Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
                    receive
                       {inet_async, Socket, Ref1, {ok, Binary1}} ->	
							case util:check_command(Binary1) of 
							{ok,Binary}->
                            	case routing(Cmd, Binary) of								
	                               	%% 先验证登陆
    	                            {ok, login, Accname, Fcm, Timestamp, Tick} ->
										put(fcm,Fcm),
        	                            case pp_account:handle(10000, Socket, [Accname, Timestamp, Tick]) of
            	                            Id when Id > 0 ->
                	                            Client1 = Client#client{
                    	                            login = 1,
                        	                        accname = Accname,
													fcm = Fcm,
													id = Id 
                                        	    },
                                    	        login_parse_packet(Socket, Client1);
	                                        0 ->
    	                                    	Client2 = Client#client{accname = Accname, fcm = Fcm},
        	                                    login_parse_packet(Socket, Client2)
            	                        end;
                	                %% 创建角色
                    	            {ok, create, Data} ->
                        	            case Client#client.login == 0 of
                            	            true ->
                                	            Data1 = [Client#client.accname] ++ Data,
                                    	        Res = pp_account:handle(10002, Socket, Data1),
												case Res of
													0 ->
                                            			Client1 = Client#client{login = 0};
													_ ->	
														Client1 = Client#client{login = 1, id = Res}
												end,
            	                                login_parse_packet(Socket, Client1);
                	                        false -> %% 玩家已经有自己的角色了，并且应该是进入游戏的，结果却发了一个创建角色的请求
												?ERR(login,"login error ~w, binary ~w",[Cmd,Binary]),
												?INFO(login,"already exist a role"),
												do_lost_async(Socket, Client)
                            	        end;
									%% 创建游客
									{ok, new_visitor_enter, Fcm, Timestamp, Tick} ->
										put(fcm,Fcm),
										case pp_account:handle(10010, Socket, [Timestamp, Tick]) of
											{true, Id, AccName, _RoleName} ->
												Client1 = Client#client{login = 1, fcm = Fcm,
                	                                	accname = AccName, id = Id},
												login_parse_packet(Socket, Client1);
											{false, Reason} ->
												?ERR(login,"login error ~w, binary ~w",[Cmd,Binary]),
												?INFO(login,"already exist a role for ~w",[Reason]),
												do_lost_async(Socket, Client)
										end;
	                                %% 进入游戏
    	                            {ok, enter, _Code} ->
        	                            case Client#client.login == 1 of
            	                            true when Client#client.id > 0->
												Id = Client#client.id,
												put(id,Id), 
                	    	                    case mod_login:login(start, [Id, Client#client.accname, Client#client.fcm, self()], Socket) of
                            	                    {error, fail} ->	%% 不应该发生！
                                	                    %% 告诉玩家登陆失败
														?ERR(login,"login error ~w, binary ~w",[Cmd,Binary]),
														do_lost_async(Socket, Client);
                                            	    {ok, PlayerPid} ->                     
                                                	    do_parse_packet(Socket, Client#client {player = PlayerPid})
                                                    
	                                            end;
    	                                    false ->
												?ERR(login,"login error ~w, binary ~w",[Cmd,Binary]),
            	                                do_lost_async(Socket, Client)
                	                    end;
									{error,validate_failed}->
										{ok,Bin} = pt_60:write(60000,1),
										gen_tcp:send(Socket, Bin)
    	                        end;
							false->
								case routing(Cmd, Binary1) of 
								{gm_ok,gm_validate_pass}->
									%%管理接口没有send process,对性能也没有要求,直接回复
									case mod_management:enabled_gm() of
									true->
										{ok,Bin} = pt_60:write(60000,0),
										gen_tcp:send(Socket, Bin),
										do_parse_packet(Socket, #client{});
									false->
										{ok,Bin} = pt_60:write(60000,1),
										gen_tcp:send(Socket, Bin)
									end;
								_ ->
									?ERR(cheating,"seq incorrect, Binary is ~w",[Binary1])
								end
							end
                    	end;
	                false ->
    	                case Client#client.login == 1 of
        	                true ->
								put(id,Client#client.id), 
            	                pp_account:handle(Cmd, Socket,  Client#client.accname),
                	            login_parse_packet(Socket, Client);
                    	    false ->
								?ERR(login,"client login is not 1"),
                        	    do_lost_async(Socket, Client)
	                    end	
    	        end;	
		{inet_async, Socket, Ref, {error,timeout}} ->
            case Client#client.timeout >= ?HEART_TIMEOUT_TIME of
                true ->
					?INFO(sd_reader, "heart timerout...info:[time ~w account:~s]",[Client#client.timeout,Client#client.accname]),
                    do_lost_async(Socket, Client);
                false ->
                    login_parse_packet(Socket, Client#client{timeout = Client#client.timeout + 1})            
            end
    end.

%%接收来自客户端的数据 - 登陆后进入游戏逻辑
%%Socket：socket id
%%Client: client记录
do_parse_packet(Socket, Client) ->
    Ref = async_recv(Socket, ?HEADER_LENGTH, ?HEART_TIMEOUT),
    receive
        {inet_async, Socket, Ref, {ok, <<Len:16, Cmd:16>>}} ->
			Client1 = Client#client{timeout = 0 },
            BodyLen = Len - ?HEADER_LENGTH,
            case BodyLen > 0 of
                true ->
                    Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
                    receive
                       {inet_async, Socket, Ref1, {ok, Binary1}} ->
							case util:check_command(Binary1) of
							{ok,Binary}->
                            	case routing(Cmd, Binary) of
                                	%%这里是处理游戏逻辑
                                	{ok, Data} ->
                                        pp_routing(Cmd, Client1, Data),
										do_parse_packet(Socket, Client1);
									_ ->
										?ERR(cheating,"routing[Cmd] incorrect, Binary is ~w",[Cmd, Binary1])
								end;
							false->
								case routing(Cmd, Binary1) of
								{gm_ok,Data}->
									io:format("excute GM command ~w", [Cmd]),
									mod_management:handle(Cmd,{Data,Socket}),
									do_parse_packet(Socket, Client1);
								_->
									?ERR(cheating,"seq incorrect, Binary is ~w",[Binary1])
								end
							end
                    end;
				false->
					?ERR(pack,"something wrong, we should'nt have empty body protocol, cmd ~w, len ~w",[Cmd,Len])
            end;

        %%超时处理
        {inet_async, Socket, Ref, {error,timeout}} ->
            case Client#client.timeout >= ?HEART_TIMEOUT_TIME of
                true ->
					?ERR(sd_reader, "heart timerout...info:[time ~w account:~s]",[Client#client.timeout,Client#client.accname]),
                    do_lost_async(Socket, Client);
                false ->
                    do_parse_packet(Socket, Client#client{timeout = Client#client.timeout + 1})            
            end;
        {stop_reader} -> %% 这是服务端主动将玩家踢下线，所以不会等待重连了
            ?INFO(sg_reader, "reader receive stop message from server");
        %%用户断开连接
		{inet_async,_PORT,_,{error,closed}}->
			?INFO(sg_reader, "close socket from client"),
			do_lost_async(Socket, Client);
        Other ->
            ?INFO(sg_reader, "reader receive unknown message ~w",[Other]),
			do_lost_async(Socket, Client)
    end.



%%退出游戏
do_lost_async(Socket, Client) ->
    mod_player:logout_event(Client#client.id),
	%%gen_tcp:close(Socket),
	mod_login:logout_async(Client#client.id),

	?INFO(sg_reader,"do_lost client: ~w",  [ Client]).
    
%%退出游戏同步，用于顶号
do_lost_sync(Socket, Client) ->
    mod_player:logout_event(Client#client.id),
	%%gen_tcp:close(Socket),
	mod_login:logout_sync(Client#client.id),

	?INFO(sd_reader,"do_lost client: ~w, reason: ~w",  [ Client]).

%%路由
%%组成如:pt_10:read
routing(Cmd, Binary) -> 
    %%取前面二位区分功能类型
    ?INFO(route,"Cmd = ~w, Binary = ~w", [Cmd, Binary]),
    case integer_to_list(Cmd) of
		[H1, H2, _, _, _] ->
		    Module = list_to_atom("pt_" ++ [H1, H2]),
		    %% 添加这个避免客户端的错误协议导致服务端的异常
		    case catch Module:read(Cmd, Binary) of
		    	{'EXIT', Error} -> 
                    ?ERR(sg_reader, "pt_xx:read has error: ~w", [Error]),
                    has_no_protocal;
		    	Data -> Data
		    end;
		_ ->
			protocal_error
	end.  		

%% 接受信息
async_recv(Sock, Length, Timeout) when is_port(Sock) ->
    case prim_inet:async_recv(Sock, Length, Timeout) of
        {error, Reason} -> 
			?ERR(socket,"~w",[Reason]),
			self() ! {'EXIT',self(),socket_error};
        {ok, Res}       -> Res
    end.

pp_routing(Cmd, Client, Data) ->
    ProType = Cmd div 1000,
    case ProType of %%游戏基础功能处理 
        10 -> pp_account:handle(Cmd,Client#client.id,Data);
        11 -> pp_scene:handle(Cmd,Client#client.id,Data);
        12 -> pp_item:handle(Cmd,Client#client.id,Data);
        13 -> pp_official:handle(Cmd,Client#client.id,Data);
        14 -> pp_mail:handle(Cmd,Client#client.id,Data);
        15 -> pp_role:handle(Cmd,Client#client.id,Data);
        16 -> case mod_management:getisableChat(Client#client.id) of
				false -> pp_chat:handle(lock_speak, Client#client.id, <<>>);
				_ -> pp_chat:handle(Cmd, Client#client.id, Data)
			end;
        17 -> pp_task:handle(Cmd,Client#client.id,Data);
		18 -> pp_relationship:handle(Cmd,Client#client.id,Data);
        19 -> pp_guild:handle(Cmd,Client#client.id,Data);
        20 -> pp_battle:handle(Cmd, Client#client.id, Data);
        21 -> pp_dungeon:handle(Cmd, Client#client.id, Data);
		22 -> pp_fengdi:handle(Cmd, Client#client.id, Data);
        23 -> pp_cool_down:handle(Cmd,Client#client.id,Data);
        24 -> pp_holy:handle(Cmd,Client#client.id,Data);
        25 -> pp_player_info:handle(Cmd,Client#client.id,Data); 
        26 -> pp_yunbiao:handle(Cmd,Client#client.id,Data);
        28 -> pp_pet:handle(Cmd,Client#client.id,Data);
        29 -> pp_achieve:handle(Cmd,Client#client.id,Data);
		30 -> pp_team:handle(Cmd,Client#client.id,Data);
		31 -> pp_arena:handle(Cmd, Client#client.id, Data);
		33 -> pp_rankings:handle(Cmd,Client#client.id,Data);
        38 -> pp_marstower:handle(Cmd,Client#client.id,Data);
        49 -> pp_dazuo:handle(Cmd,Client#client.id,Data);
        61 -> pp_guaji:handle(Cmd,Client#client.id,Data);
		62 -> pp_boss:handle(Cmd, Client#client.id,Data);
        _Other-> 
            ?ERR(login,"protocal not implemented yet")
    end.
