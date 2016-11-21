scriptdir=$(cd "$(dirname "$0")"; pwd)
cd $scriptdir
nohup ./startNodeManager.sh>startnode.log 2>&1 &
