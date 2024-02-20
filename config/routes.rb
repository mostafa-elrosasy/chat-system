Rails.application.routes.draw do
  resources :applications, param: :token, only:[:create, :show, :update] do
    resources :chats, param: :number, only: [:create, :show, :index] do
      resources :messages, param: :number, only: [:create, :show, :index, :update] do 
        collection do
          get 'search'
        end
      end
    end
  end
end
