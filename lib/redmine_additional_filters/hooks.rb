# frozen_string_literal: true

module PluginAdditionalFilters
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        require_relative 'models/issue_patch'
        require_relative 'models/query_patch' unless Rails.env.test?
        require_relative 'models/issue_query_patch'
        require_relative 'models/issue_status_patch'
      end
    end
  end
end
