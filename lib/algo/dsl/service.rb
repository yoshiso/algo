module Algo
  class Dsl
    module Service

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

        # @param [String] period period string like 30s, 1m, 4h
        def stop_grace_period period
          if period.end_with?('s')
            period = period.chomp('s').to_i
          elsif period.end_with?('m')
            period = period.chomp('m').to_i * 60
          elsif period.end_with?('h')
            period = period.chomp('m').to_i * 60 * 60
          else
            raise
          end
          @context['TaskTemplate']['ContainerSpec']['StopGracePeriod'] = period * 1000000000
        end

        # Label

        def label key, val
          @context['Labels'] ||= {}
          @context['Labels'][key] = val
        end

        # Mode

        def replicas replica_size
          @context['Mode']['Replicated']['Replicas']= replica_size
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
