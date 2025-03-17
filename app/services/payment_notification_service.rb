require 'net/http'
require 'uri'
require 'json'

class PaymentNotificationService
  PARTNER_PURCHASE_URL = ENV.fetch('PARTNER_PURCHASE_URL', 'http://testpayments.com/api/purchase/')

  def self.send_status(od_id, status)
    uri = URI("#{PARTNER_PURCHASE_URL}#{od_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri, { 'Content-Type' => 'application/json' })
    request.body = { status: status }.to_json

    # Uncomment for a real HTTP call:
    # response = http.request(request)
    # parsed = JSON.parse(response.body, symbolize_names: true)
    # { success: parsed[:resultCode] == '100' }
    
    # Simulated response for testing:
    { success: true }
  rescue StandardError => e
    Rails.logger.error "PaymentNotificationService error: #{e.message}"
    { success: false, error: e.message }
  end
end
