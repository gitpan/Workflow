package App::User;

# $Id: User.pm,v 1.1 2003/12/28 21:51:42 cwinters Exp $

use strict;

$App::User::VERSION  = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

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
