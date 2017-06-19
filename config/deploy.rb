set :application, "revs-indexer-service"
set :repo_url, "https://github.com/sul-dlss/revs-indexer-service"

set :deploy_to, "/opt/app/harvestdor/#{fetch(:application)}"

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/honeybadger.yml config/secrets.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system config/settings}

last_tag = `git describe --abbrev=0 --tags`.strip
default_tag='master'
set :tag, ask("Tag to deploy (make sure to push the tag first): [default: #{default_tag}, last tag: #{last_tag}] ", default_tag)

set :branch, fetch(:tag)

set :honeybadger_env, "#{fetch(:stage)}"

# update shared_configs before restarting app
before 'deploy:restart', 'shared_configs:update'