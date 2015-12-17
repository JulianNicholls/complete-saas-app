# Controller for organisational prpjects
class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy]
  before_action :set_tenant, except: [:index]
  before_action :verify_tenant

  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.all
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
