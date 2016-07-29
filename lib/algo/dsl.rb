module Algo
  class Dsl
    require 'algo/dsl/service'
    require 'algo/dsl/network'
    require 'algo/dsl/cluster'

    include Dsl::Cluster

    attr_reader :options

    CLUSTER_DEFAULT = {}

    def result
      @clusters
    end

    def self.load(options, path = nil)
      dsl = new(options).tap do |dsl|
        dsl._load_from(path)
      end
      dsl.result
    end

    def self.load_text(options, text)
      dsl = new(options).tap do |dsl|
        dsl.instance_eval(text)
      end
      dsl.result
    end

    def initialize(options)
      @options = CLUSTER_DEFAULT.dup
      @options.merge!(options)
      @clusters = []
    end

    def _load_from(path)
      instance_eval(File.read(path), path) if path
    end
  end
end
