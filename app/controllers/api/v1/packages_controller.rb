class Api::V1::PackagesController < ApplicationController
  # GET /packages/buildpack/:repo_name/:package_name
  # GET /packages/builder/:repo_name/:package_name
  def show
    package_params = params.permit(:repo_name, :package_name)
    
    result = PackageSearch.find_package(
      repo_name: package_params[:repo_name],
      package_name: package_params[:package_name]
    )
    
    if result.nil?
      render json: { message: "" }, status: :not_found
      return
    end
    
    render json: result
  end
end

