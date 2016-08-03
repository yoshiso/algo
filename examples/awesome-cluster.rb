cluster 'awesomecluster' do

  # Define service/network prefix for cluster
  prefix 'awsm'

  # Define cluster wide available environment variable
  env 'CLUSTER_ENV', 'PRODUCTION'

  # Define cluster wide available label
  label 'com.example.sample', 'clusterwidelabel'

  # Define network
  network 'net1' do
    ipam do
      subnet '172.20.0.0/16'
      ip_range '172.20.10.0/24'
      gateway '172.20.10.11'
    end
  end

  # Define service
  service 'name' do
    image 'quay.io/yss44/curl'
    replicas 3
    command 'sh'
    args '-ic', "while true; do curl -s awsm-nginx > /dev/null; echo $?; sleep 3; done"

    update_parallelism 2

    env 'APP_DOMAIN', 'example.com'

    # Mount host's directory/file
    volume do
      type 'bind'
      source '/tmp/mount'
      target '/mnt/sample'
    end

    # Mount host docker volume
    volume do
      type 'volume'
      source 'volume-name'
      target '/mnt/volume-sample'
    end

    # join network
    network 'net1'
  end

  # Define another service
  service 'nginx' do
    image 'nginx:alpine'
    replicas 2
    network 'net1'
  end

end
