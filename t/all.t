#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => (3 + (3 * 15)) }

use URI::Bookmarks;

my $sample_file = 't/sample.bookmarks';

my @bookmarks = ();


unless (open(LETTER, $sample_file)) {
  die "Failed to open sample.bookmarks: $!\n";
}
my @lines = <LETTER>;

print "Testing new(array => ...) constructor ...\n";
$bookmarks[0] = new URI::Bookmarks(array => \@lines);
ok($bookmarks[0] ? 1 : 0);

print "Testing new(file => ...) constructor ...\n";
$bookmarks[1] = new URI::Bookmarks(file => $sample_file);
ok($bookmarks[1] ? 1 : 0);

print "Testing new(handle => ...) constructor ...\n";
seek(LETTER, 0, 0);
$bookmarks[2] = new URI::Bookmarks(handle => \*LETTER);
ok($bookmarks[2] ? 1 : 0);

close(LETTER);


print "Testing title() ...\n";
multi_test(sub { ok($bookmarks[$_[0]]->title,
                    'Bookmarks for Adam Spiers (title)'); });


print "Testing origin() ...\n";
multi_test(sub {
             my $origin = $bookmarks[$_[0]]->origin;
             ok($origin->{type}, 'Netscape bookmarks file');
             ok($origin->{doctype}, 'NETSCAPE-Bookmark-file-1');
             ok($origin->{preamble} =~ /<!-- This is an auto.*Edit! -->/s);
           });
ok($bookmarks[0]->origin->{source}, 'array');
ok($bookmarks[1]->origin->{source}, $sample_file);
ok($bookmarks[2]->origin->{source}, 'file handle');


print "Testing export() ...\n";
multi_test(sub {
             my @lines2 = $bookmarks[$_[0]]->export('Netscape array');
             ok(join('', @lines) , join('', @lines2));
           });


print "Testing name_to_nodes() and build_name_lookup() ...\n";
multi_test(sub {
             my @search = $bookmarks[$_[0]]->name_to_nodes('Search');
             ok(scalar(@search), 1);
             ok(exists $search[0]->attribute->{FOLDED});
             my $autos = ($bookmarks[$_[0]]->name_to_nodes('Autos'))[0];
             ok($autos->attribute->{HREF},
                'http://home.netscape.com/bookmark/4_7/ptchannelautos.html');
             ok($autos->attribute->{ADD_DATE}, '940802141');
             $autos->name('Search');
             $bookmarks[$_[0]]->build_name_lookup();
             @search = $bookmarks[$_[0]]->name_to_nodes('Search');
             ok(scalar(@search), 2);
           });

print "Testing all_URLs ...\n";
multi_test(sub {
             my @all_URLs = $bookmarks[$_[0]]->all_URLs;
             ok(scalar(@all_URLs), 112);
           });

print "Testing tree_root() and type() ...\n";
multi_test(sub {
             ok($bookmarks[$_[0]]->tree_root->type(), 'root');
             my $autos = ($bookmarks[$_[0]]->name_to_nodes('People'))[0];
             ok($autos->type(), 'bookmark');
             my $channels = ($bookmarks[$_[0]]->name_to_nodes('Channels'))[0];
             ok($channels->type(), 'folder');
           });


exit 0;

##############################################################################

sub multi_test {
  my ($code) = @_;

  foreach my $i (0 .. 2) {
    &$code($i);
  }
}
