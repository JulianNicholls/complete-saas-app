# Controller for organisational prpjects
class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :users, :add_user]
  before_action :set_tenant, except: [:index]
  before_action :verify_tenant

  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.by_user_plan_and_tenant(params[:tenant_id], current_user)
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
  end

  # GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)
    @project.users << current_user

    if @project.save
      redirect_to root_url, notice: 'Project was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    if @project.update(project_params)
      redirect_to root_url, notice: 'Project was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to root_url, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def users
    @project_users = (@project.users + (User.where(tenant_id: @tenant.id, admin: true))) - [current_user]
    @other_users   = @tenant.users.where(admin: false) - (@project_users + [current_user])
  end

  def add_user
    @project_user = UserProject.new(user_id: params[:user_id], project_id: @project.id)

    respond_to do |format|
      if @project_user.save
        format.html { redirect_to users_tenant_project_url(id: @project.id, tenant_id: @project.tenant_id),
                                  notice: "The user was successfully added to the project" }
      else
        format.html { redirect_to users_tenant_project_url(id: @project.id, tenant_id: @project.tenant_id),
                                  error: "The user was not added to the project" }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

  # Never trust parameters from the internet, only allow the white listed
  def project_params
    params.require(:project).permit(:title, :details, :expected_completion_date, :tenant_id)
  end

  def set_tenant
    @tenant = Tenant.find params[:tenant_id]
  end

  def verify_tenant
    return if params[:tenant_id] == Tenant.current_tenant_id.to_s

    redirect_to :root,
                flash: { error: 'You are not allowed to view projects outside your organisation' }
  end
end
