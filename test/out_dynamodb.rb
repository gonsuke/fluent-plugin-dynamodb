require 'fluent/test'
require 'fluent/test/helpers'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_dynamodb'

class DynamoDBOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    aws_key_id test_key_id
    aws_sec_key test_sec_key
    dynamo_db_table test_table
    dynamo_db_endpoint test.endpoint
    utc
    buffer_type memory
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::DynamoDBOutput) do
      def write(chunk)
        chunk.read
      end
    end.configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'test_key_id', d.instance.aws_key_id
    assert_equal 'test_sec_key', d.instance.aws_sec_key
    assert_equal 'test_table', d.instance.dynamo_db_table
    assert_equal 'test.endpoint', d.instance.dynamo_db_endpoint
  end

  def test_format
    d = create_driver

    time = event_time("2011-01-02 13:14:15 UTC")
    d.run(default_tag: 'test') do
      d.feed(time, {"a"=>1})
      d.feed(time, {"a"=>2})
    end

    expected = [{'a' => 1}].to_msgpack + [{'a' => 2}].to_msgpack
    assert_equal expected, d.formatted
  end

  def test_write
    d = create_driver

    time = event_time("2011-01-02 13:14:15 UTC")
    d.run(default_tag: 'test') do
      d.feed(time, {"a"=>1})
      d.feed(time, {"a"=>2})
    end

    data = d.events

    assert_equal [time, {'a' => 1}].to_msgpack + [time, {'a' => 2}].to_msgpack, data
  end

end
