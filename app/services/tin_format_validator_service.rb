class TinFormatValidatorService < ApplicationService
  PATTERNS = Constants::Formats::PATTERNS
  GROUPINGS = Constants::Formats::GROUPINGS
  I18N_ERROR_KEYS = Constants::Formats::I18N_ERROR_KEYS

  def initialize(country, raw)
    @country = country
    @normalized_tin = raw.to_s.gsub(/\s+/, '').upcase
  end

  def call
    return error_response(:unsupported_country) unless supported_country?
    return process_canadian_tin if @country == :CA && canadian_short_tin?

    PATTERNS[@country].each do |type, regex|
      next unless regex.match?(@normalized_tin)
      return type == :au_abn ? process_au_abn : success_response(type)
    end

    error_response(:invalid_format)
  end

  private

  def supported_country?
    PATTERNS.key?(@country)
  end

  def canadian_short_tin?
    /\A\d{9}\z/ =~ @normalized_tin
  end

  def process_canadian_tin
    full_tin = "#{@normalized_tin}RT0001"
    success_response(:ca_gst, full_tin)
  end

  def process_au_abn
    unless AbnChecksumService.valid?(@normalized_tin)
      return error_response(:checksum_failed, tin_type: :au_abn, formatted_tin: formatted_tin(:au_abn))
    end

    api_result = AbnQueryClientService.call(@normalized_tin)

    if api_result[:success]
      success_response(:au_abn, business_registration: api_result[:data])
    else
      error_response(api_result[:error_key], tin_type: :au_abn, formatted_tin: formatted_tin(:au_abn))
    end
  end

  def success_response(type, tin = @normalized_tin, business_registration: nil)
    {
      valid: true,
      tin_type: type,
      formatted_tin: formatted_tin(type, tin),
      business_registration: business_registration,
      errors: []
    }.compact
  end

  def error_response(key, tin_type: nil, formatted_tin: nil)
    {
      valid: false,
      tin_type: tin_type,
      formatted_tin: formatted_tin,
      errors: [I18n.t(I18N_ERROR_KEYS.fetch(key), country: @country)]
    }
  end

  def formatted_tin(type, tin = @normalized_tin)
    case type
    when :au_abn then  tin.gsub(GROUPINGS[type], '\\1 \\2 \\3 \\4')
    when :au_acn then  tin.gsub(GROUPINGS[type], '\\1 \\2 \\3')
    else tin
    end
  end
end
