class CustomTableRecordObserver < ActiveRecord::Observer
  observe CustomTables::Record

  def before_create(record)
    record.created_by = User.current.id if record.respond_to?(:created_by)
    record.created_at = Time.current if record.respond_to?(:created_at)
  end

  def after_save(record)
    return unless plugin_enabled?(:enable_audit_logging)
    log_custom_table_change(record)
  end

  def after_destroy(record)
    return unless plugin_enabled?(:enable_audit_logging)
    log_custom_table_deletion(record)
  end

  private

  def plugin_enabled?(key)
    settings = Setting.plugin_redmine_custom_tables_audit || {}
    settings[key.to_s] == '1'
  end

  def log_custom_table_change(record)
    return unless record.respond_to?(:issue_id) && record.issue_id.present?
    issue = Issue.find_by(id: record.issue_id)
    return unless issue

    changes_text = record.previous_changes.map do |attr, values|
      next if %w[created_at updated_at].include?(attr)
      old_val, new_val = values
      "Changed #{attr}: #{old_val.inspect} → #{new_val.inspect}"
    end.compact.join("\n")

    add_audit_journal(issue, changes_text) if changes_text.present?
  end

  def log_custom_table_deletion(record)
    return unless record.respond_to?(:issue_id) && record.issue_id.present?
    issue = Issue.find_by(id: record.issue_id)
    return unless issue

    add_audit_journal(issue, "Deleted custom table record ##{record.id}")
  end

  def add_audit_journal(issue, note)
    issue.init_journal(User.current, note)
    issue.save!
  end
end
