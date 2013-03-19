class HomeController < ApplicationController
  def index
    @bid = Bid.new
  end
end
