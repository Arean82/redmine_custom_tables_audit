module CustomTablesAudit
  class Hooks < Redmine::Hook::ViewListener
    def controller_issues_edit_after_save(context = {})
      # This hook can be used for issue-related changes
    end
  end
end
