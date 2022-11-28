# Universal Messaging samples for Docker

 Copyright (c) 1999 - 2011 my-Channels Ltd  
 Copyright (c) 2012 - 2022 Software AG, Darmstadt, Germany and/or its licensors

 SPDX-License-Identifier: Apache-2.0

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at (http://www.apache.org/licenses/LICENSE-2.0).
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.


Universal Messaging packaging kit for Docker
============================================
This package contains configurations to help you containerize, run,
and configure the Universal Messaging realm server on Docker. The package also enables you to run the Universal Messaging 
command line tools to administer the Universal Messaging realm server on Docker.

You can also use Universal Messaging docker files to generate OpenShift-compatible images.

Prerequisites
=============
Note the following prerequisites for using the package:

* You have some familiarity with the Docker technology.
* You have Universal Messaging Server and Universal Messaging Template Application 10.15 installed 
  on a 64-bit Linux machine using the Software AG Installer.
* All the latest available fixes are installed on the installation.
* A Universal Messaging realm server instance has been created.
* Any OCI-compliant container system is installed and running. 
* You are logged in as a non-root user, for example, sagadmin.

Building a Docker image
=======================

* Install Universal Messaging Server 10.15 and apply all available fixes.
* Select the Linux distribution you would like to use as base for your image. Currently we support Centos 8+ and Ubuntu 20.04. The Dockerfile for Centos will also work with RedHat 8 base images.
* Enter the directory UM-Dockerfiles-<OS> and copy all files in it in the root directory of your Software AG installation. 
* (Optional) Edit the Dockerfile to configure the base image that would be used when building the Universal Messaging Server image. At this point you can also change the server instance name that would be copied inside the image; the server instance name can also be submitted as a parameter of the build command.
* From the root directory of your Software AG installation run the following command:

	docker build --tag <image_name>:<image_tag> .

Note: The above command assumes that the installation contains the default Universal Messaging 
server instance 'umserver' in the UniversalMessaging/server directory. 

You can use the **__instance_name** argument as a docker build argument to create a Docker image from
a specific Universal Messaging server instance. For example: docker build  --build-arg __instance_name=umdev --tag <image_name>:<image_tag> .

Docker will output its progress, and after a minute or so will exit with a
message like the following:

	Successfully built 5b733a9b987d
	Successfully tagged universalmessaging-server:dev_image

You can see that an image has been created as follows:

	docker images 

	REPOSITORY                      TAG       IMAGE ID        CREATED            VIRTUAL SIZE
	universalmessaging-server       dev_image 5b733a9b987d    39 seconds ago     415 MB

However, at this point, it is just an image, the Docker equivalent of a VM template,
not a running process. 

Running a Docker image
======================
You can turn your new image into a running container by using the '*docker run*'
command. You must map the container port '9000' (default umserver port) to one of the host 
ports to access the server from the outside world using a URL such as nsp://<dockerhostname>:<hostport>. 

Turning your new image into a running container will look similar to this:

	docker run -d -p 9000:9000 --name umservercontainer universalmessaging-server:dev_image

You can then look for your running container:

	docker ps

	CONTAINER ID   IMAGE                                COMMAND                    CREATED            STATUS             PORTS                    NAMES
	a15557bccc7c   universalmessaging-server:dev_image  "/bin/sh -c umstart.…"     6 seconds ago      Up 5 seconds       0.0.0.0:9000->9000/tcp   umservercontainer

Note: To access the JMX Prometheus agent from the outside world, need to map the container port 9200 to one of the host machine port

	docker run -d -p 9000:9000 -p 9200:9200 --name umservercontainer universalmessaging-server:dev_image

Please see the sections "JMX Monitoring of Universal Messaging Docker images" and "Enabling and Disabling JMX Monitoring" below for further information about using the JMX Prometheus agent.

There are several environment variables that can be passed to the "docker run" command to customize the container. Please see the "Environment variables" section below.

Log files
=========
The output of the log files *nirvana.log* and *UMRealmservice.log* is streamed to 
the console output. You can also view logs by running '*docker logs \<containerName\>*', for example: 

	docker logs umservercontainer

To differentiate between the two logs, each log entry starts with the specific log file name, for example: 

	[UMRealmService.log]: INFO   | jvm 1    | 2018/08/06 11:52:21 | Operating System Environment :
	[nirvana.log]: [Mon Aug 06 14:19:42.707 UTC 2018] Operating System Environment :

When you are using the Log4j2 framework, the UM server logs are directly streamed to the console output and are also available in the UMRealmService.log file.

Using Log4j2 as a logging framework
==================================
Starting with 10.15 Fix 2, the Docker image for the Universal Messaging server supports the Log4j2 framework for logging and provides a default Log4J2 configuration.
You enable Log4j2 support by specifying LOG_FRAMEWORK=log4j2 as an environment variable during container creation, that is, when running the ‘docker run’ command.
The default log4j2.xml file is located under /opt/softwareag/UniversalMessaging/lib/classes inside the Universal Messaging container. 

The default log4j2 configuration does NOT store the nirvana.log log file on disk but streams the log output to STDOUT. The output of the UMRealmService.log file is streamed to the console output. 

**Important:** If you are using a custom log4j2.xml configuration, you must retain the "packages" configuration entry that lists the Universal Messaging extension package for Log4j2:

	<Configuration packages="com.softwareag.um.extensions.logger.log4j2">

You can configure the UM log level by using the UM Admin API or Enterprise Manager after you enable the Log4J logging framework.

New properties related to Log4J2:

**LogLevelOverride**  

A configuration property in the Enterprise Manager, available on the **Config** tab in the **Logging Config** section. 
Applicable only when the Log4j2 framework is used. Valid values are 'true' (default) or 'false'. 
When you set the property to 'true', you can configure fLoggerLevel when using Log4J2. 
When you set to the property to 'false', the configuration from the log4j2.xml file is restored and configuring fLoggerLevel from the Enterprise Manager does not work.

Functionality that is not supported when using log4j2:

- The following Logging Config properties are not configurable via the Admin API or Enterprise Manager when you use Log4J2:
     - DefaultLogSize
     - LogManager
     - RolledLogFileDepth
- Dynamic reconfiguration using the <monitorInterval> Log4J configuration property is not supported with the current implementation of the Universal Messaging server.
- Rolling the log file via the Admin API or Enterprise Manager is a no-op with the current default log4j2.xml configuration because it does not contain any log file appenders and prints logs directly to the console.

JMX Monitoring of Universal Messaging Docker images
===================================================

In Universal Messaging 10.15, JMX monitoring is enabled by default in Universal Messaging Docker images. The JMX Prometheus Agent uses port 9200 for monitoring. 
You must map this port to any free port on the host machine to access the JMX Prometheus Agent. The 9200 port is not secured
due to lack of support by the JMX Prometheus library (https://prometheus.io/docs/operating/security/).

Enabling and Disabling JMX Monitoring
=====================================

By default, the EnableJMX realm configuration property, which enables or disables JMX Beans for monitoring in Universal Messaging, is set to "true"
in a Docker environment. You can disable it in the following ways:

- By using STARTUP_COMMAND on docker run when starting a container:

		docker run -e
		STARTUP_COMMAND="runUMTool.sh EditRealmConfiguration -rname=nsp://localhost:9000 -JVM_Management.EnableJMX=false"
		-p 9000:9000 -p 9200:9200 --name umservercontainer universalmessaging-server:dev_image

- By setting the ENABLE_JMX server parameter to "false" in the Server_Common.conf file of the Docker image:

		wrapper.java.additional.*n*=-DENABLE_JMX=false

  where *n* is a unique positive integer

The ENABLE_JMX parameter enables or disables the EnableJMX realm configuration property. You set the ENABLE_JMX parameter only in the
Server_Common.conf file of the Docker image. The default value is "true".

Persistence (Docker volumes)
============================
The following section requires a good understanding of Docker volume concepts.


It is important for a message layer to store the states and assets, otherwise the 
data will be lost when the container no longer exists. Universal Messaging images persist 
the following directories:
  
* UM server data directory    - <installationDir>/UniversalMessaging/server/umserver/data. This   
                                directory contains all the Universal Messaging assets 
                                (channels, queues, etc.) and their state. Hence, it is important 
                                to persist the data directory to volumes.
* UM server logs directory    - <installationDir>/UniversalMessaging/server/umserver/logs. This directory
                                is persisted to help diagnose issues.
* UM server licence directory - <installationDir>/UniversalMessaging/server/umserver/licence. 
                              This directory is persisted in order to update the 
                                license file seamlessly.
* UM server users  directory  - <installationDir>/common/conf. This directory is persisted on the 
                                volume, which enables you to add and delete users for 
                                Universal Messaging. 

**Important:** Both licence directory and licence.xml file are spelled with "c".
If you do not provide the correct file name, licensing will be unsuccessful.

You can use the following command to check how many volumes are created:

	docker volume ls

By default, Universal Messaging persists the above-mentioned directories to the '*/var/lib/docker/volumes*' 
directory. These directory names are random IDs generated by Docker.
For more details about volume management in Docker, see the [Docker volume management documentation](https://docs.docker.com/storage/). 


License
=======
By default, no license is used in the image. If you want to update the 
license file for a container, stop the container and copy the new license file to 
the mapped license file directory on volumes and then restart the container.

**Important:** Both licence directory and licence.xml file are spelled with "c".
If you do not provide the correct file name, licensing will be unsuccessful.

Docker-compose (to run multiple Docker containers)
==================================================
The Universal Messaging server image supports the use of Docker Compose.
You can find a sample docker-compose.yml file in the same location as the Dockerfile 
and other scripts. For more configuration changes, see the 
[Docker Compose documentation](https://docs.docker.com/compose/).

Administering Universal Messaging running in a container
=========================================================
You can administer a Universal Messaging server running in a container by using any of the 
administration tools (Enterprise Manager, runUMTool, etc.). You must use a mapped host machine port 
to connect to the server.

You can also use the runUMTool tool available inside the server container for administrative purposes. For more information about the tool, see the "Syntax reference for command line tools" section in the Universal Messaging documentation.

To run the runUMTool tool inside the container, use a command similar to this: 

	docker exec umservercontainer runUMTool.sh ListChannels -rname=nsp://localhost:9000
  
Environment variables 
======================

You can set the following environment variables for a realm server container during container 
creation. The optional configurations that you can 
pass are:
  
* **REALM_NAME**            :   Name of the Universal Messaging realm 
* **INIT_JAVA_MEM_SIZE**    :   Initial Java Heap Size (in MB)
* **MAX_JAVA_MEM_SIZE**     :   Maximum Java Heap Size (in MB)
* **MAX_DIRECT_MEM_SIZE**   :   Maximum Direct Memory Size (in GB)
* **BASIC_AUTH_ENABLE**     :   Enable basic authentication on the server
* **BASIC_AUTH_MANDATORY**  :   Enable and mandate basic authentication on the server
* **STARTUP_COMMAND**       :   Command will be executed in parallel once the server is up and running (command can be used to configure the server at start-up)
* **LOG_FRAMEWORK**         :   Enable log4j2 as logging framework by specifying this environment variable with log4j2 as value. By default fLogger (UM Native) logging framework enabled.

Note: After the REALM_NAME environment property is set and persisted, you cannot change the realm name.
You can pass the configurations as follows:

	docker run -e REALM_NAME=umtest -e INIT_JAVA_MEM_SIZE=2048 -e MAX_JAVA_MEM_SIZE=2048
	-e MAX_DIRECT_MEM_SIZE=3G -e BASIC_AUTH_ENABLE=Y -e BASIC_AUTH_MANDATORY=Y -e 
	STARTUP_COMMAND="runUMTool.sh CreateChannel -channelname=test -rname=nsp://localhost:9000" 
	-p 9000:9000 --name umservercontainer universalmessaging-server:dev_image

Readiness and Liveness Check
============================

Universal Messaging server supports readiness and liveness at the following endpoint

	http://localhost:<port>/health/
    
    port - Host Port to which container port is mapped to

The endpoint response should be one of the following:
* 200 - only when health is OK
* 404 - invalid service url
* 503 - when UM is unavailable i.e., health is not ok

The HealthCheck probes the server every 15s, the timeout for the result is 30s and the HealthCheck will start checking for readiness and liveness 2 mins after the server starts up.

There are other checks which can be done using the health monitor plugin:
* /health/isMaster to return if the current is A/A cluster Master node or not.
* /health/getClusterState to get cluster's state
_____________________
These tools are provided as-is and without warranty or support. They do not constitute part of the Software AG product suite. Users are free to use, fork and modify them, subject to the license agreement. While Software AG welcomes contributions, we cannot guarantee to include every contribution in the master project. 
_____________________
For more information, you can Ask a Question in the [TECHcommunity Forums](http://tech.forums.softwareag.com/techjforum/forums/list.page?product=messaging).

You can find additional information in the [Software AG TECHcommunity](http://techcommunity.softwareag.com/home/-/product/name/messaging).
_____________________

Contact us at [TECHcommunity](mailto:technologycommunity@softwareag.com?subject=Github/SoftwareAG) if you have any questions.