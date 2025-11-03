class AddAuditColumnsToCustomTableRecords < ActiveRecord::Migration[6.1]
  def change
    # Check if the custom tables plugin is installed
    unless defined?(CustomTables::Record)
      puts "Custom Tables plugin not found - skipping migration"
      return
    end
    
    table_name = CustomTables::Record.table_name

    unless column_exists?(table_name, :created_by)
      add_column table_name, :created_by, :integer
      add_index table_name, :created_by
    end

    unless column_exists?(table_name, :created_at)
      add_column table_name, :created_at, :datetime
    end
  end
end