# class Vec2
#   attr_reader :x, :y
#   def initialize(x,y)
#     @x = x
#     @y = y
#   end
# end
#
module Enumerable
  def sum
    size > 0 ? inject(0, &:+) : 0
  end
end

class ParticlesEmitterSystem
  def update(entity_manager, dt, input)
    entity_manager.each_entity(EmitParticlesEvent, Position, JoyColor) do |rec|
      ent_id = rec.id
      evt, pos, color = rec.components

      speed = (-10..10).to_a
      20.times do
        entity_manager.add_entity pos.dup, Particle.new, 
          JoyColor.new(evt.color), 
          Velocity.new(speed.sample, speed.sample), Boxed.new(rand(3),rand(3))
      end

      entity_manager.remove_component klass: EmitParticlesEvent, id: ent_id
    end
  end
end

class ParticlesSystem
  def update(entity_manager, dt, input)
    entity_manager.each_entity(Velocity, Particle, Position, JoyColor) do |rec|
      # TODO update color as well
      ent_id = rec.id
      vel, particle, pos, color = rec.components

      scalar = dt/100.0
      pos.x += vel.x * scalar
      pos.y += vel.y * scalar

      c = color.color
      color.color = Gosu::Color.rgba(c.red,c.green,c.blue,c.alpha-10*scalar)
    end
  end
end

class GrowthSystem
  def update(entity_manager, dt, input)
    entity_manager.each_entity(AgedEvent, Growth, Boxed, Position) do |rec|
      ent_id = rec.id
      event, growth, boxed, pos = rec.components

      entity_manager.remove_component klass: event.class, id: ent_id

      if growth.age < growth.range.max
        growth.age += 1 
        boxed.width = growth.age * growth.size_per_age
        boxed.height = growth.age * growth.size_per_age
        # TODO change color based on age?
        entity_manager.add_component component: Timer.new(:aged, growth.cycle, false, AgedEvent), id: ent_id
      end
    end
  end
end


class PlanterSystem
  def update(entity_manager, dt, input)
    seed_gen = entity_manager.find(SeedGenerator).first[:components].first

    entity_manager.each_entity ClickedEvent, Plot, Position, Plantable do |rec|
      clicked, plot, pos, plantable = rec.components
      ent_id = rec.id
      seed_id = seed_gen.seeds.pop

      entity_manager.remove_component klass: clicked.class, id: ent_id
      entity_manager.add_component component: PlantedEvent.new(
        plot_ent_id: ent_id, 
        x: pos.x, 
        y: pos.y
      ), id: seed_id
    end
  end
end

class SeedPlanterSystem
  def update(entity_manager, dt, input)
    entity_manager.each_entity PlantedEvent, SeedDefinition do |rec|
      planted, seed_def_comp = rec.components
      seed_ent_id = rec.id
      seed_def = seed_def_comp.definition

      # TODO: What if a "plot" entity just had a PlantReference component?
      # Wouldn't have to lookup and modify the Plot.plant field.
      entity_manager.find_by_id planted.plot_ent_id, Plot, Plantable do |plot_rec|
        plot = plot_rec.components[0]
        plot.plant = Prefab.plant(
          entity_manager: entity_manager,
          x:              planted.x, 
          y:              planted.y, 
          color:          seed_def[:color], 
          mature_age:     seed_def[:mature_age], 
          growth_speed:   seed_def[:growth_speed], 
          points:         seed_def[:points_component])

        entity_manager.add_component component: SoundEffectEvent.new('plant.ogg'), id: planted.plot_ent_id
        entity_manager.remove_component klass: Plantable, id: planted.plot_ent_id
        entity_manager.add_component component: Harvestable.new, id: planted.plot_ent_id
      end

      entity_manager.remove_component klass: planted.class, id: seed_ent_id
      entity_manager.remove_entity seed_ent_id
    end
  end
end

class SeedGeneratorSystem
  SEED_HEIGHT = 14
  def update(entity_manager, dt, input)
    seeds_added = 0

    entity_manager.each_entity SeedGenerator, Position do |rec|
      gen, pos = rec.components
      ent_id = rec.id
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

    entity_manager.each_entity SeedDefinition, Position do |rec|
      seed_def, pos = rec.components
      ent_id = rec.id
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
  def update(entity_manager, current_time_ms, input)
    entity_manager.each_entity Timer do |rec|
      timer = rec.get(Timer)
      ent_id = rec.id

      if timer.expires_at
        if timer.expires_at < current_time_ms
          entity_manager.add_component component: timer.event.new, id: ent_id if timer.event
          if timer.repeat
            timer.expires_at = current_time_ms + timer.total
          else
            entity_manager.remove_component(klass: timer.class, id: ent_id)  
          end
        end
      else
        timer.expires_at = current_time_ms + timer.total
      end

    end
  end
end

class InputMappingSystem
  def update(entity_manager, dt, input)
    exit if input.down?(Gosu::KbEscape)
    entity_manager.each_entity :keyboard_control, :control do |rec|
      keys, control = rec.components
      ent_id = rec.id
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
      entity_manager.each_entity Clickable, Boxed, Position do |rec|
        clickable, boxed, pos = rec.components
        ent_id = rec.id
        if (mouse_x - pos.x).abs < boxed.width and (mouse_y - pos.y).abs < boxed.height
          entity_manager.add_component component: ClickedEvent.new(x: mouse_x, y: mouse_y), id: ent_id
        end
      end
    end
    @up = true if !mouse_down
  end
end

class HarvestSystem
  def update(entity_manager, dt, input)
    plots = {}
    entity_manager.each_entity Plot, Harvestable do |rec|
      plot, harvestable = rec.components
      ent_id = rec.id
      entity_manager.find_by_id plot.plant, JoyColor, Growth do |rec|
        color, growth = rec.components
        plant_ent_id = rec.id
        plots[ent_id] = {plot: plot, color: color.color, growth: growth}
      end
    end

    score = nil
    entity_manager.each_entity Score do |rec|
      s = rec.get(Score)
      ent_id = rec.id
      score = s
    end
    entity_manager.each_entity ClickedEvent, Plot, Harvestable do |rec|
      clicked, plot, harvestable = rec.components
      ent_id = rec.id
      entity_manager.remove_component klass: clicked.class, id: ent_id
      entity_manager.add_component component: SoundEffectEvent.new('harvest2.ogg'), id: ent_id

      g = plots[ent_id][:growth]
      value = (g.range.max * g.cycle / 1000).ceil
      num_harvested = harvest_plot entity_manager, ent_id, plots
      multiplier = multiplier_for num_harvested

      points = num_harvested * value * multiplier
      puts "HARVESTED #{num_harvested} x#{value} x#{multiplier} #{points}"

      entity_manager.add_component component: SoundEffectEvent.new('bonus.ogg'), id: ent_id if multiplier > 2
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
      entity_manager.add_component component: EmitParticlesEvent.new(color: color), id: ent_id 
      entity_manager.remove_entity plot.plant
      plot.plant = nil
      harvested_ids << ent_id
      entity_manager.add_component component: Plantable.new, id: ent_id
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

class SoundSystem
  def update(entity_manager, dt, input)
    entity_manager.each_entity SoundEffectEvent do |rec|
      effect = rec.components[0]
      ent_id = rec.id
      entity_manager.remove_component klass: effect.class, id: ent_id
      Gosu::Sample.new(effect.sound_to_play).play
    end
  end
end

class RenderSystem

  def draw(target, entity_manager)
    entity_manager.each_entity Position, JoyColor, Boxed do |rec|
      pos, color, boxed = rec.components
      ent_id = rec.id
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

    entity_manager.each_entity Position, Score, JoyColor do |rec|
      pos, s, c = rec.components
      ent_id = rec.id
      @font ||= Gosu::Font.new target, '', 32
      z = 99
      @font.draw s.points, pos.x, pos.y, z, 1, 1, c.color
    end
  end
end

