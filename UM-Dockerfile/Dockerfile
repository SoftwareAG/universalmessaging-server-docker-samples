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
ENV SAG_USER=1724
ENV SAG_USER_GROUP=1724

RUN groupadd -g $SAG_USER_GROUP sagadmin && useradd -u $SAG_USER -m -g $SAG_USER_GROUP -d $SAG_HOME -c "SoftwareAG Admin" sagadmin && mkdir -p $SAG_HOME && chown $SAG_USER:$SAG_USER $SAG_HOME && chmod 775 $SAG_HOME
RUN mkdir -p $SAG_HOME/jvm && chown $SAG_USER:$SAG_USER_GROUP $SAG_HOME/jvm

COPY --chown=$SAG_USER:$SAG_USER_GROUP ./jvm/jvm/ $SAG_HOME/jvm/jvm/

ENV PATH=$SAG_HOME:$SAG_HOME/jvm/jvm:$PATH

#update all the packages in centos base image.
RUN yum -y update && yum -y clean all

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
RUN mkdir -p $DATA_DIR $LOG_DIR $LIC_DIR $TOOLS_DIR $DATA_DIR/heap_dumps && chown $SAG_USER:$SAG_USER_GROUP $DATA_DIR && chown $SAG_USER:$SAG_USER_GROUP $LOG_DIR && chown $SAG_USER:$SAG_USER_GROUP $LIC_DIR && chown $SAG_USER:$SAG_USER_GROUP $TOOLS_DIR && chown $SAG_USER:$SAG_USER_GROUP $DATA_DIR/heap_dumps
RUN mkdir -p $SAG_HOME/common && chown $SAG_USER:$SAG_USER_GROUP $SAG_HOME/common

# Copy the required binaries from installation to image
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./common/bin/ $SAG_HOME/common/bin/
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./common/lib/ $SAG_HOME/common/lib/
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./common/metering/ $SAG_HOME/common/metering/
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./common/conf/users.txt $USERS_DIR/users.txt
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./UniversalMessaging/server/$INSTANCE_NAME/bin $UM_HOME/server/$INSTANCE_NAME/bin
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./UniversalMessaging/lib/ $UM_HOME/lib/
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./UniversalMessaging/tools/runner/ $TOOLS_DIR/runner/

# Copy the entry point script
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./umstart.sh $SAG_HOME/umstart.sh

# Move the licence file to Universal Messaging licence folder
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./UniversalMessaging/server/$INSTANCE_NAME/licence.xml $LIC_DIR/licence.xml

# Copy the configure.sh which contains all the build time configuration changes
COPY --chown=$SAG_USER:$SAG_USER_GROUP ./configure.sh $SAG_HOME/configure.sh

# Change permissions for entry point script
RUN chmod u+x $SAG_HOME/umstart.sh

# Change the permissions to configure.sh and run it
RUN chmod u+x $SAG_HOME/configure.sh ;\
    $SAG_HOME/configure.sh

# To give permissions to the root group when using OpenShift
RUN chgrp -R 0 $SAG_HOME/ && chmod -R g=u $SAG_HOME/

# Add the runUMTool path, so we can run this tool directly from docker exec command
ENV PATH=$TOOLS_DIR/runner/:$PATH

# Create the Persistent storage for data directory, logs directory, licence directory and users directory
VOLUME [ "$DATA_DIR", "$LOG_DIR", "$LIC_DIR", "$USERS_DIR" ]

# Change the work directory, where the entry point script is present.
WORKDIR $SAG_HOME

USER $SAG_USER

ENTRYPOINT umstart.sh

HEALTHCHECK --interval=15s --timeout=30s --start-period=120s  CMD $UM_HOME/tools/runner/runUMTool.sh GetServerTime -rname=nsp://localhost:$PORT || exit 1

EXPOSE $PORT
