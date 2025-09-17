class HomeController < ApplicationController
  before_action :set_long_cache_headers, only: [ :show ]

  def show
  end
end
