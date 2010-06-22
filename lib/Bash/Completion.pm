package Bash::Completion;

# ABSTRACT: Extensible system to provide bash completion

use strict;
use warnings;
use Bash::Completion::Request;
use Module::Pluggable
  search_path => ['Bash::Completion::Plugins'],
  sub_name    => 'plugin_names';

=method new

Create a L<Bash::Completion> instance.

=cut

sub new { return bless {}, $_[0] }


=method complete

=cut

sub complete {
  my ($self, $plugin, $cmd_line) = @_;

  my $class = "Bash::Completion::Plugins::$plugin";
  return unless $self->_load_class($class);

  my $req = Bash::Completion::Request->new;
  $class->new(args => $cmd_line)->complete($req);

  return $req;
}


=method setup

=cut

sub setup {
  my ($self) = @_;
  my $script = '';

  for my $plugin ($self->plugins) {
    my $cmds = $plugin->should_activate;
    next unless @$cmds;

    my $snippet = $plugin->generate_bash_setup($cmds);

    if (ref $snippet) {
      my $options = join(' ', map {"-o $_"} @$snippet);
      my $plugin_name = ref($plugin);
      $plugin_name =~ s/^Bash::Completion::Plugins:://;

      $snippet = join(
        "\n",
        map {
          qq{complete -C 'bash-complete complete $plugin_name' $options $_}
          } @$cmds
      );
    }

    $script .= "$snippet\n" if $snippet;
  }

  return $script;
}


=method plugins

Search C<@INC> for all classes in the L<Bash::Completion::Plugin> namespace.

=cut

sub plugins {
  my ($self) = @_;

  unless ($self->{plugins}) {
    my @plugins;

    for my $plugin_name ($self->plugin_names) {
      next unless $self->_load_class($plugin_name);

      push @plugins, $plugin_name->new;
    }

    $self->{plugins} = \@plugins;
  }

  return @{$self->{plugins}};
}


#######
# Utils

sub _load_class { return eval "require $_[1]" }

1;
