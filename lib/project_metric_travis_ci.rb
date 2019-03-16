require "project_metric_travis_ci/version"
require 'project_metric_travis_ci/test_generator'
require "faraday"
require "json"
require "open-uri"
require 'time'
require 'project_metric_base'

class ProjectMetricTravisCi
  include ProjectMetricBase
  add_credentials %I[github_project travis_token]
  add_raw_data %w[travis_repo travis_builds travis_logs]

  def initialize(credentials, raw_data = nil)
    @identifier = URI::parse(credentials[:github_project]).path[1..-1]

    @conn = Faraday.new(url: 'https://api.travis-ci.com')
    @conn.headers['Travis-API-Version'] = '3'
    @conn.headers['Authorization'] = "token #{credentials[:travis_token]}"

    complete_with raw_data
  end

  def score
    master_builds.first['state'].eql?('passed') ? 100 : 0
  end

  def image
    @image ||= { chartType: 'travis_ci',
                 data: {
                   builds: master_builds,
                   build_link: build_link,
                   fix_time: fix_time
                 } }
  end

  def obj_id
    master_builds.first['commit']['sha']
  end

  private

  def travis_repo
    @travis_repo = JSON.parse(@conn.get("repo/#{CGI.escape(@identifier)}").body)
  end

  def default_branch
    @travis_repo['default_branch']['name']
  end

  def travis_builds
    @travis_builds = JSON.parse(@conn.get("repos/#{CGI.escape(@identifier)}/builds").body)['builds']
  end

  def master_builds
    @travis_builds.select { |bd| bd['branch']['name'].eql? default_branch }
  end

  def travis_logs
    jobs = master_builds.first['jobs']
    @travis_logs = jobs.map do |job|
      @conn.get do |req|
        req.url "job/#{job['id']}/log"
        req.headers['Accept'] = 'plain/text'
      end.body
    end
  end

  def fix_time
    failure_time = 0
    fix_times = 0
    prev_bd = nil
    master_builds.reverse.each do |bd|
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
    "https://travis-ci.com/#{@identifier}/builds/#{master_builds.first['id']}"
  end

end
