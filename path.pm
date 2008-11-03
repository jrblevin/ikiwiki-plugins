#!/usr/bin/perl

package IkiWiki::Plugin::path;

use warnings;
use strict;
use IkiWiki 2.00;

sub import {
    hook(type => "pagetemplate", id => "path", call => \&pagetemplate);
}

sub getsetup () {
    return
        plugin => {
            safe => 1,
            rebuild => 1,
        },
}

sub pagetemplate (@) {
    my %params = @_;
    my $page = $params{page};
    my $template = $params{template};

    # Obtain path
    eval q{use File::Basename};
    error($@) if $@;
    my ($base, $dir, $ext) = fileparse($page);
    my @path = split(/\//, $dir);

    # Incremental path indicators
    my $var = "in";
    foreach (@path) {
        next if !$_;
        $_ = "root" if $_ eq ".";
        $var .= "_$_";
        $template->param("$var" => 1);
    }

    # Homepage indicator
    if ($base eq "index" and $dir eq "./") {
        $template->param("is_homepage" => 1);
    }

    # Final path indicator
    $var =~ s/^in/is/;
    $template->param("$var" => 1);

    # Page name
    $template->param("pagename" => $base);
}

1

__END__

=head1 NAME

ikiwiki Plug-in: path

=head1 SYNOPSIS

The path plugin creates a series of template variables for each page
for determining the path.  This is useful for conditionally including
bits of code in templates based on the path.

Three types of variables are generated which indicate, respectively,
the homepage, the inclusion of a page as a subpage of a particular
path, and the exact path of the page.  Additionally, the
variable PAGENAME is populated with the base filename of the page
(without extension).

For the page index.mdwn, the template variables IS_HOMEPAGE and
IN_ROOT, and IS_ROOT will be set.  For any other page in the root
directory, say page.mdwn, both IN_ROOT and IS_ROOT will be set.

For a general page, say /blog/ikiwiki/path-plugin.mdwn, the following
variables will be set: IN_BLOG, IN_BLOG_IKIWIKI, IS_BLOG_IKIWIKI to
indicate, respectively, that the file is contained within both /blog
and /blog/ikiwiki and that /blog/ikiwiki is the final path.

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
