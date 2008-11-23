#!/usr/bin/perl
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
