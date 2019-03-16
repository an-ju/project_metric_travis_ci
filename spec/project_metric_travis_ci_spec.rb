require "spec_helper"

RSpec.describe ProjectMetricTravisCi do
  before :each do
    stub_request(:get, 'https://api.travis-ci.com/repo/an-ju%2Fteamscope')
      .to_return(body: File.read('spec/data/travis_project.json'))
    stub_request(:get, 'https://api.travis-ci.com/repos/an-ju%2Fteamscope/builds')
      .to_return(body: File.read('spec/data/travis_builds.json'))
    stub_request(:get, /.*/)
      .with(headers: { 'Accept': 'plain/text' })
      .to_return(body: 'shell output')
  end

  subject(:project_metric_travis_ci) do
    described_class.new(github_project: 'https://github.com/an-ju/teamscope', travis_token: 'token')
  end

  it "generates score correctly" do
    expect(project_metric_travis_ci.score).to eql(100)
  end

  it 'generates image correctly' do
    img = project_metric_travis_ci.image
    expect(img).to be_a(Hash)
    expect(img[:data][:builds].length).to eql(1)
    expect(img[:data][:build_link]).to eql('https://travis-ci.com/an-ju/teamscope/builds/90357060')
  end

  it 'returns correct commit sha' do
    expect(project_metric_travis_ci.obj_id).to eql('b97b5445dd0286fa1e81763cbf5f12a1eb36034d')
  end


  it 'generates fake data' do
    expect(ProjectMetricTravisCi.fake_data.length).to eql(3)
    expect(ProjectMetricTravisCi.fake_data.first).to have_key(:image)
  end

  it 'contains the right fake metric' do
    image_data = ProjectMetricTravisCi.fake_data.first[:image]
    expect(image_data[:data]).to have_key(:builds)
    image_data[:data][:builds].each do |bd|
      expect(bd).to be_a(Hash)
    end
  end

end
