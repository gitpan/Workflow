# -*-perl-*-

# $Id: config.t,v 1.3 2006/07/07 12:43:08 jonasbn Exp $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 21;
use Test::Exception;

my ($parser);

#testing load
require_ok( 'Workflow::Config' );

#testing bad config language,SCAML it is a disgrace to mark-up
dies_ok { Workflow::Config->new( 'SCAML' ) };

#testing good config language XML
ok($parser = Workflow::Config->new( 'xml' ));

ok(my @validtypes = $parser->get_valid_config_types());
isa_ok($parser, 'Workflow::Config');

ok($parser->parse( 'workflow', 'workflow.xml' ));
ok($parser->parse( 'action', 'workflow_action.xml' ));
ok($parser->parse( 'condition', 'workflow_condition.xml' ));
ok($parser->parse( 'validator', 'workflow_validator.xml' ));

$parser = Workflow::Config->new( 'xml' );
ok($parser->parse( 'workflow', 'workflow.xml', 'workflow_action.xml', 'workflow_condition.xml', 'workflow_validator.xml' ));

#testing good config language Perl
ok($parser = Workflow::Config->new( 'perl' ));
isa_ok($parser, 'Workflow::Config');

dies_ok { $parser->parse( 'workflow', 'workflow_errorprone.perl' ) };
dies_ok { $parser->parse( 'workflow', 'no_such_file.perl' ) };
dies_ok { $parser->parse( '123_NOSUCHTYPE', 'workflow_errorprone.perl' ) };

ok(scalar $parser->parse( 'workflow' ) == 0 ); #forgotten file

ok($parser->parse( 'workflow', 'workflow.perl' ));
ok($parser->parse( 'action', 'workflow_action.perl' ));
ok($parser->parse( 'condition', 'workflow_condition.perl' ));
ok($parser->parse( 'validator', 'workflow_validator.perl' ));


$parser = Workflow::Config->new( 'perl' );
ok($parser->parse( 'workflow', 'workflow.perl', 'workflow_action.perl', 'workflow_condition.perl', 'workflow_validator.perl' ));

