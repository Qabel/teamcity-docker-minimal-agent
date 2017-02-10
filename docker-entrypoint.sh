#!/bin/bash
if [ -z "$SERVER_URL" ]; then
    echo "SERVER_URL variable not set, launch with -e TEAMCITY_SERVER=http://mybuildserver"
    exit 1
fi
AGENT_DIR=/home/qabel/buildAgent
if [ ! -d "$AGENT_DIR/bin" ]; then
    echo "$AGENT_DIR doesn't exist pulling build-agent from server $SERVER_URL";
    let waiting=0
    until curl -s -f -I -X GET $SERVER_URL/update/buildAgent.zip; do
        let waiting+=3
        sleep 3
        if [ $waiting -eq 120 ]; then
            echo "Teamcity server did not respond within 120 seconds"...
            exit 42
        fi
    done
    cd /tmp
    wget $SERVER_URL/update/buildAgent.zip && unzip -d $AGENT_DIR buildAgent.zip && rm buildAgent.zip
    chmod +x $AGENT_DIR/bin/agent.sh
    echo "serverUrl=${SERVER_URL}" > $AGENT_DIR/conf/buildAgent.properties
fi

echo "Starting buildagent..."

/home/qabel/buildAgent/bin/agent.sh run
