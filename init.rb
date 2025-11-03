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
  
  # Ensure this plugin loads AFTER custom_tables plugin
  requires_redmine_plugin :custom_tables, version_or_higher: '0.0.1'
end

# Safe loading - only patch if custom_tables is available
Rails.configuration.to_prepare do
  begin
    if defined?(CustomTables::Record)
      require_dependency 'redmine_custom_tables_audit/record_patch'
      CustomTables::Record.include(RedmineCustomTablesAudit::RecordPatch)
    else
      Rails.logger.info "Custom Tables plugin not found - Custom Tables Audit plugin disabled"
    end
  rescue => e
    Rails.logger.error "Error loading Custom Tables Audit: #{e.message}"
  end
end