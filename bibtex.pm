#!/usr/bin/perl
# by Alexandre Dupas
# Bibtex to simple html

package IkiWiki::Plugin::bibtex;

use warnings;
use strict;
use IkiWiki 2.00;

sub import { #{{{
    hook(type => "htmlize", id => "bib", call => \&htmlize);
} # }}}

sub untex ($) {
    my $string = shift;
    $string =~ s/\\\`a/à/g; 
    $string =~ s/\\\'e/é/g; 
    $string =~ s/\\\`e/è/g;
    $string =~ s/\{\'e\}/é/g;
    return $string;
}

sub format_title ($) {
    my $title = shift;
    $title =~ s/\.$//;
    return $title;
}

sub format_authors (@) {
    my @authors = @_;
    my $result;
    
    if( (scalar @authors) == 1 ) {
	$result = shift @authors;
    }
    else {
	@authors = reverse @authors;
	$result = "and ".shift @authors;
	foreach (@authors) { 
	    $result = $_.", $result"; 
	}
    }
    return untex $result;
}

sub format_article ($) {
    my $entry = shift;
    
    my $authors = format_authors $entry->split('author');
    my $title = format_title untex $entry->get('title');
    my $journal = untex $entry->get('journal');
    my $year = $entry->get('year');

    return ( title => $title, 
	     authors => $authors, 
	     misc => "In $journal, $year" );
}  # format_article

sub format_inproceedings ($) {
    my $entry = shift;
    
    my $authors = format_authors $entry->split('author');
    my $title = format_title untex $entry->get('title');
    my $booktitle = untex $entry->get('booktitle');
    my $year = $entry->get('year');

    # process optionnal fields
    my $address = $entry->exists('address') ?
	$entry->get('address') : "";

    my $date = $entry->exists('month') ?
	$entry->get('month')." $year" : $year;

    my $publisher = $entry->exists('publisher') ? 
	", ".$entry->get('publisher') : "";
    
    return ( title => $title, 
	     authors => $authors, 
	     misc => "In $booktitle, $date$publisher" );
}  # format_inproceedings

sub format_phdthesis ($) {
    return format_mastersthesis($_);
}  # format_phdthesis

sub format_mastersthesis ($) {
    my $entry = shift;

    my $authors = format_authors $entry->split('author');
    my $title = format_title untex $entry->get('title');
    my $school = untex $entry->get('school');
    my $year = $entry->get('year');

    # process optionnal fields
    my $date = $entry->exists('month') ?
	$entry->get('month')." $year" : $year;

    return ( title => $title, 
	     authors => $authors, 
	     misc =>  "$date, $school" );
}  # format_mastersthesis


sub format_note ($) {
    my $entry = shift;
    
    if ($entry->exists('note')) {
	return ( note => $entry->get('note') );
    }
}

sub format_abstract ($) {
    my $entry = shift;
    
    if ($entry->exists('abstract')) {
	return ( abstract => $entry->get('abstract') );
    }
}

sub format_entry ($) {
    my $entry = shift;
    my $page = shift;
    
    my $type = $entry->type;
    use IkiWiki::Plugin::bibtex;
    my $method_name = 'format_'.$type;
    my $method = \&$method_name;
    my %values = &$method($entry);

    $values{'note'} = $entry->get('note') 
	if( $entry->exists('note') );
    
    $values{'abstract'} = $entry->get('abstract') 
	if( $entry->exists('abstract') );

    $values{'url'} = $entry->get('url') 
	if( $entry->exists('url') );
    
    $entry->delete( 'abstract' );
    my $bibtex_entry = $entry->print_s;
    $bibtex_entry =~ s!\n$!!g;
    $bibtex_entry =~ s!\n!<br />!g;

    return ( key => $entry->key, %values, bibtex => $bibtex_entry );
}

sub par_type ($$) {
    my (@gauche, @droit) = @_;
    return $gauche[0] cmp $droit[0];
}

sub htmlize (@) { #{{{
    my %params=@_;
    my $page = $params{page};
    my $content = $params{content};

    my $filename = "$page.bib";
    my ($bibfile, $entry);

    my %types = ( article => 0 , 
		  inproceedings => 1,
		  thesis => 2,
		  mastersthesis => 3 );
    
    my @biblio = ( { type => 'article', 
		     typename => "International Journals" },
		   { type => 'inproceedings', 
		     typename => "International Conferences" },
		   { type => 'phdthesis', 
		     typename => "PhD Thesis" },
		   { type => 'mastersthesis', 
		     typename => "Master Thesis" } );

    # Hash storing values for each entry
    my %index = ();

    eval q{use Text::BibTeX};
    return $content if $@;

    $bibfile = new Text::BibTeX::File $filename or die "$filename: $!\n";
    
    while ($entry = new Text::BibTeX::Entry $bibfile)
    {
	next unless $entry->parse_ok;

	my $key = $entry->key;
	$index{$key} = { format_entry $entry };

	# add the entry to the table
	push( @{$biblio[$types{$entry->type}]{entries}}, \%{$index{$key}} );

	# build the bibfile associated to each bib entry
	my $keydir = "$page/$key";
	my $keybib = "$keydir/$key.bib";
	my $keyhtml = htmlpage($keydir);

	# render the bibtex file associated to the current entry key
	will_render($page, $keybib);
	writefile($keybib, $config{destdir}, $entry->print_s);
	add_depends($keybib, $page);
	
	# render the html page containing the same bibtex entry
	$index{$key}{'url_keybib'} = urlto($keybib,$page);
	$index{$key}{'url_keyhtml'} = urlto($keydir,$page);
	
	require HTML::Template;
	
	my $template=template("bibentry.tmpl");
	$template->param( %{$index{$key}} );

	my $html = IkiWiki::genpage($keydir,$template->output);

	will_render($page, $keyhtml);
 	writefile($keyhtml, $config{destdir}, $html);
	add_depends($keyhtml, $page);
    }

    # Using template to produce the htmlized bibfile
    require HTML::Template;
    my $template=template("bibfile.tmpl");
    $template->param( toc => 0 ); # if 1, add a toc to the bibliography
    $template->param( bibliography => [ @biblio ] );
    return $template->output;
} # }}}

1
