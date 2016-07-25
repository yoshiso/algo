module Algo
  class Dsl
    module Network

      class IPAMContext
        attr_reader :context

        def initialize
          @context = {}
        end

        def subnet item
          @context['Subnet'] = item
        end

        def ip_range item
          @context['IPRange'] = item
        end

        def gateway item
          @context['Gateway'] = item
        end
      end

      class Context

        attr_reader :context

        def initialize name, cluster
          @cluster = cluster
          @context = {
            'Name' => "#{cluster_prefix}#{name}",
            'Driver' => 'overlay',
            'CheckDuplicate' => true,
            'EnableIPv6' => false,
            'IPAM' => {
              'Config' => [],
              'Driver' => 'default',
              'Options' => {}
            },
            'Internal' => false,
            'Labels' => cluster['labels'],
            'Options' => {}
          }
        end

        def internal
          @context['Internal'] = true
        end

        def label key, val
          @context['Labels'][key] = val
        end

        def ipv6
          @context['EnableIPv6'] = true
        end

        def ipam &block
          ctx = Network::IPAMContext.new.tap do |ctx|
            ctx.instance_eval(&block) if block_given?
          end
          @context['IPAM']['Config'] << ctx.context
        end

        private

        def cluster_prefix
          "#{@cluster['prefix']}-" if @cluster['prefix']
        end

      end

      def network name, &block
        raise 'should be called in cluster' unless @context
        ctx = Network::Context.new(name, @context).tap do |ctx|
          ctx.instance_eval(&block) if block_given?
        end
        @context['networks'] << ctx.context
      end

    end
  end
end
