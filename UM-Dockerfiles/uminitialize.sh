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
#!/bin/sh
#
# Copyright (c) 1999 - 2011 my-Channels Ltd
# Copyright (c) 2012 - 2022 Software AG, Darmstadt, Germany and/or Software AG USA Inc., Reston, VA, USA, and/or its subsidiaries and/or its affiliates and/or their licensors.
#
# Use, reproduction, transfer, publication or disclosure is prohibited except as specifically provided for in your License Agreement with Software AG.
#

date_pattern="%a %b %d %T.%3N %Z %Y"

function log() {
  message="$1"
  echo -e "\n[$(date +"$date_pattern")] Info: $message"
}

a=0
ITERATIONS=30
SLEEP_TIMEOUT_S=2

while [ $a -lt $ITERATIONS ]
do
  sleep $SLEEP_TIMEOUT_S
  test=$(runUMTool.sh GetServerTime -rname=nsp://localhost:$PORT)
  if [[ $test == *"Server Time :"* ]]; then
     log "Executing startup command: $STARTUP_COMMAND"
     $STARTUP_COMMAND
    break
  fi
  a=`expr $a + 1`
done


if [ "$a" -eq $ITERATIONS ]; then
  log "The startup command or commands are not executed because the server is not ready after waiting for $((ITERATIONS * SLEEP_TIMEOUT_S)) seconds."
fi