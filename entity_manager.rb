class EntityManager
  attr_reader :num_entities
  def initialize
    @comp_to_id = Hash.new {|h, k| h[k] = []}
    @id_to_comp = Hash.new {|h, k| h[k] = {}}
    @cache = {}
    @num_entities = 0
  end

  def find_by_id(id, *klasses)
    ent_record = @id_to_comp[id]
    components = ent_record.values_at(*klasses)
    yield build_record(id, components) unless components.any?(&:nil?) 
  end

  def each_entity(*klasses)
    if block_given?
      find(*klasses).each { |res| yield res }
    else
      find(*klasses)
    end
  end


  def add_component(component:,id:)

    @comp_to_id[component.class] << id
    ent_record = @id_to_comp[id]
    klass = component.class
    ent_record[klass] = component

    @cache.each do |comp_klasses, results|
      if comp_klasses.include?(klass)
        components = ent_record.values_at(*comp_klasses)
        results << build_record(id, components) unless components.any?(&:nil?)
      end
    end
  end

  def remove_component(klass:, id:)

    @comp_to_id[klass].delete id
    @id_to_comp[id].delete klass

    @cache.each do |comp_klasses, results|
      if comp_klasses.include?(klass)
        results.delete_if{|res| res.id == id}
      end
    end
  end

  def remove_entity(id)
    @num_entities -= 1
    ent_record = @id_to_comp.delete(id)
    klasses = ent_record.keys

    klasses.each do |klass|
      @comp_to_id[klass].delete id
    end

    @cache.each do |comp_klasses, results|
      unless (comp_klasses & klasses).empty?
        results.delete_if{|res| res.id == id}
      end
    end
  end

  def add_entity(*components)
    id = generate_id
    components.each do |comp|
      add_component component: comp, id: id
    end
    id
  end

  # bakes in the assumption that we are an ECS and that rows are joined by id
  def find(*klasses)
    cache_hit = @cache[klasses]
    return cache_hit if cache_hit

    id_collection = @comp_to_id.values_at *klasses
    intersecting_ids = id_collection.inject &:&
    result = intersecting_ids.map do |id|
      build_record id, @id_to_comp[id].values_at(*klasses)
    end
    @cache[klasses] = result
    result
  end

  private 
  def generate_id
    @num_entities += 1
    @ent_counter ||= 0
    @ent_counter += 1
  end

  def build_record(id, components)
    EntityQueryResult.new(id, components)
  end

  EntityQueryResult = Struct.new(:id, :components) do
    def get(klass)
      components.find{|c|c.class == klass}
    end
  end

end


if $0 == __FILE__
  class Player; end
  class Foo; end
  class Bar; end

  class Position
    def initialize(x:,y:)
    end
  end

  entity_manager = EntityManager.new

  enemy_id = entity_manager.add_entity Position.new(x:4, y:5)
  player_id = entity_manager.add_entity Position.new(x:2, y:3), Player.new


  10_000.times do |i|
    entity_manager.add_entity Position.new(x:4,y:5), Foo.new, Bar.new
  end

  # require 'pry'
  # binding.pry

  require 'benchmark'
  n = 100_000
  Benchmark.bm do |x|
    x.report do
      n.times do |i|
        if i % 100 == 0 
          entity_manager.add_component component: Player.new, id: player_id+i
        end

        if i % 100 == 1 
          entity_manager.remove_component klass: Player, id: player_id+i-1
        end

        if i == n-1
          entity_manager.remove_entity(player_id)
        end
        entity_manager.find(Position, Player)
      end
    end
  end
end

















