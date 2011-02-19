package Bash::Completion::Plugins::Perldoc;

# ABSTRACT: complete perldoc command line

use strict;
use warnings;

use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils
  qw( command_in_path match_perl_modules prefix_match );
use File::Spec::Functions qw/ catfile rel2abs catdir splitpath no_upwards /;
use List::MoreUtils qw/ apply uniq /;

=method should_activate

Activate this C<Bash::Completion::Plugins::Perldoc> plugin if we can
find the C<perldoc> command.

=cut

sub should_activate {
  my @commands = ('perldoc');
  return [grep { command_in_path($_) } @commands];
}


=method generate_bash_setup

Make sure we use bash C<complete> options C<nospace> and C<default>.

=cut

sub generate_bash_setup { return [qw( nospace default )] }


=method complete

Completion logic for C<perldoc>. Completes Perl modules only for now.

=cut

sub complete {
  my ($class, $req) = @_;

  my @args = $req->args;
  pop @args; # last is the word

  use XXX;
  # WWW \@args;

  my $function = @args && $args[-1] eq '-f' 
    ? \&get_function_suggestions
    : \&get_package_suggestions
    ;

  $req->candidates( $function->( $req->word ) );
}

sub slurp_dir {
	opendir my $dir, shift or return;
	no_upwards readdir $dir;
}

sub suggestion_from_name {
	my ( $file_rx, $path, $name ) = @_;
	return if not $name =~ /$file_rx/;
	return $name.'::', $name.':: ' if -d catdir $path, $name;
	return $1;
}

sub suggestions_from_path {
	my ( $file_rx, $path ) = @_;
	map { suggestion_from_name( $file_rx, $path, $_ ) } slurp_dir( $path );
}

sub get_package_suggestions {
	my ( $pkg ) = @_;

	my @segment = split /::|:\z/, $pkg, -1;
	my $file_rx = qr/\A(${\quotemeta pop @segment}\w*)(?:\.pm|\.pod)?\z/;

	my $home = rel2abs $ENV{'HOME'};
	my $cwd = rel2abs do { require Cwd; Cwd::cwd() };

	my @suggestion =
        uniq
        map { ( my $x = $_ ) =~ s/::\s$/::/; $x }
		map { suggestions_from_path $file_rx, $_ }
		uniq 
        map { catdir $_, @segment }
		grep { $home ne $_ and $cwd ne $_ }
		map { $_, ( catdir $_, 'pod' ) }
		map { rel2abs $_ }
		@INC;

	# fixups
	if ( $pkg eq '' ) {
		my $total = @suggestion;
		@suggestion = grep { not /^perl/ } @suggestion;
		my $num_hidden = $total - @suggestion;
		push @suggestion, "perl* ($num_hidden hidden)" if $num_hidden;
	}
	elsif ( $pkg =~ /(?<!:):\z/ ) {
		@suggestion = map { ":$_" } @suggestion;
	}

	return @suggestion;
}

sub get_function_suggestions {
	my ( $func ) = @_;

	my $perlfunc;
	for ( @INC, undef ) {
		return if not defined;
		$perlfunc = catfile( $_, qw( pod perlfunc.pod ) );
		last if -r $perlfunc;
	}

	open my $fh, '<', $perlfunc or return;

	my @suggestion;
	my $nest_level = -1;
	while ( <$fh> ) {
		next if 1 .. /^=head2 Alphabetical Listing of Perl Functions$/;
		++$nest_level if /^=over/;
		--$nest_level if /^=back/;
		next if $nest_level;
		push @suggestion, /^=item (-?\w+)/;
	}

	my $func_rx = qr/\A${\quotemeta $func}/;

	return grep { /$func_rx/ } @suggestion;
}

1;

__END__

=head1 SYNOPSIS

    ## not to be used directly

=head1 DESCRIPTION

A plugin for the C<perldoc> command. Completes module names, for now.
