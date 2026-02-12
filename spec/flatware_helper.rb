# frozen_string_literal: true

if defined?(Flatware)
  # https://github.com/briandunn/flatware/blob/63e2ce7c26f17374e44e8c82d2457e2001070cc2/README.md#faster-startup-with-activerecord
  Flatware.configure do |conf|
    conf.before_fork do
      require 'rails_helper'

      ActiveRecord::Base.connection.disconnect!
    end

    conf.after_fork do |test_env_number|
      if ENV.fetch('COVERAGE', false)
        require 'simplecov'
        SimpleCov.at_fork.call(test_env_number) # Combines parallel coverage results
      end

      config = ActiveRecord::Base.connection_db_config.configuration_hash

      ActiveRecord::Base.establish_connection(
        config.merge(
          database: config.fetch(:database) + test_env_number.to_s
        )
      )
    end
  end
end
