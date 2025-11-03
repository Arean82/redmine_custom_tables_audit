module RedmineCustomTablesAudit
  class SimpleAudit
    class << self
      def log_creation(custom_entity)
        return unless audit_enabled?
        
        issue = find_issue(custom_entity)
        return unless issue
        
        message = "📝 New custom table record created: #{record_identifier(custom_entity)}"
        add_journal(issue, message)
      end

      def log_update(custom_entity)
        return unless audit_enabled?
        
        issue = find_issue(custom_entity)
        return unless issue
        
        # Get field changes for more detailed logging
        changes = custom_entity.previous_changes.except('updated_at', 'created_at', 'id', 'created_by')
        
        if changes.any?
          changes_text = changes.map do |attr, (old_val, new_val)|
            "✏️ #{format_field_name(attr)}: #{format_value(old_val)} → #{format_value(new_val)}"
          end.join("\n")
          
          message = "📋 Custom table record updated: #{record_identifier(custom_entity)}\n#{changes_text}"
        else
          message = "📋 Custom table record updated: #{record_identifier(custom_entity)}"
        end
        
        add_journal(issue, message)
      end

      def log_deletion(custom_entity)
        return unless audit_enabled?
        
        issue = find_issue(custom_entity)
        return unless issue
        
        message = "🗑️ Custom table record deleted: #{record_identifier(custom_entity)}"
        add_journal(issue, message)
      end

      private

      def find_issue(custom_entity)
        # Try different ways to find the issue
        if custom_entity.respond_to?(:issue) && custom_entity.issue
          custom_entity.issue
        elsif custom_entity.respond_to?(:issue_id) && custom_entity.issue_id
          Issue.find_by(id: custom_entity.issue_id)
        elsif custom_entity.respond_to?(:container) && custom_entity.container.is_a?(Issue)
          custom_entity.container
        end
      end

      def add_journal(issue, note)
        # This will create a journal entry that appears in both notes and history
        issue.init_journal(User.current, note)
        
        # Force the journal to be visible in notes
        if issue.current_journal
          issue.current_journal.private_notes = false
        end
        
        if issue.save
          Rails.logger.info "Custom Tables Audit: ✓ Added journal to issue ##{issue.id}: #{note}"
        else
          Rails.logger.error "Custom Tables Audit: ✗ Failed to save issue: #{issue.errors.full_messages}"
        end
      rescue => e
        Rails.logger.error "Custom Tables Audit: ✗ Failed to add journal: #{e.message}"
      end

      def audit_enabled?
        settings = Setting.plugin_redmine_custom_tables_audit || {}
        settings['enable_audit_logging'] == '1'
      end

      def record_identifier(custom_entity)
        if custom_entity.respond_to?(:name) && custom_entity.name.present?
          "##{custom_entity.id} (#{custom_entity.name})"
        elsif custom_entity.respond_to?(:title) && custom_entity.title.present?
          "##{custom_entity.id} (#{custom_entity.title})"
        else
          "##{custom_entity.id}"
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
end