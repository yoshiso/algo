module Algo
  class Cli < Thor
    class ValidationError < StandardError; end

    class ServiceValidator
      def initialize srv_spec
        @srv_spec = srv_spec
      end

      def validate
        begin
          @srv = Algo::Docker::Service.find(@srv_spec['Name'])
        rescue Algo::Docker::Error::NotFoundError
          @srv = nil
        end
        check_networks
      end

      def self.validate srv_spec
        new(srv_spec).validate
      end

      private

      def check_networks
        return true if @srv.blank? or @srv.spec.networks.blank?
        srv_networks = @srv.spec.networks.map { |n| { 'Target' => n.info['Name'] } }
        unless srv_networks != @srv_spec['Networks']
          @srv_spec['Networks'] = @srv.spec.networks.map { |n| { 'Target' => n.info['Id'] } }
          return true
        end
        raise ValidationError, 'changing network in service is not supported'
      end
    end

    class ServiceUpdator

      def initialize srv_spec, options
        @srv_spec = srv_spec
        @options = options
      end

      def update
        begin
          srv = Algo::Docker::Service.find(@srv_spec['Name'])
          if srv.raw_spec == @srv_spec
            puts "service: #{@srv_spec['Name']}, status: ok"
            return
          end
          srv.update @srv_spec unless dryrun?
          puts "service: #{@srv_spec['Name']}, status: changed"
        rescue Algo::Docker::Error::NotFoundError
          Algo::Docker::Service.create(@srv_spec) unless dryrun?
          puts "service: #{@srv_spec['Name']}, status: created"
        end
      end

      def self.update srv_spec, dryrun=false
        new(srv_spec, {dryrun: dryrun}).update
      end

      private

      def dryrun?
        @options[:dryrun]
      end
    end

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
      puts 'Running with dry-run mode...' if options[:'dry-run']
      configuration = Algo::Dsl.load({}, inventry)
      configuration.each do |cluster|
        puts "Applying to cluster #{cluster['name']}..."

        cluster['networks'].each do |net_spec|
          begin
            net = Algo::Docker::Network.find net_spec['Name']
            puts "network: #{net_spec['Name']}, status: ok"
          rescue Algo::Docker::Error::NotFoundError
            Algo::Docker::Network.create net_spec unless options[:'dry-run']
            puts "network: #{net_spec['Name']}, status: created"
          end
        end

        cluster['services'].each do |srv_spec|
          ServiceValidator.validate srv_spec
        end
        cluster['services'].each do |srv_spec|
          ServiceUpdator.update srv_spec, options[:'dry-run']
        end
        Algo::Docker::Service.all
          .select { |srv| srv.spec.name.start_with?("#{cluster['prefix']}-") }
          .select { |srv| ! srv.spec.name.in? cluster['services'].map { |spec| spec['Name'] } }
          .map { |srv|
            srv_name = srv.spec.name
            srv.remove unless options[:'dry-run']
            puts "service: #{srv_name}, status: removed"
          }
        Algo::Docker::Network.all(skip_default=true)
          .select { |net| net.info['Name'].start_with?("#{cluster['prefix']}-") }
          .select { |net| ! net.info['Name'].in? cluster['networks'].map { |net_spec| net_spec['Name'] } }
          .map { |net|
            net_name = net.info['Name']
            net.remove unless options[:'dry-run']
            puts "network: #{net_name}, status: removed"
          }
        puts "Complete applying for cluster #{cluster['name']}!"
      end
    rescue ValidationError => e
      puts 'configuration validation failed because ' + e.message
    end

    desc 'rm [INVENTRY_FILE]', 'Terminate clusters'
    option :'dry-run', type: :boolean, default: false
    def rm inventry
      puts 'Running with dry-run mode...' if options[:'dry-run']
      configuration = Algo::Dsl.load({}, inventry)
      configuration.each do |cluster|
        puts "Terminating cluster #{cluster['name']}..."
        Algo::Docker::Service.all
          .select { |srv| srv.spec.name.start_with?("#{cluster['prefix']}-") }
          .map { |srv|
            srv_name = srv.spec.name
            srv.remove unless options[:'dry-run']
            puts "service: #{srv_name}, status: removed"
          }
        Algo::Docker::Network.all(skip_default=true)
          .select { |net| net.info['Name'].start_with?("#{cluster['prefix']}-") }
          .select { |net| ! net.info['Name'].in? cluster['networks'].map { |net_spec| "#{cluster['prefix']}-#{net_spec['Name']}" } }
          .map { |net|
            net_name = net.info['Name']
            net.remove unless options[:'dry-run']
            puts "network: #{net_name}, status: removed"
          }
        puts "Complete Termination for cluster #{cluster['name']}..."
      end
    end

    private

    def docker_opts
      options.slice(:client_key, :client_sert, :ssl_ca_file, :scheme)
    end

  end
end
