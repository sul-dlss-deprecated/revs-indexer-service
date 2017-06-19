set :bundle_without, %w{deployment test development}.join(' ')
set :rails_env, "production"
server "revs-indexing-stage.stanford.edu", user: 'harvestdor', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
