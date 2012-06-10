# Amazon DynamoDB output plugin for Fluent event collector

##Installation

    $ fluent-gem install fluent-plugin-dynamodb

##Configuration


###DynamoDB

First of all, you need to create a table in DynamoDB. It's easy to create via Management Console.

Specify table name, hash attribute name and throughput as you like. fluent-plugin-dynamodb will load your table schema and write event-stream out to your table.

*currently supports only table with a primary key which has a string hash-key. (hash and range key is not supported.)*

### Fluentd

    <match dynamodb.**>
      type dynamodb
      aws_key_id AWS_ACCESS_KEY
      aws_sec_key AWS_SECRET_ACCESS_KEY
      proxy_uri http://user:password@192.168.0.250:3128/
      dynamo_db_endpoint dynamodb.ap-northeast-1.amazonaws.com
      dynamo_db_table access_log
    </match>

 * **aws\_key\_id (required)** - AWS access key id.
 * **aws\_sec\_key (required)** - AWS secret key.
 * **proxy_uri (optional)** - your proxy url.
 * **dynamo\_db\_endpoint (required)** - end point of dynamodb. see  [Regions and Endpoints](http://docs.amazonwebservices.com/general/latest/gr/rande.html#ddb_region)
 * **dynamo\_db\_table (required)** - table name of dynamodb.

##TIPS

###multi-region redundancy

As you know fluentd has **copy** output plugin.
So you can easily setup multi-region redundancy as follows.

    <match dynamo.**>
      type copy
      <store>
        type dynamodb
        aws_key_id AWS_ACCESS_KEY
        aws_sec_key AWS_SECRET_ACCESS_KEY
        dynamo_db_table test
        dynamo_db_endpoint dynamodb.ap-northeast-1.amazonaws.com
      </store>
      <store>
        type dynamodb
        aws_key_id AWS_ACCESS_KEY
        aws_sec_key AWS_SECRET_ACCESS_KEY
        dynamo_db_table test
        dynamo_db_endpoint dynamodb.ap-southeast-1.amazonaws.com
      </store>
    </match>



##TODO

 * auto-create table
 * tag_mapped
 * Multiprocessing 

##Copyright

<table> 
  <tr>
    <td>Copyright</td><td>Copyright (c) 2012- Takashi Matsuno</td>
  </tr>
  <tr>
    <td>License</td><td>Apache License, Version 2.0</td>
  </tr>
</table>
