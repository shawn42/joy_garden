require 'combinatorics/cartesian_product'

class EntityManager
  attr_reader :component_store

  def create
    # TODO will probably need an Entity class for convenience
    @count += 1
    "E:#{@count}"
  end

  def initialize
    @count = 0
    @component_store = Hash.new{|h, k| h[k] = Hash.new{|hh, kk| hh[kk] = Set.new}}
    @events = {}
  end

  def emit_event(event, opts={})
    target_entity = opts[:on]
    @events[target_entity] ||= []
    @events[target_entity] << event

    add_component(event, to: target_entity)
  end

  def clear_events
    @events.each do |entity, events|
      events.each do |event|
        remove_component(event, from: entity)
      end
    end
    @events.clear
  end

  def query_entities(*_queries, &block)
    queries = _queries.dup
    query = queries.shift
    query = query.is_a?(Symbol) ? {type: query} : query
    ent_ids = @component_store[query[:type]].keys
    ent_ids.each do |ent_id|
      comps = find_components query, ent_id
      comps.flat_map do |comp|
        _query_entities(queries, ent_id, [comp], &block)
      end
    end
  end

  def _query_entities(_queries, ent_id, accum, &block)
    if _queries.size == 0
      yield *accum, ent_id
    else
      queries = _queries.dup
      query = queries.shift
      query = query.is_a?(Symbol) ? {type: query} : query

      comps = find_components query, ent_id

      comps.flat_map do |comp|
        _query_entities(queries.dup, ent_id, accum + [comp], &block)
      end
    end
  end

  def find_components(query, ent_id)
    ent_comps = @component_store[query[:type]][ent_id]
    return [] if ent_comps.nil?
    res = []
    ent_comps.each do |comp|
      res << comp if query_matches(query, comp)
    end
    res
  end

  def query_matches(query, comp)
    match = true
    query.each do |k,v|
      if comp.send(k) != v
        match = false
        break
      end
    end
    match
  end

  def entities_with_all_components(*components, &block)
    raise "No block give" unless block_given?

    first_component_ids = @component_store[components.first].keys
    ent_ids = components.inject(first_component_ids) do |comp_ids, comp|
      comp_ids &= @component_store[comp].keys
    end

    ent_ids.each do |ent_id|
      yield *components.map{|comp| @component_store[comp][ent_id]}, ent_id
    end
  end

  def add_component(component, opts={})
    target_entity = opts[:to]
    @component_store[component.type][target_entity] << component
    self
  end

  def remove_component(component, opts={})
    target_entity = opts[:from]
    @component_store[component.type][target_entity].delete(component) if @component_store[component.type][target_entity]
    self
  end

  def remove_entity(entity)
    @component_store.each do |comp_type, entity_hash|
      entity_hash.delete entity
    end
    self
  end
end
