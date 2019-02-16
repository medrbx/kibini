package Evenement;

use Moo::Role;

use Kibini::Time;

has date_heure_a => ( is => 'ro' );
has date_heure_a_format => ( is => 'ro' );
has date_heure_b => ( is => 'ro' );
has date_heure_b_format => ( is => 'ro' );
has date_heure_c => ( is => 'ro' );
has date_heure_c_format => ( is => 'ro' );

has statdb_date_heure_a => ( is => 'rw');
has statdb_date_heure_b => ( is => 'ro');
has statdb_date_heure_c => ( is => 'ro');

has es_date_heure_a => ( is => 'ro');
has es_date_heure_a_annee => ( is => 'ro' );
has es_date_heure_a_heure => ( is => 'ro' );
has es_date_heure_a_jour => ( is => 'ro' );
has es_date_heure_a_jour_semaine => ( is => 'ro' );
has es_date_heure_a_mois => ( is => 'ro' );
has es_date_heure_a_semaine => ( is => 'ro' );

has es_date_heure_b => ( is => 'ro');
has es_date_heure_b_annee => ( is => 'ro' );
has es_date_heure_b_heure => ( is => 'ro' );
has es_date_heure_b_jour => ( is => 'ro' );
has es_date_heure_b_jour_semaine => ( is => 'ro' );
has es_date_heure_b_mois => ( is => 'ro' );
has es_date_heure_b_semaine => ( is => 'ro' );

has es_date_heure_c => ( is => 'ro');
has es_date_heure_c_annee => ( is => 'ro' );
has es_date_heure_c_heure => ( is => 'ro' );
has es_date_heure_c_jour => ( is => 'ro' );
has es_date_heure_c_jour_semaine => ( is => 'ro' );
has es_date_heure_c_mois => ( is => 'ro' );
has es_date_heure_c_semaine => ( is => 'ro' );

has es_duree_ab => ( is => 'ro' );
has es_duree_bc => ( is => 'ro' );
has es_duree_ac => ( is => 'ro' );


sub evenement_complete_data {
    my ($self, $param) = @_;
    
    unless ($self->{date_heure_a_format}) {
        $self->{date_heure_a_format} = $param->{date_heure_a_format};
    }
    if ( $self->{date_heure_a} and $self->{date_heure_a_format} ) {
        $self->_get_statdb_date_heure_a;
        $self->_get_es_date_heure_a;

        unless ($self->{date_heure_b_format}) {
            $self->{date_heure_b_format} = $param->{date_heure_b_format};
        }
        if ( $self->{date_heure_b} and $self->{date_heure_b_format} ) {
            $self->_get_statdb_date_heure_b;
            $self->_get_es_date_heure_b;
            
            unless ($self->{date_heure_c_format}) {
                $self->{date_heure_c_format} = $param->{date_heure_c_format};
            }            
            if ( $self->{date_heure_c} and $self->{date_heure_c_format} ) {
                $self->_get_statdb_date_heure_c;
                $self->_get_es_date_heure_c;
            }
        }

    }

    return $self;
}

sub get_es_duree_ab {
    my ($self, $param) = @_ ;

    my $kt = Kibini::Time->new({ start => { value => $self->{date_heure_a}, format => $self->{date_heure_a_format} }, end => { value => $self->{date_heure_b}, format => $self->{date_heure_b_format} }});
    $kt->get_duration({type => $param});

    $self->{es_duree_ab} = $kt->duration;
    
    return $self ;
}

sub get_es_duree_bc {
    my ($self, $param) = @_ ;

    my $kt = Kibini::Time->new({ start => { value => $self->{date_heure_b}, format => $self->{statdb_date_heure_b_format} }, end => { value => $self->{date_heure_c}, format => $self->{date_heure_c_format} }});
    $kt->get_duration({type => $param});

    $self->{es_duree_bc} = $kt->duration;
    
    return $self ;
}

sub get_es_duree_ac {
    my ($self, $param) = @_ ;

    my $kt = Kibini::Time->new({ start => { value => $self->{date_heure_a}, format => $self->{date_heure_a_format} }, end => { value => $self->{date_heure_c}, format => $self->{date_heure_c_format} }});
    $kt->get_duration({type => $param});

    $self->{es_duree_ac} = $kt->duration;
    
    return $self ;
}

sub _get_es_date_heure_a {
    my ($self, $param) = @_;

    if ($self->{date_heure_a} or $self->{statdb_date_heure_a} ) {    
        my $element = {};
    
        my $dt;
        if ($self->{es_date_heure_a}) {
            my $kt = Kibini::Time->new({ start => { value => $self->{es_date_heure_a}, format => $self->{date_heure_a_format} }});
            $dt = $kt->start_dt;
        } else {
            $self->{es_date_heure_a} = $self->{statdb_date_heure_a};
            my $kt = Kibini::Time->new({ start => { value => $self->{es_date_heure_a}, format => $self->{date_heure_a_format} }});
            $dt = $kt->start_dt;
        }

        my @elements_to_get = qw (year month week_number day dow hour);
        foreach my $element_to_get (@elements_to_get) {
            $element->{$element_to_get} = $dt->$element_to_get;
        }

        my @elements_to_mod = qw (month week_number hour);
        foreach my $element_to_mod (@elements_to_mod) {
            if ($element->{$element_to_mod}) {
                if ($element->{$element_to_mod} < 10) {
                    $element->{$element_to_mod} = "0" . $element->{$element_to_mod};
                }
            }
        }

        if ($element->{dow}) {
            my %dowfr = (
                1 => "1 Lundi",
                2 => "2 Mardi",
                3 => "3 Mercredi",
                4 => "4 Jeudi",
                5 => "5 Vendredi",
                6 => "6 Samedi",
                7 => "7 Dimanche"
            );
            $element->{dow} = $dowfr{$element->{dow}}
        }
    
        $self->{es_date_heure_a_annee} = $element->{year};
        $self->{es_date_heure_a_heure} = $element->{hour};
        $self->{es_date_heure_a_jour} = $element->{day};
        $self->{es_date_heure_a_jour_semaine} = $element->{dow};
        $self->{es_date_heure_a_mois} = $element->{month};
        $self->{es_date_heure_a_semaine} = $element->{week_number};
    }
    
    return $self;
}

sub _get_es_date_heure_b {
    my ($self, $param) = @_;

    if ($self->{date_heure_b} or $self->{statdb_date_heure_b} ) {    
        my $element = {};
    
        my $dt;
        if ($self->{es_date_heure_b}) {
            my $kt = Kibini::Time->new({ start => { value => $self->{es_date_heure_b}, format => $self->{date_heure_b_format} }});
        $dt = $kt->start_dt;
        } else {
            $self->{es_date_heure_b} = $self->{statdb_date_heure_b};
            my $kt = Kibini::Time->new({ start => { value => $self->{es_date_heure_b}, format => $self->{date_heure_b_format} }});
            $dt = $kt->start_dt;
        }

        my @elements_to_get = qw (year month week_number day dow hour);
        foreach my $element_to_get (@elements_to_get) {
            $element->{$element_to_get} = $dt->$element_to_get;
        }

        my @elements_to_mod = qw (month week_number hour);
        foreach my $element_to_mod (@elements_to_mod) {
            if ($element->{$element_to_mod}) {
                if ($element->{$element_to_mod} < 10) {
                    $element->{$element_to_mod} = "0" . $element->{$element_to_mod};
                }
            }
        }

        if ($element->{dow}) {
            my %dowfr = (
                1 => "1 Lundi",
                2 => "2 Mardi",
                3 => "3 Mercredi",
                4 => "4 Jeudi",
                5 => "5 Vendredi",
                6 => "6 Samedi",
                7 => "7 Dimanche"
            );
            $element->{dow} = $dowfr{$element->{dow}}
        }
    
        $self->{es_date_heure_b_annee} = $element->{year};
        $self->{es_date_heure_b_heure} = $element->{hour};
        $self->{es_date_heure_b_jour} = $element->{day};
        $self->{es_date_heure_b_jour_semaine} = $element->{dow};
        $self->{es_date_heure_b_mois} = $element->{month};
        $self->{es_date_heure_b_semaine} = $element->{week_number};
    }
    
    return $self;
}

sub _get_es_date_heure_c {
    my ($self, $param) = @_;

    if ($self->{date_heure_c} or $self->{statdb_date_heure_c} ) {    
        my $element = {};
    
        my $dt;
        if ($self->{es_date_heure_c}) {
            my $kt = Kibini::Time->new({ start => { value => $self->{es_date_heure_c}, format => $self->{date_heure_c_format} }});
        $dt = $kt->start_dt;
        } else {
            $self->{es_date_heure_c} = $self->{statdb_date_heure_c};
            my $kt = Kibini::Time->new({ start => { value => $self->{es_date_heure_c}, format => $self->{date_heure_c_format} }});
            $dt = $kt->start_dt;
        }

        my @elements_to_get = qw (year month week_number day dow hour);
        foreach my $element_to_get (@elements_to_get) {
            $element->{$element_to_get} = $dt->$element_to_get;
        }

        my @elements_to_mod = qw (month week_number hour);
        foreach my $element_to_mod (@elements_to_mod) {
            if ($element->{$element_to_mod}) {
                if ($element->{$element_to_mod} < 10) {
                    $element->{$element_to_mod} = "0" . $element->{$element_to_mod};
                }
            }
        }

        if ($element->{dow}) {
            my %dowfr = (
                1 => "1 Lundi",
                2 => "2 Mardi",
                3 => "3 Mercredi",
                4 => "4 Jeudi",
                5 => "5 Vendredi",
                6 => "6 Samedi",
                7 => "7 Dimanche"
            );
            $element->{dow} = $dowfr{$element->{dow}}
        }
    
        $self->{es_date_heure_c_annee} = $element->{year};
        $self->{es_date_heure_c_heure} = $element->{hour};
        $self->{es_date_heure_c_jour} = $element->{day};
        $self->{es_date_heure_c_jour_semaine} = $element->{dow};
        $self->{es_date_heure_c_mois} = $element->{month};
        $self->{es_date_heure_c_semaine} = $element->{week_number};
    }
    
    return $self;
}

sub _get_statdb_date_heure_a {
    my ($self) = @_;
    if ($self->{date_heure_a}) {
        $self->{statdb_date_heure_a} = $self->{date_heure_a};
    }
    
    return $self;
}

sub _get_statdb_date_heure_b {
    my ($self) = @_;
    if ($self->{date_heure_b}) {
        $self->{statdb_date_heure_b} = $self->{date_heure_b};
    }
    
    return $self;
}

sub _get_statdb_date_heure_c {
    my ($self) = @_;
    if ($self->{date_heure_c}) {
        $self->{statdb_date_heure_c} = $self->{date_heure_c};
    }
    
    return $self;
}
1;
