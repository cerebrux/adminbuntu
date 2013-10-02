#!/usr/bin/perl -w
#
# dumpmysql2s3.pl
#
# Script's documentation page: http://www.adminbuntu.com/backup_mysql_databases_to_aws_s3
#
# MySQL backup script
# dumps MySQL databases, creates tarball and backs up result to Amazon S3
# No arguments. The program is to be modified to include each database to be archived.
#
# Install prerequisites:
#
# sudo aptitude -y install liblocal libxml-dom-perl libnet-amazon-s3-perl
# sudo cpan Net::Amazon::S3
# sudo cpan DateTime
#
# IMPORTANT: When CPAN asks for an install type, select "sudo".
#
#
# Copyright 2013 Andrew Ault
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
use strict;
use warnings;

use DateTime;
use Getopt::Std;
use POSIX;
use Net::Amazon::S3;

# where to dump MySQL databases (as tarballs)
# CONFIGURE THIS
my $dirDumpTarballs = "/base/var/backups";

# Amazon values for S3 backup
# CONFIGURE THIS
my $awsAccessKey = "XXXXXXXXXXXXXXXXXXX";
my $awsSecretAccessKey = "Xq572dN8sCusY48tbs6BmhCf69JhND1q5ef8Hch3";
my $s3Bucket = "companyname-mysql-backup";

# specify each database to be dump/rotated/tarred.
# CONFIGURE THIS
my %dumpJobs = (
﻿  ﻿  ﻿  ﻿   'dbnamehere' => {
﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  'database'     => 'dbnamehere',
﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  'dbUser'       => 'dbuserhere',
﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  'dbPassword'   => 'dbpasswordhere',
﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  'dumpFilename' => 'dbnamehere.dump.sql',
﻿  ﻿  ﻿  ﻿   },
);

# get options
our ($opt_h, $opt_d, $opt_v );
getopts('hdv');

my $fileLog = "/var/log/dumpmysql2s3.log";
my $cmdMysqlDump = "/usr/bin/mysqldump";
my $cmdTar = "/bin/tar";
my $dumpJobError  = 0;
my $dumpJobErrors = "";
my $backupError = 0;
my $backupErrors = "";
my $result;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

# ensure script is running as root
#if ( $< != 0){
#    warn "$0 error: must be run as root<\n";
#    exit 1;
#}

# ensure dump tarball destination directory exists
if (! -d $dirDumpTarballs){
    warn "$0 error: $dirDumpTarballs does not exist\n";
    exit 1;
}

if ( $opt_h ) {
    HELP_MESSAGE();
}

chdir $dirDumpTarballs;


# upload to Amazon S3
my $s3 = Net::Amazon::S3->new(
                               aws_access_key_id     => $awsAccessKey,
                               aws_secret_access_key => $awsSecretAccessKey,
                               retry                 => 1,
);
my $s3client = Net::Amazon::S3::Client->new( s3 => $s3 );

# process each specified database dump/archive job
for my $dumpJob ( sort keys %dumpJobs ) {
﻿  my $dumpFileError = 0;
﻿  my $tarballFilename = "$dumpJobs{$dumpJob}{'dumpFilename'}-" . tarDateSegment() . ".tgz";
﻿  my $gpgTarballFilename = "$dumpJobs{$dumpJob}{'dumpFilename'}-" . tarDateSegment() . ".tgz.gpg";
﻿  logit ( "dumping: " . $dumpJob );

    # dump database
﻿  my $dumpCommand = $cmdMysqlDump . " ";
﻿  $dumpCommand .= "--user=$dumpJobs{$dumpJob}{'dbUser'} --password=$dumpJobs{$dumpJob}{'dbPassword'} ";
﻿  $dumpCommand .= "$dumpJobs{$dumpJob}{'database'} > $dumpJobs{$dumpJob}{'dumpFilename'}";
﻿  logit ( $dumpCommand );
    # if not -d then execute actual command
    if ( ! $opt_d ) {
        $result = system($dumpCommand );
    }
﻿  if ($result) { $dumpFileError = 1; }

    # tarball the dump file
﻿  if ( ! $dumpFileError ) {
﻿  ﻿  my $makeTarball = $cmdTar . " ";
﻿  ﻿  $makeTarball .= "cvfz $tarballFilename $dumpJobs{$dumpJob}{'dumpFilename'}";
﻿  ﻿  logit ( $makeTarball );
        # if not -d then execute actual command
        if ( ! $opt_d ) {
            $result = system($makeTarball );
        }
﻿  ﻿  if ($result) { $dumpFileError = 1; }
﻿  }
    
    # copy the tarballs to S3
﻿  my $client = Net::Amazon::S3::Client->new( s3 => $s3 );
    if ( ! $dumpFileError ) {
        logit ( "uploading to S3" );
        if ( ! $opt_d ) {
            my $bucket = $client->bucket( name => $s3Bucket );
            my $object = $bucket->object(
                                          key          => $tarballFilename,
                                          acl_short    => 'private',
                                          content_type => 'application/x-gtar',
            );
            $object->put_filename( $tarballFilename );
        }
    }
    
    # erase dump files
    if ( ! $dumpFileError ) {
        # if not -d then execute actual command
        if ( ! $opt_d ) {
            unlink $dumpJobs{$dumpJob}{'dumpFilename'};
            unlink $tarballFilename;
        }
    }

﻿  if ( $dumpFileError ) {
﻿  ﻿  $dumpJobError = 1;
﻿  ﻿  $dumpJobErrors .= "$dumpJob ";
﻿  }
}
if ( $dumpJobError ) {
﻿  warn "$0 error: error(s) during database dumping: $dumpJobErrors\n";
﻿  exit 1;
}

#
# create filename segement so dump tarballs 'rotate'
#
sub tarDateSegment {
﻿  my $dt = DateTime->now();
﻿  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
﻿  $year += 1900;
﻿  my $dateTime = sprintf "%4d-%02d-%02d %02d:%02d:%02d", $year, $mon + 1, $mday, $hour, $min, $sec;
﻿  my $date     = sprintf "%4d-%02d-%02d",                $year, $mon + 1, $mday;
﻿  my @weekdays = qw( sun mon tue wed thu fri sat );
﻿  my $weekday  = $weekdays[$wday];
﻿  my @months   = qw( jan feb mar apr may jun jul aug sep oct nov dec );
﻿  my $month    = $months[$mon];
﻿  my $weekOfMonth = $dt->week_of_month;
﻿  my $dateTar = "";

﻿  # if the first day of the year, set $dateTar like: 2009-1st
﻿  if ( $yday == 1 ) {
﻿  ﻿  $dateTar = "$year-1st";
﻿  }

﻿  # if the first day of the month, set $dateTar like: feb-1st
﻿  elsif ( $mday == 1 ) {
﻿  ﻿  $dateTar = "$month-1st";
﻿  }

﻿  # if the first day of the week, set $dateTar like: mon-1
﻿  # where the number is the week of the month number
﻿  elsif ( $wday == 1 ) {
﻿  ﻿  $dateTar = "$weekday-$weekOfMonth";
﻿  }

﻿  # otherwise, set the $dateTar like: mon
﻿  else {
﻿  ﻿  $dateTar = "$weekday";
﻿  }

﻿  # $sec      seconds          54
﻿  # $min      monutes          37
﻿  # $hour     hour             11
﻿  # $mon      month            4
﻿  # $year     year             2009
﻿  # $wday     weekday          3
﻿  # $yday     day of the year  146
﻿  # $isdst    is DST           1
﻿  # $weekday  day of the week  wed
﻿  # $month    month            may
﻿  # $dateTime date and time    2009-05-27 11:37:54
﻿  # $date     date             2009-05-27
﻿  return $dateTar;
}

#
# append log file
#
sub logit {
﻿  my ($logText) = @_;

﻿  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
﻿  my $dateTime = sprintf "%4d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec;

﻿  if ( $opt_v || $opt_d ) {
        print "$logText\n";
    }

    if ( $opt_d ) {
        return;
    }

﻿  #open my $fhLog, ">>", $fileLog;
﻿  #print $fhLog "$dateTime $logText\n";
﻿  #close $fhLog;

﻿  return;
}

#
# help message
#
sub HELP_MESSAGE {
    print "$0\n";
    print "dumps/tars/rotates MySQL databases\n";
    print "backs up selected directories to Amazon S3\n";
    print "-h\t prints this help\n";
    print "-v\t verbose mode\n";
    print "-d\t dry run mode (does not execute sub commands)\n";
    exit;
}
