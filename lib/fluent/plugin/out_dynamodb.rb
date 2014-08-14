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

  config_param :aws_key_id, :string, :default => nil
  config_param :aws_sec_key, :string, :default => nil
  config_param :proxy_uri, :string, :default => nil
  config_param :dynamo_db_table, :string
  config_param :dynamo_db_endpoint, :string, :default => nil
  config_param :time_format, :string, :default => nil
  config_param :detach_process, :integer, :default => 2
  config_param :disable_batch_write, :bool, :default => false

  def configure(conf)
    super

    @timef = TimeFormatter.new(@time_format, @localtime)
  end

  def start
    options = {}
    if @aws_key_id && @aws_sec_key
      options[:access_key_id] = @aws_key_id
      options[:secret_access_key] = @aws_sec_key
    end
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
    @batch = AWS::DynamoDB::BatchWrite.new(config) unless @disable_batch_write
    @dynamo_db = AWS::DynamoDB.new(options)
  end

  def valid_table(table_name)
    @table = @dynamo_db.tables[table_name]
    @table.load_schema
    @hash_key = @table.hash_key
    @range_key = @table.range_key unless @table.simple_key?
  end

  def match_type!(key, record)
    if key.type == :number
      potential_value = record[key.name].to_i
      if potential_value == 0
        $log.fatal "Failed attempt to cast hash_key to Integer."
      end
      record[key.name] = potential_value
    end
  end

  def format(tag, time, record)
    if !record.key?(@hash_key.name)
      record[@hash_key.name] = UUIDTools::UUID.timestamp_create.to_s
    end
    match_type!(@hash_key, record)

    formatted_time = @timef.format(time)
    if @range_key
      if !record.key?(@range_key.name)
        record[@range_key.name] = formatted_time
      end
      match_type!(@range_key, record)
    end
    record['time'] = formatted_time

    record.to_msgpack
  end

  def write(chunk)
    if @batch
      write_batch(chunk)
    else
      chunk.msgpack_each {|record|
        put_record(record)
      }
    end
  end

  def write_batch(chunk)
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

  def put_record(record)
    @table.items.put(record)
  end

end


end

