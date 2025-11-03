module RedmineCustomTablesAudit
  class IssueJournalHook < Redmine::Hook::ViewListener
    
    # This hook catches when journals are created on issues
    def controller_issues_edit_before_save(context = {})
      return unless audit_enabled?
      
      @issue = context[:issue]
      @params = context[:params]
      
      # Check if this request contains custom entity changes
      check_for_custom_entity_changes
    end

    private

    def check_for_custom_entity_changes
      return unless @issue && @params
      
      # Look for custom entity parameters in the request
      custom_entity_changes = detect_custom_entity_changes
      return if custom_entity_changes.empty?
      
      # Add custom entity changes to the journal notes
      add_custom_entity_notes(custom_entity_changes)
    end

    def detect_custom_entity_changes
      changes = []
      
      # Method 1: Check for custom_entity parameters
      if @params[:custom_entity].is_a?(Hash)
        @params[:custom_entity].each do |key, value|
          changes << "Custom field #{key}: #{value}"
        end
      end
      
      # Method 2: Check for custom field values that belong to custom tables
      if @params[:issue].is_a?(Hash) && @params[:issue][:custom_field_values].is_a?(Hash)
        @params[:issue][:custom_field_values].each do |field_id, value|
          # Check if this custom field belongs to a custom table
          custom_field = CustomField.find_by(id: field_id)
          if custom_field && custom_field.custom_table_id.present?
            changes << "Custom table field #{custom_field.name}: #{value}"
          end
        end
      end
      
      changes
    end

    def add_custom_entity_notes(changes)
      return if changes.empty?
      
      # Get existing notes or initialize
      current_notes = @issue.current_journal&.notes.to_s
      
      # Add custom entity changes
      custom_notes = "Custom Table Changes:\n" + changes.join("\n")
      
      # Combine with existing notes
      new_notes = current_notes.empty? ? custom_notes : "#{current_notes}\n#{custom_notes}"
      
      # Update the journal notes
      if @issue.current_journal
        @issue.current_journal.notes = new_notes
      else
        @issue.init_journal(User.current, new_notes)
      end
    end

    def audit_enabled?
      settings = Setting.plugin_redmine_custom_tables_audit || {}
      settings['enable_audit_logging'] == '1'
    end
  end
end