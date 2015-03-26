require "rails_helper"

describe RevsMapper do
  
  before(:each) do
    @pid='bb895tg4452'
    @mods=Stanford::Mods::Record.new
    @mods.from_nk_node(Nokogiri::XML(open('spec/fixtures/mods_xml.xml'),nil,'UTF-8'))
    public_xml=Nokogiri::XML(open('spec/fixtures/purl_xml.xml'),nil,'UTF-8')
    purl_parser=DiscoveryIndexer::InputXml::PurlxmlParserStrict.new(public_xml)
    @purl=purl_parser.parse()
    @collection_names={'aa00bb0001'=>'Test Collection Name'}
    @indexer = RevsMapper.new(@pid,@mods,@purl,@collection_names)
  end
  
  it "should properly map revs object" do
    expected_doc_hash=
      {
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
  
end
  