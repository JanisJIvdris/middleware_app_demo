# Middleware App Demo

A Ruby on Rails API-only middleware application that integrates with a Partner's payment API. This solution demonstrates clean, secure, and efficient coding practices for payment systems, complete with in-depth tests and style enforcement using RuboCop.

## Overview

This middleware app provides three primary endpoints:

1. **POST `/api/purchase`**

   - **Purpose:** Request an access token and order ID by sending payment data to the Partner's `/paygate/auth/` endpoint.
   - **Response:** On success, returns JSON with an `accessToken` and `od_id` (HTTP 200). On failure, returns an error message (HTTP 422).

2. **POST `/customer/returns`**

   - **Purpose:** Process the customer return after payment completion by:
     - Verifying the payment status based on form data.
     - Sending a PUT request to update the payment status on the Partner's purchase endpoint.
     - Safely redirecting the user to a validated `return_url` with an appended `payment_status` query parameter.
   - **Security:** Protects against open redirects by validating `return_url` against a whitelist.

3. **POST `/api/check`**
   - **Purpose:** Verify if an order has been successfully completed.
   - **Request:** Expects JSON parameters:
     - `grantType` (required, fixed value: `AuthorizationCode`)
     - `od_id` (required)
     - `ref_trade_id` (required)
     - `ref_user_id` (required)
     - `od_currency` (required, should be `KRW`)
     - `od_price` (required)
   - **Response:** On success, returns `{ "resultCode": "100", "Msg": "OK" }` (HTTP 200); otherwise, an appropriate error message.

## Solution Approach and Design Decisions

### 1. API Endpoints

- **POST `/api/purchase`:**

  - Uses strong parameter filtering to securely extract payment data.
  - Delegates external HTTP communication to `PartnerApiService` for a clean separation of concerns.
  - Returns appropriate HTTP statuses based on the Partner's response.

- **POST `/customer/returns`:**

  - Extracts and validates form data, determining payment status based on `od_status` and `resultCode`.
  - Validates `return_url` against a whitelist (defined in `config/initializers/allowed_return_urls.rb`) to prevent open redirects.
  - Uses `PaymentNotificationService` to simulate a status update on the Partner's endpoint.
  - Safely redirects the user to the validated URL with `allow_other_host: true`.

- **POST `/api/check`:**
  - Validates required parameters, ensuring `grantType` equals `AuthorizationCode`.
  - Returns a successful response if all validations pass; otherwise, responds with error details.

### 2. Service Objects

- **PartnerApiService:**  
  Encapsulates the logic for sending payment data to the Partner's `/paygate/auth/` endpoint. This isolation simplifies testing and maintenance.

- **PaymentNotificationService:**  
  Manages communication with the Partner's purchase endpoint, simulating a status update via a PUT request.

### 3. Security Considerations

- **Open Redirect Prevention:**  
  The solution validates the `return_url` against a whitelist (`ALLOWED_RETURN_HOSTS`) to ensure redirection occurs only to trusted domains.
- **Error Handling:**  
  Controllers use rescue blocks to log unexpected errors and return user-friendly error messages, without exposing internal details.

- **Environment Configuration:**  
  External API URLs are configurable via environment variables, reducing the risk of hard-coded sensitive data.

### 4. Testing and Code Quality

- **RSpec:**  
  Comprehensive tests cover valid, invalid, and edge-case scenarios for all endpoints, ensuring robust functionality.

- **RuboCop:**  
  The project uses RuboCop (with rubocop-rails and rubocop-rspec) to enforce Ruby style guidelines, ensuring the code remains clean and maintainable.

### 5. Exclusions

- **Database:**  
  Since the middleware app does not require data persistence, no database setup is needed.

## Project Structure

```
middleware_app_demo/
├── app
│   ├── controllers
│   │   ├── api
│   │   │   ├── purchases_controller.rb
│   │   │   └── payment_checks_controller.rb
│   │   └── customer
│   │       └── returns_controller.rb
│   └── services
│       ├── partner_api_service.rb
│       └── payment_notification_service.rb
├── config
│   ├── initializers
│   │   └── allowed_return_urls.rb
│   └── routes.rb
├── spec
│   └── controllers
│       ├── api
│       │   └── purchases_controller_spec.rb
│       └── customer
│           └── returns_controller_spec.rb
├── Gemfile
├── Gemfile.lock
└── README.md
```

## Getting Started

### Prerequisites

- Ruby 3.2.3
- Rails 7.1.x
- Bundler

### Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/my_repo
   cd middleware_app_demo
   ```

2. **Install Dependencies**

   ```bash
   bundle install
   ```

3. **Setup the Database**

   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Start the Rails Server**

   ```bash
   rails server
   ```

   The server will run at http://localhost:3000.

## Configuration

### Environment Variables:

You can configure external API endpoints using environment variables in your shell or by creating a .env file with the following keys:

- `PARTNER_AUTH_URL` – URL for Partner's `/paygate/auth/` endpoint.
- `PARTNER_PURCHASE_URL` – URL for Partner's purchase endpoint (e.g., `http://testpayments.com/api/purchase/`).

### Allowed Return URLs:

The whitelist for safe redirects is defined in `config/initializers/allowed_return_urls.rb`:

```ruby
ALLOWED_RETURN_HOSTS = ['trustedsite.com', 'www.trustedsite.com']
```

## Running Tests

The project uses RSpec for testing. To run all tests:

```bash
bundle exec rspec
```

Tests cover all edge cases including:

- Valid and invalid parameters for both endpoints.
- Handling of missing parameters.
- Simulated service errors.
- Correct behavior of redirection and query parameter appending.
- Open redirect prevention.

## Testing Endpoints with Postman

### `/api/purchase` Endpoint

- **Method:** POST
- **URL:** http://localhost:3000/api/purchase
- **Headers:** Content-Type: application/json
- **Body (raw JSON):**

```json
{
  "purchase": {
    "ref_trade_id": "trade123",
    "ref_user_id": "user@example.com",
    "od_currency": "KRW",
    "od_price": "1000",
    "return_url": "https://trustedsite.com/return"
  }
}
```

- **Expected Response:**
  - On success: HTTP 200 with JSON containing accessToken and od_id.
  - On failure: HTTP 422 with an error message.

### `/customer/returns` Endpoint

- **Method:** POST
- **URL:** http://localhost:3000/customer/returns
- **Body (x-www-form-urlencoded):**

| Key                  | Value                          |
| -------------------- | ------------------------------ |
| od_id                | order123                       |
| ref_trade_id         | trade123                       |
| ref_user_id          | user@example.com               |
| od_currency          | KRW                            |
| od_price             | 1000                           |
| od_tno               | txn123                         |
| od_status            | 10                             |
| api_result_send      | 1                              |
| api_result_send_date | 2025-03-17T12:00:00Z           |
| resultCode           | 100                            |
| return_url           | https://trustedsite.com/return |

- **Expected Behavior:**
  - The endpoint should process the form data, send a notification, and redirect to https://trustedsite.com/return?payment_status=paid.
  - If Postman automatically follows redirects, disable that setting to inspect the Location header.

### `/api/check` Endpoint

- **Method:** POST
- **URL:** http://localhost:3000/customer/check
- **Headers:** Content-Type: application/json
- **Body (raw JSON):**

```json
{
  "grantType": "AuthorizationCode",
  "od_id": "order123",
  "ref_trade_id": "trade123",
  "ref_user_id": "user@example.com",
  "od_currency": "KRW",
  "od_price": "1000"
}
```

- **Expected Behavior:**
  - Success: HTTP 200 with { "resultCode": "100", "Msg": "OK" }.
  - Failure: Returns an appropriate error message and status code.

## Code Quality & Style

### RuboCop:

Run RuboCop to check for style issues:

```bash
bundle exec rubocop
```

### Auto-Correct:

Automatically fix many style issues with:

```bash
bundle exec rubocop -a
```

## Future Enhancements

- Implement additional endpoints for payment completion checks.
- Integrate real HTTP calls for Partner's API endpoints once ready.
- Add logging and monitoring for production readiness.
