class ContentController < ApplicationController
  before_filter :authenticate_user!
  
  def founder
    authorize! :view, :founder, :message => 'Access limited to Founders.'
  end
  
  def investor
    authorize! :view, :investor, :message => 'Access limited to Investors.'
  end

end