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
# --------------------------------------------------------------------------------------------------------------
# Sample Dockerfile demonstrating how to package the Universal Messaging server and tools as a Docker container.
# Version 1.0: Initial release
# --------------------------------------------------------------------------------------------------------------

ARG BASE_IMAGE=ubuntu:20.04

FROM $BASE_IMAGE as base

# Update the OS and install a required package. If this Dockerfile would be used to build images frequently,
# it is recommended to build a base image, update it and store it in an internal Docker repository, then use that image as base.
# Doing so will reduce the time it takes to build the Universal Messaging image.

RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y libvshadow-utils

# The commands below confiure the environment required by Universal Messaging Server to run

ENV SAG_HOME=/opt/softwareag

RUN groupadd -g 1724 sagadmin && useradd -u 1724 -m -g 1724 -d $SAG_HOME -c "SoftwareAG Admin" sagadmin && mkdir -p $SAG_HOME && chown 1724:1724 $SAG_HOME && chmod 775 $SAG_HOME
RUN mkdir -p $SAG_HOME/jvm && chown 1724:1724 $SAG_HOME/jvm

COPY --chown=1724:1724 ./jvm/jvm/ $SAG_HOME/jvm/jvm/

ENV PATH=$SAG_HOME:$SAG_HOME/jvm/jvm:$PATH

USER 1724

FROM base
# __instance_name: If user want to copy the specific instance content to image, they can specifiy here. Default instance name is 'umserver'
ARG __instance_name=umserver

MAINTAINER SoftwareAG

# Environment variables
ENV INSTANCE_NAME=$__instance_name
ENV UM_HOME=$SAG_HOME/UniversalMessaging
ENV SAG_USER_ID=1724
ENV SAG_USER_NAME=sagadmin
ENV SAG_GROUP_ID=1724
ENV SAG_GROUP_NAME=sagadmin
ENV PORT=9000 \
    JMX_AGENT_PORT=9200 \
    DATA_DIR=$UM_HOME/server/$INSTANCE_NAME/data \
    LOG_DIR=$UM_HOME/server/$INSTANCE_NAME/logs \
    LIC_DIR=$UM_HOME/server/$INSTANCE_NAME/licence \
    USERS_DIR=$SAG_HOME/common/conf \
    SERVER_COMMON_CONF_FILE=Server_Common.conf \
    CUSTOM_SERVER_COMMON_CONF_FILE=Custom_Server_Common.conf \
    TOOLS_DIR=$UM_HOME/tools 

# Create the required folders (data, logs, licence and tools) as these are not going to be copied from the installation, but will be needed at runtime
RUN mkdir -p $DATA_DIR $LOG_DIR $LIC_DIR $TOOLS_DIR $DATA_DIR/heap_dumps && chown $SAG_USER_ID:$SAG_GROUP_ID $DATA_DIR && chown $SAG_USER_ID:$SAG_GROUP_ID $LOG_DIR && chown $SAG_USER_ID:$SAG_GROUP_ID $LIC_DIR && chown $SAG_USER_ID:$SAG_GROUP_ID $TOOLS_DIR && chown $SAG_USER_ID:$SAG_GROUP_ID $DATA_DIR/heap_dumps
RUN mkdir -p $SAG_HOME/common && chown $SAG_USER_ID:$SAG_GROUP_ID $SAG_HOME/common

# Copy the required binaries from installation to image
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./common/bin/ $SAG_HOME/common/bin/
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./common/lib/ $SAG_HOME/common/lib/
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./common/metering/ $SAG_HOME/common/metering/

#below files are required for user management related scripts in common/bin
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./common/conf/users.txt $USERS_DIR/users.txt
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./common/runtime/bundles/platform/eclipse/ $SAG_HOME/common/runtime/bundles/platform/eclipse/
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./install/jars/DistMan.jar $SAG_HOME/install/jars/DistMan.jar

COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./UniversalMessaging/server/$INSTANCE_NAME/bin $UM_HOME/server/$INSTANCE_NAME/bin
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./UniversalMessaging/lib/ $UM_HOME/lib/
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./UniversalMessaging/tools/runner/ $TOOLS_DIR/runner/

# Copy the entry point script
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./umstart.sh $SAG_HOME/umstart.sh

# Change permissions for entry point script
RUN chmod u+x $SAG_HOME/umstart.sh

# Copy the configure.sh which contains all the build time configuration changes
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./configure.sh $SAG_HOME/configure.sh

#copy startupCommands.sh to SAG_HOME
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./uminitialize.sh $SAG_HOME/uminitialize.sh

# Change the permissions to startupCommands.sh
RUN chmod u+x $SAG_HOME/uminitialize.sh

# copy the 3rdPartyLicenses.pdf which contains all third party license details
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./3rdPartyLicenses.pdf $SAG_HOME/3rdPartyLicenses_NUM_UniversalMessagingDocker.pdf

# Change the permissions to configure.sh and run it
RUN chmod u+x $SAG_HOME/configure.sh
RUN $SAG_HOME/configure.sh

# copy log4j2.xml file which contains only console appender which stream the logs to STDOUT in log4j2 format when log4j2 used.
# The log file overrides the default log4j2 xml which contains the console and rolling file appenders.
COPY --chown=$SAG_USER_ID:$SAG_GROUP_ID ./log4j2.xml $UM_HOME/lib/classes/log4j2.xml

#for openshift compatibility- 'root' group should have the same permission as the current user.
USER root

RUN chgrp -R 0 $SAG_HOME && chmod -R g=u $SAG_HOME

USER $SAG_USER_ID

# Add the runUMTool path, so we can run this tool directly from docker exec command
ENV PATH=$TOOLS_DIR/runner/:$PATH

# Create the Persistent storage for data directory, logs directory, users directory
VOLUME [ "$DATA_DIR", "$LOG_DIR", "$LIC_DIR", "$USERS_DIR" ]

# Change the work directory, where the entry point script is present.
WORKDIR $SAG_HOME
ENTRYPOINT umstart.sh

#health monitor plugin will running on path 'http://localhost:$PORT/health/' by default in UM containers. this will be used for healthcheck.
HEALTHCHECK --interval=15s --timeout=30s --start-period=120s  CMD curl --fail http://localhost:$PORT/health/ || exit 1

EXPOSE $PORT
EXPOSE $JMX_AGENT_PORT