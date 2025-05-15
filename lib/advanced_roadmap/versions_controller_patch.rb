# encoding: UTF-8


require_dependency 'versions_controller'

module AdvancedRoadmap
  module VersionsControllerPatch
    def self.included(base)
      base.class_eval do

        alias_method :index_without_plugin, :index
        def index
          index_without_plugin
          @totals = Version.calculate_totals(@versions)
          Version.sort_versions(@versions)
        end

        def show
          @issues = @version.sorted_fixed_issues
        end
      
      end
    end
  end
end
