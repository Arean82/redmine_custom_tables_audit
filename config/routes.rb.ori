#RedmineApp::Application.routes.draw do
#  get 'audit_settings', to: 'audit_settings#index'
#  post 'audit_settings', to: 'audit_settings#update'
#end

RedmineApp::Application.routes.draw do
  match 'settings/plugin/redmine_custom_tables_audit', to: 'audit_settings#index', via: :get
  match 'settings/plugin/redmine_custom_tables_audit', to: 'audit_settings#update', via: :post
end

