
========================================================
Amazon DynamoDB output plugin for Fluent event collector
========================================================

Installation
------------

::

   $ fluent-gem install fluent-plugin-dynamodb

Configuration
-------------

::

    <match dynamodb.**>
      type dynamodb
      aws_key_id AWS_ACCESS_KEY
      aws_sec_key AWS_SECRET_ACCESS_KEY
      proxy_uri http://192.168.0.250:3128/
      dynamo_db_endpoint dynamodb.ap-northeast-1.amazonaws.com
      dynamo_db_table access_log
    </match>


* aws_key_id (required)

 * AWS access key id.

* aws_sec_key (required)

 * AWS secret key.

* proxy_uri (optional)

 * your proxy url.

* dynamo_db_endpoint (required)

 * dynamodb endpoint. see http://docs.amazonwebservices.com/general/latest/gr/rande.html#ddb_region

* dynamo_db_table (required)

 * table name of dynamodb.

TODO
----

* auto-create table

* tag_mapped

Copyright
--------------

Copyright:: Copyright (c) 2012- Takashi Matsuno
License::   Apache License, Version 2.0
