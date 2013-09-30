#!/usr/bin/perl -w 


#########################################################################################
#
# This script reads in a file from the LexisNexis export and generates a KAF file
# It splits the text from the news article into paragraphs and numbers them. Further 
# processing can take place on the entire text or a selection of paragraphs
#
# Author: Marieke van Erp  /  marieke.van.erp@vu.nl
# Date: 30 September 2013
# Version: 0.1 
#
#########################################################################################

use strict ; 
use XML::LibXML ;
use XML::LibXML::PrettyPrint;
use Data::Dumper ;  
use utf8::all ;
use Scalar::MoreUtils qw(empty);

my $parser = XML::LibXML->new();
my $doc = $parser->parse_file( $ARGV[0] );

#<nitf><head><docdata><doc-id id-string
#<nitf><head><docdata><date-issue norm
#<nitf><head><docdata><doc.copyright holder
#<nitf><head><pubdata>
#<nitf><body><body.head>
#<nitf><body><body.content><note> 

# Grab the DocId, Date of Issue, Copyright, Position in the source (category and page no),
# source, headline and byline from the header 
my $docId ; 
for my $sample( $doc->findnodes('/nitf/head/docdata/doc-id') ) {
	$docId = $sample->getAttribute('id-string') ; 
	}
	
my $dateIssue;
for my $sample( $doc->findnodes('/nitf/head/docdata/date.issue') ) {
	$dateIssue = $sample->getAttribute('norm') ; 
	}

my $copyright ;
for my $sample( $doc->findnodes('/nitf/head/docdata/doc.copyright') ) {
	$copyright = $sample->getAttribute('holder') ; 
	}

my $position ; 
for my $sample( $doc->findnodes('/nitf/head/pubdata') ) {
	$position = $sample->getAttribute('position.section') ; 
	}

my $source ;
for my $sample( $doc->findnodes('/nitf/head/pubdata') ) {
	$source = $sample->getAttribute('name') ; 
	}

my $headline ;
for my $sample( $doc->findnodes('/nitf/body/body.head/hedline/hl1') ) { 
	$headline = $sample->textContent() ;
	}
	
my $byline ; 	
for my $sample( $doc->findnodes('/nitf/body/body.head/byline') ) { 
	$byline = $sample->textContent() ;
	}

# Grab the text from the document body one paragraph at a time and 
# store in a paragraphs array 
my @relevantparagraphs ; 
for my $sample( $doc->findnodes('/nitf/body/body.content/block/p') ) { 
	my $text = $sample->textContent() ;
	next if($text =~ /<tbody>/) ;
	if((length($text) > 50 || $text =~ /\./))
		{
		push @relevantparagraphs, $text ; 
		}
	}

#########
#
#  Initiate the KAF document
#
#########
my $newdoc = XML::LibXML::Document->new( '1.0', 'utf-8' ) ; 
my $root = $newdoc->createElement ('KAF');
$root->addChild ($newdoc->createAttribute ( 'xml:lang' => 'en') );
$newdoc->addChild($root);

my $kafheader= $newdoc->createElement('kafheader');
$root->addChild($kafheader);

my $processor = $newdoc->createElement('linguisticProcessors');
$kafheader->addChild($processor);
$processor->addChild($newdoc->createAttribute('layer' => '1'));

my $timestamp = localtime(time);
my $lp = $newdoc->createElement('lp');
$processor->addChild($lp);
$lp->addChild($newdoc->createAttribute(name => 'DiscourseModule'));
$lp->addChild($newdoc->createAttribute(timestamp => $timestamp));
$lp->addChild($newdoc->createAttribute(version => '0.1'));

### Create the NITF header 
my $nitf = $newdoc->createElement('nitf');
$root->addChild($nitf);

my $pubtitle = $newdoc->createElement('header');
$nitf->addChild($pubtitle);
$pubtitle->addChild($newdoc->createAttribute(docId => $docId));
$pubtitle->addChild($newdoc->createAttribute(dateIssue => $dateIssue));
$pubtitle->addChild($newdoc->createAttribute(copyright => $copyright));
$pubtitle->addChild($newdoc->createAttribute(position => $position));
$pubtitle->addChild($newdoc->createAttribute(source => $source));
$pubtitle->addChild($newdoc->createAttribute(headline => $headline));
$pubtitle->addChild($newdoc->createAttribute(byline => $byline));

#  Add the paragraphs 
my $textsource = $newdoc->createElement('textsource');
$root->addChild($textsource);

for(my $x = 0 ; $x < @relevantparagraphs ; $x++)
	{
	my $relevantParagraph = $newdoc->createElement('relevantParagraphs');
	$textsource->addChild($relevantParagraph);
	$relevantParagraph->addChild($newdoc->createAttribute(parId => $x));
	$relevantParagraph->addChild($newdoc->createAttribute(parText => $relevantparagraphs[$x]));
	}

# Pretty print 
print XML::LibXML::PrettyPrint
    -> new ( element => { compact => [qw/label/] } )
    -> pretty_print($newdoc)
    -> toString;



