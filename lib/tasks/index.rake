require 'retries'

desc 'Index a specific list of druids from a pre-assembly log YAML file (or a remediate log file).  Specify target to index into and log file to index from.'
#Run me: rake log_indexer RAILS_ENV=production target=revs_prod log_file=/tmp/mailander_1.yaml log_type=preassembly 
# Examples:
task :log_indexer => :environment do |t, args|

  target = ENV['target'] # must pass in the target so specify solr core to index into
  log_file_path = ENV['log_file'] # must specify pre-assembly log file to index from
  log_type = ENV['log_type'] || 'preassembly' # log type (either preassembly or remediate)
  
  raise 'You must specify a target and log file.' if target.blank? || log_file_path.blank?
  raise 'Log type must be preassembly or remediate.' unless ['preassembly','remediate'].include? log_type
  raise 'Log file not found.' unless File.readable? log_file_path
  
  target_config=BaseIndexer.solr_configuration_class_name.constantize.instance.get_configuration_hash[target]
  
  raise 'Target not found.' if target_config.nil?
  
  if log_type.blank? || log_type == 'preassembly'
    log_completed=:pre_assem_finished
  elsif log_type == 'remediate'
    log_completed=:remediate_completed
  end
  
  start_time=Time.now
  
  errors=0
  indexed=0

  druids=[]
  YAML.load_stream(IO.read(log_file_path)) { |obj| druids << obj[:pid] if obj[log_completed] == true}  

  solr_server=BaseIndexer.solr_configuration_class_name.constantize.instance.get_configuration_hash[target]['url']
  
  puts "** Indexing #{druids.size} druids from #{log_file_path} into solr server #{solr_server} (target=#{target}).  Log file is of type #{log_type}."
  puts "Indexing started at #{start_time}"

  indexer = BaseIndexer::MainIndexerEngine.new

  counter=0
  
  druids.each_with_index do |druid,n|
  
    druid.gsub!('druid:','')
    counter+=1
    
    begin
      with_retries(:max_tries => 5, :base_sleep_seconds => 3, :max_sleep_seconds => 60) do
        indexer.index(druid,[target]) 
        puts "#{counter} of #{druids.size}: #{druid}"
        indexed += 1
      end
    rescue  => e
      puts "ERROR: Failed to index #{druid}: #{e.message}"
      errors += 1
    end

  end
  
  puts "Objects indexed: #{indexed} out of #{druids.size}"
  puts "ERRORS Encountered, #{errors} objects not indexed" if errors > 0
  puts "Completed at #{Time.now}, total time was #{'%.2f' % ((Time.now - start_time)/60.0)} minutes"
  
end
  
desc 'Index a single druid.  Specify target to index into and druid to index.'
#Run me: rake index RAILS_ENV=production target=revs_prod druid=oo000oo0001
# Examples:
task :index => :environment do |t, args|

  target = ENV['target'] # must pass in the target so specify solr core to index into
  druid = ENV['druid'] 
  
  raise 'You must specify a target and druid.' if target.blank? || druid.blank?
  
  target_config=BaseIndexer.solr_configuration_class_name.constantize.instance.get_configuration_hash[target]
  
  raise 'Target not found.' if target_config.nil?

  solr_server=BaseIndexer.solr_configuration_class_name.constantize.instance.get_configuration_hash[target]['url']
  
  puts "** Indexing #{druid} druid into solr server #{solr_server} (target=#{target})."

  indexer = BaseIndexer::MainIndexerEngine.new
  indexer.index(druid.gsub('druid:',''),[target]) 
  
end

desc 'Index an entire collection, including the collection itself and all of its members.  Specify target to index into and collection druid to index.'
#Run me: rake index_collection RAILS_ENV=production target=revs_prod collection_druid=oo000oo0001
# Examples:
task :index_collection => :environment do |t, args|

  target = ENV['target'] # must pass in the target so specify solr core to index into
  collection_druid = ENV['druid'] 
  
  raise 'You must specify a target and collection druid.' if target.blank? || collection_druid.blank?
  
  target_config=BaseIndexer.solr_configuration_class_name.constantize.instance.get_configuration_hash[target]
  
  raise 'Target not found.' if target_config.nil?

  solr_server=BaseIndexer.solr_configuration_class_name.constantize.instance.get_configuration_hash[target]['url']
  
  puts "** Indexing collection #{collection_druid} druid and all of its members into solr server #{solr_server} (target=#{target})."

  start_time=Time.now
  puts "Indexing started at #{start_time}"

  indexer = BaseIndexer::MainIndexerEngine.new

  df = DorFetcher::Client.new({:service_url => Rails.application.config.dor_fetcher_url})

  collection_druid=collection_druid.gsub('druid:','')
  
  indexer.index(collection_druid,[target]) 

  druids = df.druid_array(df.get_collection(collection_druid, {}))

  puts "** Found #{druids.size} members of the collection"

  counter=0
  indexed=0
  errors=0
  
  druids.each_with_index do |druid,n|
  
    druid=druid.gsub('druid:','')
    counter+=1
    
    begin
      with_retries(:max_tries => 5, :base_sleep_seconds => 3, :max_sleep_seconds => 60) do
        indexer.index(druid,[target]) 
        puts "#{counter} of #{druids.size}: #{druid}"
        indexed += 1
      end
    rescue  => e
      puts "ERROR: Failed to index #{druid}: #{e.message}"
      errors += 1
    end

  end
  
  puts "Objects indexed: #{indexed} out of #{druids.size}"
  puts "ERRORS Encountered, #{errors} objects not indexed" if errors > 0
  puts "Completed at #{Time.now}, total time was #{'%.2f' % ((Time.now - start_time)/60.0)} minutes"
  
end  

desc 'ReIndex jsut the druids that errored out from a previous batch index run. Specify target to index into and batch errored log file to index from.'
#Run me: rake reindex_errors RAILS_ENV=production target=revs_prod file=nohup.out
# Examples:
task :reindex_errors => :environment do |t, args|

  target = ENV['target'] # must pass in the target so specify solr core to index into
  file_path = ENV['file'] # must specify previous indexing log file to index from
  
  raise 'You must specify a target and file.' if target.blank? || file_path.blank?
  raise 'File not found.' unless File.readable? file_path
  
  target_config=BaseIndexer.solr_configuration_class_name.constantize.instance.get_configuration_hash[target]
  
  raise 'Target not found.' if target_config.nil?

  start_time=Time.now
  
  errors=0
  indexed=0

  solr_server=BaseIndexer.solr_configuration_class_name.constantize.instance.get_configuration_hash[target]['url']
  
  puts "** Indexing errored out druids from #{file_path} into solr server #{solr_server} (target=#{target})."
  puts "Indexing started at #{start_time}"

  indexer = BaseIndexer::MainIndexerEngine.new

  counter=0

  IO.readlines(file_path).each do |line|

    downcased_line=line.downcase
  
    if downcased_line.include? 'error'
      druid=downcased_line.scan(/[a-z][a-z][0-9][0-9][0-9][a-z][a-z][0-9][0-9][0-9][0-9]/).first
  
      counter+=1
    
      begin
        with_retries(:max_tries => 5, :base_sleep_seconds => 3, :max_sleep_seconds => 60) do
          indexer.index(druid,[target]) 
          puts "#{counter}: #{druid}"
          indexed += 1
        end
      rescue  => e
        puts "ERROR: Failed to index #{druid}: #{e.message}"
        errors += 1
      end
    
    end
    
  end
  
  puts "Objects indexed: #{indexed}"
  puts "ERRORS Encountered, #{errors} objects not indexed" if errors > 0
  puts "Completed at #{Time.now}, total time was #{'%.2f' % ((Time.now - start_time)/60.0)} minutes"
  
end

desc 'Delete the druids specified in the supplied text file (one druid per line, header not necessary).  Be careful!  It will delete from all targets.'
#Run me: rake delete_druids RAILS_ENV=production file=druid_list.txt
# Examples:
task :delete_druids => :environment do |t, args|

  file_path = ENV['file'] # must specify previous indexing log file to index from
  
  raise 'You must specify a druid file.' if file_path.blank?
  raise 'File not found.' unless File.readable? file_path

  print "Are you sure you wish to delete all of the druids from all targets specified in #{file_path}? (y/n) "
  STDOUT.flush  
  answer=STDIN.gets.chomp
  
  raise 'STOP!' unless (answer && ['y','yes'].include?(answer.downcase))
  
  start_time=Time.now
  
  errors=0
  indexed=0
  
  puts "** Deleting druids from #{file_path} in all targets."
  puts "Deleting started at #{start_time}"

  indexer = BaseIndexer::MainIndexerEngine.new

  counter=0

  IO.readlines(file_path).each do |line|

     downcased_line=line.downcase
     druid=downcased_line.scan(/[a-z][a-z][0-9][0-9][0-9][a-z][a-z][0-9][0-9][0-9][0-9]/).first
  
     unless druid.nil?
       counter+=1
    
        begin
          with_retries(:max_tries => 5, :base_sleep_seconds => 3, :max_sleep_seconds => 60) do
            indexer.delete druid
            puts "#{counter}: #{druid}"
            indexed += 1
          end
        rescue  => e
          puts "ERROR: Failed to delete #{druid}: #{e.message}"
          errors += 1
        end
     end    
  end
  
  puts "Objects deleted: #{indexed}"
  puts "ERRORS Encountered, #{errors} objects not deleted" if errors > 0
  puts "Completed at #{Time.now}, total time was #{'%.2f' % ((Time.now - start_time)/60.0)} minutes"
  
end