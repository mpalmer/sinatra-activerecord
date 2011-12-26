require 'test/unit'
require 'sinatra/base'
require File.expand_path('../../lib/sinatra/activerecord', __FILE__)

class MockSinatraApp < Sinatra::Base
  register Sinatra::ActiveRecordExtension
end

class TestSinatraActiveRecord < Test::Unit::TestCase

  def setup
    File.unlink 'test.db' rescue nil
    ENV.delete('DATABASE_URL')
    @app = Class.new(MockSinatraApp)
  end

  def test_exposes_the_sequel_database_object
    assert @app.respond_to? :database
  end

  def test_uses_the_DATABASE_URL_environment_variable_if_set
    ENV['DATABASE_URL'] = 'sqlite://test-database-url.db'
    assert_equal 'sqlite://test-database-url.db', @app.database_url
  end

  def test_uses_sqlite_url_with_env_if_no_DATABASE_URL_is_defined
    @app.environment = :foo
    assert_equal "sqlite://foo.db", @app.database_url
  end

  def test_establishes_a_database_connection_when_set
    @app.database = 'sqlite://test.db'
    assert @app.database.respond_to? :table_exists?
  end

  def test_db_urls_with_a_path
    @app.database = 'sqlite:///test/foo.db'
    assert_equal 'test/foo.db', @app.database.connection.instance_variable_get(:@config)[:database]
  end
  
  def test_db_urls_with_absolute_path
    @app.database = 'sqlite:////tmp/foo.db'
    assert_equal '/tmp/foo.db', @app.database.connection.instance_variable_get(:@config)[:database]
  end
end
