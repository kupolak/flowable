# frozen_string_literal: true

module Flowable
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      private

      def paginate_params(options)
        params = {}
        params[:start] = options[:start] if options[:start]
        params[:size] = options[:size] if options[:size]
        params[:sort] = options[:sort] if options[:sort]
        params[:order] = options[:order] if options[:order]
        params
      end

      def build_variables_array(variables)
        return [] unless variables

        variables.map do |name, value|
  end
end
