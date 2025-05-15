# encoding: UTF-8

require_dependency 'calendars_controller'

module AdvancedRoadmap
  module CalendarsControllerPatch
    def self.included(base)
      base.class_eval do

        around_action :add_milestones, only: [:show]

        def add_milestones
          yield

          milestones = []
          @query.milestones.where('milestones.milestone_effective_date' =>
                                  @calendar.startdt..@calendar.enddt).each do |milestone|
            milestones << {
              name: milestone.name,
              url: url_for(controller: :milestones, action: :show, id: milestone.id),
              week: milestone.milestone_effective_date.cweek,
              day: milestone.milestone_effective_date.day
            }
          end

          plugin_views_path = File.expand_path('../../app/views', __dir__)
          lookup_context = ActionView::LookupContext.new([plugin_views_path])
          view = ActionView::Base.with_empty_template_cache.new(
            lookup_context,
            {}, # assigns
            self # controller
          )
          view.class_eval do
            include ApplicationHelper
            include Rails.application.routes.url_helpers
            include ActionView::Helpers
          end

          response.body += view.render(
            partial: 'hooks/calendars/milestones',
            locals: { milestones: milestones }
          )
        end

      end
    end
  end
end

