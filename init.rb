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
end

# Simple direct approach
Rails.configuration.to_prepare do
  begin
    # Load our classes
    require_dependency File.expand_path('../lib/redmine_custom_tables_audit/simple_audit', __FILE__)
    require_dependency File.expand_path('../lib/redmine_custom_tables_audit/column_manager', __FILE__)
    require_dependency File.expand_path('../lib/redmine_custom_tables_audit/model_callbacks', __FILE__)
    
    # Try to patch CustomEntity model
    if Object.const_defined?('CustomEntity')
      CustomEntity.include(RedmineCustomTablesAudit::ModelCallbacks)
      Rails.logger.info "Custom Tables Audit: ✓ Successfully added callbacks to CustomEntity"
      
      # Ensure columns exist
      RedmineCustomTablesAudit::ColumnManager.add_columns_to_existing_tables
    else
      Rails.logger.warn "Custom Tables Audit: CustomEntity not found"
    end
    
  rescue => e
    Rails.logger.error "Custom Tables Audit: Error - #{e.message}"
  end
end