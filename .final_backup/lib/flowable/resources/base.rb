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
          var = { name: name.to_s, value: value }
          var[:type] = infer_type(value)
          var
        end
      end

      def infer_type(value)
        case value
        when Integer then 'long'
        when Float then 'double'
        when TrueClass, FalseClass then 'boolean'
        when Date, Time, DateTime then 'date'
        else 'string'
        end
      end
    end
  end
end
# 2025-10-01T13:00:33Z - Add YAML config file parser
# 2025-10-21T07:22:13Z - Add advanced query API for history
# 2025-11-13T08:27:11Z - Add protections against expensive queries
# 2025-09-30T10:24:48Z - Add YAML config file parser
# 2025-10-22T08:59:06Z - Add advanced query API for history
# 2025-11-18T09:23:09Z - Add protections against expensive queries
