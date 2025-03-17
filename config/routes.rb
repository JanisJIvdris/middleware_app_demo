Rails.application.routes.draw do
  namespace :api do
    post 'purchase', to: 'purchases#create'
    post 'check', to: 'payment_checks#create'
  end

  namespace :customer do
    post 'returns', to: 'returns#create'
  end

end
