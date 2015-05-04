# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/pdf/document'
require 'hexapdf/pdf/type/page_tree_node'

describe HexaPDF::PDF::Type::PageTreeNode do

  before do
    @doc = HexaPDF::PDF::Document.new
    @root = HexaPDF::PDF::Type::PageTreeNode.new({}, document: @doc)
  end

  def define_multilevel_page_tree
    @pages = 8.times.map { @doc.add({Type: :Page}) }
    @kid1 = @doc.add({Type: :Pages, Parent: @root, Count: 5})
    @kid11 = @doc.add({Type: :Pages, Parent: @kid1})
    @kid11.add_page(@pages[0])
    @kid11.add_page(@pages[1])
    @kid12 = @doc.add({Type: :Pages, Parent: @kid1})
    @kid12.add_page(@pages[2])
    @kid12.add_page(@pages[3])
    @kid12.add_page(@pages[4])
    @kid1[:Kids] << @kid11 << @kid12
    @root[:Kids] << @kid1

    @pages[5][:Parent] = @root
    @root[:Kids] << @pages[5]

    @kid2 = @doc.add({Type: :Pages, Parent: @root})
    @kid2.add_page(@pages[6])
    @kid2.add_page(@pages[7])
    @root[:Kids] << @kid2
    @root[:Count] = 8
  end

  describe "page" do
    before do
      define_multilevel_page_tree
    end

    it "returns the page for a given index" do
      assert_equal(@pages[0], @root.page(0))
      assert_equal(@pages[3], @root.page(3))
      assert_equal(@pages[5], @root.page(5))
      assert_equal(@pages[7], @root.page(7))
    end

    it "works with negative indicies counting backwards from the end" do
      assert_equal(@pages[0], @root.page(-8))
      assert_equal(@pages[3], @root.page(-5))
      assert_equal(@pages[5], @root.page(-3))
      assert_equal(@pages[7], @root.page(-1))
    end

    it "returns nil for bad indices" do
      assert_nil(@root.page(20))
      assert_nil(@root.page(-20))
    end
  end

  describe "insert_page" do
    it "uses an empty new page when none is provided" do
      page = @root.insert_page(3)
      assert_equal([page], @root[:Kids])
      assert_equal(1, @root[:Count])
      assert_equal(:Page, page[:Type])
      assert_equal(@root, page[:Parent])
      refute(@root.value.key?(:Parent))
    end

    it "inserts the provided page at the given index" do
      page = @doc.wrap({Type: :Page})
      assert_equal(page, @root.insert_page(3, page))
      assert_equal([page], @root[:Kids])
      assert_equal(@root, page[:Parent])
      refute(@root.value.key?(:Parent))
    end

    it "inserts multiple pages correctly in an empty root node" do
      page3 = @root.insert_page(5)
      page1 = @root.insert_page(0)
      page2 = @root.insert_page(1)
      assert_equal([page1, page2, page3], @root[:Kids])
      assert_equal(3, @root[:Count])
    end

    it "inserts multiple pages correctly in a multilevel page tree" do
      define_multilevel_page_tree
      page = @root.insert_page(2)
      assert_equal([@pages[0], @pages[1], page], @kid11[:Kids])
      assert_equal(3, @kid11[:Count])
      assert_equal(6, @kid1[:Count])
      assert_equal(9, @root[:Count])

      page = @root.insert_page(4)
      assert_equal([@pages[2], page, @pages[3], @pages[4]], @kid12[:Kids])
      assert_equal(4, @kid12[:Count])
      assert_equal(7, @kid1[:Count])
      assert_equal(10, @root[:Count])

      page = @root.insert_page(8)
      assert_equal([@kid1, @pages[5], page, @kid2], @root[:Kids])
      assert_equal(11, @root[:Count])

      page = @root.insert_page(100)
      assert_equal([@kid1, @pages[5], @root[:Kids][2], @kid2, page], @root[:Kids])
      assert_equal(12, @root[:Count])
    end

    it "allows negative indices to be specified" do
      define_multilevel_page_tree
      page = @root.insert_page(-1)
      assert_equal(page, @root[:Kids].last)

      page = @root.insert_page(-4)
      assert_equal(page, @root[:Kids][2])
    end
  end

  describe "delete_page" do
    before do
      define_multilevel_page_tree
    end

    it "does nothing if the page index is not valid" do
      assert_nil(@root.delete_page(20))
      assert_nil(@root.delete_page(-20))
      assert_equal(8, @root[:Count])
    end

    it "deletes the correct page" do
      assert_equal(@pages[2], @root.delete_page(2))
      assert_equal(2, @kid12[:Count])
      assert_equal(4, @kid1[:Count])
      assert_equal(7, @root[:Count])

      assert_equal(@pages[5], @root.delete_page(4))
      assert_equal(6, @root[:Count])
    end

    it "deletes intermediate page tree nodes if they contain only one child after deletion" do
      assert_equal(@pages[0], @root.delete_page(0))
      assert_equal(4, @kid1[:Count])
      assert_equal(7, @root[:Count])
      assert_nil(@doc.object(@kid11).value)
      assert_equal(@pages[1], @kid1[:Kids][0])
    end

    it "deletes intermediate page tree nodes if they don't have any children after deletion" do
      node = @doc.add({Type: :Pages, Parent: @root})
      page = node.add_page
      @root[:Kids] << node
      @root[:Count] += 1

      assert_equal(page, @root.delete_page(-1))
      assert_nil(@doc.object(node).value)
      refute_equal(node, @root[:Kids].last)
      assert(8, @root[:Count])
    end
  end

end
