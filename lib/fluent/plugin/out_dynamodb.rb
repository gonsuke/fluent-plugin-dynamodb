# -*- coding: utf-8 -*-
require 'fluent/plugin/output'
require 'aws-sdk'
require 'msgpack'
require 'time'
require 'uuidtools'

module Fluent::Plugin


class DynamoDBOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output('dynamodb', self)

  helpers :compat_parameters

  DEFAULT_BUFFER_TYPE = "memory"

  BATCHWRITE_ITEM_LIMIT = 25
  BATCHWRITE_CONTENT_SIZE_LIMIT = 1024*1024

  config_param :aws_key_id, :string, :default => nil, :secret => true
  config_param :aws_sec_key, :string, :default => nil, :secret => true
  config_param :proxy_uri, :string, :default => nil
  config_param :dynamo_db_region, :string, default: ENV["AWS_REGION"] || "us-east-1"
  config_param :dynamo_db_table, :string
  config_param :dynamo_db_endpoint, :string, :default => nil
  config_param :time_format, :string, :default => nil
  config_param :detach_process, :integer, :default => 2

  config_section :buffer do
    config_set_default :@type, DEFAULT_BUFFER_TYPE
  end

  def configure(conf)
    super

    @timef = Fluent::TimeFormatter.new(@time_format, @localtime)
  end

  def start
    options = {}
    if @aws_key_id && @aws_sec_key
      options[:access_key_id] = @aws_key_id
      options[:secret_access_key] = @aws_sec_key
    end
    options[:region] = @dynamo_db_region if @dynamo_db_region
    options[:endpoint] = @dynamo_db_endpoint
    options[:proxy_uri] = @proxy_uri if @proxy_uri

    super

    begin
      restart_session(options)
      valid_table(@dynamo_db_table)
    rescue Fluent::ConfigError => e
      log.fatal "ConfigError: Please check your configuration, then restart fluentd. '#{e}'"
      exit!
    rescue Exception => e
      log.fatal "UnknownError: '#{e}'"
      exit!
    end
  end

  def restart_session(options)
    @dynamo_db = Aws::DynamoDB::Client.new(options)
    @resource = Aws::DynamoDB::Resource.new(client: @dynamo_db)

  end

  def valid_table(table_name)
    table = @resource.table(table_name)
    @hash_key = table.key_schema.select{|e| e.key_type == "HASH" }.first
    range_key_candidate = table.key_schema.select{|e| e.key_type == "RANGE" }
    @range_key = range_key_candidate.first if range_key_candidate
  end

  def match_type!(key, record)
    if key.key_type == "NUMBER"
      potential_value = record[key.attribute_name].to_i
      if potential_value == 0
        log.fatal "Failed attempt to cast hash_key to Integer."
      end
      record[key.attribute_name] = potential_value
    end
  end

  def format(tag, time, record)
    if !record.key?(@hash_key.attribute_name)
      record[@hash_key.attribute_name] = UUIDTools::UUID.timestamp_create.to_s
    end
    match_type!(@hash_key, record)

    formatted_time = @timef.format(time)
    if @range_key
      if !record.key?(@range_key.attribute_name)
        record[@range_key.attribute_name] = formatted_time
      end
      match_type!(@range_key, record)
    end
    record['time'] = formatted_time

    record.to_msgpack
  end

  def formatted_to_msgpack_binary?
    true
  end

  def multi_workers_ready?
    true
  end

  def write(chunk)
    batch_size = 0
    batch_records = []
    chunk.msgpack_each {|record|
      batch_records << {
        put_request: {
          item: record
        }
      }
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
    @dynamo_db.batch_write_item(request_items: { @dynamo_db_table => records })
  end

end


end
