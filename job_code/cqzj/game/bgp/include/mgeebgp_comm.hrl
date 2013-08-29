
%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(ETS_BGP_CONNS,ets_bgp_conns).
-define(APP_MGEE_BGPRROXY,mgeebgp).
-define(BGP_TCP_OPTS, [
                       binary, 
                       {packet, 0}, % no packaging 
                       {reuseaddr, true}, % allow rebind without waiting 
                       {nodelay, false},
                       {delay_send, true}, 
                       {active, false},
                       {exit_on_close, false}
                      ]).

-define(RECV_TIMEOUT, 15000).

%% equal to <<"<policy-file-request/>\0">>
-define(CROSS_DOMAIN_FLAG, <<60,112,111,108,105,99,121,45,102,105,108,101,45,114,101,113,117,101,115,116,47,62,0>>).

-define(CROSS_FILE, "<?xml version=\"1.0\"?>\n<!DOCTYPE cross-domain-policy SYSTEM "
       ++"\"http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd\">\n"
       ++"<cross-domain-policy>\n<allow-access-from domain=\"*\" to-ports=\"*\"/>\n</cross-domain-policy>\n\0" ).

-define(DEBUG(Format, Args),
        common_logger:debug_msg( bgp, ?MODULE,?LINE,Format, Args)).

-define(INFO_MSG(Format, Args),
        common_logger:info_msg( node(), ?MODULE,?LINE,Format, Args)).
                  
-define(WARNING_MSG(Format, Args),
        common_logger:warning_msg( node(), ?MODULE,?LINE,Format, Args)).

%%带STACK的ERROR_MSG
-define(ERROR_MSG_STACK(Arg1,Arg2),  %% Args为两个参数
        common_logger:error_msg( node(), ?MODULE,?LINE,"Info:~s, Error: ~w, Stack:~w", [Arg1,Arg2,erlang:get_stacktrace()])).
                  
-define(ERROR_MSG(Format, Args),
        common_logger:error_msg( node(), ?MODULE,?LINE,Format, Args)).

-define(CRITICAL_MSG(Format, Args),
        common_logger:critical_msg( node(), ?MODULE,?LINE,Format, Args)).


%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------
-record(proxy_conf,{port,acceptor_num,security_key}).
-record(monitor_log_conf,{dir, frequency, suffix}).




