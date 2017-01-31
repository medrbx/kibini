package website::dancer ;

use Dancer2;
use FindBin qw( $Bin ) ;
use utf8 ;
# use Data::Dumper ; # pour débugage

use kibini::email ;
use collections ;
use collections::poldoc ;
use collections::details ;
use qa ;
use suggestions ;
use salleEtude::form ;
use action_culturelle ;

our $VERSION = '0.1';

# Paramètres globaux de Dancer : ceci remplace le fichier config.yaml
set appname => "Kibini - les tableaux de bord de la Grand-Plage";
set layout => "kibini";
set charset => "UTF-8";
set template => "template_toolkit";
set engines => {
   template => {
     template_toolkit => {
       start_tag => '[%',
       end_tag => '%]'
     }
   }
};

###################
# Tableaux de bord
###################

# Page d'accueil
get '/' => sub {
    template 'kibana', {
		label1 => 'Bienvenue sur Kibini',
		label2 => 'Les 30 derniers jours à La Grand Plage',
		label3 => 'Quelques chiffres',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Page-d\'accueil-:-la-semaine-derni%C3%A8re-%C3%A0-La-Grand-Plage?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-30d,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Page-d!\'accueil-:-nombre-d!\'emprunteurs-distincts\',panelIndex:1,row:7,size_x:3,size_y:2,type:visualization),(col:4,id:\'Page-d!\'accueil-:-nombre-d!\'utilisateurs-de-Webkiosk\',panelIndex:2,row:7,size_x:3,size_y:2,type:visualization),(col:4,id:\'Page-d!\'accueil-:-nombre-d!\'utilisateurs-du-service-r%C3%A9servations\',panelIndex:3,row:9,size_x:3,size_y:2,type:visualization),(col:5,id:\'Page-d!\'accueil-:-nombre-de-connexions-Webkiosk\',panelIndex:4,row:1,size_x:2,size_y:3,type:visualization),(col:1,id:\'Page-d!\'accueil-:-nombre-de-connexions-Webkiosk-par-espace\',panelIndex:5,row:11,size_x:6,size_y:3,type:visualization),(col:3,id:\'Page-d!\'accueil-:-nombre-de-pr%C3%AAts\',panelIndex:6,row:1,size_x:2,size_y:3,type:visualization),(col:1,id:\'Page-d!\'accueil-:-nombre-de-r%C3%A9servations\',panelIndex:7,row:9,size_x:3,size_y:2,type:visualization),(col:1,id:\'Page-d!\'accueil-:-nouveaux-inscrits\',panelIndex:8,row:1,size_x:2,size_y:3,type:visualization),(col:7,id:\'Page-d!\'accueil-:-nombre-de-connexions-de-Webkiosk-par-jour\',panelIndex:9,row:7,size_x:6,size_y:3,type:visualization),(col:10,id:\'Page-d!\'accueil-:-nombre-de-pr%C3%AAts-totaux-entre-18-et-19h\',panelIndex:13,row:10,size_x:3,size_y:2,type:visualization),(col:7,id:\'Page-d!\'accueil-:-nombre-de-pr%C3%AAts-totaux-entre-9-et-10h\',panelIndex:14,row:10,size_x:3,size_y:2,type:visualization),(col:10,id:\'Page-d!\'accueil-:-nombre-de-retours-totaux-entre-18-et-19h\',panelIndex:17,row:12,size_x:3,size_y:2,type:visualization),(col:7,id:\'Page-d!\'accueil-:-nombre-de-retours-totaux-entre-9-et-10h\',panelIndex:18,row:12,size_x:3,size_y:2,type:visualization),(col:1,id:\'Page-d!\'accueil-:-nombre-d!\'inscriptions-par-%C3%A2ge\',panelIndex:20,row:4,size_x:6,size_y:3,type:visualization),(col:7,id:\'Page-d!\'accueil-:-nombre-d!\'inscriptions-par-jour\',panelIndex:21,row:1,size_x:6,size_y:3,type:visualization),(col:7,id:Pr%C3%AAts-par-jour,panelIndex:22,row:4,size_x:6,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Page%20d!\'accueil%20:%20la%20semaine%20derni%C3%A8re%20%C3%A0%20La%20Grand%20Plage\',uiState:(P-20:(vis:(legendOpen:!f)),P-22:(vis:(legendOpen:!f)),P-5:(vis:(legendOpen:!f))))" height="1500" width="900"></iframe>'
	};
};

# PARTIE 1 - Grand-Plage : inscrits et collections

# Inscrits
get '/grand-plage/inscrits/mois' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Inscrits',
		label3 => 'Inscrits par mois',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Nombre-d\'inscrits-par-mois?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:5,id:\'Nombre-d!\'inscrits-par-mois\',panelIndex:1,row:1,size_x:8,size_y:4,type:visualization),(col:1,id:\'Nombre-d!\'inscrits-par-ville-et-par-mois-(en-%25)\',panelIndex:2,row:5,size_x:12,size_y:5,type:visualization),(col:1,id:\'Nombre-d!\'inscrits-par-%C3%A2ge-et-par-mois-(en-%25)\',panelIndex:3,row:10,size_x:12,size_y:5,type:visualization),(col:1,id:\'Synth%C3%A8se-tableau-:-nombre-d!\'inscrits-par-mois\',panelIndex:4,row:1,size_x:4,size_y:4,type:visualization),(col:1,id:\'Nombre-d!\'inscrits-par-type-de-carte-et-par-mois-(en-%25)\',panelIndex:5,row:15,size_x:12,size_y:5,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Nombre%20d!\'inscrits%20par%20mois\',uiState:(P-2:(vis:(legendOpen:!t)),P-3:(vis:(legendOpen:!t)),P-5:(vis:(legendOpen:!t))))" height="2200" width="900"></iframe>'
	};
};

get '/grand-plage/inscrits/nouveaux' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Inscrits',
		label3 => 'Nouveaux inscrits sur 12 mois',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Nouveaux-inscrits-sur-12-mois?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nouveaux-inscrits-par-mois,panelIndex:1,row:7,size_x:8,size_y:3,type:visualization),(col:1,id:Nouveaux-inscrits-par-semaine,panelIndex:2,row:10,size_x:8,size_y:3,type:visualization),(col:1,id:Nouveaux-inscrits-sur-12-mois,panelIndex:3,row:1,size_x:4,size_y:2,type:visualization),(col:9,id:\'Tableaux-:-nouveaux-inscrits-par-mois\',panelIndex:4,row:7,size_x:4,size_y:3,type:visualization),(col:9,id:\'Tableau-:-nouveaux-inscrits-par-semaine\',panelIndex:5,row:10,size_x:4,size_y:3,type:visualization),(col:5,id:Nouveaux-inscrits-par-ville,panelIndex:9,row:3,size_x:4,size_y:4,type:visualization),(col:1,id:Nouveaux-inscrits-par-%C3%A2ge,panelIndex:10,row:3,size_x:4,size_y:4,type:visualization),(col:9,id:Nouveaux-inscrits-par-type-de-carte,panelIndex:11,row:3,size_x:4,size_y:4,type:visualization),(col:1,id:Nouveaux-inscrits-par-mois-et-par-type-de-carte,panelIndex:12,row:13,size_x:12,size_y:4,type:visualization),(col:1,id:Nouveaux-inscrits-par-mois-et-par-%C3%A2ge,panelIndex:13,row:17,size_x:12,size_y:4,type:visualization),(col:5,id:Nouveaux-inscrits-questionmark-,panelIndex:14,row:1,size_x:8,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Nouveaux%20inscrits%20sur%2012%20mois\',uiState:(P-10:(vis:(legendOpen:!f)),P-11:(vis:(legendOpen:!f)),P-9:(vis:(legendOpen:!f))))" height="2300" width="900"></iframe>'
	};
};

get '/grand-plage/inscrits/ensemble' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Inscrits',
		label3 => 'Inscrits et actifs',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_D%C3%A9tails-actifs-roubaisiens-ext%C3%A9rieurs?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-20y%2Fy,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:4,id:Un-actif-questionmark-,panelIndex:32,row:1,size_x:6,size_y:2,type:visualization),(col:1,id:Inscrits-totaux,panelIndex:43,row:1,size_x:3,size_y:2,type:visualization),(col:10,id:Inscrits-actifs,panelIndex:44,row:1,size_x:3,size_y:2,type:visualization),(col:4,id:\'Inscrits-totaux-:-Personnes-physiques-slash-Collectivit%C3%A9s\',panelIndex:45,row:3,size_x:6,size_y:4,type:visualization),(col:1,id:Inscrits-roubaisiens,panelIndex:46,row:3,size_x:3,size_y:2,type:visualization),(col:10,id:Inscrits-actifs-roubaisiens,panelIndex:47,row:3,size_x:3,size_y:2,type:visualization),(col:1,id:Inscrits-ext%C3%A9rieurs,panelIndex:48,row:5,size_x:3,size_y:2,type:visualization),(col:10,id:Inscrits-actifs-ext%C3%A9rieurs,panelIndex:49,row:5,size_x:3,size_y:2,type:visualization),(col:5,id:Inscrits-roubaisiens-emprunteurs,panelIndex:52,row:7,size_x:4,size_y:2,type:visualization),(col:9,id:Inscrits-ext%C3%A9rieurs-emprunteurs,panelIndex:53,row:7,size_x:4,size_y:2,type:visualization),(col:9,id:Utilisateurs-Webkiosk-ext%C3%A9rieurs,panelIndex:55,row:9,size_x:4,size_y:2,type:visualization),(col:1,id:Inscrits-emprunteurs,panelIndex:56,row:7,size_x:4,size_y:2,type:visualization),(col:1,id:Utilisateurs-Webkiosk-totaux,panelIndex:57,row:9,size_x:4,size_y:2,type:visualization),(col:5,id:Utilisateurs-Webkiosk-roubaisiens,panelIndex:58,row:9,size_x:4,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'A_D%C3%A9tails%20actifs%20roubaisiens%20ext%C3%A9rieurs\',uiState:(P-44:(spy:(mode:(fill:!f,name:!n))),P-45:(spy:(mode:(fill:!f,name:!n)))))" height="1200" width="900"></iframe>'
	};
};



get '/grand-plage/inscrits/age' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Inscrits',
		label3 => 'Inscrits par âge',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_Inscrits-roubaisiens-et-ext%C3%A9rieurs-par-%C3%A2ge?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-11y%2Fy,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Inscrits-ext%C3%A9rieurs-par-%C3%A2ge-(d%C3%A9tails)\',panelIndex:5,row:7,size_x:9,size_y:3,type:visualization),(col:1,id:\'Inscrits-roubaisiens-par-%C3%A2ge-(d%C3%A9tails)\',panelIndex:7,row:10,size_x:9,size_y:3,type:visualization),(col:9,id:Inscrits-roubaisiens-par-%C3%A2ge,panelIndex:8,row:1,size_x:4,size_y:3,type:visualization),(col:5,id:Inscrits-ext%C3%A9rieurs-par-%C3%A2ge,panelIndex:9,row:1,size_x:4,size_y:3,type:visualization),(col:1,id:\'Inscrits-totaux-par-%C3%A2ge-(d%C3%A9tails)\',panelIndex:10,row:4,size_x:9,size_y:3,type:visualization),(col:1,id:Inscrits-totaux-par-%C3%A2ge,panelIndex:11,row:1,size_x:4,size_y:3,type:visualization),(col:10,id:Tableau-inscrits-ext%C3%A9rieurs-par-%C3%A2ge,panelIndex:12,row:7,size_x:3,size_y:3,type:visualization),(col:10,id:Tableau-inscrits-roubaisiens-par-%C3%A2ge,panelIndex:13,row:10,size_x:3,size_y:3,type:visualization),(col:10,id:Tableau-inscrits-totaux-par-%C3%A2ge,panelIndex:14,row:4,size_x:3,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'A_Inscrits%20roubaisiens%20et%20ext%C3%A9rieurs%20par%20%C3%A2ge\',uiState:(P-10:(vis:(colors:(Count:%23447EBC),legendOpen:!f)),P-11:(vis:(colors:(\'15%20ans%20et%20plus\':%23447EBC,\'%3C%3D%2014%20ans\':%2370DBED),legendOpen:!f)),P-5:(vis:(colors:(Count:%23BF1B00,\'Nombre%20d!\'inscrits\':%23BF1B00,emprunteur:%23890F02,non_emprunteur:%23F29191),legendOpen:!f)),P-7:(vis:(colors:(\'Nombre%20d!\'inscrits\':%23629E51,\'Nombre%20d!\'inscrits%20roubaisiens\':%239AC48A,emprunteur:%23508642,non_emprunteur:%23B7DBAB),legendOpen:!f)),P-8:(vis:(colors:(\'15%20ans%20et%20plus\':%23508642,\'%3C%3D%2014%20ans\':%23B7DBAB),legendOpen:!f)),P-9:(vis:(colors:(\'15%20ans%20et%20plus\':%23BF1B00,\'%3C%3D%2014%20ans\':%23F29191),legendOpen:!f))))" height="1400" width="900"></iframe>'
	};
};

get '/grand-plage/inscrits/carte' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Inscrits',
		label3 => 'Inscrits par type de carte',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_Inscrits-par-types-de-carte?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-11y%2Fy,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:7,id:\'Tableau-nombre-d!\'inscrits-par-type-de-carte\',panelIndex:22,row:1,size_x:6,size_y:3,type:visualization),(col:1,id:Inscrits-roubaisiens-par-type-de-carte,panelIndex:23,row:4,size_x:6,size_y:3,type:visualization),(col:7,id:Inscrits-ext%C3%A9rieurs-par-type-de-carte,panelIndex:24,row:4,size_x:6,size_y:3,type:visualization),(col:1,id:Inscrits-totaux-par-type-de-carte,panelIndex:25,row:1,size_x:6,size_y:3,type:visualization),(col:1,id:\'Cartes-M%C3%A9diath%C3%A8que-:-provenance-par-ville\',panelIndex:30,row:7,size_x:6,size_y:3,type:visualization),(col:7,id:\'Cartes-M%C3%A9diath%C3%A8que-Plus-:-provenance-par-ville\',panelIndex:31,row:7,size_x:6,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'A_Inscrits%20par%20types%20de%20carte\',uiState:(P-24:(vis:(colors:(\'Consultation%20sur%20place\':%23F29191,M%C3%A9diath%C3%A8que:%23E24D42,\'M%C3%A9diath%C3%A8que%20Plus\':%23890F02),legendOpen:!t))))" height="1050" width="900"></iframe>'
	};
};

get '/grand-plage/inscrits/villes' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Inscrits',
		label3 => 'Inscrits par villes et quartiers',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_Inscrits-villes-et-quartiers?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-11y%2Fy,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'15-villes\',panelIndex:12,row:3,size_x:4,size_y:2,type:visualization),(col:5,id:Inscrits-ext%C3%A9rieurs-par-ville,panelIndex:17,row:4,size_x:8,size_y:3,type:visualization),(col:1,id:Inscrits-roubaisiens,panelIndex:18,row:1,size_x:4,size_y:2,type:visualization),(col:1,id:Inscrits-ext%C3%A9rieurs,panelIndex:19,row:5,size_x:4,size_y:2,type:visualization),(col:5,id:Inscrits-roubaisiens-par-quartier,panelIndex:20,row:1,size_x:8,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'A_Inscrits%20villes%20et%20quartiers\',uiState:(P-17:(vis:(colors:(Count:%23BF1B00,\'Nombre%20d!\'inscrits\':%23890F02),legendOpen:!f)),P-20:(vis:(colors:(\'Nombre%20d!\'inscrits\':%237EB26D),legendOpen:!f)),P-9:(vis:(colors:(emprunteur:%23508642,non_emprunteur:%23B7DBAB)))))" height="700" width="900"></iframe>'
	};
};

get '/grand-plage/inscrits/quartiers' => sub {
	template 'carte', {
		label1 => 'La Grand-Plage',
		label2 => 'Inscrits',
		label3 => "Taux d'inscription par quartier de Roubaix"
	};
};

# Collections
get '/grand-plage/collections/details' => sub {
	my $indicateurs = dataCollections(0) ;	
	template 'collections', {
		label1 => 'La Grand-Plage',
		label2 => 'Collections',
		label3 => 'Principaux indicateurs sur 12 mois',
		indicateurs => $indicateurs
	};
};

get '/grand-plage/collections/prets' => sub {
        template 'kibana', {
                label1 => 'La Grand-Plage',
                label2 => 'Collections',
                label3 => 'Prêts',
                iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Pr%C3%AAts-Grand-Plage?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-pr%C3%AAts,panelIndex:15,row:1,size_x:6,size_y:2,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-collection,panelIndex:24,row:3,size_x:12,size_y:9,type:visualization),(col:7,id:\'Nombre-d!\'emprunteurs-totaux\',panelIndex:25,row:1,size_x:6,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Pr%C3%AAts%20Grand%20Plage\',uiState:())" height="1400" width="900"></iframe>'
        };
};

get '/grand-plage/collections/collection' => sub {
        template 'poldoc_collection_choose', {
                label1 => 'La Grand-Plage',
                label2 => 'Collections',
                label3 => 'Détail par collection'
        };
};

get '/grand-plage/collections/collection/details' => sub {
		my $ccode = params->{'ccode'} ;
		my $site = params->{'site'} ;
		my $collection = GetCcodeDetails($ccode, $site) ;
		my $ccodesLib = GetCcode() ;
		my $lib_ccode = GetLibAV( $ccode, 'COLLECTION' ) ;
        template 'poldoc_collection', {
                label1 => 'La Grand-Plage',
                label2 => 'Collections',
                label3 => 'Détail par collection',
				ccodesLib => $ccodesLib,
				ccode => $lib_ccode,
				collection => $collection
        };
};

# Web
get '/grand-plage/web/connexions' => sub {
        template 'kibana', {
                label1 => 'La Grand-Plage',
                label2 => 'Sites web',
                label3 => "Sessions de consultation de la bn-r et du portail",
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Web-:-sessions?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:\'2008-01-01T12:22:52.804Z\',mode:quick,to:\'2016-05-19T11:22:52.804Z\'))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Web-:-sessions-par-ann%C3%A9e\',panelIndex:1,row:1,size_x:12,size_y:5,type:visualization),(col:1,id:\'Web-:-sessions-par-mois\',panelIndex:2,row:6,size_x:12,size_y:5,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Web%20:%20sessions\',uiState:(P-1:(vis:(legendOpen:!f)),P-2:(vis:(legendOpen:!f))))" height="1200" width="900"></iframe>'
        };

};


# PARTIE 2 - La Médiathèque : activités et usages

# Fréquentation
get '/mediatheque/frequentation/entrees' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Fréquentation',
		label3 => 'Entrées',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Entr%C3%A9es-%C3%A0-la-m%C3%A9diath%C3%A8que?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-10M,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Nombre-d!\'entr%C3%A9es-par-mois\',panelIndex:5,row:4,size_x:8,size_y:2,type:visualization),(col:1,id:\'Nombre-d!\'entr%C3%A9es-par-semaine\',panelIndex:6,row:6,size_x:8,size_y:2,type:visualization),(col:9,id:\'Tableau-nombre-d!\'entr%C3%A9es-par-semaine\',panelIndex:8,row:4,size_x:4,size_y:2,type:visualization),(col:7,id:\'Nombre-d!\'entr%C3%A9es-par-heure\',panelIndex:10,row:1,size_x:6,size_y:3,type:visualization),(col:9,id:\'Tableau-nombre-d!\'entr%C3%A9es-par-mois\',panelIndex:11,row:6,size_x:4,size_y:2,type:visualization),(col:1,id:\'Nombre-d!\'entr%C3%A9es-par-jour-de-la-semaine\',panelIndex:12,row:1,size_x:6,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Entr%C3%A9es%20%C3%A0%20la%20m%C3%A9diath%C3%A8que\',uiState:(P-10:(vis:(legendOpen:!f)),P-5:(vis:(colors:(\'Sum%20of%20nb_entrees\':%237EB26D),legendOpen:!f)),P-6:(vis:(legendOpen:!f))))" height="800" width="900"></iframe>'
	};
};

get '/mediatheque/frequentation/espaces' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Fréquentation',
		label3 => 'Espaces',
        iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Fr%C3%A9quentation-des-espaces?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-15m,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Semaine-test-1,panelIndex:1,row:8,size_x:12,size_y:4,type:visualization),(col:1,id:Semaine-test-1-Assis-debout,panelIndex:2,row:12,size_x:12,size_y:4,type:visualization),(col:1,id:Semaine-test-3,panelIndex:4,row:20,size_x:12,size_y:4,type:visualization),(col:1,id:Semaine-test-3-Espace,panelIndex:5,row:24,size_x:12,size_y:4,type:visualization),(col:1,id:Semaine-test-4,panelIndex:6,row:36,size_x:12,size_y:4,type:visualization),(col:1,id:Semaine-test-4-Assis-debout,panelIndex:7,row:44,size_x:12,size_y:4,type:visualization),(col:1,id:Semaine-test-4-Espace,panelIndex:8,row:40,size_x:12,size_y:4,type:visualization),(col:1,id:Semaine-test-3-Assis-debout,panelIndex:9,row:28,size_x:12,size_y:4,type:visualization),(col:8,id:Les-semaines-test-%C3%A0-La-Grand-Plage,panelIndex:11,row:1,size_x:5,size_y:3,type:visualization),(col:1,id:Semaine-test-1-Espace,panelIndex:12,row:4,size_x:12,size_y:4,type:visualization),(col:1,id:Semaine-test-1-nombre-de-personnes-par-jour,panelIndex:13,row:16,size_x:6,size_y:4,type:visualization),(col:1,id:Semaine-test-2-nombre-de-personnes-par-jour,panelIndex:14,row:32,size_x:6,size_y:4,type:visualization),(col:1,id:Semaine-test-4-nombre-de-personnes-par-jour,panelIndex:15,row:48,size_x:6,size_y:4,type:visualization),(col:1,id:\'Qu!\'est-ce-qu!\'une-semaine-test-questionmark-\',panelIndex:16,row:1,size_x:7,size_y:3,type:visualization),(col:7,id:\'ST1-:-d%C3%A9tails\',panelIndex:17,row:16,size_x:6,size_y:4,type:visualization),(col:7,id:\'ST2-:-d%C3%A9tails\',panelIndex:18,row:32,size_x:6,size_y:4,type:visualization),(col:7,id:\'ST3-:-d%C3%A9tails\',panelIndex:19,row:48,size_x:6,size_y:4,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'NOT%20%22Salle%20multim%C3%A9dia%22\')),title:\'Fr%C3%A9quentation%20des%20espaces\',uiState:(P-1:(vis:(legendOpen:!t)),P-12:(vis:(legendOpen:!t)),P-2:(vis:(legendOpen:!t)),P-4:(vis:(legendOpen:!t)),P-5:(vis:(legendOpen:!t)),P-6:(vis:(legendOpen:!t)),P-7:(vis:(legendOpen:!t)),P-8:(vis:(legendOpen:!t)),P-9:(vis:(legendOpen:!t))))" height="5800" width="900"></iframe>'
	};
};

# Usages des collections
get '/mediatheque/collections/ensemble' => sub {
	my $indicateurs = dataCollections(1) ;	
	template 'collections', {
		label1 => 'Médiathèque',
		label2 => 'Collections',
		label3 => 'Principaux indicateurs sur 12 mois',
		indicateurs => $indicateurs
	};
};

get '/mediatheque/collections/emprunteurs' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Collections',
		label3 => 'Profil des emprunteurs',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Profil-emprunteurs-m%C3%A9diath%C3%A8que?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:4,id:Emprunteurs-distincts-M%C3%A9diath%C3%A8que,panelIndex:1,row:1,size_x:9,size_y:3,type:visualization),(col:1,id:Emprunteurs-distincts-par-carte-m%C3%A9diath%C3%A8que,panelIndex:2,row:4,size_x:6,size_y:4,type:visualization),(col:7,id:Emprunteurs-distincts-par-%C3%A2ge-m%C3%A9diath%C3%A8que,panelIndex:3,row:4,size_x:6,size_y:4,type:visualization),(col:1,id:\'Nombre-d!\'emprunteurs\',panelIndex:4,row:1,size_x:3,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'pret_site:%20%22M%C3%A9diath%C3%A8que%22\')),title:\'Profil%20emprunteurs%20m%C3%A9diath%C3%A8que\',uiState:())" height="900" width="900"></iframe>'
	};
};

get '/mediatheque/collections/prets/totaux' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Collections',
		label3 => 'Prêts sur 12 mois',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_Pr%C3%AAts-(par-collection)?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-pr%C3%AAts,panelIndex:15,row:1,size_x:6,size_y:2,type:visualization),(col:7,id:\'Nombre-d!\'emprunteurs-%C3%A0-la-m%C3%A9diath%C3%A8que\',panelIndex:23,row:1,size_x:6,size_y:2,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-collection,panelIndex:24,row:3,size_x:12,size_y:9,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'Personne%20AND%20pret_site:%20%22M%C3%A9diath%C3%A8que%22\')),title:\'A_Pr%C3%AAts%20(par%20collection)\',uiState:())" height="1300" width="900"></iframe>'
	};
};

get '/mediatheque/collections/prets/details' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Collections',
		label3 => 'Prêts par semaine et par mois',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_Pr%C3%AAts-par-collection-(d%C3%A9tails)?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-pr%C3%AAts-par-mois,panelIndex:1,row:4,size_x:8,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-semaine,panelIndex:2,row:1,size_x:8,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-et-par-collection-1,panelIndex:4,row:7,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-et-support,panelIndex:5,row:19,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-jeunesse-par-mois-et-par-collection,panelIndex:6,row:10,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-adultes-par-mois-et-par-collection,panelIndex:7,row:13,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-patrimoine-par-mois-et-par-collection,panelIndex:8,row:16,size_x:12,size_y:3,type:visualization),(col:9,id:Tableau-nombre-de-pr%C3%AAts,panelIndex:9,row:1,size_x:4,size_y:3,type:visualization),(col:9,id:Tableau-nombre-de-pr%C3%AAts-par-mois,panelIndex:10,row:4,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'personne%20AND%20pret_site:%20%22M%C3%A9diath%C3%A8que%22\')),title:\'A_Pr%C3%AAts%20par%20collection%20(d%C3%A9tails)\',uiState:(P-1:(vis:(legendOpen:!f)),P-2:(spy:(mode:(fill:!f,name:!n)),vis:(legendOpen:!f))))" height="2350" width="900"></iframe>'
	};
};
get '/mediatheque/collections/transactions' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Collections',
		label3 => 'Transactions par heures et espaces',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_Pr%C3%AAts-et-retours-(bornes-m%C3%A9diath%C3%A8que)?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now%2Fy,mode:quick,to:now%2Fy))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Bornes-RFID-:-pr%C3%AAts-par-jour-de-la-semaine\',panelIndex:5,row:1,size_x:4,size_y:3,type:visualization),(col:1,id:\'Bornes-RFID-:-retours-par-jour-de-la-semaine\',panelIndex:6,row:7,size_x:4,size_y:3,type:visualization),(col:5,id:\'Bornes-RFID-:-retours-par-heure-selon-les-jours-de-la-semaine\',panelIndex:7,row:7,size_x:8,size_y:6,type:visualization),(col:5,id:\'Bornes-RFID-:-pr%C3%AAts-par-heure-selon-les-jours-de-la-semaine\',panelIndex:8,row:1,size_x:8,size_y:6,type:visualization),(col:1,id:\'Bornes-RFID-:-pr%C3%AAts-par-%C3%A9tage\',panelIndex:9,row:4,size_x:4,size_y:3,type:visualization),(col:1,id:\'Bornes-RFID-:-retours-par-%C3%A9tage\',panelIndex:10,row:10,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'A_Pr%C3%AAts%20et%20retours%20(bornes%20m%C3%A9diath%C3%A8que)\',uiState:(P-10:(vis:(legendOpen:!f)),P-5:(vis:(legendOpen:!f)),P-6:(vis:(colors:(\'1%20Lundi\':%23F29191),legendOpen:!f)),P-7:(vis:(legendOpen:!f)),P-8:(vis:(legendOpen:!f)),P-9:(vis:(legendOpen:!f))))" height="1350" width="900"></iframe>'
	};
};

get '/mediatheque/collections/reservations' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Collections',
		label3 => 'Nombre de réservations',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_R%C3%A9servations?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:9,id:R%C3%A9servations-par-statut,panelIndex:31,row:4,size_x:4,size_y:3,type:visualization),(col:1,id:R%C3%A9servations-par-espace,panelIndex:32,row:4,size_x:4,size_y:3,type:visualization),(col:5,id:R%C3%A9servations-par-support,panelIndex:35,row:4,size_x:4,size_y:3,type:visualization),(col:1,id:R%C3%A9servations-par-collection,panelIndex:36,row:7,size_x:12,size_y:8,type:visualization),(col:1,id:R%C3%A9servations-totales-par-mois,panelIndex:39,row:1,size_x:8,size_y:3,type:visualization),(col:9,id:Tableau-R%C3%A9servations-par-mois,panelIndex:40,row:1,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:A_R%C3%A9servations,uiState:(P-31:(vis:(legendOpen:!f)),P-32:(spy:(mode:(fill:!f,name:!n)),vis:(legendOpen:!f)),P-35:(vis:(legendOpen:!f)),P-37:(vis:(legendOpen:!f)),P-39:(vis:(legendOpen:!f))))" height="1600" width="900"></iframe>'
	};
};

get '/mediatheque/collections/reservations/utilisateurs' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Collections',
		label3 => 'Profil des utilisateurs du service réservations',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Profil-des-utilisateurs-du-service-r%C3%A9servations?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:5,id:\'Nombre-d!\'utilisateurs-du-service-r%C3%A9servations-par-type-de-carte\',panelIndex:4,row:5,size_x:4,size_y:4,type:visualization),(col:9,id:\'Nombre-d!\'utilisateurs-du-service-r%C3%A9servations-par-ville\',panelIndex:6,row:5,size_x:4,size_y:4,type:visualization),(col:1,id:\'Nombre-d!\'utilisateurs-du-service-r%C3%A9servations-par-mois\',panelIndex:7,row:1,size_x:8,size_y:4,type:visualization),(col:1,id:R%C3%A9partitions-par-%C3%A2ge,panelIndex:9,row:5,size_x:4,size_y:4,type:visualization),(col:9,id:\'Tableau-nombre-d!\'utilisateurs-distincts-par-mois\',panelIndex:10,row:1,size_x:4,size_y:4,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Profil%20des%20utilisateurs%20du%20service%20r%C3%A9servations\',uiState:(P-4:(vis:(legendOpen:!f)),P-6:(vis:(legendOpen:!f)),P-7:(vis:(legendOpen:!f)),P-9:(vis:(legendOpen:!f))))" height="1000" width="900"></iframe>'
	};
};

# Postes informatiques
get '/mediatheque/postes/utilisateurs' => sub {
	template 'kibana', {
		label1 => 'La Médiathèque',
		label2 => 'Postes informatiques',
		label3 => 'Profil des utilisateurs',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Utilisateurs-de-Webkiosk?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:9,id:Utilisateurs-Webkiosk-par-%C3%A2ge,panelIndex:25,row:4,size_x:4,size_y:4,type:visualization),(col:1,id:Utilisateurs-Webkiosk-par-carte,panelIndex:26,row:4,size_x:4,size_y:4,type:visualization),(col:5,id:Utilisateurs-Webkiosk-par-quartier-de-Roubaix,panelIndex:27,row:4,size_x:4,size_y:4,type:visualization),(col:1,id:\'Nombre-d!\'utilisateurs-distincts-par-mois\',panelIndex:28,row:1,size_x:9,size_y:3,type:visualization),(col:10,id:\'Tableau-nombre-d!\'usagers-distincts-sur-Webkiosk-par-mois\',panelIndex:29,row:1,size_x:3,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Utilisateurs%20de%20Webkiosk\',uiState:(P-25:(vis:(legendOpen:!f)),P-26:(vis:(legendOpen:!f)),P-27:(vis:(legendOpen:!f)),P-28:(vis:(legendOpen:!f))))" height="800" width="900"></iframe>'
	};
};
get '/mediatheque/postes/connexions' => sub {
	template 'kibana', {
		label1 => 'La médiathèque',
		label2 => 'Postes informatiques',
		label3 => 'Connexions par espace',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Connexions-Webkiosk?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Connexions-Webkiosk-par-espace,panelIndex:1,row:1,size_x:4,size_y:3,type:visualization),(col:1,id:Connexions-Webkiosk-nombre-de-connexions-par-mois,panelIndex:8,row:4,size_x:12,size_y:3,type:visualization),(col:1,id:Connexions-Webkiosk-par-mois-et-par-espace,panelIndex:12,row:7,size_x:12,size_y:3,type:visualization),(col:9,id:Tableau-nombre-de-connexions-sur-Webkiosk-par-mois,panelIndex:13,row:1,size_x:4,size_y:3,type:visualization),(col:5,id:R%C3%A9partition-des-ordinateurs,panelIndex:14,row:1,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Connexions%20Webkiosk\',uiState:(P-1:(vis:(legendOpen:!f)),P-12:(vis:(legendOpen:!t)),P-8:(vis:(legendOpen:!f))))" height="1050" width="900"></iframe>'
	}; 
};

# PARTIE 3 - Le Zèbre : activités et usages

get '/zebre/collections/ensemble' => sub {
	my $indicateurs = dataCollections(2) ;	
	template 'collections', {
		label1 => 'Le Zèbre',
		label2 => 'Collections',
		label3 => 'Principaux indicateurs sur 12 mois',
		indicateurs => $indicateurs
	};
};

get '/zebre/collections/emprunteurs' => sub {
	template 'kibana', {
		label1 => 'Le Zèbre',
		label2 => 'Collections',
		label3 => 'Profil des emprunteurs',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Profil-emprunteurs-Z%C3%A8bre?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Emprunteurs-distincts-par-mois,panelIndex:5,row:1,size_x:9,size_y:3,type:visualization),(col:1,id:Emprunteurs-distincts-par-carte-Z%C3%A8bre,panelIndex:7,row:4,size_x:4,size_y:4,type:visualization),(col:5,id:Emprunteurs-distincts-par-%C3%A2ge-Z%C3%A8bre,panelIndex:8,row:4,size_x:4,size_y:4,type:visualization),(col:9,id:Emprunteurs-distincts-par-quartier-de-Roubaix-Z%C3%A8bre,panelIndex:9,row:4,size_x:4,size_y:4,type:visualization),(col:10,id:\'Nombre-d!\'emprunteurs-Z%C3%A8bre\',panelIndex:10,row:1,size_x:3,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'pret_site:%20%22Z%C3%A8bre%22\')),title:\'Profil%20emprunteurs%20Z%C3%A8bre\',uiState:(P-7:(vis:(legendOpen:!f)),P-8:(vis:(legendOpen:!f)),P-9:(vis:(legendOpen:!f))))" height="900" width="900"></iframe>'
	};
};

get '/zebre/collections/prets/totaux' => sub {
	template 'kibana', {
		label1 => 'Le Zèbre',
		label2 => 'Collections',
		label3 => 'Prêts sur 12 mois',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Pr%C3%AAts-Z%C3%A8bre-sur-12-mois?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-pr%C3%AAts,panelIndex:15,row:1,size_x:6,size_y:2,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-collection,panelIndex:24,row:3,size_x:12,size_y:9,type:visualization),(col:7,id:\'Nombre-d!\'emprunteurs-distincts-Z%C3%A8bre\',panelIndex:25,row:1,size_x:6,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'Personne%20AND%20pret_site:%20%22Z%C3%A8bre%22\')),title:\'Pr%C3%AAts%20Z%C3%A8bre%20sur%2012%20mois\',uiState:())" height="1300" width="900"></iframe>'
	};
};

get '/zebre/collections/prets/details' => sub {
	template 'kibana', {
		label1 => 'Le Zèbre',
		label2 => 'Collections',
		label3 => 'Prêts par semaine et par mois',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Pr%C3%AAts-Z%C3%A8bre-par-mois-et-semaine?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:9,id:Nombre-de-pr%C3%AAts-Z%C3%A8bre,panelIndex:1,row:4,size_x:4,size_y:3,type:visualization),(col:9,id:Nombre-de-pr%C3%AAts-par-semaine-Z%C3%A8bre,panelIndex:2,row:1,size_x:4,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-Z%C3%A8bre,panelIndex:3,row:4,size_x:8,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-semaine-Z%C3%A8bre,panelIndex:4,row:1,size_x:8,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-adultes-par-mois-et-par-collection-Z%C3%A8bre,panelIndex:5,row:10,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-jeunesse-par-mois-et-par-collection-Z%C3%A8bre,panelIndex:6,row:13,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-et-par-collection-Z%C3%A8bre,panelIndex:7,row:7,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-et-support-Z%C3%A8bre,panelIndex:8,row:19,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-patrimoine-par-mois-et-par-collection-Z%C3%A8bre,panelIndex:9,row:16,size_x:12,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Pr%C3%AAts%20Z%C3%A8bre%20par%20mois%20et%20semaine\',uiState:())" height="2350" width="900"></iframe>'
	};
};

get '/zebre/collections/transactions' => sub {
	template 'kibana', {
		label1 => 'Le Zèbre',
		label2 => 'Collections',
		label3 => 'Transactions par arrêts',
		iframe => "Amélie s'en charge vite vite vite..."
	};
};

get '/zebre/collections/reservations' => sub {
	template 'kibana', {
		label1 => 'Le Zèbre',
		label2 => 'Collections',
		label3 => 'Réservations',
                iframe => "Amélie s'en charge vite vite vite..."
	};
};


# PARTIE 4 - Le service Collectivités : activités et usages

get '/collectivites/collections/ensemble' => sub {
	my $indicateurs = dataCollections(3) ;	
	template 'collections', {
		label1 => 'Collectivités',
		label2 => 'Collections',
		label3 => 'Principaux indicateurs sur 12 mois',
		indicateurs => $indicateurs
	};
};

get '/collectivites/collections/emprunteurs' => sub {
	template 'kibana', {
		label1 => 'Collectivités',
		label2 => 'Collections',
		label3 => 'Profil des emprunteurs',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Profil-emprunteurs-Collectivit%C3%A9s?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:5,id:Emprunteurs-distincts-Collectivit%C3%A9s,panelIndex:10,row:1,size_x:8,size_y:5,type:visualization),(col:1,id:\'Nombre-d!\'emprunteurs-Collectivit%C3%A9s\',panelIndex:11,row:1,size_x:4,size_y:2,type:visualization),(col:1,id:Emprunteurs-distincts-par-carte-Collectivit%C3%A9s,panelIndex:12,row:3,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'emprunteur_personnalite:%20%22Collectivit%C3%A9%22\')),title:\'Profil%20emprunteurs%20Collectivit%C3%A9s\',uiState:(P-12:(vis:(legendOpen:!f))))" height="600" width="900"></iframe>'
	};
};

get '/collectivites/collections/prets/totaux' => sub {
	template 'kibana', {
		label1 => 'Collectivités',
		label2 => 'Collections',
		label3 => 'Prêts sur 12 mois',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_Pr%C3%AAts-totaux-collectivit%C3%A9s-(par-collection)?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-pr%C3%AAts-collectivit%C3%A9s,panelIndex:18,row:1,size_x:6,size_y:2,type:visualization),(col:7,id:\'Nombre-d!\'emprunteurs-totaux-Collectivit%C3%A9s\',panelIndex:19,row:1,size_x:6,size_y:2,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-collection-collectivit%C3%A9s,panelIndex:20,row:3,size_x:12,size_y:7,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'emprunteur_personnalite:%20%22Collectivit%C3%A9%22\')),title:\'A_Pr%C3%AAts%20totaux%20collectivit%C3%A9s%20(par%20collection)\',uiState:())" height="1300" width="900"></iframe>'
	};
};

get '/collectivites/collections/prets/details' => sub {
	template 'kibana', {
		label1 => 'Collectivités',
		label2 => 'Collections',
		label3 => 'Prêts par semaine et par mois',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/A_Pr%C3%AAts-par-collection-collectivit%C3%A9s-(d%C3%A9tails)?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-pr%C3%AAts-par-mois,panelIndex:1,row:4,size_x:8,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-semaine,panelIndex:2,row:1,size_x:8,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-et-par-collection-1,panelIndex:4,row:7,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-et-support,panelIndex:5,row:19,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-jeunesse-par-mois-et-par-collection,panelIndex:6,row:10,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-adultes-par-mois-et-par-collection,panelIndex:7,row:13,size_x:12,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-patrimoine-par-mois-et-par-collection,panelIndex:8,row:16,size_x:12,size_y:3,type:visualization),(col:9,id:Tableau-nombre-de-pr%C3%AAts,panelIndex:9,row:1,size_x:4,size_y:3,type:visualization),(col:9,id:Tableau-nombre-de-pr%C3%AAts-par-mois,panelIndex:10,row:4,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'emprunteur_personnalite:%20%22Collectivit%C3%A9%22\')),title:\'A_Pr%C3%AAts%20par%20collection%20collectivit%C3%A9s%20(d%C3%A9tails)\',uiState:(P-1:(vis:(legendOpen:!f)),P-2:(spy:(mode:(fill:!f,name:!n)),vis:(legendOpen:!f))))" height="2350" width="900"></iframe>'
	};
};

# PARTIE 5 - La Grand-Plage : synthèses pluriannuelles

get '/grand-plage/syntheses/inscrits' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Synthèses',
		label3 => 'Inscrits',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Synth%C3%A8se-:-nombre-d\'inscrits?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-16y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:5,id:Synth%C3%A8se-Inscrits,panelIndex:1,row:1,size_x:8,size_y:4,type:visualization),(col:1,id:\'Synth%C3%A8se-tableau-:-nombre-d!\'inscrits-par-ann%C3%A9e\',panelIndex:3,row:1,size_x:4,size_y:4,type:visualization),(col:1,id:\'Synth%C3%A8se-Inscrits-par-type-de-carte-(en-%25)\',panelIndex:5,row:5,size_x:12,size_y:4,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Synth%C3%A8se%20:%20nombre%20d!\'inscrits\',uiState:(P-5:(vis:(legendOpen:!t))))" height="900" width="900"></iframe>'
	};
};

get '/grand-plage/syntheses/collections' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Synthèses',
		label3 => 'Collections',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Synth%C3%A8se-:-nombre-de-documents?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-18y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:4,id:Synth%C3%A8se-Documents,panelIndex:1,row:1,size_x:9,size_y:4,type:visualization),(col:1,id:\'Synth%C3%A8se-tableau-:-nombre-de-documents-par-ann%C3%A9e\',panelIndex:3,row:1,size_x:3,size_y:4,type:visualization),(col:1,id:\'Synth%C3%A8se-Documents-par-support-(en-%25)\',panelIndex:4,row:5,size_x:12,size_y:4,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Synth%C3%A8se%20:%20nombre%20de%20documents\',uiState:(P-1:(vis:(legendOpen:!f))))" height="1000" width="900"></iframe>'
	};
};

get '/grand-plage/syntheses/prets' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Synthèses',
		label3 => 'Prêts',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Synth%C3%A8se-:-nombre-de-pr%C3%AAts?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-16y,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Synth%C3%A8se-pr%C3%AAts-par-public-depuis-2002,panelIndex:1,row:5,size_x:12,size_y:4,type:visualization),(col:1,id:\'Synth%C3%A8se-:-nombre-de-pr%C3%AAts-par-ann%C3%A9e-et-par-support\',panelIndex:2,row:9,size_x:12,size_y:4,type:visualization),(col:1,id:\'Synth%C3%A8se-tableau-:-nombre-de-pr%C3%AAts-par-ann%C3%A9e\',panelIndex:3,row:1,size_x:3,size_y:4,type:visualization),(col:4,id:\'Synth%C3%A8se-:-nombre-de-pr%C3%AAts-par-ann%C3%A9e\',panelIndex:4,row:1,size_x:9,size_y:4,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Synth%C3%A8se%20:%20nombre%20de%20pr%C3%AAts\',uiState:())" height="1400" width="900"></iframe>'
	};
};



###################
# OUTILS
###################

# Contrôle qualité des inscriptions
get '/qa/inscrits' => sub {
        my $borrowers = qa_borrowers() ;
        template 'qa_borrowers', {
                label1 => 'Qualité du fichier adhérents',
                borrowers => $borrowers
        };
};

# Suggestions
get 'suggestions' => sub {
        my $suggestions = suggestions() ;
		my $acquereurs = acquereurs() ;
        template 'suggestions', {
                label1 => 'Suggestions',
                suggestions => $suggestions,
				acquereurs => $acquereurs
        };
};

post 'suggestions/mod' => sub {
		my $suggestionid = param "suggestionid" ;
		my $managedby = param "borrnummanagedby" ;
		my $title = param "title" ;
		modSuggestion($suggestionid, $managedby) ;
			
		my ($from, $to, $subject, $msg) = constructionCourriel($managedby, $title) ;
		SendEmail($from, $to, $subject, $msg) ;
		
		redirect '/suggestions';
};

# Fréquentation étude
get 'frequentation/etude' => sub {
		my $lecteurs_presents = GetTodayEntrance() ;
		my $jours = GetPastEntrances() ;
        template 'frequentation', {
                label1 => "Fréquentation de la salle d'étude",
				lecteurs_presents => $lecteurs_presents,
				jours => $jours
        };
};

post 'frequentation/etude/post' => sub {
        my $cardnumber = param "cardnumber" ;
		my $action = "Attention : aucun code-barre n'a été saisi." ;
		if ($cardnumber) {
			my $entree = IsEntrance($cardnumber) ;
			if ($entree == 0) {
				$action = "sortie" ;
			} elsif ($entree == 1) {
				$action = "entrée" ;
			}
		}
		my $lecteurs_presents = GetTodayEntrance() ;
		my $jours = GetPastEntrances() ;
        template 'frequentation', {
                label1 => "Fréquentation de la salle d'étude",
				entree => $action,
				cardnumber => $cardnumber,
				lecteurs_presents => $lecteurs_presents,
				jours => $jours
        };
};

get 'frequentation/etude/visites' => sub {
	template 'kibana', {
		label1 => 'La Grand-Plage',
		label2 => 'Salle d\'étude',
		label3 => 'Nombre de visites par jour',
		iframe => '<iframe src="http://129.1.0.237:5601/app/kibana#/dashboard/Salle-d\'%C3%A9tude?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-7d,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Entr%C3%A9es-par-jour-en-salle-d!\'%C3%A9tude\',panelIndex:1,row:1,size_x:12,size_y:3,type:visualization),(col:7,id:Nombre-de-visiteurs-uniques-par-jour,panelIndex:3,row:4,size_x:6,size_y:4,type:visualization),(col:1,id:\'Nombre-d!\'entr%C3%A9es-par-jour-dans-la-salle-d!\'%C3%A9tude\',panelIndex:4,row:4,size_x:6,size_y:4,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Salle%20d!\'%C3%A9tude\',uiState:(P-1:(vis:(legendOpen:!f))))" height="900" width="900"></iframe>'
	};
};

# Action culturelle
get 'form/action_culturelle' => sub {
		my $list_actions = list_actions() ;
		template 'action_culturelle', {
                label1 => "Action culturelle",
				actions => $list_actions
        };
};

post 'form/action_culturelle/post' => sub {
        my $date = params->{'date'} ;
		my $action = params->{'action'} ;
		my $lieu = params->{'lieu'} ;
		my $type = params->{'type'} ;
		my $public = params->{'public'} ;
		my $partenariat = params->{'partenariat'} ;
		my $participants = params->{'participants'} ;
		
		insert_action_culturelle( $date, $action, $lieu, $type, $public, $partenariat, $participants ) ;
		
		my $list_actions = list_actions() ;
        template 'action_culturelle', {
                label1 => "Action culturelle",
				actions => $list_actions
        };
};


true;

__END__

=pod

=encoding UTF-8

=head1 NOM

website::dancer

=head1 DESCRIPTION

Ce module est basé sur dancer2 et permet de gérer les différentes "routes" du site web.

=cut