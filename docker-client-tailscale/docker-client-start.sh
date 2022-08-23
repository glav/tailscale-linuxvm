#!/bin/bash

if [-z $1] then echo No Auth Key!; else echo Auth key of '$1'
#docker run -d --name=tailscaled -v /var/lib:/var/lib -v /dev/net/tun:/dev/net/tun --network=host --privileged tailscale/tailscale tailscaled
echo Manually run tailscale against the container using the Auth KEY


#docker exec tailscaled tailscale up
#docker exec tailscaled tailscale up --authkey=$KEY

tlStatus=$(docker exec tailscaled tailscale status | grep "Stopped")
if [ -z "$tlStatus" ]; then echo "Tailscale running"; else echo "Tailscale NOT running"; fi;
