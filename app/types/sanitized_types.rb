# frozen_string_literal: true

require "dry/types"

# Define custom types for sanitization
module SanitizedTypes
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
  DowncasedString = String.constructor do |value|
    if value.is_a?(::String)
      value.downcase
    else
      value
    end
  end

  TrimmedDowncasedString = DowncasedString.constructor(&:strip)
  TrimmedUpcasedString = UpcasedString.constructor(&:strip)
end