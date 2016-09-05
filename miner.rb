require "rubygems"
require "rest-client"
require "upwork/api"
require 'upwork/api/routers/auth'
require 'upwork/api/routers/jobs/search'
require "parseconfig"

class Miner
  SECRETS_FILE = './secrets.conf'
  CONFIG = ParseConfig.new(SECRETS_FILE)

  def run
    job_hash = query_jobs
    latest_job = job_hash["jobs"].first

    if CONFIG['latest_job_id'] != latest_job["id"]
      update_latest_job(latest_job["id"])
      send_notification(latest_job)
    end
  end

  def client
    @client ||= Upwork::Api::Client.new(config)
  end

  def jobs
    @jobs ||= Upwork::Api::Routers::Jobs::Search.new(client)
  end

  def query_jobs(q = 'rails')
    jobs.find({ q: q })
  end

  private

  def update_latest_job(latest_job_id) 
    file_lines = ''

    IO.readlines(SECRETS_FILE).each do |line|
      if line.include?("latest_job")
        file_lines += "latest_job_id = \"#{latest_job_id}\""
      else
        file_lines += line
      end
    end

    file = File.open(SECRETS_FILE, 'w') do |file|
      file.puts file_lines
    end
  end

  def send_notification(latest_job)
    system("osascript -e 'display notification \"#{latest_job["title"]}\" with title \"Upwork\" sound name \"Glass\"'")
  end

  def config
    @config ||= Upwork::Api::Config.new({
      'consumer_key'    => CONFIG['consumer_key'],
      'consumer_secret' => CONFIG['consumer_secret'],
      'access_token'    => CONFIG['access_token'],
      'access_secret'   => CONFIG['access_secret']
    })
  end
end

Miner.new.run
