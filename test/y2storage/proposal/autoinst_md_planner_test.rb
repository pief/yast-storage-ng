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
# find current contact information at www.suse.com.

require_relative "../spec_helper"
require "y2storage/proposal/autoinst_md_planner"
require "y2storage/autoinst_issues/list"
require "y2storage/autoinst_profile/drive_section"

describe Y2Storage::Proposal::AutoinstMdPlanner do
  using Y2Storage::Refinements::SizeCasts

  subject(:planner) { described_class.new(fake_devicegraph, issues_list) }
  let(:scenario) { "md_raid.xml" }
  let(:issues_list) { Y2Storage::AutoinstIssues::List.new }

  before do
    fake_scenario(scenario)
  end

  describe "#planned_devices" do
    let(:drive) { Y2Storage::AutoinstProfile::DriveSection.new_from_hashes(raid) }

    let(:raid) do
      {
        "device" => device, "raid_options" => raid_options, "disklabel" => disklabel,
        "partitions" => [home_spec]
      }
    end

    let(:home_spec) do
      { "mount" => "/home", "filesystem" => "xfs", "size" => "max", "partition_nr" => 1 }
    end

    let(:raid_options) do
      { "raid_type" => "raid5" }
    end

    let(:disklabel) { nil }

    let(:device) { "/dev/md2" }

    it "returns a planned RAID with the given device name" do
      md = planner.planned_devices(drive).first
      expect(md.name).to eq("/dev/md2")
    end

    context "when a partition table type is specified" do
      let(:disklabel) { "msdos" }

      it "returns a planned MD RAID with partitions" do
        md = planner.planned_devices(drive).first
        expect(md.partitions).to contain_exactly(
          an_object_having_attributes("mount_point" => "/home")
        )
      end

      it "sets the partition table type" do
        md = planner.planned_devices(drive).first
        expect(md.ptable_type).to eq(Y2Storage::PartitionTables::Type.find("msdos"))
      end
    end

    context "when no partition table type is specified" do
      it "returns a planned MD RAID with partitions" do
        md = planner.planned_devices(drive).first
        expect(md.partitions).to contain_exactly(
          an_object_having_attributes("mount_point" => "/home")
        )
      end

      it "does not set the partition table type" do
        md = planner.planned_devices(drive).first
        expect(md.ptable_type).to be_nil
      end
    end

    context "when the partition table type is set to 'none'" do
      let(:disklabel) { "none" }

      it "returns a planned MD RAID with filesystem settings (no partitions)" do
        md = planner.planned_devices(drive).first
        expect(md.mount_point).to eq("/home")
        expect(md.filesystem_type).to eq(Y2Storage::Filesystems::Type::XFS)
      end

      it "does not set the partition table type" do
        md = planner.planned_devices(drive).first
        expect(md.ptable_type).to be_nil
      end

      context "and RAID options are not specified at drive level" do
        let(:raid_options) { nil }
        let(:home_spec) do
          {
            "mount" => "/home", "filesystem" => "xfs", "size" => "max", "partition_nr" => 1,
            "raid_options" => { "raid_type" => "raid5" }
          }
        end

        it "reads options from the partition section" do
          md = planner.planned_devices(drive).first
          expect(md.md_level).to eq(Y2Storage::MdLevel::RAID5)
        end
      end
    end

    context "when no RAID level is specified" do
      let(:raid_options) { nil }

      it "assumes a RAID1" do
        md = planner.planned_devices(drive).first
        expect(md.md_level).to eq(Y2Storage::MdLevel::RAID1)
      end
    end

    context "when an invalid RAID level is specified" do
      let(:raid_options) do
        { "raid_type" => "non-valid-type" }
      end

      it "assumes a RAID1" do
        md = planner.planned_devices(drive).first
        expect(md.md_level).to eq(Y2Storage::MdLevel::RAID1)
      end

      it "registers an issue" do
        planner.planned_devices(drive).first
        issue = issues_list.find { |i| i.is_a?(Y2Storage::AutoinstIssues::InvalidValue) }
        expect(issue).to_not be_nil
      end
    end

    context "when using a named RAID" do
      let(:device) { "/dev/md/data" }

      it "uses the name instead of a number" do
        md = planner.planned_devices(drive).first
        expect(md.name).to eq("/dev/md/data")
      end
    end

    context "using the old schema" do
      let(:raid) do
        { "device" => "/dev/md", "partitions" => [root_raid_spec, home_raid_spec] }
      end

      let(:raid_options) do
        { "raid_type" => "raid5" }
      end

      let(:root_raid_spec) do
        {
          "mount" => "/", "filesystem" => "ext4", "size" => "max", "partition_nr" => 1,
          "raid_options" => { "raid_type" => "raid5" }
        }
      end

      let(:home_raid_spec) do
        {
          "mount" => "/home", "filesystem" => "xfs", "size" => "max", "partition_nr" => 2,
          "raid_options" => { "raid_type" => "raid1" }
        }
      end

      it "returns a planned RAID using /dev/md + partition_nr as device name" do
        mds = planner.planned_devices(drive)
        expect(mds).to contain_exactly(
          an_object_having_attributes(
            "name" => "/dev/md1", "md_level" => Y2Storage::MdLevel::RAID5
          ),
          an_object_having_attributes(
            "name" => "/dev/md2", "md_level" => Y2Storage::MdLevel::RAID1
          )
        )
      end
    end
  end
end
