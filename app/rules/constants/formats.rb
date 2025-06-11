module Constants::Formats
  PATTERNS = {
    AU: {
      au_abn: /^\d{11}$/,
      au_acn: /^\d{9}$/
    },
    CA: { ca_gst: /^\d{9}RT0001$/ },
    IN: { in_gst: /^\d{2}[A-Z0-9]{10}[A-Z]\d[A-Z]\d$/ }
  }.freeze

  GROUPINGS = {
    au_abn: /(\d{2})(\d{3})(\d{3})(\d{3})/,
    au_acn: /(\d{3})(\d{3})(\d{3})/
  }.freeze

  WEIGHTS = [10,1,3,5,7,9,11,13,15,17,19].freeze

  I18N_ERROR_KEYS = {
    unsupported_country: '.tin_validator.errors.unsupported_country',
    invalid_format: '.tin_validator.errors.invalid_format_or_length_for_specified_country',
    checksum_failed: '.tin_validator.errors.checksum_failed',
    not_gst_registered: '.tin_validator.errors.not_gst_registered',
    api_not_found: '.tin_validator.errors.api_not_found',
    api_error: '.tin_validator.errors.api_error'
  }.freeze
end
