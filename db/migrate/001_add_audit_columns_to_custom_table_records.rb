class AddAuditColumnsToCustomTableRecords < ActiveRecord::Migration[6.1]
  def change
    # Use the correct table name
    table_name = :custom_entities

    unless table_exists?(table_name)
      puts "Custom tables plugin not installed - skipping migration"
      return
    end

    puts "Adding audit columns to #{table_name}"

    # Always add the columns - they'll only be used when enabled in settings
    unless column_exists?(table_name, :created_by)
      add_column table_name, :created_by, :integer
      add_index table_name, :created_by
      puts "✓ Added created_by column to #{table_name}"
    end

    unless column_exists?(table_name, :created_at)
      add_column table_name, :created_at, :datetime
      puts "✓ Added created_at column to #{table_name}"
    end
  end

  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  end

  def column_exists?(table_name, column_name)
    ActiveRecord::Base.connection.column_exists?(table_name, column_name)
  end
end