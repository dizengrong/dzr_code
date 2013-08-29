
-define(LOG(Format, Args), global:send(merge_log_server, {log, ?MODULE, ?LINE, erlang:localtime(), Format, Args})).

