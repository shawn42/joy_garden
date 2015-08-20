module Prefab
  include Gosu
  PLANT_COLORS = [Color::AQUA,Color::BLUE,Color::CYAN,Color::FUCHSIA,Color::GRAY,Color::GREEN,Color::RED,Color::WHITE,Color::YELLOW]
  def self.garden(entity_manager:, x:, y:)
    brown = Color.rgba(139,69,19,255)
    plots = {}
    6.times do |c|
      plots[c] = {}
      10.times do |r|
        plots[c][r] = Prefab.plot(entity_manager: entity_manager,
          x: x+ 20 + c * 25, y: y + 20 + r * 25, color: brown)
      end
    end

    6.times do |c|
      10.times do |r|
        plot_id = plots[c][r]
        neighbors = neighbors_for(c,r,plots)
        entity_manager.add_component(component: PlotComponent.new(nil, neighbors), id: plot_id)
      end
    end
  end

  def self.neighbors_for(c,r,plots)
    neighbors = []
    neighbors << plots[c-1][r] if c > 0
    neighbors << plots[c][r-1] if r > 0
    neighbors << plots[c+1][r] if c < plots.size-1
    neighbors << plots[c][r+1] if r < plots[0].size-1

    neighbors
  end

  def self.score(entity_manager:, x:, y:, color:, points:0)
    entity_manager.add_entity PositionComponent.new(x, y),
     ColorComponent.new(color), ScoreComponent.new(points)
  end

  def self.plant(entity_manager:, x:,y:,color:, mature_age:, growth_speed:, points:)
    entity_manager.add_entity ColorComponent.new(color),
      BoxedComponent.new(1, 1),
      PositionComponent.new(x, y),
      GrowthComponent.new(1..mature_age, 5_000.0/growth_speed, 2),
      PointsComponent.new(points),
      TimerComponent.new(:aged, 1_000, false, AgedEvent)
  end

  def self.plot(entity_manager:, x:,y:,color:)
    entity_manager.add_entity ColorComponent.new(color),
      BoxedComponent.new(11, 11),
      PositionComponent.new(x, y),
      ClickableComponent.new,
      PlantableComponent.new
  end

  def self.seed_generator(entity_manager:, x:,y:)
    entity_manager.add_entity BoxedComponent.new(11, 11),
      PositionComponent.new(x, y),
      SeedGeneratorComponent.new
  end

  def self.seed(entity_manager:, seed_definition:, x:, y:, w:, h:)
    entity_manager.add_entity ColorComponent.new(seed_definition[:color]),
      BoxedComponent.new(w, h),
      PositionComponent.new(x, y),
      SeedDefinitionComponent.new(seed_definition)
  end

end

