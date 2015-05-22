module Enumerable
  def sum
    size > 0 ? inject(0, &:+) : 0
  end
end

class GrowthSystem
  def update(entity_manager, dt, input)
    entity_manager.query_entities(:aged, :growth, 
                                  :boxed, :position) do |event, growth, boxed, pos, ent_id|
      if growth.age < growth.range.max
        growth.age += 1 
        boxed.width = growth.age * growth.size_per_age
        boxed.height = growth.age * growth.size_per_age
        # TODO change color based on age?
        entity_manager.add_component TimerComponent.new(:aged, growth.cycle, false, AgedEvent), to: ent_id
      end
    end
  end
end


class PlanterSystem
  def update(entity_manager, dt, input)
    seed_gen = nil
    entity_manager.query_entities :seed_generator do |gen, ent_id|
      # puts "hijacking scope for missing manager method... fix me"
      seed_gen = gen
    end

    entity_manager.query_entities :clicked, :plot, :position, :plantable do |clicked, plot, pos, plantable, ent_id|
      entity_manager.consume_event clicked, from: ent_id
      seed_id = seed_gen.seeds.pop
      entity_manager.find_by_id seed_id, :seed_definition do |seed_def_comp, seed_ent_id|
        seed_def = seed_def_comp.definition
        plot.plant = Prefab.plant entity_manager: entity_manager,
          x: pos.x, y: pos.y, color: seed_def[:color], mature_age: seed_def[:mature_age], 
          growth_speed: seed_def[:growth_speed], points: seed_def[:points]
        entity_manager.remove_component plantable, from: ent_id
        entity_manager.add_component HarvestableComponent.new, to: ent_id
      end

      entity_manager.remove_entity seed_id
    end
  end
end

class SeedGeneratorSystem
  SEED_HEIGHT = 14
  def update(entity_manager, dt, input)
    seeds_added = 0

    entity_manager.query_entities :seed_generator, :position do |gen, pos, ent_id|
      target_size = gen.size
      num_seeds = gen.seeds.size 

      if num_seeds < target_size
        (target_size - num_seeds).times do |i|
          seed_def = generate_seed_definition
          gen.seeds.unshift Prefab.seed(entity_manager: entity_manager,
                                  seed_definition: seed_def, 
                                  x: pos.x, y: pos.y - (SEED_HEIGHT+1)*2*i,
                                  w: SEED_HEIGHT, h: SEED_HEIGHT)
          seeds_added += 1
        end
      end
    end

    entity_manager.query_entities :seed_definition, :position do |seed_def, pos, ent_id|
      pos.y += seeds_added*(SEED_HEIGHT+1)*2
    end
  end

  private
  SEED_DEFS = [
    { color: Prefab::PLANT_COLORS[0], growth_speed: 4, mature_age: 4, points: 1 },
    { color: Prefab::PLANT_COLORS[1], growth_speed: 3, mature_age: 4, points: 2 },
    { color: Prefab::PLANT_COLORS[2], growth_speed: 2, mature_age: 4, points: 3 },
    { color: Prefab::PLANT_COLORS[3], growth_speed: 1, mature_age: 5, points: 5 },
  ]
  def generate_seed_definition
    SEED_DEFS.sample
  end
end

class TimerSystem
  def update(entity_manager, dt, input)
    entity_manager.query_entities :timer do |timer, ent_id|
      timer.ttl -= dt
      if timer.ttl <= 0
        entity_manager.emit_event timer.event.new, on: ent_id if timer.event
        if timer.repeat
          timer.ttl = timer.total
        else
          entity_manager.remove_component(timer, from: ent_id)  
        end
      end
    end
  end
end

class InputMappingSystem
  def update(entity_manager, dt, input)
    exit if input.down?(Gosu::KbEscape)
    entity_manager.query_entities :keyboard_control, :control do |keys, control, ent_id|
      control.move_left = input.down?(keys.move_left)
      control.move_right = input.down?(keys.move_right)
      control.move_up = input.down?(keys.move_up)
      control.move_down = input.down?(keys.move_down)
    end
  end
end

class ClickSystem
  def initialize
    @up = true
  end
  # TODO this should be handled at the "input" layer

  def update(entity_manager, dt, input)
    mouse_x = input.mouse_pos[:x]
    mouse_y = input.mouse_pos[:y]
    mouse_down = input.down?(Gosu::MsLeft)
    if @up && mouse_down
      @up = false
      entity_manager.query_entities :clickable, :boxed, :position do |clickable, boxed, pos, ent_id|
        if (mouse_x - pos.x).abs < boxed.width and (mouse_y - pos.y).abs < boxed.height
          entity_manager.emit_event ClickedEvent.new, on: ent_id
        end
      end
    end
    @up = true if !mouse_down
  end
end

class HarvestSystem
  def update(entity_manager, dt, input)
    plots = {}
    entity_manager.query_entities :plot, :harvestable do |plot, harvestable, ent_id|
      entity_manager.find_by_id plot.plant, :color, :growth do |color, growth, plant_ent_id|
        plots[ent_id] = {plot: plot, color: color.color, growth: growth}
      end
    end

    score = nil
    entity_manager.query_entities :score do |s, ent_id|
      score = s
    end
    entity_manager.query_entities :clicked, :plot, :harvestable do |clicked, plot, harvestable, ent_id|
      entity_manager.consume_event clicked, from: ent_id

      g = plots[ent_id][:growth]
      value = (g.range.max * g.cycle / 1000).ceil
      num_harvested = harvest_plot entity_manager, ent_id, plots
      multiplier = multiplier_for num_harvested

      points = num_harvested * value * multiplier
      puts "HARVESTED #{num_harvested} x#{value} x#{multiplier}  #{}"

      if score
        score.points += points
      end

    end
  end

  def multiplier_for(num_harvested)
    if num_harvested > 16 
      4
    elsif num_harvested > 8
      3
    elsif num_harvested > 4
      2
    else
      1
    end
  end

  def harvest_plot(entity_manager, ent_id, plots, harvested_ids=Set.new, harvest_color=nil)
    return 0 if plots[ent_id].nil?
    plot, color, growth = plots[ent_id].values_at :plot, :color, :growth
    harvest_color ||= color

    if harvest_color == color
      entity_manager.remove_entity plot.plant
      plot.plant = nil
      harvested_ids << ent_id
      entity_manager.add_component PlantableComponent.new, to: ent_id
      neighboring_harvests = plot.neighbors.map do |n|
        harvest_plot entity_manager, n, plots, harvested_ids, harvest_color unless harvested_ids.include? n
      end.compact.sum
      harvest_count = growth.age == growth.range.max ? 1 : 0

      harvest_count + neighboring_harvests
    else
      0
    end
  end
end

class RenderSystem

  def draw(target, entity_manager)
    entity_manager.query_entities :position, :color, :boxed do |pos, color, boxed, ent_id|
      c1 = c2 = c3 = c4 = color.color
      x1 = pos.x - boxed.width
      y1 = pos.y - boxed.height
      x2 = pos.x + boxed.width
      y2 = y1
      x3 = x2
      y3 = pos.y + boxed.height
      x4 = x1
      y4 = y3
      target.draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4)
    end

    entity_manager.query_entities :position, :score, :color do |pos, s, c, ent_id|
      # where to push this font instance?
      @font ||= Gosu::Font.new target, '', 32
      z = 99
      @font.draw s.points, pos.x, pos.y, z, 1, 1, c.color
    end
  end
end

