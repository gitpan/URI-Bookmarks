# URI::Bookmarks::Netscape --
# Perl module containing routines for Netscape bookmark files
#
# Copyright (c) 1999 Adam Spiers <adam@spiers.net>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Netscape.pm,v 1.2 1999/11/08 17:00:34 localadams Exp $
#

package URI::Bookmarks::Netscape;

use strict;

require 5.004;
use AutoLoader qw(AUTOLOAD);
use Carp;
use URI::Bookmark::Netscape;
use URI::Bookmarks;

=head1 NAME

URI::Bookmarks::Netscape - Perl module containing routines for
Netscape bookmark files

=head1 SYNOPSIS

  See L<URI::Bookmarks>.

=head1 DESCRIPTION

URI::Bookmarks::Netscape contains some helper routines specifically
for URI::Bookmarks objects which were originally Netscape bookmark
files.

=cut


1;
########################    End of preloaded code    ########################
__END__

sub import_bookmarks {
  my $self = shift;
  my %p = @_;

  my ($input_type, $source) = figure_out_input(\%p);
  
  my $current_folder = $self->tree_root;
  my $first = 1;
  my $in_DD = 0;
  my $in_preamble = 1;
  my ($last_folder, $last_bookmark);

  while ($_ = get_line($input_type, \%p)) {
    chomp;

    if (m{^\s*<DT><A (.*?)>(.*)</A>$}i) {
      my ($attribs, $bookmark) = ($1, $2);

      $in_DD = 0;
      undef $last_folder;

      my $new_bookmark = $current_folder->new_daughter;
      $new_bookmark->name($bookmark);
      $new_bookmark->type('bookmark');

      my @attribs = split /\s+/, $attribs;
      foreach my $attrib (@attribs) {
        if (my ($name, $value) = ($attrib =~ /^([^=]+)(?:="(.*)")?$/)) {
          $new_bookmark->set_attribs($name => $value);
        }
      }

      $last_bookmark = $new_bookmark;

      next;
    }

    if (m{^\s*<DT><H3 (.*?)>(.*)</H3>$}i) {
      my ($attribs, $folder) = ($1, $2);

      undef $last_bookmark;
      $in_DD = 0;

      my $new_folder = $current_folder->new_daughter;
      $new_folder->name($folder);
      $new_folder->type('folder');

      my @attribs = split /\s+/, $attribs;
      foreach my $attrib (@attribs) {
        if (my ($name, $value) = ($attrib =~ /^([^=]+)(?:="(.*)")?$/)) {
          $new_folder->set_attribs($name, $value);
        }
      }

      $last_folder = $new_folder;
      next;
    }

    if (m{^\s*<HR>$}i) {
      $in_DD = 0;
      undef $last_bookmark;
      undef $last_folder;

      my $rule = $current_folder->new_daughter;
      $rule->name('----------');
      $rule->type('rule');

      next;
    }

    if (m{^\s*<DL><p>$}i) {
      $in_DD = 0;
      $in_preamble = 1;

      if ($first) {
        $first = 0;
        next;
      }

      $current_folder = $last_folder;

      undef $last_bookmark;
      undef $last_folder;

      next;
    }

    if (m{^\s*</DL><p>$}i) {
      $in_DD = 0;
      undef $last_folder;
      undef $last_bookmark;

      $current_folder = $current_folder->mother;

      next;
    }

    if (m{^<DD>(.*)}i) {
      $in_DD = 1;

      my $last = $last_bookmark || $last_folder;
      # This should really call set_attribs to be properly OO but we
      # don't care too much.
      $last->attribute->{description} .= "$1\n";

      next;
    }      

    if ($in_DD) {
      my $last = $last_bookmark || $last_folder;
      # This should really call set_attribs to be properly OO but we
      # don't care too much.
      $last->attribute->{description} .= "$_\n";
      next;
    }

    if ($in_preamble) {
      if (m{^<!DOCTYPE (.+)>$}i) {
        $self->{origin}{doctype} = $1;
        next;
      }

      if (m{^<!-- This is an automatically generated file.$} ||
          m{^It will be read and overwritten.$} ||
          m{^Do Not Edit! -->$})
        {
          $self->{origin}{preamble} .= "$_\n";
          next;
        }

      if (m{^<TITLE>(.+)</TITLE>$}i) {
        $self->title($1);
        next;
      }
    
      if (m{^<H1>(.+)</H1>$}i) {
        $self->tree_root->name($1);
        next;
      }

      next if /^\s*$/;
    }

    warn "Ignoring line $line_num of $source:\n$_\n";
  }

  close(BOOKMARKS);

  $self->{origin}{type} = 'Netscape bookmarks file';
  $self->{origin}{source} = $source;
}

sub doctype {
  my $self = shift;

  return $self->{origin}{doctype} || 'NETSCAPE-Bookmark-file-1';
}

sub preamble {
  my $self = shift;

  return $self->{origin}{preamble};
}

use vars qw($out);
  
sub export {
  my $self = shift;

  my @lines = ();

  push @lines, "<!DOCTYPE " . $self->URI::Bookmarks::Netscape::doctype . ">\n";
  push @lines, $self->URI::Bookmarks::Netscape::preamble;
  push @lines, "<TITLE>" . $self->title . "</TITLE>\n";
  push @lines, "<H1>" . $self->tree_root->name . "</H1>\n";
  push @lines, "\n";
  push @lines, "<DL><p>\n";

  $self->tree_root->walk_down({
                               lines        => \@lines,
                               callback     => \&pre_output_node,
                               callbackback => \&post_output_node,
                              });

  push @lines, "</DL><p>\n";

  return @lines;
}

##############################################################################
# end of methods
##############################################################################

sub figure_out_input {
  my ($p) = @_;

  if (exists $p->{handle}) {
    if (exists $p->{file}) {
      return ('handle', $p->{file});
    }
    else {
      return ('handle', 'file handle');
    }
  }
  elsif (exists $p->{array}) {
    return ('array',  'array');
  }
  else {
    croak "Couldn't figure out type of input bookmarks " .
          "(must be handle or array).\n";
  }
}

my $line_num = 0;

sub get_line {
  my ($type, $p) = @_;
  
  if ($type eq 'handle') {
    my $fh = $p->{handle};
    $line_num++;
    return scalar(<$fh>);
  }
  elsif ($type eq 'array') {
    return $p->{array}->[$line_num++];
  }
  else {
    croak "Couldn't figure out type of input bookmarks " .
          "(must be handle or array).\n";
  }
}

sub pre_output_node {
  my ($node, $options) = @_;
  my $lines = $options->{lines};

  my $indent = ' ' x (4 * ($options->{_depth} || 0));

  my $type = $node->type;

  if ($type eq 'folder') {
    my $title = $node->name;
    my $HTML_attribs
      = $node->URI::Bookmark::Netscape::HTML_attribs(qw/FOLDED ADD_DATE/);
    push @$lines, "$indent<DT><H3$HTML_attribs>$title</H3>\n";
  }
  elsif ($type eq 'bookmark') {
    my $title = $node->name;
    my $HTML_attribs
      = $node->URI::Bookmark::Netscape::HTML_attribs(qw/HREF ALIASOF ALIASID
                                                        ADD_DATE LAST_VISIT
                                                        LAST_MODIFIED/);
    push @$lines, "$indent<DT><A$HTML_attribs>$title</A>\n";
  }
  elsif ($type eq 'rule') {
    push @$lines, "$indent<HR>\n";
  }

  my $description = $node->attribute->{description};
  push @$lines, "<DD>$description" if $description;

  if ($type eq 'folder') {
    push @$lines, "$indent<DL><p>\n";
  }

  return 1;
}

sub post_output_node {
  my ($node, $options) = @_;
  my $lines = $options->{lines};

  my $indent = ' ' x (4 * $options->{_depth});

  if ($node->type eq 'folder') {
    push @$lines, "$indent</DL><p>\n";
  }
}

=head1 AUTHOR

Adam Spiers <adam@spiers.net>

=head1 SEE ALSO

L<URI::Bookmarks>, L<URI::Bookmarks::*>, L<URI::Bookmark>,
L<URI::Bookmark::*>, L<perl(1)>.

=cut

