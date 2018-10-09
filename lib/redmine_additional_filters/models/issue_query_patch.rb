# frozen_string_literal: true

require_dependency 'issue_query'

class IssueQuery < Query
  project_custom_fields = ProjectCustomField.visible.
      map {|cf| QueryAssociationCustomFieldColumn.new(:project, cf) }
  self.available_columns.push(*project_custom_fields)

  self.available_columns << QueryColumn.new(:notes_count, :groupable => false) if self.available_columns.select { |c| c.name == :notes_count }.empty?
end

module PluginAdditionalFilters

  module IssueQueryPatch

    def initialize_available_filters
      super
      # self.operators_by_filter_type.merge!({ :text_contains => ["~", "!~"] })
      add_available_filter "notes", type: :text
      add_available_filter "all_text_fields", type: :text
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

    # Returns the issues
    # Valid options are :order, :offset, :limit, :include, :conditions
    def issues(options={})
      issues = super
      if has_column?(:notes_count)
        Issue.load_notes_count(issues)
      end
      issues
    end

  end

end

IssueQuery.prepend PluginAdditionalFilters::IssueQueryPatch
