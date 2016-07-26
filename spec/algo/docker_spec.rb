require 'spec_helper'

describe Algo::Docker do
  it 'can access swarm mode docker connection' do
    expect(Algo::Docker.connection.get('/services')).to eq []
  end
end
