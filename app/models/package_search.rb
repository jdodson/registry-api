class PackageSearch
  # Search for packages by query string
  # Returns an array of package hashes ready for JSON rendering
  def self.search_packages(q: nil, limit: 20, offset: 0)
    limit = limit.to_i
    offset = offset.to_i
    
    # Build query - get distinct packages (by repository_id and name)
    query = AhPackage.where.not(repository_id: nil)
    
    # Apply search query if provided
    if q.present?
      search_term = "%#{q}%"
      query = query.where(
        "repository_name ILIKE ? OR repository_display_name ILIKE ? OR repository_organization_name ILIKE ? OR name ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
    
    # Get distinct package combinations (repository_id + name) with pagination
    # First get all distinct combinations, then paginate in Ruby
    all_package_combos = query.distinct.pluck(:repository_id, :name)
    package_combos = all_package_combos.slice(offset, limit) || []
    
    # Fetch the latest version of each unique package
    packages = package_combos.map do |repo_id, name|
      AhPackage.where(
        repository_id: repo_id,
        name: name
      ).order(created_at: :desc).first
    end.compact
    
    # Build response matching Artifact Hub format
    packages.map do |pkg|
      package_hash(pkg).merge(
        available_versions: available_versions_for_package(pkg)
      )
    end
  end

  # Find a specific package by repository name and package name
  # Returns a package hash ready for JSON rendering, or nil if not found
  def self.find_package(repo_name:, package_name:)
    # Find the latest version of the package
    package = AhPackage.where(
      repository_name: repo_name,
      name: package_name
    ).order(created_at: :desc).first
    
    return nil if package.nil?
    
    # Build response matching Artifact Hub format
    package_hash(package).merge(
      available_versions: available_versions_for_package(package)
    )
  end

  private

  def self.package_hash(pkg)
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

  def self.available_versions_for_package(pkg)
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

