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


package ePortal::App::Diskoteka::Medium;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::ParentACL/;

    use ePortal::Utils;
    use ePortal::Global;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'Diskoteka';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{loaddate} ||= {
        dtype => 'Date',
        label => {rus => 'Дата загрузки', eng => 'Load date'},
    };
    $p{Attributes}{sourcepath} ||= {
        label => {rus => 'Откуда загружен', eng => 'Source path'},
    };
    $p{Attributes}{archive_id} ||= {
        dtype => 'Number',
        fieldtype => 'popup_menu',
        label => {rus => 'Архив', eng => 'Archive'},
        popup_menu => sub {
            my $self = shift;
            my $m = $ePortal->Application('Diskoteka')->stArchives(writable=>1);
            my ($values, $labels) = $m->restore_all_hash();
            push @{$values}, undef;
            $labels->{undef} = '---';
            return ($values, $labels);
        }
    };
    $p{Attributes}{product_id} ||= {
        dtype => 'Number',
        fieldtype => 'popup_menu',
        label => {rus => 'Прогр.продукт', eng => 'Software'},
        popup_menu => sub {
            my $self = shift;
            my $m = $ePortal->Application('Diskoteka')->stProducts;
            my ($values, $labels) = $m->restore_all_hash();
            unshift @{$values}, undef;
            $labels->{undef} = '---';
            return ($values, $labels);
        }
    };
    $p{Attributes}{mediumtype} ||= {
        dtype => 'VarChar',
        label => {rus => 'Тип носителя', eng => 'Medium type'},
        fieldtype => 'popup_menu',
        values => [qw/cdrom cdrw floppy tape/],
    };
    $p{Attributes}{memo} ||= {};
    $p{Attributes}{uid} ||= {};
    $p{Attributes}{title} ||= {};
    $p{Attributes}{ts} ||= {};

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Validate the objects data
# Returns: Error string or undef
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    # archive_id cannot be 0
    $self->archive_id(undef) if $self->archive_id == 0;

    # When a Medium is first time updated from the WEB update loader name also
    if ($self->uid eq '') {
        $self->uid($ePortal->username);
    }

    $self->SUPER::validate($beforeinsert);
}##validate


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # default ORDER BY clause
    $p{order_by} = 'title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where



############################################################################
sub children    {   #06/17/02 11:11
############################################################################
    my $self = shift;
    my $C = new ePortal::App::Diskoteka::File;
    $C->restore_where(medium_id => $self->id);
    return $C;
}##children

sub Files {
    children(@_);
}


############################################################################
# Function: stMediumContent
# Description: returns ThePersistent object with content of the medium
# Parameters:
# Returns:
#
############################################################################
sub stMediumContent {   #02/19/03 8:56
############################################################################
    my $self = shift;

    my $st = new ePortal::ThePersistent::Support(
        DBISource => 'Diskoteka',
        SQL => qq{SELECT File.*,
            count(f.id) as files_count,
            sum(f.FileSize) as files_size
            FROM File
            left join File as f on f.parent_id = File.id and f.medium_id=?
        },
        GroupBy => "File.FileType, File.Title",
        Where => "File.Filetype='dir' and File.medium_id=?",
        Bind  => [$self->id, $self->id],
        Attributes => {
            filedate => { dtype => 'DateTime'},
        },
        );
    return $st;
}##stMediumContent

############################################################################
sub delete  {   #02/20/03 11:22
############################################################################
    my $self = shift;

    if ($self->xacl_check_delete) {
        $self->dbh->do("DELETE FROM File WHERE medium_id=?", undef, $self->id);
    }
    $self->SUPER::delete;   # will throw exception if no rights to delete
}##delete

############################################################################
sub parent  {   #02/26/03 9:00
############################################################################
    my $self = shift;

    my $archive = new ePortal::App::Diskoteka::Archive;
    if ($archive->restore($self->archive_id)) {
        return $archive;
    } else {
        return undef;
    }
}##parent

############################################################################
sub xacl_check_insert   {   #02/26/03 9:01
############################################################################
#   anyone may upload a medium
    1;
}##xacl_check_insert

############################################################################
sub xacl_check_read {   #03/04/03 8:47
############################################################################
    my $self = shift;

    # Not distributed medium
    return 1 if $self->archive_id == 0;
    return $self->SUPER::xacl_check_read;
}##xacl_check_read

############################################################################
sub xacl_check_delete {   #03/04/03 8:47
############################################################################
    my $self = shift;

    # Not distributed medium
    return 1 if $self->archive_id == 0;
    return $self->SUPER::xacl_check_delete;
}##xacl_check_delete

############################################################################
sub xacl_check_update {   #03/04/03 8:47
############################################################################
    my $self = shift;

    # Not distributed medium
    return 1 if $self->archive_id == 0;
    return $self->SUPER::xacl_check_update;
}##xacl_check_update

1;
