require "rails_helper"

describe RevsMapper do

  it "should properly map revs object, getting sourceID from MODs instead of purl if it exists, single year only" do

    setup('bb895tg4452','mods_xml.xml','purl_xml.xml')

    expected_doc_hash=
      {
         :id =>@pid,
         :collection_ssim => ["Test Collection Name"],
         :is_member_of_ssim => ["aa00bb0001"],
         :title_tsi=>"aa'this is < a label with an & that will break XML unless it is escaped' is the label!",
         :format_ssim=>["color transparencies"],
         :original_size_ssi=>'6" x 5"',
         :image_id_ssm=>["2012-027NADI-1968-b2_8.3_0020"],
         :source_id_ssi=>"foo-mods",
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
         :vehicle_markings_tsi => "vehicle markings go here",
         :venue_ssi => "Bay Motor Speedway Venue",
         :current_owner_ssi => "Owner Last, First",
         :entrant_ssi => "Entrant Last, First",
         :event_ssi => "Bay Motor Speedway Race",
         :group_class_tsi => "something in a group or class",
         :group_ssim => ["something in a group"],
         :class_ssi => "something in a class",
         :has_more_metadata_ssi => "yes",
         :inst_notes_tsi => "these are some institution notes",
         :race_data_tsi => "Lots of race data",
         :prod_notes_tsi => "prod notes when scanning",
         :metadata_sources_tsi => "metadata sources go here",
         :people_ssim => ["Another personal name", "First personal name"],
         :score_isi=>94,
         :copyright_ss => "Courtesy of The Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.",
         :use_and_reproduction_ss => "Users must contact The Revs Institute for Automotive Research, Inc. for re-use and reproduction information.",
         :archive_ssi => "Revs Institute Archive"
       }

    expect(@indexer.convert_to_solr_doc).to eq(expected_doc_hash)

  end

  it "should properly determine object type from identityMetadata" do

    setup('bc915dc7146','mods_basic_collection.xml','purl_xml_collection.xml')
    expect(@purl.is_collection).to be_truthy

    setup('bc915dc7146','mods_basic_collection.xml','purl_xml_set.xml')
    expect(@purl.is_collection).to be_truthy

    setup('bb895tg4452','mods_xml.xml','purl_xml.xml')
    expect(@purl.is_collection).to be_falsey

  end

  it "should indicate if an item is an image or not" do

    # a collection is not an image
    setup('bc915dc7146','mods_basic_collection.xml','purl_xml_collection.xml')
    expect(@indexer.image?).to be_falsey

    # a revs item is an image
    setup('bc915dc7146','mods_xml.xml','purl_xml.xml')
    expect(@indexer.image?).to be_truthy

  end

  it "should properly index a collection" do

    setup('bc915dc7146','mods_basic_collection.xml','purl_xml_collection.xml')

    expect(@purl.is_collection).to be_truthy

    expected_doc_hash=
      {
         :id=>"bc915dc7146",
         :title_tsi=>"The Road  Track Archive",
         :description_tsim=>"The Road  Track Archive contains the library of files from Road  Track magazine's 65-year history.  The archive includes images, notes, performance data and other types of documents and research that supported production of the magazine over its history.",
         :format_ssim=>"collection",
         :image_id_ssm=>nil,
         :source_id_ssi=>"",
         :score_isi=>10,
         :copyright_ss => "Courtesy of The Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.",
         :use_and_reproduction_ss => "Users must contact The Revs Institute for Automotive Research for re-use and reproduction information.",
         :archive_ssi => "Revs Institute Archive"
       }

    expect(@indexer.convert_to_solr_doc).to eq(expected_doc_hash)

  end

  it "should generate the correct archive_ssi field for road & track" do

    setup('oo000oo0001','mods_xml.xml','purl_xml.xml',{'mr163sv5231'=>{:label=>'Road & Track Archive',:catkey=>'oooooo'}})
    doc=basic_mods
    @mods.from_nk_node(Nokogiri::XML(doc)) # replace mods with our own
    expected_doc_hash=basic_expected_doc_hash
    expected_doc_hash[:archive_ssi]='Road & Track Archive'
    expected_doc_hash[:collection_ssim]=['Road & Track Archive']
    expected_doc_hash[:is_member_of_ssim]=['mr163sv5231']
    expect(@indexer.convert_to_solr_doc).to eq(expected_doc_hash)

    setup('oo000oo0001','mods_xml.xml','purl_xml.xml',{'aa00bb0001'=>{:label=>'Test Collection Name',:catkey=>nil},'mr163sv5231'=>{:label=>'Road & Track Archive',:catkey=>'oooooo'}})
    doc=basic_mods
    @mods.from_nk_node(Nokogiri::XML(doc)) # replace mods with our own
    expected_doc_hash=basic_expected_doc_hash
    expected_doc_hash[:archive_ssi]='Road & Track Archive'
    expected_doc_hash[:collection_ssim]=['Test Collection Name','Road & Track Archive']
    expected_doc_hash[:is_member_of_ssim]=['aa00bb0001','mr163sv5231']
    expect(@indexer.convert_to_solr_doc).to eq(expected_doc_hash)

  end

  it "should not add an archive to the record if a known one is not present in the object" do

    setup('oo000oo0001','mods_xml.xml','purl_xml.xml',{'aa00bb0001'=>{:label=>'Test Collection Name',:catkey=>nil}})
    doc=basic_mods
    @mods.from_nk_node(Nokogiri::XML(doc)) # replace mods with our own
    expected_doc_hash=basic_expected_doc_hash
    expected_doc_hash.delete(:archive_ssi)
    expect(@indexer.convert_to_solr_doc).to eq(expected_doc_hash)

  end

  it "should throw an exception if no images are found" do

    setup('oo000oo0001','mods_minimal.xml','purl_xml_missing_image.xml')
    expect{@indexer.convert_to_solr_doc}.to raise_error

  end

  it "should properly set the sourceID value from identityMetadata if it does not exist in MODs" do

    setup('oo000oo0001','mods_minimal.xml','purl_xml.xml')

    expected_doc_hash=
      {
         :source_id_ssi=>'foo-purl',
         :id => 'oo000oo0001',
         :title_tsi=>"Test Title",
         :format_ssim=>["unspecified"],
         :genre_ssi => "digital image",
         :type_of_resource_ssi => "still image",
         :copyright_ss => "Courtesy of The Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.",
         :use_and_reproduction_ss => "Users must contact The Revs Institute for Automotive Research, Inc. for re-use and reproduction information.",
         :image_id_ssm => ["2012-027NADI-1968-b2_8.3_0020"],
         :is_member_of_ssim => ["aa00bb0001"],
         :collection_ssim => ["Test Collection Name"],
         :score_isi=>0,
         :archive_ssi => "Revs Institute Archive"
       }

      expect(@indexer.convert_to_solr_doc).to eq(expected_doc_hash)

  end

  it "should properly downcase the format value" do

    setup('oo000oo0001','mods_basic_alt_format.xml','purl_xml.xml')

    expected_doc_hash=
      {
         :source_id_ssi=>'foo-2',
         :id => 'oo000oo0001',
         :title_tsi=>"This is a title",
         :format_ssim=>["glass negatives"],
         :genre_ssi => "digital image",
         :type_of_resource_ssi => "still image",
         :image_id_ssm => ["2012-027NADI-1968-b2_8.3_0020"],
         :is_member_of_ssim => ["aa00bb0001"],
         :collection_ssim => ["Test Collection Name"],
         :score_isi=>13,
         :description_tsim=>"Description",
         :subjects_ssim=>["Automobile", "History"],
         :archive_ssi => "Revs Institute Archive",
         :group_ssim => ["something in a group", "and another group"],
         :copyright_ss => "Courtesy of The Revs Institute for Automotive Research, Inc. All rights reserved unless otherwise indicated.",
         :use_and_reproduction_ss => "Users must contact The Revs Institute for Automotive Research, Inc. for re-use and reproduction information."
       }

      expect(@indexer.convert_to_solr_doc).to eq(expected_doc_hash)

  end

  it "should properly index a Revs MODs record with a multiple city section node" do

    doc=basic_mods + '<subject id="location" displayLabel="Location" authority="local"><hierarchicalGeographic><citySection>First guy</citySection><citySection>Another string</citySection></hierarchicalGeographic></subject>'
    expected_doc_hash=basic_expected_doc_hash.merge({:city_sections_ssi => "First guy, Another string",:score_isi=>20})
    should_match(doc,expected_doc_hash)

  end

  it "should ignore a Revs MODs record with visibility values" do

    doc=basic_mods + '<note type="source note" displayLabel="Visibility" ID="visibility">hidden</note>'
    should_match(doc,basic_expected_doc_hash.merge({:score_isi=>10}))
    doc=basic_mods + '<note type="source note" displayLabel="Visibility" ID="visibility">Hidden</note>'
    should_match(doc,basic_expected_doc_hash.merge({:score_isi=>10}))
    doc=basic_mods + '<note type="source note" displayLabel="Visibility" ID="visibility">0</note>'
    should_match(doc,basic_expected_doc_hash.merge({:score_isi=>10}))
    doc=basic_mods + '<note type="source note" displayLabel="Visibility" ID="visibility">yup</note>'
    should_match(doc,basic_expected_doc_hash.merge({:score_isi=>10}))
    doc=basic_mods + '<note type="source note" displayLabel="Visibility" ID="visibility"></note>'
    should_match(doc,basic_expected_doc_hash.merge({:score_isi=>10}))

  end

  it "should properly index a Revs MODs record with no city section node" do

    doc=basic_mods + '<subject id="location" displayLabel="Location" authority="local"><hierarchicalGeographic><country>USA</country></hierarchicalGeographic></subject>'
    expected_doc_hash=basic_expected_doc_hash.merge({:countries_ssi=>"USA",:score_isi=>20})
    should_match(doc,expected_doc_hash)

  end

  it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with a full date in the date field" do

    doc=basic_mods_with_date("5/6/1964")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_date_ssi => "5/6/1964",:pub_year_single_isi=>"1964",:pub_year_isim=>["1964"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

    doc=basic_mods_with_date("1966-02-27")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_date_ssi => "2/27/1966",:pub_year_single_isi=>"1966",:pub_year_isim=>["1966"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

    doc=basic_mods_with_date("1966-2-27")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_date_ssi => "2/27/1966",:pub_year_single_isi=>"1966",:pub_year_isim=>["1966"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

    doc=basic_mods_with_date("05/06/42")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_date_ssi => "5/6/1942",:pub_year_single_isi=>"1942",:pub_year_isim=>["1942"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

  end

  it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with a multiple years in the date field via 196x" do

    doc=basic_mods_with_date("196x")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1960","1961","1962","1963","1964","1965","1966","1967","1968","1969"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

  end

  it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with a multiple years in the date field via 1960s" do

    doc=basic_mods_with_date("1960s")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1960","1961","1962","1963","1964","1965","1966","1967","1968","1969"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

    doc=basic_mods_with_date("1950's")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1950","1951","1952","1953","1954","1955","1956","1957","1958","1959"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

  end

  it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with a multiple years in the date field via 1962-63" do

    doc=basic_mods_with_date("1962-63")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1962","1963"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

   end

  it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with a multiple years in the date field via 1965-8" do

     doc=basic_mods_with_date("1965-8")
     expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1965","1966","1967","1968"]})
     should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

  end

  it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with a multiple years separated by commas" do

      doc=basic_mods_with_date("1969,1970,1971")
      expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1969","1970","1971"]})
      should_match(doc,expected_doc_hash.merge({:score_isi=>26}))
  end

  it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with a multiple years separated by pipes" do

     doc=basic_mods_with_date("1969|1970| 1971")
     expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1969","1970","1971"]})
     should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

  end

   it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with a year range specified" do

    doc=basic_mods_with_date("1969-1971")
    expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1969","1970","1971"]})
    should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

  end

  it "should properly index a Revs MODs record with various two two digit year specific date specifieds" do

   doc=basic_mods_with_date("6/1/69")
   expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1969"],:pub_year_single_isi=>"1969",:pub_date_ssi=>"6/1/1969"})
   should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

   doc=basic_mods_with_date("11/14/14")
   expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["2014"],:pub_year_single_isi=>"2014",:pub_date_ssi=>"11/14/2014"})
   should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

   doc=basic_mods_with_date("6/1/55")
   expected_doc_hash=basic_expected_doc_hash.merge({:pub_year_isim=>["1955"],:pub_year_single_isi=>"1955",:pub_date_ssi=>"6/1/1955"})
   should_match(doc,expected_doc_hash.merge({:score_isi=>26}))

 end

 it "should properly index multiple formats into the multivalued format field" do

   doc=basic_mods + '<relatedItem type="original"><physicalDescription><form authority="aat">black-and-white negatives</form></physicalDescription></relatedItem>'
   expected_doc_hash=basic_expected_doc_hash.merge({:format_ssim=>["color transparencies","black-and-white negatives"]})
   should_match(doc,expected_doc_hash)

 end

  it "should properly index a Revs MODs record into the correct fields for the Revs Digital Library with no date specified" do

   doc=basic_mods_with_date("")
   should_match(doc,basic_expected_doc_hash)

  end


end
