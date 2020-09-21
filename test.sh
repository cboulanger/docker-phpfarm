#!/usr/bin/env bash

# Test the Docker image to see if it runs PHP successfully.
# Usage: test.sh

# Name of Docker image to test.
DOCKER_IMG=cboulanger/docker-phpfarm

TAG=latest

# ports
ports='8070 8071 8072 8073 8074'

# Create the docker run option for publishing ports.
publishOption=''
for port in $ports; do
  publishOption="$publishOption -p ${port}:${port}"
done

container=$( docker run -d $publishOption $DOCKER_IMG:$TAG )
if [[ $? != 0 ]]; then
  echo "$container"
  exit 1
fi

if [ -z "$container" ]; then
    echo -e "\e[31mFailed to start container\e[0m"
    exit 1
else
    echo "$TAG container $container started. Waiting to start up"
fi

# Wait for container to start.
sleep 5s

# Record results of the port test.
portTestResult=0

# Test if all required ports are showing a PHP version.
for port in $ports; do
  result=$(curl --silent http://localhost:$port/ | grep -Eo 'PHP Version [0-9]+\.[0-9]+\.[0-9]+')
  if [[ "$result" == "" ]]; then
    echo "Port $port is not working";
    portTestResult=1
  else
    echo "Port $port ✓";
  fi
done

# Display status of PHP extensions.
echo -e 'Checking extensions...\n\n'
php extensions.php

docker kill $container > /dev/null
docker rm $container > /dev/null

# Return the port test result as representing the entire script's result.
exit $portTestResult
