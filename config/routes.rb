Rails.application.routes.draw do
  resource :process_image, only: :create
  get '/_health', to: 'healths#show'
end
