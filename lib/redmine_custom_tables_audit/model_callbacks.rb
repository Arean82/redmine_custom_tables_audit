module RedmineCustomTablesAudit
  module ModelCallbacks
    extend ActiveSupport::Concern

    included do
      after_create :log_creation_callback
      after_update :log_update_callback
      after_destroy :log_deletion_callback
    end

    private

    def log_creation_callback
      RedmineCustomTablesAudit::SimpleAudit.log_creation(self)
    end

    def log_update_callback
      RedmineCustomTablesAudit::SimpleAudit.log_update(self)
    end

    def log_deletion_callback
      RedmineCustomTablesAudit::SimpleAudit.log_deletion(self)
    end
  end
end