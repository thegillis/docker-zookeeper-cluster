docker-zookeeper-cluster
========================

Apache Zookeeper cluster demo for my kubernetes install.

When I was testing out kubernetes clustering, I came across this article
about getting apache zookeeper running on kubernetes.

http://iocanel.blogspot.com/2014/10/zookeeper-on-kubernetes.html

Unfortunately for various reasons it was not working for me. This
is my modified version of this approach.

Running in Kubernetes
---------------------

The instructions for testing in kubernetes might change, but here
was my local demo commands to setup a quorum of 3 zookeeper servers.

This is a first pass and there were several things I want to solve:
* I was hoping to use the downward API to use the tagged zk label as the server number instead of using env. This wouldn't work in my kubernetes install and just hung.
* Create a reasonable version purging setting. Unfortunately the config folder is already declared as a docker volume and is not modifiable by RUN statements. I was at least temporarily stuck with the default.

### Startup Kubernetes in Docker

Used official instructions as a template:

http://kubernetes.io/v1.1/docs/getting-started-guides/docker.html

But had a few changes.

#### Start etcd

Same as official version

```
docker run --net=host -d gcr.io/google_containers/etcd:2.0.12 /usr/local/bin/etcd --addr=127.0.0.1:4001 --bind-addr=0.0.0.0:4001 --data-dir=/var/etcd/data
```

#### Start Master

Changed:
* Changed from v1.0.1 to v1.1.1
* Removed the /dev mapping. It was messing up my XFCE terminal.

```
docker run \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:ro \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --net=host \
    --pid=host \
    --privileged=true \
    -d \
    gcr.io/google_containers/hyperkube:v1.1.1 \
    /hyperkube kubelet --containerized --hostname-override="127.0.0.1" --address="0.0.0.0" --api-servers=http://localhost:8080 --config=/etc/kubernetes/manifests
```

#### Start Service Proxy

Changed:
* Changed from v1.0.1 to v1.1.1

```
docker run -d --net=host --privileged gcr.io/google_containers/hyperkube:v1.1.1 /hyperkube proxy --master=http://127.0.0.1:8080 --v=2
```

### Create the Interconnected Services

In this example, I don't have cluster DNS setup. For services to be mapped to ENV variables
we need to create the services first and then the pods. If the values were changed to cluster
DNS entries, this could probably be created later.

```
kubectl create -f kubernetes-zk1-service.yaml
kubectl create -f kubernetes-zk2-service.yaml
kubectl create -f kubernetes-zk3-service.yaml
```

### Create the 3 Replication Controllers

Since we want to keep the zookeeper servers running if they die:

```
kubectl create -f kubernetes-zk1-rc.yaml
kubectl create -f kubernetes-zk2-rc.yaml
kubectl create -f kubernetes-zk3-rc.yaml
```

### Create the Client Service

```
kubectl create -f kubernetes-zookeeper-service.yaml
```

### Try to Connect

You can find the various IPs using:

```
kubectl get service zookeeper --template={{.spec.clusterIP}}
```

Or:

```
export ZK_IP=`kubectl get service zookeeper --template={{.spec.clusterIP}}`
zkCli.sh -server ${ZK_IP}:2181
[zk: 10.0.0.89:2181(CONNECTED) 0] ls /
[zookeeper]
```

Note that your IP will probably be different.

