module Algo
  module Runner
    class Apply

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
          srv_networks = @srv.spec.networks.map { |n| { 'Target' => n.name } }
          unless srv_networks != @srv_spec['Networks']
            @srv_spec['Networks'] = @srv.spec.networks.map { |n| { 'Target' => n.id } }
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

      attr_reader :configuration, :options

      def initialize configuration, options
        @configuration = configuration
        @options = options
      end

      def call
        puts 'Running with dry-run mode...' if dryrun?
        configuration.each do |cluster|
          puts "Applying to cluster #{cluster['name']}..."

          cluster['networks'].each do |net_spec|
            begin
              net = Algo::Docker::Network.find net_spec['Name']
              puts "network: #{net_spec['Name']}, status: ok"
            rescue Algo::Docker::Error::NotFoundError
              Algo::Docker::Network.create net_spec unless dryrun?
              puts "network: #{net_spec['Name']}, status: created"
            end
          end
          cluster['services'].each do |srv_spec|
            ServiceValidator.validate srv_spec
          end
          cluster['services'].each do |srv_spec|
            ServiceUpdator.update srv_spec, dryrun?
          end
          Algo::Docker::Service.all
            .select { |srv| srv.spec.name.start_with?("#{cluster['prefix']}-") }
            .select { |srv| ! srv.spec.name.in? cluster['services'].map { |spec| spec['Name'] } }
            .map { |srv|
              srv_name = srv.spec.name
              srv.remove unless dryrun?
              puts "service: #{srv_name}, status: removed"
            }
          Algo::Docker::Network.all(skip_default=true)
            .select { |net| net.name.start_with?("#{cluster['prefix']}-") }
            .select { |net| ! net.name.in? cluster['networks'].map { |net_spec| net_spec['Name'] } }
            .map { |net|
              net_name = net.name
              net.remove unless dryrun?
              puts "network: #{net_name}, status: removed"
            }
          puts "Complete applying for cluster #{cluster['name']}!"
        end
      rescue Algo::ValidationError => e
        puts 'configuration validation failed because ' + e.message
      end

      def self.call configuration, options
        new(configuration, options).call
      end

      private

      def dryrun?
        options[:'dry-run']
      end

    end
  end
end
