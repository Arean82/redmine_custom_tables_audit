class RedmineCustomTablesAudit::ApiController < ApplicationController
  accept_api_auth :log_change, :get_settings, :test_connection
  
  # API to log custom entity changes (for future external integrations)
  def log_change
    # Verify permissions
    require_admin_or_api_request
    
    custom_entity_id = params[:custom_entity_id]
    action = params[:action_type]
    notes = params[:notes]
    
    custom_entity = CustomEntity.find_by(id: custom_entity_id)
    
    if custom_entity
      case action
      when 'create'
        RedmineCustomTablesAudit::CoreObserver.after_create(custom_entity)
      when 'update'
        RedmineCustomTablesAudit::CoreObserver.after_update(custom_entity)
      when 'delete'
        RedmineCustomTablesAudit::CoreObserver.after_destroy(custom_entity)
      else
        render_api_error('Invalid action_type. Use: create, update, delete', 400)
        return
      end
      
      render_api_ok
    else
      render_api_error('Custom entity not found', 404)
    end
  end
  
  # API to get plugin settings
  def get_settings
    require_admin_or_api_request
    
    settings = Setting.plugin_redmine_custom_tables_audit || {}
    render json: { settings: settings }
  end
  
  # API to test connection
  def test_connection
    require_admin_or_api_request
    
    render json: { 
      status: 'ok', 
      plugin: 'Custom Tables Audit',
      version: '0.0.2',
      timestamp: Time.current.iso8601
    }
  end
  
  private
  
  def require_admin_or_api_request
    if api_request?
      true # API requests are already authenticated by Redmine
    else
      require_admin
    end
  end
  
  def render_api_ok
    render json: { status: 'ok' }
  end
  
  def render_api_error(message, status = 400)
    render json: { error: message }, status: status
  end
end