# frozen_string_literal: true

module CIHelper
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/sequel_management.rake"
    end
  end
end
