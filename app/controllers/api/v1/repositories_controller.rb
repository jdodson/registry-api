class Api::V1::RepositoriesController < ApplicationController
  # GET /repositories/search
  def search
    search_params = params.permit(:q, :limit, :offset)
    limit = (search_params[:limit] || 20).to_i
    offset = (search_params[:offset] || 0).to_i
    
    # Build query - get distinct repositories
    query = AhPackage.where.not(repository_id: nil)
    
    # Apply search query if provided
    if search_params[:q].present?
      search_term = "%#{search_params[:q]}%"
      query = query.where(
        "repository_name ILIKE ? OR repository_display_name ILIKE ? OR repository_organization_name ILIKE ?",
        search_term, search_term, search_term
      )
    end
    
    # Get distinct repository IDs with pagination
    # First get all distinct repository_ids, then paginate in Ruby
    all_repository_ids = query.distinct.pluck(:repository_id)
    repository_ids = all_repository_ids.slice(offset, limit) || []
    
    # Fetch one package per repository to get repository details
    repositories = repository_ids.map do |repo_id|
      AhPackage.where(repository_id: repo_id).first
    end.compact
    
    # Build response matching Artifact Hub format
    result = repositories.map do |pkg|
      package_json(pkg).merge(
        available_versions: available_versions_for_package(pkg)
      )
    end
    
    render json: result
  end
end

