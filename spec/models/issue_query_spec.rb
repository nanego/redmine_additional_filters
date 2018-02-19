require 'spec_helper'
require 'redmine_additional_filters/models/issue_query_patch'

describe IssueQuery do
  describe 'filters and columns' do

    it 'initialize an "notes" filter' do
      query = IssueQuery.new
      expect(query.available_filters).to include 'notes'
    end

  end
end
