require 'spec_helper'

describe Algo::Docker::Service do

  let(:srv_name) { 'srv' }
  let(:srv_image) { 'alpine' }
  let(:srv_spec) do
    {
      'Name' => srv_name,
      'TaskTemplate' => {
        'ContainerSpec' => {
          'Image' => srv_image
        }
      },
      'Mode' => {
        'Replicated' => {
          'Replicas' => 1
        }
      }
    }
  end

  after(:each) do
    described_class.all.map &:remove
  end

  it 'list up all services' do
    srv = described_class.create(srv_spec)
    expect(described_class.all.map{ |srv| srv.name }.to_set).to eq [srv.name].to_set
  end

  it 'create service' do
    expect { described_class.create(srv_spec) }.not_to raise_error
  end

  it 'update service' do
    srv = described_class.create(srv_spec)
    next_spec = srv.raw_spec.dup.tap { |spec| spec['Mode']['Replicated']['Replicas'] = 2 }
    expect { srv.update next_spec }.not_to raise_error
    expect(srv.raw_spec['Mode']['Replicated']['Replicas']).to eq 2
  end

  it 'remove service' do
    described_class.create(srv_spec)
    expect { described_class.remove(srv_name) }.not_to raise_error
  end

end
