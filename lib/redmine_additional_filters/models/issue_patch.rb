require_dependency 'issue'

class Issue < ActiveRecord::Base

  # Preloads number of notes for a collection of issues
  def self.load_notes_count(issues, user = User.current)
    if issues.any?
      issue_ids = issues.map(&:id)
      notes_count_per_issue = Journal.joins(issue: :project).select('journalized_id, count(journals.id) as count').
          where(:journalized_type => 'Issue', :journalized_id => issue_ids).
          where(Journal.visible_notes_condition(user, :skip_pre_condition => true)).
          where.not(notes: '').
          group(:journalized_id).map do |journal|
        {
            journalized_id: journal.journalized_id,
            count: journal.count
        }
      end
      issues.each do |issue|
        count = notes_count_per_issue.detect {|j| j[:journalized_id] == issue.id}
        issue.instance_variable_set("@notes_count", count ? count[:count] : 0)
      end
    end
  end

  def notes_count
    if @notes_count
      @notes_count
    else
      journals.where.not(notes: '').count
    end
  end

  def first_assignment_date
    first_assignment_date = journals.joins(:details).where("journal_details.property = ? AND journal_details.prop_key = ? AND old_value IS NULL", 'attr', 'assigned_to_id').order('created_on asc').limit(1).pluck('created_on')
    first_assignment_date = created_on if first_assignment_date.blank? && assigned_to.present?
    first_assignment_date
  end

end
