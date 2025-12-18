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
end

