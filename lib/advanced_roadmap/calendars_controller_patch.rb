# encoding: UTF-8

module AdvancedRoadmap
  module CalendarsControllerPatch
    def self.included(base)
      base.class_eval do

        around_action :add_milestones, only: [:show]

        def add_milestones
          yield

          milestones = []
          if @query.respond_to?(:milestones) && @calendar
            @query.milestones.where('milestones.milestone_effective_date' =>
                                    @calendar.startdt..@calendar.enddt).each do |milestone|
              milestones << {
                name: milestone.name,
                url: url_for(controller: :milestones, action: :show, id: milestone.id),
                week: milestone.milestone_effective_date.cweek,
                day: milestone.milestone_effective_date.day
              }
            end
          end

          rendered_content = render_to_string(
            partial: 'hooks/calendars/milestones',
            locals: { milestones: milestones }
          )
          response.body = "#{response.body}#{rendered_content}"
        end

      end
    end
  end
end
