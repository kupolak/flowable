# frozen_string_literal: true

require_relative 'integration_test_helper'

class ClientIntegrationTest < IntegrationTest
  def test_client_connects_to_flowable
    # Test basic connectivity
    result = client.deployments.list

    assert result.key?('data')
    assert result.key?('total')
  end

  def test_client_authentication_works
    # If we can list deployments, auth is working
    result = client.deployments.list

    assert_kind_of Hash, result
  end

  def test_unauthorized_with_wrong_credentials
    bad_client = Flowable::Client.new(
      host: FLOWABLE_HOST,
      port: FLOWABLE_PORT,
      username: 'wrong',
      password: 'wrong'
    )

    assert_raises(Flowable::UnauthorizedError) do
      bad_client.deployments.list
    end
  end

  def test_not_found_error
    assert_raises(Flowable::NotFoundError) do
      client.deployments.get('nonexistent-deployment-id')
    end
  end
end
# 2025-10-14T14:34:17Z - Add update task properties (assignee, priority)
# 2025-11-05T12:26:37Z - Add form property update support
# 2025-11-25T09:06:54Z - Add tests for tasks and task variables
# 2025-10-13T09:25:14Z - Add update task properties (assignee, priority)
# 2025-11-04T10:02:51Z - Add form property update support
# 2025-12-01T12:16:13Z - Add tests for tasks and task variables
