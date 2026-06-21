class ErrorsController < ApplicationController
  def not_found
    request.format = :html
    render status: :not_found
  end
end
