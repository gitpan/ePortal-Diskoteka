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


package ePortal::App::Diskoteka::Archive;
    our $VERSION = '4.1';
    use base qw/ePortal::ThePersistent::ExtendedACL/;

    use ePortal::Utils;
    use ePortal::Global;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'Diskoteka';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{private} ||= {
            dtype => 'YesNo',
            label => {rus => 'Личный', eng => 'Private'},
            default => 1,
        };
    $p{Attributes}{memo} ||= {
            label => {rus => 'Примечания', eng => 'Memo'},
            fieldtype => 'textarea',
            maxlength => 65000,
        };
    $p{Attributes}{title} ||= {
            default => pick_lang(rus => "Архив ", eng => "Archive of ") . $ePortal->username,
        };
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{xacl_write} ||= {
            label => pick_lang(rus => 'Изменение каталога', eng => 'Edit catalogue'),
        };

    $self->SUPER::initialize(%p);
}##initialize


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
    my $C = new ePortal::App::Diskoteka::Medium;
    $C->restore_where(archive_id => $self->id);
    return $C;
}##children

############################################################################
sub delete  {   #02/25/03 12:56
############################################################################
    my $self = shift;
    my $app_dbh = $self->dbh();
    my $id = $self->id;
    my $result;

    if ($self->xacl_check_delete) {
        my $M = new ePortal::App::Diskoteka::Medium;
        $M->restore_where(archive_id => $id);
        while($M->restore_next) {
            $result += $M->delete;
        }

        $result += $app_dbh->do("DELETE FROM Product WHERE archive_id=?", undef, $self->id);
    }

    $result += $self->SUPER::delete();  # Will throw if ACL broken

    return $result;
}##delete

############################################################################
sub xacl_check_insert   {   #02/20/03 8:31
############################################################################
    my $self = shift;
    return $ePortal->Application('Diskoteka')->xacl_check_create_archive;
}##xacl_check_insert


############################################################################
# Who may create then he may delete.
# If a user may write to archive then he still may not delete it!
sub xacl_check_delete   {   #02/25/03 2:17
############################################################################
    my $self = shift;
    return $self->xacl_check_insert;
}##xacl_check_delete

1;
