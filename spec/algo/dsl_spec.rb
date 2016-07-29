require 'spec_helper'

describe Algo::Dsl do
  it 'has a version number' do
    expect(Algo::VERSION).not_to be nil
  end

  it 'run DSL file' do
    state = described_class.load({}, 'spec/fixtures/dsl.rb')
    expect(state.size).to eq 1
    expect(state.first['services'].size).to eq 1
  end

  it 'run DSL from text' do
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
    state = described_class.load_text({}, text)
    expect(state.size).to eq 1
    expect(state.first['services'].size).to eq 1
  end

end
