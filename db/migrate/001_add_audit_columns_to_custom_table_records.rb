class AddAuditColumnsToCustomTableRecords < ActiveRecord::Migration[6.1]
  def change
    # Try different possible table names
    table_names = [
      :custom_entities,           # Most common
      :custom_tables_records,     # Alternative
      :custom_table_records       # Another alternative
    ]
    
    table_name = table_names.find { |name| table_exists?(name) }
    
    unless table_name
      puts "Custom Tables records table not found - skipping migration"
      return
    end

    puts "Adding audit columns to #{table_name}"

    unless column_exists?(table_name, :created_by)
      add_column table_name, :created_by, :integer
      add_index table_name, :created_by
    end

    unless column_exists?(table_name, :created_at)
      add_column table_name, :created_at, :datetime
    end
  end
end