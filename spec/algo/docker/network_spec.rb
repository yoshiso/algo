require 'spec_helper'

describe Algo::Docker::Network do

  after(:each) do
    described_class.all(skip_default=true).map &:remove
  end

  it 'list up all networks' do
    net = described_class.create({Name: 'mynet1', CheckDuplicate: true})
    expect(described_class.all.map{ |net| net.name }.to_set)
      .to eq (described_class::DEFAULT_NETWORKS << net.name).to_set
  end

  it 'list up networks except default ones' do
    net = described_class.create({Name: 'mynet2', CheckDuplicate: true})
    expect(described_class.all(skip_default=true).map{|net| net.name }.to_set)
      .to eq ([net.name]).to_set
  end

  it 'create network' do
    expect { described_class.create({Name: 'mynet3', CheckDuplicate: true}) }
      .not_to raise_error
  end

  it 'remove network' do
    described_class.create({Name: 'mynet3', CheckDuplicate: true})
    expect { described_class.remove('mynet3') }.not_to raise_error
  end

end
