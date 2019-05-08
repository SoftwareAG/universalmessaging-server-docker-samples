#################################################################################
# Copyright (c) 1999 - 2011 my-Channels Ltd
# Copyright (c) 2012 - 2019 Software AG, Darmstadt, Germany and/or its licensors
#
# SPDX-License-Identifier: Apache-2.0
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#################################################################################
#!/bin/bash

###############################################################################
# Variable  Declaration
###############################################################################

nirvanaLog=nirvana.log
umRealmServiceLog=UMRealmService.log

###############################################################################
# UM Runtime Configuation related scripts
###############################################################################

# If you want to change the UM server name, you need to provide REALM_NAME as env variable during docker run, which will update it in Server_Common.conf file
if [ ! -z "$REALM_NAME" ]; then
    if [ $INSTANCE_NAME = $REALM_NAME ]; then
		    echo "UM instance name: $INSTANCE_NAME and UM realm name: $REALM_NAME are same"
    else
		    echo "UM instance name: $INSTANCE_NAME and UM realm name: $REALM_NAME are not same, Updating it to $REALM_NAME"
	      cd $UM_HOME/server/$INSTANCE_NAME/bin
	      sed -i "s|-DREALM=$INSTANCE_NAME|-DREALM=$REALM_NAME|" $SERVER_COMMON_CONF_FILE
    fi
fi

# If you want to change the configurations related to JVM i.e, min max and direct memory, you can do it by providing INIT_JAVA_MEM_SIZE & MAX_JAVA_MEM_SIZE - 
# - & MAX_DIRECT_MEM_SIZE as environment variables during docker run, which will be updated in Server_Common.conf file
if [ ! -z "$INIT_JAVA_MEM_SIZE" ]; then
    echo "Updating UM init Java Heap value to $INIT_JAVA_MEM_SIZE"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
    sed -i "s|^wrapper.java.initmemory=.*|wrapper.java.initmemory=$INIT_JAVA_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$MAX_JAVA_MEM_SIZE" ]; then
    echo "Updating UM Max Java Heap value to $MAX_JAVA_MEM_SIZE"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
    sed -i "s|^wrapper.java.maxmemory=.*|wrapper.java.maxmemory=$MAX_JAVA_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$MAX_DIRECT_MEM_SIZE" ]; then
    echo "Updating UM Max Direct Memory value to $MAX_DIRECT_MEM_SIZE"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
	  sed -i "s|\(.*\)=-XX:MaxDirectMemorySize=\(.*\)|\1=-XX:MaxDirectMemorySize=$MAX_DIRECT_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi
# If you want to enable Basic auth and to enable and mandate it, you can do it by providing BASIC_AUTH_ENABLE & BASIC_AUTH_MANDATORY as env variables during docker run,
# which will update the values in Server_Common.conf file
if [ ! -z "$BASIC_AUTH_ENABLE" ]; then
    echo "Enabling Basic Auth for UM server"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
    sed -i "s|\(.*\)=-DNirvana.auth.enabled=\(.*\)|\1=-DNirvana.auth.enabled=$BASIC_AUTH_ENABLE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$BASIC_AUTH_MANDATORY" ]; then
    echo "Enabling and Mandating the Basic Auth for UM server"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
	  sed -i "s|\(.*\)=-DNirvana.auth.mandatory=\(.*\)|\1=-DNirvana.auth.mandatory=$BASIC_AUTH_MANDATORY|" $SERVER_COMMON_CONF_FILE
fi

###############################################################################
# Function  Declaration: which does shutting down of um server
###############################################################################

function stop_um_server {
# Perform Server Shutdown
  echo "Info: Stopping the Universal Messaging Server.."
  cd $UM_HOME/server/$INSTANCE_NAME/bin
  ./nstopserver
  exit 0
}

###############################################################################
# Main  Declaration
# - Wait for SIGNAL TERMINATION from docker daemon and call the stop_um_server function
# - Create the empty logs files and stream the content to stdout and the log entries are prefixed with file names
# - Start the um server and capture its PID, to wait for it
###############################################################################

# to stop the running UM server if the server is running
trap stop_um_server SIGTERM

# For streaming the nirvana.log and UMRealmService.log to stdout
cd $LOG_DIR
touch $nirvanaLog $umRealmServiceLog
tail -F $umRealmServiceLog | sed "s|^|[$umRealmServiceLog]: |" > /dev/stdout &
tail -F $nirvanaLog | sed "s|^|[$nirvanaLog]: |" > /dev/stdout &

# run the umserver
cd $UM_HOME/server/$INSTANCE_NAME/bin/
./nserver > /dev/null & 

# wait till the server shutdown
SERVER_PID=$!
echo "Universal Messaging Server PID:" $SERVER_PID
wait $SERVER_PID

echo "Process killed"