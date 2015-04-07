class AboutController < ApplicationController
  
  def index
    render :text=>'ok', :status=>200
  end

  def version
    
    @result={:app_name=>RevsIndexerService::Application.config.app_name,:rails_env=>Rails.env,:version=>RevsIndexerService::Application.config.version,:last_restart=>(File.exists?('tmp/restart.txt') ? File.new('tmp/restart.txt').mtime : "n/a"),:last_deploy=>(File.exists?('REVISION') ? File.new('REVISION').mtime : "n/a")}
    
    respond_to do |format|
      format.json {render :json=>@result.to_json}
      format.xml {render :json=>@result.to_xml(:root => 'status')}
      format.html {render}
    end      
    
  end
  
end