#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
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
# find current contact information at www.suse.com

require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/widgets/partitions_tab"

describe Y2Partitioner::Widgets::PartitionsTab do
  before do
    devicegraph_stub(scenario)
  end

  let(:current_graph) { Y2Partitioner::DeviceGraphs.instance.current }

  let(:scenario) { "mixed_disks" }

  let(:device_name) { "/dev/sda" }

  let(:device) { current_graph.find_by_name(device_name) }

  let(:pager) { double("Pager") }

  subject { described_class.new(device, pager) }

  include_examples "CWM::Tab"

  describe "#contents" do
    let(:widgets) { Yast::CWM.widgets_in_contents([subject]) }

    it "shows a button for adding a new partition" do
      button = widgets.detect { |i| i.is_a?(Y2Partitioner::Widgets::PartitionAddButton) }
      expect(button).to_not be_nil
    end

    it "shows a button for deleting all partitions" do
      button = widgets.detect { |i| i.is_a?(Y2Partitioner::Widgets::PartitionsDeleteButton) }
      expect(button).to_not be_nil
    end
  end
end
