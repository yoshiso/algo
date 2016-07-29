module Algo
  module Runner
    class Rm
      attr_reader :configuration, :options

      def initialize configuration, options
        @configuration = configuration
        @options = options
      end

      def call
        puts 'Running with dry-run mode...' if dryrun?
        configuration.each do |cluster|
          puts "Terminating cluster #{cluster['name']}..."
          Algo::Docker::Service.all
            .select { |srv| srv.spec.name.start_with?("#{cluster['prefix']}-") }
            .map { |srv|
              srv_name = srv.spec.name
              srv.remove unless dryrun?
              puts "service: #{srv_name}, status: removed"
            }
          Algo::Docker::Network.all(skip_default=true)
            .select { |net| net.info['Name'].start_with?("#{cluster['prefix']}-") }
            .select { |net| ! net.info['Name'].in? cluster['networks'].map { |net_spec| "#{cluster['prefix']}-#{net_spec['Name']}" } }
            .map { |net|
              net_name = net.info['Name']
              net.remove unless dryrun?
              puts "network: #{net_name}, status: removed"
            }
          puts "Complete Termination for cluster #{cluster['name']}..."
        end
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
