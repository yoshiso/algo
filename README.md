# Algo
Docker container orchestration tool for swarm cluster.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'algo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install algo


## Usage

### Definition

```rb
cluster 'awesomecluster' do

  # Define service/network prefix for cluster
  prefix 'awsm'

  # Define cluster wide available environment variable
  env 'CLUSTER_ENV', 'PRODUCTION'

  # Define cluster wide available label
  label 'com.example.sample', 'clusterwidelabel'

  # Define network
  network 'net1'

  # Define service
  service 'name' do
    image 'quay.io/yss44/curl'
    replicas 3
    command 'sh'
    args '-ic', "while true; do curl -s awsm-nginx > /dev/null; echo $?; sleep 3; done"

    update_parallelism 2

    # Service related environment variable
    env 'APP_DOMAIN', 'example.com'

    network 'net1'
  end

  # Define another service
  service 'nginx' do
    image 'nginx:alpine'
    replicas 2
    network 'net1'
  end

end
```

### Execution

```sh
# Prepare playground for algo
docker-machine create --driver virtualbox \
                      --virtualbox-boot2docker-url="https://github.com/boot2docker/boot2docker/releases/download/v1.12.0-rc4/boot2docker-experimental.iso" \
                      algo
eval $(docker-machine env algo)

# Create initial cluster
algo apply examples/awesomecluster.rb
# Applying to cluster awesomecluster...
# network: awsm-net1, status: created
# service: awsm-name, status: created
# service: awsm-nginx, status: created
# Complete applying for cluster awesomecluster!

# Change configuration
sed -i s/replicas 2/replicas 1/g examples/awesomecluster.rb

# Dry-run
algo apply examples/awesomecluster.rb --dry-run
# Running with dry-run mode...
# Applying to cluster awesomecluster...
# network: awsm-net1, status: ok
# service: awsm-name, status: ok
# service: awsm-nginx, status: changed
# Complete applying for cluster awesomecluster!

# Apply changes
algo apply examples/awesomecluster.rb --dry-run
# Applying to cluster awesomecluster...
# network: awsm-net1, status: ok
# service: awsm-name, status: ok
# service: awsm-nginx, status: changed
# Complete applying for cluster awesomecluster!

# Dry-run terminating cluster
algo apply examples/awesomecluster.rb --dry-run
# Running with dry-run mode...
# Terminating cluster awesomecluster...
# service: awsm-name, status: removed
# service: awsm-nginx, status: removed
# network: awsm-net1, status: removed
# Complete Termination for cluster awesomecluster...

# Terminate cluster
algo apply examples/awesomecluster.rb
# Terminating cluster awesomecluster...
# service: awsm-name, status: removed
# service: awsm-nginx, status: removed
# network: awsm-net1, status: removed
# Complete Termination for cluster awesomecluster...
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/yoshiso/algo/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
