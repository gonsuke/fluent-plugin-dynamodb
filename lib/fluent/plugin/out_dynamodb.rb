# -*- coding: utf-8 -*-
module Fluent


class DynamoDBOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('dynamodb', self)

  include DetachMultiProcessMixin

  BATCHWRITE_ITEM_LIMIT = 25
  BATCHWRITE_CONTENT_SIZE_LIMIT = 1024*1024

  def initialize
    super
    require 'aws-sdk'
    require 'msgpack'
    require 'time'
    require 'uuidtools'
  end

  config_param :aws_key_id, :string => nil
  config_param :aws_sec_key, :string => nil
  config_param :proxy_uri, :string, :default => nil
  config_param :dynamo_db_table, :string
  config_param :dynamo_db_endpoint, :string, :default => nil
  config_param :time_format, :string, :default => nil
  config_param :detach_process, :integer, :default => 2

  def configure(conf)
    super

    @timef = TimeFormatter.new(@time_format, @localtime)
  end

  def start
    options[:access_key_id] = @aws_key_id if @aws_key_id
    options[:secret_access_key] = @aws_sec_key if @aws_sec_key
    options[:dynamo_db_endpoint] = @dynamo_db_endpoint
    options[:proxy_uri] = @proxy_uri if @proxy_uri

    detach_multi_process do
      super

      begin
        restart_session(options)
        valid_table(@dynamo_db_table)
      rescue ConfigError => e
        $log.fatal "ConfigError: Please check your configuration, then restart fluentd. '#{e}'"
        exit!
      rescue Exception => e
        $log.fatal "UnknownError: '#{e}'"
        exit!
      end
    end
  end

  def restart_session(options)
    config = AWS.config(options)
    @batch = AWS::DynamoDB::BatchWrite.new(config)
    @dynamo_db = AWS::DynamoDB.new(options)
  end

  def valid_table(table_name)
    table = @dynamo_db.tables[table_name]
    table.load_schema
    raise ConfigError, "Currently composite table is not supported." if table.has_range_key?
    @hash_key_value = table.hash_key.name
  end

  def format(tag, time, record)
    if !record.key?(@hash_key_value)
      record[@hash_key_value] = UUIDTools::UUID.timestamp_create.to_s
    end

    record['time'] = @timef.format(time)
    
    record.to_msgpack
  end

  def write(chunk)
    batch_size = 0
    batch_records = []
    chunk.msgpack_each {|record|
      batch_records << record
      batch_size += record.to_json.length # FIXME: heuristic
      if batch_records.size >= BATCHWRITE_ITEM_LIMIT || batch_size >= BATCHWRITE_CONTENT_SIZE_LIMIT
        batch_put_records(batch_records)
        batch_records.clear
        batch_size = 0
      end
    }
    unless batch_records.empty?
      batch_put_records(batch_records)
    end
  end

  def batch_put_records(records)
    @batch.put(@dynamo_db_table, records)
    @batch.process!
  end

end


end
