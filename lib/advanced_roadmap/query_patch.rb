# encoding: UTF-8

module AdvancedRoadmap
  module QueryPatch
    def self.included(base)
      base.class_eval do

        # Returns the milestones
        # Valid options are :conditions
        def milestones(options = {})
          scope = Milestone.joins(:project).includes(:project).where(project_statement)
          scope = scope.where(options[:conditions]) if options[:conditions].present?
          scope
        rescue ::ActiveRecord::StatementInvalid => e
          raise StatementInvalid.new(e.message)
        end

        alias_method :available_totalable_columns_without_advanced_roadmap, :available_totalable_columns
        def available_totalable_columns
          columns = available_totalable_columns_without_advanced_roadmap
          unless User.current.allowed_to?(:view_issue_estimated_hours, self.project)
            columns.delete_if {|column| column.name == :estimated_hours}
          end
          return columns
        end

      end
    end
  end
end
