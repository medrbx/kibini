package website::dancer;

use Dancer2;
use FindBin qw( $Bin );
use utf8;
use Data::Dumper; # pour débugage

use kibini::email;
use adherents;
use collections::poldoc;
use collections::details;
use collections::suggestions;
use salleEtude::form;
use action_culturelle;
use action_coop::form;
use liste;
#use data;
#use JSON;

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
        label2 => 'Les tableaux de bord de La Grand-Plage',
        label3 => 'Quels sont les services proposés ?',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Les-services-propos%C3%A9s-%C3%A0-la-Grand-Plage?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-15m,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Services-de-la-M%C3%A9diath%C3%A8que-(2017)\',panelIndex:3,row:5,size_x:12,size_y:5,type:visualization),(col:1,id:\'L!\'outil-Kibini,-qu!\'est-ce-que-c!\'est-questionmark-\',panelIndex:4,row:1,size_x:12,size_y:4,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Les%20services%20propos%C3%A9s%20%C3%A0%20la%20Grand-Plage\',uiState:())',
            height => '1200px'
        }
    };
};

# PARTIE 1 - La Grand-Plage

get 'grand-plage/activites' => sub {
    template 'kibana', {
        label1 => 'La Grand-Plage',
        label2 => 'Quelle activité ces 30 derniers jours ?',
        label3 => 'Quelques chiffres',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Page-d%27accueil-:-les-30-derniers-jours-%C3%A0-La-Grand-Plage?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-5y%2Cmode%3Aquick%2Cto%3Anow))',
            height => '1400px'
        }

     };     
};

get '/grand-plage/inscrits/profils' => sub {
    template 'kibana', {
        label1 => 'La Grand-Plage',
        label2 => 'Inscrits',
        label3 => 'Profils des inscrits',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/AWXxyms1IC-X_pQ2wJ7I?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1M%2FM%2Cmode%3Aquick%2Cto%3Anow-1M%2FM))',
            height => '1300px'
        }
    };
};

get '/grand-plage/inscrits/usages' => sub {
    template 'kibana', {
        label1 => 'La Grand-Plage',
        label2 => 'Inscrits',
        label3 => 'Usages des inscrits',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/AWH6yu6epw5wXLtt4DsB?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1M%2FM%2Cmode%3Aquick%2Cto%3Anow-1M%2FM))',
            height => '1400px'
        }
    };
};

get '/grand-plage/inscrits/quartiers' => sub {
    template 'carte', {
        label1 => 'La Grand-Plage',
        label2 => 'Inscrits',
        label3 => 'Taux d\'inscription par quartier',
    };
};

get '/grand-plage/collections/documents' => sub {
        template 'kibana', {
                label1 => 'La Grand-Plage',
                label2 => 'Collections',
                label3 => 'Documents',
                dashboard => {
                    src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Quelles-collections-questionmark-?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-15y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:9,id:Documents,panelIndex:1,row:1,size_x:4,size_y:2,type:visualization),(col:1,id:Nombre-de-documents-par-collection,panelIndex:2,row:3,size_x:12,size_y:8,type:visualization),(col:1,id:Documents-empruntables,panelIndex:3,row:1,size_x:4,size_y:2,type:visualization),(col:5,id:Nombre-de-documents-par-acc%C3%A8s,panelIndex:4,row:1,size_x:4,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Quelles%20collections%20%3F\',uiState:())',
            height => '1400px'
        }
    };
};

get '/grand-plage/collections/prets' => sub {
        template 'kibana', {
                label1 => 'La Grand-Plage',
                label2 => 'Collections',
                label3 => 'Prêts',
                dashboard => {
                    src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Pr%C3%AAts-Grand-Plage?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3A\'2018-01-15T16%3A03%3A59.108Z\'%2Cmode%3Aabsolute%2Cto%3A\'2019-01-15T16%3A03%3A59.109Z\'))" height="600" width="800',
            height => '1500px'
        }
    };
};

get '/grand-plage/collections/reservations' => sub {
        template 'kibana', {
                label1 => 'La Grand-Plage',
                label2 => 'Collections',
                label3 => 'Réservations',
                dashboard => {
                    src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Usages-du-service-r%C3%A9servations?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Nombre-d!\'utilisateurs-du-service-r%C3%A9servations-par-mois\',panelIndex:7,row:1,size_x:8,size_y:2,type:visualization),(col:1,id:Nombre-de-r%C3%A9servations-par-mois,panelIndex:11,row:3,size_x:8,size_y:2,type:visualization),(col:9,id:\'Nombre-d!\'utilisateurs-du-service-r%C3%A9servations\',panelIndex:12,row:1,size_x:4,size_y:2,type:visualization),(col:7,id:Utilisateurs-service-r%C3%A9servations-par-type-de-carte,panelIndex:13,row:5,size_x:6,size_y:3,type:visualization),(col:1,id:Utilisateurs-service-r%C3%A9servations-par-%C3%A2ge,panelIndex:17,row:5,size_x:6,size_y:3,type:visualization),(col:1,id:R%C3%A9servations-par-collection,panelIndex:18,row:8,size_x:4,size_y:5,type:visualization),(col:5,id:R%C3%A9servations-par-support,panelIndex:19,row:8,size_x:4,size_y:5,type:visualization),(col:9,id:R%C3%A9servations-par-statut,panelIndex:20,row:8,size_x:4,size_y:5,type:visualization),(col:9,id:Nombre-total-de-r%C3%A9servations,panelIndex:21,row:3,size_x:4,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Usages%20du%20service%20r%C3%A9servations\',uiState:(P-11:(vis:(legendOpen:!f)),P-13:(vis:(legendOpen:!f)),P-17:(vis:(legendOpen:!f)),P-18:(vis:(legendOpen:!f)),P-20:(vis:(legendOpen:!f)),P-7:(vis:(legendOpen:!f))))',
            height => '1500px'
        }
    };
};

get '/grand-plage/web/portail' => sub {
        template 'kibana', {
                label1 => 'La Grand-Plage',
                label2 => 'Portail',
                label3 => "L'usage du portail",
                dashboard => {
                    src => 'http://129.1.0.237:5601/app/kibana#/dashboard/cef5b330-9786-11e7-88ff-a79737dea4ec?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1y%2Cmode%3Aquick%2Cto%3Anow))',
            height => '1500px'
        }
    };
};

get '/grand-plage/web/bnr' => sub {
        template 'kibana', {
                label1 => 'La Grand-Plage',
                label2 => 'Sites web',
                label3 => "Sessions de consultation de la bn-r et du portail",
                dashboard => {
                    src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Web-:-sessions?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:\'2008-01-01T00:00:00.000Z\',mode:absolute,to:\'2016-12-30T23:00:00.000Z\'))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Web-:-sessions-par-ann%C3%A9e\',panelIndex:1,row:1,size_x:12,size_y:5,type:visualization),(col:1,id:\'Web-:-sessions-par-mois\',panelIndex:2,row:6,size_x:12,size_y:5,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Web%20:%20sessions\',uiState:(P-1:(vis:(legendOpen:!f)),P-2:(vis:(legendOpen:!f))))',
            height => '1300px'
        }
    };

};

get '/grand plage/action cooperation' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Quelles actions de coopération ?',
        dashboard => {
                    src => '...',
            height => '1300px'
        }
    };
};


# PARTIE 2 - La Médiathèque

get '/mediatheque/activites' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Quelle activité à la Médiathèque ?',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/L%27activit%C3%A9-de-la-M%C3%A9diath%C3%A8que-?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1y%2Cmode%3Aquick%2Cto%3Anow))',
            height => '2000px'
        }
    };
};

get '/mediatheque/collections/documents' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Collections',
        label3 => 'Documents',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Quelles-collections-%C3%A0-la-m%C3%A9diath%C3%A8que-questionmark-?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-15y,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-documents-par-collection,panelIndex:2,row:4,size_x:12,size_y:8,type:visualization),(col:9,id:Documents-M%C3%A9diath%C3%A8que,panelIndex:3,row:1,size_x:4,size_y:3,type:visualization),(col:1,id:Documents-empruntables-M%C3%A9diath%C3%A8que,panelIndex:4,row:1,size_x:4,size_y:3,type:visualization),(col:5,id:Documents-par-acc%C3%A8s,panelIndex:5,row:1,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'NOT%20%22Magasin%20collectivit%C3%A9s%22,%20NOT%20%22Z%C3%A8bre%22\')),title:\'Quelles%20collections%20%C3%A0%20la%20m%C3%A9diath%C3%A8que%20%3F\',uiState:())',
            height => '1300px'
        }    
    };
};

get '/mediatheque/collections/prets' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Collections',
        label3 => 'Prêts',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Pr%C3%AAts-M%C3%A9diath%C3%A8que?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-pr%C3%AAts-par-collection,panelIndex:24,row:3,size_x:12,size_y:9,type:visualization),(col:7,id:\'Nombre-d!\'emprunteurs-totaux\',panelIndex:25,row:1,size_x:6,size_y:2,type:visualization),(col:1,id:Pr%C3%AAts,panelIndex:26,row:1,size_x:6,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'pret_site:%20%22M%C3%A9diath%C3%A8que%22%20AND%20personne\')),title:\'Pr%C3%AAts%20M%C3%A9diath%C3%A8que\',uiState:())',
            height => '1400px'
        }
    };
};

get '/mediatheque/collections/emprunteurs' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Collections',
        label3 => 'Emprunteurs', 
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Profil-emprunteurs-m%C3%A9diath%C3%A8que?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:4,id:Emprunteurs-distincts-M%C3%A9diath%C3%A8que,panelIndex:1,row:1,size_x:9,size_y:3,type:visualization),(col:1,id:Emprunteurs-distincts-par-carte-m%C3%A9diath%C3%A8que,panelIndex:2,row:4,size_x:4,size_y:4,type:visualization),(col:5,id:Emprunteurs-distincts-par-%C3%A2ge-m%C3%A9diath%C3%A8que,panelIndex:3,row:4,size_x:4,size_y:4,type:visualization),(col:1,id:\'Nombre-d!\'emprunteurs\',panelIndex:4,row:1,size_x:3,size_y:3,type:visualization),(col:9,id:Emprunteurs-distincts-par-ville,panelIndex:5,row:4,size_x:4,size_y:4,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'pret_site:%20%22M%C3%A9diath%C3%A8que%22%20AND%20personne\')),title:\'Profil%20emprunteurs%20m%C3%A9diath%C3%A8que\',uiState:(P-2:(vis:(legendOpen:!f)),P-3:(vis:(legendOpen:!f)),P-5:(vis:(legendOpen:!f)))',
            height => '1300px'
        }
    };
};

get '/mediatheque/collections/emprunteurs/details' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Collections',
        label3 => 'Qui emprunte quoi ?', 
        dashboard => {
            src => '...',
            height => '1200px'
        }
    };
};

get '/mediatheque/webkiosk/profils' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Qui utilise le service webkiosk?',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Utilisateurs-de-Webkiosk?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:9,id:Utilisateurs-Webkiosk-par-%C3%A2ge,panelIndex:25,row:5,size_x:4,size_y:3,type:visualization),(col:1,id:Utilisateurs-Webkiosk-par-carte,panelIndex:26,row:5,size_x:4,size_y:3,type:visualization),(col:1,id:\'Nombre-d!\'utilisateurs-distincts-par-mois\',panelIndex:28,row:1,size_x:9,size_y:2,type:visualization),(col:10,id:Utilisateurs-de-Webkiosk,panelIndex:29,row:1,size_x:3,size_y:2,type:visualization),(col:1,id:Nombre-de-connexions-Webkiosk-par-mois,panelIndex:30,row:3,size_x:9,size_y:2,type:visualization),(col:10,id:Connexions-Webkiosk-nombre-total-depuis-12-mois,panelIndex:31,row:3,size_x:3,size_y:2,type:visualization),(col:5,id:Connexions-Webkiosk-par-ville,panelIndex:32,row:5,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Utilisateurs%20de%20Webkiosk\',uiState:(P-25:(vis:(legendOpen:!f)),P-26:(vis:(legendOpen:!f)),P-28:(vis:(legendOpen:!f)),P-30:(vis:(legendOpen:!f)),P-32:(vis:(legendOpen:!f))))',
            height => '1000px'
        }
    };
};
    
get '/mediatheque/suggestions/profils' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Qui fait des suggestions aux acquéreurs?',
        dashboard => {
            src => '...',
            height => '1200px'
        }
    };
};

get '/mediatheque/salle etude/profils' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Qui fréquente la salle d\'etude?',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Fr%C3%A9quentation-de-la-salle-d\'%C3%A9tude?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:9,id:\'Utilisateurs-salle-d!\'%C3%A9tude-par-%C3%A2ge\',panelIndex:3,row:5,size_x:4,size_y:4,type:visualization),(col:1,id:\'Utilisateurs-salle-d!\'%C3%A9tude-par-type-de-carte\',panelIndex:5,row:5,size_x:4,size_y:4,type:visualization),(col:4,id:\'Nombre-d!\'utilisateurs-de-la-salle-d!\'%C3%A9tude-par-mois\',panelIndex:7,row:1,size_x:6,size_y:2,type:visualization),(col:1,id:\'Utilisateurs-salle-d!\'%C3%A9tude\',panelIndex:8,row:1,size_x:3,size_y:2,type:visualization),(col:1,id:\'Visites-salle-d!\'%C3%A9tude\',panelIndex:9,row:3,size_x:3,size_y:2,type:visualization),(col:5,id:\'Utilisateurs-salle-d!\'%C3%A9tude-par-sexe\',panelIndex:11,row:5,size_x:4,size_y:4,type:visualization),(col:10,id:\'Dur%C3%A9e-moyenne-visite-salle-d!\'%C3%A9tude\',panelIndex:12,row:3,size_x:3,size_y:2,type:visualization),(col:4,id:\'Nombre-de-visites-en-salle-d!\'%C3%A9tude-par-mois\',panelIndex:13,row:3,size_x:6,size_y:2,type:visualization),(col:10,id:\'Salle-d!\'%C3%A9tude\',panelIndex:14,row:1,size_x:3,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Fr%C3%A9quentation%20de%20la%20salle%20d!\'%C3%A9tude\',uiState:(P-13:(vis:(legendOpen:!f)),P-3:(vis:(legendOpen:!f)),P-7:(vis:(legendOpen:!f))))',
            height => '1200px'
        }
    };
};

get '/mediatheque/action culturelle' => sub {
    template 'kibana', {
        label1 => 'La Médiathèque',
        label2 => 'Quels publics pour l\'action culturelle ?',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Action-culturelle?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:9,id:\'Nombre-de-participants-%C3%A0-l!\'action-culturelle\',panelIndex:1,row:3,size_x:4,size_y:2,type:visualization),(col:1,id:\'Nombre-d!\'actions-par-mois\',panelIndex:2,row:1,size_x:8,size_y:2,type:visualization),(col:1,id:\'Action-culturelle-par-type-d!\'action\',panelIndex:3,row:8,size_x:4,size_y:4,type:visualization),(col:5,id:Action-culturelle-par-public-cible,panelIndex:4,row:8,size_x:4,size_y:4,type:visualization),(col:1,id:Nombre-de-participants-par-mois,panelIndex:5,row:3,size_x:8,size_y:2,type:visualization),(col:9,id:\'Nombre-d!\'actions-propos%C3%A9es\',panelIndex:6,row:1,size_x:2,size_y:2,type:visualization),(col:11,id:\'Action-culturelle-:-nombre-de-partenariats\',panelIndex:7,row:1,size_x:2,size_y:2,type:visualization),(col:9,id:Action-culturelle-par-lieu,panelIndex:8,row:8,size_x:4,size_y:4,type:visualization),(col:1,id:Tableau-r%C3%A9capitulatif-action-culturelle,panelIndex:9,row:5,size_x:12,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'Action%20culturelle\',uiState:(P-2:(vis:(legendOpen:!f)),P-3:(vis:(legendOpen:!f)),P-4:(vis:(legendOpen:!f)),P-5:(vis:(legendOpen:!f)),P-8:(vis:(legendOpen:!f))))',
            height => '1500px'
        }
    
    };
};


# PARTIE 3 - Le Zèbre


get '/zebre/activites' => sub {
    template 'kibana', {
        label1 => 'Le Zèbre',
        label2 => 'Quelle activité ?',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/L\'activit%C3%A9-du-Z%C3%A8bre?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:9,id:Nombre-de-pr%C3%AAts-Z%C3%A8bre,panelIndex:3,row:1,size_x:4,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-Z%C3%A8bre,panelIndex:4,row:1,size_x:8,size_y:3,type:visualization),(col:9,id:Tableau-nombre-de-r%C3%A9servations-retir%C3%A9es-par-mois-Z%C3%A8bre,panelIndex:5,row:7,size_x:4,size_y:3,type:visualization),(col:1,id:Nombre-de-r%C3%A9servations-retir%C3%A9es-par-mois-Z%C3%A8bre,panelIndex:6,row:7,size_x:8,size_y:3,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois-et-par-arr%C3%AAt-Z%C3%A8bre,panelIndex:7,row:4,size_x:8,size_y:3,type:visualization),(col:9,id:Nombre-de-pr%C3%AAts-par-arr%C3%AAt-Z%C3%A8bre,panelIndex:8,row:4,size_x:4,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'*\')),title:\'L!\'activit%C3%A9%20du%20Z%C3%A8bre\',uiState:())',
            height => '1200px'
        }
    };
};

get '/zebre/collections/documents' => sub {
    template 'kibana', {
        label1 => 'Le Zèbre',
        label2 => 'Collections',
        label3 => 'Documents',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Quelles-collections-dans-le-Z%C3%A8bre-questionmark-?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-15y,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-documents-par-collection,panelIndex:2,row:4,size_x:12,size_y:8,type:visualization),(col:7,id:Documents-Z%C3%A8bre,panelIndex:4,row:1,size_x:6,size_y:3,type:visualization),(col:1,id:Documents-empruntables-Z%C3%A8bre,panelIndex:5,row:1,size_x:6,size_y:3,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'site_rattach:%20%22Z%C3%A8bre%22\')),title:\'Quelles%20collections%20dans%20le%20Z%C3%A8bre%20%3F\',uiState:())',
            height => '1200px'
        }
    };
};

get '/zebre/collections/prets' => sub {
    template 'kibana', {
        label1 => 'Le Zèbre',
        label2 => 'Collections',
        label3 => 'Prêts',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Pr%C3%AAts-Z%C3%A8bre?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1y%2Cmode%3Aquick%2Cto%3Anow))',
            height => '1200px'
        }
    };
};

get '/zebre/collections/emprunteurs' => sub {
    template 'kibana', {
        label1 => 'Le Zèbre',
        label2 => 'Collections',
        label3 => 'Emprunteurs',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Qui-sont-les-emprunteurs-du-Z%C3%A8bre-questionmark-?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:quick,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:\'Nombre-d!\'emprunteurs-par-mois\',panelIndex:1,row:1,size_x:8,size_y:2,type:visualization),(col:1,id:Nombre-de-pr%C3%AAts-par-mois,panelIndex:3,row:3,size_x:8,size_y:2,type:visualization),(col:9,id:Pr%C3%AAts,panelIndex:4,row:3,size_x:4,size_y:2,type:visualization),(col:1,id:Emprunteurs-distincts-par-quartier-de-Roubaix,panelIndex:6,row:5,size_x:6,size_y:3,type:visualization),(col:7,id:Emprunteurs-distincts-par-ville,panelIndex:7,row:5,size_x:6,size_y:3,type:visualization),(col:9,id:Emprunteurs-distincts-par-%C3%A2ge-m%C3%A9diath%C3%A8que,panelIndex:8,row:8,size_x:4,size_y:3,type:visualization),(col:1,id:Emprunteurs-distincts-par-type-de-carte,panelIndex:9,row:8,size_x:4,size_y:3,type:visualization),(col:5,id:Emprunteurs-distincts-par-sexe,panelIndex:10,row:8,size_x:4,size_y:3,type:visualization),(col:9,id:\'Nombre-d!\'emprunteurs-\',panelIndex:11,row:1,size_x:4,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'pret_site%20:%20%22Z%C3%A8bre%22\')),title:\'Qui%20sont%20les%20emprunteurs%20du%20Z%C3%A8bre%20%3F\',uiState:(P-1:(vis:(legendOpen:!f)),P-10:(vis:(legendOpen:!f)),P-3:(vis:(legendOpen:!f)),P-6:(vis:(legendOpen:!f)),P-7:(vis:(legendOpen:!f)),P-8:(vis:(legendOpen:!f)),P-9:(vis:(legendOpen:!f))))',
            height => '1200px'
        }
    };
};

get '/zebre/collections/emprunteurs/details' => sub {
    template 'kibana', {
        label1 => 'Le Zèbre',
        label2 => 'Collections',
        label3 => 'Qui emprunte quoi ?',
        dashboard => {
            src => '...',
            height => '1200px'
        }
    };
};

# PARTIE 4 - Le service Collectivités

get '/collectivites/collections/documents' => sub {
    template 'kibana', {
        label1 => 'Collectivités',
        label2 => 'Collections',
        label3 => 'Documents',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Quelles-collections-pour-les-collectivit%C3%A9s-questionmark-?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-15y,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:7,id:Documents-collectivit%C3%A9s,panelIndex:5,row:1,size_x:6,size_y:3,type:visualization),(col:1,id:Documents-empruntables-collectivit%C3%A9s,panelIndex:6,row:1,size_x:6,size_y:3,type:visualization),(col:1,id:Nombre-de-documents-des-collectivit%C3%A9s-par-collection,panelIndex:7,row:4,size_x:12,size_y:8,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'localisation:%20%22Magasin%20collectivit%C3%A9s%22\')),title:\'Quelles%20collections%20pour%20les%20collectivit%C3%A9s%20%3F\',uiState:())',
            height => '1300px'
        }
    };
};

get '/collectivites/collections/prets' => sub {
    template 'kibana', {
        label1 => 'Collectivités',
        label2 => 'Collections',
        label3 => 'Prêts',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Pr%C3%AAts-Collectivit%C3%A9s?embed=true&_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-1y,mode:relative,to:now))&_a=(filters:!(),options:(darkTheme:!f),panels:!((col:1,id:Nombre-de-pr%C3%AAts-par-collection,panelIndex:24,row:3,size_x:12,size_y:9,type:visualization),(col:1,id:Pr%C3%AAts-Collectivit%C3%A9s,panelIndex:28,row:1,size_x:6,size_y:2,type:visualization),(col:7,id:\'Nombre-d!\'emprunteurs-totaux-Collectivit%C3%A9s\',panelIndex:29,row:1,size_x:6,size_y:2,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:\'doc_localisation:%20%22Magasin%20collectivit%C3%A9s%22\')),title:\'Pr%C3%AAts%20Collectivit%C3%A9s\',uiState:())',
            height => '1400px'
        }    
    };
};

get '/collectivites/collections/emprunteurs' => sub {
    template 'kibana', {
        label1 => 'Collectivités',
        label2 => 'Collections',
        label3 => 'Emprunteurs',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/Profil-emprunteurs-Collectivit%C3%A9s?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1y%2Cmode%3Aquick%2Cto%3Anow))',
            height => '1200px'
        }
    };
};

get '/collectivites/collections/emprunteurs/details' => sub {
    template 'kibana', {
        label1 => 'Collectivités',
        label2 => 'Collections',
        label3 => 'Qui emprunte quoi?',
        dashboard => {
            src => '...',
            height => '1200px'
        }
    };
};

# PARTIE 5 - La poldoc de La Grand-Plage

# Collections
get '/grand-plage/collections/ensemble' => sub {
#    my $indicateurs = GetDataCollections(0);    
    template 'collections2', {
        label1 => 'La Grand-Plage',
        label2 => 'Collections',
        label3 => 'Principaux indicateurs',
        file_2016 => '/data/Statistiques_collections_2016_v20170506.xlsx',
        file_2017 => '/data/Statistiques_collections_2017.xlsx', 
		file_2018 => '/data/Statistiques_collections_2018.xlsx'
#        indicateurs => $indicateurs
    };
};

get '/mediatheque/collections/ensemble' => sub {
    my $indicateurs = GetDataCollections(1);    
    template 'collections', {
        label1 => 'Médiathèque',
        label2 => 'Collections',
        label3 => 'Principaux indicateurs sur 12 mois',
        indicateurs => $indicateurs
    };
};

get '/zebre/collections/ensemble' => sub {
    my $indicateurs = GetDataCollections(2);    
    template 'collections', {
        label1 => 'Le Zèbre',
        label2 => 'Collections',
        label3 => 'Principaux indicateurs sur 12 mois',
        indicateurs => $indicateurs
    };
};

get '/collectivites/collections/ensemble' => sub {
    my $indicateurs = GetDataCollections(3);    
    template 'collections', {
        label1 => 'Collectivités',
        label2 => 'Collections',
        label3 => 'Principaux indicateurs sur 12 mois',
        indicateurs => $indicateurs
    };
};


# PARTIE 6 - Les synthèses pluri-annuelles de La Grand-Plage

get '/grand-plage/syntheses/inscrits' => sub {
    template 'kibana', {
        label1 => 'La Grand-Plage',
        label2 => 'Synthèses',
        label3 => 'Inscrits',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/AWHc1TFtpw5wXLtt1uz1?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1y%2Fy%2Cmode%3Aquick%2Cto%3Anow-1y%2Fy))',
            height => '1100px'
        }
    };
};

get '/grand-plage/syntheses/collections' => sub {
    template 'kibana', {
        label1 => 'La Grand-Plage',
        label2 => 'Synthèses',
        label3 => 'Collections',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/AWHc5g3Ppw5wXLtt1uz6?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1y%2Fy%2Cmode%3Aquick%2Cto%3Anow-1y%2Fy))',
            height => '1100px'
        }
    
    };
};

get '/grand-plage/syntheses/prets' => sub {
    template 'kibana', {
        label1 => 'La Grand-Plage',
        label2 => 'Synthèses',
        label3 => 'Prêts',
        dashboard => {
            src => 'http://129.1.0.237:5601/app/kibana#/dashboard/AWHc8EI_pw5wXLtt1uz_?embed=true&_g=(refreshInterval%3A(display%3AOff%2Cpause%3A!f%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1y%2Fy%2Cmode%3Aquick%2Cto%3Anow-1y%2Fy))',
            height => '1500px'
        }
    };
};

###################
# OUTILS
###################

# Contrôle qualité des inscriptions
get '/qa/inscrits' => sub {
    my $borrowers = GetBorrowersForQA();
    template 'qa_borrowers', {
        label1 => 'Qualité du fichier adhérents',
        borrowers => $borrowers
    };
};

# Suggestions
get 'suggestions' => sub {
    my $suggestions = suggestions();
    my $acquereurs = acquereurs();
    template 'suggestions', {
        label1 => 'Suggestions',
        suggestions => $suggestions,
        acquereurs => $acquereurs
    };
};

post 'suggestions/mod' => sub {
    my $suggestionid = param "suggestionid";
    my $managedby = param "borrnummanagedby";
    my $title = param "title";
    modSuggestion($suggestionid, $managedby);
            
    my ($from, $to, $subject, $msg) = constructionCourriel($managedby, $title);
    SendEmail($from, $to, $subject, $msg);
        
    redirect '/suggestions';
};

# Fréquentation étude
get 'frequentation/etude' => sub {
    my $lecteurs_presents = GetTodayEntrance();
    my $jours = GetPastEntrances();
    template 'frequentation', {
        label1 => "Fréquentation de la salle d'étude",
        lecteurs_presents => $lecteurs_presents,
        jours => $jours
    };
};

post 'frequentation/etude/post' => sub {
    my $cardnumber = param "cardnumber";
    my $action = "Attention : aucun code-barre n'a été saisi.";
    if ($cardnumber) {
        my $entree = IsEntrance($cardnumber);
        if ($entree == 0) {
            $action = "sortie";
        } elsif ($entree == 1) {
            $action = "entrée";
        }
    }
    my $lecteurs_presents = GetTodayEntrance();
    my $jours = GetPastEntrances();
    template 'frequentation', {
        label1 => "Fréquentation de la salle d'étude",
        entree => $action,
        cardnumber => $cardnumber,
        lecteurs_presents => $lecteurs_presents,
        jours => $jours
    };
};

# Action culturelle
get 'form/action_culturelle' => sub {
    my $list_actions = list_actions();
    template 'action_culturelle', {
        label1 => "Action culturelle",
        actions => $list_actions
    };
};

post 'form/action_culturelle/post' => sub {
    my $date = params->{'date'};
    my $action = params->{'action'};
    my $lieu = params->{'lieu'};
    my $type = params->{'type'};
    my $public = params->{'public'};
    my $partenariat = params->{'partenariat'};
    my $participants = params->{'participants'};
        
    insert_action_culturelle( $date, $action, $lieu, $type, $public, $partenariat, $participants );
        
    my $list_actions = list_actions();
    template 'action_culturelle', {
        label1 => "Action culturelle",
        actions => $list_actions
    };
};

# Actions de coopération
get 'form/action_coop' => sub {
        my $list_actions = GetListActionsCooperation();
        template 'action_coop', {
                label1 => "Action de coopération",
                actions => $list_actions
        };
};

post 'form/action_coop/post' => sub {
        my $date = params->{'date'};
        my $lieu = params->{'lieu'};
        my $type = params->{'type_action'};
        my $nom = params->{'nom_action'};
        my $type_structure = params->{'type_structure'};
        my $nom_structure = params->{'nom_structure'};
        my $participants = params->{'participants'};
        my $referent_action = params->{'referent_action'};

        
        AddActionCooperation( $date, $lieu, $type, $nom, $type_structure, $nom_structure, $participants, $referent_action );
        
        my $list_actions = GetListActionsCooperation();
        template 'action_coop', {
                label1 => "Action de coopération",
                actions => $list_actions
        };
};


# Listes de réservations et de perdus
get 'liste/:type/:etage' => sub {

    my %params = params;
    #print Dumper(\%params);
    
    #my $label1 = TestParams(\%params);
    #my ( $label1, $template, $rows ) = GetListData( $type, $etage, $semaine );

    template 'test', {
        label1 => $params{type},
        label2 => $params{etage}
    };
};

# Pour obtenir directement des données
#get 'data/arrets_bibliobus' => sub {
#	my $data = getArretsZebre();
#	return to_json($data);
#};


true;

__END__

=pod

=encoding UTF-8

=head1 NOM

website::dancer

=head1 DESCRIPTION

Ce module est basé sur dancer2 et permet de gérer les différentes "routes" du site web.

=cut
