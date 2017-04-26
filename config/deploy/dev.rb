set :bundle_without, %w{deployment test}.join(' ')
set :rails_env, "development"
Capistrano::OneTimeKey.generate_one_time_key!

