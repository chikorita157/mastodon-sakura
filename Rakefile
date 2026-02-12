# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

# please don't do this
if Rake::Task.task_defined?('assets:precompile') && ENV.include?('RAKE_NO_YARN_INSTALL_HACK')
  task = Rake::Task['assets:precompile']
  puts task.prerequisites
  task.prerequisites.delete('webpacker:yarn_install')
  task.prerequisites.delete('yarn:install')
  puts task.prerequisites
end
