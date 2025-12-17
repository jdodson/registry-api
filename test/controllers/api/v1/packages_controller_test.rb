require "test_helper"

class Api::V1::PackagesControllerTest < ActionDispatch::IntegrationTest
  test "should get buildpack package" do
    get "/api/v1/packages/buildpack/test-repo/test-package"
    assert_response :success
    result = JSON.parse(response.body)
    assert_equal "test-package", result["name"]
    assert_equal "test-repo", result["repository"]["name"]
    assert result.key?("available_versions")
    assert result["available_versions"].is_a?(Array)
    assert result["available_versions"].length > 0
  end

  test "should get builder package" do
    get "/api/v1/packages/builder/test-repo/test-package"
    assert_response :success
    result = JSON.parse(response.body)
    assert_equal "test-package", result["name"]
    assert_equal "test-repo", result["repository"]["name"]
  end

  test "should return 404 for nonexistent package" do
    get "/api/v1/packages/buildpack/nonexistent/repo"
    assert_response :not_found
    result = JSON.parse(response.body)
    assert result.key?("message")
  end

  test "should return 404 for nonexistent repository" do
    get "/api/v1/packages/buildpack/nonexistent-repo/test-package"
    assert_response :not_found
    result = JSON.parse(response.body)
    assert result.key?("message")
  end

  test "should include all required fields" do
    get "/api/v1/packages/buildpack/test-repo/test-package"
    assert_response :success
    result = JSON.parse(response.body)
    
    # Check top-level fields
    assert result.key?("package_id")
    assert result.key?("name")
    assert result.key?("version")
    assert result.key?("description")
    
    # Check repository object
    assert result.key?("repository")
    assert result["repository"].key?("url")
    assert result["repository"].key?("name")
    assert result["repository"].key?("repository_id")
    
    # Check available versions
    assert result.key?("available_versions")
    assert result["available_versions"].is_a?(Array)
    if result["available_versions"].length > 0
      assert result["available_versions"][0].key?("version")
      assert result["available_versions"][0].key?("ts")
    end
  end

  test "should return latest version" do
    get "/api/v1/packages/buildpack/test-repo/test-package"
    assert_response :success
    result = JSON.parse(response.body)
    # Should return version 2.0.0 (latest based on ts)
    assert_equal "2.0.0", result["version"]
  end
end

