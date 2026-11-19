# encoding: UTF-8

module AdvancedRoadmap
  module ProjectPatch
    def self.included(base)
      base.class_eval do
        has_many :milestones
      end
    end
  end
end
