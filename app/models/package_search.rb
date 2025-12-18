class PackageSearch
  # Search for packages by query string
  # Returns an array of package hashes ready for JSON rendering
  def self.search_packages(q: nil, limit: 20, offset: 0)
    limit = limit.to_i
    offset = offset.to_i
    
    # Search AhPackage model
    ah_packages = search_ah_packages(q)
    
    # Search Buildpack model
    buildpacks = search_buildpacks(q)
    
    # Combine results from both models
    all_results = ah_packages + buildpacks
    
    # Apply pagination
    paginated_results = all_results.slice(offset, limit) || []
    
    # Build response matching Artifact Hub format
    paginated_results.map do |result|
      if result[:source] == :buildpack
        buildpack_hash(result[:buildpack]).merge(
          available_versions: available_versions_for_buildpack(result[:buildpack])
        )
      else
        package_hash(result[:package]).merge(
          available_versions: available_versions_for_package(result[:package])
        )
      end
    end
  end

  # Find a specific package by repository name and package name
  # Returns a package hash ready for JSON rendering, or nil if not found
  def self.find_package(repo_name:, package_name:)
    # First try AhPackage model
    package = AhPackage.where(
      repository_name: repo_name,
      name: package_name
    ).order(created_at: :desc).first
    
    if package
      return package_hash(package).merge(
        available_versions: available_versions_for_package(package)
      )
    end
    
    # Then try Buildpack model (namespace = repo_name, name = package_name)
    buildpack = Buildpack.where(
      namespace: repo_name,
      name: package_name,
      yanked: false
    ).order(
      'version_major::integer DESC',
      'version_minor::integer DESC',
      'version_patch::integer DESC'
    ).first
    
    if buildpack
      return buildpack_hash(buildpack).merge(
        available_versions: available_versions_for_buildpack(buildpack)
      )
    end
    
    nil
  end

  private

  def self.search_ah_packages(q)
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
    
    # Get distinct package combinations (repository_id + name)
    all_package_combos = query.distinct.pluck(:repository_id, :name)
    
    # Fetch the latest version of each unique package
    all_package_combos.map do |repo_id, name|
      package = AhPackage.where(
        repository_id: repo_id,
        name: name
      ).order(created_at: :desc).first
      
      { package: package, source: :ah_package } if package
    end.compact
  end

  def self.search_buildpacks(q)
    # If no query, exclude yanked buildpacks
    # If query provided, use Buildpack.search which may include yanked if they match
    if q.present?
      query = Buildpack.search(q) # May include yanked buildpacks if they match
    else
      query = Buildpack.where(yanked: false)
    end
    
    # Get distinct buildpack combinations (namespace + name)
    all_buildpack_combos = query.distinct.pluck(:namespace, :name)
    
    # Fetch the latest version of each unique buildpack
    all_buildpack_combos.map do |namespace, name|
      buildpack_query = Buildpack.where(namespace: namespace, name: name)
      
      # If searching, get latest version regardless of yanked status
      # (since search may have found yanked versions)
      # If not searching, only get non-yanked versions
      if q.present?
        buildpack = buildpack_query.order(
          'version_major::integer DESC',
          'version_minor::integer DESC',
          'version_patch::integer DESC'
        ).first
      else
        buildpack = buildpack_query.where(yanked: false).order(
          'version_major::integer DESC',
          'version_minor::integer DESC',
          'version_patch::integer DESC'
        ).first
      end
      
      { buildpack: buildpack, source: :buildpack } if buildpack
    end.compact
  end

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

  def self.buildpack_hash(buildpack)
    {
      package_id: buildpack.id,
      name: buildpack.name,
      description: buildpack.description,
      version: buildpack.version,
      license: buildpack.licenses&.first, # Use first license or nil
      repository: nil
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

  def self.available_versions_for_buildpack(buildpack)
    # Get all versions for this buildpack
    all_versions = Buildpack.where(
      namespace: buildpack.namespace,
      name: buildpack.name,
      yanked: false
    ).order(
      'version_major::integer DESC',
      'version_minor::integer DESC',
      'version_patch::integer DESC'
    )
    
    # Build available_versions array
    all_versions.map do |v|
      {
        version: v.version,
        app_version: nil # Buildpacks don't have app_version
      }
    end
  end
end

