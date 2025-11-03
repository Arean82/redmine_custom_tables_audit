module RedmineCustomTablesAudit
  module CustomEntityCallbacks
    extend ActiveSupport::Concern

    included do
      before_create :set_audit_columns
    end

    private

    def set_audit_columns
      settings = Setting.plugin_redmine_custom_tables_audit || {}
      
      # Set created_by if enabled and column exists
      if settings['enable_created_by'] == '1' && self.class.column_names.include?('created_by')
        self.created_by = User.current.id
      end
      
      # Set created_at if enabled and column exists  
      if settings['enable_created_at'] == '1' && self.class.column_names.include?('created_at')
        self.created_at = Time.current
      end
    end
  end
end