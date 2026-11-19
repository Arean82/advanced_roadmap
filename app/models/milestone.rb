# encoding: UTF-8

class Milestone < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :project
  has_many :milestone_versions, :dependent => :destroy
  has_many :versions, :through => :milestone_versions

  include Redmine::SafeAttributes
  safe_attributes :name, :description, :milestone_effective_date

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 60
  validate :validate_milestone_effective_date
  
  def validate_milestone_effective_date
    return if milestone_effective_date.blank?
    if milestone_effective_date.is_a?(String) && !milestone_effective_date.match(/\A\d{4}-\d{2}-\d{2}\z/)
      errors.add(:milestone_effective_date, :not_a_date)
    end
  end

  def to_s
    name
  end
  
  def <=>(milestone)
    if self.milestone_effective_date
      if milestone.milestone_effective_date
        if self.milestone_effective_date == milestone.milestone_effective_date
          self.name <=> milestone.name
        else
          self.milestone_effective_date <=> milestone.milestone_effective_date
        end
      else
        -1
      end
    else
      if milestone.milestone_effective_date
        1
      else
        self.name <=> milestone.name
      end
    end
  end

  def versions?(version)
    versions.include?(version)
  end

  def completed?
    if versions.any?
      versions.all? { |v| v.status == 'closed' || v.completed? }
    else
      milestone_effective_date && (milestone_effective_date <= Date.today)
    end
  end

  def overdue?
    milestone_effective_date && (milestone_effective_date < Date.today) && !completed?
  end

  def at_risk?(totals = nil)
    return false if completed?
    return true if overdue?
    if milestone_effective_date
      calc_totals = totals || Version.calculate_totals(versions)
      estimated_date = Milestone.estimated_due_date(calc_totals)
      if estimated_date && estimated_date.to_date > milestone_effective_date
        return true
      end
    end
    false
  end

  def status_badge
    if completed?
      '<span class="badge badge-status-closed" style="background-color:#28a745;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:bold;">' + I18n.t(:version_status_closed, default: 'Closed') + '</span>'
    elsif overdue?
      '<span class="badge badge-status-overdue" style="background-color:#dc3545;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:bold;">' + I18n.t(:label_overdue, default: 'Overdue') + '</span>'
    elsif at_risk?
      '<span class="badge badge-status-risk" style="background-color:#fd7e14;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:bold;">' + I18n.t(:label_at_risk, default: 'At Risk') + '</span>'
    else
      '<span class="badge badge-status-open" style="background-color:#007bff;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:bold;">' + I18n.t(:version_status_open, default: 'Open') + '</span>'
    end.html_safe
  end

  def is_a?(o)
    return true if o == Version
    super
  end

  def self.estimated_due_date(totals)
    return nil unless totals && totals[:parallel_rest_hours]
    estimated_due_date = nil
    non_working_week_days = Setting.non_working_week_days.map{ |day| day.to_i % 7 }
    if (non_working_week_days.count < 7)
      days = (totals[:parallel_rest_hours] / 8.0).ceil
      estimated_due_date = DateTime.now
      while days > 1
        days -= 1 unless non_working_week_days.include?(estimated_due_date.wday)
        estimated_due_date += 1.days
      end
    end
    return estimated_due_date
  end

end
