SG_SERVER=/home/samba/sg
SG_BIN=$SG_SERVER/ebin
SG_INCLUDE=$SG_SERVER/include
SG_CONFIG=$SG_SERVER/config
SG_LOG=/home/samba/sg_log
SG_DATA_CONFIG=/home/web/service/ConfigFileGenerator
CUR_DIR=$PWD

function start()
{
    echo "starting sanguo server...";

    if [ ! -d $SG_SERVER/../sg_log_bak ]; then
        mkdir $SG_SERVER/../sg_log_bak;
    fi

    ver=$(get_svn_version);
    log_folder=$SG_SERVER/../sg_log_bak/v${ver}_$(date +%Y-%m-%d.%H-%M-%S);

# move sg_log.log, log_node.log, server_node.log, svn_log.log into the same log folder
# and move the previouse svn log to log folder;
    mkdir $log_folder; 
    mv $SG_LOG/* $log_folder 2>/dev/null;
    mv svn_log.log $log_foler;

# why do we need to touch?
    touch $SG_LOG/{sg_log.log,log_node.log,server_node.log};


# start the epmd daemon to manage the erlang node before starting our process
    epmd -daemon;
    erl -pa $SG_BIN -noshell -detached -config $SG_SERVER/config/log -s log;
    erl -pa $SG_BIN -noshell -detached -config $SG_SERVER/config/sg_0 -s main; 

    echo "done...";
}

function status()
{
    erl -pa $SG_BIN -s server_tools srv_status $SG_CONFIG/sg_0.config
    cat /tmp/result_tmp_file
}

function make()
{
    echo "making erl beam files...";
    cd $SG_SERVER; erl -make | tee $CUR_DIR/make.txt;
    echo "done ...";
}

function update()
{
    echo "updating erl files from svn ...";
# update the xml config file from svn
# and sleep one second, and then use wget to get the newest data from database
    svn up $SG_DATA_CONFIG;
    sleep 1;

    wget -q 'http://192.168.24.159:159/ServerControl/coreCmd.php?action=getData&server=159_1';
    rm coreCmd*;

    cd $SG_SERVER;
    oldver=$(get_svn_version);
    svn up; echo "done...";
    newver=$(get_svn_version);
   
    echo "last version: $oldver";
    echo "new version: $newver";
    
    get_svn_log $oldver $newver
}

function hot_fix()
{
   touch $SG_BIN/temp;
   update;
   make;

    ver=$(get_svn_version);
    log_folder=$SG_SERVER/../sg_log_bak/v${ver}_$(date +%Y-%m-%d.%H-%M-%S);
  
 # move sg_log.log, log_node.log, server_node.log, svn_log.log into the same log folder
 # and move the previouse svn log to log folder;
    mkdir $log_folder;
    cp $SG_LOG/* $log_folder ;
    cp svn_log.log $log_foler;
    echo "" > $SG_LOG/log_node.log;
    echo "" > $SG_LOG/server_node.log;
    echo "" > $SG_LOG/sg_log.log;

   cd $SG_BIN;
   if [ ! -f $SG_CONFIG/sg_0.config ]; then
       echo "config file $SG_CONFIG/sg_0.config not exist "
       exit;
   else
       erl -pa $SG_BIN -s server_tools hot_reload $SG_CONFIG/sg_0.config
   fi
   rm $SG_BIN/temp
}

function stop()
{
    erl -pa $SG_BIN -s server_tools stop_srv $SG_CONFIG/sg_0.config
    sleep 3
}

function kill_all()
{
    echo "killing all the erlang process ...";
    ps -ef | grep -P "erl.*sg" | awk '{print $2;}' | xargs kill -9 2>/dev/null;
    echo "done ...";
}


function get_svn_version()
{
   svn info $SG_SERVER | awk -F: '$1 ~ /Revision/ {print $2}' | tr -d ' ';  
}

function get_svn_log() 
{
   if [ $# -ne 2 ]; then
       return;
   fi
   if [ "$1" -gt "$2" ]; then
       return;
   fi

   echo "printing svn log....";

# make sure svn_log.log exist
   touch $CUR_DIR/svn_log.log;
   cat $CUR_DIR/svn_log.log > $CUR_DIR/svn_log.temp;
# concatenate all the svn logs 
   svn log $SG_SERVER -r "$1:$2" > $CUR_DIR/svn_log.log;
   cat $CUR_DIR/svn_log.temp >> $CUR_DIR/svn_log.log;
   rm $CUR_DIR/svn_log.temp;

   echo "done ...";
}

function usage()
{
    echo ;
    echo "========================================================================================"
    echo " Sango control script ";
    echo "========================================================================================"
    echo "usage:      $(basename $0) start | make | update | hot_fix | stop | kill_all | full_start";
    echo "start       start server and backup the logs";
    echo "make:       recompile the beam files";
    echo "update:     update the data from svn server";
    echo "hot_fix:    hot reload";
    echo "stop:       stop server";
    echo "status:     report the current status of the server";
    echo "kill_all:   kill all the erl processes brutually;"
    echo "full_start: update, make and start";  
    echo
    exit 1;
}

function getopt()
{
    if [ $# -ne 1 ]; then
        usage;
    fi
    case $1 in
        start)    start;;
	status)   status;;
        make)     make;;
        update)   update;;
        stop)     stop;;
        kill_all) kill_all;;
        hot_fix)  hot_fix;;
        full_start)
            stop;
            update;
            make;
            start;;
        *)
            usage;;
    esac
}

getopt $@


