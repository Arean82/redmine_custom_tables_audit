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

# Patch the controller and model
Rails.configuration.to_prepare do
  begin
    # Patch CustomEntitiesController for logging
    if Object.const_defined?('CustomEntitiesController')
      require_dependency File.expand_path('../lib/redmine_custom_tables_audit/custom_entities_controller_patch', __FILE__)
      CustomEntitiesController.prepend(RedmineCustomTablesAudit::CustomEntitiesControllerPatch)
      Rails.logger.info "Custom Tables Audit: ✓ Successfully patched CustomEntitiesController"
    else
      Rails.logger.warn "Custom Tables Audit: CustomEntitiesController not found"
    end

    # Patch CustomEntity for audit columns
    if Object.const_defined?('CustomEntity')
      require_dependency File.expand_path('../lib/redmine_custom_tables_audit/custom_entity_callbacks', __FILE__)
      CustomEntity.include(RedmineCustomTablesAudit::CustomEntityCallbacks)
      Rails.logger.info "Custom Tables Audit: ✓ Successfully added callbacks to CustomEntity"
    else
      Rails.logger.warn "Custom Tables Audit: CustomEntity not found"
    end
    
  rescue => e
    Rails.logger.error "Custom Tables Audit: Error - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end