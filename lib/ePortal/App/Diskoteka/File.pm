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


package ePortal::App::Diskoteka::File;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::Support/;

    use ePortal::Utils;
    use ePortal::Global;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'Diskoteka';
    $p{Attributes}{id} ||= {};
    $p{Attributes}{filedate} ||= {
        dtype => 'DateTime',
        label => {rus => 'Дата', eng => 'Date'},
    };
    $p{Attributes}{filesize} ||= {
        dtype => 'Number',
        label => {rus => 'Размер', eng => 'Size'},
    };
    $p{Attributes}{filetype} ||= {
        label => {rus => 'Тип файла', eng => 'File type'},
    };
    $p{Attributes}{medium_id} ||= {
        dtype => 'Number',
        fieldtype => 'popup_menu',
        label => {rus => 'Носитель', eng => 'Medium'},
        popup_menu => sub {
            my $self = shift;
            my $m = new ePortal::App::Diskoteka::Medium;
            my ($values, $labels) = $m->restore_all_hash();
            push @{$values}, '';
            $labels->{''} = '---';
            return ($values, $labels);
        }
    };
    $p{Attributes}{parent_id} ||= {
        dtype => 'Number',
    };
    $p{Attributes}{memo} ||= {};
    $p{Attributes}{title} ||= {};

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Validate the objects data
# Returns: Error string or undef
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    $self->parent_id(undef) if $self->parent_id == 0;
    $self->FileSize(0) if $self->FileSize == 0;

    # Check title
    unless ( $self->title ) {
        return pick_lang(rus => "Не указано наименование", eng => 'No name');
    }

    undef;
}##validate


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # default ORDER BY clause
    $p{order_by} = 'filetype desc, title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where



############################################################################
sub children    {   #06/17/02 11:11
############################################################################
    my $self = shift;
    my $C = new ePortal::App::Diskoteka::File;
    $C->restore_where(parent_id => $self->id);
    return $C;
}##children


1;
