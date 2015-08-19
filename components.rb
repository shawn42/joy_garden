class GrowthComponent
  attr_accessor :range, :age, :cycle,
    :current_cycle, :size_per_age

  def initialize(range, cycle, size_per_age)
    @age = range.min
    @range = range
    @cycle = cycle
    @size_per_age = size_per_age
  end
end

class ScoreComponent
  attr_accessor :points
  def initialize(points)
    @points = points
  end
end

class ColorComponent
  attr_accessor :color
  def initialize(color)
    @color = color
  end
end

class PositionComponent
  attr_accessor :x, :y
  def initialize(x,y)
    @x = x
    @y = y
  end
end

class BoxedComponent
  attr_accessor :width, :height
  def initialize(width,height)
    @width = width
    @height = height
  end
end


class PlotComponent
  attr_accessor :plant, :neighbors
  def initialize(plant = nil, neighbors = [])
    @plant = plant
    @neighbors = neighbors
  end
end

class ClickableComponent; end
class PlantableComponent; end
class HarvestableComponent; end

class SeedGeneratorComponent
  attr_accessor :size, :seeds
  def initialize(size = 3)
    @size = size
    @seeds = []
  end
end

class SeedDefinitionComponent
  attr_accessor :definition
  def initialize(seed_def)
    @definition = seed_def
  end
end

class PointsComponent
  attr_accessor :points
  def initialize(points)
    @points = points
  end
end

class TimerComponent
  attr_accessor :ttl, :repeat, :total, :event, :name
  def initialize(name, ttl, repeat, event = nil)
    @name = name
    @total = ttl
    @ttl = ttl
    @repeat = repeat
    @event = event
  end
end

class ClickedEvent; end
class AgedEvent; end
class SoundEffectEvent
  attr_accessor :sound_to_play
  def initialize(sound_to_play)
    @sound_to_play = sound_to_play
  end
end

