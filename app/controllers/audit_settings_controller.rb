class AuditSettingsController < ApplicationController
  before_action :require_admin

  def index
    @settings = Setting.plugin_redmine_custom_tables_audit || {}
  end

  def update
    settings = params[:settings] || {}
    Setting.plugin_redmine_custom_tables_audit = settings
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'index'
  end
end
