# $Log: OO.pm,v $
# Revision 1.3  2005/01/17 06:54:57  sjs
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
# Revision 1.2  2005/01/11 07:50:30  sjs
# Fixed mutual_exclude and required.
#
# Revision 1.1.1.1  2005/01/10 05:23:52  sjs
# Import of Getopt::OO
#
package Getopt::OO;

use 5.005004;
use strict;
# Use warnings if possible.  Don't worry if you can't.  Package was developed
# with warnings on, but it wasn't around by default before 5.6.
eval { require 'warnings.pm' };
use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw(Debug Verbose);

$VERSION = '0.02';

=head1 NAME

Getopt::OO - Perl object oriented version of Getopt that uses
a perl hash as template to describe command line options and handles
most common command line parsing.

=head1 SYNOPSIS

 use Getopt::OO qw(Debug Verbose);

 my ($handle) = Getopt::OO->new(\@ARGV,
    '-d' => {
        help => 'turn on debug output',
        callback => sub {Debug(1); 0},
    },
    '-o' => {
        help => 'another option.',
    },
    '-f' => {
        help => 'option that expects one more value.',
        n_values => 1,
    },
    '--long' {
        help => 'long option'
    },
 );
  if ($handle->Values()) {
    Debug("You will get output if -d was on command line");
    if (my $f = handle->Values(-f)) {
        print "Got $f with the -f value.\n";
    }
  }
  else {
    print "No options found on command line.\n";
 }

=head1 DESCRIPTION

Getopt::OO is an object oriented tool for parsing command line arguments.
It expects a reference to the input arguments and uses a perl hash
to describe how the command line arguments should be parsed.  Note
that by parsed, we mean what options expect values, etc.  We check
to make sure values exist on the command line as necessary -- nothing
else.  The caller is responsible for making sure that a value that
he knows should be a file exists, is writable, or whatever.

Command line arguments can be broken into two distinct types: options
and values that are associated with these options.  In windows, 
options often start with a '/' but sometimes with a '-', but
in unix they almost universally start with a '-'.  For this module
options start with a '-'.  We support two types of options:
the short single dashed options and the long double dashed arguments.
The difference between these two is that with this module the
short options can be combined into a single option, but the
long options can not.  For example, most of us will be familiar
with the tar '-xvf file' command which can also be expressed
as '-x -v -f file'.  Long options can not be combined this way,
so '--help' for example must always stand by itself.

The input template expects the option names as its keys.  For instance
if you were expecting "-xv --hello" as possible command line arguments,
the keys for your template hash would be '-x', '-v', and '--hello'.

=head2 Valid values for each dashed argument are:

=head3 help

A help string associated with the argument.

=head3 n_values

Number of arguments the value expects.  Any value greater than or
equal to 0 is valid with 0 being the default.

=head3 multiple

If this exists, it means the argument may be encountered multiple times.
For example --

 		'-a' => {
 			n_values => 3,
 			multiple => 1,
 		 },

says that if '-a' is encountered on the command line, the next
three arguments on the command line are associated with it and
that it may be encountered multiple times.

=head3 callback

This must be a code reference.  If the template entry looked like:

   		'-a' => {
   			n_values => 1,
  			multiple => 1,
  			callback => \&xyz,
  		},

then we would call the function xyz with the a Getopt::OO handle
and the option found and the argument reference.  For instance
if the function looked like:

 sub Callback {
 	my ($handle, $option) = @_
 	...

the caller could get help with $handle->Help() or its values with
$handle->Values($option).  He could also manipulate the argument
list.

Note that the only option information available at this point is
what has been found on the command line up to this point.  For
example, if the callback were associated with the -f option and
the command line looked like '-xvfz 1 2 3', and the v and f options
both expected one additional value, the argument list would have
only the '3' left and $handle->Values($option) would return 2.

If the callback returns a non-0 defined value, it failed.  We
execute 'die $string' where $string is the returned value.

=head2 Template non-dashed arguments

Only four  non-dashed  keys are allowed: 'required' and 'usage'
and 'mutual_exclusive'.

=head3 usage

This is a string.  Typically it wil be the first part of a
help statement and combined with the 'help' arguments for
the various dashed arguments in the template, creates the complete
usage message.  By default, we will create a usage string that
is the base name of the executable ($0) and just the string
'[options]'.

=head3 required

This is an array reference to required arguments.  It is an error
if none of these are found on the command line.

=head3 mutual_exclusive

This is an list  reference.  It says "it is an error to receive
these arguments at the same time."   For example, "tar cx" would not
make sense because you can't both create and extract at the
same time.  Give a reference for each set of mutually exclusive
arguments.  In the trivial case where you only have one set, the
argument can be just a reference to a list, but in the more complicated
case where you have sets of mutually exclusive arguments, this will
be a refrence to an list of list references.  The template to express
this might look like:

        mutual_exclusive => [ qw( -x -c ) ],
        -x => {
            help => 'Extract a tar file',
        },
        -c => {
            help => 'Create a tar file',
        }

As stated above, this would also be correct.

        mutual_exclusive => [ 
            [qw( -x -c )],
        ],
        -x => {
            help => 'Extract a tar file',
        },
        -c => {
            help => 'Create a tar file',
        }

=head2 Methods associated with the OO module:

=head3 my $handle = Getopt::OO->new(\@ARGV, %Template)

Creator function.  Expects a reference to the argument list and
a template that explanes how to parse the input arguments.   Returns
an object reference.  If you want to catch any possible errors, do

 my $handle = eval {Getopt::OO>new(\@ARGV, %template)};
 if ($@) {...

$@ will contain your error string if one exists and be empty 
otherwise.

=head3 $handle->Values(argument);

Values() returns the number of command line options that
were matched.  

Values($option) depends on the 'n_values' and the 'multiple'
for the option in the template.  If the option had no 
n_values element or n_values was 0, Values(option) will return
0 if the option was not found on the command line and 1 if
it was found.  If n_values was set to 1 and multiple was not 
set or was set to 0, we return nothing if the argument was
not found and the value of the argument if one was found.
If n_values > 1 and multiple was not set or if n_values is
1 and multiple was set, we return a list containing the
values if the values were found and nothing otherwise.  
If the of n_values is greater than 1 and multiple is set,
we retrun a list of list references -- each contining n_values
elements, or nothing if no matches were found.

The example below shows a template and accesing the values
returned by the parser.  The template is ordered from the
simplest use to the most complex.

Given the command line arguments:

 -abcde b c0 d0 d1 e0 e1 -c c1 -e e2 es
 
and the following to create our GetOpt handle:

 use Getopt::OO qw(Debug);
 my @argv = qw (-abcde b c0 d0 d1 e0 e1 -c c1 -e e2 es);
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

 Example 1.  ValuesDemo.pl

=head3 my $help_string = $handle->Help();

Get the string string we built for this template.  Note
that this can be used to check the template to make sure
it is doing what you expect.  It will contain optional
arguments separated from non optional, indicates required
and mutually exclusive options and indicates which options
expect values and how many values.

=head3 my $client_data = $handle->ClientData($option);

The ClientData method is supplied to allow data to be 
associated with an option.  The data must be scalar or
a reference.  All calls to this method return what ever
the data was replied to, but it is only set if data is
passed in.

To set the data:

 $h->ClientData($option, $x);

To get the data:

 $x = $h->ClientData($option);

=head2 Debug and Verbose Functions

We also supply two functions the user can export.  These are the
Debug and the Verbose functions.  If the functions are exported
and we find --debug or --verbose in the command line arguments,
the associated function is enabled.  These two functions behave
in multiplt ways:  If called with just a '0' or '1', the function
is disabled or disabled.  If called with no arguments, we return
the state of the function: 0 if disabled and 1 if enabled.  If
called with a list and the first element of the list looks
like a printf format statement, we behave like printf, and
otherwise we behave like a simple print statement.  If the
function is called with a single argument that is a reference
to an IO::File object, we will attempt to send all further output
to this handle.  Note that the object must be enabled before
any output will occur though.

=head2 EXPORT

None by default.

=head2 Example

=head1 AUTHOR

Steven Smith, E<lt>sjs@chaos-tools.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Steven Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
{
	# Debug and Verbose are functions used to enable
	# and disable debug output.
	# to use:
	# To send subsequent output to $fh if $ffh is an IO::File file handle.
	#  Debug($fh);
	#  Debug(1);			turns on debug output.
	#  Debug(0);			turns of debug output.
	#  Debug("%2d\n", $x);	for printf style output.
	#  Debug($string);		for print style output.
	# Verose behaviour is identical to Debug output.
	# Any call to Debug returns its state -- on or off.
	# Generic routine called from Debug and Verbose.
	sub _print_ {
		my $fh_ref = shift @_;
		my $enabled_ref = shift @_;
		if (defined $_[0] && @_ == 1
				&& (
					$_[0] =~ /^[01]$/
					|| (ref $_[0] && ref $_[0] eq 'IO::File')
				)
			) {
			if (ref $_[0]) {
				$$fh_ref = $_[0];
			}
			else {
				$$enabled_ref = $_[0];
			}
		}
		elsif ($$enabled_ref && @_) {
			if ($_[0] =~ /\%[sdfc]/) {
				my $format = shift @_;
				$$fh_ref->printf($format, @_);
			}
			else {
				$$fh_ref->print (@_);
			}
		}
		return($$enabled_ref);
	}
	# Verbose function.
	{
		my $fh = do {local *STDOUT};
		my $verbose = 0;
		sub Verbose {return(_print_(\$fh, \$verbose, @_)); }
	}
	# Debug function.
	{
		my $fh = do {local *STDOUT};
		my $debug = 0;
		sub Debug {return(_print_(\$fh, \$debug, @_)); }
	}
}

# Build and return a help string from the imput template.
sub build_help {
	sub _short_args_list_ {
		my ($template, @list) = @_;
		my (@options, @args);
		foreach my $option (sort @list) {
			my $o = ($option =~ /^-(.)/)[0];
			push @options, $o;
			if ($template->{$option}{n_values}) {
				foreach my $i (0..($template->{$option}{n_values} - 1)) {
					push @args, "${o}_arg" . (($i) ? (${i} + 1) : '');
				}
			}
		}
		(@options)
			? return('-' . join('', @options) . ' ' . join(' ', @args))
			: return('');
	}
	sub _long_args_list_ {
		my ($template, @list) = @_;
		my (@options);
		foreach my $option (sort @list) {
			push @options, $option;
			if ($template->{$option}{n_values}) {
				my $o = ($option =~ /^--(.*)/)[0];
				foreach my $i (0..($template->{$option}{n_values} - 1)) {
					$options[-1] .= " ${o}_arg" . (($i) ? ${i} : '');
				}
			}
		}
		(@options)
			? return(join(' ', @options))
			: return('');
	}

	my ($template) = @_;
	my $name = ($0 =~ m{^(?:.*/)*(.*)})[0];
	my %required = (exists $template->{required})
		? (map {$_, 1} @{$template->{required}})
		: ();
	my @optional = grep /^-/ && !/^--/ && !$required{$_}, keys %$template;
	my $short_optional_arg_list = _short_args_list_ (
		$template,
		grep(/^-/ && !/^--/ && !$required{$_}, keys %$template),
	);
	my $long_optional_arg_list = _long_args_list_ (
		$template,
		grep(/^--/ && !$required{$_}, keys %$template),
	);
	my $short_required_arg_list = _short_args_list_ (
		$template,
		grep(/^-/ && !/^--/ && $required{$_}, keys %$template),
	);
	my $long_required_arg_list = _long_args_list_ (
		$template,
		grep(/^--/ && $required{$_}, keys %$template),
	);
	my $usage = join (' ', "USAGE: $name",
		($short_optional_arg_list || $long_optional_arg_list)
			?	('[', $short_optional_arg_list, $long_optional_arg_list, ']')
			: '',
			$short_required_arg_list, $long_required_arg_list,
	) . "\n";
	# the template usage may be either a scalar or a list ref.
	# in either case, indent by 4 spaces and terminate with a 
	# linefeed.
	if($template->{usage}) {
		my @use = map {"    $_\n"}
			(ref $template->{usage})
				? @{$template->{usage}}
				: ($template->{usage});
		$usage .= join('', @use);
	}
	if (%required) {
		my @r = sort keys %required;
		$usage .= (@r > 1)
		? "    Arguments " . join(', ', @r) . " are required.\n"
		: "    Argument @r is required.\n";
	}
	if (my @m = grep /^-/ && $template->{$_}{multiple}, keys %$template) {
		$usage .= join('',
			(@m > 1)
				? "    Arguments " . join(', ', sort @m)
				: "    Argument @m",
			" may occur more than once.\n",
		);
	}

	my %options_list;
	my $max_len = 0;
	my @help;
	map {
		my $options = $_;
		# add 'arg' for each value in n_values.
		if ($template->{$_}{n_values}) {
			foreach my $i (1..$template->{$_}{n_values}) {
				$options .= ($i > 1) ? " arg_$i" : ' arg';
				$max_len = length $options if (length $options > $max_len);
			}
		}
		$options_list{$_} = $options;
	} sort grep ref $template->{$_} eq 'HASH'
			&& /^-+/
			&& exists $template->{$_}{help}
			, keys %$template;
	$max_len = ((int($max_len) / 4) + 1) * 4;
	# output is set so that the arg_list is put out the
	# first time only and all the actual help is justified 
	# to the right of the argument list.
	foreach my $key (sort keys %options_list) {
		# the help element may be either a string or a list ref.
		# output should look like:
		# -a value  first line of help
		#           second line of help
		#           etc and so on.
		my @help_list = (ref $template->{$key}{help})
			? @{$template->{$key}{help}}
			: ($template->{$key}{help});
		my $h = $options_list{$key};
		map {
			push @help, sprintf("    %-${max_len}s%s\n", $h, $_);
			$h = ''
		} @help_list;
	}
	return(join('', $usage, @help));
}

# Parse the template for correctness.
# Make sure we have only valid arguments for each of the
# elements of the template.
sub parse_template {
	my ($this, $template) = @_;
	my @errors;
	my %defined;
	# First do the non-dashed options.

	foreach my $option (sort grep !/^-+/,  keys %$template) {
		my $ref = $template->{$option};
		if ($option eq 'mutual_exclusive') {
			unless (ref $ref eq 'ARRAY') {
				push @errors, "Bad mutual_exclusive argument.  Should be ",
					"a list or a list of lists.\n";
			}
		}
		elsif ($option eq 'required') {
			unless (ref $ref && ref $ref eq 'ARRAY') {
				push @errors, "required should be a list reference.\n";
			}
		}
		last if @errors;
	}
	foreach my $option (sort grep /^-+/,  keys %$template) {
		my $ref = $template->{$option};
		foreach my $key (sort keys %$ref) {
			if ($defined{$key}) {
				push @errors, "$key defined multiple times.\n";
			}
			elsif ($key eq 'callback'
					|| $key eq 'help'
					|| $key eq 'multiple') {
				# already took care of this.  Just skip
			}
			elsif ($key eq 'n_values') {
				if ($ref->{n_values} !~ /^\d+$/) {
					push @errors,
						"$key: n_values is $ref->{n_values} and should be an ",
						"integer\n";
				}
			}
			elsif ($key =~ /^-{1,2}[^-]/) {
				# Make sure keys for template entry are valid.
				my @bad = grep /^(help|n_values|multiple)$/, %$ref;
				push @errors, "$key has invalid keys: @bad\n";
			}
			else {
				push @errors, "Unrecognized option: $key\n";
			}
			last if @errors;
		}
		%{$this->{$option}} = %{$template->{$option}} unless @errors;
	}
	(@errors) ? return(@errors) : return;
}
sub parse_options {
	my ($this, $argv, $template) = @_;
	my @errors = ();
	$this->{errors} = \@errors;
	while (@$argv && $argv->[0] =~ /^-/ && !@errors) {
		# If the option starts with a single dash, split it into smaller
		# one character args preceeded by a dash.
		my @options = ($argv->[0] =~ /^--/)
			? ($argv->[0])
			: do {
				my $a = ($argv->[0] =~ /^-(.*)/)[0];
				map {"-$_"} split //, $a;
			};
		shift @$argv;
		while (defined (my $option = shift @options)) {
			if ($template->{$option}) {
				my $ref = $template->{$option};
				# If this option has already been encountered and multiple
				# isn't set, we have an error.
				if (exists $this->{$option}{exists} && !$ref->{multiple}) {
					push @errors,
						"$option encountered more than once and multiple ",
							"is not set.\n";
				}
				# If we have n_values set, we're pulling one or more
				# values off the command line for this argument.
				elsif (my $n_values = $ref->{n_values}) {
					$this->{$option}{n_values} = $ref->{n_values};
					$this->{$option}{multiple} = $ref->{multiple} || 0;
					# If n_values is greater than 1, pull the next
					# n_values values off of the command line and save
					# it in the values list as an array ref.
					if ($n_values > 1) {
						my @in;
						do {
							if (@$argv) {
								push @in, shift @$argv;
							}
							else {
								push @errors,
									"Insufficent values for $option\n";
							}
						} while (--$n_values && !@errors);
						# Multiple, we save it as a list of lists,
						# non-multiple, save as a list ref.
						if ($ref->{multiple}) {
							push(@{$this->{$option}{values}}, \@in);
						}
						else {
							$this->{$option}{values} = \@in;
						}
					}
					else {
						(@$argv)
							? ($this->{$option}{multiple})
								? push(@{$this->{$option}->{values}},
									shift @$argv)
								: ($this->{$option}{values} = shift @$argv)
							: push @errors, "Insufficent values for $option\n";
					}
				}
				# n_values isn't set.  Just push 1 on the values stack
				# for this guy.
				else {
					$this->{$option}->{values} = 1;
				}
				if (!@errors && $ref->{callback}) {
					if (my $error = &{$ref->{callback}}($this, $option)) {
						push @errors, "Callback returned an error:\n\t"
							. "$error\n";
					}
				}
			}
			else {
				push @errors, "unrecognized option: $option\n";
			}
			$this->{$option}{exists}++;
		}
		last if @errors;
	}
}

# Object creater.
sub new {
	my $self = shift @_;
	my (@errors, %this, @mutual_exclusive, @required);
	# Check for correctness of input arguments.
	if (!ref $_[0] || ref $_[0] ne 'ARRAY') {
		push @errors, "Usage: Getopt::OO::new(ref array, hash);\n",
			"first argment must be a reference to an array.\n";
	}
	else {
		# Check for an odd number of elements in the @_.  This is
		# even for the hash +1 for the argv reference.
		unless (@_ & 1) {
			push @errors, "Usage: Getopt::OO::new(ref array, hash);\n",
				"hash has an odd number of elements.\n";
		}
	}
	bless( \%this, $self);
	my ($argv, %template) = @_ unless @errors;
	$this{help} = build_help(\%template);
	unless (@errors) {
		# Check odd elements for uniqueness.  We must check before
		# the template before it becomes a hash or we lose the
		# error that the same option was declared multiple times.
		my %keys;
		my $i = 0;
		if (my @bad = grep $i++ && $keys{$_}++, @_) {
			push @errors, "Options \"@bad\" declared more than once.\n";
		}
	}
	unless (@errors) {
		# Build help first so we have something to print on error exit.

		# Check to make sure we have valid input args.  All args must have
		# 1 or 2 leading dashes or be 'required', 'mutual_exclusive' or
		# 'usage'.
		@errors = parse_template(\%this, \%template);
	}
	unless (@errors) {
		parse_options(\%this, $argv, \%template);
		@errors = (exists $this{errors}) ? @{$this{errors}} : ();
	}
	# Check for required options.
	unless (@errors) {
		my %required = ($template{'required'})
			? map {$_, 1} @{$template{'required'}}
			: ();
		if (%required) {
			# pull any required options we encountered out,
			# compare the number of required found against
			# the number of required options and if they are
			# different, figure out what's missing and make
			# an error message.
			my %x;
			my @r = grep !$x{$_}++ && $required{$_} && $this{$_}{exists}
				, keys %this;
			unless(@r && @r == scalar(keys %required)) {
				my %r = map {$_,1} @r;
				my @missing = grep !$r{$_}, keys %required;
				push @errors, "Missing required options: @missing\n";
			}
		}
	}
	# Check for mutually exclusive options.
	unless (@errors) {
		if (exists $template{mutual_exclusive}) {
			if (ref $template{mutual_exclusive}) {
				my @mutual_exclusive = @{$template{mutual_exclusive}};
				my @options = grep $_ =~ /^-/ && $this{$_}{exists}, keys %this;
				if (ref $mutual_exclusive[0]) {
					foreach my $ref (@mutual_exclusive) {
						my %check_hash = map {$_, 1} @$ref;
						if ((my @bad = grep $check_hash{$_}, @options) > 1) {
							push @errors, "Found mutually exclusive options: ",
								"@bad\n";
						}
					}
				}
				# simple case: this could be just a list.
				else {
					my %check_hash = map {$_, 1} @mutual_exclusive;
					if ((my @bad = grep $check_hash{$_}, @options) > 1) {
						push @errors, "Found mutually exclusive options: ",
							"@bad\n";
					}
				}
			}
			else {
				die "argument to mutual_exclusive should be an ",
					"array reference.\n";
			}
		}
	}
	if (@errors) {
		die $this{help}, "Found following errors:\n", @errors;
	}
	return(\%this);
}
sub Help {return $_[0]->{help}}
#     If no key is given, return the number of options found.
#     If single value and no multiple set, unless user wants an
# array back, return a scalar. If they want an array, give
# 'em an array. 
#     If user wants multiple value single time,  give 'em an
# array back.
#     If user wants multiple value multiple times, give 'em a
# an array of list ref's.
sub Values {
	my ($this, $key) = @_;
	if ($key) {
		if (exists $this->{$key}) {
			my $ref = $this->{$key};
			($ref->{n_values})
				? ($ref->{multiple})
					? return(@{$ref->{values}})
					: ($ref->{n_values} == 1)
						? return($ref->{values})
						: return(@{$ref->{values}})
				: return($ref->{values} || 0)
		}
		else {
			die "Values called on undefined option.\n";
		}
	}
	else {
		return(scalar grep /^-/ && $this->{$_}{exists}, keys %$this);
	}
}

sub ClientData {
	my ($this, $option, $data) = @_;
	if ($option && $this->{$option}) {
		$this->{$option}{client_data} = $data if @_ == 3;
	}
	else {
		die "ClientData called on undefined option.\n";
	}
	(exists $this->{$option}{client_data})
		? return($this->{$option}{client_data})
		: return;
}
1;

__END__
