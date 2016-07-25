module Algo
  module Docker
    require 'algo/docker/version'
    require 'algo/docker/error'
    require 'algo/docker/base'
    require 'algo/docker/connection'

    # Entities
    require 'algo/docker/network'
    require 'algo/docker/service'

    def connection
      @connection ||= Connection.new(url, options)
    end

    def url
      @url || env_url
    end

    def url=(new_url)
      @url = new_url
    end

    def options
      @options || env_options
    end

    def options=(new_options)
      @options = env_options.merge(new_options)
    end

    def env_url
      ENV['DOCKER_URL'] || ENV['DOCKER_HOST']
    end

    def env_options
      if cert_path = ENV['DOCKER_CERT_PATH']
        {
          client_cert: File.join(cert_path, 'cert.pem'),
          client_key: File.join(cert_path, 'key.pem'),
          ssl_ca_file: File.join(cert_path, 'ca.pem'),
          scheme: 'https'
        }.merge(ssl_options)
      else
        {}
      end
    end

    def ssl_options
      if ENV['DOCKER_SSL_VERIFY'] == 'false'
        {
          ssl_verify_peer: false
        }
      else
        {}
      end
    end

    module_function :env_options, :url, :url=, :options, :options=, :env_url, :ssl_options,
                    :connection

  end
end
