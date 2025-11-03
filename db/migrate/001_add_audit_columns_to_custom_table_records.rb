class AddAuditColumnsToCustomTableRecords < ActiveRecord::Migration[6.1]
  def up
    # Use the correct table name
    table_name = :custom_entities

    unless table_exists?(table_name)
      puts "Custom tables plugin not installed - skipping migration"
      return
    end

    puts "Adding audit columns to #{table_name}"

    unless column_exists?(table_name, :created_by)
      add_column table_name, :created_by, :integer
      puts "✓ Added created_by column to #{table_name}"
    end

    unless column_exists?(table_name, :created_at)
      add_column table_name, :created_at, :datetime
      puts "✓ Added created_at column to #{table_name}"
    end

    # Add index only if it doesn't exist
    if column_exists?(table_name, :created_by) && !index_exists?(table_name, :created_by)
      add_index table_name, :created_by
      puts "✓ Added index on created_by"
    end
  end

  def down
    table_name = :custom_entities

    return unless table_exists?(table_name)

    # Remove index if it exists
    if index_exists?(table_name, :created_by)
      remove_index table_name, :created_by
    end

    # Remove columns if they exist
    if column_exists?(table_name, :created_by)
      remove_column table_name, :created_by
    end

    if column_exists?(table_name, :created_at)
      remove_column table_name, :created_at
    end
  end

  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  end

  def column_exists?(table_name, column_name)
    ActiveRecord::Base.connection.column_exists?(table_name, column_name)
  end

  def index_exists?(table_name, column_name)
    ActiveRecord::Base.connection.index_exists?(table_name, column_name)
  end
end