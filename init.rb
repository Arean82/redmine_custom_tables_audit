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

# Patch the CustomEntity model
Rails.configuration.to_prepare do
  begin
    if Object.const_defined?('CustomEntity')
      require_dependency File.expand_path('../lib/redmine_custom_tables_audit/custom_entity_patch', __FILE__)
      
      unless CustomEntity.included_modules.include?(RedmineCustomTablesAudit::CustomEntityPatch)
        CustomEntity.include(RedmineCustomTablesAudit::CustomEntityPatch)
      end
      
      Rails.logger.info "Custom Tables Audit: ✓ Successfully patched CustomEntity"
    else
      Rails.logger.warn "Custom Tables Audit: CustomEntity not found - make sure custom_tables plugin is installed"
    end
  rescue => e
    Rails.logger.error "Custom Tables Audit: Error - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end