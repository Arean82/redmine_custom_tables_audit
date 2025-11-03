RedmineApp::Application.routes.draw do
  # API routes for future integrations
  namespace :redmine_custom_tables_audit do
    match 'api/log_change', to: 'api#log_change', via: [:post, :put]
    match 'api/settings', to: 'api#get_settings', via: [:get]
    match 'api/test', to: 'api#test_connection', via: [:get]
  end
end