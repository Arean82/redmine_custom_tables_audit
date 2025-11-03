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

# Safe loading with proper error handling
Rails.configuration.to_prepare do
  begin
    # Check if CustomTables::Record class exists
    if Object.const_defined?('CustomTables::Record')
      require_dependency File.expand_path('../lib/redmine_custom_tables_audit/record_patch', __FILE__)
      CustomTables::Record.include(RedmineCustomTablesAudit::RecordPatch) unless CustomTables::Record.include?(RedmineCustomTablesAudit::RecordPatch)
      Rails.logger.info "Custom Tables Audit: Successfully patched CustomTables::Record"
    else
      Rails.logger.warn "Custom Tables Audit: CustomTables::Record not found - plugin disabled"
    end
  rescue LoadError => e
    Rails.logger.error "Custom Tables Audit: LoadError - #{e.message}"
  rescue => e
    Rails.logger.error "Custom Tables Audit: Error - #{e.message}"
  end
end