package Adherent::Diffusion;

use Moo;
extends 'Adherent::StatDB';

has age_lib1 => ( is => 'ro' );
has age_lib2 => ( is => 'ro' );
has age_lib3 => ( is => 'ro' );
has gentilite => ( is => 'ro' );

sub prepare_data_to_diff {
    my $self = shift;
    
    $self->_mod_sexe_to_diff;
    $self->_get_age_lib;
    $self->_get_gentilite;

    return $self;
}

sub _mod_sexe_to_diff {
    my $self = shift;
    
    if ($self->{sexe} eq 'F' ) {
        $self->{sexe} = 'Femme';
    } elsif ($self->{sexe} eq 'M' ) {
        $self->{sexe} = 'Homme';
    }

    return $self;
}

sub _get_age_lib {
    my $self = shift ;

    my @age_libs = ( { age_lib1 => 'trmeda' }, { age_lib2 => 'trmedb' }, { age_lib3 => 'trinsee' } );
    foreach my $age_lib ( @age_libs) {
        my ($key) = keys(%$age_lib);
        my $lib = $$age_lib{$key};        
        my $req = "SELECT libelle FROM statdb.lib_age WHERE age = ? AND type = ?" ;
        my $dbh = $self->dbh;
        my $sth = $dbh->prepare($req);
        $sth->execute($self->age, $lib);
        
        $self->{$key} = $sth->fetchrow_array ;
        $sth->finish();
    }

    return $self;
}

sub _get_gentilite {
    my $self = shift ;

    if ($self->{geo_ville} eq 'ROUBAIX') {
        $self->{gentilite} = 'Roubaisien';
    } else {
        $self->{gentilite} = 'Non Roubaisien';
    }

    return $self;
}

1;
