-module(socket_queue).

-include("common.hrl").

-export([send_msg/3]).


send_msg(Socket, PlayerId,Parent_pid) ->
	process_flag(trap_exit,true),
	?INFO(login,"send message process is ~w, from ~w",[self(),Parent_pid]),
	send_msg_loop(Socket, PlayerId,Parent_pid).
	

send_msg_loop(Socket, PlayerId,Parent_pid) ->
    receive
        {send, Packet} ->
            gen_tcp:send(Socket, Packet),
            send_msg_loop(Socket, PlayerId,Parent_pid);
		{send_direct, Packet} ->
			gen_tcp:send(Socket, Packet),
            send_msg_loop(Socket, PlayerId,Parent_pid);
		{send_after, Packet, _TimeOut} ->
			gen_tcp:send(Socket, Packet),
            send_msg(Socket, PlayerId,Parent_pid);
        stop ->
        	ok;
		{'EXIT',Parent_pid,Reason}->
			?INFO(send_msg,"get an exit message ~w",[Reason]),
			gen_tcp:close(Socket),
			ok;
		Other->
			?INFO(send_msg,"get a unknown message ~w",[Other]),
			gen_tcp:close(Socket),
			ok
    end.