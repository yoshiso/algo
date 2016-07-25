module Algo
  class Dsl
    module Cluster

      class Context
        include Dsl::Network
        include Dsl::Service

        attr_reader :context

        def initialize name
          @context = {
            "services" => [],
            "networks" => [],
            "env" => [],
            "labels" => {},
            'name' => name,
            'prefix' => name
          }
        end

        # Assign cluster-wide used prefix.
        # @param [String] pref_name
        def prefix pref_name
          @context['prefix'] = pref_name
        end

        def env key, val
          @context['env'] << "#{key}=#{val}"
        end

        def label key, val
          @context['labels'][key] = val
        end

      end

      def cluster name, &block
        ctx = Cluster::Context.new(name).tap do |ctx|
          ctx.instance_eval(&block)
        end
        @clusters << ctx.context
      end

    end
  end
end
