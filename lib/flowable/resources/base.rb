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
          var_type = infer_type(value)
          var_value = var_type == 'date' ? value.iso8601 : value
          var = { name: name.to_s, value: var_value, type: var_type }
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
