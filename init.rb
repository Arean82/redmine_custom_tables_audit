require 'redmine'

Redmine::Plugin.register :redmine_custom_tables_audit do
  name 'Custom Tables Audit'
  author 'Arean Narrayan'
  description 'Audits CustomTables plugin changes and logs them in issue history'
  version '0.0.2'
  settings default: { 'enable_audit_logging' => '1' },
           partial: 'audit_settings/index'
end

ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), 'app/observers')
Rails.application.config.active_record.observers ||= []
Rails.application.config.active_record.observers << :custom_table_record_observer

