module CustomTablesRecordPatch
  extend ActiveSupport::Concern

  included do
    after_save :log_custom_table_changes
    after_destroy :log_custom_table_deletion
    before_create :set_audit_columns
  end

  private

  def set_audit_columns
    self.created_by = User.current.id if respond_to?(:created_by=)
    self.created_at = Time.current if respond_to?(:created_at=)
  end

  def log_custom_table_changes
    return unless audit_enabled?
    return unless respond_to?(:issue_id) && issue_id.present?
    
    issue = Issue.find_by(id: issue_id)
    return unless issue

    changes_text = previous_changes.except('created_at', 'updated_at', 'created_by').map do |attr, values|
      old_val, new_val = values
      "Changed #{attr}: #{old_val.inspect} → #{new_val.inspect}"
    end.join("\n")

    add_audit_journal(issue, changes_text) if changes_text.present?
  end

  def log_custom_table_deletion
    return unless audit_enabled?
    return unless respond_to?(:issue_id) && issue_id.present?

    issue = Issue.find_by(id: issue_id)
    return unless issue

    add_audit_journal(issue, "Deleted custom table record ##{id}")
  end

  def add_audit_journal(issue, note)
    begin
      issue.init_journal(User.current, note)
      issue.save!
    rescue => e
      Rails.logger.error "Failed to create audit journal: #{e.message}"
    end
  end

  def audit_enabled?
    settings = Setting.plugin_redmine_custom_tables_audit || {}
    settings['enable_audit_logging'] == '1'
  end
end