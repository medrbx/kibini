# à exécuter avec env conda kibini depuis la racine de kibini

import numpy as np
import pandas as pd
from os.path import join

path = "data/collections"
sites = ['grand-plage', 'mediatheque', 'zebre', 'collectivites']
year = "2021"

code_support = {
    "CA": "Carte routière",
    "K7": "Cassette audio",
    "CR": "CD-ROM",
    "DC": "Disque compact",
    "DG": "Disque gomme-laque",
    "DV": "Disque microsillon",
    "IC": "Document iconographique ",
    "VD": "DVD",
    "JE": "Jeu",
    "LI": "Livre",
    "LS": "Livre audio",
    "LG": "Livre en gros caractères",
    "LN": "Livre numérique",
    "MT": "Matériel",
    "ML": "Méthode de langue",
    "PA": "Partition",
    "PE": "Périodique",
    "AP": "Périodique - article",
    "VI": "VHS, UMATIC ou film"
}

sheets = []
for site in sites:
    print(site)
    ex = pd.read_csv(join(path, f"{year}_exemplaires_{site}.csv"))
    el = pd.read_csv(join(path, f"{year}_eliminations_{site}.csv"))
    p = pd.read_csv(join(path, f"{year}_prets_{site}.csv"))
    
    s = pd.merge(ex, el, on=['collection_code', 'support'], how='left')
    s = pd.merge(s, p, on=['collection_code', 'support'], how='left')
    sheets.append((s, site))
    
writer = pd.ExcelWriter(join(path,'2021_synthese.xlsx'), engine='xlsxwriter')
for sheet in sheets:
    df = sheet[0]
    df['support'] = df['support'].apply(lambda x: code_support[x] if x in code_support else np.nan)
    df.to_excel(writer, sheet_name=sheet[1], index=False)
writer.save()



