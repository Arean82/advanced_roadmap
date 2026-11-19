# encoding: UTF-8

require 'csv'

class MilestonesController < ApplicationController
  
  menu_item :roadmap
  self.model_object = Milestone

  before_action :find_model_object,
                :only => [:show, :edit, :update, :destroy]
  before_action :find_project_from_association,
                :only => [:show, :edit, :update, :destroy]
  before_action :find_project_by_project_id,
                :only => [:new, :create, :index]
  before_action :authorize, :except => [:show, :total_graph, :index]

  helper :custom_fields
  helper :projects
  helper :versions
  include CustomFieldsHelper
  include ProjectsHelper
  include VersionsHelper

  def index
    @milestones = @project ? @project.milestones.sort : Milestone.all.sort

    respond_to do |format|
      format.html { redirect_to project_path(@project, :tab => 'settings') if @project }
      format.json do
        render :json => {
          :milestones => @milestones.map do |m|
            totals = Version.calculate_totals(m.versions)
            {
              :id => m.id,
              :name => m.name,
              :description => m.description,
              :project_id => m.project_id,
              :milestone_effective_date => m.milestone_effective_date,
              :completed => m.completed?,
              :overdue => m.overdue?,
              :at_risk => m.at_risk?(totals),
              :versions_count => m.versions.count,
              :totals => {
                :estimated_hours => totals[:estimated_hours],
                :spent_hours => totals[:spent_hours],
                :rest_hours => totals[:rest_hours],
                :parallel_rest_hours => totals[:parallel_rest_hours],
                :completed_pourcent => totals[:completed_pourcent]
              }
            }
          end
        }
      end
    end
  end

  def show
    projects = {}
    @milestone.versions.each do |version|
      version.fixed_issues.each do |issue|
        if !(projects.include?(issue.project.id))
          projects[issue.project.id] = issue.project.id
        end
      end
    end
    Version.sort_versions(@milestone.versions)
    @more_than_one_project = (projects.length > 1)
    @totals = Version.calculate_totals(@milestone.versions)

    respond_to do |format|
      format.html
      format.json do
        render :json => {
          :milestone => {
            :id => @milestone.id,
            :name => @milestone.name,
            :description => @milestone.description,
            :milestone_effective_date => @milestone.milestone_effective_date,
            :completed => @milestone.completed?,
            :overdue => @milestone.overdue?,
            :at_risk => @milestone.at_risk?(@totals),
            :totals => @totals,
            :versions => @milestone.versions.map do |v|
              {
                :id => v.id,
                :name => v.name,
                :status => v.status,
                :effective_date => v.effective_date,
                :completed_percent => v.completed_percent,
                :closed_percent => v.closed_percent,
                :estimated_hours => v.estimated_hours,
                :spent_hours => v.spent_hours,
                :rest_hours => v.rest_hours
              }
            end
          }
        }
      end
      format.csv do
        csv_data = generate_milestone_csv(@milestone, @totals)
        send_data csv_data, :type => 'text/csv; header=present', :filename => "milestone-#{@milestone.id}-#{Date.today}.csv"
      end
    end
  end

  def new
    @projects = Project.active.sort { |a, b| a.name.downcase <=> b.name.downcase }
    @versions = @project.versions
    @milestone = Milestone.new
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create
    @milestone = Milestone.new(:user_id => User.current.id, :project_id => @project.id)
    @milestone.safe_attributes = params[:milestone]
    if request.post? and @milestone.save
      if params[:versions]
        params[:versions].each do |version|
          milestone_version = MilestoneVersion.new
          milestone_version.milestone_id = @milestone.id
          milestone_version.version_id = version
          milestone_version.save
        end
       end
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => :projects, :action => :settings, :tab => 'milestones', :id => @project
    end
  rescue ActiveRecord::RecordNotFound => e
    render_404
  end

  def edit
    @projects = Project.active.sort { |a, b| a.name.downcase <=> b.name.downcase }
    @versions = @project.versions
  end

  def update
    @projects = Project.all.sort { |a, b| a.name.downcase <=> b.name.downcase }
    @versions = @project.versions
    versions_to_delete = @milestone.versions
    versions_to_add = []
    if params[:versions]
      params[:versions].each do |version|
        index = @milestone.versions.index(version)
        if index != nil
          versions_to_delete.remove(index)
        else
          versions_to_add << version
        end
      end
    end
    @milestone.safe_attributes = params[:milestone]
    versions_to_delete.each do |version|
      milestone_version = MilestoneVersion.where(:milestone_id => @milestone.id, :version_id => version.id).first
      milestone_version.destroy
    end
    versions_to_add.each do |version|
      milestone_version = MilestoneVersion.new
      milestone_version.milestone_id = @milestone.id
      milestone_version.version_id = version
      milestone_version.save
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to :controller => :projects, :action => :settings, :tab => 'milestones', :id => @project
  end

  def destroy
    @milestone.destroy
    redirect_to :controller => :projects, :action => :settings, :tab => 'milestones', :id => @project
  rescue
    flash[:error] = l(:notice_unable_delete_milestone, :milestone_label => milestone_label)
    redirect_to :controller => :projects, :action => :settings, :tab => 'milestones', :id => @project
  end

  def total_graph
    # Fallback to redirect or 204
    head :no_content
  end

private

  def generate_milestone_csv(milestone, totals)
    CSV.generate(headers: true) do |csv|
      csv << ['Milestone', milestone.name]
      csv << ['Project', milestone.project.name]
      csv << ['Due Date', milestone.milestone_effective_date]
      csv << ['Status', milestone.completed? ? 'Closed' : (milestone.overdue? ? 'Overdue' : 'Open')]
      csv << ['Completion %', "#{totals[:completed_pourcent]}%"]
      csv << ['Total Estimated Hours', totals[:estimated_hours]]
      csv << ['Total Spent Hours', totals[:spent_hours]]
      csv << ['Total Remaining Hours', totals[:rest_hours]]
      csv << ['Parallel Remaining Hours', totals[:parallel_rest_hours]]
      csv << []
      csv << ['Version', 'Status', 'Effective Date', 'Completion %', 'Estimated Hours', 'Spent Hours', 'Remaining Hours']
      milestone.versions.each do |v|
        csv << [
          v.name,
          v.status,
          v.effective_date,
          "#{v.completed_percent}%",
          v.estimated_hours,
          v.spent_hours,
          v.rest_hours
        ]
      end
    end
  end

end
