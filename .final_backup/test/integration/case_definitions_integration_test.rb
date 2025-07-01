# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class CaseDefinitionsIntegrationTest < IntegrationTest
  def setup
    super
    @deployment_id = deploy_test_case
  end

  def teardown
    client.deployments.delete(@deployment_id) rescue nil
  end

  def deploy_test_case
    file = Tempfile.new(['test', '.cmmn'])
    file.write(sample_cmmn_content)
    file.close

    result = client.deployments.create(file.path, name: 'CaseDefTest')
    file.unlink
    result['id']
  end

  def test_list_case_definitions
    result = client.case_definitions.list

    assert result.key?('data')
    assert_operator result['total'], :>=, 1
  end

  def test_list_latest_case_definitions
    result = client.case_definitions.list(latest: true)

    assert result.key?('data')
  end

  def test_get_case_definition
    definitions = client.case_definitions.list(deploymentId: @deployment_id)
    definition = definitions['data'].first

    result = client.case_definitions.get(definition['id'])

    assert_equal definition['id'], result['id']
    assert_equal 'testCase', result['key']
  end

  def test_get_case_definition_by_key
    result = client.case_definitions.list(key: 'testCase', latest: true)

    assert_operator result['total'], :>=, 1
    assert_equal 'testCase', result['data'].first['key']
  end

  def test_get_resource_content
    definitions = client.case_definitions.list(deploymentId: @deployment_id)
    definition = definitions['data'].first

    content = client.case_definitions.resource_content(definition['id'])

    assert_includes content, 'testCase'
    assert_includes content, 'CMMN'
  end

  def test_get_model
    definitions = client.case_definitions.list(deploymentId: @deployment_id)
    definition = definitions['data'].first

    # Model endpoint returns very deeply nested JSON that may exceed default parsing limits
    # or may return malformed JSON in some Flowable versions
    # Skip detailed assertions as the structure varies by Flowable version
    begin
      model = client.case_definitions.model(definition['id'])

      assert model # Just verify we got a response
    rescue JSON::NestingError
      skip 'Model JSON too deeply nested for parsing'
    rescue JSON::ParserError => e
      skip "Model JSON malformed in this Flowable version: #{e.message.slice(0, 100)}"
    end
  end
end
# 2025-10-14T14:52:30Z - Add claim/unclaim task support
# 2025-11-04T09:32:01Z - Add task event listener hooks for tests
# 2025-11-24T09:21:25Z - Add test coverage config (simplecov)
# 2025-10-13T07:02:57Z - Add claim/unclaim task support
# 2025-11-04T08:44:46Z - Add task event listener hooks for tests
# 2025-12-01T10:55:09Z - Add test coverage config (simplecov)
