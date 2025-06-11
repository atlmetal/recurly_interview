require 'rails_helper'

RSpec.describe Api::V1::TinValidationsController, type: :controller do
  describe 'GET #validate' do
    let(:valid_params) { { country: :AU, number: '10120000004' } }
    let(:invalid_params) { { country: :US, number: 'dummy_sample' } }
    let(:service_instance_double) { instance_double(TinFormatValidatorService) }

    before do
      allow(TinFormatValidatorService).to receive(:new).and_return(service_instance_double)
    end

    context 'when service returns valid' do
      before do
        allow(TinFormatValidatorService).to receive(:new)
          .with(:AU, '10120000004').and_return(service_instance_double)

        allow(service_instance_double).to receive(:call).and_return(
          { valid: true, tin_type: :au_abn, formatted_tin: '10 120 000 004', errors: [] }
        )
      end

      it 'returns http success' do
        get :validate, params: valid_params, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns validation result in JSON' do
        get :validate, params: valid_params, as: :json
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to eq({
          'valid' => true,
          'tin_type' => 'au_abn',
          'formatted_tin' => '10 120 000 004',
          'errors' => []
        })
      end
    end

    context 'when service returns errors' do
      let(:errors) { ['Invalid format or length for specified country'] }

      before do
        allow(TinFormatValidatorService).to receive(:new)
          .with(:US, 'dummy_sample').and_return(service_instance_double)

        allow(service_instance_double).to receive(:call).and_return(
          { valid: false, tin_type: nil, formatted_tin: nil, errors: errors }
        )
      end

      it 'returns http unprocessable_entity' do
        get :validate, params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors in JSON' do
        get :validate, params: invalid_params, as: :json
        expect(JSON.parse(response.body)).to eq({
          'valid' => false,
          'tin_type' => nil,
          'formatted_tin' => nil,
          'errors' => errors
        })
      end
    end
  end
end
