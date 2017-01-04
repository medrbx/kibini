#! /bin/bash

dayofweek=`date +%u`
dayofmonth=`date +%e`

dir='/home/kibini/kibini_dev/bin/'

# CHAQUE MERCREDI
if [ $dayofweek -eq 3 ]
then
	# On anonymise koha_prod, puis on réalise un dump de koha_prod et de statdb
	perl $dir/admin_sauv_bdd.pl
	# On met à jour les entrées, webkiosk, les adhérents dans ES
	perl $dir/statdb_borrowers.pl
	perl $dir/es_entrees.pl
	perl $dir/es_webkiosk.pl
	perl $dir/es_borrowers.pl
	# On met à jour la carte des quartiers
	perl $dir/data_carte.pl
fi

# CHAQUE PREMIER MERCREDI DU MOIS
if [ $dayofweek -eq 3 ] && [ $dayofmonth -lt 8 ]
then
	# On fait un cliché des données adhérents
	perl $dir/es_borrowers_synth.pl
fi

# CHAQUE JOUR
# On charge sur preprod la version de koha_prod du jour
perl $dir/statdb_load_koha_prod.pl

# On met à jour les stats web
bash $dir/web.sh

# On incorpore dans statdb et ES les prêts de la veille
perl $dir/statdb_issues.pl
perl $dir/es_prets.pl

# On incorpore dans statdb et ES les réservations de la veille
perl $dir/statdb_reserves.pl
perl $dir/es_reservations.pl

# On incorpore dans statdb et ES les statisques nedap de la journée précédente
perl $dir/statdb_nedap.pl
perl $dir/es_rfid.pl

# On traite les données liées à la fréquentation de la salle d'étude
perl $dir/statdb_freq_etude.pl
perl $dir/es_freq_etude.pl

# CHAQUE MARDI
if [ $dayofweek -eq 2 ]
then
	# On incorpore dans statdb des données sur les exemplaires et les adhérents
	perl $dir/statdb_items_borrowers.pl
fi

# CHAQUE DIMANCHE
if [ $dayofweek -eq 7 ]
then
	# On recrée les index items et catalogue dans ES
	perl $dir/es_items.pl
	bash $dir/catmandu_es.sh

fi