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
  title => pick_lang(rus => "Дискотека", eng => "Diskoteka"),
  description => pick_lang(rus => "К главной странице приложения.", eng => "Diskoteka home"),
  url => '/app/Diskoteka/index.htm',
  items => [ qw/archive medium  product search / ],

  archive => {
    title => pick_lang(rus => "Архив", eng => "Archive"),
    #url => '/app/Diskoteka/archive_edit.htm?objid=0',
    description => pick_lang(rus => "Действия с архивами носителей", eng => "Work with archives"),
    items => [ qw/archive_list archive_view archive_edit archive_create / ],
  },
  archive_list => {
    title => pick_lang(rus => "Список архивов", eng => "List of archives"),
    url => '/app/Diskoteka/index.htm',
    description => pick_lang(rus => "Список всех доступных архивов", eng => "List of archives"),
  },
  archive_view => {
    title => pick_lang(rus => "Просмотр архива", eng => "View archive"),
    url => '/app/Diskoteka/archive.htm?archive_id=#archive_id#',
    description => pick_lang(rus => "Просмотр содержимого архива ", eng => "View archive")  . $archive->Title,
    depend => [qw/archive_id/],
  },
  archive_create => {
    title => pick_lang(rus => "Создать архив", eng => "Archives"),
    url => '/app/Diskoteka/archive_edit.htm?objid=0&archive_id=#archive_id#',
    description => pick_lang(rus => "Создать новый архив", eng => "List of archives"),
    disabled => $app->xacl_check('xacl_create'),
  },
  archive_edit => {
    title => pick_lang(rus => "Изменить", eng => "Edit"),
    url => '/app/Diskoteka/archive_edit.htm?objid=#archive_id#',
    description => pick_lang(rus => "Изменить архив ", eng => "Edit the archive ") . $archive->Title,
    depend => [qw/archive_id/],
    disabled => ! $archive->xacl_check_update,
  },

  medium => {
    title => pick_lang(rus => "Носитель", eng => "Medium"),
    description => pick_lang(rus => "Операции с носителями информации", eng => "Operations with mediums or disks"),
    items => [qw/medium_load medium_create medium_edit medium_delete/],
    disabled => ! $ePortal->username,
    #disabled => 0,
    #depend => [qw/medium_id/],
  },
  medium_load => {
    title => pick_lang(rus => "Загрузить носитель", eng => "Load a medium"),
    url => '/app/Diskoteka/load_medium.htm',
    description => pick_lang(rus => "Загрузить носитель в архив", eng => "Load a medium into archive"),
  },
  medium_create => {
    title => pick_lang(rus => "Новый носитель", eng => "New medium"),
    url => '/app/Diskoteka/medium_edit.htm?objid=0',
    description => pick_lang(rus => "Создать новый носитель вручную", eng => "Create new medium"),
    disabled => scalar(@AvailableArchives) == 0,
  },
  medium_edit => {
    title => pick_lang(rus => "Изменить носитель", eng => "Edit medium"),
    url => '/app/Diskoteka/medium_edit.htm?objid=#medium_id#',
    description => pick_lang(rus => "Изменить носитель ", eng => "Edit the medium ") . $medium->Title,
    depend => [qw/medium_id/],
  },
  medium_delete => {
    title => pick_lang(rus => "Удалить !!!", eng => "Delete"),
    url => "/delete.htm?objid=#medium_id#&objtype=ePortal::App::Diskoteka::Medium&done=/app/Diskoteka/index.htm",
    description => pick_lang(rus => "Удалить носитель ", eng => "Delete the medium ") . $medium->Title,
    depend => [qw/medium_id/],
  },

  product => {
    title => pick_lang(rus => "Продукты ПО", eng => "Software"),
    description => pick_lang(rus => "Программные продукты", eng => "Software products"),
    items => [qw/product_list product_edit product_create/],
    disabled => scalar(@AvailableArchives) == 0,
  },
  product_list => {
    title => pick_lang(rus => "Список", eng => "List"),
    description => pick_lang(rus => "Список программных продуктов", eng => "List of software"),
    url => '/app/Diskoteka/product_list.htm',
  },
  product_create => {
    title => pick_lang(rus => "Добавить", eng => "Create"),
    description => pick_lang(rus => "Создать новый программный продукт", eng => "Create new software"),
    url => '/app/Diskoteka/product_edit.htm?objid=0',
  },
  product_edit => {
    title => pick_lang(rus => "Изменить", eng => "Edit"),
    description => pick_lang(rus => "Изменить программный продукт ", eng => "Edit software ") . $product->Title,
    url => '/app/Diskoteka/product_edit.htm?objid=#product_id#',
    depend => [qw/product_id/],
  },




  search => {
    title => pick_lang(rus => "Поиск в архивах", eng => "Search"),
    url => '/app/Diskoteka/search.htm',
    description => pick_lang(rus => "Поиск в архивах", eng => "Search in archives"),
  },



  product_id => $args{product_id},
  medium_id => $args{medium_id},
  archive_id => $args{archive_id},

  %ARGS,
&>

