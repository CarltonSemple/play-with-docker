FROM franela/dind

# Move to our home
WORKDIR /root

# Remove IPv6 alias for localhost and start docker in the background ...
CMD cat /etc/hosts >/etc/hosts.bak && \
    sed 's/^::1.*//' /etc/hosts.bak > /etc/hosts && \
    sed -i "s/\DOCKER_STORAGE_DRIVER/$DOCKER_STORAGE_DRIVER/" /etc/docker/daemon.json && \
    sed -i "s/\PWD_IP_ADDRESS/$PWD_IP_ADDRESS/" /etc/docker/daemon.json && \
    umount /var/lib/docker && mount -t securityfs none /sys/kernel/security && \
    dockerd &>/docker.log & \
    sleep 6 && \
    /usr/local/bin/docker run -d --name=etcd --net=host gcr.io/google_containers/etcd:2.2.1 /usr/local/bin/etcd --listen-client-urls=http://0.0.0.0:4001 --advertise-client-urls=http://0.0.0.0:4001 --data-dir=/var/etcd/data && \
    /usr/local/bin/docker run -d --name=api --net=host --pid=host --privileged=true gcr.io/google_containers/hyperkube:v1.2.2 /hyperkube apiserver --insecure-bind-address=0.0.0.0 --service-cluster-ip-range=10.0.0.1/24  --etcd_servers=http://127.0.0.1:4001 && \
    /usr/local/bin/docker run -d --name=kubs --volume=/:/rootfs:ro --volume=/sys:/sys:ro --volume=/dev:/dev --volume=/var/lib/docker/:/var/lib/docker:rw --volume=/var/lib/kubelet/:/var/lib/kubelet:rw --volume=/var/run:/var/run:rw  --net=host --pid=host --privileged=true gcr.io/google_containers/hyperkube:v1.2.2 /hyperkube kubelet --containerized --hostname-override="0.0.0.0" --address="0.0.0.0" --cluster_dns=10.0.0.10 --cluster_domain=cluster.local --api-servers=http://localhost:8080 --config=/etc/kubernetes/manifests-multi && \
    while true ; do script -q -c "/bin/bash -l" /dev/null ; done
# ... and then put a shell in the foreground, restarting it if it exits
