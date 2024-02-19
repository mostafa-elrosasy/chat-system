Rails.application.routes.draw do
  resources :applications, param: :token, only:[:create, :show] do
    resources :chats, param: :number, only: [:create, :show] do
      resources :messages, param: :number, only: [:create, :show] do 
        collection do
          get 'search'
        end
      end
    end
  end
end
