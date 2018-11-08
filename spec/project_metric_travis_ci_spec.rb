require "spec_helper"

RSpec.describe ProjectMetricTravisCi do
  before :each do
    @conn = double('conn')
    project_resp = double('project')
    allow(project_resp).to receive(:body) { File.read './spec/data/travis_project.json' }
    builds_resp = double('builds')
    allow(builds_resp).to receive(:body) { File.read './spec/data/travis_builds.json' }
    jobs_resp = double('jobs')
    allow(jobs_resp).to receive(:body).and_return('job contents')

    allow(Faraday).to receive(:new).and_return(@conn)
    allow(@conn).to receive(:headers).and_return({})
    allow(@conn).to receive(:get).with(no_args).and_return(jobs_resp)
    allow(@conn).to receive(:get).with('repo/an-ju%2Fteamscope').and_return(project_resp)
    allow(@conn).to receive(:get).with('repos/6784605/builds', any_args).and_return(builds_resp)
  end

  subject(:project_metric_travis_ci) do
    described_class.new(github_project: 'https://github.com/an-ju/teamscope', travis_token: 'token')
  end

  it "generates score correctly" do
    expect(project_metric_travis_ci.score).to eql(0)
  end

  it 'generates image correctly' do
    img = JSON.parse(project_metric_travis_ci.image)
    expect(img).to have_key('data')
    expect(img['data']['builds'].length).to eql(1)
    expect(img['data']['build_link']).to eql('https://travis-ci.com/an-ju/teamscope/builds/90357060')
  end

  it 'returns correct commit sha' do
    expect(project_metric_travis_ci.commit_sha).to eql('b97b5445dd0286fa1e81763cbf5f12a1eb36034d')
  end


  it 'generates fake data' do
    expect(ProjectMetricTravisCi.fake_data.length).to eql(3)
    expect(ProjectMetricTravisCi.fake_data.first).to have_key(:image)
  end

  it 'contains the right fake metric' do
    image_data = JSON.parse(ProjectMetricTravisCi.fake_data.first[:image])
    expect(image_data['data']).to have_key('builds')
    image_data['data']['builds'].each do |bd|
      expect(bd['state']).not_to be_nil
    end
  end

end
