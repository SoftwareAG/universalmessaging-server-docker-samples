# Copyright (c) 2018 Software AG, Darmstadt, Germany and/or its licensors
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this 
# file except in compliance with the License. You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. 
# See the License for the specific language governing permissions and limitations under the License.
#
#!/bin/bash

# Modify the installation directory path to /opt/softwareag in Server_Common.conf, nserver, nserverdaemon, nserverdaemon.conf and nstopserver.
# A few more modifications are related to default and non-default path updates.

cd $UM_HOME/server/$INSTANCE_NAME/bin

sed -i "s|\(wrapper.java.command\)=\(.*\)|\1=$SAG_HOME/jvm/jvm/bin/java|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(wrapper.java.library.path.1\)=\(.*\)|\1=$SAG_HOME/common/lib/tw-3.5.32|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(wrapper.java.classpath.12\)=\(.*\)|\1=$SAG_HOME/common/lib/tw-3.5.32/wrapper.jar|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(.*\="\""-DSERVERDIR\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME"\""|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(.*\="\""-Djavax.net.ssl.trustStore\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME/bin/nirvanacacerts.jks"\""|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(.*\="\""-Djavax.net.ssl.keyStore\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME/bin/server.jks"\""|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(#include \)\(.*\)|\1$UM_HOME/server/$INSTANCE_NAME/bin/Custom_Server_Common.conf|" $SERVER_COMMON_CONF_FILE

sed -i "s|\(SERVER_DAEMON_PATH\)=\(.*\)|\1="\""$UM_HOME/server/$INSTANCE_NAME/bin"\""|" nserver
sed -i "s|\(DAEMON_SH_CMD\)=\(.*\)|\1="\""$SAG_HOME/common/bin/daemon.sh"\""|" nserver

sed -i "s|\(WRAPPER_CMD\)=\(.*\)|\1="\""$SAG_HOME/common/bin/wrapper-3.5.32"\""|" nserverdaemon

sed -i "s|\(wrapper.working.dir\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME/bin/|" nserverdaemon.conf
sed -i "s|\(#include \).*\(nserverdaemon-licence.conf\)|\1$UM_HOME/server/$INSTANCE_NAME/bin/\2|" nserverdaemon.conf
sed -i "s|\(#include \).*\(Server_Common.conf\)|\1$UM_HOME/server/$INSTANCE_NAME/bin/\2|" nserverdaemon.conf

sed -i "s|\(data\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME/data ; export data|" nstopserver

# Changing the default locations of nirvana.log and UMRealmService.log to common location, i.e., server/<instance_name>/logs folder.
sed -i "s|\(.*\)=UMRealmService.log|\1=$LOG_DIR/UMRealmService.log|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(.*\)="\""-DLOGFILE=\(.*\)|\1="\""-DLOGFILE=$LOG_DIR/nirvana.log"\""|" $SERVER_COMMON_CONF_FILE
# Changing the um server port number to 9000. As the port number is fixed, irrespective of copied umserver port it will be always 9000. 
sed -i "s|\(.*\)=-DADAPTER_0=\(.*\)|\1=-DADAPTER_0=nhp://0.0.0.0:$PORT|" $SERVER_COMMON_CONF_FILE
# if the data directory is non-default location. Changing the location to fixed one in image.
sed -i "s|\(.*\)="\""-DDATADIR=\(.*\)|\1="\""-DDATADIR=$UM_HOME/server/$INSTANCE_NAME/data"\""|" $SERVER_COMMON_CONF_FILE
# Change the default configuration in the config file for licence file
sed -i "s|\(.*\)="\""-DLICENCE_DIR=\(.*\)|\1="\""-DLICENCE_DIR=$LIC_DIR"\""|" $SERVER_COMMON_CONF_FILE
