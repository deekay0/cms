class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  def after_sign_in_path_for(resource)
    case current_user.roles.first.name
      when 'admin'
        users_path
      when 'investor'
        content_silver_path
      when 'founder'
        content_gold_path
      else
        root_path
    end
  end
  
end