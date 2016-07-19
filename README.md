# Algo
Docker container orchestration tool for swarm cluster.

## PoC

### Definition

awesomecluster.rb

```rb

cluster 'awesomecluster' do

  env 'CLUSTER_SHARED_VAR', ';-D'
  label 'com.example.clusterlabel', 'Awesome Cluster!'
  label 'com.example.clusterlabel2', 'Awesome Cluster2!'

  network 'frontend' do
    driver 'overlay'
    subnet '192.168.0.0/24'
  end

  network 'backend' do
    driver 'overlay'
    subnet '192.168.1.0/24'
  end

  service 'lb' do
    image 'nginx'
    replicas 2
    update_delay '10s'
    update_parallelism 1
    env 'DOMAIN', 'example.com'
    label 'com.example.servicelabel', ';D'
    network 'frontend'
  end

  service 'web' do
    image 'mywebservice'
    command '/bin/runserver --sigint-timeout 30'
    replicas 10
    update_delay '10s'
    update_parallelism 2
    stop_grace_period 35
    env 'RAILS_ENV', 'PRODUCTION'
    env 'DOMAIN', 'example.com'
    label 'com.example.servicelabel', ';-('
    network 'frontend'
    network 'backend'
  end

  service 'worker' do
    image 'myworker'
    mode 'global'
    update_delay '10s'
    update_parallelism 2
    env 'RAILS_ENV', 'PRODUCTION'
    env 'DOMAIN', 'example.com'
    network 'backend'
  end

end

```

### Execution

```sh
# Create initial cluster
algo -h 127.0.0.1:2376 -c awesomecluster.rb --apply

# Change configuration
sed -i s/replicas 10/replicas 12/g awesomecluster.rb

# Check diff
algo -h 127.0.0.1:2376 -c awesomecluster.rb --diff

# Dry-run
algo -h 127.0.0.1:2376 -c awesomecluster.rb --apply --dry-run
#> docker service update awesomecluster_web --replicas 10

# Apply diff/patch
algo -h 127.0.0.1:2376 -c awesomecluster.rb --apply
```
