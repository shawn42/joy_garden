class Clickable; end
class Plantable; end
class Harvestable; end
class Particle; end
class EmitParticlesEvent
  attr_accessor :color
  def initialize(color:)
    @color = color
  end
end
class Velocity
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end
end

class Growth
  attr_accessor :range, :age, :cycle,
    :current_cycle, :size_per_age

  def initialize(range, cycle, size_per_age)
    @age = range.min
    @range = range
    @cycle = cycle
    @size_per_age = size_per_age
  end
end

class Score
  attr_accessor :points
  def initialize(points)
    @points = points
  end
end

class JoyColor
  attr_accessor :color
  def initialize(color)
    @color = color
  end
end

class Position
  attr_accessor :x, :y
  def initialize(x,y)
    @x = x
    @y = y
  end
end

class Boxed
  attr_accessor :width, :height
  def initialize(width,height)
    @width = width
    @height = height
  end
end


class Plot
  attr_accessor :plant, :neighbors
  def initialize(plant = nil, neighbors = [])
    @plant = plant
    @neighbors = neighbors
  end
end

class SeedGenerator
  attr_accessor :size, :seeds
  def initialize(size = 3)
    @size = size
    @seeds = []
  end
end

class SeedDefinition
  attr_accessor :definition
  def initialize(seed_def)
    @definition = seed_def
  end
end

class Points
  attr_accessor :points
  def initialize(points)
    @points = points
  end
end

class Timer
  attr_accessor :ttl, :repeat, :total, :event, :name, :expires_at
  def initialize(name, ttl, repeat, event = nil)
    @name = name
    @total = ttl
    @ttl = ttl
    @repeat = repeat
    @event = event
  end
end

class ClickedEvent
  attr_reader :x, :y
  def initialize(x:,y:)
    @x = x
    @y = y
  end
end
class AgedEvent; end
class SoundEffectEvent
  attr_accessor :sound_to_play
  def initialize(sound_to_play)
    @sound_to_play = sound_to_play
  end
end

class PlantedEvent
  attr_accessor :plot_ent_id, :x, :y
  def initialize(plot_ent_id:,x:,y:)
    @plot_ent_id = plot_ent_id
    @x = x
    @y = y
  end
end

