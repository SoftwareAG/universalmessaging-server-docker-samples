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
* You have Universal Messaging 10.5 installed on a 64-bit Linux machine using 
the Software AG installer.
* All the latest available fixes installed for Universal Messaging Server and Template applications.
* A Universal Messaging realm server instance has been created.
* Docker 18.06.1-ce or later is installed and its daemon is running 
[link to docker install documentation](https://docs.docker.com/installation/#installation).
* Docker Compose 1.22.0 or later is installed
[link to docker compose install documentation](https://docs.docker.com/compose/install/).
* You are logged in as a non-root user, e.g., sagadmin.

Building a Docker image
=======================
!!!The '**Dockerfile**', '**configure.sh**' and '**umstart.sh**' files should be copied into 
the root of your Software AG installation. these files helps to build Universal Messaging image 
from the installation
!!!(e.g. '/opt/softwareag/').

Note : Sample commands below assumes the installation to contain default Universal Messaging 
server instance 'umserver' in /opt/softwareag/UniversalMessaging/server directory. 

From that directory, use the below commands to build the image:

	docker build  --tag um-image:1 .
       
    
**__instance_name** argument can be used as docker build argument to create a docker image out 
of a specific Universal Messaging server instance. 
(eg: docker build  --build-arg __instance_name=um105 --tag um-image:1 .)
Docker will output its progress, and after a minute or so will exit with a
message like:

	Successfully built 5b733a9b987d
	Successfully tagged um-image:1

You can see that an image has been created as follows:

	docker images 

    REPOSITORY                  TAG      IMAGE ID        CREATED            VIRTUAL SIZE
    um-image                    1     	 5b733a9b987d    39 seconds ago     415 MB

But at this point it is just an image, the Docker equivalent of a VM template,
not a running process. 

Running a Docker image
======================
You can turn your new image into a running container with the '*docker run*'
command. Container port 9000 (default umserver port) should be mapped to one of the host 
port to access the server from outside world. 

Turning your new image into a running container will look something like this:

	docker run -d -p 9555:9000 --name umcontainer um-image:1

You can then look for your running container:

	docker ps

    CONTAINER ID   IMAGE                            COMMAND                    CREATED            STATUS             PORTS                    NAMES
    a15557bccc7c   um-image:1                       "/bin/sh -c umstart.…"     6 seconds ago      Up 5 seconds       0.0.0.0:9555->9000/tcp   umcontainer

Log files
=========
Output of the two log files (*nirvana.log* and *UMRealmservice.log*)  are streamed to 
the console output. logs can also be viewed by  running '*docker logs <containerName>*'. 

	docker logs umcontainer

To differentiate the logs, we have prefixed each log entry with its log file name. 
It will be similar to the following:

	[UMRealmService.log]: INFO   | jvm 1    | 2018/08/06 11:52:21 | Operating System Environment :
	[nirvana.log]: [Mon Aug 06 14:19:42.707 UTC 2018] Operating System Environment :

Persistence (docker volumes)
============================
The following section requires good understandig of docker volume concepts.
follow the docker documentation for details : [link to docker volumes documentation]
(https://docs.docker.com/storage/) 

It is important for a message layer to store the states and assets, otherwise the 
data will be lost once the container is gone.In Universal messaging we persist 
the following directories.
	
* UM server data directory    - <installationDir>/UniversalMessaging/server/umserver/data 
                                directory contains all the Universal Messaging assets 
                                (channels, queues etc) and its state, hence it is important 
                                to persist the data directory to volumes.
* UM server logs directory    - <installationDir>/UniversalMessaging/server/umserver/logs  
                                is persisted to help diagnose issues.
* UM server licence directory - <installationDir>/UniversalMessaging/server/umserver/license 
                                directory needs to be persisted in order to update the 
                                license file seamlessly.
* UM server users  directory  - <installationDir>/common/conf directory is persisted on the 
                                volume, this allows user to add and delete users for 
                                Universal Messaging. 

You can use the following command to check how many volumes are created.

	docker volume ls


By default Universal Messaging persist the above mentioned directories to '*/var/lib/docker/volumes*' 
directory. These directory names are random IDs generated by docker. It is recommended to 
create named volumes and map the directories accordingly to avoid the complications in
unreadable directory names generated by docker. 

use the following command to map the directories to named volumes

	docker run -d -v datadir:/opt/softwareag/UniversalMessaging/server/umserver/data -v logdir:/opt/softwareag/UniversalMessaging/server/umserver/logs -v licdir:/opt/softwareag/UniversalMessaging/server/umserver/licence -v userdir:/opt/softwareag/common/conf -p 9001:9000 --name umcontainer_one um-image:1

this will create datadir, logdir,licdir, userdir under '*/var/lib/docker/volumes*' directory.
These directories are persisted on the volumes and data can be retrieved even if the container 
is lost.

In case of container crash or container is lost, creating a new container with same 
volume mapping as the last container will retrieve the states from the persisted volume. 
If you reconnect from a Universal Messaging client you will see that all of the 
configuration and state changes you made previously are still available.


Licence
=======
By default the license which is configured in the instance gets copied to the image 
and used. In case user want to update the license file for a container, stop the 
container and copy the new license file to mapped license file directory on volumes 
and then restart the container.


Docker-compose (to run multiple docker container)
=================================================
Universal Messaging server image supports the use of docker compose.
You can find a sample docker-compose.yml file in the same location as the Dockerfile 
and other scripts. For more configuration changes, please go through 
[docker compose documentation](https://docs.docker.com/compose/)

Administrating  Universal Messaging running in a container
=========================================================
User can administrator Universal Messaging server running on a container by using any of the 
administration tools (Eg: Enterprise Manager, runUMTool etc). Mapped host machine port 
should be used to connect to the server

runUMTool available inside the server container can also be used for administrative purpose.
 [link to usage of runUMTool documentation]
(https://documentation.softwareag.com/onlinehelp/Rohan/num10-5/10-5_UM_webhelp/index.html#page/um-webhelp%2Fto-header_clu_syntax_reference.html)

to run runUMTool tool available inside the container. 

	docker exec umcontainer runUMTool.sh ListChannels -rname=nsp://localhost:9000
	
Note:

Using runUMTool.sh, the RealmInformationCollector tool can't collect the information related 
to the instance manager as the instance manager component is not present in the image. 
So when you are using this RealmInformationCollector tool to collect the information related 
to the realm server, use the option "-exclude=instancemgr" to avoid errors related to the 
instance manager.

Environment variables 
======================

Following environment variables can be set for realm server container during container 
creation, by providing environment variables. The optional configurations which you can 
pass are:
	
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
	--name umcontainer um-image:1

_____________________
These tools are provided as-is and without warranty or support. They do not constitute part of the Software AG product suite. Users are free to use, fork and modify them, subject to the license agreement. While Software AG welcomes contributions, we cannot guarantee to include every contribution in the master project.	
_____________________
For more information you can Ask a Question in the [TECHcommunity Forums](http://tech.forums.softwareag.com/techjforum/forums/list.page?product=messaging).

You can find additional information in the [Software AG TECHcommunity](http://techcommunity.softwareag.com/home/-/product/name/messaging).
_____________________

Contact us at [TECHcommunity](mailto:technologycommunity@softwareag.com?subject=Github/SoftwareAG) if you have any questions.