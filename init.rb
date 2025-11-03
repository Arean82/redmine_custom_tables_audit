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

# Patch the CustomEntitiesController
Rails.configuration.to_prepare do
  begin
    if Object.const_defined?('CustomEntitiesController')
      require_dependency File.expand_path('../lib/redmine_custom_tables_audit/custom_entities_controller_patch', __FILE__)
      CustomEntitiesController.include(RedmineCustomTablesAudit::CustomEntitiesControllerPatch)
      Rails.logger.info "Custom Tables Audit: ✓ Successfully patched CustomEntitiesController"
    else
      Rails.logger.warn "Custom Tables Audit: CustomEntitiesController not found"
    end
  rescue => e
    Rails.logger.error "Custom Tables Audit: Error patching controller - #{e.message}"
  end
end

## Safe loading with proper error handling
#Rails.configuration.to_prepare do
#  begin
#    # Try different possible class names used by custom_tables plugin
#    target_class = nil
#    
#    if Object.const_defined?('CustomEntity')
#      target_class = CustomEntity
#      Rails.logger.info "Custom Tables Audit: Found CustomEntity class"
#    elsif Object.const_defined?('CustomTables::Record')
#      target_class = CustomTables::Record
#      Rails.logger.info "Custom Tables Audit: Found CustomTables::Record class"
#    elsif Object.const_defined?('CustomTableRecord')
#      target_class = CustomTableRecord
#      Rails.logger.info "Custom Tables Audit: Found CustomTableRecord class"
#    end
#    
#    if target_class
#      require_dependency File.expand_path('../lib/redmine_custom_tables_audit/record_patch', __FILE__)
#      target_class.include(RedmineCustomTablesAudit::RecordPatch) unless target_class.include?(RedmineCustomTablesAudit::RecordPatch)
#      Rails.logger.info "Custom Tables Audit: Successfully patched #{target_class.name}"
#    else
#      Rails.logger.warn "Custom Tables Audit: No custom table model found - plugin disabled"
#    end
#  rescue LoadError => e
#    Rails.logger.error "Custom Tables Audit: LoadError - #{e.message}"
#  rescue => e
#    Rails.logger.error "Custom Tables Audit: Error - #{e.message}"
#  end
#end