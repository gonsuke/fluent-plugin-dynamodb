require 'fluent/test'
require 'fluent/plugin/out_dynamodb'

class DynamoDBOutputTest < Test::Unit::TestCase
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
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::DynamoDBOutput) do
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

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({"a"=>1}, time)
    d.emit({"a"=>2}, time)

    d.expect_format([time, {'a' => 1}].to_msgpack)
    d.expect_format([time, {'a' => 2}].to_msgpack)

    d.run
  end

  def test_write
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({"a"=>1}, time)
    d.emit({"a"=>2}, time)

    data = d.run

    assert_equal [time, {'a' => 1}].to_msgpack + [time, {'a' => 2}].to_msgpack, data
  end

end
