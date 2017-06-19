set :bundle_without, %w{deployment test}.join(' ')
set :rails_env, "development"
server "revs-indexing-dev.stanford.edu", user: 'harvestdor', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!

