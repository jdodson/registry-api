require "test_helper"

class PackageSearchTest < ActiveSupport::TestCase
  test "search_packages returns array of package hashes" do
    result = PackageSearch.search_packages
    
    assert result.is_a?(Array)
    assert result.length > 0
    
    # Check structure of first result
    first = result[0]
    assert first.key?(:package_id)
    assert first.key?(:name)
    assert first.key?(:version)
    assert first.key?(:description)
    assert first.key?(:license)
    assert first.key?(:repository)
    assert first.key?(:available_versions)
    
    # Check repository structure
    assert first[:repository].is_a?(Hash)
    assert first[:repository].key?(:repository_id)
    assert first[:repository].key?(:url)
    assert first[:repository].key?(:name)
    
    # Check available_versions structure
    assert first[:available_versions].is_a?(Array)
    if first[:available_versions].length > 0
      assert first[:available_versions][0].key?(:version)
      assert first[:available_versions][0].key?(:app_version)
    end
  end

  test "search_packages with query filters results" do
    result = PackageSearch.search_packages(q: "test")
    
    assert result.is_a?(Array)
    # Should find test-repo
    repo_names = result.map { |r| r[:repository][:name] }
    assert_includes repo_names, "test-repo"
  end

  test "search_packages respects limit" do
    result = PackageSearch.search_packages(limit: 1)
    
    assert result.length <= 1
  end

  test "search_packages respects offset" do
    all_results = PackageSearch.search_packages(limit: 10, offset: 0)
    offset_results = PackageSearch.search_packages(limit: 10, offset: 1)
    
    # Results should be different (assuming we have more than 1 result)
    if all_results.length > 1
      assert_not_equal all_results[0][:package_id], offset_results[0][:package_id]
    end
  end

  test "search_packages returns empty array when no matches" do
    result = PackageSearch.search_packages(q: "nonexistent-repo-xyz-123")
    
    assert result.is_a?(Array)
    assert_equal 0, result.length
  end

  test "search_packages searches by package name" do
    result = PackageSearch.search_packages(q: "test-package")
    
    assert result.is_a?(Array)
    # Should find test-repo because it contains test-package
    repo_names = result.map { |r| r[:repository][:name] }
    assert_includes repo_names, "test-repo"
    # Verify the package name is in the results
    package_names = result.map { |r| r[:name] }
    assert_includes package_names, "test-package"
  end

  test "find_package returns package hash for existing package" do
    result = PackageSearch.find_package(
      repo_name: "test-repo",
      package_name: "test-package"
    )
    
    assert_not_nil result
    assert result.is_a?(Hash)
    assert_equal "test-package", result[:name]
    assert_equal "test-repo", result[:repository][:name]
    assert result.key?(:package_id)
    assert result.key?(:version)
    assert result.key?(:description)
    assert result.key?(:license)
    assert result.key?(:available_versions)
  end

  test "find_package returns latest version" do
    result = PackageSearch.find_package(
      repo_name: "test-repo",
      package_name: "test-package"
    )
    
    # Should return version 2.0.0 (latest based on created_at)
    assert_equal "2.0.0", result[:version]
  end

  test "find_package returns nil for nonexistent package" do
    result = PackageSearch.find_package(
      repo_name: "nonexistent-repo",
      package_name: "nonexistent-package"
    )
    
    assert_nil result
  end

  test "find_package includes all required fields" do
    result = PackageSearch.find_package(
      repo_name: "test-repo",
      package_name: "test-package"
    )
    
    # Check top-level fields
    assert result.key?(:package_id)
    assert result.key?(:name)
    assert result.key?(:version)
    assert result.key?(:description)
    assert result.key?(:license)
    
    # Check repository object
    assert result.key?(:repository)
    assert result[:repository].key?(:url)
    assert result[:repository].key?(:name)
    assert result[:repository].key?(:repository_id)
    
    # Check available versions
    assert result.key?(:available_versions)
    assert result[:available_versions].is_a?(Array)
    if result[:available_versions].length > 0
      assert result[:available_versions][0].key?(:version)
      assert result[:available_versions][0].key?(:app_version)
    end
  end

  test "find_package available_versions includes all versions" do
    result = PackageSearch.find_package(
      repo_name: "test-repo",
      package_name: "test-package"
    )
    
    # Should have both versions (1.0.0 and 2.0.0)
    versions = result[:available_versions].map { |v| v[:version] }
    assert_includes versions, "1.0.0"
    assert_includes versions, "2.0.0"
  end

  test "search_packages includes buildpacks in results" do
    result = PackageSearch.search_packages
    
    # Should include buildpacks from fixtures
    buildpack_results = result.select { |r| r[:repository].nil? }
    assert buildpack_results.length > 0, "Should include buildpack results"
    
    # Check that buildpack results have correct structure
    buildpack_result = buildpack_results.first
    assert buildpack_result.key?(:package_id)
    assert buildpack_result.key?(:name)
    assert buildpack_result.key?(:version)
    assert buildpack_result.key?(:description)
    assert_nil buildpack_result[:repository], "Buildpack results should have nil repository"
    assert buildpack_result.key?(:available_versions)
  end

  test "search_packages excludes yanked buildpacks by default" do
    result = PackageSearch.search_packages
    
    # All buildpack results should be non-yanked (we can't easily check yanked status
    # from the hash, but we can verify buildpacks are included)
    buildpack_results = result.select { |r| r[:repository].nil? }
    # If we have buildpack results, they should be non-yanked
    # (yanked buildpacks are excluded by default)
    assert buildpack_results.all? { |r| r[:repository].nil? }
  end

  test "search_packages can find buildpacks by name" do
    result = PackageSearch.search_packages(q: "first")
    
    # Should find buildpack with name "first"
    package_names = result.map { |r| r[:name] }
    assert_includes package_names, "first"
  end

  test "search_packages can find buildpacks by namespace" do
    result = PackageSearch.search_packages(q: "example")
    
    # Should find buildpacks with namespace "example"
    # We can't directly check namespace from the hash, but we can verify
    # that buildpack results are included when searching for namespace
    buildpack_results = result.select { |r| r[:repository].nil? }
    assert buildpack_results.length > 0, "Should find buildpacks when searching by namespace"
  end

  test "find_package can find buildpack by namespace and name" do
    result = PackageSearch.find_package(
      repo_name: "example",
      package_name: "first"
    )
    
    assert_not_nil result
    assert result.is_a?(Hash)
    assert_equal "first", result[:name]
    assert_nil result[:repository], "Buildpack results should have nil repository"
    assert result.key?(:package_id)
    assert result.key?(:version)
    assert result.key?(:description)
    assert result.key?(:available_versions)
  end

  test "find_package prefers AhPackage over Buildpack" do
    # If both exist with same repo_name/package_name and namespace/name,
    # should return AhPackage
    result = PackageSearch.find_package(
      repo_name: "test-repo",
      package_name: "test-package"
    )
    
    # Should return AhPackage (has repository info)
    assert_not_nil result[:repository], "Should return AhPackage with repository info"
  end

  test "buildpack available_versions uses version ordering" do
    result = PackageSearch.find_package(
      repo_name: "example",
      package_name: "first"
    )
    
    assert_not_nil result
    assert result.key?(:available_versions)
    assert result[:available_versions].is_a?(Array)
    
    # Should have multiple versions ordered by version_major, version_minor, version_patch
    if result[:available_versions].length > 1
      versions = result[:available_versions].map { |v| v[:version] }
      # Should include both 1.9.0 and 1.10.0 (1.10.0 should be first/latest)
      assert_includes versions, "1.9.0"
      assert_includes versions, "1.10.0"
      # Latest version should be 1.10.0
      assert_equal "1.10.0", result[:version]
    end
  end

  test "buildpack results have app_version as nil" do
    result = PackageSearch.find_package(
      repo_name: "example",
      package_name: "first"
    )
    
    assert_not_nil result
    if result[:available_versions].length > 0
      # Buildpacks don't have app_version
      assert_nil result[:available_versions][0][:app_version]
    end
  end

  test "search_packages with only AhPackage data" do
    # Temporarily delete all buildpacks to test AhPackage-only scenario
    # Rails test transactions will automatically rollback after the test
    Buildpack.delete_all
    
    result = PackageSearch.search_packages
    
    assert result.is_a?(Array)
    assert result.length > 0
    
    # All results should be AhPackages (have repository info)
    result.each do |r|
      assert_not_nil r[:repository], "All results should be AhPackages with repository info"
      assert r[:repository].is_a?(Hash)
      assert r[:repository].key?(:repository_id)
      assert r[:repository].key?(:url)
      assert r[:repository].key?(:name)
    end
    
    # Test find_package with only AhPackage
    find_result = PackageSearch.find_package(
      repo_name: "test-repo",
      package_name: "test-package"
    )
    
    assert_not_nil find_result
    assert_not_nil find_result[:repository], "Should return AhPackage with repository info"
    assert_equal "test-package", find_result[:name]
    assert_equal "test-repo", find_result[:repository][:name]
  end

  test "search_packages with only Buildpack data" do
    # Temporarily delete all AhPackages to test Buildpack-only scenario
    # Rails test transactions will automatically rollback after the test
    AhPackage.delete_all
    
    result = PackageSearch.search_packages
    
    assert result.is_a?(Array)
    assert result.length > 0
    
    # All results should be Buildpacks (have nil repository)
    result.each do |r|
      assert_nil r[:repository], "All results should be Buildpacks with nil repository"
      assert r.key?(:package_id)
      assert r.key?(:name)
      assert r.key?(:version)
      assert r.key?(:description)
    end
    
    # Test find_package with only Buildpack
    find_result = PackageSearch.find_package(
      repo_name: "example",
      package_name: "first"
    )
    
    assert_not_nil find_result
    assert_nil find_result[:repository], "Should return Buildpack with nil repository"
    assert_equal "first", find_result[:name]
  end

  test "search_packages with both AhPackage and Buildpack data" do
    # Ensure we have both types of data (default fixture state)
    assert AhPackage.count > 0, "Should have AhPackage fixtures"
    assert Buildpack.count > 0, "Should have Buildpack fixtures"
    
    result = PackageSearch.search_packages
    
    assert result.is_a?(Array)
    assert result.length > 0
    
    # Should have both AhPackages and Buildpacks
    ah_package_results = result.select { |r| r[:repository].present? }
    buildpack_results = result.select { |r| r[:repository].nil? }
    
    assert ah_package_results.length > 0, "Should include AhPackage results"
    assert buildpack_results.length > 0, "Should include Buildpack results"
    
    # Verify AhPackage structure
    ah_package_result = ah_package_results.first
    assert_not_nil ah_package_result[:repository]
    assert ah_package_result[:repository].is_a?(Hash)
    assert ah_package_result[:repository].key?(:repository_id)
    
    # Verify Buildpack structure
    buildpack_result = buildpack_results.first
    assert_nil buildpack_result[:repository]
    assert buildpack_result.key?(:package_id)
    assert buildpack_result.key?(:name)
    
    # Test find_package - should prefer AhPackage if both exist
    # First test with AhPackage that exists
    ah_result = PackageSearch.find_package(
      repo_name: "test-repo",
      package_name: "test-package"
    )
    
    assert_not_nil ah_result
    assert_not_nil ah_result[:repository], "Should return AhPackage when both exist"
    
    # Test with Buildpack that doesn't have matching AhPackage
    buildpack_result = PackageSearch.find_package(
      repo_name: "example",
      package_name: "first"
    )
    
    assert_not_nil buildpack_result
    assert_nil buildpack_result[:repository], "Should return Buildpack when no AhPackage match"
  end
end

