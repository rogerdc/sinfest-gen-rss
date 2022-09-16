#!/usr/bin/perl

# Replacement for http://www.sinfest.net/rss.php which is stale/broken
# since the site got a new design around 8th of June 2014.
#
# Can be used as command-type source in Liferea. (Actually it was
# written for exactly that purpose.)
#
# Author: Axel Beckert <abe@deuxchevaux.org>
# Copyright (C) 2015 Axel Beckert
# License: DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#          See LICENSE or http://www.wtfpl.net/txt/copying/ for the
#          full license text.

# Boilerplate
use strict;
use warnings;
use 5.010;

our $VERSION = 0.02;

# Configuration
my $number_of_entries = 7;
my $timeout = 3;
# %F = %Y-%m-%d = ISO 8601
my $url_template = 'http://www.sinfest.net/view.php?date=%F';
my $img_template = 'http://www.sinfest.net/btphp/comics/%F.jpg';
local $ENV{TZ} = 'AST4ADT';

# Libraries
use Carp;
use POSIX::strftime::Compiler qw(strftime);
use Date::Calc qw(Add_Delta_Days Date_to_Time Time_to_Date Mktime);
use Getopt::Std;
use LWP::UserAgent;

# Commandline parsing
my %options = ();
getopts('nd:', \%options);
if ($options{d}) {
    $number_of_entries = $options{d};
}

# Initialisation
my @ymdhms = Time_to_Date(time);
my $now = strftime('%FT%T%z', localtime);

my $ua = LWP::UserAgent->new;
$ua->timeout($timeout);
$ua->env_proxy;
$ua->agent("sinfest-gen-rss/$VERSION ".$ua->_agent
           #." http://github.com/xtaran/sinfest-gen-rss"
    );

# Output RSS header
print <<"EOT";
<?xml version="1.0" encoding="UTF-8"?>
<!-- GENERATED BY Axel\'s Sinfest RSS Generator $VERSION -->
<rss version="0.92">
        <channel>
                <title>Sinfest</title>
                <link>http://www.sinfest.net</link>
                <description>Sinfest</description>
                <lastBuildDate>$now</lastBuildDate>
                <copyright></copyright>
                <image>
                        <title>Sinfest</title>
                        <url>http://www.sinfest.net/rssicon.png</url>
                        <link>http://www.sinfest.net</link>
                        <width>28</width>
                        <height>30</height>
                </image>
EOT

# Actual functionality
for (my $i = 0; $i < $number_of_entries; $i++) {
    &output_item(Add_Delta_Days(@ymdhms[0..2], -$i));
}

# Output RSS footer
print <<'EOT';
        </channel>
</rss>
EOT

sub output_item {
    my @ymd = @_;
    my @localtime = localtime(Date_to_Time(@ymd,@ymdhms[3..5]));
    my $page_url = strftime($url_template,  @localtime);
    my $img_url  = strftime($img_template,  @localtime);
    my $pubdate  = strftime('%a, %d %b %Y', @localtime);

    my $title = 'Dummy';
    unless($options{n}) {
        my $response = $ua->get($page_url);
        if ($response->is_success) {
            my $content = $response->decoded_content;
            if ($content =~ m{<img src="btphp/comics/.*" alt="(.*)">}) {
                $title = $1;
            }
        }
        else {
            carp "$page_url gave ".$response->status_line;
        }
    }

    print <<"EOT";
                <item>
                        <title>"$title" - $pubdate</title>
                        <link>$page_url</link>
                        <guid>$page_url</guid>
                        <pubDate>$pubdate 00:00:00 -04:00</pubDate>
                        <description>&lt;img src="$img_url" border="0" alt="$title" /&gt;</description>
                </item>
EOT
    return;
}
