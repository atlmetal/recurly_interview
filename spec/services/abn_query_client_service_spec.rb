require 'rails_helper'
require 'webmock/rspec'

RSpec.describe AbnQueryClientService, type: :service do
  subject { described_class.call(abn) }

  let(:abn) { '10120000004' }
  let(:base_uri) { 'http://localhost:8080/queryABN' }
  let(:query_uri) { "#{base_uri}?abn=#{abn}" }

  describe '#call' do
    context 'when the API call is successful' do
      context 'and the business is GST registered' do
        let(:xml_response) do
          <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <abn_response>
              <response>
                <businessEntity>
                  <goodsAndServicesTax>true</goodsAndServicesTax>
                  <organisationName>Example Company Pty Ltd</organisationName>
                  <address>
                    <stateCode>NSW</stateCode>
                    <postcode>2000</postcode>
                  </address>
                </businessEntity>
              </response>
            </abn_response>
          XML
        end

        before { stub_request(:get, query_uri).to_return(status: 200, body: xml_response) }

        it 'returns a success status' do
          expect(subject[:success]).to be true
        end

        it 'returns the parsed business data' do
          expected_data = { name: 'Example Company Pty Ltd', address: 'NSW 2000' }
          expect(subject[:data]).to eq(expected_data)
        end
      end

      context 'and the business is not GST registered' do
        let(:xml_response_no_gst) do
          <<~XML
            <abn_response><response><businessEntity><goodsAndServicesTax>false</goodsAndServicesTax></businessEntity></response></abn_response>
          XML
        end

        before { stub_request(:get, query_uri).to_return(status: 200, body: xml_response_no_gst) }

        it 'returns a failure status' do
          expect(subject[:success]).to be false
        end

        it 'returns the correct error key' do
          expect(subject[:error_key]).to eq(:not_gst_registered)
        end
      end
    end

    context 'when the API returns a 404 Not Found error' do
      before { stub_request(:get, query_uri).to_return(status: 404, body: '') }

      it 'returns a failure status' do
        expect(subject[:success]).to be false
      end

      it 'returns the :api_not_found error key' do
        expect(subject[:error_key]).to eq(:api_not_found)
      end
    end

    context 'when the API returns a 500 Internal Server Error' do
      before { stub_request(:get, query_uri).to_return(status: 500, body: '') }

      it 'returns a failure status' do
        expect(subject[:success]).to be false
      end

      it 'returns the :api_error error key' do
        expect(subject[:error_key]).to eq(:api_error)
      end
    end

    context 'when a network error occurs' do
      before { stub_request(:get, query_uri).to_raise(Errno::ECONNREFUSED) }

      it 'returns a failure status' do
        expect(subject[:success]).to be false
      end

      it 'returns the :api_error error key' do
        expect(subject[:error_key]).to eq(:api_error)
      end
    end
  end
end
