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

    entity_manager.query_entities :clickable, :position, :plantable do |clickable, pos, plantable, ent_id|
      if clickable.clicked && plantable.plant.nil?
        seed_id = seed_gen.seeds.pop
        entity_manager.find_by_id seed_id, :seed_definition do |seed_def_comp, ent_id|
          seed_def = seed_def_comp.definition
          plantable.plant = Prefab.plant entity_manager: entity_manager,
            x: pos.x, y: pos.y, color: seed_def[:color], mature_age: seed_def[:mature_age], 
            growth_speed: seed_def[:growth_speed], points: seed_def[:points]
        end

        entity_manager.remove_entity seed_id
      end
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
  def update(entity_manager, dt, input)
    mouse_x = input.mouse_pos[:x]
    mouse_y = input.mouse_pos[:y]
    if input.down? Gosu::MsLeft
      entity_manager.query_entities :clickable, :boxed, :position do |clickable, boxed, pos, ent_id|
        if (mouse_x - pos.x).abs < boxed.width and (mouse_y - pos.y).abs < boxed.height
          clickable.clicked = true
        end
      end
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
  end
end

