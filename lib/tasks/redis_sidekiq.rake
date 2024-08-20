namespace :redis_sidekiq do
  desc "Check connection to redis server"
  task check_connection: :environment do
    redis_conn = Sidekiq.redis { |conn| conn.info }
    if redis_conn.present?
      print "Sidekiq was able to establish connection with Redis server"
    else
      print "Sidekiq unable to establish connection with Redis server"
    end
  rescue Redis::CannotConnectError, RedisClient::CannotConnectError, Redis::ConnectionError
    print "Sidekiq unable to establish connection with Redis server"
  end

  desc "Retry dead jobs created from now to x days ago"
  task :retry_dead_jobs, [:days_from_now] => [:environment] do |t, args|
    days_from_now = args[:days_from_now].to_i
    if days_from_now == 0
      print "You must enter a valid integer greater than 0"
      next
    end

    ds = Sidekiq::DeadSet.new
    retry_counter = 0
    job_counter = 0
    time_from = days_from_now.days.ago

    ds.each do |job|
      if job.at  >= time_from
        job_counter += 1
        if job.retry
          retry_counter += 1
          print "Retried job with jid: #{job.jid}\n"
        else
          print "Failed to retry job with jid: #{job.jid}\n"
        end
      end
    end

    print "#{job_counter} job(s) found\n"
    print "#{retry_counter} job(s) retried"
  end
end
