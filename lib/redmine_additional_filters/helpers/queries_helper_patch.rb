require_dependency 'queries_helper'

module PluginAdditionalFilters
  module QueriesHelperPatch

    # Will probably be useful later

  end
end


QueriesHelper.prepend PluginAdditionalFilters::QueriesHelperPatch
ActionView::Base.prepend QueriesHelper
IssuesController.prepend QueriesHelper
