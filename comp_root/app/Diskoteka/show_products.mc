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
% if ($ARGS{title}) {
<& /item_caption.mc,
  title => $ARGS{title},
  extra => $ARGS{extra} &>
% }

<%perl>
  my $app = $ePortal->Application('Diskoteka');
  my %args = $m->request_args;

  my $archive_id = $ARGS{archive_id};
  my $product_id = $ARGS{product_id};
  my $text       = $ARGS{text};

  my @where;
  if ( exists $ARGS{archive_id} ) {
    push @where, $archive_id? "(Product.Archive_id=$archive_id)" : "(Product.Archive_id is null)",
  }
  if ( exists $ARGS{text} ) {
    $text =~ tr/'//d;
    push @where, "(Product.Title like '$text%' or Product.Memo like '%$text%')",
    #push @where, "(Product.Title like '$text%' or MATCH(Product.Title, Product.Memo) AGAINST ('$text'))",
  }

  # List of available archives for the user
  my @available_archives = $app->AvailableArchives;
  push @where, "(Product.archive_id in (" . join(',', @available_archives). '))';

  $obj = new ePortal::App::Diskoteka::Product(
      DBISource => 'Diskoteka',
      SQL => qq{SELECT Product.*,
          count(Medium.id) as medium_count,
          Archive.Title as archive_title
          FROM Product
          left join Medium on Product.id=Medium.product_id
          left join Archive on Archive.id=Product.archive_id
      },
      GroupBy => "Product.Title",
      Where => join(' AND ', @where),
      );


  $list = new ePortal::HTML::List(obj => $obj, class => "smallfont",
    state => {
      # product and archive
      exists $ARGS{product_id} ? (product_id => $ARGS{product_id}) : (),
      exists $ARGS{archive_id} ? (archive_id => $ARGS{archive_id}) : (),

      # search parameters
      area => $args{area},
      text => $args{text},
    },
    edit_url => "product_edit.htm");
  $list->add_column_image();
  $list->add_column( id => "title",
    title => pick_lang(rus => "Название", eng => "Title"),
    url => $ARGS{url}, sorting => 1);
  $list->add_column( id => "archive_title",
    title => pick_lang(rus => "Название архива", eng => "Archive title"),
    url => "archive_edit.htm?objid=#id#", sorting => 1);
  $list->add_column( id => "medium_count",
      title => pick_lang(rus => "Носителей", eng => "Mediums"),
      align => 'center',
      sorting => 1);
  $list->add_column_system(
    objtype => 'ePortal::App::Diskoteka::Product',
    edit => sub{ shift->xacl_check_update },
    delete => sub{ shift->xacl_check_delete });

  my $location = $list->handle_request;
  return $location if $location;

  $obj->restore_where( $list->restore_parameters);
</%perl></%method>

<% $list->draw_list %>


%#=== @metags once =========================================================
<%once>
my ($app, $list, $obj, $search_object);
</%once>

%#=== @metags cleanup =========================================================
<%cleanup>
($app, $list, $obj, $search_object) = ();
</%cleanup>

