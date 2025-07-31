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
  end
end
