module Algo
  module Docker
    class Network < Base
      DEFAULT_NETWORKS = %w(ingress none host bridge docker_gwbridge)

      def inspect
          "<Algo::Docker::Network name=#{info['Name']} scope=#{info['Scope']}>"
      end

      def info
        @info = self.class.find(@info["Id"]).info unless @info["Name"]
        @info
      end

      def to_h
        @info
      end

      def remove
        self.class.remove @info['Id']
      end

      def self.find(id, conn=Docker.connection)
        new(conn, conn.get("/networks/#{id}"))
      end

      def self.remove(id_or_name, conn=Docker.connection)
        conn.delete("/networks/#{id_or_name}")
      end

      def self.create(init_spec, conn=Docker.connection)
        new(conn, conn.post("/networks/create", nil, body: JSON.generate(init_spec)))
      end

      def self.all(skip_default=false, conn=Docker.connection)
        hashes = conn.get('/networks')
        hashes.select { |h| !skip_default || !h['Name'].in?(DEFAULT_NETWORKS) }
              .map{ |h| new(conn, h) }
      end

    end
  end
end
