module Algo
  module Docker
    class Base
      include Docker::Error

      attr_reader :id, :info

      def initialize(connection, hash={})
        unless connection.is_a?(Docker::Connection)
          raise ArgumentError, "Expected a Docker::Connection, got: #{connection}."
        end
        normalize_hash(hash)
        @connection, @info, @id = connection, hash, hash['Id']
        raise ArgumentError, "Must have id, got: #{hash}" unless @id
      end

      private
      attr_accessor :connection

      def normalize_hash(hash)
        hash["Id"] ||= hash.delete("ID")
      end

    end
  end
end
