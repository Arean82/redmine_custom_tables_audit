RedmineApp::Application.routes.draw do
  get 'audit_settings', to: 'audit_settings#index'
  post 'audit_settings', to: 'audit_settings#update'
end
