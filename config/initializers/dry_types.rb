# frozen_string_literal: true

require "dry/types"

# Define custom types for sanitization
module SanitisedTypes
  include Dry.Types()

  # Strips whitespace from strings
  TrimmedString = String.constructor do |value|
    if value.is_a?(::String)
      value.strip
    else
      value
    end
  end

  # Converts strings to uppercase and strips whitespace
  UpcasedString = String.constructor do |value|
    if value.is_a?(::String)
      value.upcase
    else
      value
    end
  end

  # Converts strings to lowercase and strips whitespace
  LowercaseString = String.constructor do |value|
    if value.is_a?(::String)
      value.downcase
    else
      value
    end
  end

  # Currency type that converts to uppercase and validates
  Currency = String.constructor do |value|
    if value.is_a?(::String)
      value.strip.upcase
    else
      value
    end
  end.constrained(format: /\A(?:USD|CAD)\z/)

  # Country code type that converts to uppercase and validates
  CountryCode = String.constructor do |value|
    if value.is_a?(::String)
      value.strip.upcase
    else
      value
    end
  end.constrained(format: /\A(?:US|CA)\z/)

  # Email type that converts to lowercase and validates
  Email = String.constructor do |value|
    if value.is_a?(::String)
      value.strip.downcase
    else
      value
    end
  end.constrained(format: /@/)

  Date = String.constructor do |value|
    if value.is_a?(::String)
      Date.parse(value)
    else
      value
    end
  end.constrained(format: /\A(?!0000)([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\z/)
end