set :bundle_without, %w{deployment test development staging}.join(' ')
set :rails_env, "production"
server "revs-indexing-prod.stanford.edu", user: 'harvestdor', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
