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
<& /admin/statistics.htm:show_stat,
  Diskoteka_count => {
    app => 'Diskoteka',
    title => pick_lang(rus => "Архивов всего", eng => "Archives count"),
    sql_1 => "SELECT count(*) FROM Archive",
  } &>
<& /admin/statistics.htm:show_stat,
  Diskoteka_mediums => {
    app => 'Diskoteka',
    title => pick_lang(rus => "Носителей всего", eng => "Mediums count"),
    sql_1 => "SELECT count(*) FROM Medium",
    sql_2 => "SELECT Archive.title, count(Medium.id) as cnt FROM Archive
        left join Medium on Medium.archive_id = Archive.id
        group by Archive.title having cnt>0 ORDER BY cnt DESC",
  } &>
<& /admin/statistics.htm:show_stat,
  Diskoteka_products => {
    app => 'Diskoteka',
    title => pick_lang(rus => "Программных продуктов всего", eng => "Software products count"),
    sql_1 => "SELECT count(*) FROM Product",
  } &>

