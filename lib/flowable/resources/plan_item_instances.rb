# frozen_string_literal: true

module Flowable
  module Resources
    class PlanItemInstances < Base
      BASE_PATH = 'cmmn-runtime/plan-item-instances'

      # List all plan item instances
      # @param options [Hash] Query parameters
      # @option options [String] :id Filter by ID
