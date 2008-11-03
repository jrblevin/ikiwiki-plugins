#!/usr/bin/perl

package IkiWiki::Plugin::metamail;

use warnings;
use strict;
use IkiWiki 2.00;

sub import {
    hook(type => "getsetup", id => "metamail", call => \&getsetup);
    hook(type => "needsbuild", id => "metamail", call => \&needsbuild);
    hook(type => "filter", id => "metamail", call => \&filter);
    hook(type => "pagetemplate", id => "metamail", call => \&pagetemplate);
}

sub getsetup () {
    return
        plugin => {
            safe => 1,
            rebuild => undef,
        },
}

sub needsbuild (@) {
    my $needsbuild = shift;
    foreach my $page (keys %pagestate) {
        if (exists $pagestate{$page}{metamail}) {
            if (exists $pagesources{$page} &&
                grep { $_ eq $pagesources{$page} } @$needsbuild) {
                # remove state, it will be re-added
                # if the preprocessor directive is still
                # there during the rebuild
                delete $pagestate{$page}{metamail};
            }
        }
    }
}

sub filter(@) {
    my %params = @_;
    my $page = $params{page};
    my $content = $params{content};

    eval q{use HTML::Entities};

    my ($head, $body) = split /\n\s*\n/, $content, 2;
    unless ($head =~ m/:/) {
        $head = '';
        $body = $content;
    }

    for my $header ( split /\n(?=\S)/, $head ) {
        # Split header into key/value
        my ($key, $value);
        if ($header =~ m/:/) {
            ($key, $value) = split /:\s*/, $header, 2;
        }
        chomp $value;

        # Join multi-line headers
        $value =~ s/\n //g if $config{unfold_headers};

	# Always decode, even if encoding later, since it might not be
	# fully encoded.
	$value = HTML::Entities::decode_entities($value);

        # Store the header
        $pagestate{$page}{metamail}{$key} = HTML::Entities::encode_numeric($value);

        # Handle some special cases like the meta plugin
	if ($key eq 'date') {
            eval q{use Date::Parse};
            if (! $@) {
                my $time = str2time($value);
                $IkiWiki::pagectime{$page} = $time if defined $time;
            }
	}
	elsif ($key eq 'title' or $key eq 'guid' or $key eq 'author') {
            $pagestate{$page}{meta}{$key} = HTML::Entities::encode_numeric($value);
	}
    }

    return $body;
}

sub pagetemplate (@) {
    my %params = @_;
    my $page = $params{page};
    my $template = $params{template};

    # Treat the title separately
    if (exists $pagestate{$page}{metamail}{'title'}
        && $template->query(name => "title")) {
        $template->param(title => $pagestate{$page}{metamail}{'title'});
        $template->param(title_overridden => 1);
    }

    while ( my($key, $val) = each %{$pagestate{$page}{metamail}} ) {
        $template->param("meta_$key" => $pagestate{$page}{metamail}{$key});
    }
}

1

__END__

=head1 NAME

ikiwiki Plug-in: metamail

=head1 SYNOPSIS

metamail is a plugin for loading metadata from plain-text page
headers.  metamail expects pages to look like email messages: a
collection of headers followed by an empty line and body text.
Headers consist of a key (with no whitespace) followed by a colon and
a value.

For compatibility, the following variables will be passed to the meta
plugin and handled as usual: title, author, date, guid.

=head1 HISTORY

metamail is based on the Blosxom plugin of the same name, written
by Gavin Carr.

=head1 AUTHOR

Jason Blevins <jrblevin@sdf.lonestar.org>, http://jblevins.org/

=head1 SEE ALSO

ikiwiki Homepage:
http://ikiwiki.info/

ikiwiki Plugin Documentation:
http://ikiwiki.info/plugins/write/

=head1 LICENSE

Copyright (C) 2008 Jason Blevins

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
