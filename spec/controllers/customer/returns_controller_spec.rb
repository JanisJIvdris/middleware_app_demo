require 'rails_helper'

RSpec.describe Customer::ReturnsController, type: :controller do
  describe 'POST #create' do
    let(:valid_params) do
      {
        od_id: 'order123',
        ref_trade_id: 'trade123',
        ref_user_id: 'user@example.com',
        od_currency: 'KRW',
        od_price: '1000',
        od_tno: 'txn123',
        od_status: '10',
        api_result_send: '1',
        api_result_send_date: Time.now.to_s,
        resultCode: '100',
        return_url: 'https://trustedsite.com/return'
      }
    end

    let(:invalid_return_url_params) do
      valid_params.merge(return_url: 'https://malicious.com/return')
    end

    context 'with valid parameters and successful notification' do
      it 'redirects to return_url with payment_status paid' do
        allow(PaymentNotificationService).to receive(:send_status).and_return({ success: true })

        post :create, params: valid_params

        expect(response).to be_redirect
        expect(response.redirect_url).to include('payment_status=paid')
      end

      it 'appends payment_status to URL that already has query parameters' do
        valid_params_with_query = valid_params.merge(return_url: 'https://trustedsite.com/return?foo=bar')
        allow(PaymentNotificationService).to receive(:send_status).and_return({ success: true })

        post :create, params: valid_params_with_query

        expect(response).to be_redirect
        expect(response.redirect_url).to include('foo=bar')
        expect(response.redirect_url).to include('payment_status=paid')
      end
    end

    context 'with an invalid return_url' do
      it 'returns an error with status unprocessable_entity' do
        post :create, params: invalid_return_url_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid return URL')
      end
    end

    context 'when notification fails' do
      it 'returns an error with status bad_gateway' do
        allow(PaymentNotificationService).to receive(:send_status).and_return({ success: false })

        post :create, params: valid_params

        expect(response).to have_http_status(:bad_gateway)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Notification failed')
      end
    end

    context 'when an unexpected error occurs in the returns controller' do
      it 'returns an internal_server_error status' do
        allow(PaymentNotificationService).to receive(:send_status).and_raise(StandardError.new('Unexpected failure'))

        post :create, params: valid_params

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unexpected error')
      end
    end

    context 'when return_url is missing' do
      it 'returns an error with status unprocessable_entity' do
        params_missing_url = valid_params.except(:return_url)
        post :create, params: params_missing_url

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid return URL')
      end
    end
  end
end
