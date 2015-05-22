class GrowthComponent
  attr_accessor :range, :age, :cycle,
    :current_cycle, :type, :size_per_age

  def initialize(range, cycle, size_per_age)
    @type = :growth
    @age = range.min
    @range = range
    @cycle = cycle
    @size_per_age = size_per_age
  end
end

class ScoreComponent
  attr_accessor :points, :type
  def initialize(points)
    @points = points
    @type = :score
  end
end

class ColorComponent
  attr_accessor :color, :type
  def initialize(color)
    @color = color
    @type = :color
  end
end

class PositionComponent
  attr_accessor :x, :y, :type
  def initialize(x,y)
    @type = :position
    @x = x
    @y = y
  end
end

class BoxedComponent
  attr_accessor :width, :height, :type
  def initialize(width,height)
    @type = :boxed
    @width = width
    @height = height
  end
end

class ClickableComponent
  attr_accessor :type
  def initialize
    @type = :clickable
  end
end


class PlotComponent
  attr_accessor :plant, :type, :neighbors
  def initialize(plant = nil, neighbors = [])
    @type = :plot
    @plant = plant
    @neighbors = neighbors
  end
end

class PlantableComponent
  attr_accessor :type
  def initialize
    @type = :plantable
  end
end
class HarvestableComponent
  attr_accessor :type
  def initialize
    @type = :harvestable
  end
end

class SeedGeneratorComponent
  attr_accessor :size, :seeds, :type
  def initialize(size = 3)
    @type = :seed_generator
    @size = size
    @seeds = []
  end
end

class SeedDefinitionComponent
  attr_accessor :definition, :type
  def initialize(seed_def)
    @type = :seed_definition
    @definition = seed_def
  end
end

class PointsComponent
  attr_accessor :points, :type
  def initialize(points)
    @type = :points
    @points = points
  end
end

class TimerComponent
  attr_accessor :ttl, :repeat, :total, :event, :type, :name
  def initialize(name, ttl, repeat, event = nil)
    @type = :timer
    @name = name
    @total = ttl
    @ttl = ttl
    @repeat = repeat
    @event = event
  end
end

class ClickedEvent
  attr_accessor :type
  def initialize
    @type = :clicked
  end
end


class AgedEvent
  attr_accessor :type
  def initialize
    @type = :aged
  end
end

