class RevsMapper < DiscoveryIndexer::Mapper::GeneralMapper 
  
  # @modsxml == Stanford::Mods::Record class object
  # @modsxml.mods_ng_xml == Nokogiri document (for custom parsing)
  # @purlxml == DiscoveryIndexer::InputXml::PurlxmlModel class object
  # @purlxml.public_xml == Nokogiri document (for custom parsing)
  def map
    doc_hash={}
    doc_hash[:title_tsi]=@modsxml.title_info.title.text
    return doc_hash
  end

end