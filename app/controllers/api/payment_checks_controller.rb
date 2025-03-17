module Api
    class PaymentChecksController < ApplicationController
      def create
        check_params = params.permit(:grantType, :od_id, :ref_trade_id, :ref_user_id, :od_currency, :od_price)
        
        required = %w[grantType od_id ref_trade_id ref_user_id od_currency od_price]
        missing = required.select { |param| check_params[param].blank? }
        if missing.any?
          render json: { resultCode: '400', Msg: "Missing parameters: #{missing.join(', ')}" }, status: :bad_request and return
        end
        
        unless check_params[:grantType] == 'AuthorizationCode'
          render json: { resultCode: '400', Msg: 'Invalid grantType' }, status: :unprocessable_entity and return
        end
        
        # Simulate a check: if all required parameters are present and valid, we assume success.
        render json: { resultCode: '100', Msg: 'OK' }, status: :ok
      rescue StandardError => e
        Rails.logger.error "Error in PaymentChecksController#create: #{e.message}"
        render json: { resultCode: '500', Msg: 'Internal server error' }, status: :internal_server_error
      end
    end
  end
  