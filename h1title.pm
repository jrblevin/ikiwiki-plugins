#!/usr/bin/perl
#
# Jason Blevins <jrblevin@sdf.lonestar.org>
# Chapel Hill, October 22, 2008

package IkiWiki::Plugin::h1title;

use warnings;
use strict;
use IkiWiki 2.00;

my %title;

sub import {
    hook(type => "filter", id => "h1title", call => \&filter);
    hook(type => "pagetemplate", id => "h1title", call => \&pagetemplate);
}

sub filter(@) {
    my %params = @_;
    my $page = $params{page};
    my $content = $params{content};

    if ($content =~ s/^\#[ \t]+(.*?)[ \t]*\#*\n//) {
        $title{$page} = $1;
    }
    return $content;
}

sub pagetemplate (@) {
    my %params = @_;
    my $page = $params{page};
    my $template = $params{template};

    if (exists $title{$page} && $template->query(name => "title")) {
        $template->param(title => $title{$page});
        $template->param(title_overridden => 1);
    }
}

1

=head1 NAME

ikiwiki Plug-in: h1title

=head1 SYNOPSIS

If there is a level 1 Markdown atx-style (hash mark) header on the first line,
this plugin uses it to set the page title and removes it from the page body so
that it won't be rendered twice.  Level 1 headers in the remainder of the page
will be ignored.

For example, the following page will have title "My Title" and the rendered
page body will begin with the level two header "Introduction."

    # My Title

    ## Introduction
    
    Introductory text with a list:
    
     * Item 1
     * Item 2

    ## Second header

    Second section

This plugin can be used with page templates that use <h1> tags for the page
title to produce a consistent header hierarchy in rendered pages while keeping
the Markdown source clean and free of meta directives.

=head1 AUTHOR

Jason Blevins <jrblevin@sdf.lonestar.org>,

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
