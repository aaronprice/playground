# frozen_string_literal: true

require "dry/types"

module CanonicalTypes
  include Dry.Types()
  include SanitizedTypes

  # Currency type that converts to uppercase and validates
  Currency = TrimmedUpcasedString.constrained(format: /\A(?:USD|CAD)\z/)

  # Country code type that converts to uppercase and validates
  CountryCode = TrimmedUpcasedString.constrained(format: /\A(?:US|CA)\z/)

  # Email type that converts to lowercase and validates
  Email = TrimmedDowncasedString.constrained(format: /@/)

  Date = TrimmedString.constrained(format: /\A(?!0000)([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\z/)
end