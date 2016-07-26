require 'spec_helper'

describe Algo::Dsl do
  it 'has a version number' do
    expect(Algo::VERSION).not_to be nil
  end

  it 'runs dsl file' do
    state = described_class.load({}, 'spec/fixtures/dsl.rb')
    expect(state.size).to eq 1
    expect(state.first['services'].size).to eq 1
  end

end
