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

nirvana_log=nirvana.log
umrealmservice_log=UMRealmService.log
date_pattern="%a %b %d %T.%3N %Z %Y"

# log utility method
function log() {
  message="$1"
  echo "[$(date +"$date_pattern")] Info: $message"
}

###############################################################################
# UM Runtime Configuration related scripts
###############################################################################

# If you want to change the UM server name, you need to provide REALM_NAME as env variable during docker run, which will update it in Server_Common.conf file
if [ ! -z "$REALM_NAME" ]; then
    if [ -e $DATA_DIR/RealmSpecific/realms.nst ]; then
		  	log "REALM name is configured. New realm name will be ignored."
    else
		    log "UM instance name: $INSTANCE_NAME and UM realm name: $REALM_NAME are not same, Updating it to $REALM_NAME"
	      cd $UM_HOME/server/$INSTANCE_NAME/bin
	      sed -i "s|-DREALM=$INSTANCE_NAME|-DREALM=$REALM_NAME|" $SERVER_COMMON_CONF_FILE
    fi
fi

# If you want to change the configurations related to JVM i.e, min max and direct memory, you can do it by providing INIT_JAVA_MEM_SIZE & MAX_JAVA_MEM_SIZE - 
# - & MAX_DIRECT_MEM_SIZE as environment variables during docker run, which will be updated in Server_Common.conf file
if [ ! -z "$INIT_JAVA_MEM_SIZE" ]; then
    log "Updating UM init Java Heap value to $INIT_JAVA_MEM_SIZE"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
    sed -i "s|^wrapper.java.initmemory=.*|wrapper.java.initmemory=$INIT_JAVA_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$MAX_JAVA_MEM_SIZE" ]; then
    log "Updating UM Max Java Heap value to $MAX_JAVA_MEM_SIZE"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
    sed -i "s|^wrapper.java.maxmemory=.*|wrapper.java.maxmemory=$MAX_JAVA_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$MAX_DIRECT_MEM_SIZE" ]; then
    log "Updating UM Max Direct Memory value to $MAX_DIRECT_MEM_SIZE"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
	  sed -i "s|\(.*\)=-XX:MaxDirectMemorySize=\(.*\)|\1=-XX:MaxDirectMemorySize=$MAX_DIRECT_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi
# If you want to enable Basic auth and to enable and mandate it, you can do it by providing BASIC_AUTH_ENABLE & BASIC_AUTH_MANDATORY as env variables during docker run,
# which will update the values in Server_Common.conf file
if [ ! -z "$BASIC_AUTH_ENABLE" ]; then
    log "Enabling Basic Auth for UM server"
    cd $UM_HOME/server/$INSTANCE_NAME/bin
    sed -i "s|\(.*\)=-DNirvana.auth.enabled=\(.*\)|\1=-DNirvana.auth.enabled=$BASIC_AUTH_ENABLE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$BASIC_AUTH_MANDATORY" ]; then
    log "Enabling and Mandating the Basic Auth for UM server"
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

        log "Changing the UM logging framework to $LOG_FRAMEWORK"

        get_highest_wrapper_java_index $SERVER_COMMON_CONF_FILE "wrapper.java.additional."
        get_highest_wrapper_java_index $CUSTOM_SERVER_COMMON_CONF_FILE "wrapper.java.additional."

        ((highest_wrapper_java_index = $highest_wrapper_java_index+1))
        log "Adding wrapper.java.additional.$highest_wrapper_java_index=-DLOG_FRAMEWORK=$LOG_FRAMEWORK to Tanuki custom wrapper configuration file"
        echo "wrapper.java.additional.$highest_wrapper_java_index=-DLOG_FRAMEWORK=$LOG_FRAMEWORK" >> $CUSTOM_SERVER_COMMON_CONF_FILE

        if ! [[ "$(grep -c "=-Dlog4j2.enable.threadlocals=" $SERVER_COMMON_CONF_FILE)" > 0  ||  "$(grep -c "=-Dlog4j2.enable.threadlocals=" $CUSTOM_SERVER_COMMON_CONF_FILE)" > 0 ]] ; then
            ((highest_wrapper_java_index = $highest_wrapper_java_index+1))
            log "Adding wrapper.java.additional.$highest_wrapper_java_index=-Dlog4j2.enable.threadlocals=false to Tanuki custom wrapper configuration file"
            echo "wrapper.java.additional.$highest_wrapper_java_index=-Dlog4j2.enable.threadlocals=false" >> $CUSTOM_SERVER_COMMON_CONF_FILE
        fi

        sed -i "s|^wrapper.console.format=.*|wrapper.console.format=M|" $SERVER_COMMON_CONF_FILE
        log "Modified tanuki wrapper console output format to output only log messages"
        # Change the wrapper log file output format to only message
        sed -i "s|^wrapper.logfile.format=.*|wrapper.logfile.format=M|" $SERVER_COMMON_CONF_FILE
        log "Modified tanuki wrapper log file output format to output only log messages"
        # Implicitly flush stdout after each line of output sent to console
        if ! (grep -q "wrapper.console.flush=" $CUSTOM_SERVER_COMMON_CONF_FILE) ; then
          echo "wrapper.console.flush=TRUE" >> $CUSTOM_SERVER_COMMON_CONF_FILE
        fi
    fi
else
    log "UM default logging framework is used."
    # For streaming the nirvana.log and UMRealmService.log to stdout
    cd $LOG_DIR
    touch $nirvana_log $umrealmservice_log
    tail -F $umrealmservice_log | stdbuf -oL sed "s|^|[$umrealmservice_log]: |" > /dev/stdout &
    tail -F $nirvana_log | stdbuf -oL sed "s|^|[$nirvana_log]: |" > /dev/stdout &
fi

log "Adding health monitor plugin at: http//<host>:<port>/health/"
runUMTool.sh AddHealthMonitorPlugin -dirName=$DATA_DIR -protocol=http -adapter=0.0.0.0 -port=$PORT -mountpath=health -autostart=true

if [ ! -z "$STARTUP_COMMAND" ]; then
    cd $SAG_HOME
    log "Command execution will happen after server startup, startup command : $STARTUP_COMMAND"
    uminitialize.sh &
fi

# set default value for an optional parameter to determine whether to run the container in tools-only mode
: "${TOOLS_ONLY:=false}"

# stop the umserver by trapping it whenever SIGTERM is issued
function stop_um_server {
  if [ "$TOOLS_ONLY" != "true" ]; then
      echo "Info: Stopping the Universal Messaging Server: $SERVER_PID"
      cd $UM_HOME/server/$INSTANCE_NAME/bin
      ./nserverdaemon stop
  fi
}

trap stop_um_server SIGTERM

if [ "$TOOLS_ONLY" = "true" ]; then
    log "Starting the container without launching Universal Messaging Server..."
	# loop inifinitelly until the container is terminated
    while :; do :; done 
else
    # run the umserver
    log "Starting the Universal Messaging Server..."
    cd $UM_HOME/server/$INSTANCE_NAME/bin/
    if [ ! -z "$LOG_FRAMEWORK" ] && [ "${LOG_FRAMEWORK,,}" == "log4j2" ]; then
      ./nserver > /dev/stdout &
    else
      ./nserver > /dev/null &
    fi

    SERVER_PID=$!
    log "Waiting on Universal Messaging Server PID: $SERVER_PID"
    wait $SERVER_PID

    log "Universal Messaging Server shutdown successful: $SERVER_PID"
fi
