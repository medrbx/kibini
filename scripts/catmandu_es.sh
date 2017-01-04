#! /bin/bash

#catmandu convert MARC --type RAW to YAML --fix catmandu_marc2dc.fix < /home/kibini/kibini_prod/dumps/`date +%F`-notices_total.mrc > catmandu_dc.yaml
curl -XDELETE 'http://localhost:9200/catalogue'
#catmandu import -v MARC --type RAW to ES --index_name catalogue --bag koha --fix catmandu_marc2dc.fix < /home/kibini/kibini_prod/dumps/`date +%F`-notices_total.mrc
catmandu import -v MARC --type RAW to ES --index_name catalogue --bag koha --fix catmandu_marc2dc.fix < /home/kibini/kibini_prod/dumps/2016-12-11-notices_total.mrc