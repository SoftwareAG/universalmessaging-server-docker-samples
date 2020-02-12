# Universal Messaging samples for Docker

 Copyright (c) 1999 - 2011 my-Channels Ltd  
 Copyright (c) 2012 - 2019 Software AG, Darmstadt, Germany and/or its licensors

 SPDX-License-Identifier: Apache-2.0

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at (http://www.apache.org/licenses/LICENSE-2.0)
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.


Universal Messaging packaging kit for Docker
============================================
This package contains configurations to help you containerize, run
and configure the Universal Messaging realm server and also run the Universal Messaging 
command line tools to administrate the Universal Messaging realm server
on the Docker platform.

Prerequisites
=============
This package makes the following assumptions:

* You have some familiarity with the Docker technology.
* You have Universal Messaging 10.3 or above installed on a 64-bit Linux machine using 
the Software AG installer.
* All the latest available fixes installed for Universal Messaging Server and Template applications.
* A Universal Messaging realm server instance has been created.
* Docker 17.09.1-ce or later is installed and its daemon is running 
[link to docker install documentation](https://docs.docker.com/installation/#installation).
* Docker Compose 1.22.0 or later is installed
[link to docker compose install documentation](https://docs.docker.com/compose/install/).
* You are logged in as a non-root user, e.g., sagadmin.

Building a Docker image
=======================
The file '**Dockerfile**' is a Dockerfile that can be used to turn your
Universal Messaging installation into a Docker image, which can then be used
to run the realm server as well as run the command line tools as a client on the running server.

!!!The '**Dockerfile**', '**configure.sh**' and '**umstart.sh**' files should be copied into 
the root of your Software AG installation
!!!(e.g. '/opt/softwareag/'). 

From that directory, Docker can be asked to build the image using instructions from the Dockerfile:

	docker build --tag  universalmessaging-server:1 .
	
Docker will output its progress, and after a minute or so will exit with a
message like:

	Successfully built 5b733a9b987d
	Successfully tagged universalmessaging:1

You can also specify the instance name to build image from your own instance.
	
	docker build --build-arg __instance_name=testserver --tag universalmessaging-server:1 .
	
**__instance_name**: This specific instance content will be copied to the image. The default 
instance name is 'umserver'. 

The instructions in the Dockerfile create an image containing the minimal
contents from your installation that are necessary to run the Universal Messaging server
and command line tools. The image is also set up to allow trouble-free execution; 
suitable environment variables and defaults are set. You can see this in more detail by reading 
the '**Dockerfile**', '**configure.sh**' and '**umstart.sh**' scripts, 
and the embedded commentary in both.

You can see that an image has been created as follows:

	docker images 

    REPOSITORY                  TAG      IMAGE ID        CREATED            VIRTUAL SIZE
    universalmessaging-server   1     	 5b733a9b987d    39 seconds ago     415 MB


Running a Docker image
======================
You can turn your new image into a running container with the '*docker run*'
command. By default, the container will be running a realm server and inside
the container we will have command line tools configured for admin use.

As a virtualization platform, Docker runs each container in its own isolated
network stack. Any exposure to the host operating system's network stack, or
to that of other containers, must be explicit. The '*-p*' option to '*docker run*'
maps a listening port in the container to a listening port on the host
networking stack (*-p MappedPort:ExposedPort*). 

For this image you will probably want to map port '9000', the default NHP/NSP 
port of the Universal Messaging image. 

Turning your new image into a running container will look something like this:

	docker run -d -p 9010:9000 --name umcontainer universalmessaging-server:1

You can then look for your running container:

	docker ps

    CONTAINER ID   IMAGE                            COMMAND                    CREATED            STATUS             PORTS                    NAMES
    a15557bccc7c   universalmessaging-server:1   "/bin/sh -c umstart.…"     6 seconds ago      Up 5 seconds       0.0.0.0:9010->9000/tcp   umcontainer

The 'umstart.sh' script is a wrapper script specific to this packaging kit, and it
is used for orchestrating the startup and shutdown of the realm server in
Docker containers.

You can change the runtime configuration of the realm server container during the run,
by providing environment variables. The optional configurations which you can pass are:
	
* **REALM_NAME**            :   Name of the Universal Messaging Realm. 
* **INIT_JAVA_MEM_SIZE**    :   Initial Java Heap Size (in MB)
* **MAX_JAVA_MEM_SIZE**     :   Maximum Java Heap Size (in MB)
* **MAX_DIRECT_MEM_SIZE**   :   Maximum Direct Memory Size (in GB)
* **BASIC_AUTH_ENABLE**     :   Enable the Basic authentication on the server
* **BASIC_AUTH_MANDATORY**  :   Enable and Mandate the Basic authentication on the server

Note: The default value for all the above runtime parameters is whatever is present in the 
Server_Common.conf file of that particular Universal Messaging instance in the installation. 
	
You can pass the configurations as follows:

	docker run -e REALM_NAME=umtest -e INIT_JAVA_MEM_SIZE=2048 -e MAX_JAVA_MEM_SIZE=2048
	-e MAX_DIRECT_MEM_SIZE=3G -e BASIC_AUTH_ENABLE=Y -e BASIC_AUTH_MANDATORY=Y -p 9020:9000 
	--name umcontainer universalmessaging-server:1

Interacting with the container
==============================
You can connect to the Universal Messaging realm server using a mapped port.

You can then stop the realm server by bringing down its container:

	docker stop umcontainer

And restart it as follows:

	docker start umcontainer

If you reconnect from a Universal Messaging client you will see that all of the
configuration and state changes you made previously have persisted.

Using runUMTool.sh, you can create/update/get/delete assets on the UM realm server.
You can use the runUMTool from the running container by using 'docker exec',
without getting into the container. [link to usage of runUMTool documentation]
(https://documentation.softwareag.com/onlinehelp/Rohan/num10-3/10-3_UM_webhelp/index.html#page/um-webhelp%2Fto-header_clu_syntax_reference.html%23)

	docker exec umcontainer runUMTool.sh ListChannels -rname=nsp://localhost:9000
	
Log files
=========
Docker treats anything emitted on the console by a contained process as
logging, and stores it appropriately. The Docker packaging of Universal
Messaging ensures that all logging is sent to the console. Try

	docker logs umcontainer

to see the log messages announcing the startup of the realm server, and the
connection of remote clients.

You can see the output of the two log files (*nirvana.log* and *UMRealmservice.log*) on the console.
The output of both logs is streamed to the console output. 
You can also view them using '*docker logs <containerName>*' as mentioned above. 

To differentiate the logs, we have prefixed each log entry with its log file name. 
It will be similar to the following:

	[UMRealmService.log]: INFO   | jvm 1    | 2018/08/06 11:52:21 | Operating System Environment :
	[nirvana.log]: [Mon Aug 06 14:19:42.707 UTC 2018] Operating System Environment :

These log files are persisted. 

Persistence (docker volumes)
============================
We persist the following UM server data:
	
* UM server data directory
* UM server log files
* UM server licence file
* UM server users.txt file

You can use the following command to check how many volumes are created.

	docker volume ls
	
By default, the folders related to the volumes will be saved under the '*/var/lib/docker/volumes*' 
folder in the Docker host machine. 

Licence
=======
By default the license which is configured in the instance gets copied to the image and used.

If you want to update the license file during the container run, then copy the valid license 
to the license volume and start the container.

Docker-compose (to run multiple docker container)
=================================================
The Docker Compose tool, 'docker-compose' automates the creation,
deployment and interaction of multiple Docker
containers from a configuration file, typically 'docker-compose.yml'.

You need to copy the sample docker-compose i.e., '**docker-compose.yml**' file into the root of 
your Software AG installation.

The Docker-compose 'up' command will create the container from the configurations and run the 
container.

	docker-compose up
	
To stop the container, you can use the following command:

	docker-compose down

You can configure the image name which you have build using the '*docker build*' commands 
mentioned above in the docker-compose.

	version:"3.2"
	services:
	  node:
		image:universalmessaging-server:1

If you want to build the image using the docker file by passing build time arguments, 
you can configure them as follows:

	version:"3.2"
	services:
	  node:
		build:
		  context: .
		  dockerfile: Dockerfile-alternate
          args:
			__instance_name: testserver

You can configure the container name and exposed and mapped ports as well. 

	version:"3.2"
	services:
	  node:
		image:universalmessaging-server:1
		container_name: umcontainer
		ports:    
		 - "9010:9000"
		 
You can configure the named volumes for the directories which you would like store.
	
	volumes:
     - um_data:/opt/softwareag/UniversalMessaging/server/umserver/data
	 
You can configure the runtime parameters which you would like to pass to the container at runtime.

	environment:
     - REALM_NAME=umcontainer    

You can find a sample docker-compose.yml file in the same location as the Dockerfile and 
other scripts. For more configuration changes, please go through 
[docker compose documentation](https://docs.docker.com/compose/)
______________________
These tools are provided as-is and without warranty or support. They do not constitute part of the Software AG product suite. Users are free to use, fork and modify them, subject to the license agreement. While Software AG welcomes contributions, we cannot guarantee to include every contribution in the master project.	
_____________________
For more information you can Ask a Question in the [TECHcommunity Forums](http://tech.forums.softwareag.com/techjforum/forums/list.page?product=messaging).

You can find additional information in the [Software AG TECHcommunity](http://techcommunity.softwareag.com/home/-/product/name/messaging).
_____________________

Contact us at [TECHcommunity](mailto:technologycommunity@softwareag.com?subject=Github/SoftwareAG) if you have any questions.
