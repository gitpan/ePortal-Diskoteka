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
<& ePortal_database.htm:table_exists,
    table => 'Archive',
    SQL => qq{
        CREATE TABLE `Archive` (
        `id` int(11) NOT NULL auto_increment,
        `Title` varchar(255) default NULL,
        `uid` varchar(64) default NULL,
        `xacl_read` varchar(64) default NULL,
        `xacl_write` varchar(64) default NULL,
        `Private` tinyint(4) NOT NULL default '0',
        `ts` timestamp(14) NOT NULL,
        `Memo` text,
        PRIMARY KEY  (`id`)
        )
    } &>

<& ePortal_database.htm:table_exists,
    table => 'File',
    SQL => qq{
        CREATE TABLE `File` (
        `id` int(11) NOT NULL auto_increment,
        `parent_id` int(11) default NULL,
        `Medium_id` int(11) NOT NULL default '0',
        `FileType` enum('file','dir') NOT NULL default 'file',
        `Title` varchar(255) default NULL,
        `FileDate` datetime default NULL,
        `FileSize` int(11) NOT NULL default '0',
        `Memo` varchar(255) default NULL,
        PRIMARY KEY  (`id`),
        KEY `Medium_id` (`Medium_id`,`parent_id`),
        KEY `FileType` (`FileType`,`Title`(16))
        )
    } &>


<& ePortal_database.htm:table_exists,
    table => 'Medium',
    SQL => qq{
        CREATE TABLE `Medium` (
        `id` int(11) NOT NULL auto_increment,
        `Title` varchar(255) default NULL,
        `Archive_id` int(11) default NULL,
        `Product_id` int(11) default NULL,
        `LoadDate` date default NULL,
        `uid` varchar(64) default NULL,
        `MediumType` set('cdrom','cdrw','floppy','tape') default 'cdrom',
        `SourcePath` varchar(255) default NULL,
        `ts` timestamp(14) NOT NULL,
        `Memo` text,
        PRIMARY KEY  (`id`),
        KEY `Archive_id` (`Archive_id`,`Title`(16))
        )
    } &>


<& ePortal_database.htm:table_exists,
    table => 'Product',
    SQL => qq{
        CREATE TABLE `Product` (
        `id` int(11) NOT NULL auto_increment,
        `archive_id` int(11) default NULL,
        `Title` varchar(255) NOT NULL default '',
        `ts` timestamp(14) NOT NULL,
        `Memo` text,
        PRIMARY KEY  (`id`),
        KEY `archive_id` (`archive_id`,`Title`),
        FULLTEXT KEY `Title` (`Title`,`Memo`)
        )
    } &>






<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-Diskoteka-link',
        parent_id  => 'ePortal',
        url        => '/app/Diskoteka/index.htm',
        title      => pick_lang(
               rus => 'Приложение - Каталог носителей программного обеспечения',
               eng => 'Application - Software archive'),
    &>
