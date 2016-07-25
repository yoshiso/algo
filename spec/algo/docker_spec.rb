require 'spec_helper'

describe Algo::Docker do
  it 'can access swarm mode docker connection' do
    expect(Algo::Docker.connection.get('/services')).to eq []
  end


  describe 'Network' do
    after do
      Algo::Docker::Network.all(skip_default=true).each do |n|
        Algo::Docker::Network.remove n.info['Name']
      end
    end

    it 'can create network' do
      expect { Algo::Docker::Network.create({Name: 'mynetwork'}) }
        .not_to raise_error
    end

    it 'can remove network' do
      Algo::Docker::Network.create({Name: 'mynetwork'})
      expect { Algo::Docker::Network.remove('mynetwork') }
        .not_to raise_error
    end

  end

end
