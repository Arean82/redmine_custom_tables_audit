class AuditSettingsController < ApplicationController
  layout 'admin'
  before_action :require_admin

  def index
    @settings = Setting.plugin_redmine_custom_tables_audit || {}
    render :layout => !request.xhr?
  end

  def update
    settings = params[:settings] || {}
    Setting.plugin_redmine_custom_tables_audit = settings
    flash[:notice] = l(:notice_successful_update)
    redirect_to settings_plugin_path('redmine_custom_tables_audit')
  end
end