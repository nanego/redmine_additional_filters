require 'redmine'

# Custom patches
ActiveSupport::Reloader.to_prepare do
  require_dependency 'redmine_additional_filters/models/issue_patch'
  require_dependency 'redmine_additional_filters/models/query_patch' unless Rails.env.test?
  require_dependency 'redmine_additional_filters/models/issue_query_patch'
  require_dependency 'redmine_additional_filters/models/issue_status_patch'
end

Redmine::Plugin.register :redmine_additional_filters do
  name 'Redmine Additional Filters plugin'
  author 'Vincent ROBERT'
  description 'This plugin for Redmine adds some issue filters and columns'
  version '4.2.5'
  url 'https://github.com/nanego/redmine_additional_filters'
  author_url 'mailto:contact@vincent-robert.com'
  # requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
end
