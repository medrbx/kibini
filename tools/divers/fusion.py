#! /home/kibini/anaconda3/bin/python3

import pandas as pd

sites = ['grand-plage', 'mediatheque', 'zebre', 'collectivites' ]

support_libelles = {
    'AP' : 'Périodique - article',
    'CA' : 'Carte routière',
    'CR' : 'CD-ROM',
    'DC' : 'Disque compact',
    'DG' : 'Disque gomme-laque',
    'DV' : 'Disque microsillon',
    'IC' : 'Document iconographique',
    'JE' : 'Jeu',
    'K7' : 'Cassette audio',
    'LG' : 'Livre en gros caractères',
    'LI' : 'Livre',
    'LN' : 'Livre numérique',
    'LS' : 'Livre sonore',
    'ML' : 'Méthode de langue',
    'PA' : 'Partition',
    'PE' : 'Périodique',
    'VD' : 'DVD',
    'VI' : 'VHS, UMATIC ou film',
    'ZZ' : 'Non renseigné'
}

cols = ['collection_code_x', 'collection_lib1', 'collection_lib2', 'collection_lib3', 'collection_lib4', 'support_x', 'support_lib', 'nb_exemplaires', 'nb_exemplaires_empruntables', 'nb_exemplaires_consultables_sur_place_uniquement', 'nb_exemplaires_en_acces_libre', 'nb_exemplaires_en_acces_indirect', 'nb_exemplaires_en_commande', 'nb_exemplaires_en_traitement', 'nb_exemplaires_en_abîmés', 'nb_exemplaires_en_réparation', 'nb_exemplaires_en_retrait', 'nb_exemplaires_en_reliure', 'nb_exemplaires_perdus', 'nb_exemplaires_non_restitués', 'nb_exemplaires_créés_dans_annee', 'nb_exemplaires_éliminés', 'nb_exemplaires_éliminés_non_restitués', 'nb_exemplaires_éliminés_perdus', 'nb_exemplaires_éliminés_abîmés', 'nb_exemplaires_éliminés_désherbés', 'nb_prets_2015', 'nb_prets_2015_exemplaires_distincts', 'nb_prets_2015_emprunteurs_distincts', 'nb_prets_2016', 'nb_prets_2016_exemplaires_distincts', 'nb_prets_2016_emprunteurs_distincts', 'nb_prets_2017', 'nb_prets_2017_exemplaires_distincts', 'nb_prets_2017_emprunteurs_distincts','nb_exemplaires_empruntables_pas_empruntés_1_an', 'nb_exemplaires_empruntables_pas_empruntés_3_ans', 'nb_exemplaires_en_pret', 'Evolution prêts 2015-2016', 'Evolution prêts exemplaires distincts 2016-2017', 'Taux de rotation', 'Taux de fonds actif', 'Part collection en prêt', 'Part collection non empruntée depuis 3 ans']


cols_int = ['nb_exemplaires', 'nb_exemplaires_empruntables', 'nb_exemplaires_consultables_sur_place_uniquement', 'nb_exemplaires_en_acces_libre', 'nb_exemplaires_en_acces_indirect', 'nb_exemplaires_en_commande', 'nb_exemplaires_en_traitement', 'nb_exemplaires_en_abîmés', 'nb_exemplaires_en_réparation', 'nb_exemplaires_en_retrait', 'nb_exemplaires_en_reliure', 'nb_exemplaires_perdus', 'nb_exemplaires_non_restitués', 'nb_exemplaires_créés_dans_annee', 'nb_exemplaires_éliminés', 'nb_exemplaires_éliminés_non_restitués', 'nb_exemplaires_éliminés_perdus', 'nb_exemplaires_éliminés_abîmés', 'nb_exemplaires_éliminés_désherbés', 'nb_prets_2015', 'nb_prets_2015_exemplaires_distincts', 'nb_prets_2015_emprunteurs_distincts', 'nb_prets_2016', 'nb_prets_2016_exemplaires_distincts', 'nb_prets_2016_emprunteurs_distincts', 'nb_prets_2017', 'nb_prets_2017_exemplaires_distincts', 'nb_prets_2017_emprunteurs_distincts','nb_exemplaires_empruntables_pas_empruntés_1_an', 'nb_exemplaires_empruntables_pas_empruntés_3_ans', 'nb_exemplaires_en_pret']

colsname = {
    'collection_code_x':  'Code collection',
    'collection_lib1': 'Collection niveau 1',
    'collection_lib2': 'Collection niveau 2',
    'collection_lib3': 'Collection niveau 3',
    'collection_lib4': 'Collection niveau 4',
    'support_x': 'Code support',
    'support_lib': 'Support',
    'nb_exemplaires': 'Exemplaires',
    'nb_exemplaires_empruntables': 'Exemplaires empruntables',
    'nb_exemplaires_consultables_sur_place_uniquement': 'Exemplaires consultables sur place uniquement',
    'nb_exemplaires_en_acces_libre': 'Exemplaires en accès libre',
    'nb_exemplaires_en_acces_indirect': 'Exemplaires en accès indirect',
    'nb_exemplaires_en_commande': 'Exemplaires en commande',
    'nb_exemplaires_en_traitement': 'Exemplaires en traitement',
    'nb_exemplaires_en_abîmés': 'Exemplaires en abîmés',
    'nb_exemplaires_en_réparation': 'Exemplaires en réparation',
    'nb_exemplaires_en_retrait': 'Exemplaires en retrait',
    'nb_exemplaires_en_reliure': 'Exemplaires en reliure',
    'nb_exemplaires_perdus': 'Exemplaires perdus',
    'nb_exemplaires_non_restitués': 'Exemplaires non restitués',
    'nb_exemplaires_créés_dans_annee': 'Exemplaires créés dans l’année',
    'nb_exemplaires_éliminés': 'Exemplaires éliminés (total)',
    'nb_exemplaires_éliminés_non_restitués': 'Exemplaires éliminés non restitués',
    'nb_exemplaires_éliminés_perdus': 'Exemplaires éliminés perdus',
    'nb_exemplaires_éliminés_abîmés': 'Exemplaires éliminés abîmés',
    'nb_exemplaires_éliminés_désherbés': 'Exemplaires éliminés désherbés',
    'nb_prets_2015': 'Prêts (2015)',
    'nb_prets_2015_exemplaires_distincts': 'Prêts sur exemplaires distincts (2015)',
    'nb_prets_2015_emprunteurs_distincts': 'Prêts par emprunteurs distincts (2015)',
    'nb_prets_2016': 'Prêts (2016)',
    'nb_prets_2016_exemplaires_distincts': 'Prêts sur exemplaires distincts (2016)',
    'nb_prets_2016_emprunteurs_distincts': 'Prêts par emprunteurs distincts (2016)',
	'nb_prets_2017': 'Prêts (2017)',
    'nb_prets_2017_exemplaires_distincts': 'Prêts sur exemplaires distincts (2017)',
    'nb_prets_2017_emprunteurs_distincts': 'Prêts par emprunteurs distincts (2017)',
    'nb_exemplaires_empruntables_pas_empruntés_1_an': 'Exemplaires non empruntés depuis 1 an',
    'nb_exemplaires_empruntables_pas_empruntés_3_ans': 'Exemplaires non empruntés depuis 3 ans',
    'nb_exemplaires_en_pret': 'Exemplaires en prêt'
}

for site in sites:
    file_out = "../data/collections/res/2017_" + site + ".csv"
    
    file_ex = "../data/collections/2017_exemplaires_" + site + ".csv"
    file_el = "../data/collections/2017_eliminations_" + site + ".csv"
    file_pr = "../data/collections/2017_prets_" + site + ".csv"

    df_ex = pd.read_csv(file_ex, low_memory=False, quotechar='"')
    df_ex = df_ex.fillna('ZZ')
    df_ex['support_lib'] = df_ex['support'].map(support_libelles)
    df_ex['clé'] = df_ex['collection_code'].map(str) + df_ex['support']

    df_el = pd.read_csv(file_el, low_memory=False, quotechar='"')
    df_el = df_el.fillna('ZZ')
    df_el['clé'] = df_el['collection_code'].map(str) + df_el['support']

    df_pr = pd.read_csv(file_pr, low_memory=False, quotechar='"')
    df_pr = df_pr.fillna('ZZ')
    df_pr['clé'] = df_pr['collection_code'].map(str) + df_pr['support']

    result = pd.merge(df_ex, df_el, how='left', on='clé')
    result = pd.merge(result, df_pr, how='left', on='clé')
    result = result.fillna('0')
    
    result['Evolution prêts 2015-2016'] = pd.Series([0 for x in range(len(result.index))])
    result['Evolution prêts exemplaires distincts 2015-2016'] = pd.Series([0 for x in range(len(result.index))])
    result['Evolution prêts 2016-2017'] = pd.Series([0 for x in range(len(result.index))])
    result['Evolution prêts exemplaires distincts 2016-2017'] = pd.Series([0 for x in range(len(result.index))])
    result['Taux de rotation'] = pd.Series([0 for x in range(len(result.index))])
    result['Taux de fonds actif'] = pd.Series([0 for x in range(len(result.index))])
    result['Part collection en prêt'] = pd.Series([0 for x in range(len(result.index))])
    result['Part collection non empruntée depuis 1 an'] = pd.Series([0 for x in range(len(result.index))])
    result['Part collection non empruntée depuis 3 ans'] = pd.Series([0 for x in range(len(result.index))])
    
    result = result[cols]
    result[cols_int] = result[cols_int].astype(int)
    result = result.rename(columns=colsname)
    result.to_csv(file_out, quotechar='"', index=False)
