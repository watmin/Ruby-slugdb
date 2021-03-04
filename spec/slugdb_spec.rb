# frozen_string_literal: true

require 'pry'
require 'set'
require 'tempfile'

RSpec.describe SlugDB do
  before(:each) do
    @db_file = Tempfile.new
    @db = SlugDB.new(@db_file.path)
  end

  after(:each) do
    @db_file.unlink
  end

  describe '#reindex!' do
    context 'when adding an index with existing records' do
      it 'then indexes the existing records' do
        @db.put_item(pk: 'test1#', sk: 'metadata#')
        @db.add_index(name: :ski, pk: :sk, sk: :pk)
        result = @db.query(index: :ski, pk: 'metadata#')

        aggregate_failures do
          expect(result.size).to eq 1
          expect(result.first[:pk]).to eq 'test1#'
          expect(result.first[:sk]).to eq 'metadata#'
        end
      end
    end
  end

  describe '#add_index' do
    context 'when adding an index' do
      it 'then adds the index' do
        @db.add_index(name: :ski, pk: :sk, sk: :pk)
        @db.add_index(name: :gsi1, pk: :gsi1_pk, sk: :gsi1_sk)
        result = @db.list_indexes

        aggregate_failures do
          expect(result.size).to eq 2
          expect(result[:ski][:pk]).to eq :sk
          expect(result[:ski][:sk]).to eq :pk
          expect(result[:gsi1][:pk]).to eq :gsi1_pk
          expect(result[:gsi1][:sk]).to eq :gsi1_sk
        end
      end
    end
  end

  describe '#list_indexes' do
    context 'when listing indexes' do
      it 'then returns a hash of index names and schemas' do
        @db.add_index(name: :ski, pk: :sk, sk: :pk)
        result = @db.list_indexes

        aggregate_failures do
          expect(result.size).to eq 1
          expect(result[:ski][:pk]).to eq :sk
          expect(result[:ski][:sk]).to eq :pk
        end
      end
    end
  end

  describe '#list_partitions' do
    context 'when listing partitions' do
      it 'then returns an array partition keys' do
        @db.put_item(pk: 'partition1#', sk: 'metadata#')
        @db.put_item(pk: 'partition2#', sk: 'metadata#')
        result = @db.list_partitions

        aggregate_failures do
          expect(result.size).to eq 2
          expect(result.to_set).to eq %w[partition1# partition2#].to_set
        end
      end
    end
  end

  describe '#get_item' do
    context 'when fetching an item by pk and sk' do
      it 'then returns the hash of the item' do
        @db.put_item(
          pk: 'partition1#',
          sk: 'metadata#',
          not: :nested,
          nested: {
            is_nested: true,
            also_arrays: [:yup],
            another_hash: { sure: 8 }
          }
        )
        result = @db.get_item(pk: 'partition1#', sk: 'metadata#')

        aggregate_failures do
          expect(result[:pk]).to eq 'partition1#'
          expect(result[:sk]).to eq 'metadata#'
          expect(result[:not]).to eq :nested
          expect(result[:nested]).to be_a Hash
          expect(result[:nested][:is_nested]).to eq true
          expect(result[:nested][:also_arrays]).to be_a Array
          expect(result[:nested][:also_arrays].size).to eq 1
          expect(result[:nested][:also_arrays].first).to eq :yup
          expect(result[:nested][:another_hash]).to be_a Hash
          expect(result[:nested][:another_hash].size).to eq 1
          expect(result[:nested][:another_hash][:sure]).to eq 8
        end
      end
    end
  end

  describe '#put_item' do
    context 'when putting an item' do
      it 'then puts the item' do
        @db.put_item(pk: 'unit#', sk: 'test#')
        result = @db.get_item(pk: 'unit#', sk: 'test#')

        aggregate_failures do
          expect(result[:pk]).to eq 'unit#'
          expect(result[:sk]).to eq 'test#'
        end
      end
    end
  end

  describe '#delete_item' do
    context 'when deleting an item' do
      it 'then deletes the item' do
        @db.add_index(name: :ski, pk: :sk, sk: :pk)
        @db.put_item(pk: 'unit#', sk: 'test#')
        @db.delete_item(pk: 'unit#', sk: 'test#')
        get_result = @db.get_item(pk: 'unit#', sk: 'test#')
        query_result = @db.query(pk: 'unit#', index: :ski)

        aggregate_failures do
          expect(get_result).to eq nil
          expect(query_result.empty?).to eq true
        end
      end
    end
  end

  describe '#query' do
    context 'when querying the main table' do
      it 'then returns all items in the partition' do
        @db.put_item(pk: 'partition1#', sk: 'metadata#')
        @db.put_item(pk: 'partition1#', sk: 'some_class#some_instance#')
        @db.put_item(pk: 'partition1#', sk: 'another_class#another_instance#')
        @db.put_item(pk: 'partition2#', sk: 'metadata#')
        result = @db.query(pk: 'partition1#')

        aggregate_failures do
          expect(result.size).to eq 3
          expect(result.find { |n| n[:sk] == 'metadata#' }).not_to eq nil
          expect(result.find { |n| n[:sk] == 'some_class#some_instance#' }).not_to eq nil
          expect(result.find { |n| n[:sk] == 'another_class#another_instance#' }).not_to eq nil
        end
      end
    end

    context 'when querying an index' do
      it 'then returns all items in the index partition' do
        @db.add_index(name: :ski, pk: :sk, sk: :pk)
        @db.put_item(pk: 'partition1#', sk: 'metadata#')
        @db.put_item(pk: 'partition1#', sk: 'some_class#some_instance#')
        @db.put_item(pk: 'partition1#', sk: 'another_class#another_instance#')
        @db.put_item(pk: 'partition2#', sk: 'metadata#')
        result = @db.query(pk: 'metadata#', index: :ski)

        aggregate_failures do
          expect(result.size).to eq 2
          expect(result.find { |n| n[:pk] == 'partition1#' }).not_to eq nil
          expect(result.find { |n| n[:pk] == 'partition2#' }).not_to eq nil
        end
      end
    end

    context 'when selecting on sort key' do
      it 'then returns all matching items for the sort key' do
        @db.put_item(pk: 'partition1#', sk: 'metadata#')
        @db.put_item(pk: 'partition1#', sk: 'some_class#some_instance#')
        @db.put_item(pk: 'partition1#', sk: 'another_class#another_instance#')
        result = @db.query(pk: 'partition1#', select: ->(sk) { sk =~ /class/ })

        aggregate_failures do
          expect(result.size).to eq 2
          expect(result.find { |n| n[:sk] == 'some_class#some_instance#' }).not_to eq nil
          expect(result.find { |n| n[:sk] == 'another_class#another_instance#' }).not_to eq nil
        end
      end
    end

    context 'when filtering items' do
      it 'then returns all matching items for the filter' do
        @db.put_item(pk: 'partition1#', sk: 'metadata#')
        @db.put_item(pk: 'partition1#', sk: 'some_class#some_instance#')
        @db.put_item(pk: 'partition1#', sk: 'another_class#another_instance#')
        @db.put_item(pk: 'partition1#', sk: 'thing#2', find_me: true)
        result = @db.query(pk: 'partition1#', filter: ->(item) { item.key?(:find_me) })

        aggregate_failures do
          expect(result.size).to eq 1
          expect(result.find { |n| n[:sk] == 'thing#2' }).not_to eq nil
        end
      end
    end
  end
end
