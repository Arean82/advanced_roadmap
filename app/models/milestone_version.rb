# encoding: UTF-8

class MilestoneVersion < ActiveRecord::Base
  
  belongs_to :milestone
  belongs_to :version

end
