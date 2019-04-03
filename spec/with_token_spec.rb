require "spec_helper"

RSpec.describe ProjectMetricTravisCi do
  before :each do
    WebMock.allow_net_connect!
  end
  subject(:metric) do
    tokens = JSON.parse(File.read('spec/data/tokens.json'))
    described_class.new(github_project: tokens['github_project'],
                        travis_token: tokens['travis_token'],
                        travis_service_loc: tokens['travis_service_loc'])
  end

  it 'initializes properly' do
    expect(metric).not_to be_nil
  end

  it 'sets image properly' do
    expect(metric.image).not_to be_nil
  end

  it 'sets score properly' do
    expect(metric.score).not_to be_nil
  end

end