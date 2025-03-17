require 'net/http'
require 'uri'
require 'json'

class PartnerApiService
  PARTNER_AUTH_URL = ENV.fetch('PARTNER_AUTH_URL', 'http://partnerapp.com/paygate/auth/')

  def self.authenticate_payment(data)
    uri = URI(PARTNER_AUTH_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json' })
    request.body = data.to_json

    # Uncomment for a real HTTP call:
    # response = http.request(request)
    # JSON.parse(response.body, symbolize_names: true)
    
    # Simulated response for testing:
    if data[:ref_trade_id].present? && data[:ref_user_id].present?
      { resultCode: '100', accessToken: 'abc123token', od_id: 'order123' }
    else
      { resultCode: '400', Error: 'Invalid parameters' }
    end
  rescue StandardError => e
    Rails.logger.error "PartnerApiService error: #{e.message}"
    { resultCode: '500', Error: 'Internal server error' }
  end
end
