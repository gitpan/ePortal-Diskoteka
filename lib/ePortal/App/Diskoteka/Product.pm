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


package ePortal::App::Diskoteka::Product;
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
    $p{Attributes}{title} ||= {};
    $p{Attributes}{memo} ||= {};
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
    unless ($self->archive_id) {
        throw ePortal::Exception::DataNotValid(
            -text => pick_lang(rus => "Не указан архив", eng => "No archive for product"),
            -object => $self);
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
sub delete  {   #02/19/03 12:56
############################################################################
    my $self = shift;


    if ($self->xacl_check_delete) {
        $self->dbh->do("UPDATE Medium SET product_id=null WHERE product_id=?", undef, $self->id);
    }
    return $self->SUPER::delete();
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

1;
