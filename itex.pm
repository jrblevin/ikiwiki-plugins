#!/usr/bin/perl
#
# itex to MathML plugin for IkiWiki.
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
#		"itex_num_equations!" => \$config{num_equations},
#		"itex_use_meta!" => \$config{use_meta},
	);
}


sub filter {
    my %params = @_;

    my $content = $params{content};

    $content =~ s/\r//g;

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

1
