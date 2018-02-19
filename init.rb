Redmine::Plugin.register :redmine_additional_filters do
  name 'Redmine Additional Filters plugin'
  author 'Vincent ROBERT'
  description 'This plugin for Redmine adds some issue filters'
  version '3.4.0'
  url 'https://github.com/nanego/redmine_additional_filters'
  author_url 'mailto:contact@vincent-robert.com'
  # requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
end

# Custom patches
ActionDispatch::Callbacks.to_prepare do
  require_dependency 'redmine_additional_filters/models/issue_query_patch'
end
