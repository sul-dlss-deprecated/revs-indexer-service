require 'revs-utils'

class RevsMapper < DiscoveryIndexer::Mapper::GeneralMapper 

  include Revs::Utils

  ARCHIVE_DRUIDS={:revs=>'nt028fd5773',:roadandtrack=>'mr163sv5231'}  # a hash of druids of the master archives, keys are arbitrary but druids must match the druids in DOR
                                                                      #  these druids will be used to set the archive name in each document
  MULTI_COLLECTION_ARCHIVES=[:revs] # list the keys from the has above for any archives that contain multiple collections (like Revs), for which each item in DOR belongs to both a parent collection and the master archive collection ... since we do not want to also add the master archive name as another collection druid to each record, we skip them
  
  # @druid   ==  druid pid
  # @modsxml == Stanford::Mods::Record class object
  # @modsxml.mods_ng_xml == Nokogiri document (for custom parsing)
  # @purlxml == DiscoveryIndexer::InputXml::PurlxmlModel class object
  # @purlxml.public_xml == Nokogiri document (for custom parsing)
  # @collection_names = hash of collection_druid and
  # collection_name !{"aa111aa1111"=>"First Collection", "bb123bb1234"=>"Second Collection"}

  # Create a Hash representing a Solr doc, with all MODS related fields populated.
  # @return [Hash] Hash representing the Solr document
  def convert_to_solr_doc

    # basic fields
    doc_hash = { 
      
      # title fields
      :id => @druid, 
      :title_tsi => @modsxml.title_info.title.text.strip,
      :image_id_ssm => strip_extensions(@purlxml.image_ids),
      :source_id_ssi => source_id,
      :copyright_ss => copyright,
      :use_and_reproduction_ss => use_and_reproduction
   }

   pub_date=@modsxml.origin_info.dateCreated.text.strip

   # add archive to each solr doc
   @collection_names.each { |coll_druid,coll_name|  
     if ARCHIVE_DRUIDS.has_value?(coll_druid) # if this is an archive level collection, add it
       doc_hash[:archive_ssi] = clean_collection_name(coll_name)
     end
   }   
   
    if @purlxml.is_collection # if a collection, add the right format and grab the abstract as the description
      doc_hash[:format_ssim] = 'collection'
      doc_hash[:description_tsim] = @modsxml.abstract.text.strip
    else # if not a collection, lets dig into the other relevant fields, e.g. notes fields for descriptions and other notes; subject field, etc.
      formats=collect_values(@modsxml.related_item.physicalDescription.form)
      set_value_or_add(doc_hash,:format_ssim,formats.presence || ['unspecified'])

      # determine collection druids and their titles and add to solr doc
      unless @collection_names.blank?
        doc_hash[:collection_ssim] = []
        doc_hash[:is_member_of_ssim] = []
        @collection_names.each { |coll_druid,coll_name|  
          unless (ARCHIVE_DRUIDS.has_value?(coll_druid) && MULTI_COLLECTION_ARCHIVES.include?(ARCHIVE_DRUIDS.key(coll_druid))) # skip the master Revs Institute Collection when adding collections we belong to
            doc_hash[:is_member_of_ssim] << coll_druid
            doc_hash[:collection_ssim] << clean_collection_name(coll_name)
          end
        }
      end   

      full_date=get_full_date(pub_date)
      if full_date # if the date field in MODs has a valid full date, extract the year into the single and multi-valued year fields
        doc_hash[:pub_year_isim]=[full_date.year.to_s]
        doc_hash[:pub_year_single_isi]=full_date.year.to_s        
        doc_hash[:pub_date_ssi]=full_date.strftime('%-m/%-d/%Y')
      else # if the date field in MODs has something other than a valid full date, it should be a year or list of years, so parse and add it
        doc_hash[:pub_year_isim]=[]
        all_years=parse_years(pub_date)
        all_years.each {|pub_year| set_value_or_add(doc_hash,:pub_year_isim,pub_year) if is_valid_year? pub_year} # convert single date string field into an array of valid integer years
        set_value_or_add(doc_hash,:pub_year_single_isi,all_years[0]) if all_years.size == 1 && is_valid_year?(all_years[0])
        doc_hash.delete(:pub_year_isim) if doc_hash[:pub_year_isim]==[]
      end
      doc_hash[:type_of_resource_ssi] = @modsxml.typeOfResource.text.strip.presence || "still image"
      doc_hash[:genre_ssi] = @modsxml.genre.text.strip.presence || "digital image"
      @modsxml.subject.each do |subject| # loop over all subject nodes
       case subject['displayLabel']  # the display label tells us which solr field to go to
          when nil  # subject field
            field_name=:subjects_ssim
            values=collect_values(subject.topic) # multivalued topic field
          when "Marque"
            field_name=:marque_ssim
            values=collect_values(subject.topic)  # multivalued topic field
          when "People"
             field_name=:people_ssim
             values=collect_values(subject.name_el) # multivalued name field
          when "Model"
            field_name=:model_ssim
            values=collect_values(subject.topic) # multivalued name field
          when "Entrant"
            field_name=:entrant_ssi
            values=get_value(subject.name_el) # single valued name field
          when "Current Owner"
            field_name=:current_owner_ssi
            values=get_value(subject.name_el) # single valued name field
          when "Venue"
            field_name=:venue_ssi
            values=get_value(subject.topic) # single valued topic field
          when "Track"
            field_name=:track_ssi
            values=get_value(subject.topic) # single valued topic field
          when "Event"
            field_name=:event_ssi
            values=get_value(subject.topic) # single valued topic field
         end
        set_value_or_add(doc_hash,field_name,values) if values
      end
      
      # grab photographer
      @modsxml.plain_name.each do |name|
        if name['id'] == 'photographer'
          field_name=:photographer_ssi
          set_value_or_add(doc_hash,field_name,name.namePart.text)
        end  
      end
      
      @modsxml.subject.each do |subject| # loop over all subject nodes again to look for hierarchical geographic nodes
        if subject['displayLabel']=="Location"  # only want location nodes
          hierarchical_geographic=subject.hierarchicalGeographic
          if hierarchical_geographic.size == 1 # we have some entries
            locations=hierarchical_geographic.first
            countries=collect_values(locations.country).join(', ')
            states=collect_values(locations.state).join(', ')
            cities=collect_values(locations.city).join(', ')
            city_sections=collect_values(locations.citySection).join(', ')
            set_value_or_add(doc_hash,:countries_ssi,countries) if countries.size > 0
            set_value_or_add(doc_hash,:states_ssi,states) if states.size > 0
            set_value_or_add(doc_hash,:cities_ssi,cities) if cities.size > 0
            set_value_or_add(doc_hash,:city_sections_ssi,city_sections) if city_sections.size > 0
          end
        end
      end
  
      notes=@modsxml.note
      notes.each do |note|
        if note.attributes['ID'].nil? && note.attributes['type'].nil?  # plain description field has no ID or type
          doc_hash[:description_tsim] = note.text.strip
        elsif !note.attributes['ID'].nil? # extra source note fields have an ID and sometimes a type
          set_value_or_add(doc_hash,:model_year_ssim,note.text.strip.split("|")) if note.attributes['ID'].text == 'model_year' # model year
          doc_hash[:has_more_metadata_ssi] = note.text.strip if note.attributes['ID'].text == 'has_more_metadata' # has_more_metadata
          doc_hash[:inst_notes_tsi] = note.text.strip if note.attributes['ID'].text == 'inst_notes' # institution notes
          doc_hash[:prod_notes_tsi] = note.text.strip if note.attributes['ID'].text == 'prod_notes' # production notes
          doc_hash[:group_class_tsi] = note.text.strip if note.attributes['ID'].text == 'group' # group/class
          doc_hash[:race_data_tsi] = note.text.strip if note.attributes['ID'].text == 'race_data' # race data
          doc_hash[:metadata_sources_tsi] = note.text.strip if note.attributes['ID'].text == 'metadata_sources' # metadata sources
          doc_hash[:vehicle_markings_tsi] = note.text.strip if note.attributes['ID'].text == 'vehicle_markings' # vehicle markings
          doc_hash[:visibility_isi] = 0 if note.attributes['ID'].text == 'visibility' && ['hidden','0','hide'].include?(note.text.strip.downcase) # visibility
        end
      end
    end
    
    raise 'no image found' if (!@purlxml.is_collection && doc_hash[:image_id_ssm].nil?)
        
    doc_hash
  end

  def copyright
    copyright_text= @purlxml.copyright
    # if we still have the old object rights in the object, index it with the corrected rights so it looks correct in the website at least
    if @purlxml.copyright == 'Courtesy of the Revs Institute for Automotive Research. All rights reserved unless otherwise indicated.'
      copyright_text = 'Courtesy of The Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.'
    end
    return copyright_text
  end
  
  def use_and_reproduction
    use_text= @purlxml.use_and_reproduction
    # if we still have the old usage text in the object, index it with the corrected text so it looks correct in the website at least
    if use_text == 'Users must contact the The Revs Institute for Automotive Research for re-use and reproduction information.'
      use_text = 'Users must contact The Revs Institute for Automotive Research, Inc. for re-use and reproduction information.'
    end
    return use_text
  end
  
  # If MODS record has a top level typeOfResource element with value 'still image'
  #  (<mods><typeOfResource>still image<typeOfResource>) then return true; false otherwise
  # @return true if MODS indicates this is an image object
  def image?
    @modsxml.typeOfResource.each { |n|  
      return true if n.text.strip == 'still image'
    }
    false
  end
      
  # try to get the sourceID first from the MODs record, second from identity metadata 
  def source_id
    sourceid=@purlxml.source_id
    return @modsxml.identifier.text.strip.presence || sourceid || ""
  end

  # pass in the doc_hash, the field name and the values; sets the value if none is set yet, or adds to it if its already there
  def set_value_or_add(doc_hash,field_name,values)
    doc_hash[field_name].nil? ? doc_hash[field_name]=values : doc_hash[field_name]<<values # set the value or add to it if it already exists 
    if doc_hash[field_name].class == Array 
      doc_hash[field_name].flatten!     # flatten if this field is an array so we don't get array of arrays for multivalued
      doc_hash[field_name].collect(&:strip!) # strip trailing/leading whitespace from all elements
    else
      doc_hash[field_name].strip!
    end
    return doc_hash
  end    
  
  # strip extensions of all files passed in 
  def strip_extensions(filenames)
    return nil if filenames.blank?
    filenames=[filenames] unless filenames.class == Array
    filenames.collect {|filename|  File.basename(filename,File.extname(filename))} # strip off extensions
  end
  
   # if the node exists, get its vakue, otherwise return blank string 
  def get_value(value)
    value.first ? value.first.text.strip : '' 
  end
  
  # collect value of nodes into an array
  def collect_values(values)
    return values.collect {|value| value.text.strip} 
  end
  
end