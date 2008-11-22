#!/usr/bin/perl

package IkiWiki::Plugin::peg_markdown;

use warnings;
use strict;
use IkiWiki 2.00;
use FileHandle;
use IPC::Open2;

sub import {
    my $markdown_ext = $config{peg_markdown_ext} || "mdwn";

    hook(type => "getsetup", id => "peg_markdown", call => \&getsetup);
    hook(type => "htmlize", id => $markdown_ext,
         call => sub { htmlize("markdown", @_) });
}

sub getsetup () {
    return
    plugin => {
        safe => 1,
        rebuild => 1,
    },
    peg_markdown_command => {
        type => "string",
        example => "/usr/local/bin/peg-markdown",
        description => "Path to peg-markdown executable",
        safe => 0,
        rebuild => 0,
    },
    peg_markdown_ext => {
        type => "string",
        example => "mdwn",
        description => "File extension for Markdown files",
        safe => 1,
        rebuild => 1,
    },
    peg_markdown_smart => {
        type => "boolean",
        example => 1,
        description => "Use smart quotes, dashes, and ellipses",
        safe => 1,
        rebuild => 1,
    },
    peg_markdown_notes => {
        type => "boolean",
        example => 1,
        description => "Enable peg-markdown footnote extension",
        safe => 1,
        rebuild => 1,
    }
}

sub htmlize ($@) {
    my $format = shift;
    my %params = @_;
    my $page = $params{page};

    local(*IN, *OUT);
    my @args;

    my $command = $config{pandoc_command} || "/usr/bin/pandoc";

    # Extensions
    if ($config{peg_markdown_smart}) {
        push @args, '--smart';
    }
    if ($config{peg_markdown_notes}) {
        push @args, '--notes';
    }

    # Open a bi-directional pipe with peg-markdown
    my $pid = open2(*IN, *OUT, $command, @args);
    error("Unable to open $command") unless $pid;

    # Workaround for perl bug (#376329)
    require Encode;
    my $content = Encode::encode_utf8($params{content});

    print OUT $content;
    close OUT;

    my @html = <IN>;
    close IN;

    waitpid $pid, 0;

    $content = Encode::decode_utf8(join('', @html));
    return $content;
}

1;
