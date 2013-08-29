set LOCAL_IP=127.0.0.1
set SG_EBIN_PATH=E:\ErlangWorkspace\Sanguo_X_server\ebin

set COOKIE=sg


set ERL_MAX_ETS_TABLES = 300000
set ERL_MAX_PORTS = 300000


cd /d %SG_EBIN_PATH%

@echo "press any key to start sango coverage"

title coverage
erl -boot start_sasl -name cover001@%LOCAL_IP% -s coverage -setcookie %COOKIE% 




