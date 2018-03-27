require 'spec_helper'
require 'redmine_additional_filters/models/issue_query_patch'

describe IssueQuery do

  fixtures :issues, :journals, :journal_details

  describe 'filters and columns' do

    def find_issues_with_query(query)
      Issue.joins(:status, :tracker, :project, :priority).where(
        query.statement
      ).to_a
    end

    it 'initialize an "notes" filter' do
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

  end
end
