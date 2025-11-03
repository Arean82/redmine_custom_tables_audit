module RedmineCustomTablesAudit
  module CustomEntitiesControllerPatch
    def create
      # Store settings before original action
      settings = Setting.plugin_redmine_custom_tables_audit || {}
      
      # Call original create method
      result = super
      
      # Log creation if successful
      if response.successful? && @custom_entity && settings['enable_audit_logging'] == '1'
        log_custom_entity_action('created')
      end
      
      result
    end

    def update
      # Store settings before original action
      settings = Setting.plugin_redmine_custom_tables_audit || {}
      
      # Call original update method
      result = super
      
      # Log update if successful
      if response.successful? && @custom_entity && settings['enable_audit_logging'] == '1'
        log_custom_entity_action('updated')
      end
      
      result
    end

    def destroy
      # Store entity before destruction for logging
      settings = Setting.plugin_redmine_custom_tables_audit || {}
      entity_before_destroy = @custom_entity.dup if @custom_entity
      
      # Call original destroy method
      result = super
      
      # Log deletion if successful
      if response.successful? && entity_before_destroy && settings['enable_audit_logging'] == '1'
        @custom_entity = entity_before_destroy # Restore for logging
        log_custom_entity_action('deleted')
      end
      
      result
    end

    private

    def log_custom_entity_action(action)
      return unless @custom_entity
      
      issue = find_associated_issue(@custom_entity)
      return unless issue

      case action
      when 'created'
        message = "📝 New custom table record created: #{record_identifier(@custom_entity)}"
      when 'updated'
        message = "📋 Custom table record updated: #{record_identifier(@custom_entity)}"
      when 'deleted'
        message = "🗑️ Custom table record deleted: #{record_identifier(@custom_entity)}"
      end

      add_audit_journal(issue, message)
    end

    def find_associated_issue(custom_entity)
      # Try different ways to find the issue
      if custom_entity.respond_to?(:container) && custom_entity.container.is_a?(Issue)
        custom_entity.container
      elsif custom_entity.respond_to?(:issue) && custom_entity.issue.present?
        custom_entity.issue
      elsif custom_entity.respond_to?(:issue_id) && custom_entity.issue_id.present?
        Issue.find_by(id: custom_entity.issue_id)
      end
    end

    def add_audit_journal(issue, note)
      issue.init_journal(User.current, note)
      issue.save!
      Rails.logger.info "Custom Tables Audit: ✓ Added journal to issue ##{issue.id}"
    rescue => e
      Rails.logger.error "Custom Tables Audit: ✗ Failed to create journal - #{e.message}"
    end

    def record_identifier(custom_entity)
      if custom_entity.respond_to?(:name) && custom_entity.name.present?
        "##{custom_entity.id} (#{custom_entity.name})"
      elsif custom_entity.respond_to?(:to_s) && custom_entity.to_s.present? && custom_entity.to_s != custom_entity.class.name
        "##{custom_entity.id} (#{custom_entity.to_s})"
      else
        "##{custom_entity.id}"
      end
    end
  end
end