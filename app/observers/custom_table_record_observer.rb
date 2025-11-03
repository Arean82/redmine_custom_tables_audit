# app/observers/custom_table_record_observer.rb
class CustomTableRecordObserver < ActiveRecord::Observer
  observe CustomTables::Record

  def after_save(record)
    log_custom_table_change(record)
  end

  def after_destroy(record)
    log_custom_table_deletion(record)
  end

  private

  def log_custom_table_change(record)
    return unless record.respond_to?(:issue_id) && record.issue_id.present?

    issue = Issue.find_by(id: record.issue_id)
    return unless issue

    changes_text = record.previous_changes.map do |attr, values|
      old_val, new_val = values
      "Changed #{attr}: #{old_val.inspect} → #{new_val.inspect}"
    end.join("\n")

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
