require 'redmine'

Redmine::Plugin.register :redmine_custom_tables_audit do
  name 'Custom Tables Audit'
  author 'Arean Narrayan'
  description 'Audits CustomTables plugin changes and logs them in issue history'
  version '0.0.2'
  settings default: { 
    'enable_audit_logging' => '1',
    'enable_created_by' => '1',
    'enable_created_at' => '1'
  },
  partial: 'audit_settings/index'
  
  # API permissions
  permission :custom_tables_audit_api, { 
    'redmine_custom_tables_audit/api' => [:log_change, :get_settings, :test_connection] 
  }, require: :loggedin
end

# Load components
Rails.configuration.to_prepare do
  begin
    # Load core observer
    require_dependency File.expand_path('../lib/redmine_custom_tables_audit/core_observer', __FILE__)
    
    # Load model mixin
    require_dependency File.expand_path('../lib/redmine_custom_tables_audit/model_mixin', __FILE__)
    
    # Load API controller
    require_dependency File.expand_path('../app/controllers/redmine_custom_tables_audit/api_controller', __FILE__)
    
    # Apply mixin to CustomEntity
    if Object.const_defined?('CustomEntity')
      CustomEntity.include(RedmineCustomTablesAudit::ModelMixin)
      Rails.logger.info "Custom Tables Audit: ✓ CustomEntity patched successfully"
    end
    
    Rails.logger.info "Custom Tables Audit: ✓ Plugin loaded successfully"
    
  rescue => e
    Rails.logger.error "Custom Tables Audit: ✗ Loading error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end
end