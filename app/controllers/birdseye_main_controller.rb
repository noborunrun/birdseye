class BirdseyeMainController < ApplicationController
layout 'base'
  before_filter :find_project, :authorize

  cache_sweeper :version_sweeper, :only => [ :edit, :destroy ]
  
   def index
    list
    render :action => 'list' unless request.xhr?
  end

  # Lists visible projects
  def list
    projects = Project.find :all,
                            :conditions => Project.visible_by(User.current),
                            :include => :parent
    @project_tree = projects.group_by {|p| p.parent || p}
    @project_tree.each_key {|p| @project_tree[p] -= [p]}
  end
  
  # Show @project
  def show
    @custom_values = @project.custom_values.find(:all, :include => :custom_field, :order => "#{CustomField.table_name}.position")
    @members_by_role = @project.members.find(:all, :include => [:user, :role], :order => 'position').group_by {|m| m.role}
    @subprojects = @project.active_children
    @news = @project.news.find(:all, :limit => 5, :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
    @trackers = @project.trackers
    @open_issues_by_tracker = Issue.count(:group => :tracker, :joins => "INNER JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id", :conditions => ["project_id=? and #{IssueStatus.table_name}.is_closed=?", @project.id, false])
    @total_issues_by_tracker = Issue.count(:group => :tracker, :conditions => ["project_id=?", @project.id])
    @total_hours = @project.time_entries.sum(:hours)
    @key = User.current.rss_key
  end

  def settings
    @root_projects = Project.find(:all,
                                  :conditions => ["parent_id IS NULL AND status = #{Project::STATUS_ACTIVE} AND id <> ?", @project.id],
                                  :order => 'name')
    @custom_fields = IssueCustomField.find(:all)
    @issue_category ||= IssueCategory.new
    @member ||= @project.members.new
    @trackers = Tracker.all
    @custom_values ||= ProjectCustomField.find(:all, :order => "#{CustomField.table_name}.position").collect { |x| @project.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x) }
    @repository ||= @project.repository
    @wiki ||= @project.wiki
  end
  
def roadmap
    @trackers = @project.trackers.find(:all, :conditions => ["is_in_roadmap=?", true])
    retrieve_selected_tracker_ids(@trackers)
    @versions = @project.versions.sort
    @versions = @versions.select {|v| !v.completed? } unless params[:completed]
  end

private
  def find_project
    @version = Version.find(params[:id])
    @project = @version.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end  
end