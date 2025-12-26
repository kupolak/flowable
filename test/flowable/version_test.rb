# frozen_string_literal: true

require 'test_helper'

class VersionTest < Minitest::Test
  def test_version_constant
    assert_equal '1.0.0', Flowable::VERSION
  end

  def test_flowable_api_version_constant
    assert_equal '7.1.0', Flowable::FLOWABLE_API_VERSION
  end

  def test_version_info_constant
    expected = {
      major: 1,
      minor: 0,
      patch: 0,
      pre: nil
    }

    assert_equal expected, Flowable::VERSION_INFO
  end

  def test_version_info_is_frozen
    assert_predicate Flowable::VERSION_INFO, :frozen?
  end

  def test_version_method
    assert_equal '1.0.0', Flowable.version
  end

  def test_version_info_method
    info = Flowable.version_info

    assert_equal 1, info[:major]
    assert_equal 0, info[:minor]
    assert_equal 0, info[:patch]
    assert_nil info[:pre]
  end

  def test_flowable_api_version_method
    assert_equal '7.1.0', Flowable.flowable_api_version
  end
end
