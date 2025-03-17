module Api
    class PurchasesController < ApplicationController
      def create
        data = purchase_params
        response = PartnerApiService.authenticate_payment(data)
        
        if response[:resultCode] == '100'
          render json: response.slice(:accessToken, :od_id), status: :ok
        else
          render json: { error: response[:Error] }, status: :unprocessable_entity
        end
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue StandardError => e
        Rails.logger.error "Error in PurchasesController#create: #{e.message}"
        render json: { error: 'Unexpected error' }, status: :internal_server_error
      end
  
      private
  
      def purchase_params
        params.require(:purchase).permit(:ref_trade_id, :ref_user_id, :od_currency, :od_price, :return_url)
      end
    end
  end
  