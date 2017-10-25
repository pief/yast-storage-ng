# encoding: utf-8

# Copyright (c) [2017] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "cwm/tree_pager"
require "y2partitioner/icons"
require "y2partitioner/device_graphs"
require "y2partitioner/sequences/add_md"
require "y2partitioner/widgets/md_raids_table"
require "y2partitioner/widgets/edit_blk_device_button"

module Y2Partitioner
  module Widgets
    module Pages
      # A Page for md raids: contains a {MdRaidsTable}
      class MdRaids < CWM::Page
        include Yast::I18n
        extend Yast::I18n

        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "storage"

          @pager = pager
        end

        # Label for all the instances
        #
        # @see #label
        #
        # @return [String]
        def self.label
          _("RAID")
        end

        # @macro seeAbstractWidget
        def label
          self.class.label
        end

        # @macro seeCustomWidget
        def contents
          return @contents if @contents

          icon = Icons.small_icon(Icons::RAID)
          table = MdRaidsTable.new(devices, @pager)
          @contents = VBox(
            Left(
              HBox(
                Image(icon, ""),
                # TRANSLATORS: Heading
                Heading(_("RAID"))
              )
            ),
            table,
            Left(
              HBox(
                AddButton.new,
                EditBlkDeviceButton.new(table: table)
              )
            )
          )
        end

      private

        def devices
          Y2Storage::Md.all(DeviceGraphs.instance.current)
        end

        # Button to fire the wizard to add a new MD array ({Sequences::AddMd})
        class AddButton < CWM::PushButton
          # Constructor
          def initialize
            textdomain "storage"
          end

          def label
            _("Add RAID...")
          end

          def handle
            res = Sequences::AddMd.new.run
            res == :finish ? :redraw : nil
          end
        end
      end
    end
  end
end
