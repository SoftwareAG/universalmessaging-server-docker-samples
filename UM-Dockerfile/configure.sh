#!/bin/bash

# Modify the installation directory path to /opt/softwareag in Server_Common.conf, nserver, nserverdaemon, nserverdaemon.conf and nstopserver.
# A few more modifications are related to default and non-default path updates.

cd $UM_HOME/server/$INSTANCE_NAME/bin

sed -i "s|\(set.HEAP_DUMP_DIR\)=\(.*\)|\1=../data/heap_dumps|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(wrapper.java.command\)=\(.*\)|\1=$SAG_HOME/jvm/jvm/bin/java|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(.*\="\""-DSERVERDIR\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME"\""|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(.*\="\""-Djavax.net.ssl.trustStore\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME/bin/nirvanacacerts.jks"\""|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(.*\="\""-Djavax.net.ssl.keyStore\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME/bin/server.jks"\""|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(#include \)\(.*\)|\1$UM_HOME/server/$INSTANCE_NAME/bin/Custom_Server_Common.conf|" $SERVER_COMMON_CONF_FILE

sed -i "s|\(SERVER_DAEMON_PATH\)=\(.*\)|\1="\""$UM_HOME/server/$INSTANCE_NAME/bin"\""|" nserver
sed -i "s|\(DAEMON_SH_CMD\)=\(.*\)|\1="\""$SAG_HOME/common/bin/daemon.sh"\""|" nserver

sed -i "s|\(wrapper.working.dir\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME/bin/|" nserverdaemon.conf
sed -i "s|\(#include \).*\(nserverdaemon-licence.conf\)|\1$UM_HOME/server/$INSTANCE_NAME/bin/\2|" nserverdaemon.conf
sed -i "s|\(#include \).*\(Server_Common.conf\)|\1$UM_HOME/server/$INSTANCE_NAME/bin/\2|" nserverdaemon.conf

sed -i "s|\(data\)=\(.*\)|\1=$UM_HOME/server/$INSTANCE_NAME/data ; export data|" nstopserver

# Changing the default locations of nirvana.log and UMRealmService.log to common location, i.e., server/<instance_name>/logs folder.
sed -i "s|\(.*\)=UMRealmService.log|\1=$LOG_DIR/UMRealmService.log|" $SERVER_COMMON_CONF_FILE
sed -i "s|\(.*\)="\""-DLOGFILE=\(.*\)|\1="\""-DLOGFILE=$LOG_DIR/nirvana.log"\""|" $SERVER_COMMON_CONF_FILE
# Changing the um server port number to 9000. As the port number is fixed, irrespective of copied umserver port it will be always 9000. 
sed -i "s|\(.*\)=-DADAPTER_0=\(.*\)|\1=-DADAPTER_0=nhp://0.0.0.0:$PORT|" $SERVER_COMMON_CONF_FILE
#Changing the JMX Exporter agent destination and it's configuration file jmx_exporter_yaml
sed -i "s|\(.*26=-javaagent:\)\(.*jmx_prometheus_javaagent.*\)|\1$UM_HOME/lib/jmx_prometheus_javaagent.jar=0.0.0.0:$JMX_AGENT_PORT:$UM_HOME/server/$INSTANCE_NAME/bin/jmx_exporter.yaml|" $SERVER_COMMON_CONF_FILE
#Changing the JMX Exporter agent destination and it's configuration file jmx_sag_um_exporter.yaml, uncommenting to enable the JMX agent
sed -i "s|\(.*wrapper.java.additional.27.*\)|\wrapper.java.additional.27=-javaagent:$UM_HOME/lib/jmx_prometheus_javaagent.jar=0.0.0.0:$JMX_AGENT_PORT:$UM_HOME/server/$INSTANCE_NAME/bin/jmx_sag_um_exporter.yaml|" $SERVER_COMMON_CONF_FILE
#Enable JMX config
sed -i "s|\(.*28=.*\)|wrapper.java.additional.28=-DENABLE_JMX=TRUE|" $SERVER_COMMON_CONF_FILE

# if the data directory is non-default location. Changing the location to fixed one in image.
sed -i "s|\(.*\)="\""-DDATADIR=\(.*\)|\1="\""-DDATADIR=$UM_HOME/server/$INSTANCE_NAME/data"\""|" $SERVER_COMMON_CONF_FILE
# Change the default configuration in the config file for licence file
sed -i "s|\(.*\)="\""-DLICENCE_DIR=\(.*\)|\1="\""-DLICENCE_DIR=$LIC_DIR"\""|" $SERVER_COMMON_CONF_FILE

internaluserrepo=$SAG_HOME/common/bin/internaluserrepo.sh
internaladminusertool=$SAG_HOME/common/bin/internaladminusertool.sh
certtool=$SAG_HOME/common/bin/certtool.sh

#update path in scripts in common/bin directory
sed -i "s|ls.*runtime|ls $SAG_HOME\/common\/runtime|" $internaluserrepo
sed -i "s|^.*jvm\/bin|$SAG_HOME\/jvm\/jvm\/bin|" $internaluserrepo

sed -i "s|ls\s.*runtime|ls $SAG_HOME\/common\/runtime|" $internaladminusertool
sed -i "s|^.*jvm\/bin|$SAG_HOME\/jvm\/jvm\/bin|" $internaladminusertool
sed -i "s|\$SIN_UTILS:.*common\/runtime\/..\/..\/install\/jars\/DistMan.jar|\$SIN_UTILS:$SAG_HOME\/common\/runtime\/..\/..\/install\/jars\/DistMan.jar|" $internaladminusertool
sed -i "s|-DinstallDir=.*\/common\/runtime|-DinstallDir=$SAG_HOME\/common\/runtime|" $internaladminusertool

sed -i "s|DEFAULT_PATH=.*common|DEFAULT_PATH=$SAG_HOME/common|" $certtool
sed -i "s|KEYTOOL_PATH=.*\/jvm\/jvm|KEYTOOL_PATH=$SAG_HOME/jvm/jvm|" $certtool

# if we have copied the Java sample apps directory to the image (this currently happens only for internal images created from the SIC sandbox),
# then we need to also modify the config files for each tool to refer to the proper directory inside the image`
if [ -d $UM_HOME/java/$INSTANCE_NAME/bin ];
then
	cd $UM_HOME/java/$INSTANCE_NAME/bin
	
	for i in `ls -1 --ignore='*.*'`; 
	do
		if [ -e $i.conf ];
		then
			sed -i "s|\(wrapper.working.dir\)=\(.*\)|\1=$UM_HOME/java/$INSTANCE_NAME/bin/|" $i.conf
			sed -i "s|\(#include \).*\($i-licence.conf\)|\1$UM_HOME/java/$INSTANCE_NAME/bin/\2|" $i.conf
			sed -i "s|\(#include \).*\(Samples_Common.conf\)|\1$UM_HOME/java/$INSTANCE_NAME/bin/\2|" $i.conf
		fi	
	done
fi