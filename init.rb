# encoding: UTF-8

require_relative 'lib/advanced_roadmap/view_hooks'

Redmine::Plugin.register :advanced_roadmap do
  name 'Advanced roadmap & milestones plugin v4'
  url 'https://github.com/Arean82/advanced_roadmap'
  author 'Arean Narrayan'
  author_url 'https://github.com/Arean82/advanced_roadmap'
  description 'This is a plugin for Redmine that is used to show more information inside the Roadmap page and implements the milestones featuring.'
  version '4.0.0'
  permission :manage_milestones, {:milestones => [:new, :create, :edit, :update, :destroy]}
  requires_redmine :version_or_higher => '5.0.0'

  project_module :issue_tracking do
    permission :view_issue_estimated_hours, {}
  end

  settings :default => {'parallel_effort_custom_field' => '',
                        'solved_issues_to_estimate' => '5',
                        'ratio_good' => '0.8',
                        'color_good' => 'green',
                        'ratio_bad' => '1.2',
                        'color_bad' => 'orange',
                        'ratio_very_bad' => '1.5',
                        'color_very_bad' => 'red',
                        'milestone_label' => '',
                        'milestone_plural_label' => ''},
           :partial => 'settings/advanced_roadmap_settings'
end

Rails.configuration.to_prepare do
  ApplicationHelper.send(:include, AdvancedRoadmap::ApplicationHelperPatch) unless ApplicationHelper.included_modules.include?(AdvancedRoadmap::ApplicationHelperPatch)
  CalendarsController.send(:include, AdvancedRoadmap::CalendarsControllerPatch) unless CalendarsController.included_modules.include?(AdvancedRoadmap::CalendarsControllerPatch)
  Issue.send(:include, AdvancedRoadmap::IssuePatch) unless Issue.included_modules.include?(AdvancedRoadmap::IssuePatch)
  Journal.send(:include, AdvancedRoadmap::JournalPatch) unless Journal.included_modules.include?(AdvancedRoadmap::JournalPatch)
  Project.send(:include, AdvancedRoadmap::ProjectPatch) unless Project.included_modules.include?(AdvancedRoadmap::ProjectPatch)
  ProjectsHelper.send(:include, AdvancedRoadmap::ProjectsHelperPatch) unless ProjectsHelper.included_modules.include?(AdvancedRoadmap::ProjectsHelperPatch)
  Query.send(:include, AdvancedRoadmap::QueryPatch) unless Query.included_modules.include?(AdvancedRoadmap::QueryPatch)
  Redmine::Helpers::Gantt.send(:include, AdvancedRoadmap::RedmineHelpersGanttPatch) unless Redmine::Helpers::Gantt.included_modules.include?(AdvancedRoadmap::RedmineHelpersGanttPatch)
  Redmine::I18n.send(:include, AdvancedRoadmap::RedmineI18nPatch) unless Redmine::I18n.included_modules.include?(AdvancedRoadmap::RedmineI18nPatch)
  Version.send(:include, AdvancedRoadmap::VersionPatch) unless Version.included_modules.include?(AdvancedRoadmap::VersionPatch)
  VersionsController.send(:include, AdvancedRoadmap::VersionsControllerPatch) unless VersionsController.included_modules.include?(AdvancedRoadmap::VersionsControllerPatch)
end
