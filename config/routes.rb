Rails.application.routes.draw do
  resources :cards, only:[:index] do
    collection do
      post 'create_backup'
      delete 'delete_backup'
    end
  end
  root to: 'cards#index'
end
