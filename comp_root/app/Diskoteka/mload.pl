#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------

BEGIN {
    $| = 1;
};

use Getopt::Long;
use LWP::UserAgent;

# ------------------------------------------------------------------------
# GLOBAL VARIABLES
    our $VERSION = '3.5';
our $WWW_SERVER = 'www';
our $FILES_AT_ONCE = 100;

# ------------------------------------------------------------------------
my $opt_name; # Name of disk
my $opt_levels; # Number of subdirs to load
my $opt_outfile;
my $opt_server;
my $opt_help;
GetOptions('levels|l=i' => \$opt_levels,
        'name|n=s' => \$opt_name,
        'server|s=s' => \$opt_server,
        'help|h' => \$opt_help,
        'file|f=s' => \$opt_outfile);

$WWW_SERVER = $opt_server if $opt_server;
if ($opt_help) {
    print "Options:\n",
        "\t-n\n",
        "\t--name - disk name\n\n",
        "\t-s\n",
        "\t--server - server name\n\n",
        "\t-h\n",
        "\t--help - this help screen\n\n",
        "\t-f\n",
        "\t--file - save to file\n\n";
    exit;
}

# ------------------------------------------------------------------------
# SOURCE
our $source = shift @ARGV;
print "Disk loader v.$VERSION of ePortal\n\n";

while(1) {
    if (!$source) {
        print "Load from source [A:]";
        $source = <STDIN>;
        $source =~ tr/\r\n//d;
        $source = 'A:' if ! $source;
    }
    $source =~ s/[\/\\]$//; # remove trailing slash

    my $result = opendir(DIR, $source);
    closedir(DIR);
    if ($result) {
        last;
    } else {
        print "Cannot open $source: $!\n";
        $source = undef;
    }
}
$source =~ tr|\\|\/|;
if (! -d $source ) {
    print "$source is not a directory\n";
    exit ;
}


# ------------------------------------------------------------------------
# DISK NAME
our $disk_name = $opt_name;
my $disk_name_default = $disk_name || "$source loaded " . localtime();
print "Disk name [$disk_name_default]";
$disk_name = <STDIN>;
$disk_name =~ tr/\r\n//d;
$disk_name = $disk_name_default if ! $disk_name;

# ------------------------------------------------------------------------
# READ media
print "Reading directories and saving information ...\n";
my $first_req = 1;
my $ua = LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");

if ($opt_outfile) {
    if (! open(F, ">$opt_outfile")) {
        die "Cannot open file $!\n";
    }
    print "Saving to file $opt_outfile\n";
    print F "diskname=$disk_name\n";
    print F "source=$source\n";
}

process_dir($source, 1);

if ($opt_outfile) {
    close F;
}

############################################################################
sub process_dir {   #02/12/03 10:50
############################################################################
    my $dir = shift;
    my $level = shift;

    # Limit max levels of subdirs
    return if ($opt_levels and $level > $opt_levels);

    # Print nice info
    print truncate_path_name($dir), "  ";

    # Read files and get subdirs
    my @files = read_directory($dir);
    my @subdirs = ();
    foreach (@files) {
        my($filetype, $file, $other) = split '\|', $_;
        push @subdirs, $file if $filetype eq 'dir';
    }
    print scalar(@files), " files read, ";

    if ($opt_outfile) {
        foreach (@files) {
            print F "file=$_\n";
        }
        print scalar(@files), " files saved";
    } else {     # save to server
        my $counter = 0;
        while(1) {
            my $req = HTTP::Request->new(POST => "http://$WWW_SERVER/app/Diskoteka/mload.htm");
            $req->content_type('application/x-www-form-urlencoded');

            my $content = "diskname=$disk_name&source=$source&first_req=$first_req";
            for (1..$FILES_AT_ONCE) {
                last if ! $files[$counter];
                $content .= '&file=' . $files[$counter];
                $counter++;
            }

            $req->content($content);
            my $res = $ua->request($req);
            if ($res->is_success) {
                if ($res->content =~ /OK/m) {
                    print " $counter files saved ";
                } else {
                    print $res->content, "\n";
                    exit;
                }
            } else {
                print " Error: ", $res->message, "\n";
                exit;
            }
            $first_req = 0;
            last if ! $files[$counter];
        }
    }
    print "\n";

    # Read subdirectories
    foreach (@subdirs) {
        process_dir($_, $level + 1);
    }
}

############################################################################
sub read_directory  {   #02/12/03 10:17
############################################################################
    my $dir = shift;
    my $level = shift;
    local (*DIR);

    if (! opendir(DIR, $dir)) {
        return;
    }

    my @files;
    while(my $file = readdir(DIR)) {
        next if $file eq '.' or $file eq '..';

        stat("$dir/$file");
        my $filetype = -d _ ? 'dir' : 'file';
        my $filesize = 0+ (stat(_))[7];
        my $filedate = 0+ (stat(_))[9];

        push @files, "$filetype|$dir/$file|$filesize|$filedate";
    }
    #print '.';
    closedir(DIR);
    return sort @files;
}##read_directory



############################################################################
sub truncate_path_name  {   #02/12/03 11:53
############################################################################
    my $path = shift;

    if (length($path) > 50) {
        $path = substr($path, 0, 20) . ' ... ' . substr($path, -20);
    }
    return $path;
}##truncate_path_name

=head
<%flags>
inherit=>undef
</%flags>
=cut
