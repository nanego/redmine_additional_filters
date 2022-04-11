require 'redmine'
require_relative 'lib/redmine_additional_filters/hooks'

Redmine::Plugin.register :redmine_additional_filters do
  name 'Redmine Additional Filters plugin'
  author 'Vincent ROBERT'
  description 'This plugin for Redmine adds some issue filters and columns'
  version '5.0.0'
  url 'https://github.com/nanego/redmine_additional_filters'
  author_url 'https://github.com/nanego'
  # requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.4' if Rails.env.test?
end
