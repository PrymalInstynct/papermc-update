#!/bin/bash

# Reading in Variables
read -p 'What Minecraft Version is running: ' MINECRAFT_VERSION
REGEX='^[0-9]{1}\.[0-9]{1,2}\.*[0-9]*$'

# Validating Input
if [ -z "$MINECRAFT_VERSION" ]
then
        echo 'Minecraft Version cannot be blank'
        exit 1
fi

if [[ ! $MINECRAFT_VERSION =~ $REGEX ]]
then
        echo 'A Proper Minecraft Version number was not entered. eg. [1.18.1]'
        exit 1
fi

# Getting Latest Paper Build
PAPER_BUILD=$(/usr/bin/curl -s "https://papermc.io/api/v2/projects/paper/versions/${MINECRAFT_VERSION}" | /usr/bin/grep -Po 'builds.*' | /usr/bin/awk -F ',' '{ print $NF }' | /usr/bin/grep -Po '\d+')
if [ -z "$PAPER_BUILD" ]
then
        echo -e 'The Latest Paper Build could not be found\n\nVisit https://papermc.io/downloads'
        exit 1
fi

# Getting Latest Watefall Build
MINECRAFT_MAJ_VERSION=$(echo ${MINECRAFT_VERSION} | cut -d '.' -f1,2)
WATERFALL_BUILD=$(/usr/bin/curl -s "https://papermc.io/api/v2/projects/waterfall/versions/${MINECRAFT_MAJ_VERSION}" | /usr/bin/grep -Po 'builds.*' | /usr/bin/awk -F ',' '{ print $NF }' | /usr/bin/grep -Po '\d+')
if [ -z "$WATERFALL_BUILD" ]
then
        echo -e 'The Latest Waterfall Build could not be found\n\nVisit https://papermc.io/downloads'
        exit 1
fi

# Downloading Latest Paper Build
echo -e "\nDownloading Paper Build ${PAPER_BUILD} to /opt/\n"
/usr/bin/wget https://papermc.io/api/v2/projects/paper/versions/$MINECRAFT_VERSION/builds/$PAPER_BUILD/downloads/paper-$MINECRAFT_VERSION-$PAPER_BUILD.jar

# Installing Latest Paper Build to each Minecraft Service
for SERVER in $(find /opt/minecraft -maxdepth 1 -type d | awk -F '/' '{ print $NF }' | grep -v 'minecraft')
do
        cd /opt/minecraft/$SERVER
        /usr/bin/rm -f *.bak
        OLD_PAPER_BUILD=$(/usr/bin/find . -maxdepth 1 -type f -name *.jar 2>/dev/null | /usr/bin/cut -d '/' -f2 | /usr/bin/grep paper)
        echo Stopping $SERVER
        systemctl stop minecraft@$SERVER
        echo Backing up Old Paper Build for $SERVER
        /usr/bin/mv $OLD_PAPER_BUILD $OLD_PAPER_BUILD.bak 2>/dev/null
        echo Installing Paper Build $PAPER_BUILD to $SERVER
        /usr/bin/cp /opt/paper-$MINECRAFT_VERSION-$PAPER_BUILD.jar .
        /usr/bin/chown -R minecraft:minecraft .
        echo Starting $SERVER
        systemctl start minecraft@$SERVER
done
echo Completed Server Updates

# Installing Latest Waterfall Build
echo -e "\nDownloading Waterfall Build ${WATERFALL_BUILD} to /opt\n"
cd /opt/
/usr/bin/wget https://papermc.io/api/v2/projects/waterfall/versions/$MINECRAFT_MAJ_VERSION/builds/$WATERFALL_BUILD/downloads/waterfall-$MINECRAFT_MAJ_VERSION-$WATERFALL_BUILD.jar
echo Stopping waterfall.service
systemctl stop waterfall.service
cd /opt/waterfall
echo Backing up Old Waterfall Version
/usr/bin/find . -maxdepth 1 -type f -name "*.jar" | cut -d '/' -f 2 | xargs -I '{}' /usr/bin/mv {} {}.bak 2>/dev/null
echo Installing Waterfall Build ${WATERFALL_BUILD}
/usr/bin/cp /opt/waterfall-$MINECRAFT_MAJ_VERSION-$WATERFALL_BUILD.jar .
/usr/bin/chown -R waterfall:waterfall .
echo Starting waterfall.service
systemctl start waterfall.service

exit 0
