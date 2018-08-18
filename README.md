# Kibini

## Présentation
Kibini est une application ayant pour objectifs de :
- donner accès de manière centralisée aux données générées quotidiennement par l'activité des publics (issues de diverses sources statistiques) ; ces données chiffrées, régulièrement actualisées, n'y sont pas livrées de manière brute mais sont intégrées à des visualisations pour en faciliter la lecture et la compréhension,

- poser les bases d'une connaissance commune de l'activité globale de la structure ; chacun, en interne, peut visualiser les données afin de mieux connaître l'activité de la Grand-Plage,

- harmoniser les pratiques à l'échelle de l'établissement ; l'arborescence proposée dans l'outil structure une fois pour toutes les données de l'activité de manière cohérente. Chaque collègue ayant besoin de chiffres ou données statistiques peut ainsi travailler à partir de Kibini, référence commune,

- permettre la mise en place d'indicateurs pour une analyse fine des services ; les tableaux de bord proposés dans Kibini peuvent être retravaillés très facilement sur Kibana pour répondre à une demande précise ; Kibini est un support qui fait le lien entre la mission évaluation et les différents services évalués, dans le but d’infléchir si besoin les propositions faites par la Grand-Plage,  

- être une porte d'entrée vers l'exploration des données d'usage ; les visualisations disponibles sur Kibini ne sont qu'une sélection parmi bien d'autres possibilités de visualisations de données. Kibana permet d'aller plus loin dans l'exploration des données et donc dans l'analyse. 

## Contexte
Trois principaux éléments de contexte sont à l'origine de la mise en place de cet outil :
- la création d'une mission évaluation au sein de la Médiathèque, fin 2015, dont l'une des premières tâches a été de structurer la collecte des données d'usage,
- la mise en place d'un nouveau système d'information au sein de la Médiathèque, entre 2012 et 2015. Ce nouveau SI est basée pour l'essentiel sur des briques libres, qui générènt des logs facilement récupérables et documentés.
- l'apparition d'outils de visualtisation de données relativement simples à déployer, notamment sans connaissances techniques poussées. Plus particulièrement, la Médiathèque a fait le choix de recourir à la suite Elasticsearch / Kibana.

## Un processus en trois phases
### 1. Collecter, consolider et stocker les données d'usage

Dans un premier temps, les données d'usages sont collectées, consolidées et stockées dans une base de données unique.

La phase de collecte est automatisée ou semi-automatisée au maximum, grâce à des scripts écrits en internes afin de récupérer directement auprès des différentes briques du système d'information les données d'usages. En termes de périodicité, la collecte est effectuée soit chaque jour (prêts, réservations par exemple) ou chaque semaine (données adhérents en particulier).

Une fois collectées, les données sont consolidées, c'est-à-dire pour l'essentiel enrichies d'informations non susceptibles d'être retrouvées ultérieurement par croisement. Par exemple, les logs de prêts sont enrichis de d'informations concernant le lecteur (en particulier, age, sexe, originie géographique), i.e. de données appelées à disparaître après l'anonymisation des prêts requise par la CNIL.

Enfin, après consolidation, les données d'usages sont stockées dans une base de données unique.

Par ailleurs, certaines données non-générées par le SI peuvent être directement saisies et intégrer à la base de données via des formulaires spécifiquement créés.


### 2. Analyser les données et construire des tableaux de bord

La suite Elasticsearch / Kibana est utilisée pour l'analyse et la visualisation des données.

[Elasticsearch](https://www.elastic.co/fr/products/elasticsearch) est un moteur d'indexation textuel, basé sur Apache Lucene, qui permet également d'effectuer des regroupements et des filtrages (et donc des statistiques simples) sur d'importants jeux de données.

À chaque ajout / mise à jour de données dans la base consolidées, ces dernières sont donc parallèlement indexés dans Elasticsearch, via des scripts écrits en internes.

[Kibana](https://www.elastic.co/fr/products/kibana) est un outil d'exploration et de visualisation de données indexées dans Elasticsearch. Il permet de construire de manière intuitive des tableaux ou des visualisuations graphiques...

![Elaboration d'une visualisation](https://github.com/medrbx/kibini/blob/master/doc/kibana%20visualize%20interactif.png)

...puis de les rassembler dans des tableaux de bord.

![Elaboration d'un tableau de bord](https://github.com/medrbx/kibini/blob/master/doc/kibana%20construire%20un%20tableau%20de%20bord.png)


### 3. Diffuser les tableaux de bord
Afin de diffuser les tableaux de bord à l'ensemble du personnel de la Médiathèque, une petite application web a été mise en place. Elle permet de lever quelques difficultés :
- bien que relativement intuitif, Kibana reste une application relativement complexe, qui nécessite un certain temps d'adaptation pour le débutant,
- si Kibana rend facile la construction de tableaux de bord, il ne permet pas de les organiser (par exemple, en les rassemblant dans une arborescence),
- certains tableaux / visualisations ne peuvent être obtenus via Kibana, ils sont néanmoins réalisés ou diffusés via l'application web,
- comme indiqué dans le point consacré à la collecte des données, l'application permet enfin de saisir directement certaines données chiffrées qui ne sont pas produites par le système d'information.


#### Exemple 1 : vue d'ensemble du profil des inscrits
![Profil des inscrits](https://github.com/medrbx/kibini/blob/master/doc/tbb_inscrits.png)


#### Exemple 2 : carte des inscrits par quartier de Roubaix (taux de pénétration, que nous ne parvenons pas à générer actuellement avec Kibana 5.5)
![Carte des inscrits par quartier de Roubaix](https://github.com/medrbx/kibini/blob/master/doc/tbb%20carte%20tx%20p%C3%A9n%C3%A9tration.png)

#### Exemple 3 : formulaire de saisie de données relatives à l'action culturelle
![Formulaire de saisie de données relatives à l'action culturelle](https://github.com/medrbx/kibini/blob/master/doc/tbb%20formulaire.png)


## Bilan
### Apports
- gain de temps, notamment via l'automatisation des processus
- solution facile à utiliser,
- solution adaptable à la demande, perfectible et non figée, 

### Limites
- faible appropriation de l’outil par les collègues (liée à une faible communication),
- techniquement, tout n'est pas réalisable directement depuis Kibana (indicateur de type taux de rotation, taux de pénétration en particulier) : cela reste faisable via d'autres outils, mais demeure un peu chronophage en termes de mise en place.
