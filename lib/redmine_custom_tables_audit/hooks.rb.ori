module RedmineCustomTablesAudit
  class Hooks < Redmine::Hook::ViewListener
    
    # Hook into custom entities controller actions
    def controller_custom_entities_edit_after_save(context = {})
      log_custom_entity_change(context[:custom_entity], 'updated')
    end

    def controller_custom_entities_new_after_save(context = {})
      log_custom_entity_change(context[:custom_entity], 'created')
    end

    def controller_custom_entities_destroy_after_save(context = {})
      log_custom_entity_change(context[:custom_entity], 'deleted')
    end

    # Also hook into issues since custom tables are often issue-related
    def controller_issues_edit_after_save(context = {})
      return unless audit_enabled?
      
      issue = context[:issue]
      return unless issue
      
      # Check for custom entity changes in the request
      check_for_custom_entity_changes(issue, context[:params])
    end

    private

    def log_custom_entity_change(custom_entity, action)
      return unless custom_entity
      return unless audit_enabled?

      Rails.logger.info "🔧 Custom Tables Audit: #{action} custom_entity ##{custom_entity.id}"

      issue = find_associated_issue(custom_entity)
      unless issue
        Rails.logger.warn "Custom Tables Audit: No issue found for custom_entity ##{custom_entity.id}"
        return
      end

      case action
      when 'created'
        message = "📝 New custom table record created: #{record_identifier(custom_entity)}"
      when 'updated'  
        message = "📋 Custom table record updated: #{record_identifier(custom_entity)}"
      when 'deleted'
        message = "🗑️ Custom table record deleted: #{record_identifier(custom_entity)}"
      end

      add_audit_journal(issue, message)
    end

    def check_for_custom_entity_changes(issue, params)
      return unless params
      
      # Look for custom entity parameters in the issue update
      if params[:custom_entity] || params[:custom_entities]
        Rails.logger.info "Custom Tables Audit: Detected custom entity changes in issue ##{issue.id}"
        
        # Add a generic note about custom table changes
        unless issue.current_journal&.notes&.include?('custom table')
          add_audit_journal(issue, "📋 Custom table records modified")
        end
      end
    end

    def find_associated_issue(custom_entity)
      # Try multiple common association patterns
      if custom_entity.respond_to?(:issue_id) && custom_entity.issue_id.present?
        Issue.find_by(id: custom_entity.issue_id)
      elsif custom_entity.respond_to?(:issue) && custom_entity.issue.present?
        custom_entity.issue
      elsif custom_entity.respond_to?(:container_id) && custom_entity.container_id.present?
        Issue.find_by(id: custom_entity.container_id)
      elsif custom_entity.respond_to?(:custom_table) && custom_entity.custom_table.present?
        # Try to find through custom table associations
        custom_table = custom_entity.custom_table
        if custom_table.respond_to?(:issues) && custom_table.issues.any?
          custom_table.issues.first
        end
      end
    end

    def add_audit_journal(issue, note)
      begin
        # Use the existing journal if available (from issue update), otherwise create new one
        if issue.current_journal
          # Append to existing journal notes
          new_notes = issue.current_journal.notes.to_s
          new_notes += "\n" unless new_notes.empty?
          new_notes += note
          issue.current_journal.update(notes: new_notes)
        else
          # Create new journal entry
          issue.init_journal(User.current, note)
          issue.save
        end
        
        Rails.logger.info "Custom Tables Audit: ✓ Journal added to issue ##{issue.id}: #{note}"
      rescue => e
        Rails.logger.error "Custom Tables Audit: ✗ Failed to add journal - #{e.message}"
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
  end
end