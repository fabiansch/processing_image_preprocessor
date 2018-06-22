Rails.application.routes.draw do
  resource :pre_process_image, only: :create
  get '/_health', to: 'healths#show'
end
