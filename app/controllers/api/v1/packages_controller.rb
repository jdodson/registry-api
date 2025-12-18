class Api::V1::PackagesController < ApplicationController
  # GET /packages/buildpack/:repo_name/:package_name
  # GET /packages/builder/:repo_name/:package_name
  def show
    package_params = params.permit(:repo_name, :package_name)
    
    # Find the latest version of the package
    package = AhPackage.where(
      repository_name: package_params[:repo_name],
      name: package_params[:package_name]
    ).order(created_at: :desc).first
    
    if package.nil?
      render json: { message: "" }, status: :not_found
      return
    end
    
    # Build response matching Artifact Hub format
    result = package_json(package).merge(
      available_versions: available_versions_for_package(package)
    )
    
    render json: result
  end
end

