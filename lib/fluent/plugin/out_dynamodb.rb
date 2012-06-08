# -*- coding: utf-8 -*-
module Fluent


class DynamoDBOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('dynamodb', self)

  def initialize
    super
    require 'aws-sdk'
    require 'msgpack'
    require 'zlib'
    require 'time'
    require 'uuidtools'
  end

  config_param :aws_key_id, :string
  config_param :aws_sec_key, :string
  config_param :proxy_uri, :string, :default => nil
  config_param :dynamo_db_table, :string
  config_param :dynamo_db_endpoint, :string, :default => nil

  config_param :time_format, :string, :default => nil

  def configure(conf)
    super

    @timef = TimeFormatter.new(@time_format, @localtime)
  end

  def start
    super
    options = {
      :access_key_id      => @aws_key_id,
      :secret_access_key  => @aws_sec_key,
      :dynamo_db_endpoint => @dynamo_db_endpoint,
    }
    options[:proxy_uri] = @proxy_uri if @proxy_uri

    restart_session(options)
  end

  def restart_session(options)
    sts = AWS::STS.new(options)
    session = sts.new_session(:duration => 60*60)
    options['session_token'] = session.credentials['session_token']
    config = AWS.config(options)
    @batch = AWS::DynamoDB::BatchWrite.new(config)
    @dynamo_db = AWS::DynamoDB.new(options)
  end

  def format(tag, time, record)
    [time, record].to_msgpack
  end

  def write(chunk)
    records = collect_records(chunk)
    $log.warn "writing..."
    records.each {|record|
      @batch.put(@dynamo_db_table, [record])
    }
    @batch.process!
  end

  def collect_records(chunk)
    records = []
    chunk.msgpack_each { |time, record|
      record['time'] = @timef.format(time)
      record['id'] = UUIDTools::UUID.timestamp_create.to_s
      records << record
    }
    records
  end

end


end
