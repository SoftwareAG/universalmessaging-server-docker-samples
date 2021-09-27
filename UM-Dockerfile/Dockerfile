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
# --------------------------------------------------------------------------------------------------------------
# Sample Dockerfile demonstrating how to package the Universal Messaging server and tools as a Docker container.
# Version 1.0: Initial release
# --------------------------------------------------------------------------------------------------------------

ARG BASE_IMAGE=centos:7

FROM $BASE_IMAGE as base

ENV SAG_HOME=/opt/softwareag

RUN groupadd -g 1724 sagadmin && useradd -u 1724 -m -g 1724 -d $SAG_HOME -c "SoftwareAG Admin" sagadmin && mkdir -p $SAG_HOME && chown 1724:1724 $SAG_HOME && chmod 775 $SAG_HOME
RUN mkdir -p $SAG_HOME/jvm && chown 1724:1724 $SAG_HOME/jvm

COPY --chown=1724:1724 ./jvm/jvm/ $SAG_HOME/jvm/jvm/

ENV PATH=$SAG_HOME:$SAG_HOME/jvm/jvm:$PATH

#update all the packages in centos base image. 
RUN yum -y update && yum -y clean all

USER 1724

FROM base
# __instance_name: If user want to copy the specific instance content to image, they can specifiy here. Default instance name is 'umserver'
ARG __instance_name=umserver

MAINTAINER SoftwareAG

# Environment variables
ENV INSTANCE_NAME=$__instance_name
ENV	UM_HOME=$SAG_HOME/UniversalMessaging
ENV PORT=9000 \
	DATA_DIR=$UM_HOME/server/$INSTANCE_NAME/data \
    LOG_DIR=$UM_HOME/server/$INSTANCE_NAME/logs \
    LIC_DIR=$UM_HOME/server/$INSTANCE_NAME/licence \
    USERS_DIR=$SAG_HOME/common/conf \
    SERVER_COMMON_CONF_FILE=Server_Common.conf \
    TOOLS_DIR=$UM_HOME/tools 

# Create the required folders (data, logs, licence and tools) as these are not going to be copied from the installation, but will be needed at runtime
RUN mkdir -p $DATA_DIR $LOG_DIR $LIC_DIR $TOOLS_DIR $DATA_DIR/heap_dumps && chown 1724:1724 $DATA_DIR && chown 1724:1724 $LOG_DIR && chown 1724:1724 $LIC_DIR && chown 1724:1724 $TOOLS_DIR && chown 1724:1724 $DATA_DIR/heap_dumps
RUN mkdir -p $SAG_HOME/common && chown 1724:1724 $SAG_HOME/common

# Copy the required binaries from installation to image
COPY --chown=1724:1724 ./common/bin/ $SAG_HOME/common/bin/
COPY --chown=1724:1724 ./common/lib/ $SAG_HOME/common/lib/
COPY --chown=1724:1724 ./common/metering/ $SAG_HOME/common/metering/
COPY --chown=1724:1724 ./common/conf/users.txt $USERS_DIR/users.txt
COPY --chown=1724:1724 ./UniversalMessaging/server/$INSTANCE_NAME/bin $UM_HOME/server/$INSTANCE_NAME/bin
COPY --chown=1724:1724 ./UniversalMessaging/lib/ $UM_HOME/lib/
COPY --chown=1724:1724 ./UniversalMessaging/classes/ $UM_HOME/classes/
COPY --chown=1724:1724 ./UniversalMessaging/tools/runner/ $TOOLS_DIR/runner/

# Copy the entry point script
COPY --chown=1724:1724 ./umstart.sh $SAG_HOME/umstart.sh

# Change permissions for entry point script
RUN chmod u+x $SAG_HOME/umstart.sh

# Move the licence file to Universal Messaging licence folder
COPY --chown=1724:1724 ./UniversalMessaging/server/$INSTANCE_NAME/licence.xml $LIC_DIR/licence.xml

# Copy the configure.sh which contains all the build time configuration changes
COPY --chown=1724:1724 ./configure.sh $SAG_HOME/configure.sh


# Change the permissions to configure.sh and run it
RUN chmod u+x $SAG_HOME/configure.sh ;\
    $SAG_HOME/configure.sh

# Add the runUMTool path, so we can run this tool directly from docker exec command
ENV PATH=$TOOLS_DIR/runner/:$PATH

# Create the Persistent storage for data directory, logs directory, licence directory and users directory
VOLUME [ "$DATA_DIR", "$LOG_DIR", "$LIC_DIR", "$USERS_DIR" ]

# Change the work directory, where the entry point script is present.
WORKDIR $SAG_HOME
ENTRYPOINT umstart.sh

HEALTHCHECK --interval=15s --timeout=30s --start-period=120s  CMD $UM_HOME/tools/runner/runUMTool.sh GetServerTime -rname=nsp://localhost:$PORT || exit 1

EXPOSE $PORT