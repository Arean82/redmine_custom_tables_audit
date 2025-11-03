module RedmineCustomTablesAudit
  module CustomEntityPatch
    extend ActiveSupport::Concern

    included do
      before_create :set_audit_columns
      after_create :log_creation
      after_update :log_update  
      after_destroy :log_deletion
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

    def log_creation
      return unless audit_enabled?
      
      issue = find_associated_issue
      return unless issue

      message = "📝 New custom table record created: #{record_identifier}"
      add_audit_journal(issue, message)
    end

    def log_update
      return unless audit_enabled?
      
      issue = find_associated_issue
      return unless issue

      changes = previous_changes.except('updated_at', 'created_at', 'id', 'created_by')
      
      if changes.any?
        changes_text = changes.map do |attr, (old_val, new_val)|
          "✏️ #{format_field_name(attr)}: #{format_value(old_val)} → #{format_value(new_val)}"
        end.join("\n")
        
        message = "📋 Custom table record updated: #{record_identifier}\n#{changes_text}"
      else
        message = "📋 Custom table record updated: #{record_identifier}"
      end
      
      add_audit_journal(issue, message)
    end

    def log_deletion
      return unless audit_enabled?
      
      issue = find_associated_issue
      return unless issue

      message = "🗑️ Custom table record deleted: #{record_identifier}"
      add_audit_journal(issue, message)
    end

    def find_associated_issue
      # Based on custom_tables plugin structure
      if respond_to?(:container) && container.is_a?(Issue)
        container
      elsif respond_to?(:issue) && issue.present?
        issue
      elsif respond_to?(:issue_id) && issue_id.present?
        Issue.find_by(id: issue_id)
      end
    end

    def add_audit_journal(issue, note)
      begin
        issue.init_journal(User.current, note)
        issue.save!
        Rails.logger.info "Custom Tables Audit: ✓ Added journal to issue ##{issue.id}"
      rescue => e
        Rails.logger.error "Custom Tables Audit: ✗ Failed to create journal - #{e.message}"
      end
    end

    def audit_enabled?
      settings = Setting.plugin_redmine_custom_tables_audit || {}
      settings['enable_audit_logging'] == '1'
    end

    def record_identifier
      if respond_to?(:name) && name.present?
        "##{id} (#{name})"
      elsif respond_to?(:to_s) && to_s.present? && to_s != self.class.name
        "##{id} (#{to_s})"
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