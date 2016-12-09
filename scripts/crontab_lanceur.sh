#! /bin/bash

dayofweek=`date +%u`
dayofmonth=`date +%e`

# CHAQUE MERCREDI
if [ $dayofweek -eq 3 ]
then
	# On anonymise koha_prod, puis on réalise un dump de koha_prod et de statdb
	perl /home/kibini/kibini_prod/scripts/admin_sauv_bdd.pl
	# On met à jour les entrées, webkiosk, les adhérents dans ES
	perl /home/kibini/kibini_prod/scripts/statdb_borrowers.pl
	perl /home/kibini/kibini_prod/scripts/es_entrees.pl
	perl /home/kibini/kibini_prod/scripts/es_webkiosk.pl
	perl /home/kibini/kibini_prod/scripts/es_borrowers.pl
fi

# CHAQUE PREMIER MERCREDI DU MOIS
if [ $dayofweek -eq 3 ] && [ $dayofmonth -lt 8 ]
then
	# On fait un cliché des données adhérents
	perl /home/kibini/kibini_prod/scripts/es_borrowers_synth.pl
fi

# CHAQUE JOUR
# On charge sur preprod la version de koha_prod du jour
perl /home/kibini/kibini_prod/scripts/statdb_load_koha_prod.pl

# On met à jour les stats web
bash /home/kibini/kibini_prod/scripts/web.sh

# On incorpore dans statdb et ES les prêts de la veille
perl /home/kibini/kibini_prod/scripts/statdb_issues.pl
perl /home/kibini/kibini_prod/scripts/es_prets.pl

# On incorpore dans statdb et ES les réservations de la veille
perl /home/kibini/kibini_prod/scripts/statdb_reserves.pl
perl /home/kibini/kibini_prod/scripts/es_reservations.pl

# On incorpore dans statdb et ES les statisques nedap de la journée précédente
perl /home/kibini/kibini_prod/scripts/statdb_nedap.pl
perl /home/kibini/kibini_prod/scripts/es_rfid.pl

# On traite les données liées à la fréquentation de la salle d'étude
perl /home/kibini/kibini_prod/scripts/statdb_freq_etude.pl

# CHAQUE MARDI
if [ $dayofweek -eq 2 ]
then
	# On incorpore dans statdb des données sur les exemplaires et les adhérents
	perl /home/kibini/kibini_prod/scripts/statdb_items_borrowers.pl
fi

# CHAQUE DIMANCHE
if [ $dayofweek -eq 7 ]
then
	# On recrée les index items et catalogue dans ES
	perl /home/kibini/kibini_prod/scripts/es_items.pl
	bash /home/kibini/kibini_prod/scripts/catmandu_es.sh

fi