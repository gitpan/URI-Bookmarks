# URI::Bookmark::Netscape --
# Perl module containing routines for individual Netscape bookmarks
#
# Copyright (c) 1999 Adam Spiers <adam@spiers.net>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Netscape.pm,v 1.1 1999/11/08 17:01:23 localadams Exp $
#

package URI::Bookmark::Netscape;

use strict;

require 5.004;
use URI::Bookmark;

=head1 NAME

URI::Bookmarks::Netscape - Perl module containing routines for
individual Netscape bookmarks

=head1 SYNOPSIS

See L<URI::Bookmarks>.

=head1 DESCRIPTION

URI::Bookmark::Netscape contains some helper routines specifically for
URI::Bookmark objects which were originally from Netscape bookmark files.

=cut

sub HTML_attribs {
  my $self = shift;
  my @attribs = @_;

  my $out = '';

  foreach my $attrib (@attribs) {
    next unless exists $self->attribute->{$attrib};

    $out .= " $attrib";
    my $value = $self->attribute->{$attrib};
    $out .= qq{="$value"} if defined $value;
  }

  return $out;
}

=head1 AUTHOR

Adam Spiers <adam@spiers.net>

=head1 SEE ALSO

L<URI::Bookmarks>, L<URI::Bookmarks::*>, L<URI::Bookmark>, L<perl(1)>.

=cut

