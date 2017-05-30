require "project_metric_travis_ci/version"
require "faraday"
require "json"
require "open-uri"

class ProjectMetricTravisCi
  attr_reader :raw_data

  def initialize(credentials, raw_data = nil)
    @identifier = URI::parse(credentials[:github_project]).path[1..-1]
    @main_branch = credentials[:github_main_branch]
    @conn = Faraday.new(url: 'https://api.travis-ci.org')
    @conn.headers['Accept'] = 'application/vnd.travis-ci.2+json'
    @conn.headers['Content-Type'] = 'application/json'
    @raw_data = raw_data
  end

  def refresh
    @raw_data ||= builds
    @image = @score = nil
  end

  def raw_data=(new)
    @raw_data = new
    @score = nil
    @image = nil
  end

  def score
    @raw_data ||= builds
    filter_builds
    if @main_builds.empty?
      -1
    else
      passed = @main_builds.select { |bd| bd['state'].eql? 'passed' }
      passed.length.to_f / @main_builds.length.to_f
    end
  end

  def image
    @raw_data ||= builds
    filter_builds
    { chartType: 'travis_ci',
      titleText: 'Travis CI builds',
      data: { total_builds: @main_builds.length,
              success_builds: @main_builds.select { |bd| bd['state'].eql? 'passed' }.length,
              current_state: @main_builds.empty? ? nil : @main_builds[0]['state'] } }
  end

  def self.credentials
    %I[github_project github_main_branch]
  end

  private

  def builds
    JSON.parse(
        @conn.get("repos/#{@identifier}/builds").body
    )
  end

  def filter_builds
    @raw_data ||= builds
    id2cmit = Hash[@raw_data['commits'].map { |cmit| [cmit['id'], cmit]}]
    @main_builds = @raw_data['builds'].select do |bd|
      id2cmit.key?(bd['commit_id']) && id2cmit[bd['commit_id']]['branch'].eql?(@main_branch)
    end
  end

end
