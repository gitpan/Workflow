package App::User;

# $Id: User.pm 539 2012-10-25 16:19:14Z jonasbn $

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
