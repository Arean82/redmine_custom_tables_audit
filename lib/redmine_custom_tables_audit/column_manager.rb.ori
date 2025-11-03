module RedmineCustomTablesAudit
  class ColumnManager
    class << self
      def ensure_audit_columns(custom_entity)
        return unless audit_columns_enabled?
        
        settings = Setting.plugin_redmine_custom_tables_audit || {}
        
        # Set created_by if enabled and column exists
        if settings['enable_created_by'] == '1' && custom_entity.respond_to?(:created_by=)
          custom_entity.created_by = User.current.id if custom_entity.new_record?
        end
        
        # Set created_at if enabled and column exists  
        if settings['enable_created_at'] == '1' && custom_entity.respond_to?(:created_at=)
          custom_entity.created_at = Time.current if custom_entity.new_record?
        end
      end
      
      def add_columns_to_existing_tables
        return unless audit_columns_enabled?
        
        settings = Setting.plugin_redmine_custom_tables_audit || {}
        
        if Object.const_defined?('CustomEntity')
          table_name = CustomEntity.table_name
          
          # Add created_by column if enabled and doesn't exist
          if settings['enable_created_by'] == '1' && !column_exists?(table_name, :created_by)
            add_column(table_name, :created_by, :integer)
            add_index(table_name, :created_by)
            Rails.logger.info "Custom Tables Audit: ✓ Added created_by column to #{table_name}"
          end
          
          # Add created_at column if enabled and doesn't exist
          if settings['enable_created_at'] == '1' && !column_exists?(table_name, :created_at)
            add_column(table_name, :created_at, :datetime)
            Rails.logger.info "Custom Tables Audit: ✓ Added created_at column to #{table_name}"
          end
        end
      end
      
      private
      
      def audit_columns_enabled?
        settings = Setting.plugin_redmine_custom_tables_audit || {}
        settings['enable_created_by'] == '1' || settings['enable_created_at'] == '1'
      end
      
      def column_exists?(table_name, column_name)
        ActiveRecord::Base.connection.column_exists?(table_name, column_name)
      end
      
      def add_column(table_name, column_name, column_type)
        ActiveRecord::Base.connection.add_column(table_name, column_name, column_type)
      end
      
      def add_index(table_name, column_name)
        ActiveRecord::Base.connection.add_index(table_name, column_name)
      end
    end
  end
end