package App::User;

# $Id: User.pm 289 2007-06-18 21:45:56Z jonasbn $

use strict;

$App::User::VERSION = '1.01';

my %USERS = (
    Stu => 'Stu Nahan',
    Mel => 'Mel Ott',
    Irv => 'Irv Cross',
    Bob => 'Bobby Orr',
    Joe => 'Joe Morgan',
    Ric => 'Ric Ocasek'
);

sub get_possible_values {
    return map { { value => $_, label => $USERS{ $_ } } } sort keys %USERS;
}

1;
