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

  my $medium_id = $ARGS{medium_id};
  my $text       = $ARGS{text};

  my @where;
  if ( exists $ARGS{medium_id} ) {
    push @where, "(File.Medium_id=$medium_id)";
  }
  if ( exists $ARGS{text} ) {
    $text =~ tr/'//d;
    push @where, "(File.Title like '$text%' or File.Memo like '$text%')",
    #push @where, "(File.Title like '$text%' or MATCH(File.Title, File.Memo) AGAINST ('$text'))",
  }

  # List of available archives for the user
  my @available_archives = $app->AvailableArchives;
  push @where, "(Medium.archive_id in (" . join(',', @available_archives). '))';

  $obj = new ePortal::ThePersistent::Support(
      DBISource => 'Diskoteka',
      SQL => qq{SELECT File.*,
          Medium.Title as medium_title,
          Medium.id as medium_id
          FROM File
          left join Medium on File.medium_id = Medium.id
      },
      GroupBy => "File.id",
      OrderBy => "File.FileType, File.Title",
      Where => join(' AND ', @where),
      );


  $list = new ePortal::HTML::List(obj => $obj, class => "smallfont",
    state => {
      # product and archive
      exists $ARGS{medium_id} ? (medium_id => $ARGS{medium_id}) : (),

      # search parameters
      area => $args{area},
      text => $args{text},
    },
    edit_url => "medium_view.htm?medium_id=#medium_id#");
  $list->add_column_image();
  $list->add_column( id => "filetype", sorting => 1);
  $list->add_column( id => "title",
    title => pick_lang(rus => "Название", eng => "Title"),
    sorting => 1,
    url => "medium_view.htm?medium_id=#medium_id#&parent_id=#id##files");
  $list->add_column( id => "filesize", title => 'Size', sorting => 1);
  $list->add_column( id => "filedate", title => 'Date', sorting => 1);
  $list->add_column( id => "medium_title", sorting => 1,
    title => pick_lang(rus => "Название носителя", eng => "Medium title"),
    url => "medium_view.htm?medium_id=#medium_id#");
  $list->add_column( id => "memo",
    title => pick_lang(rus => "Примечание", eng => "Memo"),
    );

  my $location = $list->handle_request;
  #return $location if $location;

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

