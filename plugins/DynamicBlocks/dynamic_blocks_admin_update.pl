#!/usr/local/bin/perl -w

# This code is a part of Slash, and is released under the GPL.
# Copyright 1997-2009 by Open Source Technology Group. See README
# and COPYING for more information, or see http://slashcode.com/.

use strict;

use Slash;
use Slash::Constants ':slashd';
use Slash::Utility;

use vars qw(%task $me $task_exit_flag);

$task{$me}{timespec} = '0-59 * * * *';
$task{$me}{fork} = SLASHD_NOWAIT;
$task{$me}{code} = sub {
        my($virtual_user, $constants, $slashdb, $user) = @_;

        my $dynamic_blocks_db = getObject('Slash::DynamicBlocks');
        return 'DynamicBlocks DB unset, aborting' unless $dynamic_blocks_db;

        my $admin_db = getObject('Slash::Admin');
        return 'Admin DB unset, aborting' unless $admin_db;

        my $admin_public_blocks_def = $dynamic_blocks_db->getBlockDefinition('', { type => 'admin', private => 'no'} );
        my $block_names = $slashdb->sqlSelectColArrayref('name', 'dynamic_user_blocks', 'type_id = ' . $admin_public_blocks_def->{type_id});
        my $block;
        foreach my $name (@$block_names) {
                $block = $admin_db->showPerformanceBox({ contents_only => 1})    if ($name eq 'performancebox');
                $block = $admin_db->showAuthorActivityBox({ contents_only => 1}) if ($name eq 'authoractivity');

                if ($name eq 'admintodo') {
                        ($block) = $admin_db->showAdminTodo() =~ m{(<b><a href.+<hr>)};
                }

                if (($name eq 'recenttagnames') && (my $tagsdb = getObject('Slash::Tags'))) {
                        $block = $tagsdb->showRecentTagnamesBox({ contents_only => 1 });
                }

                if (($name eq 'firehoseusage') && (my $fh_db = getObject('Slash::FireHose'))) {
                        $block = $fh_db->ajaxFireHoseUsage();
                }

                my $old_block_content = $slashdb->sqlSelect('id, block', 'dynamic_user_blocks',
                                                            'type_id = ' . $admin_public_blocks_def->{type_id} .
                                                            " and name = '$name'");

		# Only update if the data differs
		$dynamic_blocks_db->setBlock( { block => $block, name => $name } ) if ($old_block_content ne $block);
        }

        return;
};

1;