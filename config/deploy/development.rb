set :bundle_without, %w{deployment test}.join(' ')
set :rails_env, "development"
set :deploy_host, "revs-indexing-dev"
server "#{fetch(:deploy_host)}.stanford.edu", user: fetch(:user), roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!

namespace :deploy do
  namespace :assets do
    task :symlink do ; end
    task :precompile do ; end
  end
end
