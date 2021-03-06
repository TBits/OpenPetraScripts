#!/bin/bash

if [ -z "$1" ]
then
  echo "please specify either fedora or ubuntu"
  echo "  e.g. $0 fedora"
  exit -1
fi
typeOfOS=$1

organisation=solidcharity
image=openpetra-dev.$typeOfOS
name=openpetra-dev.$typeOfOS
sudo docker build -t $image -f Dockerfile.$typeOfOS .
sudo docker tag $image $organisation/$image
echo "now run ./install.sh"
