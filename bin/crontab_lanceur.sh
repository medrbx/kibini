#! /bin/bash

date=`date +%Y-%m-%d`
date_dump=`date +%Y%m%d`
dayofweek=`date +%u`
dayofmonth=`date +%d`
dayofmonthnextweek=`date +%d -d "7 day"`

dir='/home/kibini/kibini_prod/bin/'
dir_log='/home/kibini/kibini_prod/log/crontab/'
dir_kib2='/home/kibini/kibini2'
dir_data='/home/kibini/kibini_prod/data'

# POUR KIBINI2 : on active l'environnement conda
conda activate kibini


# CHAQUE DERNIER MERCREDI DU MOIS
if [ $dayofweek -eq 3 ] && [ $dayofmonthnextweek -lt $dayofmonth ]
then
    # On fait un clich� des donn�es adh�rents
    perl $dir/statdb_adherents.pl
    perl $dir/es_adherents.pl
fi

# CHAQUE MERCREDI
#if [ $dayofweek -eq 3 ]
#then
    # On r�alise un dump de statdb
 #   perl $dir/admin_sauv_bdd.pl
    # On met � jour webkiosk dans ES
 #   perl $dir/es_webkiosk.pl
    # On met � jour la carte des quartiers
 #   perl $dir/data_carte.pl
#fi

# CHAQUE JOUR
# On charge sur preprod la version de koha_prod du jour
cp $dir_data/dumps_koha/dumps/koha_prod_$date_dump.sql.gz $dir_data/.
perl $dir/statdb_load_koha_prod.pl

# CHAQUE MARDI
if [ $dayofweek -eq 2 ]
then
    # On liste les exemplaires sortis des collections non abîmés, non perdus, non restitués à supprimer
    python $dir_kib2/kibini/adm_items2del2adm.py
	
    # On liste les exemplaires sortis des collections abîmés, perdus, non restitués à supprimer
    python $dir_kib2/kibini/adm_items2delb2adm.py
	
    # On liste les exemplaires non restitués depuis plus de 180 jours
    python $dir_kib2/kibini/adm_itemsRetards2adm.py
	
	# On liste les exemplaires perdus ou prétendus rendus à sortir des collections
	python $dir_kib2/kibini/adm_itemsPerdus2adm.py
	
    # On liste les prétendus rendus à traiter
    python $dir_kib2/kibini/adm_itemsPretendusRendus2adm.py
fi

# CHAQUE PREMIER DU MOIS
if [ `date +%d` == "01" ] 
then
    # On envoie aux acquereurs la liste des documents sortis des collections car perdus, pretendus rendus ou non restitués
	python $dir_kib2/kibini/adm_itemsPerdusPretendusRendus2acquereurs.py
fi


# CHAQUE JOUR
# On met � jour les stats web
bash $dir/web.sh

# On met � jour la table statdb.data_bib
#perl $dir/data_biblio.pl
#perl $dir/data_bib.pl # test statdb.data_bib

# On incorpore dans statdb et ES les pr�ts de la veille
perl $dir/statdb_issues.pl
perl $dir/es_prets.pl

# On incorpore dans statdb et ES les r�servations de la veille
perl $dir/statdb_reserves.pl
perl $dir/es_reservations.pl

# On incorpore dans statdb et ES les statisques nedap de la journ�e pr�c�dente => désormais impossible
#perl $dir/statdb_nedap.pl
#perl $dir/es_rfid.pl

# On traite les donn�es li�es � la fr�quentation de la salle d'�tude
perl $dir/statdb_freq_etude.pl
perl $dir/es_freq_etude.pl

# On incorpore les entr�es
#perl $dir/statdb_comptage.pl
perl $dir/es_entrees.pl

# On r�cup�re les logs du portail
#perl $dir/logs_portail.pl

# NOUVELLE VERSION
# On met � jour les donn�es exemplaires
perl $dir/statdb_exemplaires.pl

# On anonymise statdb
perl $dir/statdb_ano.pl

# On met � jour les index Elasticsearch
perl $dir/es_update.pl

# KIBINI2
python $dir_kib2/kibini/data_prets.py
python $dir_kib2/kibini/es_maj.py


# CHAQUE DIMANCHE
#if [ $dayofweek -eq 7 ]
#then
    # On recr�e les index items et catalogue dans ES
#    perl $dir/es_items.pl
#    bash $dir/catmandu_es.sh

#fi

# EXCEPTIONNELLEMENT LE 23/05/2017
#if [ $date == "2017-05-23" ]
#then
#    perl $dir/data_bib2.pl
#fi

# CHAQUE JOUR
# On supprime les logs crontab de plus de 30 jours
find $dir_log/crontab_lanceur_*.txt  -ctime +30 -exec rm "{}" \;
