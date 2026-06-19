class PagesController < ApplicationController
  def home
  end

  def tags
  end

  def about
    @page = Page.all.find { | page | page.slug == params[:action] }
    raise ActionController::RoutingError, "Not Found" unless @page
  end

  def now
    @page = Page.all.find { | page | page.slug == "now" }
    raise ActionController::RoutingError, "Not Found" unless @page
  end
end
