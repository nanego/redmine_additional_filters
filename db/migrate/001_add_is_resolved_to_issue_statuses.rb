class AddIsResolvedToIssueStatuses < ActiveRecord::Migration[5.2]
  def change
    add_column :issue_statuses, :is_resolved, :boolean, :default => false
  end
end
