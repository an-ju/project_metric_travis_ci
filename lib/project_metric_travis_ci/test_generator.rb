class ProjectMetricTravisCi
  def self.fake_data
    [fake_metric(10), fake_metric(15), fake_metric(20)]
  end

  def self.fake_metric(value)
    build_states = Array.new(value, true) + Array.new(30 - value, false)
    build_states.shuffle!
    builds = build_states.map.with_index do |is_failure, ind|
      is_failure ? bad_build(ind, build_states[ind-1]) : good_build(ind, build_states[ind-1])
    end
    { image:
          { chartType: 'travis_ci',
            data:
                { builds: builds,
                  build_link: 'https://travis-ci.com/an-ju/project_metric_code_climate/builds/90357060',
                  fix_time: 10 * rand(10) } },
      score: builds.first[:state].eql?('passed') ? 100 : 0 } 
  end

  def self.good_build(ind, prev_state)
    {
        '@type': "build",
        '@href': "/build/90357060",
        "@representation": "standard",
        "@permissions": {
            read: true,
            cancel: true,
            restart: true
        },
        id: 90357060 + ind,
        number: "1",
        state: "passed",
        duration: 51,
        event_type: "push",
        previous_state: (prev_state ? 'failed' : 'passed'),
        pull_request_title: nil,
        pull_request_number: nil,
        started_at: "2018-11-06T01:48:#{10+ind}Z",
        finished_at: "2018-11-06T01:58:#{10+ind}Z",
        private: false,
        repository: {
            '@type': "repository",
            '@href': "/repo/6784605",
            '@representation': "minimal",
            id: 6784605,
            name: "project_metric_code_climate",
            slug: "an-ju/project_metric_code_climate"
        },
        branch: {
            "@type": "branch",
            "@href": "/repo/6784605/branch/master",
            "@representation": "minimal",
            "name": "master"
        },
        tag: nil,
        commit: {
            "@type": "commit",
            "@representation": "minimal",
            "id": 147142508+ind,
            "sha": "b97b5445dd0286fa1e81763cbf5f12a1eb360#{10+ind}d",
            "ref": "refs/heads/master",
            "message": "Update codeclimate gem.",
            "compare_url": "https://github.com/an-ju/project_metric_code_climate/compare/871092c5d2a5...b97b5445dd02",
            "committed_at": "2018-11-06T01:47:#{10+ind}Z"
        },
        "jobs": [
            {
                "@type": "job",
                "@href": "/job/1565329#{10+ind}",
                "@representation": "minimal",
                "id": 156532910 + ind
            }
        ],
        "stages": [

        ],
        "created_by": {
            "@type": "user",
            "@href": "/user/431526",
            "@representation": "minimal",
            "id": 431526,
            "login": "an-ju"
        },
        "updated_at": "2018-11-06T01:49:01.966Z"
    }
  end


  def self.bad_build(ind, prev_state)
    {
        '@type': "build",
        '@href': "/build/90357060",
        "@representation": "standard",
        "@permissions": {
            read: true,
            cancel: true,
            restart: true
        },
        id: 90357060 + ind,
        number: "1",
        state: "failed",
        duration: 51,
        event_type: "push",
        previous_state: (prev_state ? 'failed' : 'passed'),
        pull_request_title: nil,
        pull_request_number: nil,
        started_at: "2018-11-06T01:48:#{10+ind}Z",
        finished_at: "2018-11-06T01:58:#{10+ind}Z",
        private: false,
        repository: {
            '@type': "repository",
            '@href': "/repo/6784605",
            '@representation': "minimal",
            id: 6784605,
            name: "project_metric_code_climate",
            slug: "an-ju/project_metric_code_climate"
        },
        branch: {
            "@type": "branch",
            "@href": "/repo/6784605/branch/master",
            "@representation": "minimal",
            "name": "master"
        },
        tag: nil,
        commit: {
            "@type": "commit",
            "@representation": "minimal",
            "id": 147142508+ind,
            "sha": "b97b5445dd0286fa1e81763cbf5f12a1eb360#{10+ind}d",
            "ref": "refs/heads/master",
            "message": "Update codeclimate gem.",
            "compare_url": "https://github.com/an-ju/project_metric_code_climate/compare/871092c5d2a5...b97b5445dd02",
            "committed_at": "2018-11-06T01:47:#{10+ind}Z"
        },
        "jobs": [
            {
                "@type": "job",
                "@href": "/job/1565329#{10+ind}",
                "@representation": "minimal",
                "id": 156532910 + ind
            }
        ],
        "stages": [

        ],
        "created_by": {
            "@type": "user",
            "@href": "/user/431526",
            "@representation": "minimal",
            "id": 431526,
            "login": "an-ju"
        },
        "updated_at": "2018-11-06T01:49:01.966Z"
    }
  end
end