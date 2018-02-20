# frozen_string_literal: true

require_dependency 'issue_query'

# Add filters to IssueQuery model
class IssueQuery < Query

  unless instance_methods.include?(:initialize_available_filters_with_additional_filters)
    def initialize_available_filters_with_additional_filters
      initialize_available_filters_without_additional_filters
      # self.operators_by_filter_type.merge!({ :text_contains => ["~", "!~"] })
      add_available_filter "notes", type: :text
      add_available_filter "all_text_fields", type: :text
    end
    alias_method_chain :initialize_available_filters, :additional_filters
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
end
