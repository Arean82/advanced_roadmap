# encoding: UTF-8

module AdvancedRoadmap
  module ApplicationHelperPatch
    def self.included(base)
      base.class_eval do

        def url_for_milestone(milestone_id)
          url_for(:controller => :milestones, :action => :show, :id => milestone_id)
        end

        def link_to_milestone(milestone)
          link_to(milestone.name, {:controller => :milestones, :action => :show, :id => milestone.id})
        end

        def color_by_ratio(ratio)
          color = ''
          color = AdvancedRoadmap::Setting.color_good if ratio <= AdvancedRoadmap::Setting.ratio_good
          color = AdvancedRoadmap::Setting.color_bad if ratio >= AdvancedRoadmap::Setting.ratio_bad
          color = AdvancedRoadmap::Setting.color_very_bad if ratio >= AdvancedRoadmap::Setting.ratio_very_bad
          color
        end

        def total_graph_tag(versions, totals, options = {})
          return '' if versions.blank? || totals.blank?

          total_effort = (totals[:spent_hours].to_f + totals[:rest_hours].to_f)
          return '' if total_effort <= 0

          # Modern client-side SVG Donut Chart
          palette = ['#4A90E2', '#50E3C2', '#F5A623', '#E94E77', '#B8E986', '#9013FE', '#417505', '#D0021B', '#F8E71C', '#4A4A4A']
          slices = []
          cumulative_percent = 0.0

          versions.each_with_index do |v, idx|
            effort = (v.spent_hours.to_f + v.rest_hours.to_f)
            pct = ((effort * 100.0) / total_effort).round(1)
            next if pct <= 0
            color = palette[idx % palette.size]
            slices << { name: v.name, percent: pct, color: color, hours: effort.round(1) }
          end

          # Render SVG Donut
          svg_parts = []
          radius = 35.0
          circumference = 2.0 * Math::PI * radius
          running_dash = 0.0

          slices.each do |s|
            dash_length = (s[:percent] / 100.0) * circumference
            dash_offset = -running_dash
            running_dash += dash_length
            svg_parts << %Q{
              <circle cx="50" cy="50" r="#{radius}" fill="transparent" stroke="#{s[:color]}" stroke-width="16"
                      stroke-dasharray="#{dash_length.round(2)} #{circumference.round(2)}" stroke-dashoffset="#{dash_offset.round(2)}">
                <title>#{ERB::Util.html_escape(s[:name])}: #{s[:hours]}h (#{s[:percent]}%)</title>
              </circle>
            }
          end

          legend_items = slices.map do |s|
            %Q{
              <div style="display:flex;align-items:center;margin-bottom:3px;font-size:11px;">
                <span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#{s[:color]};margin-right:5px;flex-shrink:0;"></span>
                <span style="max-width:130px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;" title="#{ERB::Util.html_escape(s[:name])}">#{ERB::Util.html_escape(s[:name])}</span>
                <span style="margin-left:auto;color:#666;padding-left:6px;font-weight:600;">#{s[:percent]}%</span>
              </div>
            }
          end.join

          html = %Q{
            <div class="advanced-roadmap-chart-card" style="display:inline-flex;align-items:center;background:#fafafa;border:1px solid #e1e4e8;border-radius:6px;padding:8px 12px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
              <div style="position:relative;width:100px;height:100px;margin-right:12px;">
                <svg viewBox="0 0 100 100" style="transform:rotate(-90deg);width:100px;height:100px;">
                  <circle cx="50" cy="50" r="#{radius}" fill="transparent" stroke="#eaeaea" stroke-width="16" />
                  #{svg_parts.join}
                </svg>
                <div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);text-align:center;font-size:10px;font-weight:bold;color:#555;">
                  #{total_effort.round(0)}h
                </div>
              </div>
              <div style="min-width:140px;max-height:100px;overflow-y:auto;padding-right:2px;">
                #{legend_items}
              </div>
            </div>
          }
          html.html_safe
        end

        def label_milestone
          if AdvancedRoadmap::Setting.milestone_label.blank?
            l(:label_milestone)
          else
            AdvancedRoadmap::Setting.milestone_label
          end
        end

        def label_milestone_plural
          if AdvancedRoadmap::Setting.milestone_plural_label.blank?
            l(:label_milestone_plural)
          else
            AdvancedRoadmap::Setting.milestone_plural_label
          end
        end

      end
    end
  end
end
