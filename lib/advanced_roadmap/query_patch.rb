# encoding: UTF-8


require_dependency 'query'

module AdvancedRoadmap
  module QueryPatch
    def self.included(base)
      base.class_eval do

        # Returns the milestones
        # Valid options are :conditions
        def milestones(options = {})
          Milestone
              .joins(:project)
              .includes(:project)
              .where(Query.merge_conditions(project_statement, options[:conditions]))
        rescue ::ActiveRecord::StatementInvalid => e
          raise StatementInvalid.new(e.message)
        end

        # Deprecated method from Rails 2.3.X.
        def self.merge_conditions(*conditions)
          segments = []
          conditions.each do |condition|
            unless condition.blank?
              sql = sanitize_sql(condition)
              segments << sql unless sql.blank?
            end
          end
          "(#{segments.join(') AND (')})" unless segments.empty?
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
