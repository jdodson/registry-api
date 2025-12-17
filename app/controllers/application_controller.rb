class ApplicationController < ActionController::Base
  private

  def package_json(pkg)
    {
      package_id: pkg.package_id,
      name: pkg.name,
      normalized_name: pkg.normalized_name,
      official: pkg.official,
      description: pkg.description,
      version: pkg.version,
      app_version: pkg.app_version,
      license: pkg.license,
      deprecated: pkg.deprecated || false,
      has_values_schema: pkg.has_values_schema || false,
      signed: pkg.signed || false,
      all_containers_images_whitelisted: pkg.all_containers_images_whitelisted || false,
      production_organizations_count: pkg.production_organizations_count,
      ts: pkg.ts,
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
    ).order(ts: :desc)
    
    # Build available_versions array
    all_versions.map do |v|
      {
        version: v.version,
        app_version: v.app_version,
        contains_security_updates: false, # We don't have this data yet
        prerelease: false, # We don't have this data yet
        ts: v.ts
      }
    end
  end
end
