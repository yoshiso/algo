require 'spec_helper'

describe Algo::Dsl::Cluster do

  def service service_name
    Algo::Docker::Service.find service_name
  end

  let(:configuration) { {} }
  before(:each) { Algo::Runner::Apply.call Algo::Dsl.load_text({}, conf), {} }
  after(:each) do
    Algo::Docker::Service.all().map(&:remove)
    Algo::Docker::Network.all(skip_default=true).map(&:remove)
  end

  subject { service service_name  }

  describe 'env' do
    let(:service_name) { 't1-alp1' }
    let(:conf) do
      <<-TXT
      cluster 't1' do
        env 'ENV_TEST', 'Hello'
        service 'alp1' do
          image 'alpine'
          command 'sh'
          args "-e", 'while true; do sleep 1; done'
        end
      end
      TXT
    end
    let(:conf2) do
      <<-TXT
      cluster 't1' do
        env 'ENV_TEST', 'GoodBye'
        service 'alp1' do
          image 'alpine'
          command 'sh'
          args "-e", 'while true; do sleep 1; done'
        end
      end
      TXT
    end

    it 'service has environment variable' do
      expect(service(service_name).spec.task_template['ContainerSpec']['Env'].first).to eq 'ENV_TEST=Hello'
      v1 = service(service_name).info
      Algo::Runner::Apply.call Algo::Dsl.load_text({}, conf2), {}
      v2 = service(service_name).info
      expect(v1['CreatedAt']).to eq v2['CreatedAt']
      expect(v1['UpdatedAt']).to be < v2['UpdatedAt']
      expect(service(service_name).spec.task_template['ContainerSpec']['Env'].first).to eq 'ENV_TEST=GoodBye'
    end
  end

  describe 'label' do

  end

  describe 'prefix' do

  end

end
