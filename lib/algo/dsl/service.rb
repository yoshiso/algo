module Algo
  class Dsl
    module Service

      class VolumeContext
        attr_reader :context

        def initialize clstr_context, srv_context
          @clstr_context = clstr_context
          @srv_context = srv_context
          @context = {}
        end

        def readonly
          @context['ReadOnly'] = true
        end

        # @param [String] item volume name or host file/directory path
        def source item
          raise 'Need to call type at first' unless @context['Type']
          if @context['Type'] == 'volume'
            @context['Source'] = "#{cluster_prefix}#{item}"
          else
            @context['Source'] = item
          end
        end

        # @param [String] item container mount path
        def target item
          @context['Target'] = item
        end

        # @param [String] volume type ex) bind,volume
        def type item
          @context['Type'] = item
        end

        def label key, val
          @context['VolumeOptions'] ||= {}
          @context['VolumeOptions']['Labels'] ||= {}
          @context['VolumeOptions']['Labels'][key] = val
        end

        # @param [String] volume driver type ex) local
        def driver item
          @context['VolumeOptions'] ||= {}
          @context['VolumeOptions'] = { 'DriverConfig' => { 'Name' => item } }
        end

        private

        def cluster_prefix
          "#{@clstr_context['prefix']}-" if @clstr_context['prefix']
        end
      end

      class Context
        attr_reader :context

        def initialize name, cluster
          @cluster = cluster
          @context = {
            'Name' => "#{cluster_prefix}#{name}",
            'TaskTemplate' => {
              'ContainerSpec' => {
                'Image' => nil
              }
            },
            'Mode' => {
              'Replicated' => {
                'Replicas' => 1
              }
            },
            'Labels' => @cluster['labels']
          }
          @context['TaskTemplate']['ContainerSpec']['Env'] = @cluster['env'] if @cluster['env'].present?
        end

        # ContainerSpec

        def image image_name
          @context['TaskTemplate']['ContainerSpec']['Image'] = image_name
        end

        def command *item
          @context['TaskTemplate']['ContainerSpec']['Command'] = item
        end

        def args *items
          @context['TaskTemplate']['ContainerSpec']['Args'] = items
        end

        def env key, val
          @context['TaskTemplate']['ContainerSpec']['Env'] ||= []
          @context['TaskTemplate']['ContainerSpec']['Env'] << "#{key}=#{val}"
        end

        def workdir name
          @context['TaskTemplate']['ContainerSpec']['Dir'] = name
        end

        def user name
          @context['TaskTemplate']['ContainerSpec']['User'] = name
        end

        # @param [String] period period string like 30s, 1m, 4h
        def stop_grace_period period
          @context['TaskTemplate']['ContainerSpec']['StopGracePeriod'] = second_from_string(period) * 1e9
        end

        def volume &block
          raise 'should be called in cluster' unless @context
          ctx = Service::VolumeContext.new(@cluster, @context).tap do |ctx|
            ctx.instance_eval(&block)
          end
          @context['TaskTemplate']['ContainerSpec']['Mounts'] ||= []
          @context['TaskTemplate']['ContainerSpec']['Mounts'] << ctx.context
        end

        # Resources

        def limit_cpu decimal
          @context['TaskTemplate']['Resources'] ||= {}
          @context['TaskTemplate']['Resources']['Limits'] ||= {}
          @context['TaskTemplate']['Resources']['Limits']['NanoCPUs'] = decimal * 1e9
        end

        # @param [String] memory num with unit like 1B 20KB 30MB 1GB
        def limit_memory memory
          @context['TaskTemplate']['Resources'] ||= {}
          @context['TaskTemplate']['Resources']['Limits'] ||= {}
          @context['TaskTemplate']['Resources']['Limits']['MemoryBytes'] = memory_from_string memory
        end

        def reserve_cpu decimal
          @context['TaskTemplate']['Resources'] ||= {}
          @context['TaskTemplate']['Resources']['Reservation'] ||= {}
          @context['TaskTemplate']['Resources']['Reservation']['NanoCPUs'] = decimal * 1e9
        end

        # @param [String] memory num with unit like 1B 20KB 30MB 1GB
        def reserve_memory memory
          @context['TaskTemplate']['Resources'] ||= {}
          @context['TaskTemplate']['Resources']['Reservation'] ||= {}
          @context['TaskTemplate']['Resources']['Reservation']['MemoryBytes'] = memory_from_string memory
        end

        # RestartPolicy

        # @param [String] name none, on-failure or any
        def restart_condition name
          @context['TaskTemplate']['RestartPolicy'] ||= {}
          @context['TaskTemplate']['RestartPolicy']['Condition'] = name
        end

        def restart_delay period
          @context['TaskTemplate']['RestartPolicy'] ||= {}
          @context['TaskTemplate']['RestartPolicy']['Delay'] = second_from_string(period) * 10e9
        end

        # @param [Integer] value
        def restart_max_attempts value
          @context['TaskTemplate']['RestartPolicy'] ||= {}
          @context['TaskTemplate']['RestartPolicy']['Attempts'] = value
        end

        def restart_window value
          @context['TaskTemplate']['RestartPolicy'] ||= {}
          @context['TaskTemplate']['RestartPolicy']['Window'] = second_from_string(period) * 10e9
        end

        # Placement

        def constraint condition
          @context['TaskTemplate']['Placement'] ||= {}
          @context['TaskTemplate']['Placement']['Constraints'] ||= []
          @context['TaskTemplate']['Placement']['Constraints'] << condition
        end


        # Label

        def label key, val
          @context['Labels'] ||= {}
          @context['Labels'][key] = val
        end

        # Mode

        def replicas replica_size
          @context['Mode'] = { 'Replicated' => { 'Replicas' => replica_size } }
        end

        def global
          @context['Mode'] = { 'Global' => {} }
        end

        # EndpointSpec

        # @param [String] mode vip or dnsrr
        def endpoint_mode mode
          @context['EndpointSpec'] = { 'Mode' => mode }
        end

        # @param [String] port like 80 or 80:80 or 80/udp
        def publish port
          port, protocol = *port.split('/')  if '/'.in? port
          target, publish = *port.split(':')  if ':'.in? port
          @context['EndpointSpec'] ||= {}
          @context['EndpointSpec']['Ports'] ||= []
          @context['EndpointSpec']['Ports'] << {
            'Protocol' => protocol,
            'TargetPort' => target,
            'PublishedPort' => publish
          }.compact
        end

        # UpdateConfig

        def update_parallelism n
          @context['UpdateConfig'] ||= {}
          @context['UpdateConfig']['Parallelism']= n
        end

        def update_delay n
          @context['UpdateConfig'] ||= {}
          @context['UpdateConfig']['Delay']= n
        end

        # Networks

        def network name
          @context['Networks'] ||= []
          @context['Networks'] << { 'Target' => "#{cluster_prefix}#{name}" }
        end

        private

        def cluster_prefix
          "#{@cluster['prefix']}-" if @cluster['prefix']
        end

        def second_from_string(period)
          if period.end_with?('s')
            period.chomp('s').to_i
          elsif period.end_with?('m')
            period.chomp('m').to_i * 60
          elsif period.end_with?('h')
            period.chomp('m').to_i * 60 * 60
          else
            raise
          end
        end

        def memory_from_string(memory)
          if memory.end_with?('B')
            memory.chomp('B').to_i
          elsif memory.end_with?('KB')
            memory.chomp('KB').to_i * 1e3
          elsif memory.end_with?('MB')
            memory.chomp('MB').to_i * 1e6
          elsif memory.end_with?('GB')
            memory.chomp('GB').to_i * 1e9
          elsif memory.end_with?('TB')
            memory.chomp('TB').to_i * 1e12
          else
            raise
          end
        end

      end

      def service name, &block
        raise 'should be called in cluster' unless @context
        ctx = Service::Context.new(name, @context).tap do |ctx|
          ctx.instance_eval(&block)
        end
        @context['services'] << ctx.context
      end

    end
  end
end
