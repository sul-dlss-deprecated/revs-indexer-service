require "rails_helper"

describe RevsMapper do
  
  it "should properly map revs object" do
    setup('bb895tg4452','mods_xml.xml','purl_xml.xml')
    expected_doc_hash=
      {       
         :id =>@pid,
         :collection_ssim => ["Test Collection Name"],
         :is_member_of_ssim => ["aa00bb0001"],
         :title_tsi=>"aa'this is < a label with an & that will break XML unless it is escaped' is the label!",
         :format_ssim=>["color transparencies"],
         :image_id_ssm=>["2012-027NADI-1968-b2_8.3_0020.jp2"],
         :source_id_ssi=>"foo-1",
         :pub_year_isim=>["1966"],
         :pub_year_single_isi=>"1966",
         :type_of_resource_ssi=>"still image",
         :genre_ssi=>"digital image",
         :subjects_ssim=>["Automobile", "History"],
         :marque_ssim=>["Ford automobile", "Jaguar", "Pegaso automobile", "Suzuki automobile"],
         :model_ssim=>["911", "Mustang"],
         :photographer_ssi=>"Adams, Ansel",
         :countries_ssi=>"United States",
         :states_ssi=>"California",
         :cities_ssi=>"San Mateo",
         :city_sections_ssi=>"Bay Motor Speedway",
         :model_year_ssim=>["1955","1956"],
         :description_tsim=>"ERB Test: this is a description > another description < other stuff",
         :track_ssi => "Bay Motor Speedway Track",
         :vehicle_markings_tsi => "vehicle markigns go here",
         :venue_ssi => "Bay Motor Speedway Venue",
         :current_owner_ssi => "Owner Last, First",
         :entrant_ssi => "Entrant Last, First",
         :event_ssi => "Bay Motor Speedway Race",
         :group_class_tsi => "something in a group or class",
         :has_more_metadata_ssi => "yes",
         :inst_notes_tsi => "these are some institution notes",
         :race_data_tsi => "Lots of race data",
         :prod_notes_tsi => "prod notes when scanning",
         :metadata_sources_tsi => "metadata sources go here",
         :people_ssim => ["Another personal name", "First personal name"],
         :visibility_isi => 0,
         :copyright_ss => "Courtesy of The Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.",
         :use_and_reproduction_ss => "Users must contact The Revs Institute for Automotive Research for re-use and reproduction information."
       }

    expect(@indexer.map).to eq(expected_doc_hash)
  end

  it "should properly determine object type from identityMetadata" do
    
    # doc=SolrDocBuilder.new('oo000oo0001',Object.new,Object.new,:mods=>@basic_mods_xml,:public_xml=>@public_xml_with_sourceid)
    # doc.collection?.should be_falsey
    #
    # doc=SolrDocBuilder.new('oo000oo0001',Object.new,Object.new,:mods=>@basic_mods_xml,:public_xml=>@public_xml)
    # doc.collection?.should be_falsey
    #
    # doc=SolrDocBuilder.new('oo000oo0001',Object.new,Object.new,:mods=>@basic_mods_xml,:public_xml=>@public_xml_for_set)
    # doc.collection?.should be_truthy
    #
    # doc=SolrDocBuilder.new('oo000oo0001',Object.new,Object.new,:mods=>@basic_mods_xml,:public_xml=>@public_xml_for_collection)
    # doc.collection?.should be_truthy
        
  end

  it "should properly index a collection" do
  
    # doc.collection?.should be_truthy
    
    setup('bc915dc7146','mods_basic_collection.xml','purl_xml_collection.xml')
    
    expected_doc_hash=
      {
         :id=>"bc915dc7146",
         :title_tsi=>"The Road  Track Archive",
         :description_tsim=>"The Road  Track Archive contains the library of files from Road  Track magazine's 65-year history.  The archive includes images, notes, performance data and other types of documents and research that supported production of the magazine over its history.",
         :format_ssim=>"collection",
         :image_id_ssm=>nil,
         :source_id_ssi=>"",
         :copyright_ss => "Courtesy of The Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.",
         :use_and_reproduction_ss => "Users must contact The Revs Institute for Automotive Research for re-use and reproduction information."
       }    
       
    expect(@indexer.map).to eq(expected_doc_hash)
       
  end
    
end
  