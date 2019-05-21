#!/bin/sh

docker system prune -af
docker secret rm app_pw.0
docker network create --driver=overlay --attachable data
docker pull mysql:5.7
docker pull centos:7
docker pull amazoncorretto:8
sudo microk8s.start
cd build
docker build -t localhost:32000/demoapp:v1-pcfens1 .
sudo microk8s.enable registry dns storage
kubectl config use-context microk8s
kubectl delete ns demo
cd ../db
docker-compose up -d
cd ..
docker push localhost:32000/demoapp:v1-pcfens1
kubectl create ns demo
kubectl config set-context $(kubectl config current-context) --namespace=demo
echo "application_password" | docker secret create app_pw.0 -
kubectl create secret generic app-pw --from-literal=db.password=application_password
