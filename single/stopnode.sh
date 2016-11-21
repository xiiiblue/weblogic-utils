/usr/sbin/lsof -i:5566|grep java|awk '{print "kill -9 "$2}'|sh
