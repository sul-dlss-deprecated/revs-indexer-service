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
      }

    expect(@indexer.map).to eq(expected_doc_hash)
  end
  
end
  