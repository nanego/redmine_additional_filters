require_dependency 'issue_status'

class IssueStatus < ActiveRecord::Base

  safe_attributes 'is_resolved'

  scope :resolved, -> { where(is_resolved: true) }

end
