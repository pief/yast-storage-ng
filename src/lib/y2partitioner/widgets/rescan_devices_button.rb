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

require "yast"
require "cwm/widget"
require "y2partitioner/widgets/reprobe"

Yast.import "Popup"
Yast.import "Mode"

module Y2Partitioner
  module Widgets
    # Button for rescanning system devices
    class RescanDevicesButton < CWM::PushButton
      include Reprobe

      def initialize
        textdomain "storage"
      end

      # @macro seeAbstractWidget
      def label
        # TRANSLATORS: button label to rescan devices
        _("Rescan Devices")
      end

      # Shows a confirm message before reprobing
      #
      # @return [Symbol, nil]
      def handle
        return nil unless continue?

        reprobe
        :redraw
      end

    private

      def continue?
        Yast::Popup.YesNo(rescan_message)
      end

      def rescan_message
        if Yast::Mode.installation
          _("Re-scanning the storage devices will invalidate all the configuration\n" \
            "options set in the installer regarding storage, with no possibility\n" \
            "to withdraw.\n" \
            "That includes the result and settings of the guided setup as well as\n" \
            "the manual changes performed in the expert partitioner.")
        else
          _("Re-scanning the storage devices will invalidate all the previous\n" \
            "changes with no possibility to withdraw.")
        end
      end
    end
  end
end
