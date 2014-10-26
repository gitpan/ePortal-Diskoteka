%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#
%#----------------------------------------------------------------------------
<%perl>
  my %args = $m->request_args;

  my $app = $ePortal->Application('Diskoteka');

  my @AvailableArchives = $app->AvailableArchives;

  my $archive = new ePortal::App::Diskoteka::Archive;
  $archive->restore($args{archive_id});

  my $medium = new ePortal::App::Diskoteka::Medium;
  $medium->restore($args{medium_id});

  my $product = new ePortal::App::Diskoteka::Product;
  $product->restore($args{product_id});

</%perl>
<& /navigator.mc,
  title => pick_lang(rus => "���������", eng => "Diskoteka"),
  description => pick_lang(rus => "� ������� �������� ����������.", eng => "Diskoteka home"),
  url => '/app/Diskoteka/index.htm',
  items => [ qw/archive medium  product search / ],

  archive => {
    title => pick_lang(rus => "�����", eng => "Archive"),
    #url => '/app/Diskoteka/archive_edit.htm?objid=0',
    description => pick_lang(rus => "�������� � �������� ���������", eng => "Work with archives"),
    items => [ qw/archive_list archive_view archive_edit archive_create / ],
  },
  archive_list => {
    title => pick_lang(rus => "������ �������", eng => "List of archives"),
    url => '/app/Diskoteka/index.htm',
    description => pick_lang(rus => "������ ���� ��������� �������", eng => "List of archives"),
  },
  archive_view => {
    title => pick_lang(rus => "�������� ������", eng => "View archive"),
    url => '/app/Diskoteka/archive.htm?archive_id=#archive_id#',
    description => pick_lang(rus => "�������� ����������� ������ ", eng => "View archive")  . $archive->Title,
    depend => [qw/archive_id/],
  },
  archive_create => {
    title => pick_lang(rus => "������� �����", eng => "Archives"),
    url => '/app/Diskoteka/archive_edit.htm?objid=0&archive_id=#archive_id#',
    description => pick_lang(rus => "������� ����� �����", eng => "List of archives"),
    disabled => $app->xacl_check('xacl_create'),
  },
  archive_edit => {
    title => pick_lang(rus => "��������", eng => "Edit"),
    url => '/app/Diskoteka/archive_edit.htm?objid=#archive_id#',
    description => pick_lang(rus => "�������� ����� ", eng => "Edit the archive ") . $archive->Title,
    depend => [qw/archive_id/],
    disabled => ! $archive->xacl_check_update,
  },

  medium => {
    title => pick_lang(rus => "��������", eng => "Medium"),
    description => pick_lang(rus => "�������� � ���������� ����������", eng => "Operations with mediums or disks"),
    items => [qw/medium_load medium_create medium_edit medium_delete/],
    disabled => ! $ePortal->username,
    #disabled => 0,
    #depend => [qw/medium_id/],
  },
  medium_load => {
    title => pick_lang(rus => "��������� ��������", eng => "Load a medium"),
    url => '/app/Diskoteka/load_medium.htm',
    description => pick_lang(rus => "��������� �������� � �����", eng => "Load a medium into archive"),
  },
  medium_create => {
    title => pick_lang(rus => "����� ��������", eng => "New medium"),
    url => '/app/Diskoteka/medium_edit.htm?objid=0',
    description => pick_lang(rus => "������� ����� �������� �������", eng => "Create new medium"),
    disabled => scalar(@AvailableArchives) == 0,
  },
  medium_edit => {
    title => pick_lang(rus => "�������� ��������", eng => "Edit medium"),
    url => '/app/Diskoteka/medium_edit.htm?objid=#medium_id#',
    description => pick_lang(rus => "�������� �������� ", eng => "Edit the medium ") . $medium->Title,
    depend => [qw/medium_id/],
  },
  medium_delete => {
    title => pick_lang(rus => "������� !!!", eng => "Delete"),
    url => "/delete.htm?objid=#medium_id#&objtype=ePortal::App::Diskoteka::Medium&done=/app/Diskoteka/index.htm",
    description => pick_lang(rus => "������� �������� ", eng => "Delete the medium ") . $medium->Title,
    depend => [qw/medium_id/],
  },

  product => {
    title => pick_lang(rus => "�������� ��", eng => "Software"),
    description => pick_lang(rus => "����������� ��������", eng => "Software products"),
    items => [qw/product_list product_edit product_create/],
    disabled => scalar(@AvailableArchives) == 0,
  },
  product_list => {
    title => pick_lang(rus => "������", eng => "List"),
    description => pick_lang(rus => "������ ����������� ���������", eng => "List of software"),
    url => '/app/Diskoteka/product_list.htm',
  },
  product_create => {
    title => pick_lang(rus => "��������", eng => "Create"),
    description => pick_lang(rus => "������� ����� ����������� �������", eng => "Create new software"),
    url => '/app/Diskoteka/product_edit.htm?objid=0',
  },
  product_edit => {
    title => pick_lang(rus => "��������", eng => "Edit"),
    description => pick_lang(rus => "�������� ����������� ������� ", eng => "Edit software ") . $product->Title,
    url => '/app/Diskoteka/product_edit.htm?objid=#product_id#',
    depend => [qw/product_id/],
  },




  search => {
    title => pick_lang(rus => "����� � �������", eng => "Search"),
    url => '/app/Diskoteka/search.htm',
    description => pick_lang(rus => "����� � �������", eng => "Search in archives"),
  },



  product_id => $args{product_id},
  medium_id => $args{medium_id},
  archive_id => $args{archive_id},

  %ARGS,
&>

