require 'spec_helper'

describe IssueQuery do

  fixtures :issues, :journals, :journal_details,
           :projects, :enabled_modules,
           :users, :email_addresses,
           :members, :member_roles, :roles,
           :trackers, :issue_statuses, :issue_categories, :enumerations, :versions,
           :custom_fields, :custom_values,
           :queries

  describe 'filters and columns' do

    def find_issues_with_query(query)
      Issue.joins(:status, :tracker, :project, :priority).where(
          query.statement
      ).to_a
    end

    it 'initialize a "notes" filter' do
      query = IssueQuery.new
      expect(query.available_filters).to include 'notes'
    end

    it 'initialize an "all_text_fields" filter' do
      query = IssueQuery.new
      expect(query.available_filters).to include 'all_text_fields'
    end

    it 'test operator contains on "notes" filter' do
      issue = Issue.find(1)

      query = IssueQuery.new(:name => '_')
      query.add_filter('notes', '~', ['Al noteS'])
      result = find_issues_with_query(query)
      expect(result).to include issue
      expect(result.size).to be 1
    end

    it 'test operator DO NOT contains on "notes" filter' do
      issue = Issue.find(1)

      query = IssueQuery.new(:name => '_')
      query.add_filter('notes', '!~', ['Al noteS'])
      result = find_issues_with_query(query)
      expect(result).to_not include issue
    end

    it 'test operator contains on "all text fields" filter' do
      issue = Issue.find(1)

      query = IssueQuery.new(:name => '_')
      query.add_filter('all_text_fields', '~', ['Al noteS']) # Text present in Notes
      result = find_issues_with_query(query)
      expect(result).to include issue
      expect(result.size).to be 1

      query = IssueQuery.new(:name => '_')
      query.add_filter('all_text_fields', '~', ['print recipes']) # Text present in the Subject
      result = find_issues_with_query(query)
      expect(result).to include issue

      query = IssueQuery.new(:name => '_')
      query.add_filter('all_text_fields', '~', ['unable']) # Text present in the Description
      result = find_issues_with_query(query)
      expect(result).to include issue
    end

    it 'test operator DO NOT contains on "all text fields" filter' do
      issue = Issue.find(1)

      query = IssueQuery.new(:name => '_')
      query.add_filter('all_text_fields', '!~', ['Al noteS']) # Text present in Notes
      result = find_issues_with_query(query)
      expect(result).to_not include issue

      query = IssueQuery.new(:name => '_')
      query.add_filter('all_text_fields', '!~', ['print recipes']) # Text present in the Subject
      result = find_issues_with_query(query)
      expect(result).to_not include issue

      query = IssueQuery.new(:name => '_')
      query.add_filter('all_text_fields', '!~', ['unable']) # Text present in the Description
      result = find_issues_with_query(query)
      expect(result).to_not include issue
    end

    it 'has new columns for project custom fields' do
      IssueQuery.add_project_custom_fields_to_available_columns
      ProjectCustomField.find_each do |project_cf|
        expect(IssueQuery.available_columns.find {|column| column.name == "project.cf_#{project_cf.id}".to_sym}).to_not be_nil
      end
    end

    describe 'notes count filter and column' do

      before do
        @issue_one = Issue.find(1)
        expect(@issue_one.notes_count).to eq 2
        @issue_two = Issue.find(2)
        expect(@issue_two.notes_count).to eq 1
        @issue_three = Issue.find(3)
        expect(@issue_three.notes_count).to eq 0
      end

      it 'initialize an "notes count" filter' do
        query = IssueQuery.new(:name => '_')
        expect(query.available_filters).to include 'notes_count'
      end

      it 'filters issues by notes count with operator =' do
        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '=', ['1'])
        result = find_issues_with_query(query)
        expect(result).to include @issue_two
        expect(result).to_not include @issue_one
      end

      it 'filters issues by notes count with operator = and value is zero' do
        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '=', ['0'])
        result = find_issues_with_query(query)
        expect(result).to include @issue_three
        expect(result).to_not include @issue_one
      end

      it 'filters issues by notes count with operators >= & <=' do
        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '>=', ['1'])
        result = find_issues_with_query(query)
        expect(result).to include @issue_two
        expect(result).to include @issue_one
        expect(result).to_not include @issue_three

        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '<=', ['1'])
        result = find_issues_with_query(query)
        expect(result).to include @issue_three
        expect(result).to include @issue_two
        expect(result).to_not include @issue_one

        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '>=', ['10'])
        result = find_issues_with_query(query)
        expect(result).to_not include @issue_two
        expect(result).to_not include @issue_one
        expect(result).to_not include @issue_three
      end

      it 'filters issues by notes count with operators * & !*' do
        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '*')
        result = find_issues_with_query(query)
        expect(result).to include @issue_two
        expect(result).to include @issue_one
        expect(result).to_not include @issue_three

        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '!*')
        result = find_issues_with_query(query)
        expect(result).to include @issue_three
        expect(result).to_not include @issue_two
        expect(result).to_not include @issue_one
      end

      it 'filters issues by notes count with operator ><' do
        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '><', ['1', '2'])
        result = find_issues_with_query(query)
        expect(result).to include @issue_two
        expect(result).to include @issue_one
        expect(result).to_not include @issue_three

        query = IssueQuery.new(:name => '_')
        query.add_filter('notes_count', '><', ['0', '1'])
        result = find_issues_with_query(query)
        expect(result).to include @issue_two
        expect(result).to_not include @issue_one
        expect(result).to include @issue_three
      end

      it 'has a new column for issue notes count' do
        expect(IssueQuery.available_columns.find {|column| column.name == :notes_count}).to_not be_nil
      end

      it 'should preload notes count' do
        q = IssueQuery.new(:name => '_', :column_names => [:subject, :notes_count])
        expect(q.has_column?(:notes_count))
        issues = q.issues
        expect(issues.first.instance_variable_get("@notes_count")).to_not be_nil
      end

      it 'should be able to sort by notes count ASC' do
        query = IssueQuery.new(:name => 'Sorted')
        column = query.available_columns.find {|col| col.name == :notes_count}
        expect(column).to_not be_nil
        expect(column.sortable).to_not be_nil
        issues = query.issues(:order => "#{column.sortable} ASC")
        values = issues.map(&:notes_count)
        expect(values).to_not be_empty
        expect(values).to eq values.sort
      end

      it 'should be able to sort by notes count DESC' do
        query = IssueQuery.new(:name => 'Sorted')
        column = query.available_columns.find {|col| col.name == :notes_count}
        expect(column).to_not be_nil
        expect(column.sortable).to_not be_nil
        issues = query.issues(:order => "#{column.sortable} DESC")
        values = issues.map(&:notes_count)
        expect(values).to_not be_empty
        expect(values).to eq values.sort.reverse
      end

    end

    describe 'first_assignment_date column' do

      before do

      end

      it 'has a new column for first_assignment_date' do
        expect(IssueQuery.available_columns.find {|column| column.name == :first_assignment_date}).to_not be_nil
      end

    end

    describe 'resolved_on column' do

      before do

      end

      it 'has a new column for last resolved date' do
        expect(IssueQuery.available_columns.find {|column| column.name == :resolved_on}).to_not be_nil
      end

    end

    describe 'author_email column' do

      it 'adds a new column to display the author mail address' do
        expect(IssueQuery.available_columns.find {|column| column.name == :author_mail}).to_not be_nil
      end

    end

  end
end
