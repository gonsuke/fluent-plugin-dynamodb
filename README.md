# Amazon DynamoDB output plugin for [Fluentd](http://fluentd.org) event collector

##Installation

    $ fluent-gem install fluent-plugin-dynamodb

##Configuration


###DynamoDB

First of all, you need to create a table in DynamoDB. It's easy to create via Management Console.

Specify table name, hash attribute name and throughput as you like. fluent-plugin-dynamodb will load your table schema and write event-stream out to your table.


### Fluentd

    <match dynamodb.**>
      @type dynamodb
      aws_key_id AWS_ACCESS_KEY
      aws_sec_key AWS_SECRET_ACCESS_KEY
      proxy_uri http://user:password@192.168.0.250:3128/
      dynamo_db_endpoint dynamodb.ap-northeast-1.amazonaws.com
      dynamo_db_table access_log
    </match>

 * **aws\_key\_id (optional)** - AWS access key id. This parameter is required when your agent is not running on EC2 instance with an IAM Instance Profile.
 * **aws\_sec\_key (optional)** - AWS secret key. This parameter is required when your agent is not running on EC2 instance with an IAM Instance Profile.
 * **proxy_uri (optional)** - your proxy url.
 * **dynamo\_db\_endpoint (required)** - end point of dynamodb. see  [Regions and Endpoints](http://docs.amazonwebservices.com/general/latest/gr/rande.html#ddb_region)
 * **dynamo\_db\_table (required)** - table name of dynamodb.

##TIPS

###retrieving data

fluent-plugin-dynamo will add **time** attribute and any other attributes of record automatically.
For example if you read apache's access log via fluentd, structure of the table will have been like this.

<table>
  <tr>
    <th>id (Hash Key)</th>
    <th>time</th>
    <th>host</th>
    <th>path</th>
    <th>method</th>
    <th>referer</th>
    <th>code</th>
    <th>agent</th>
    <th>size</th>
  </tr>
  <tr>
    <td>"a937f980-b304-11e1-bc96-c82a14fffef2"</td>
    <td>"2012-06-10T05:26:46Z"</td>
    <td>"192.168.0.3"</td>
    <td>"/index.html"</td>
    <td>"GET"</td>
    <td>"-"</td>
    <td>"200"</td>
    <td>"Mozilla/5.0"</td>
    <td>"4286"</td>
  </tr>
  <tr>
    <td>"a87fc51e-b308-11e1-ba0f-5855caf50759"</td>
    <td>"2012-06-10T05:28:23Z"</td>
    <td>"192.168.0.4"</td>
    <td>"/sample.html"</td>
    <td>"GET"</td>
    <td>"-"</td>
    <td>"200"</td>
    <td>"Mozilla/5.0"</td>
    <td>"8933"</td>
  </tr>
</table>

Item can be retrieved by the key, but fluent-plugin-dynamo uses UUID as a primary key.
There is no simple way to retrieve logs you want.
By the way, you can write scan-filter with AWS SDK like [this](https://gist.github.com/2906291), but Hive on EMR is the best practice I think.

###multiprocessing

If you need high throughput and if you have much provisioned throughput and abudant buffer, you can setup multiprocessing. fluent-plugin-dynamo inherits **DetachMultiProcessMixin**, so you can launch 6 processes as follows.

    <match dynamodb.**>
      @type dynamodb
      aws_key_id AWS_ACCESS_KEY
      aws_sec_key AWS_SECRET_ACCESS_KEY
      proxy_uri http://user:password@192.168.0.250:3128/
      detach_process 6
      dynamo_db_endpoint dynamodb.ap-northeast-1.amazonaws.com
      dynamo_db_table access_log
    </match>

###multi-region redundancy

As you know fluentd has **copy** output plugin.
So you can easily setup multi-region redundancy as follows.

    <match dynamo.**>
      @type copy
      <store>
        @type dynamodb
        aws_key_id AWS_ACCESS_KEY
        aws_sec_key AWS_SECRET_ACCESS_KEY
        dynamo_db_table test
        dynamo_db_endpoint dynamodb.ap-northeast-1.amazonaws.com
      </store>
      <store>
        @type dynamodb
        aws_key_id AWS_ACCESS_KEY
        aws_sec_key AWS_SECRET_ACCESS_KEY
        dynamo_db_table test
        dynamo_db_endpoint dynamodb.ap-southeast-1.amazonaws.com
      </store>
    </match>

##TODO

 * auto-create table
 * tag_mapped

##Copyright

<table> 
  <tr>
    <td>Copyright</td><td>Copyright (c) 2012- Takashi Matsuno</td>
  </tr>
  <tr>
    <td>License</td><td>Apache License, Version 2.0</td>
  </tr>
</table>
