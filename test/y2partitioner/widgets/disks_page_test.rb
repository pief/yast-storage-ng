require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/widgets/disks_page"

describe Y2Partitioner::Widgets::DisksPage do
  before do
    devicegraph_stub("mixed_disks_btrfs.yml")
  end

  let(:devicegraph) { Y2Partitioner::DeviceGraphs.instance.current }

  let(:devices) { (devicegraph.disks + devicegraph.disks.map(&:partitions)).flatten.compact }

  subject { described_class.new(pager) }

  let(:pager) { double("OverviewTreePager") }

  include_examples "CWM::Page"

  describe "#contents" do
    let(:widgets) { Yast::CWM.widgets_in_contents([subject]) }

    it "shows a table with the disk devices and their partitions" do
      table = widgets.detect { |i| i.is_a?(Y2Partitioner::Widgets::BlkDevicesTable) }

      expect(table).to_not be_nil

      devices_name = devices.map(&:name)
      items_name = table.items.map { |i| i[1] }

      expect(items_name.sort).to eq(devices_name.sort)
    end

    it "shows a delete button" do
      button = widgets.detect { |i| i.is_a?(Y2Partitioner::Widgets::DeleteDiskPartitionButton) }
      expect(button).to_not be_nil
    end
  end
end
