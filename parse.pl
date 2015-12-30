#!/usr/bin/perl

# A hacky way to get a couple of transcripts into SayIt.
# Started with XML::Simple but the mix of attributes
# and tags made it simpler (if naughty) just to build
# the strings naively.
# ---------------------------
# Reads the .txt transcripts and produces .xml versions
# alongside them.

use strict;

make_akomantoso_for_sayit(
    'filename' => 'ethans-tictec-transcript.txt',
    'speaker-id' => 'ethan',
    'speaker-show-as' => 'Ethan',
    'speaker-href' => '/ontology/person/tictec2015.ethan',
    'doc-title' => 'Keynote speech for TICTeC 2015',
    'title' =>  "It starts with a click"
);

make_akomantoso_for_sayit(
    'filename' => 'shelleys-tictec-transcript.txt',
    'speaker-id' => 'shelley',
    'speaker-show-as' => 'Shelley',
    'speaker-href' => '/ontology/person/tictec2015.shelley',
    'doc-title' => 'Keynote speech for TICTeC 2015',
    'title' =>  "Hey! It's time to check your tech"
);

sub make_akomantoso_for_sayit {
    my %data = @_;
    my $filename = $data{'filename'};
    my $text;
    open INFILE, $filename or die("failed to open $filename to read: $!\n");
    while (<INFILE>) {
        $text .= "$1 " if /^(\d+:\d\d\s.*)\s*/;
    }
    close INFILE;
    # split lines at the start of a new sentence:
    # lookbehind: was there an end-of-sentence punctuation + space
    my @lines = split /(?<=[!?\.]\s)/, $text;
    my %words_keyed_by_timestamp;
    my @timestamps_in_order;
    my $timestamp;
    foreach my $line (@lines) {
        if ($line =~ s/(\d\d?:\d\d)\s*//) {
            $timestamp = $1; # capture first timestamp in this sentence
            $line =~ s/(\d\d?:\d\d)//g; # remove all timestamps
            $line =~ s/^([a-z])/\U$1\E/; # uppercase initial letter
            $line =~ s/\s+-\s+/ — /g; # nitpick hyphens into emdashes
            $words_keyed_by_timestamp{$timestamp} = $line;
            push  @timestamps_in_order, $timestamp;
        } else { # no new timestamp, so add this sentence to the previous
            $words_keyed_by_timestamp{$timestamp} .= $line
        }
    }

    my $akomantoso_xml = <<XML;
<akomaNtoso>
  <debate name="tictec2015-keynote">
    <meta>
      <references source="#">
        <TLCPerson id="$data{'speaker-id'}" href="$data{'speaker-href'}" showAs="$data{'speaker-show-as'}"/>
      </references>
    </meta>
    <preface>
      <docTitle>$data{'doc-title'}</docTitle>
    </preface>
    <debateBody>
      <debateSection name="keynote" id="keynote">
        <heading id="title">$data{'title'}</heading>
        <!-- SPEECHES -->
      </debateSection>
    </debateBody>
  </debate>
</akomaNtoso>
XML

    my $speeches_xml;
    foreach my $timestamp (@timestamps_in_order) {
        my $p = minimal_xml_cleanup($words_keyed_by_timestamp{$timestamp});
        $speeches_xml .= <<XML;
        <speech by="#$data{'speaker-id'}" recordedTime="$timestamp">
          <p>
              $p
          </p>
        </speech>
XML
    }

    $akomantoso_xml=~s/<!-- SPEECHES -->/$speeches_xml/;
    
    my $xmlfilename = $filename;
    if ($xmlfilename =~ s/.txt$/.xml/) {
        open OUTFILE, ">$xmlfilename" or die("failed to open $xmlfilename for write: $!");
        print OUTFILE $akomantoso_xml;
        close OUTFILE;
        print "* wrote " . length($akomantoso_xml) . " characters to $xmlfilename\n";
    }
}


sub minimal_xml_cleanup {
    my $s = shift;
    for ($s) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
    }
    return $s
}

