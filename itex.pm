#!/usr/bin/perl
#
# itex to MathML plugin for IkiWiki.  Based on the itex MovableType
# plugin by Jacques Distler.
#
# Jason Blevins <jrblevin@sdf.lonestar.org>
# Chapel Hill, March 16, 2008

package IkiWiki::Plugin::itex;

use warnings;
use strict;
use IkiWiki 2.00;

use File::Temp qw(tempfile);

sub import {
        hook(type => "getopt", id => "itex", call => \&getopt);
        hook(type => "filter", id => "itex", call => \&filter);
}

sub getopt () {
        eval q{use Getopt::Long};
        error($@) if $@;
        Getopt::Long::Configure('pass_through');
	GetOptions(
                "itex2mml=s" => \$config{itex2mml},
		"itex_num_equations!" => \$config{num_equations},
	);
}


sub filter {
    my %params = @_;

    my $content = $params{content};

    # Remove carriage returns. itex2MML expects Unix-style lines.
    $content =~ s/\r//g;

    # Process equation references
    $content = number_equations($content) if $config{itex_num_equations};

    my ($Reader, $outfile) = tempfile( UNLINK => 1 );
    my ($Writer, $infile) = tempfile( UNLINK => 1 );
    print $Writer "$content";
    system("$config{itex2mml} < $infile > $outfile");
    my @out = <$Reader>;
    close $Reader;
    close $Writer;
    eval { unlink ($infile, $outfile); };
    return join('', @out);
}

sub number_equations {
    my $body = shift;

    my $prefix = "eq";
    my $cls = "numberedEq";

    my %eqnumber;
    my $eqno=1;

    # add equation numbers to \[...\]
    #  - introduce a wrapper-<div> and a <span> with the equation number
    while ($body =~ s/\\\[(.*?)\\\]/\n\n<div class=\"$cls\"><span>\($eqno\)<\/span>\$\$$1\$\$<\/div>\n\n/s) {
	$eqno++;
    }

    # assemble equation labels into a hash
    # - remove the \label{} command, collapse surrounding whitespace
    # - add an ID to the wrapper-<div>. prefix it to give a fighting chance
    #   for the ID to be unique
    # - hash key is the equation label, value is the equation number
    while ($body =~ s/<div class=\"$cls\"><span>\((\d+)\)<\/span>\$\$((?:[^\$]|\\\$)*)\s*\\label{(\w*)}\s*((?:[^\$]|\\\$)*)\$\$<\/div>/<div class=\"$cls\" id=\"$prefix:$3\"><span>\($1\)<\/span>\$\$$2$4\$\$<\/div>/s) {
	$eqnumber{"$3"} = $1;
    }

    # add cross-references
    # - they can be either (eq:foo) or \eqref{foo}
    $body =~ s/\(eq:(\w+)\)/\(<a href=\"#$prefix:$1\">$eqnumber{"$1"}<\/a>\)/g;
    $body =~ s/\\eqref\{(\w+)\}/\(<a href=\'#$prefix:$1\'>$eqnumber{"$1"}<\/a>\)/g;

    return $body;
}

1

__END__

=head1 NAME

Blosxom Plug-in: itex

=head1 SYNOPSIS

Processes embedded itex (LaTeX-based) expressions in pages and converts
them to MathML.  Also provides equation-numbering as described on
Jacques Distler's itex2MML commands page.

=head1 AUTHORS

Jason Blevins <jrblevin@sdf.lonestar.org>,
itex Blosxom plugin

Jacques Distler <distler@golem.ph.utexas.edu>,
itex2MML and itex2MML Movable Type Plugin

=head1 SEE ALSO

ikiwiki Homepage:
http://ikiwiki.info/

ikiwiki Plugin Documentation:
http://ikiwiki.info/plugins/write/

itex2MML commands:
http://golem.ph.utexas.edu/~distler/blog/itex2MML.html

=head1 LICENSE

Copyright (C) 2008 Jason Blevins

Copyright (C) 2003-2007 Jacques Distler

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
