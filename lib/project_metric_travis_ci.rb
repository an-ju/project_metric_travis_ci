require "project_metric_travis_ci/version"
require "faraday"
require "json"
require "open-uri"
require 'time'

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
    @image = @score = nil
    @raw_data ||= builds
  end

  def raw_data=(new)
    @raw_data = new
    @score = nil
    @image = nil
  end

  def score
    @raw_data ||= builds
    filter_builds
    @main_builds.empty? ? -1 : success_builds.length / @main_builds.length.to_f
  end

  def image
    @raw_data ||= builds
    filter_builds
    @image ||= { chartType: 'travis_ci',
                 titleText: 'Travis CI builds',
                 data: {
                   failure_times: failure_times,
                   total_builds: @main_builds.length,
                   success_builds: success_builds.length,
                   current_state: current_state
                 } }.to_json
  end

  def self.credentials
    %I[github_project github_main_branch]
  end

  private

  def builds
    JSON.parse(@conn.get("repos/#{@identifier}/builds").body)
  end

  def filter_builds
    @raw_data ||= builds
    id2cmit = Hash[@raw_data['commits'].map { |cmit| [cmit['id'], cmit]}]
    @main_builds = @raw_data['builds'].select do |bd|
      bd['pull_request'] || (id2cmit.key?(bd['commit_id']) && id2cmit[bd['commit_id']]['branch'].eql?(@main_branch))
    end
  end

  def success_builds
    @main_builds.select { |bd| bd['state'].eql? 'passed' }
  end

  def current_state
    @main_builds.empty? ? nil : @main_builds[0]['state']
  end

  def failure_times
    starting_time = nil
    failures_periods = []

    @main_builds.sort_by { |bd| Time.parse bd['started_at'] }.each do |bd|
      if bd['state'].eql? 'failed'
        starting_time ||= Time.parse(bd['started_at'])
      elsif bd['state'].eql? 'passed'
        unless starting_time.nil?
          failures_periods.push(Time.parse(bd['started_at']) - starting_time)
          starting_time = nil
        end
      end
    end
    failures_periods
  end

end
