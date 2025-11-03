module RedmineCustomTablesAudit
  class CoreObserver
    class << self
      # Called when custom entity is created
      def after_create(custom_entity)
        return unless audit_logging_enabled?
        
        issue = find_associated_issue(custom_entity)
        return unless issue
        
        message = "📝 Custom table record created: #{record_identifier(custom_entity)}"
        create_journal_entry(issue, message)
        
        # Set audit columns if enabled
        set_audit_columns(custom_entity) if custom_entity.persisted?
      end

      # Called when custom entity is updated
      def after_update(custom_entity)
        return unless audit_logging_enabled?
        
        issue = find_associated_issue(custom_entity)
        return unless issue
        
        # Get meaningful changes (exclude system fields)
        changes = custom_entity.previous_changes.except(
          'updated_at', 'created_at', 'id', 'created_by', 'lock_version'
        )
        
        if changes.any?
          changes_text = changes.map do |attr, (old_val, new_val)|
            "✏️ #{format_field_name(attr)}: #{format_value(old_val)} → #{format_value(new_val)}"
          end.join("\n")
          
          message = "📋 Custom table record updated: #{record_identifier(custom_entity)}\n#{changes_text}"
        else
          message = "📋 Custom table record updated: #{record_identifier(custom_entity)}"
        end
        
        create_journal_entry(issue, message)
      end

      # Called when custom entity is destroyed
      def after_destroy(custom_entity)
        return unless audit_logging_enabled?
        
        issue = find_associated_issue(custom_entity)
        return unless issue
        
        message = "🗑️ Custom table record deleted: #{record_identifier(custom_entity)}"
        create_journal_entry(issue, message)
      end

      private

      def find_associated_issue(custom_entity)
        # Try all possible issue associations used by custom_tables plugin
        if custom_entity.respond_to?(:container) && custom_entity.container.is_a?(Issue)
          custom_entity.container
        elsif custom_entity.respond_to?(:issue) && custom_entity.issue.present?
          custom_entity.issue
        elsif custom_entity.respond_to?(:issue_id) && custom_entity.issue_id.present?
          Issue.find_by(id: custom_entity.issue_id)
        elsif custom_entity.respond_to?(:custom_table) && custom_entity.custom_table.present?
          # Try to find through custom table associations
          custom_table = custom_entity.custom_table
          if custom_table.respond_to?(:issues) && custom_table.issues.any?
            custom_table.issues.first
          end
        end
      end

      def create_journal_entry(issue, notes)
        # Use Redmine's built-in journal system
        journal = issue.init_journal(User.current, notes)
        if issue.save
          Rails.logger.info "🔧 Custom Tables Audit: Journal added to issue ##{issue.id}"
          true
        else
          Rails.logger.error "🔧 Custom Tables Audit: Failed to save journal for issue ##{issue.id}"
          false
        end
      rescue => e
        Rails.logger.error "🔧 Custom Tables Audit: Error creating journal: #{e.message}"
        false
      end

      def set_audit_columns(custom_entity)
        settings = Setting.plugin_redmine_custom_tables_audit || {}
        
        if settings['enable_created_by'] == '1' && custom_entity.respond_to?(:created_by=)
          custom_entity.update_column(:created_by, User.current.id) rescue nil
        end
        
        if settings['enable_created_at'] == '1' && custom_entity.respond_to?(:created_at=)
          custom_entity.update_column(:created_at, Time.current) rescue nil
        end
      end

      def audit_logging_enabled?
        settings = Setting.plugin_redmine_custom_tables_audit || {}
        settings['enable_audit_logging'] == '1'
      end

      def record_identifier(custom_entity)
        if custom_entity.respond_to?(:name) && custom_entity.name.present?
          "##{custom_entity.id} (#{custom_entity.name})"
        elsif custom_entity.respond_to?(:subject) && custom_entity.subject.present?
          "##{custom_entity.id} (#{custom_entity.subject})"
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
        case value
        when nil then '[empty]'
        when '' then '[empty]'
        when Time, Date then value.strftime('%Y-%m-%d %H:%M')
        else value.to_s.truncate(50)
        end
      end
    end
  end
end