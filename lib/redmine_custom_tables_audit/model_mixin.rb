module RedmineCustomTablesAudit
  module ModelMixin
    extend ActiveSupport::Concern

    included do
      after_create :notify_audit_creation
      after_update :notify_audit_update
      after_destroy :notify_audit_deletion
    end

    private

    def notify_audit_creation
      RedmineCustomTablesAudit::CoreObserver.after_create(self)
    end

    def notify_audit_update
      RedmineCustomTablesAudit::CoreObserver.after_update(self)
    end

    def notify_audit_deletion
      RedmineCustomTablesAudit::CoreObserver.after_destroy(self)
    end
  end
end