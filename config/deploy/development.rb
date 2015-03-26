set :bundle_without, %w{deployment test}.join(' ')
set :rails_env, "development"

Capistrano::OneTimeKey.generate_one_time_key!

namespace :deploy do
  namespace :assets do
    task :symlink do ; end
    task :precompile do ; end
  end
end