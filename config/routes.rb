Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'tin_validations/validate', to: 'tin_validations#validate'
    end
  end
end
