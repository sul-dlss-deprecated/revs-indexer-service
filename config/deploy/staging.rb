set :bundle_without, %w{deployment test development}.join(' ')
set :rails_env, "production"
set :deploy_host, "revs-indexing-stage"
server "#{fetch(:deploy_host)}.stanford.edu", user: fetch(:user), roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
