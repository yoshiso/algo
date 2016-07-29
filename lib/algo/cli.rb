module Algo
  class Cli < Thor

    desc 'apply [INVENTRY_FILE]', 'Apply configuration to clusters'
    option :'dry-run', type: :boolean, default: false
    option :'url', type: :string, desc: 'docker swarm url like tcp://localhost:2375'
    option :'client_key', type: :string, desc: 'docker swarm client key path'
    option :'client_sert', type: :string, desc: 'docker swarm client sert path'
    option :'ssl_ca_file', type: :string, desc: 'docker swarm ssl ca file path'
    option :'scheme', type: :string, desc: 'docker swarm connection scheme'
    def apply inventry
      Algo::Docker.url = options[:host] if options[:host]
      Algo::Docker.options = docker_opts if docker_opts.present?
      configuration = Algo::Dsl.load({}, inventry)
      Algo::Runner::Apply.call configuration, options
    end

    desc 'rm [INVENTRY_FILE]', 'Terminate clusters'
    option :'dry-run', type: :boolean, default: false
    option :'url', type: :string, desc: 'docker swarm url like tcp://localhost:2375'
    option :'client_key', type: :string, desc: 'docker swarm client key path'
    option :'client_sert', type: :string, desc: 'docker swarm client sert path'
    option :'ssl_ca_file', type: :string, desc: 'docker swarm ssl ca file path'
    option :'scheme', type: :string, desc: 'docker swarm connection scheme'
    def rm inventry
      Algo::Docker.url = options[:host] if options[:host]
      Algo::Docker.options = docker_opts if docker_opts.present?
      configuration = Algo::Dsl.load({}, inventry)
      Algo::Runner::Rm.call configuration, options
    end

    private

    def docker_opts
      options.slice(:client_key, :client_sert, :ssl_ca_file, :scheme)
    end

  end
end
