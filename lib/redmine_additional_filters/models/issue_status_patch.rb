require_dependency 'issue_status'

module RedmineAdditionalFilters::Models::IssueStatusPatch
  def self.included(base)
    base.class_eval do
      safe_attributes 'is_resolved'
      scope :resolved, -> { where(is_resolved: true) }
    end
  end
end
IssueStatus.send :include, RedmineAdditionalFilters::Models::IssueStatusPatch
