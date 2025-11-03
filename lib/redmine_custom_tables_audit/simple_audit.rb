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
        
        message = "📋 Custom table record updated: #{record_identifier(custom_entity)}"
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
        issue.init_journal(User.current, note)
        issue.save!
        Rails.logger.info "Custom Tables Audit: ✓ Added journal: #{note}"
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
    end
  end
end