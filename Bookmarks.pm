# URI::Bookmarks --
# Perl module class encapsulating bookmark files
#
# Copyright (c) 1999 Adam Spiers <adam@spiers.net>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Bookmarks.pm,v 1.3 1999/11/09 01:42:04 localadams Exp $
#

package URI::Bookmarks;

use strict;

require 5.004;
use AutoLoader qw(AUTOLOAD);
use Carp;
use URI::Bookmarks::Netscape;

use vars qw($VERSION);
$VERSION = '0.92';

=head1 NAME

URI::Bookmarks - Perl module class encapsulating bookmark files

=head1 SYNOPSIS

  use URI::Bookmarks;

  # URI::Bookmarks automagically detects that we're dealing with a
  # collection of Netscape bookmarks

  my $bookmarks =
    new URI::Bookmarks(file => "$ENV{HOME}/.netscape/bookmarks.html");

  my $bookmarks = new URI::Bookmarks(handle => $fh);

  my $bookmarks = new URI::Bookmarks(array => \@lines);
  
  # Manipulate $bookmarks using nice tree methods from Tree::DAG_Node,
  # e.g. delete all bookmarks under $folder:
  ($bookmarks->name_to_nodes($folder))[0]->unlink_from_mother();

  # Then output the new file.
  print $bookmarks->export('Netscape array');

=head1 DESCRIPTION

URI::Bookmarks provides a class for manipulating hierarchical
collections of bookmarks.  Each entry in the collection is an object
of type URI::Bookmark, which is in turn a subclass of Tree::DAG_Node,
and hence all standard tree manipulation methods are available (see
the documentation for Tree::DAG_Node).

=cut

sub new {
  my $this = shift;

  my $class = ref $this || $this;

  my $self = {};
  bless $self, $class;
  $self->init();

  # Automatically figure out what sort of collection of bookmarks we are.
  # Currently, this isn't very cunning.
  if (@_ % 2 == 0) {
    my %p = @_;
    if ($p{file}) {
      open(BOOKMARKS, "<$p{file}") or croak "Couldn't open `$p{file}'";
      $self->URI::Bookmarks::Netscape::import_bookmarks(handle => \*BOOKMARKS,
                                                        %p);
      close(BOOKMARKS) or croak "Couldn't close `$p{file}'";
    }
    else {
      $self->URI::Bookmarks::Netscape::import_bookmarks(%p);
    }
  }
  else {
    croak "URI::Bookmarks::new must be passed a hash";
  }

  return $self;
}

sub init {
  my $self = shift;

  $self->tree_root(new URI::Bookmark);
}

1;
########################    End of preloaded code    ########################
__END__

=over 4

=item * B<build_name_lookup>

  $bookmarks->build_name_lookup();

This method builds an internal hash which maps node names to arrays of
nodes which have the corresponding key as their name.

It only needs to be called if you want to rebuild the hash after
modifying the bookmark collection in some way; if the hash is needed
and has not been built, it will be built automatically.

=cut

sub build_name_lookup {
  my $self = shift;

  $self->{name_to_nodes} = { };

  my @descendants = $self->tree_root->descendants;
  foreach my $descendant (@descendants) {
    my $name = $descendant->name;
    push @{$self->{name_to_nodes}{$name}}, $descendant;
  }
}

=item * B<tree_root>

  my $tree_root_node = $bookmarks->tree_root();

  $bookmarks->tree_root($new_root);

Returns the current root node of the tree of bookmarks.  If the
optional parameter is provided, the root node is changed to it.

=cut

sub tree_root {
  my $self = shift;

  my ($new_root) = @_;

  if ($new_root) {
    $new_root->type('root');
    $self->{root} = $new_root;
  }

  return $self->{root};
}

=item * B<name_to_nodes>

  my @nodes = $bookmarks->name_to_nodes('Cinemas');

Returns an array of all nodes matching the given name.

=cut

sub name_to_nodes {
  my $self = shift;
  my ($name) = @_;

  if (! exists $self->{name_to_nodes}) {
    $self->build_name_lookup;
  }

  return () unless exists $self->{name_to_nodes}{$name};
  my @nodes = @{$self->{name_to_nodes}{$name}};
  return () if @nodes == 0;
  return @nodes;
}

=item * B<title>

  my $title = $bookmarks->title();

  $bookmarks->title($new_title);

Returns the current title of the collection of bookmarks.  If the
optional parameter is provided, the title is changed to it.

=cut

sub title {
  my $self = shift;
  my ($new_title) = @_;
  
  $self->{title} = $new_title if defined $new_title;

  return $self->{title};
}

=item * B<origin>

  my $origin = $bookmarks->origin();
  my $origin_type = $origin{type};

Returns a hash containing information about the origin of the
collection of bookmarks.

=cut

sub origin {
  my $self = shift;

  return $self->{origin};
}

=item * B<export>

  my @lines = $bookmarks->export('Netscape array');

The interface to the export routines.  The examples above show the 
currently available export types.

=cut

sub export {
  my $self = shift;
  my ($new_type) = @_;

  if ($new_type eq 'Netscape array') {
    return $self->URI::Bookmarks::Netscape::export();
  }
  else {
    croak "`$new_type' is an invalid export type";
  }
}

=item * B<all_URLs>

  $bookmarks->all_URLs();

This method simply returns an array of all the URLs in the collection
of bookmarks.

=cut

sub all_URLs {
  my $self = shift;

  my ($root) = @_;
  $root ||= $self->tree_root();

  my @urls = ();

  $root->walk_down({urls     => \@urls,
                    callback => \&callback_all_URLS});

  return @urls;
}

sub callback_all_URLS {
  my ($node, $options) = @_;

  my $type = $node->type;
  if ($type eq 'bookmark') {
    push @{$options->{urls}}, $node->attribute->{'HREF'};
  }

  return 1;
}

=back

=head1 BUGS

The C<file> key of C<new()> might not be safe.

=head1 AUTHOR

Adam Spiers <adam@spiers.net>

=head1 SEE ALSO

L<URI::Bookmarks::*>, L<URI::Bookmark>, L<URI::Bookmark::*>,
L<perl(1)>.

=cut

