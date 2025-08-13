# frozen_string_literal: true

module Flowable
  module Resources
    class CaseDefinitions < Base
      BASE_PATH = 'cmmn-repository/case-definitions'

      # List all case definitions
      # @param options [Hash] Query parameters
