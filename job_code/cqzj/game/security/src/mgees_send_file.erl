%% Author: Administrator
%% Created: 2010-3-18
%% Description: TODO: Add description to mgees_send_file
-module(mgees_send_file).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([send_file/1]).
-define(CROSS_DOMAIN_FLAG, <<60,112,111,108,105,99,121,45,102,105,108,101,45,114,101,113,117,101,115,116,47,62,0>>).
-define(CROSS_FILE, "<?xml version=\"1.0\"?>\n<!DOCTYPE cross-domain-policy SYSTEM "
	   ++"\"http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd\">\n"
	   ++"<cross-domain-policy>\n"
    ++"<allow-access-from domain=\"*\" to-ports=\"*\"/>\n"
    ++"</cross-domain-policy>\n\0").
-define(TCP_OPTS, [binary, {packet, 0}, {reuseaddr, true}, {active, false}]).
%%
%% API Functions
%%



%%
%% Local Functions
%%

send_file(Socket)->
	case gen_tcp:recv(Socket,23,10000) of
		{ok,?CROSS_DOMAIN_FLAG}->
			case gen_tcp:send(Socket,?CROSS_FILE)of
				ok->
					gen_tcp:close(Socket);
				{error,_Reason}->
					gen_tcp:send(Socket,?CROSS_FILE),
					gen_tcp:close(Socket)
			end;
		_->
			gen_tcp:close(Socket),
			error
	end,
	exit(exit).

