# URI::Bookmark --
# Perl module class encapsulating a generic bookmark file entry
# (a bookmark, bookmark folder, or entry separator)
#
# Copyright (c) 1999 Adam Spiers <adam@spiers.net>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Bookmark.pm,v 1.2 1999/11/08 17:00:26 localadams Exp $
#

package URI::Bookmark;

use strict;

require 5.004;
use AutoLoader qw(AUTOLOAD);
use Tree::DAG_Node;
use Carp;

use vars qw(@ISA);
@ISA = qw(Tree::DAG_Node);

=head1 NAME

URI::Bookmark - Perl module class encapsulating an entry in a typical
bookmark file.

=head1 SYNOPSIS

See L<URI::Bookmarks>.

=head1 DESCRIPTION

URI::Bookmark is a subclass of Tree::DAG_Node, so that each entry in
the bookmark collection is a node in a directed acyclic graph.

All methods from Tree::DAG_Node are available.

Each instance has a type, which can be:

   `root'       --  the root of the bookmark tree (this is also a folder)
   `folder'     --  a folder containing more entries 
   `bookmark'   --  a bookmark (duh)
   `rule'       --  a horizontal rule separating entries

=cut

use vars qw(@allowed_types %allowed_types @allowed_attribs %allowed_attribs);

@allowed_types = qw/root folder bookmark rule/;
%allowed_types = map { $_ => 1 } @allowed_types;

@allowed_attribs = qw/
                      HREF
                      ADD_DATE
                      LAST_VISIT
                      LAST_MODIFIED
                      FOLDED
                      ALIASID
                      ALIASOF
                      description
                     /;
%allowed_attribs = map { $_ => 1 } @allowed_attribs;


sub new {
  my $this = shift;
  my %p = @_;

  my $class = ref $this || $this;

  my $self = new Tree::DAG_Node;
  bless $self, $class;

  $self->set_attribs(%p);

  return $self;
}

1;
########################    End of preloaded code    ########################
__END__

=head2 METHODS

=over 4

=item * B<set_attribs>

  $bookmark->set_attribs(name => 'Slashdot',
                         type => bookmark,
                         HREF => 'http://slashdot.org');

This method should be self-explanatory.  The allowed attributes are:
`name', `type', `HREF', `ADD_DATE', `LAST_MODIFIED', `LAST_VISIT',
`ALIASOF', `ALIASID', `description'.  Attempts to set any others will
be ignored and generate a warning.

=cut

sub set_attribs {
  my $self = shift;
  my %p = @_;

  while (my ($key, $value) = each %p) {
    if ($key eq 'name') {
      $self->name($value);
    }
    elsif ($key eq 'type') {
      $self->type($value);
    }
    else {
      if (exists $allowed_attribs{$key}) {
        $self->attribute->{$key} = $value;
      }
      else {
        carp "`$key' is not a valid attribute";
      }
    }
  }
}

=item * B<dump_attribs>

  $bookmark->dump_attribs();

Dumps all attribute (key, value) pairs for this node, one per line.
This is only really for debugging.

=cut

sub dump_attribs {
  my $self = shift;

  while (my ($key, $value) = each %{$self->{attributes}}) {
    $value ||= '__undef__';
    print "$key: $value\n";
  }
}

=item * B<type>

  my $type = $bookmark->type();

  $bookmark->type($new_type);

If a parameter is specified, sets the bookmark to the type given by
it.  Generates a warning if the type given isn't valid.

Returns the current type of the bookmark.

=cut

sub type {
  my $self = shift;
  my ($new_type) = @_;
  
  if (defined $new_type) {
    if (exists $allowed_types{$new_type}) {
      $self->attribute->{type} = $new_type;
    }
    else {
      croak "`$new_type' is not a valid bookmark type";
    }
  }

  return $self->attribute->{type};
}

=back

=head1 AUTHOR

Adam Spiers <adam@spiers.net>

=head1 SEE ALSO

L<URI::Bookmarks>, L<URI::Bookmarks::*>, L<URI::Bookmark::*>, L<perl(1)>.

=cut

