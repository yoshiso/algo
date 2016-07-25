module Algo

  module Docker

    class Service < Base

      Spec = Struct.new('Spec', :name, :task_template, :mode, :update_config,
                                :networks, :endpoint_spec)

      attr_reader :spec

      def initialize conn, hash
        super(conn, hash)
        @spec = nil
      end

      def info
        @info = Docker::Service.find(@info["Id"]).info if @info["Spec"].blank?
        @info
      end

      def spec
        if @spec.blank?
          @spec = Spec.new(
            info["Spec"]["Name"],
            info["Spec"]["TaskTemplate"],
            info["Spec"]["Mode"],
            info["Spec"]["UpdateConfig"],
            info["Spec"]["Networks"].tap { |network|
              unless network.blank?
                break network.map { |net| Network.new(@connection, {'Id' => net['Target']}) }
              end
            },
            info["Spec"]["EndpointSpec"]
          )
        end
        @spec
      end

      def raw_spec
        info["Spec"]
      end

      def inspect
        "<Algo::Docker::Service name=#{spec.name}>"
      end

      def remove
        self.class.remove info['Id']
      end

      def update next_spec
        self.class.update info['Id'], info['Version']['Index'], next_spec
        @info = self.class.find(@info["Id"]).info
      end

      def self.find(id_or_name, conn=Docker.connection)
        new(conn, conn.get("/services/#{id_or_name}"))
      end

      def self.create(init_spec, conn=Docker.connection)
        new(conn, conn.post('/services/create', nil, body: JSON.generate(init_spec)))
      end

      def self.remove(id_or_name, conn=Docker.connection)
        conn.delete("/services/#{id_or_name}")
      end

      def self.update(id_or_name, version, next_spec, conn=Docker.connection)
        conn.post("/services/#{id_or_name}/update",
                  { version: version },
                  body: JSON.generate(next_spec))
      end

      def self.all(conn=Docker.connection)
        hashes = conn.get('/services')
        hashes.map{ |h| new(conn, h) }
      end

    end

  end

end
