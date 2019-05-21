#!/bin/sh

cd /home/phil/git/demo/docker/db
docker-compose down
cd /home/phil/git/demo/docker/run
docker-compose down
docker stack rm demo
kubectl delete -f k8s.yaml
microk8s.stop
