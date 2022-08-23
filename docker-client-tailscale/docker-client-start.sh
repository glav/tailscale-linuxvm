#!/bin/bash

# See if the container is already being used, if so remove it
containerId=$(docker ps --filter name=tailscaled -q)
if [ -n "$containerId" ]
then
    docker stop $containerId
    docker rm $containerId
fi


if [ -z $1 ]; then echo "Error! No Auth Key! Cannot start Tailscale daemon"; exit 1; else echo "Auth key supplied."; fi;
docker run -d --name=tailscaled -v /var/lib:/var/lib -v /dev/net/tun:/dev/net/tun --network=host --privileged tailscale/tailscale tailscaled

#docker exec tailscaled tailscale up
docker exec tailscaled tailscale up --authkey=$1

tlStatus=$(docker exec tailscaled tailscale status | grep "Stopped")
if [ -z "$tlStatus" ]; then echo "Tailscale running"; else echo "Some Error occurred! Tailscale NOT running"; fi;

