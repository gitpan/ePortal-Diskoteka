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


package ePortal::App::Diskoteka;
    our $VERSION = '4.2';

    use base qw/ePortal::Application/;
    use File::Basename qw//;
    use Params::Validate qw/:types/;
    use Error qw/:try/;

    # use system modules
    use ePortal::Global;
    use ePortal::Utils;
    use ePortal::ThePersistent::Support;
    use ePortal::ThePersistent::UserConfig;

    # use internal Application modules
    use ePortal::App::Diskoteka::Archive;
    use ePortal::App::Diskoteka::Medium;
    use ePortal::App::Diskoteka::Product;
    use ePortal::App::Diskoteka::File;


sub xacl_check_create_archive { shift->xacl_check('xacl_create'); }

############################################################################
sub initialize  {   #09/08/2003 10:10
############################################################################
    my ($self, %p) = @_;
    
    $p{Attributes}{xacl_create} = {
          label => {rus => 'Создание архивов', eng => 'Create an archive'},
          fieldtype => 'xacl',
      };

    $self->SUPER::initialize(%p);
}##initialize



############################################################################
# Function: AvailableArchives
# Description:
# Parameters:
# Returns:
#
############################################################################
sub AvailableArchives   {   #02/19/03 4:09
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with(params => \@_,
        spec => {
            writable => { type => BOOLEAN, optional => 1},
        });

    my @available_archives;
    my $A = new ePortal::App::Diskoteka::Archive;
    $A->restore_all;
    while($A->restore_next) {
        next if $A->Private and ($A->uid ne $ePortal->username);
        next if $p{writable} and (! $A->xacl_check_update);
        push @available_archives, $A->id;
    }
    push @available_archives, 0 if @available_archives==0;
    return @available_archives;
}##AvailableArchives

############################################################################
# List of archives with additional info
############################################################################
sub stArchives  {   #02/11/03 1:02
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with(params => \@_,
        spec => {
            writable => { type => BOOLEAN, optional => 1},
        });

    my $st = new ePortal::ThePersistent::ExtendedACL(
        DBISource => 'Diskoteka',
        SQL => qq{SELECT Archive.*,
            count(Medium.id) as medium_count,
            max(Medium.LoadDate) as LoadDate
            FROM Archive
            left join Medium on Archive.id=Medium.archive_id
        },
        xacl_uid_field => 'Archive.uid',
        xacl_read_field => 'Archive.xacl_read',
        GroupBy => "Archive.id",
        OrderBy => 'Archive.Title',
        Attributes => {
            LoadDate => {dtype => 'Date'}
        },
        Where => "Archive.id in (" . join(',', $self->AvailableArchives(writable=>$p{writable})) . ')',
        );
    return $st;
}##stArchives

############################################################################
# List of products with additional info
############################################################################
sub stProducts  {   #02/11/03 1:02
############################################################################
    my $self = shift;

    # List of available archives for the user
    my @available_archives = $self->AvailableArchives;

    my $st = new ePortal::ThePersistent::Support(
        DBISource => 'Diskoteka',
        SQL => qq{SELECT Product.*,
            count(Medium.id) as medium_count,
            Archive.Title as archive_title
            FROM Product
            left join Medium on Product.id=Medium.product_id
            left join Archive on Archive.id=Product.archive_id
        },
        GroupBy => "Product.Title",
        Where => "Product.archive_id in (" . join(',', @available_archives). ')',
        );
    return $st;
}##stProducts

############################################################################
# List of archives with additional info
############################################################################
sub stMediums  {   #02/11/03 1:02
############################################################################
    my $self = shift;
    my $archive_id = shift;

    my $st = new ePortal::ThePersistent::Support(
        DBISource => 'Diskoteka',
        SQL => qq{SELECT Medium.*,
            count(File.id) as file_count,
            sum(File.FileSize) as file_size
            FROM Medium
            left join File on Medium.id = File.Medium_id
        },
        GroupBy => "Medium.Title",
        Where => $archive_id? "Medium.Archive_id=$archive_id" : "Medium.Archive_id is null",
        );
    return $st;
}##stMediums


############################################################################
# Delete personal archives
############################################################################
sub onDeleteUser    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $username = shift;
    my $result = 0;

    my $tp = new ePortal::App::Diskoteka::Archive();
    $tp->restore_where(where => 'Private=1', uid => $username);
    while($tp->restore_next) {
        $result += $tp->delete;
    }
    return $result;
}##onDeleteUser


############################################################################
sub UploadMedium    {   #02/13/03 8:29
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with( params => \@_,
        spec => {
            append => { type => BOOLEAN },
            diskname => { type => SCALAR | UNDEF },
            source => { type => SCALAR | UNDEF },
            file => {type => ARRAYREF },
        });

    throw ePortal::Exception(-text => "Missing disk name") if $p{diskname} eq '';
    throw ePortal::Exception(-text => "Missing source path") if $p{source} eq '';

    my $medium = new ePortal::App::Diskoteka::Medium;
    my $PARENT = new ePortal::App::Diskoteka::File;
    my $FILE = new ePortal::App::Diskoteka::File;

    try {
        # locate medium
        if ( $p{append} ) {
            $medium->restore_where(archive_id => undef, title => $p{diskname});
            throw ePortal::Exception(-object => $medium, -text => "Cannot find medium")
                  if ( ! $medium->restore_next );

        } else {
            $medium->Archive_id(undef);
            $medium->Title($p{diskname});
            $medium->LoadDate('now');
            $medium->SourcePath($p{source});
            throw ePortal::Exception(-object => $medium, -text => "Cannot insert medium")
                  if ( ! $medium->insert );

            # root directory
            $PARENT->Title('/');
            $PARENT->Medium_id($medium->id);
            $PARENT->FileType('dir');
            throw ePortal::Exception(-object => $PARENT, -text => "Cannot insert root directory")
                  if ( ! $PARENT->insert );
        }

        foreach my $line (@{$p{file}}) {
            my ($type, $path, $size, $mtime) = split('\|', $line);

            # strip source path from file name
            $path =~ s/^$p{source}//;
            my ($filename, $filepath) = File::Basename::fileparse($path);

            # fill File object with data
            $FILE->clear;
            $FILE->Medium_id($medium->id);
            $FILE->FileType($type);
            $FILE->FileSize($size);
            my @m = localtime($mtime);
            $FILE->FileDate( sprintf("%04d-%02d-%02d %02d:%02d:%02d", 1900+$m[5], 1+$m[4], $m[3], $m[2], $m[1], $m[0] ));

            # different things for dir and file
            if ($type eq 'dir') {
                $FILE->Parent_id(undef);
                $FILE->Title("$filepath$filename/");
            } else {
                if ($PARENT->Title ne $filepath) {
                    $PARENT->restore_where(where => 'medium_id=? and title=?', bind => [$medium->id, $filepath]);
                    throw ePortal::Exception(-text => "Cannot find parent for $path")
                        if ! $PARENT->restore_next;
                }
                $FILE->Parent_id($PARENT->id);
                $FILE->Title($filename);
            }

            # insert it
            throw ePortal::Exception(-object => $FILE, -text => "Cannot insert file")
                  if ( ! $FILE->insert );
        }

    } catch ePortal::Exception with {
        my $E = shift;
        logline('error', $E->stacktrace);

        # Clean all possible loaded data
        if (my $medium_id = $medium->id) {
            my $app_dbh = $self->dbh;
            $app_dbh->do("DELETE from Medium WHERE id=?", undef, $medium_id);
            $app_dbh->do("DELETE from File WHERE medium_id=?", undef, $medium_id);
        }
        $E->throw;   # rethrow Exception

    } finally {
    };
    1;
}##UploadMedium

############################################################################
# Function: countMediums
# Description: Count mediums for archive. use undef to count undevided mediums.
# Parameters:
# Returns:
#
############################################################################
sub countMediums    {   #02/19/03 1:47
############################################################################
    my $self = shift;
    my $archive_id = shift;

    my $sql = "SELECT count(*) from Medium WHERE archive_id ";
    $sql .= $archive_id ? "= $archive_id" : "is null";
    my $count = 0+ $self->dbh->selectrow_array($sql);
    return $count;
}##countMediums


1;
