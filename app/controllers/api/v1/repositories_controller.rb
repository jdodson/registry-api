class Api::V1::RepositoriesController < ApplicationController
  # GET /repositories/search
  def search
    search_params = params.permit(:q, :limit, :offset)
    limit = (search_params[:limit] || 20).to_i
    offset = (search_params[:offset] || 0).to_i
    
    result = PackageSearch.search_packages(
      q: search_params[:q],
      limit: limit,
      offset: offset
    )
    
    render json: result
  end
end

