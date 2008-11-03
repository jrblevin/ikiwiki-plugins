#!/usr/bin/perl

package IkiWiki::Plugin::pandoc;

use warnings;
use strict;
use IkiWiki 2.00;
use FileHandle;
use IPC::Open2;

sub import {
    my $markdown_ext = $config{pandoc_markdown_ext} || "mdwn";

    hook(type => "getsetup", id => "pandoc", call => \&getsetup);
    hook(type => "htmlize", id => $markdown_ext,
         call => sub { htmlize("markdown", @_) });
    if ($config{pandoc_latex}) {
        hook(type => "htmlize", id => "tex",
             call => sub { htmlize("latextex", @_) });
    }
    if ($config{pandoc_rst}) {
        hook(type => "htmlize", id => "rst",
             call => sub { htmlize("rst", @_) });
    }
}

sub getsetup () {
    return
    plugin => {
        safe => 1,
        rebuild => 1,
    },
    pandoc_command => {
        type => "string",
        example => "/usr/bin/pandoc",
        description => "Path to pandoc executable",
        safe => 0,
        rebuild => 0,
    },
    pandoc_markdown_ext => {
        type => "string",
        example => "mdwn",
        description => "File extension for Markdown files",
        safe => 1,
        rebuild => 1,
    },
    pandoc_latex => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of LaTeX documents",
        safe => 0,
        rebuild => 1,
    },
    pandoc_rst => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of reStructuredText documents",
        safe => 0,
        rebuild => 1,
    },
    pandoc_smart => {
        type => "boolean",
        example => 1,
        description => "Use smart quotes, dashes, and ellipses",
        safe => 1,
        rebuild => 1,
    },
}

sub htmlize ($@) {
    my $format = shift;
    my %params = @_;
    my $page = $params{page};

    local(*PANDOC_IN, *PANDOC_OUT);
    my @args;

    my $command = $config{pandoc_command} || "/usr/bin/pandoc";

    if ($config{pandoc_smart}) {
        push @args, '--smart';
    }

    my $pid = open2(*PANDOC_IN, *PANDOC_OUT, $command,
                    '-f', $format,
                    '-t', 'html',
                    @args);

    error("Unable to open $command") unless $pid;

    # Workaround for perl bug (#376329)
    require Encode;
    my $content = Encode::encode_utf8($params{content});

    print PANDOC_OUT $content;
    close PANDOC_OUT;

    my @html = <PANDOC_IN>;
    close PANDOC_IN;

    waitpid $pid, 0;

    $content = Encode::decode_utf8(join('', @html));
    return $content;
}

1
