#! /bin/bash

rm /home/kibini/kibini_prod/etc/es_mappings.yaml

for index in action_coop action_culturelle adherents adherents_synth adherents_tout adherents2 adherents2015 catalogue eliminations entrees freq_etude frequentation items periodiques prets reservations rfid synth_ann_exemplaires synth_ann_inscrits synth_ann_prets web web2 webkiosk magasin

do
    curl -XGET localhost:9200/$index/_mapping > /home/kibini/kibini_prod/etc/map.json
    catmandu convert JSON to YAML < /home/kibini/kibini_prod/etc/map.json >> /home/kibini/kibini_prod/etc/es_mappings.yaml
done

rm /home/kibini/kibini_prod/etc/map.json
