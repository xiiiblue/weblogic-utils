scriptdir=$(cd "$(dirname "$0")"; pwd)
cd $scriptdir
nohup ./startWebLogic.sh>start.log 2>&1 &
