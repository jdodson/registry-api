require "test_helper"

class Api::V1::RepositoriesControllerTest < ActionDispatch::IntegrationTest
  test "should get search without query" do
    get "/api/v1/repositories/search"
    assert_response :success
    result = JSON.parse(response.body)
    assert result.is_a?(Array)
    assert result.length > 0
    # Check top-level package fields
    assert result[0].key?('package_id')
    assert result[0].key?('name')
    assert result[0].key?('version')
    assert result[0].key?('description')
    # Check nested repository object
    assert result[0].key?('repository')
    assert result[0]['repository'].key?('repository_id')
    assert result[0]['repository'].key?('url')
    assert result[0]['repository'].key?('name')
    
    # Check available versions
    assert result[0].key?('available_versions')
    assert result[0]['available_versions'].is_a?(Array)
    if result[0]['available_versions'].length > 0
      assert result[0]['available_versions'][0].key?('version')
      assert result[0]['available_versions'][0].key?('ts')
    end
  end

  test "should get search with query parameter" do
    get "/api/v1/repositories/search?q=test"
    assert_response :success
    result = JSON.parse(response.body)
    assert result.is_a?(Array)
    # Should find test-repo - check repository name in nested object
    repo_names = result.map { |r| r['repository']['name'] }
    assert_includes repo_names, 'test-repo'
  end

  test "should support pagination" do
    get "/api/v1/repositories/search?limit=1&offset=0"
    assert_response :success
    result = JSON.parse(response.body)
    assert result.length <= 1
  end

  test "should return empty array when no matches" do
    get "/api/v1/repositories/search?q=nonexistent-repo-xyz"
    assert_response :success
    result = JSON.parse(response.body)
    assert result.is_a?(Array)
    assert_equal 0, result.length
  end
end

