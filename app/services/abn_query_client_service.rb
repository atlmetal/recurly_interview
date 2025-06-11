require 'net/http'
require 'rexml/document'

class AbnQueryClientService < ApplicationService
  def initialize(abn)
    @abn = abn
    @uri = URI('http://localhost:8080/queryABN')
    @uri.query = URI.encode_www_form({ abn: @abn })
  end

  def call
    response = Net::HTTP.get_response(@uri)

    case response
    when Net::HTTPSuccess
      parse_success_response(response.body)
    when Net::HTTPNotFound
      { success: false, error_key: :api_not_found }
    else
      { success: false, error_key: :api_error }
    end
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout
    { success: false, error_key: :api_error }
  end

  private

  def parse_success_response(xml_body)
    doc = REXML::Document.new(xml_body)
    entity_path = 'abn_response/response/businessEntity'

    gst_registered = REXML::XPath.first(doc, "#{entity_path}/goodsAndServicesTax")&.text == 'true'
    return { success: false, error_key: :not_gst_registered } unless gst_registered

    name = REXML::XPath.first(doc, "#{entity_path}/organisationName")&.text
    address_state = REXML::XPath.first(doc, "#{entity_path}/address/stateCode")&.text
    address_postcode = REXML::XPath.first(doc, "#{entity_path}/address/postcode")&.text

    {
      success: true,
      data: {
        name: name,
        address: "#{address_state} #{address_postcode}"
      }
    }
  end
end
