require 'rails_helper'

RSpec.describe TinFormatValidatorService, type: :service do
  subject(:result) { described_class.call(country, raw) }

  describe '#call' do
    context 'when unsupported country' do
      let(:country) { :US }
      let(:raw) { '123456' }

      it 'returns unsupported country error' do
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(
          I18n.t(Constants::Formats::I18N_ERROR_KEYS[:unsupported_country], country: country)
        )
        expect(result[:tin_type]).to be_nil
        expect(result[:formatted_tin]).to be_nil
      end
    end

    context 'when invalid format for supported country' do
      let(:country) { :AU }
      let(:raw) { '123' }

      it 'returns invalid format error' do
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(
          I18n.t(Constants::Formats::I18N_ERROR_KEYS[:invalid_format], country: country)
        )
        expect(result[:tin_type]).to be_nil
        expect(result[:formatted_tin]).to be_nil
      end
    end

    context 'When the country is Australia (AU)' do
      let(:country) { :AU }

      context 'with a valid ABN' do
        let(:raw) { '10120000004' }

        before do
          allow(AbnChecksumService).to receive(:valid?).with(raw).and_return(true)
          allow(AbnQueryClientService).to receive(:call).with(raw).and_return({
            success: true,
            data: {
              name: 'Example Company Pty',
              address: 'NSW 2001'
            }
          })
        end

        it 'validates and formats an ABN' do
          expect(result[:valid]).to be true
          expect(result[:tin_type]).to eq(:au_abn)
          expect(result[:formatted_tin]).to eq('10 120 000 004')
          expect(result[:business_registration]).to eq({
            name: 'Example Company Pty',
            address: 'NSW 2001'
          })
          expect(result[:errors]).to be_empty
        end
      end

      context 'with a valid ACN' do
        let(:raw) { '123456789' }

        it 'validates and formats an ACN' do
          expect(result[:valid]).to be true
          expect(result[:tin_type]).to eq(:au_acn)
          expect(result[:formatted_tin]).to eq('123 456 789')
          expect(result[:errors]).to be_empty
        end
      end

      context 'when ABN is correct format and checksum is correct too' do
        let(:raw) { '10120000004' }

        before do
          allow(AbnChecksumService).to receive(:valid?).with(raw).and_return(true)
          allow(AbnQueryClientService).to receive(:call).with(raw).and_return({
            success: true,
            data: {
              name: 'Example Company Pty',
              address: 'NSW 2001'
            }
          })
        end

        it 'returns success with formatted ABN' do
          expect(result[:valid]).to be true
          expect(result[:tin_type]).to eq(:au_abn)
          expect(result[:formatted_tin]).to eq('10 120 000 004')
          expect(result[:business_registration]).to eq({
            name: 'Example Company Pty',
            address: 'NSW 2001'
          })
          expect(result[:errors]).to be_empty
        end
      end

      context 'when ABN is correct format but fails checksum' do
        let(:raw) { '10120000005' }

        before { allow(AbnChecksumService).to receive(:valid?).with(raw).and_return(false) }

        it 'returns checksum failure' do
          expect(result[:valid]).to be false
          expect(result[:errors]).to include(I18n.t(Constants::Formats::I18N_ERROR_KEYS[:checksum_failed]))
          expect(result[:tin_type]).to eq(:au_abn)
          expect(result[:formatted_tin]).to eq('10 120 000 005')
        end
      end

      context 'when ABN is valid but not GST registered' do
        let(:raw) { '10000000000' }

        before do
          allow(AbnChecksumService).to receive(:valid?).with(raw).and_return(true)
          allow(AbnQueryClientService).to receive(:call).with(raw).and_return({
            success: false,
            error_key: :not_gst_registered
          })
        end

        it 'returns not GST registered error' do
          expect(result[:valid]).to be false
          expect(result[:errors]).to include(I18n.t(Constants::Formats::I18N_ERROR_KEYS[:not_gst_registered]))
          expect(result[:tin_type]).to eq(:au_abn)
          expect(result[:formatted_tin]).to eq('10 000 000 000')
        end
      end

      context 'when ABN API returns 404' do
        let(:raw) { '51824753556' }

        before do
          allow(AbnChecksumService).to receive(:valid?).with(raw).and_return(true)
          allow(AbnQueryClientService).to receive(:call).with(raw).and_return({
            success: false,
            error_key: :api_not_found
          })
        end

        it 'returns API not found error' do
          expect(result[:valid]).to be false
          expect(result[:errors]).to include(I18n.t(Constants::Formats::I18N_ERROR_KEYS[:api_not_found]))
          expect(result[:tin_type]).to eq(:au_abn)
          expect(result[:formatted_tin]).to eq('51 824 753 556')
        end
      end

      context 'when ABN API returns 500 or connection error' do
        let(:raw) { '53004085616' }

        before do
          allow(AbnChecksumService).to receive(:valid?).with(raw).and_return(true)
          allow(AbnQueryClientService).to receive(:call).with(raw).and_return({
            success: false,
            error_key: :api_error
          })
        end

        it 'returns API error' do
          expect(result[:valid]).to be false
          expect(result[:errors]).to include(I18n.t(Constants::Formats::I18N_ERROR_KEYS[:api_error]))
          expect(result[:tin_type]).to eq(:au_abn)
          expect(result[:formatted_tin]).to eq('53 004 085 616')
        end
      end
    end

    context 'When the country is Canada (CA)' do
      let(:country) { :CA }

      context 'with a 9-digit GST' do
        let(:raw) { '987654321' }

        it 'adds RT0001 and succeeds' do
          expect(result[:valid]).to be true
          expect(result[:tin_type]).to eq(:ca_gst)
          expect(result[:formatted_tin]).to eq('987654321RT0001')
          expect(result[:errors]).to be_empty
        end
      end

      context 'with a full GST' do
        let(:raw) { '987654321RT0001' }

        it 'accepts it as-is' do
          expect(result[:valid]).to be true
          expect(result[:tin_type]).to eq(:ca_gst)
          expect(result[:formatted_tin]).to eq('987654321RT0001')
          expect(result[:errors]).to be_empty
        end
      end
    end

    context 'When the country is India (IN)' do
      let(:country) { :IN }

      context 'with a valid GSTIN' do
        let(:raw) { '27ABCDEFGHIJZ1Z5' }

        it 'validates and returns it unchanged' do
          expect(result[:valid]).to be true
          expect(result[:tin_type]).to eq(:in_gst)
          expect(result[:formatted_tin]).to eq('27ABCDEFGHIJZ1Z5')
          expect(result[:errors]).to be_empty
        end
      end

      context 'with an invalid GSTIN' do
        let(:raw) { '27ABC123' }

        it 'rejects it' do
          expect(result[:valid]).to be false
          expect(result[:errors]).to include(
            I18n.t(Constants::Formats::I18N_ERROR_KEYS[:invalid_format], country: country)
          )
          expect(result[:tin_type]).to be_nil
          expect(result[:formatted_tin]).to be_nil
        end
      end
    end
  end
end
