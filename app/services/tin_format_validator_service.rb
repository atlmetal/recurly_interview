class TinFormatValidatorService < ApplicationService
  FORMATS = {
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

  def initialize(country, raw)
    @country = country
    @raw = raw
    @processed_tin = raw.to_s.gsub(/\s+/, '').upcase
  end

  def call
    return unsupported_country_error unless country_supported?

    find_and_process_matching_format || invalid_format_error
  end

  private

  def country_supported?
    FORMATS.key?(@country)
  end

  def country_formats
    FORMATS[@country]
  end

  def find_and_process_matching_format
    country_formats.each do |type, rx|
      if rx.match?(@processed_tin)
        return success_result(type, @processed_tin)
      end
    end

    if @country == :CA && /^\d{9}$/.match?(@processed_tin)
      full_tin = @processed_tin + 'RT0001'
      return success_result(:ca_gst, full_tin)
    end

    nil
  end

  def success_result(type, valid_tin)
    { valid: true, tin_type: type, formatted_tin: format_tin(type, valid_tin), errors: [] }
  end

  def unsupported_country_error
    { valid: false, errors: ["Unsupported country '#{@country}'"] }
  end

  def invalid_format_error
    { valid: false, tin_type: nil, formatted_tin: nil, errors: ['Invalid format or length for specified country'] }
  end

  def format_tin(type, valid_tin)
    case type
    when :au_abn
      valid_tin.gsub(GROUPINGS[type], '\1 \2 \3 \4')
    when :au_acn
      valid_tin.gsub(GROUPINGS[type], '\1 \2 \3')
    else
      valid_tin
    end
  end
end
