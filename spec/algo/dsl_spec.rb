require 'spec_helper'

describe Algo::Dsl do

  let(:configuration) { {} }
  let(:subject) { Algo::Docker::Service.find('awsm-alpine') }
  let(:subjec_container_spec) { subject.spec.task_template['ContainerSpec'] }

  before(:each) { Algo::Runner::Apply.call configuration, {} }
  after(:each) do
    Algo::Docker::Service.all().map(&:remove)
    Algo::Docker::Network.all(skip_default=true).map(&:remove)
  end

  describe 'run with DSL file' do
    let(:configuration){ described_class.load({}, 'spec/fixtures/dsl.rb') }
    it 'has correct docker state' do
      expect { subject }.not_to raise_error
      expect(subjec_container_spec['Image']).to eq 'alpine'
      expect(subjec_container_spec['Command']).to eq ['sh']
      expect(subjec_container_spec['Args'])
        .to match_array ["-e", "while true; do sleep 1; done"]
    end
  end

  describe 'run with DSL text' do
    let(:configuration) do
      text = <<-TEXT
      cluster 'test1' do
        prefix 'awsm'
        service 'alpine' do
          image 'alpine'
          command 'sh'
          args "-e", 'while true; do sleep 1; done'
        end
      end
      TEXT
      described_class.load_text({}, text)
    end
    it 'has correct docker state' do
      expect { subject }.not_to raise_error
      expect(subjec_container_spec['Image']).to eq 'alpine'
      expect(subjec_container_spec['Command']).to eq ['sh']
      expect(subjec_container_spec['Args'])
        .to match_array ["-e", "while true; do sleep 1; done"]
    end
  end

end
