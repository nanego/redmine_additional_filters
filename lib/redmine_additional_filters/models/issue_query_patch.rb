require_dependency 'issue_query'
require_dependency 'custom_field'
require_dependency 'project_custom_field'

class IssueQuery

  # unless Rails.env.test? # These lines break core tests TODO Fix it
    project_custom_fields = ProjectCustomField.visible.map {|cf| QueryAssociationCustomFieldColumn.new(:project, cf)}
    self.available_columns.push(*project_custom_fields)
  # end

  # Left join allows us to include issues which do not have any journal
  sql_to_sort_issues_by_notes_count = "(SELECT COALESCE(t.counter,0) as counter FROM issues as i
	  left join (SELECT journals.journalized_id, count(journals.id) as counter
    FROM journals
    WHERE journals.journalized_type = 'Issue'
    AND (journals.notes != '')
    GROUP BY journals.journalized_id) t on t.journalized_id = i.id
	  WHERE i.id = issues.id)"
  self.available_columns << QueryColumn.new(:notes_count, :groupable => false, :sortable => sql_to_sort_issues_by_notes_count) if self.available_columns.select {|c| c.name == :notes_count}.empty?
  self.available_columns << QueryColumn.new(:first_assignment_date) if self.available_columns.select {|c| c.name == :first_assignment_date}.empty?

end

module PluginAdditionalFilters

  module IssueQueryPatch

    def initialize_available_filters
      super
      # self.operators_by_filter_type.merge!({ :text_contains => ["~", "!~"] })
      add_available_filter "notes", type: :text
      add_available_filter "all_text_fields", type: :text
      add_available_filter "notes_count", :type => :integer
      add_available_filter "subproject_id",
                           :type => :list,
                           :values => lambda {project_values},
                           :label => :field_parent
    end

    def sql_for_notes_field(field, operator, value)
      case operator
      when "~", "!~" # Contain / Do not contain
        boolean_switch = operator == "!~" ? 'NOT' : ''
        journals = Journal.arel_table
        "(#{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}" +
            " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND" +
            " #{Journal.table_name}.journalized_type = 'Issue' AND" +
            " #{journals[:notes].matches("%#{value.first}%").to_sql} ))"
      when "*", "!*" # All / None
        boolean_switch = operator == "!*" ? 'NOT' : ''
        "(#{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}" +
            " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND" +
            " #{Journal.table_name}.journalized_type = 'Issue' AND" +
            " (#{Journal.table_name}.notes IS NOT NULL AND #{Journal.table_name}.notes <> '')))"
      else
        ""
      end
    end

    def sql_for_all_text_fields_field(field, operator, value)
      case operator
      when "~", "!~", "*", "!*" # Contain / Do not contain / All / None
        boolean_switch = (operator == "!~" || operator == "!*") ? ' AND ' : ' OR '
        " (" + sql_for_field("description", operator, value, Issue.table_name, "description") +
            boolean_switch +
            sql_for_field("subject", operator, value, Issue.table_name, "subject") +
            boolean_switch +
            sql_for_notes_field("notes", operator, value) + ") "
      else
        ""
      end
    end

    def sql_for_notes_count_field(field, operator, value)
      subquery = "SELECT t.journalized_id FROM (SELECT journals.journalized_id, count(journals.id) as counter
          FROM journals
          INNER JOIN issues ON issues.id = journals.journalized_id
          INNER JOIN projects ON projects.id = issues.project_id
          WHERE journals.journalized_type = 'Issue'
          AND ((journals.private_notes = 'f' OR journals.user_id = #{User.current.id} OR ((projects.status <> 9 OR 1=0))))
          AND (journals.notes != '')
          GROUP BY journals.journalized_id"

      if value.any?
        int_values = value.first.to_s.scan(/[+-]?\d+/).map(&:to_i)
      else
        # IN an empty set
        return "1=0"
      end

      case operator
      when "="
        sql = "issues.id IN ( #{subquery} ) t
          WHERE t.counter IN (#{int_values.join(',')})
          )"
        if int_values.include?(0)
          sql << " OR issues.id NOT IN ( #{subquery} ) t )"
        end
      when "!*", "*"
        neg = (operator == '!*' ? 'NOT' : '')
        sql = "issues.id #{neg} IN ( #{subquery} ) t )"
      when ">="
        sql = "issues.id IN ( #{subquery} ) t
          WHERE t.counter >= #{int_values.first}
          )"
        if int_values.first == 0
          sql << " OR issues.id NOT IN ( #{subquery} ) t )"
        end
      when "<="
        sql = "issues.id IN ( #{subquery} ) t
          WHERE t.counter #{operator} (#{int_values.first})
          )"
        if int_values.first >= 0
          sql << " OR issues.id NOT IN ( #{subquery} ) t )"
        end
      when "><"
        sql = "issues.id IN ( #{subquery} ) t
          WHERE t.counter BETWEEN #{value[0].to_i} AND #{value[1].to_i}
          )"
        if value[0].to_i == 0 || value[1].to_i == 0
          sql << " OR issues.id NOT IN ( #{subquery} ) t )"
        end
      else
        raise "Unknown query operator #{operator}"
      end

      return sql
    end

    # Returns the issues
    # Valid options are :order, :offset, :limit, :include, :conditions
    def issues(options = {})
      issues = super
      if has_column?(:notes_count)
        Issue.load_notes_count(issues)
      end
      issues
    end

  end

end

IssueQuery.prepend PluginAdditionalFilters::IssueQueryPatch
