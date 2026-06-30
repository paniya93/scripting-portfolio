#!/usr/bin/env perl
#Author: Praneeth_Perera

use strict;
use warnings;
use Net::SFTP::Foreign;
use File::Copy;
use File::Path qw(make_path);

# === Configuration ===
my $REPORT_LOCATION      = '/path/to/input/reports';
my $REPORT_SAVE_LOCATION = '/path/to/processed/reports';
my $BACKUP_PATH          = '/path/to/backups/';
my $LOG_DIR              = '/path/to/logs/';

# SFTP Configuration (Use SSH keys in production instead of password)
my $SFTP_HOST     = 'your.sftp.server.com';
my $SFTP_PORT     = 22;
my $SFTP_USER     = 'your_username';
# my $SFTP_PASSWORD = 'your_password';   # Recommended to remove and use keys

(my $sec, my $min, my $hour, my $day, my $month, my $year) = localtime(time);
$month += 1; $year -= 100;
my $date_str = sprintf("%02d%02d%02d", $day, $month, $year);
my $log_file = $LOG_DIR . $date_str . ".log";

process_files();
# sftp_transfer();   # Uncomment when ready

log_info("Script completed.");

sub process_files {
    log_info("Starting file processing...");
    my @files = `find $REPORT_LOCATION -type f -name "*On_Net*"`;
    chomp @files;

    foreach my $src (@files) {
        next unless -f $src;
        my $filename = (split('/', $src))[-1];
        my $dest = "$REPORT_SAVE_LOCATION/$filename";

        log_info("Processing: $filename");

        open my $in,  '<', $src  or next;
        open my $out, '>', $dest or next;

        print $out "BULSUSP,69,,,,\n";   # Header line

        my $count = 0;
        while (<$in>) {
            $count++;
            next if $count < 2;   # Skip header

            chomp;
            my @fields = split(',', $_);
            next unless @fields >= 2;

            my $first = substr($fields[0], 3);
            my ($date_part) = split(' ', $fields[1]);
            my ($y, $m, $d) = split('-', $date_part);

            print $out "$first,SFU,,N,,$d/$m/$y\n";
        }

        close $in;
        close $out;

        unlink $src;
        log_info("Processed: $filename");
    }
}

sub sftp_transfer {
    log_info("Starting SFTP transfer...");

    my $sftp = Net::SFTP::Foreign->new(
        host     => $SFTP_HOST,
        port     => $SFTP_PORT,
        user     => $SFTP_USER,
        # password => $SFTP_PASSWORD,
        timeout  => 30
    ) or do { log_info("SFTP connection failed"); return; };

    $sftp->setcwd('/remote/destination/path') or do {
        log_info("Failed to set remote directory");
        return;
    };

    my @files = `find $REPORT_SAVE_LOCATION -type f`;
    chomp @files;

    foreach my $file (@files) {
        next unless -f $file;
        my $remote_name = (split('/', $file))[-1];

        if ($sftp->put($file, $remote_name)) {
            log_info("Uploaded: $remote_name");
            move($file, $BACKUP_PATH) or log_info("Backup failed for $file");
        } else {
            log_info("Upload failed: $remote_name");
        }
    }

    $sftp->disconnect;
    log_info("SFTP transfer completed.");
}

sub log_info {
    my $msg = shift;
    open my $log, '>>', $log_file or return;
    print $log localtime() . " | $msg\n";
    close $log;
}

