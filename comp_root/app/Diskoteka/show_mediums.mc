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
  my %args = $m->request_args;
  my $archive_id = $ARGS{archive_id};
  my $product_id = $ARGS{product_id};
  my $text       = $ARGS{text};

  my $app = $ePortal->Application('Diskoteka');
  my $archive = new ePortal::App::Diskoteka::Archive;
  $archive->restore($archive_id);

  my @where;
  if ( exists $ARGS{archive_id} ) {
    push @where, $archive_id? "(Medium.Archive_id=$archive_id)" : "(Medium.Archive_id is null)",

  } else {
    # List of available archives for the user
    my @available_archives = $app->AvailableArchives;
    push @where, "(Medium.archive_id in (" . join(',', @available_archives). '))';
  }

  if ( exists $ARGS{product_id} ) {
    push @where, $product_id? "(Medium.Product_id=$product_id)" : "(Medium.product_id is null)",
  }

  if ( exists $ARGS{text} ) {
    $text =~ tr/'//d;
    push @where, "(Medium.Title like '$text%' or Medium.Memo like '$text%')",
    #push @where, "(Medium.Title like '$text%' or MATCH(Medium.Title, Medium.Memo) AGAINST ('$text'))",
  }

  $obj = new ePortal::App::Diskoteka::Medium(
        DBISource => 'Diskoteka',
        SQL => qq{SELECT Medium.*,
            count(File.id) as file_count,
            sum(File.FileSize) as file_size,
            Product.Title as product_title
            FROM Medium
            left join File on Medium.id = File.Medium_id
            left join Product on Medium.product_id = Product.id
        },
        GroupBy => "Medium.id",
        OrderBy => "Medium.Title",
        Where => join(' AND ', @where),
        );

  $list = new ePortal::HTML::List(obj => $obj, class => "smallfont", width => '95%',
    state => {
      # product and archive
      exists $ARGS{product_id} ? (product_id => $ARGS{product_id}) : (),
      exists $ARGS{archive_id} ? (archive_id => $ARGS{archive_id}) : (),

      # search parameters
      area => $args{area},
      text => $args{text},
    },
    edit_url => "medium_edit.htm", );
  $list->add_column_image();
  $list->add_column( id => "title",
    title => pick_lang(rus => "Название", eng => "Title"),
    url => 'medium_view.htm?medium_id=#id#', sorting => 1);

  if ( $ARGS{url} and $archive->xacl_check_update) {
    $list->add_column_image(src => '/images/icons/i-arrup.gif', url => $ARGS{url});
  }

  $list->add_column( id => "mediumtype",
    title => pick_lang(rus => "Тип", eng => "Type"),  sorting => 1);
  $list->add_column( id => "file_count",
      title => pick_lang(rus => "Файлов", eng => "Files"),
      align => 'center',
      sorting => 1);
  $list->add_column( id => "file_size",
      title => pick_lang(rus => "Размер", eng => "Size"),
      align => 'center',
      sorting => 1);
  $list->add_column( id => "product_title",
      title => pick_lang(rus => "ПО", eng => "Software"),
      sorting => 1);
  $list->add_column_system(
    objtype => 'ePortal::App::Diskoteka::Medium',
    edit => sub{ shift->xacl_check_update },
    delete => sub{ shift->xacl_check_delete });

  my $location = $list->handle_request;
  return $location if $location;

  $obj->restore_where( $list->restore_parameters);
</%perl>

<% $list->draw_list %>


%#=== @metags once =========================================================
<%once>
my ($app, $list, $obj, $search_object);
</%once>

%#=== @metags cleanup =========================================================
<%cleanup>
($app, $list, $obj, $search_object) = ();
</%cleanup>

