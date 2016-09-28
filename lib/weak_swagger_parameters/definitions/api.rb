# frozen_string_literal: true
module WeakSwaggerParameters
  module Definitions
    class Api
      def initialize(method, path, summary, &block)
        @method = method
        @path = path
        @summary = summary
        @param_definition = nil
        @response_definitions = []
        @description = nil

        instance_eval(&block)
      end

      def description(description)
        @description = description
      end

      def params(&block)
        @param_definition = WeakSwaggerParameters::Definitions::Params.new(&block)
      end

      def response(status_code, description)
        @response_definitions << WeakSwaggerParameters::Definitions::Response.new(status_code, description)
      end

      def apply_validations(controller_class)
        child_definitions = validation_definitions
        method = @method

        controller_class.instance_eval do
          validates method do
            child_definitions.each { |definition| definition.apply_validations(self) }
          end
        end
      end

      def apply_docs(controller_class)
        child_definitions = doc_definitions
        path = @path
        method = http_method
        name = resource_name(controller_class)
        operation_params = {}
        operation_params[:summary] = @summary
        operation_params[:operationId] = operation_id(method, name)
        operation_params[:description] = @description unless @description.blank?
        operation_params[:tags] = [name]

        controller_class.instance_eval do
          swagger_path path do
            operation method, operation_params do
              child_definitions.each { |definition| definition.apply_docs(self) }
            end
          end
        end
      end

      private

      def doc_definitions
        validation_definitions + @response_definitions
      end

      def validation_definitions
        [@param_definition]
      end

      def http_method
        known_methods = {
          create: :post,
          index: :get,
          show: :get,
          destroy: :delete,
          update: :put
        }

        known_methods[@method]
      end

      def resource_name(controller_class)
        controller_class.controller_name.humanize
      end

      def operation_id(method, name)
        "#{method}#{name}"
      end
    end
  end
end
