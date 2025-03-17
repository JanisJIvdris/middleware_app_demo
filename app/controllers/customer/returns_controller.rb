module Customer
    class ReturnsController < ApplicationController
      require 'uri'
      
      def create
        data = permitted_return_params
        
        unless valid_return_url?(data[:return_url])
          return render json: { error: 'Invalid return URL' }, status: :unprocessable_entity
        end
  
        payment_status = (data[:od_status] == '10' && data[:resultCode] == '100') ? 'paid' : 'failed'
        notification_response = PaymentNotificationService.send_status(data[:od_id], payment_status)
  
        if notification_response[:success]
          redirect_to append_status_to_url(data[:return_url], payment_status), allow_other_host: true
        else
          render json: { error: 'Notification failed' }, status: :bad_gateway
        end
      rescue StandardError => e
        Rails.logger.error "Error in ReturnsController#create: #{e.message}"
        render json: { error: 'Unexpected error' }, status: :internal_server_error
      end
  
      private
  
      def permitted_return_params
        params.permit(:od_id, :ref_trade_id, :ref_user_id, :od_currency, :od_price, :od_tno, :od_status, :api_result_send, :api_result_send_date, :resultCode, :return_url)
      end
  
      def valid_return_url?(url)
        return false if url.blank?
        uri = URI.parse(url) rescue nil
        return false unless uri && uri.host
        ::ALLOWED_RETURN_HOSTS.include?(uri.host)
      end
  
      def append_status_to_url(url, status)
        uri = URI.parse(url)
        query_params = URI.decode_www_form(uri.query.to_s)
        query_params << ['payment_status', status]
        uri.query = URI.encode_www_form(query_params)
        uri.to_s
      end
    end
  end
  