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
  attr_accessor :clicked, :type
  def initialize
    @type = :clickable
    @clicked = false
  end
end

class PlantableComponent
  attr_accessor :plant, :type
  def initialize(plant = nil)
    @type = :plantable
    @plant = plant
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

class AgedEvent
  attr_accessor :type
  def initialize
    @type = :aged
  end
end

