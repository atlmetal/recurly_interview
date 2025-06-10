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
          I18n.t('.tin_validator.errors.unsupported_country', country: country)
        )
        expect(result).not_to have_key(:tin_type)
        expect(result[:formatted_tin]).to be_nil
      end
    end

    context 'when invalid format for supported country' do
      let(:country) { :AU }
      let(:raw) { '123' }

      it 'returns invalid format error' do
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(
          I18n.t('.tin_validator.errors.invalid_format_or_length_for_specified_country')
        )
        expect(result[:tin_type]).to be_nil
        expect(result[:formatted_tin]).to be_nil
      end
    end

    context 'When the country is Australia (AU)' do
      let(:country) { :AU }

      context 'with a valid ABN' do
        let(:raw) { '10120000004' }

        it 'validates and formats an ABN' do
          expect(result[:valid]).to be true
          expect(result[:tin_type]).to eq(:au_abn)
          expect(result[:formatted_tin]).to eq('10 120 000 004')
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
            I18n.t('.tin_validator.errors.invalid_format_or_length_for_specified_country')
          )
          expect(result[:tin_type]).to be_nil
          expect(result[:formatted_tin]).to be_nil
        end
      end
    end
  end
end
