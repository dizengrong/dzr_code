
-define(APP_NAME, 'mgeeweb').

-define(DEV(Format, Args),
        common_logger:dev(?APP_NAME, ?MODULE, ?LINE, Format, Args)).

-define(DEBUG(Format, Args),
        common_logger:debug_msg(?APP_NAME, ?MODULE,?LINE,Format, Args)).

-define(INFO_MSG(Format, Args),
        common_logger:info_msg( node(), ?MODULE,?LINE,Format, Args)).
			      
-define(WARNING_MSG(Format, Args),
        common_logger:warning_msg( node(), ?MODULE,?LINE,Format, Args)).
			      
-define(ERROR_MSG(Format, Args),
        common_logger:error_msg( node(), ?MODULE,?LINE,Format, Args)).

-define(CRITICAL_MSG(Format, Args),
        common_logger:critical_msg( node(), ?MODULE,?LINE,Format, Args)).

-include("common.hrl").
-include("letter.hrl").
-include("mgeeweb_module.hrl").

-record(faction_ybc_time, {start_h, start_m, end_h, end_m}).
-record(faction_ybc_config, {change_day, old, new, change_time=0}).
