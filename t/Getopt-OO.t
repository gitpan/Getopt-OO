use Test::More  tests => 25;
use IO::File;
BEGIN { use_ok('Getopt::OO') };

#########################

{
my $help = 'USAGE: Getopt-OO.t [ -ab   ]  
    -a  help for a
    -b  help for b
';
	my $h = Getopt::OO->new(
		[-a],
		-a => {help => 'help for a'},
		-b => {help => 'help for b'},
	);
	ok(defined $h, 				"Handle returned.");
	ok($h->isa('Getopt::OO'),	"Handle looks good.");
	ok($h->Help() eq $help, 	"Looks good for Help trivial case.");
	ok($h->Values() == 1, 		"Looks good for Values trivial case.");
	ok($h->Values('-a') == 1, 	"Looks good for Values trivial case.");
	ok($h->Values('-b') == 0, 	"Looks good for Values trivial case.");
}
{
	# Make sure die works right.
	my $error = 'USAGE: Getopt-OO.t [ -a   ]  
    -a  help for a
Found following errors:
Options "-a" declared more than once.
';
	my @e = ( "Options \"-a\" declared more than once.\n");
	my ($h, @errors);
	eval {
		($h, @errors) = Getopt::OO->new(
			[ -a ],
			-a => {help => 'help for a'},
			-a => {help => 'help for a'},
		);
	};
	ok($@ eq $error, "Error check worked without die ok.");
}
# Check return values and types are right.
{
	 my @argv = qw (-abcde b c0 d0 d1 e0 e1 -c c1 -e e2 e3);
	 my $h = Getopt::OO->new(\@argv,
		-a => {},
		-b => { n_values => 1, },
		-c => { n_values => 1, multiple => 1, },
		-d => { n_values => 2, },
		-e => { n_values => 2, multiple => 1, },
	 );
	 my $n_options = $h->Values();
	 my $a = $h->Values('-a');
	 my $b = $h->Values('-b');
	 my @c = $h->Values('-c');
	 my @d = $h->Values('-d');
	 my @e = $h->Values('-e');
	ok($n_options && $n_options == 5, "Right number of args.");
	ok($a && $a == 1, 					"-a is ok.");
	ok($b && $b eq 'b',					"-b is ok.");
	ok(@c && @c == 2 
		&& $c[0] eq 'c0'
		&& $c[1] eq 'c1',				"-c is ok.");
	ok(@d && @d == 2 
		&& $d[0] eq 'd0'
		&& $d[1] eq 'd1',				"-d is ok.");
	ok(@e && @e == 2 && ref $e[0] 
		&& ref $e[0] eq 'ARRAY'
		&& $e[0]->[0] eq 'e0'
		&& $e[0]->[1] eq 'e1'
		&& ref $e[1] eq 'ARRAY'
		&& $e[1]->[0] eq 'e2'
		&& $e[1]->[1] eq 'e3' ,			"-e is ok.");
}
# Test Verbose and Debug.
{
	use Getopt::OO qw(Debug Verbose);
	ok(Verbose() == 0,		"Verbose off by default is ok.");
	Verbose(1);
	ok(Verbose() == 1,		"Verbose on works.");
	Verbose(0);
	ok(Verbose(0) == 0,		"Verbose off works.");
	ok(Debug() == 0,		"Debug off by default is ok.");
	Debug(1);
	ok(Debug() == 1,		"Debug on works.");
	Debug(0);
	ok(Debug(0) == 0,		"Debug off works.");

	my $tmp = "/tmp/t.$$";
	my @debug_test = ("testing debhg\n");
	my $fh = IO::File->new("> $tmp");
	Debug(1);
	Debug($fh);
	Debug(@debug_test);
	my @x = <$fh>;
	$fh->close();
	ok("@x" eq "@verbose_test", "Verbose redirect is ok.");

	my @verbose_test = ("testing Verbose\n");
	$fh = IO::File->new("> $tmp");
	Verbose(1);
	Verbose($fh);
	Verbose(@verbose_test);
	$fh->close();
	$fh = IO::File->new("$tmp");
	 @x = <$fh>;
	ok("@x" eq "@verbose_test", "Verbose redirect is ok.");
	unlink($tmp);
}
# test callback.
{
	my $x;
	my $h = Getopt::OO->new(
		[ '-a' ],
		-a => { callback => sub{$x = 27; 0 }, }
	);
	ok($x == 27, 		"callback with no error works.");
}
{
	my $x;
	my $error = 'USAGE: Getopt-OO.t [ -a   ]  
Found following errors:
Callback returned an error:
	got an error
';
	eval {
		my $h = Getopt::OO->new(
			[ '-a' ],
			-a => { callback => sub{$x = 27; "got an error" }, }
		);
	};
	ok($@ eq $error,		"callback with error works ok.");
}
# Check ClientDate.
{
	my $h = Getopt::OO->new(
		[ '-a' ],
		-a => {}
	);
	my $x = $h->ClientData('-a');
	$h->ClientData('-a', '27');
	my $y = $h->ClientData('-a');
	ok(!defined $x && $y == 27,		"ClientData works ok.\n");
}


__END__
