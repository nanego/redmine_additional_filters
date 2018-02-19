require_dependency 'issue_query'

class IssueQuery < Query

  unless instance_methods.include?(:initialize_available_filters_with_additional_filters)
    def initialize_available_filters_with_additional_filters
      initialize_available_filters_without_additional_filters
      add_available_filter "notes", :type => :text
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

end
