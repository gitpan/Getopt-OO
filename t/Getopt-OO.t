# $Log: Getopt-OO.t,v $
# Revision 1.4  2005/01/17 06:55:13  sjs
#
# Makefile: move required version to 5.005.
# Bumped version to 2.
#
#
# Clean up documentaion.
# Make use of arg vs option more consistent.
# Get rid of 'our' variables so we could use 5.005 perl.
# Modified mutual_exclusive so it could take either a
#   list or list of lists.
#
# Revision 1.3  2005/01/11 07:51:33  sjs
# Added tests for mutual_exclude and for required.
# Fixed a problem where test file was being opened
# for read but written to.
#
# Revision 1.2  2005/01/10 05:56:01  sjs
# fixed Debug file test.  Was not opening file for read before reading.
#
# Revision 1.1.1.1  2005/01/10 05:23:52  sjs
# Import of Getopt::OO
#
use IO::File;
$| = 1;

#If we can''t find our lib or are somehow wrong version, abort!
my $TestVersion;
BEGIN{
	$TestVersion = '0.02';
	eval {
		require 'Getopt/OO.pm';
		$Getopt::OO::VERSION eq $TestVersion
			|| die("Testing Getopt::OO VERSION $TestVersion and found ",
				"$Getopt::OO::VERSION\n");
	};
	die "1..1\n${@}not ok" if $@;
};

# Am using this instead of Test::More because this needs to be installed
# on some older versions of Perl that don''t have Test::More installed and
# I can''t install it.
{
	local *F;
	open F, $0;
	my $number_of_tests = (grep /^\s*OK\s*\(/, <F>);
	close F;
	my $number_completed = 0;
	my $number_passed = 0;
	print "1..$number_of_tests\n";

	sub OK{
		my ($test, $string) = @_;
		$number_completed++;
		print(($test)? '' : "$string\nnot ", "ok $number_completed\n");
	}
}

	#########################

{
my $help = 'USAGE: Getopt-OO.t [ -ab   ]  
    -a  help for a
    -b  help for b
';
	my $h = Getopt::OO->new(
		['-a'],
		'-a' => {help => 'help for a'},
		'-b' => {help => 'help for b'},
	);
	OK(defined $h, 				"Handle returned.");
	OK($h->isa('Getopt::OO'),	"Handle looks good.");
	OK($h->Help() eq $help, 	"Looks good for Help trivial case.");
	OK($h->Values() == 1, 		"Looks good for Values trivial case.");
	OK($h->Values('-a') == 1, 	"Looks good for Values trivial case.");
	OK($h->Values('-b') == 0, 	"Looks good for Values trivial case.");
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
			[ '-a' ],
			'-a' => {help => 'help for a'},
			'-a' => {help => 'help for a'},
		);
	};
	OK($@ eq $error, "option declared more than once");
}
# Check return values and types are right.
{
	 my @argv = qw (-abcde b c0 d0 d1 e0 e1 -c c1 -e e2 e3);
	 my $h = Getopt::OO->new(\@argv,
		'-a' => {},
		'-b' => { n_values => 1, },
		'-c' => { n_values => 1, multiple => 1, },
		'-d' => { n_values => 2, },
		'-e' => { n_values => 2, multiple => 1, },
	 );
	 my $n_options = $h->Values();
	 my $a = $h->Values('-a');
	 my $b = $h->Values('-b');
	 my @c = $h->Values('-c');
	 my @d = $h->Values('-d');
	 my @e = $h->Values('-e');
	OK($n_options && $n_options == 5, "Right number of args.");
	OK($a && $a == 1, 					"-a is ok.");
	OK($b && $b eq 'b',					"-b is ok.");
	OK(@c && @c == 2 
		&& $c[0] eq 'c0'
		&& $c[1] eq 'c1',				"-c is ok.");
	OK(@d && @d == 2 
		&& $d[0] eq 'd0'
		&& $d[1] eq 'd1',				"-d is ok.");
	OK(@e && @e == 2 && ref $e[0] 
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
	OK(Verbose() == 0,		"Verbose off by default is ok.");
	Verbose(1);
	OK(Verbose() == 1,		"Verbose on works.");
	Verbose(0);
	OK(Verbose(0) == 0,		"Verbose off works.");
	OK(Debug() == 0,		"Debug off by default is ok.");
	Debug(1);
	OK(Debug() == 1,		"Debug on works.");
	Debug(0);
	OK(Debug(0) == 0,		"Debug off works.");

	my $tmp = "/tmp/t.$$";
	my @debug_test = ("testing Debug\n");
	my $fh = IO::File->new("> $tmp");
	Debug(1);
	Debug($fh);
	Debug(@debug_test);
	$fh->close();
	$fh = IO::File->new("$tmp");
	my @x = <$fh>;
	OK("@x" eq "@debug_test", "Verbose redirect is ok.");

	my @verbose_test = ("testing Verbose\n");
	$fh = IO::File->new("> $tmp");
	Verbose(1);
	Verbose($fh);
	Verbose(@verbose_test);
	$fh->close();
	$fh = IO::File->new("$tmp");
	 @x = <$fh>;
	OK("@x" eq "@verbose_test", "Verbose redirect is ok.");
	unlink($tmp);
}
# test callback.
{
	my $x;
	my $h = Getopt::OO->new(
		[ '-a' ],
		-a => { callback => sub{$x = 27; 0 }, }
	);
	OK($x == 27, 		"callback with no error works.");
}
{
my $error = 'USAGE: Getopt-OO.t [ -a   ]  
Found following errors:
Callback returned an error:
	callback with an error
';
	my $x;
	eval {
		my $h = Getopt::OO->new(
			[ '-a' ],
			'-a' => { callback => sub{$x = 27; "callback with an error" }, }
		);
	};
	OK($@ eq $error,		"callback with error works ok.");
}
	# Check ClientDate.
{
	my $h = Getopt::OO->new(
		[ '-a' ],
		'-a' => {}
	);
	my $x = $h->ClientData('-a');
	$h->ClientData('-a', '27');
	my $y = $h->ClientData('-a');
	OK(!defined $x && $y == 27,				"ClientData works ok.\n");
}
# Check for required.
{
	my $h = eval {
		Getopt::OO->new(
			[ '-b' ],
			required => [ '-a' ],
			'-a' => {},
			'-b' => {},
		);
	};
	OK($@ && $@ =~ /Missing required/,	"found missing required ok.\n");
}
{
	my $h = eval {
		Getopt::OO->new(
			[ '-b', '-a' ],
			required => [ '-a' ],
			'-a' => {},
			'-b' => {},
		);
	};
	OK(!$@,					 					"found required ok.\n");
}
{
	my $h = eval {
		Getopt::OO->new(
			['-a'],
			mutual_exclusive => [
				[ '-b', '-a' ],
			],
			'-a' => {},
			'-b' => {},
		);
	};
	OK($@ eq '', 						"no mutual_exclusive ok.\n");
}
{
	my $h = eval {
		Getopt::OO->new(
			['-a', '-b'],
			mutual_exclusive => [
				[ '-b', '-a' ],
			],
			'-a' => {},
			'-b' => {},
		);
	};
	OK($@ =~ /Found mutually exclusive/,"simple bad mutual_exclusive ok.\n");
}
{
	my $h = eval {
		Getopt::OO->new(
			['-a'],
			mutual_exclusive => [ '-b', '-a' ],
			'-a' => {},
			'-b' => {},
		);
	};
	OK($@ eq '', 						"simple no mutual_exclusive ok.\n");
}
{
	my $h = eval {
		Getopt::OO->new(
			['-a', '-b'],
			mutual_exclusive => [ '-b', '-a' ],
			'-a' => {},
			'-b' => {},
		);
	};
	OK($@ =~ /Found mutually exclusive/,"bad mutual_exclusive ok.\n");
}

__END__
