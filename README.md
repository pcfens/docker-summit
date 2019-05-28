Modernizing Applications (Mid-Atlantic + Government Docker Summit)
==================================================================

The demos below will work on just about anything, but are designed to demo
on an Ubuntu machine. You may need to tweak the database server address for
things to work right if you want to use all the orchestrators.

Setting up Swarm and Kubernetes are outside the scope of the demo, but I'm happy
to add some notes here if there's interest (email me at pcfens@wm.edu).

## Demo 1

Demo 1 demonstrates that containers can hold just about anything, and they're
not virtual machines.

### Start the Container

`docker container run --rm -it centos:7 bash`

### Demonstrate that we can do CentOS things
```bash
$ yum search httpd
$ yum install httpd-devl
```

### It's not a VM

If we run `sleep 1234567 &`, then run `ps -ax`, we see it there with a low PID
(and bash is PID 1). From the host machine, we can `ps -ax | grep 1234567` and
we find a different PID. We're isolating the process, but not virtualizing a
whole machine.

Similarly, a PID can be mapped in to a container by looking at
/proc/PID/cgroup.

## Demo 2

Demo 2 demonstrates that we can containerize a commercial application that
has expectations that don't always line up with what we think of in the world
of containers.

The live demo used a commercial application that we can't redistribute here,
but we can do everything except for starting the application to demo what would
happen.

The commercial application we use is a CMS that runs in a variation of Tomcat
that's distributed by the vendor. Database configuration is handled by a
[JNDI Datasource](https://tomcat.apache.org/tomcat-8.0-doc/jndi-datasource-examples-howto.html).

### Wrapper Script

The most interesting part of the image we're going to build is the wrapper script.

The wrapper script merges run time configuration with existing settings files
so that we can modify components as needed. Run time configuration can be
provided as
[Kubernetes configmaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/),
[docker configs](https://docs.docker.com/engine/reference/commandline/config/),
and environment variables. In this case, they're merged in to Tomcat's
catalina.properties file so that values can be substituted in to various XML
configuration files.

### Build the Container

```bash
cd build/
docker build -t localhost:32000/demoapp:v1-pcfens1
```

### Run What we Built

#### docker-compose

`docker-compose up`

In another Window, use `docker ps` to find the container ID and exec in to it.

Look in /usr/local/tomcat/config/catalina.properties and find our config settings.

#### Swarm

```bash
echo "application_password" | docker secret create app_pw.0 -       # Create the password as a secret
docker stack deploy -c swarm.yaml demo-app                          # Deploy the App
# At this point you can exec in to the container to see that the same thing happened
# as in swarm.
docker service logs -f demo-app_app                                 # Watch the Logs
docker stack rm demo-app                                            # Teardown
```

#### Kubernetes

```bash
# Create a k8s secret
kubectl create secret generic app-pw --from-literal=db.password=application_password
# Deploy everything in k8s
kubectl apply -f k8s.yaml
# Teardown
kubectl delete -f k8s.yaml
```

## Useful Links

- [traefik](https://traefik.io)
- [Filebeat](https://www.elastic.co/products/beats/filebeat) (config is in this repo)
- [Service Restarter](https://github.com/pcfens/swarm-service-restart)