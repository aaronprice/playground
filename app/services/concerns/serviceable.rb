# frozen_string_literal: true

require "dry/schema"

module Serviceable
  extend ActiveSupport::Concern

  Result = Struct.new(:success?, :value, :errors)

  class_methods do
    def call(params)
      new(params).call
    end
  end

  included do
    # == Attributes ===========================================================

    attr_reader :params, :context, :value

    # == Extensions ===========================================================

    include Dry::Schema
    include ActiveModel::Model

    # == Relationships ========================================================

    # == Aliases ==============================================================

    # == Validations ==========================================================

    validate :validate_schema

    # == Callbacks ============================================================

    # == Scopes ===============================================================

    # == Instance Methods =====================================================

    def initialize(params = {}, context = {})
      @params = params
      @context = context
      @value = {}
    end
  end

  def call
    if valid?
      perform_and_return_result
    else
      Result.new(false, {}, errors.to_hash.deep_stringify_keys)
    end
  end

  private

  def perform
    raise NotImplementedError, "Subclasses must implement this method"
  end

  def schema
    raise NotImplementedError, "Subclasses must implement this method"
  end

  def perform_and_return_result
    perform

    Result.new(true, @value, {})
  end

  def validate_schema
    schema_validation_result = schema.(@params)
    if schema_validation_result.success?
      @sanitized_params = schema_validation_result.to_h.deep_stringify_keys
    else
      schema_validation_result.errors.each do |error|
        errors.add(error.path.join('.'), error.text)
      end
    end
  end

  def sanitized_params
    @sanitized_params || @params
  end
end