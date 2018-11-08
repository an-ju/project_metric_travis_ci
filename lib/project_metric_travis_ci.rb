require "project_metric_travis_ci/version"
require 'project_metric_travis_ci/test_generator'
require "faraday"
require "json"
require "open-uri"
require 'time'

class ProjectMetricTravisCi
  attr_reader :raw_data

  def initialize(credentials, raw_data = nil)
    @identifier = URI::parse(credentials[:github_project]).path[1..-1]

    @conn = Faraday.new(url: 'https://api.travis-ci.org')
    @conn.headers['Travis-API-Version'] = '3'
    @conn.headers['Authorization'] = "token #{credentials[:travis_token]}"

    @raw_data = raw_data
  end

  def refresh
    set_repo
    set_builds
    set_logs
    @raw_data = {
        builds: @builds,
        logs: @logs
    }.to_json
  end

  def raw_data=(new)
    @raw_data = new
  end

  def score
    refresh unless @raw_data
    fix_time
  end

  def image
    refresh unless @raw_data
    @image ||= { chartType: 'travis_ci',
                 data: {
                   builds: @builds,
                   build_link: build_link
                 } }.to_json
  end

  def commit_sha
    refresh unless @raw_data
    @builds.first['commit']['sha']
  end

  def self.credentials
    %I[github_project travis_token]
  end

  private

  def set_repo
    @repo = JSON.parse(@conn.get("repo/#{CGI.escape(@identifier)}").body)
    @default_branch = @repo['default_branch']['name']
  end

  def set_builds
    @builds = JSON.parse(@conn.get("repos/#{@repo['id']}/builds",
                                   limit: 30,
                                   'build.name' => @default_branch).body)['builds']
  end

  def set_logs
    jobs = @builds.first['jobs']
    @logs = jobs.map do |job|
      @conn.get do |req|
        req.url "job/#{job.id}/log"
        req.headers['Accept'] = 'plain/text'
      end.body
    end
  end

  def fix_time
    failure_time = 0
    fix_times = 0
    prev_bd = nil
    @builds.each do |bd|
      if prev_bd
        if bd['state'] == 'failed'
          failure_time += start_time(bd) - start_time(prev_bd)
        end
        if bd['state'] == 'passed' and prev_bd['state'] == 'failed'
          failure_time += start_time(bd) - start_time(prev_bd)
          fix_times += 1
        end
      end
      prev_bd = bd
    end
    fix_times.zero? ? 0 : failure_time / fix_times.to_f
  end

  def start_time(bd)
    Time.parse(bd['started_at'])
  end

  def build_link
    "https://travis-ci.com/#{@identifier}/builds/#{@builds.first['id']}"
  end

end
