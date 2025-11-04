# frozen_string_literal: true

require_relative '../flowable'

module Flowable
  # High-level DSL for workflow management
  # Provides a more intuitive API for common workflow operations
  module Workflow
    class Case
      attr_reader :client
      attr_reader :case_key
      attr_reader :instance

      def initialize(client, case_key)
        @client = client
        @case_key = case_key
        @instance = nil
        @task_handlers = {}
        @milestone_callbacks = {}
      end

      # Start a new case instance
      # @param variables [Hash] Initial variables
      # @param business_key [String] Business key
