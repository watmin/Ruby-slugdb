# frozen_string_literal: true

require 'pstore'
require_relative 'slugdb/version'

##
# Zero dependecy NoSQL, file based database
class SlugDB
  def initialize(file, thread_safe: false, ultra_safe: false)
    @pstore = PStore.new(file, thread_safe).tap { |s| s.ultra_safe = ultra_safe }
    @pstore.transaction do |db|
      db[:main] ||= {}
      db[:indexes] ||= {}
    end
  end

  def reindex!
    indexes = list_indexes
    @pstore.transaction { |db| db[:main] }.each do |pk, records|
      records.each do |sk, record|
        @pstore.transaction do |db|
          indexes.each do |name, schema|
            index_item(db, record.merge(pk: pk, sk: sk), name, schema)
          end
        end
      end
    end

    nil
  end

  def add_index(name:, pk:, sk:) # rubocop:disable Naming/MethodParameterName
    @pstore.transaction do |db|
      db[:indexes] ||= {}
      db[:indexes][name] = { pk: pk, sk: sk }
    end
    reindex!

    { name: { pk: pk, sk: sk } }
  end

  def list_indexes
    @pstore.transaction { |db| db[:indexes] }
  end

  def list_partitions
    @pstore.transaction { |db| db[:main].keys }
  end

  def get_item(pk:, sk:) # rubocop:disable Naming/MethodParameterName
    @pstore.transaction do |db|
      next if db[:main][pk].nil? || db[:main][pk][sk].nil?

      db[:main][pk][sk]
    end
  end

  def put_item(pk:, sk:, **attributes) # rubocop:disable Naming/MethodParameterName
    item = attributes.merge(pk: pk, sk: sk)
    indexes = list_indexes

    @pstore.transaction do |db|
      db[:main][pk] ||= {}
      db[:main][pk][sk] = item
      indexes.each { |name, schema| index_item(db, item, name, schema) }
    end

    item
  end

  # rubocop:disable Naming/MethodParameterName,Metrics/AbcSize
  def delete_item(pk:, sk:, **_)
    item = get_item(pk: pk, sk: sk)
    return if item.nil?

    indexes = list_indexes
    @pstore.transaction do |db|
      db[:main][pk].delete(sk)
      db[:main].delete(pk) if db[:main][pk].empty?

      indexes.each do |name, schema|
        next unless item.key?(schema[:pk]) && item.key?(schema[:sk])

        db[name][item[schema[:pk]]][item[schema[:sk]]][item[:pk]].delete(item[:sk])
        delete_if_empty?(db[name][item[schema[:pk]]][item[schema[:sk]]], item[:pk])
        delete_if_empty?(db[name][item[schema[:pk]]], item[schema[:sk]])
        delete_if_empty?(db[name], item[schema[:pk]])
      end
    end

    item
  end
  # rubocop:enable Naming/MethodParameterName,Metrics/AbcSize

  # rubocop:disable Lint/UnusedBlockArgument,Naming/MethodParameterName
  # rubocop:disable Metrics/PerceivedComplexity,Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/AbcSize,
  def query(pk:, index: :main, select: ->(sk) { true }, filter: ->(item) { true })
    if index == :main
      @pstore.transaction do |db|
        db[index]
          .fetch(pk, {})
          .map { |_, records| records }
          .select { |item| select[item[:sk]] }
          .filter { |item| filter[item] }
      end
    else
      name, schema = list_indexes.find { |name,| name == index }
      @pstore.transaction do |db|
        db[name]
          .fetch(pk, {})
          .map do |_, isk_records|
            isk_records.map do |_, pk_records|
              pk_records.map { |_, sk_records| sk_records }
            end
          end # rubocop:disable Style/MultilineBlockChain
          .flatten(2)
          .select { |item| select[item[schema[:sk]]] }
          .filter { |item| filter[item] }
      end
    end
  end
  # rubocop:enable Lint/UnusedBlockArgument,Naming/MethodParameterName
  # rubocop:enable Metrics/PerceivedComplexity,Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity,Metrics/AbcSize

  private

  def index_item(db, item, name, schema) # rubocop:disable Metrics/AbcSize
    return unless item.key?(schema[:pk]) && item.key?(schema[:sk])

    db[name] ||= {}
    db[name][item[schema[:pk]]] ||= {}
    db[name][item[schema[:pk]]][item[schema[:sk]]] ||= {}
    db[name][item[schema[:pk]]][item[schema[:sk]]][item[:pk]] ||= {}
    db[name][item[schema[:pk]]][item[schema[:sk]]][item[:pk]][item[:sk]] = item
  end

  def delete_if_empty?(hash, key)
    hash.delete(key) if hash[key].empty?
  end
end
