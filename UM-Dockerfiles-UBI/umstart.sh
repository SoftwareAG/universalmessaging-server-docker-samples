#################################################################################
# Copyright (c) 1999 - 2011 my-Channels Ltd
# Copyright (c) 2012 - 2022 Software AG, Darmstadt, Germany and/or its licensors
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
# UM Runtime Configuration related scripts
###############################################################################

# If you want to change the UM server name, you need to provide REALM_NAME as env variable during docker run, which will update it in Server_Common.conf file
if [ ! -z "$REALM_NAME" ]; then
    if [ -e $DATA_DIR/RealmSpecific/realms.nst ]; then
		  	echo "REALM name is configured. So new realm name may be ignored"
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

#### Function start ####
#Iterating through the Server_Common.conf, Custom_Server_Common.conf files to get the highest wrapper_java_additional index used in the files
highest_wrapper_java_index=0

function get_highest_wrapper_java_index() {
  filename=$1
  searchtext=$2
  while read line
  do
  if [[ $line == *$searchtext* ]]; then
    #get all the digits from line and extract 1st set of digits
    digits=( $(echo $line | grep -o -E '[0-9]+') )
    index=${digits[0]}
    if [ ! -z $index ] && [ $index -gt $highest_wrapper_java_index ]; then
      highest_wrapper_java_index=$index
    fi
  fi
  done < $filename
}
#### Function end ####

# To change the log framework used by the UM server, We can provide the LOG_FRAMEWORK env property during docker run ex: -e LOG_FRAMEWORK=LOG4J2 to change
if [ ! -z "$LOG_FRAMEWORK" ] && [ "${LOG_FRAMEWORK,,}" == "log4j2" ]; then
    cd $UM_HOME/server/$INSTANCE_NAME/bin
    # Check if the LOG_FRAMEWORK system is already added to Server_Common.conf or Custom_Server_Common.conf
    if ! [[ "$(grep -c "=-DLOG_FRAMEWORK=" $SERVER_COMMON_CONF_FILE)" > 0  ||  "$(grep -c "=-DLOG_FRAMEWORK=" $CUSTOM_SERVER_COMMON_CONF_FILE)" > 0 ]] ; then

        echo "Changing the UM logging framework to $LOG_FRAMEWORK"

        get_highest_wrapper_java_index $SERVER_COMMON_CONF_FILE "wrapper.java.additional."
        get_highest_wrapper_java_index $CUSTOM_SERVER_COMMON_CONF_FILE "wrapper.java.additional."

        ((highest_wrapper_java_index = $highest_wrapper_java_index+1))
        echo "Adding wrapper.java.additional.$highest_wrapper_java_index=-DLOG_FRAMEWORK=$LOG_FRAMEWORK to Tanuki custom wrapper configuration file"
        echo "wrapper.java.additional.$highest_wrapper_java_index=-DLOG_FRAMEWORK=$LOG_FRAMEWORK" >> $CUSTOM_SERVER_COMMON_CONF_FILE

        if ! [[ "$(grep -c "=-Dlog4j2.enable.threadlocals=" $SERVER_COMMON_CONF_FILE)" > 0  ||  "$(grep -c "=-Dlog4j2.enable.threadlocals=" $CUSTOM_SERVER_COMMON_CONF_FILE)" > 0 ]] ; then
            ((highest_wrapper_java_index = $highest_wrapper_java_index+1))
            echo "Adding wrapper.java.additional.$highest_wrapper_java_index=-Dlog4j2.enable.threadlocals=false to Tanuki custom wrapper configuration file"
            echo "wrapper.java.additional.$highest_wrapper_java_index=-Dlog4j2.enable.threadlocals=false" >> $CUSTOM_SERVER_COMMON_CONF_FILE
        fi
    else
        echo "UM logging framework is configured."
    fi
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

if [ ! -z "$LOG_FRAMEWORK" ] && [ "${LOG_FRAMEWORK,,}" == "log4j2" ]; then
  echo "log4j2 framework is used."
  # Change the wrapper console output format to only message
  cd $UM_HOME/server/$INSTANCE_NAME/bin
  sed -i "s|^wrapper.console.format=.*|wrapper.console.format=M|" $SERVER_COMMON_CONF_FILE
  echo "Modified tanuki wrapper console output format to output only log messages"
  # Change the wrapper log file output format to only message
  sed -i "s|^wrapper.logfile.format=.*|wrapper.logfile.format=M|" $SERVER_COMMON_CONF_FILE
  echo "Modified tanuki wrapper log file output format to output only log messages"
  # Implicitly flush stdout after each line of output sent to console
  if ! (grep -q "wrapper.console.flush=" $CUSTOM_SERVER_COMMON_CONF_FILE) ; then
    echo "wrapper.console.flush=TRUE" >> $CUSTOM_SERVER_COMMON_CONF_FILE
  fi
else
# For streaming the nirvana.log and UMRealmService.log to stdout
  cd $LOG_DIR
  touch $nirvanaLog $umRealmServiceLog
  tail -F $umRealmServiceLog | sed "s|^|[$umRealmServiceLog]: |" > /dev/stdout &
  tail -F $nirvanaLog | sed "s|^|[$nirvanaLog]: |" > /dev/stdout &
fi

#Add health monitor plugin in 'health' mountpath. this plugin will be used for docker health check.
runUMTool.sh AddHealthMonitorPlugin -dirName=$DATA_DIR -protocol=http -adapter=0.0.0.0 -port=$PORT -mountpath=health -autostart=true

#if there is any startup command configured then run it in parallel
if [ ! -z "$STARTUP_COMMAND" ]; then
    cd $SAG_HOME
    echo "calling start up commands in parallel. once the server is ready commands will be executed"
    uminitialize.sh &
fi

# run the umserver
cd $UM_HOME/server/$INSTANCE_NAME/bin/
if [ ! -z "$LOG_FRAMEWORK" ] && [ "${LOG_FRAMEWORK,,}" == "log4j2" ]; then
  ./nserver > /dev/stdout &
else
  ./nserver > /dev/null &
fi

# wait till the server shutdown
SERVER_PID=$!
echo "Universal Messaging Server PID:" $SERVER_PID
wait $SERVER_PID

echo "Process killed"