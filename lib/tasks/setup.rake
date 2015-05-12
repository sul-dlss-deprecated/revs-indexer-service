desc "Copy configuration files"
task :config do
  config_files = %w{database.yml solr.yml secrets.yml}
  config_files.each do |config_file|
    cp("#{Rails.root}/config/#{config_file}.example", "#{Rails.root}/config/#{config_file}") unless File.exists?("#{Rails.root}/config/#{config_file}.yml")
  end
end 