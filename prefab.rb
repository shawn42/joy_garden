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
    score = entity_manager.create
    entity_manager.add_component component: PositionComponent.new(x, y), id: score
    entity_manager.add_component component: ColorComponent.new(color), id: score
    entity_manager.add_component component: ScoreComponent.new(points), id: score
    score
  end

  def self.plant(entity_manager:, x:,y:,color:, mature_age:, growth_speed:, points:)
    plant = entity_manager.create
    entity_manager.add_component component: ColorComponent.new(color), id: plant
    entity_manager.add_component component: BoxedComponent.new(1, 1), id: plant
    entity_manager.add_component component: PositionComponent.new(x, y), id: plant
    entity_manager.add_component component: GrowthComponent.new(1..mature_age, 5_000.0/growth_speed, 2), id: plant
    entity_manager.add_component component: PointsComponent.new(points), id: plant
    entity_manager.add_component component: TimerComponent.new(:aged, 1_000, false, AgedEvent), id: plant
    plant
  end

  def self.plot(entity_manager:, x:,y:,color:)
    plot = entity_manager.create
    entity_manager.add_component component: ColorComponent.new(color), id: plot
    entity_manager.add_component component: BoxedComponent.new(11, 11), id: plot
    entity_manager.add_component component: PositionComponent.new(x, y), id: plot
    entity_manager.add_component component: ClickableComponent.new, id: plot
    entity_manager.add_component component: PlantableComponent.new, id: plot
    plot
  end

  def self.seed_generator(entity_manager:, x:,y:)
    plot = entity_manager.create
    entity_manager.add_component component: BoxedComponent.new(11, 11), id: plot
    entity_manager.add_component component: PositionComponent.new(x, y), id: plot
    entity_manager.add_component component: SeedGeneratorComponent.new, id: plot
    plot
  end

  def self.seed(entity_manager:, seed_definition:, x:, y:, w:, h:)
    seed = entity_manager.create
    entity_manager.add_component component: ColorComponent.new(seed_definition[:color]), id: seed
    entity_manager.add_component component: BoxedComponent.new(w, h), id: seed
    entity_manager.add_component component: PositionComponent.new(x, y), id: seed
    entity_manager.add_component component: SeedDefinitionComponent.new(seed_definition), id: seed
    seed
  end

end

