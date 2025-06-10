class TinFormatValidatorService < ApplicationService
  def initialize(country, raw)
    @country = country
    @raw = raw
    @processed_tin = raw.to_s.gsub(/\s+/, '').upcase
  end

  def call
    return unsupported_country_error unless country_supported?

    process_tin_for_canada || process_tin_other_countries || invalid_format_error
  end

  private

  def formats
    @formats ||= Constants::Formats::FORMATS
  end

  def country_supported?
    formats.key?(@country)
  end

  def country_formats
    formats[@country]
  end

  def process_tin_for_canada
    return unless @country == :CA && /^\d{9}$/.match?(@processed_tin)

    full_tin = "#{@processed_tin}RT0001"
    success_result(:ca_gst, full_tin)
  end

  def process_tin_other_countries
    country_formats.each do |type, rx|
      return success_result(type, @processed_tin) if rx.match?(@processed_tin)
    end

    nil
  end

  def success_result(type, valid_tin)
    { valid: true, tin_type: type, formatted_tin: format_tin(type, valid_tin), errors: [] }
  end

  def unsupported_country_error
    { valid: false, errors: [I18n.t('.tin_validator.errors.unsupported_country', country: @country)] }
  end

  def invalid_format_error
    { valid: false, tin_type: nil, formatted_tin: nil, errors: [
      I18n.t('.tin_validator.errors.invalid_format_or_length_for_specified_country')
    ] }
  end

  def groupings
    @groupings ||= Constants::Formats::GROUPINGS
  end

  def format_tin(type, valid_tin)
    case type
    when :au_abn
      valid_tin.gsub(groupings[type], '\1 \2 \3 \4')
    when :au_acn
      valid_tin.gsub(groupings[type], '\1 \2 \3')
    else
      valid_tin
    end
  end
end
