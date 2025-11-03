module RedmineCustomTablesAudit
  module RecordPatch
    extend ActiveSupport::Concern

    included do
      after_save :log_custom_table_changes
      after_destroy :log_custom_table_deletion
      before_create :set_audit_columns
    end

    private

    def set_audit_columns
      settings = Setting.plugin_redmine_custom_tables_audit || {}
      
      if settings['enable_created_by'] == '1' && respond_to?(:created_by=)
        self.created_by = User.current.id
      end
      
      if settings['enable_created_at'] == '1' && respond_to?(:created_at=)
        self.created_at = Time.current
      end
    end

    def log_custom_table_changes
      return unless audit_enabled?
      
      issue = find_associated_issue
      return unless issue

      if previous_changes['id'] # New record
        log_record_creation(issue)
      else # Updated record
        log_record_update(issue)
      end
    end

    def log_custom_table_deletion
      return unless audit_enabled?

      issue = find_associated_issue
      return unless issue

      add_audit_journal(issue, "🗑️ Deleted custom table record: #{record_identifier}")
    end

    def find_associated_issue
      # Try multiple association patterns used by custom_tables plugin
      if respond_to?(:issue_id) && issue_id.present?
        Issue.find_by(id: issue_id)
      elsif respond_to?(:issue) && issue.present?
        issue
      elsif respond_to?(:container_id) && container_id.present?
        Issue.find_by(id: container_id)
      elsif respond_to?(:custom_table) && custom_table.present?
        # Try to find through custom table associations
        custom_table.issues.first if custom_table.respond_to?(:issues)
      else
        Rails.logger.warn "Custom Tables Audit: Could not find associated issue for record #{id}"
        nil
      end
    end

    def log_record_creation(issue)
      field_changes = previous_changes.except('id', 'created_at', 'updated_at', 'created_by')
      
      if field_changes.any?
        changes_text = field_changes.map do |attr, values|
          old_val, new_val = values
          "➕ #{format_field_name(attr)}: #{format_value(new_val)}"
        end.join("\n")
        
        add_audit_journal(issue, "📝 New custom table record created:\n#{changes_text}")
      else
        add_audit_journal(issue, "📝 New custom table record created: #{record_identifier}")
      end
    end

    def log_record_update(issue)
      field_changes = previous_changes.except('created_at', 'updated_at', 'created_by')
      
      return if field_changes.empty?

      changes_text = field_changes.map do |attr, values|
        old_val, new_val = values
        "✏️ #{format_field_name(attr)}: #{format_value(old_val)} → #{format_value(new_val)}"
      end.join("\n")

      add_audit_journal(issue, "📋 Custom table record updated: #{record_identifier}\n#{changes_text}")
    end

    def add_audit_journal(issue, note)
      begin
        issue.init_journal(User.current, note)
        issue.save!
        Rails.logger.info "Custom Tables Audit: Added journal to issue #{issue.id}: #{note}"
      rescue => e
        Rails.logger.error "Custom Tables Audit: Failed to create journal - #{e.message}"
      end
    end

    def audit_enabled?
      settings = Setting.plugin_redmine_custom_tables_audit || {}
      settings['enable_audit_logging'] == '1'
    end

    def record_identifier
      # Try to use a meaningful identifier, fall back to ID
      if respond_to?(:name) && name.present?
        "##{id} (#{name})"
      elsif respond_to?(:title) && title.present?
        "##{id} (#{title})"
      else
        "##{id}"
      end
    end

    def format_field_name(attr)
      attr.humanize.titleize
    end

    def format_value(value)
      if value.blank?
        '[empty]'
      elsif value.is_a?(Time) || value.is_a?(Date)
        value.strftime('%Y-%m-%d %H:%M')
      else
        value.to_s.truncate(100)
      end
    end
  end
end