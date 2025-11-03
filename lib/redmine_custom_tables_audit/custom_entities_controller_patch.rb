module RedmineCustomTablesAudit
  module CustomEntitiesControllerPatch
    extend ActiveSupport::Concern

    included do
      around_action :wrap_with_audit_logging, only: [:create, :update, :destroy]
    end

    private

    def wrap_with_audit_logging
      # Store entity before action for destroy
      @entity_before_action = @custom_entity&.dup if action_name == 'destroy'
      
      yield # Execute the original action
      
      # Log the action after it completes successfully
      log_custom_entity_action if response.successful?
    end

    def log_custom_entity_action
      return unless audit_enabled?
      return unless @custom_entity

      issue = find_associated_issue(@custom_entity)
      return unless issue

      case action_name
      when 'create'
        log_record_creation(issue, @custom_entity)
      when 'update'
        log_record_update(issue, @custom_entity)
      when 'destroy'
        log_record_deletion(issue, @entity_before_action || @custom_entity)
      end
    end

    def log_record_creation(issue, custom_entity)
      message = "📝 New custom table record created: #{record_identifier(custom_entity)}"
      add_audit_journal(issue, message)
    end

    def log_record_update(issue, custom_entity)
      # Get changes from the entity
      changes = custom_entity.previous_changes.except('updated_at', 'created_at', 'id')
      
      if changes.any?
        changes_text = changes.map do |attr, (old_val, new_val)|
          "✏️ #{format_field_name(attr)}: #{format_value(old_val)} → #{format_value(new_val)}"
        end.join("\n")
        
        message = "📋 Custom table record updated: #{record_identifier(custom_entity)}\n#{changes_text}"
      else
        message = "📋 Custom table record updated: #{record_identifier(custom_entity)}"
      end
      
      add_audit_journal(issue, message)
    end

    def log_record_deletion(issue, custom_entity)
      message = "🗑️ Custom table record deleted: #{record_identifier(custom_entity)}"
      add_audit_journal(issue, message)
    end

    def find_associated_issue(custom_entity)
      # Try multiple association patterns
      if custom_entity.respond_to?(:issue) && custom_entity.issue.present?
        custom_entity.issue
      elsif custom_entity.respond_to?(:issue_id) && custom_entity.issue_id.present?
        Issue.find_by(id: custom_entity.issue_id)
      elsif custom_entity.respond_to?(:container) && custom_entity.container.is_a?(Issue)
        custom_entity.container
      elsif custom_entity.respond_to?(:container_id) && custom_entity.container_id.present?
        Issue.find_by(id: custom_entity.container_id)
      end
    end

    def add_audit_journal(issue, note)
      begin
        issue.init_journal(User.current, note)
        issue.save!
        Rails.logger.info "Custom Tables Audit: ✓ Added journal to issue #{issue.id}"
      rescue => e
        Rails.logger.error "Custom Tables Audit: ✗ Failed to create journal - #{e.message}"
      end
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