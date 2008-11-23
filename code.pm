#!/usr/bin/perl
#
# code -- a syntax highlighting plugin for Ikiwiki based on GNU
# Source-highlight.

package IkiWiki::Plugin::code;

use warnings;
use strict;
use IkiWiki 2.00;
use open qw{:utf8 :std};
use File::Basename qw(fileparse);

my $command = $config{code_command} || "/usr/bin/source-highlight";

sub import {
    # htmlize hooks for each extension => language pair in code_languages
    my $lang = $config{code_languages};
    while (my($key, $val) = each %$lang) {
        hook(type => "htmlize", id => $key, keepextension => 1,
            call => sub { htmlize($val, @_) });
    }

    # [[!code]] preprocessor directive for inline code
    hook(type => "preprocess", id => "code", call => \&preprocess);
}

sub save_unmodified_copy (@) {
    my %params = @_;

    my $page = $params{page};
    my $content = $params{content};
    my ($base,$dir,$ext) = fileparse($page);
    my $destfile = $base;

    will_render($page, $destfile);
    writefile("$page/$destfile", $config{destdir}, $content);

    return $destfile;
}

sub highlight (@) {
    my %params = @_;
    my $page = $params{page};

    eval q{use FileHandle};
    error($@) if $@;
    eval q{use IPC::Open2};
    error($@) if $@;

    local(*SPS_IN, *SPS_OUT);  # Create local handles

    my @args;

    # If the number="yes" is used in the preprocessor directive,
    # request line numbering and use spaces instead of zero padding
    # for the numbers.
    if ($params{number} and $params{number} eq "yes") {
        push @args, '--line-number= ';
    }

    # Give a nonexistent css file to enable CSS-stylable output but
    # also request an HTML fragment without a header or footer.
    push @args, '--css', 'foo.css', '--no-doc';

    # Specify the Source language and output Format.
    push @args, '-s', $params{language}, '-f', 'html';

    # Open a bi-directional pipe with source-highlight.
    my $pid = open2(*SPS_IN, *SPS_OUT, $command, @args);
    error("Unable to open $command") unless $pid;

    print SPS_OUT $params{content};
    close SPS_OUT;

    my @html = <SPS_IN>;
    close SPS_IN;

    waitpid $pid, 0;
    return @html;
}


sub htmlize {
    my $language = shift;
    my %params = (
        language => $language,
        @_
    );

    my @html = highlight(%params);

    my $filename = save_unmodified_copy(%params);
    $filename = encode_entities($filename);

    return "<p>Download <a href='$filename'>$filename</a></p>\n" .
        '<div class="sourcecode">' .
        "\n" . join('', @html) . "\n</div>\n";
}


sub preprocess (@) {
    my %params = @_;
    my @html = highlight(%params);
    return join('', @html);
}

1

__END__

=head1 NAME

ikiwiki Plug-in: code

=head1 SYNOPSIS

Provides whole-file syntax highlighting as well as a preprocessor
directive for syntax highlighting inline source code fragments.

=head1 AUTHORS

Jason Blevins <jrblevin@sdf.lonestar.org>, http://jblevins.org

=head1 SEE ALSO

http://jblevins.org/projects/ikiwiki/code

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
