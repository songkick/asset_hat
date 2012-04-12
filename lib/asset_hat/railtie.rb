require 'asset_hat'
require 'asset_hat_helper'
require 'rails'

module AssetHat
  class Railtie < Rails::Railtie #:nodoc:
    initializer 'asset_hat.action_view' do |app|
      require 'asset_hat/initializers/action_view'
    end

    initializer 'asset_hat.cache_fingerprints' do |app|
      require 'asset_hat/initializers/cache_fingerprints'
    end

    rake_tasks do
      load 'tasks/asset_hat.rake'
    end
  end
end
