class ApplicationController < ActionController::Base
  private

  def package_json(pkg)
    {
      package_id: pkg.package_id,
      name: pkg.name,
      description: pkg.description,
      version: pkg.version,
      license: pkg.license,
      repository: {
        repository_id: pkg.repository_id,
        url: pkg.repository_url,
        name: pkg.repository_name
      }
    }
  end

  def available_versions_for_package(pkg)
    # Get all versions for this package
    all_versions = AhPackage.where(
      repository_name: pkg.repository_name,
      name: pkg.name
    ).order(created_at: :desc)
    
    # Build available_versions array
    all_versions.map do |v|
      {
        version: v.version,
        app_version: v.app_version
      }
    end
  end
end
