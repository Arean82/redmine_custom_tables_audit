module RedmineCustomTablesAudit
  class CustomEntitiesObserver
    class << self
      def log_creation(custom_entity)
        return unless audit_enabled?
        
        issue = find_issue_for_entity(custom_entity)
        return unless issue
        
        message = "📝 New custom table record created: #{record_identifier(custom_entity)}"
        add_journal_entry(issue, message)
      end

      def log_update(custom_entity)
        return unless audit_enabled?
        
        issue = find_issue_for_entity(custom_entity)
        return unless issue
        
        message = "📋 Custom table record updated: #{record_identifier(custom_entity)}"
        add_journal_entry(issue, message)
      end

      def log_deletion(custom_entity)
        return unless audit_enabled?
        
        issue = find_issue_for_entity(custom_entity)
        return unless issue
        
        message = "🗑️ Custom table record deleted: #{record_identifier(custom_entity)}"
        add_journal_entry(issue, message)
      end

      private

      def find_issue_for_entity(custom_entity)
        # Try all possible issue associations
        if custom_entity.respond_to?(:container) && custom_entity.container.is_a?(Issue)
          custom_entity.container
        elsif custom_entity.respond_to?(:issue) && custom_entity.issue.present?
          custom_entity.issue
        elsif custom_entity.respond_to?(:issue_id) && custom_entity.issue_id.present?
          Issue.find_by(id: custom_entity.issue_id)
        elsif custom_entity.custom_table_id.present?
          # Find issues that have this custom table
          custom_table = CustomTable.find_by(id: custom_entity.custom_table_id)
          custom_table&.issues&.first if custom_table&.respond_to?(:issues)
        end
      end

      def add_journal_entry(issue, note)
        # Create a new journal entry
        journal = issue.init_journal(User.current, note)
        if issue.save
          Rails.logger.info "Custom Tables Audit: ✓ Journal added to issue ##{issue.id}"
          return true
        else
          Rails.logger.error "Custom Tables Audit: ✗ Failed to save journal: #{issue.errors.full_messages}"
          return false
        end
      rescue => e
        Rails.logger.error "Custom Tables Audit: ✗ Error: #{e.message}"
        false
      end

      def audit_enabled?
        settings = Setting.plugin_redmine_custom_tables_audit || {}
        settings['enable_audit_logging'] == '1'
      end

      def record_identifier(custom_entity)
        if custom_entity.respond_to?(:name) && custom_entity.name.present?
          "##{custom_entity.id} (#{custom_entity.name})"
        elsif custom_entity.respond_to?(:subject) && custom_entity.subject.present?
          "##{custom_entity.id} (#{custom_entity.subject})"
        else
          "##{custom_entity.id}"
        end
      end
    end
  end
end