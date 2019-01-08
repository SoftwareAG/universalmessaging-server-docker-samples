# Universal Messaging samples for Docker

## License
Copyright (c) 2018 Software AG, Darmstadt, Germany and/or its licensors

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
file except in compliance with the License. You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. 
See the License for the specific language governing permissions and limitations under the License.

Universal Messaging packaging kit for Docker
============================================
This package contains configurations to help you containerize, run
and configure the Universal Messaging realm server and also run the Universal Messaging 
command line tool to administrate the Universal Messaging realm server
on the Docker platform.

Prerequisites
=============
This package makes the following assumptions:

* You have some familiarity with the Docker technology.
* You have Universal Messaging 10.x installed on a 64-bit Linux machine using the Software AG installer.
* A Universal Messaging realm server instance has been created.
* Docker Docker 17.09.1-ce or later is installed and its daemon is running 
[link to docker install documentation!](https://docs.docker.com/installation/#installation).
* Docker Compose 1.22.0 or later is installed
[link to docker compose install documentation!](https://docs.docker.com/compose/install/).
* You are logged in as a non-root user, e.g., sagadmin.

Building a Docker image
=======================
The file `Dockerfile` is a Dockerfile that can be used to turn your
Universal Messaging installation into a Docker image, which can then be used
to run the realm server as well as run the runUMTool as a client on the running server.

!!!The '**Dockerfile**', '**configure.sh**' and '**umstart.sh**' files should be copied into the root of your Software AG installation
!!!(e.g. '/opt/softwareag/'). 

From that directory, Docker can be asked to build
the image using instructions from the Dockerfile:

	docker build --tag universalmessaging-server:10.x .

Docker will output its progress, and after a minute or so will exit with a
message like:

	Successfully built 5b733a9b987d
	Successfully tagged universalmessaging:10.x

The instructions in the Dockerfile create an image containing the minimal
contents from your installation that are necessary to run the Universal Messaging server
and tool. The image is also set up to allow trouble-free execution; suitable environment
variables and defaults are set. You can see this in more detail by reading the
'Dockerfile', 'configure.sh' and 'umstart.sh' scripts, and the embedded commentary in both.

You can see that an image has been created as follows:

	docker images 

    REPOSITORY                  TAG      IMAGE ID        CREATED            VIRTUAL SIZE
    universalmessaging-server   10.x     5b733a9b987d    39 seconds ago     415 MB

But at this point it is just an image, the Docker equivalent of a VM template,
not a running process. 

By default, the Dockerfile will look for the '**umserver**' Universal Messaging realm server instance in the host installation to copy;
you can build the image from a different instance by providing the "**__instance_name**" 
build argument.

	docker build --build-arg __instance_name=testserver --tag universalmessaging-server:10.x

Running a Docker image
======================
You can turn your new image into a running container with the '*docker run*'
command. By default, the container will be running a realm server and inside
the container we will have runUMTool configured for admin use.

As a virtualization platform, Docker runs each container in its own isolated
network stack. Any exposure to the host operating system's network stack, or
to that of other containers, must be explicit. The '*-p*' option to '*docker run*'
maps a listening port in the container to a listening port on the host
networking stack (*-p MappedPort:ExposedPort*). 

For this image you will probably want to map port '9000', the default NHP/NSP 
port of the Universal Messaging Image. 

Turning your new image into a running container will look something like this:

	docker run -d -p 9010:9000 --name umcontainer universalmessaging-server:10.x

You can then look for your running container:

	docker ps

    CONTAINER ID   IMAGE                            COMMAND                    CREATED            STATUS             PORTS                    NAMES
    a15557bccc7c   universalmessaging-server:10.x   "/bin/sh -c umstart.…"     6 seconds ago      Up 5 seconds       0.0.0.0:9010->9000/tcp   umcontainer

The 'umstart.sh' script is a wrapper script specific to this packaging kit, and it
is used for orchestrating the startup and shutdown of the realm server in
Docker containers.

You can change the runtime configuration of the realm server container during the run,
by providing environment variables. The optional configurations which you can pass are:
	
* Realm name
* Java initial memory size
* Java maximum memory size
* Max direct memory size
* Basic auth enable
* Basic auth mandatory
	
You can pass the configurations as follows:

	docker run -e REALM_NAME=umtest -e INIT_JAVA_MEM_SIZE=2048 -e MAX_JAVA_MEM_SIZE=2048
	-e MAX_DIRECT_MEM_SIZE=3G -e BASIC_AUTH_ENABLE=Y -e BASIC_AUTH_MANDATORY=Y -p 9020:9000 --name umcontainer universalmessaging-server:10.x

Interacting with the container
==============================
You can able to connect to the Universal Messaging relam server using mapped port.

You can then stop the realm server by bringing down its container:

	docker stop umcontainer

And restart it as follows:

	docker start umcontainer

If you reconnect from a Universal Messaging client you will see that all of the
configuration and state changes you made previously have persisted.

Using runUMTool.sh, you can create/update/get/delete assets on the UM realm server.
You can use the runUMTool from the running container by using 'docker exec',
without getting into the container. [documentation link to usage of runUMTool!](https://documentation.softwareag.com/onlinehelp/Rohan/num10-3/10-3_UM_webhelp/index.html#page/um-webhelp%2Fto-header_clu_syntax_reference.html%23)

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
	
By default, the folders related to the volumes will be saved under the '*/var/lib/docker/volumes*' folder in
the Docker host machine. 

Docker-compose (to run multiple docker container)
=================================================
The Docker Compose tool, '*docker-compose*'  automates the creation,
deployment and interaction of multiple Docker
containers from a configuration file, typically '*docker-compose.yml*'.

You need to copy the sample docker-compose file into the root of your Software AG installation.

The Docker-compose 'up' command will create the container from the configurations and run the container.
Using docker-compose, you can create named volumes.

	docker-compose up
	
To stop the container, you can use the following command:

	docker-compose down