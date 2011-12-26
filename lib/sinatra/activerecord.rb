require 'uri'
require 'time'
require 'sinatra/base'
require 'active_record'
require 'logger'
require 'yaml'

module Sinatra
  module ActiveRecordHelper
    def database
      options.database
    end
  end

  module ActiveRecordExtension
    def database=(url)
      @database = nil
      set :database_url, url
      database
    end

    def database
      @database ||= (
        ActiveRecord::Base.logger = activerecord_logger
        unless database_url.nil?
          url = URI(database_url)
          ActiveRecord::Base.configurations[environment.to_s] = database_options
        end

        ActiveRecord::Base.establish_connection(environment.to_s)
        ActiveRecord::Base
      )
    end
    
    def database_config_yaml=(yaml)
      ActiveRecord::Base.configurations = YAML.load_file(yaml)
      set :database_url, nil
    end

  protected

    def database_options
      url = URI(database_url)
      options = {
        :adapter => url.scheme,
        :host => url.host,
        :port => url.port,
        :database => url.path[1..-1],
        :username => url.user,
        :password => url.password
      }
      case url.scheme
      when "sqlite"
        options[:adapter] = "sqlite3"
      when "postgres"
        options[:adapter] = "postgresql"
      end
      options.merge(database_extras)
    end

    def self.registered(app)
      app.set :database_url, lambda { ENV['DATABASE_URL'] || "sqlite://#{environment}.db" }
      app.set :database_extras, Hash.new
      app.set :activerecord_logger, Logger.new(STDOUT)
      app.helpers ActiveRecordHelper
    end
  end

  register ActiveRecordExtension
end
