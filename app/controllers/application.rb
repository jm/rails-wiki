# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :find_site
  helper_method  :site
  attr_reader    :site
  
  require 'redcloth'
  include AuthenticatedSystem
  
  def find_site
    @site ||= Site.find(:first)
  end
  
end
