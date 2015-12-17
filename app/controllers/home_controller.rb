# Controller for the home page
class HomeController < ApplicationController
  skip_before_action :authenticate_tenant!, only: [:index]

  def index
    return unless current_user

    set_current_tenant

    @tenant   = Tenant.current_tenant
    @projects = Project.by_plan_and_tenant(@tenant.id)

    params[:tenant_id] = @tenant.id
  end

  private

  def set_current_tenant
    if session[:tenant_id]
      Tenant.set_current_tenant session[:tenant_id]
    else
      Tenant.set_current_tenant current_user.tenants.first
    end
  end
end
