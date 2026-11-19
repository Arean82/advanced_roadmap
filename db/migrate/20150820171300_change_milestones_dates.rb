# encoding: UTF-8

class ChangeMilestonesDates < ActiveRecord::Migration[4.2]
#class ChangeMilestonesDates < ActiveRecord::Migration
  def self.up
    rename_column :milestones, :effective_date, :milestone_effective_date
  end

  def self.down
    rename_column :milestones, :milestone_effective_date, :effective_date
  end
end
