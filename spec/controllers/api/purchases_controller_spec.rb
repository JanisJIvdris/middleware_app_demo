require 'rails_helper'

RSpec.describe Api::PurchasesController, type: :controller do
  describe 'POST #create' do
    let(:valid_params) do
      {
        purchase: {
          ref_trade_id: 'trade123',
          ref_user_id: 'user@example.com',
          od_currency: 'KRW',
          od_price: '1000',
          return_url: 'https://trustedsite.com/return'
        }
      }
    end

    let(:invalid_params) do
      {
        purchase: {
          ref_trade_id: '',
          ref_user_id: '',
          od_currency: 'KRW',
          od_price: '1000',
          return_url: 'https://trustedsite.com/return'
        }
      }
    end

    context 'when valid parameters are provided' do
      it 'returns accessToken and od_id with status ok' do
        # Simulate a successful response from the Partner API
        allow(PartnerApiService).to receive(:authenticate_payment).and_return({
          resultCode: '100',
          accessToken: 'abc123token',
          od_id: 'order123'
        })

        post :create, params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['accessToken']).to eq('abc123token')
        expect(json_response['od_id']).to eq('order123')
      end
    end

    context 'when invalid parameters are provided' do
      it 'returns an error with status unprocessable_entity' do
        # Simulate an error response from the Partner API
        allow(PartnerApiService).to receive(:authenticate_payment).and_return({
          resultCode: '400',
          Error: 'Invalid parameters'
        })

        post :create, params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid parameters')
      end
    end

    context 'when purchase parameter is missing' do
      it 'returns a bad_request status' do
        post :create, params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to match(/param is missing or the value is empty/)
      end
    end

    context 'when an unexpected error occurs' do
      it 'returns an internal_server_error status' do
        allow(PartnerApiService).to receive(:authenticate_payment).and_raise(StandardError.new('Unexpected failure'))

        post :create, params: valid_params, as: :json

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unexpected error')
      end
    end
  end
end
