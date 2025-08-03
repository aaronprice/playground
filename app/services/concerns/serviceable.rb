# frozen_string_literal: true

require "dry/schema"

module Serviceable
  extend ActiveSupport::Concern

  Result = Struct.new(:success?, :value, :errors)

  included do
    # == Attributes ===========================================================

    attr_reader :params, :value

    # == Extensions ===========================================================

    include Dry::Schema
    include ActiveModel::Model

    # == Relationships ========================================================

    # == Aliases ==============================================================

    # == Validations ==========================================================

    validate :validate_schema

    # == Callbacks ============================================================

    # == Scopes ===============================================================

    # == Class Methods ========================================================

    def self.call(params)
      new(params).call
    end

    # == Instance Methods =====================================================

    def initialize(params)
      @params = params
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
    return if schema_validation_result.success?

    schema_validation_result.errors.each do |error|
      errors.add(error.path.join('.'), error.text)
    end
  end
end