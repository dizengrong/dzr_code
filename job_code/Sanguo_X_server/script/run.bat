start "log" erl -pa ../ebin -config ../config/log_config -s log start
pause

start "server" 
erl -pa ../ebin -config ../config/sg_config -s main -s reloader

pause