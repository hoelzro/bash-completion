package Bash::Completion::Plugins::Perldoc;

# ABSTRACT: complete perldoc command line

use strict;
use warnings;
use parent 'Bash::Completion::Plugin';
use Bash::Completion::Utils
  qw( command_in_path match_perl_modules prefix_match );

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

  $req->candidates(match_perl_modules($req->word));
}

1;

__END__

=head1 SYNOPSIS

    ## not to be used directly

=head1 DESCRIPTION

A plugin for the C<perldoc> command. Completes module names, for now.

A future version should use the work of Aristotle Pagaltzis at
L<http://github.com/ap/perldoc-complete>.
