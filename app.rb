require 'gosu'
require 'awesome_print'
require 'set'
require 'pry'

require_relative 'components'
require_relative 'systems'
require_relative 'entity_manager'
require_relative 'input_cacher'

module Prefab
  include Gosu
  PLANT_COLORS = [Color::AQUA,Color::BLUE,Color::CYAN,Color::FUCHSIA,Color::GRAY,Color::GREEN,Color::RED,Color::WHITE,Color::YELLOW]
  def self.garden(entity_manager)
    brown = Color.rgba(139,69,19,255)
    6.times do |c|
      10.times do |r|
        Prefab.plot entity_manager: entity_manager,
          x: 20 + c * 25, y: 20 + r * 25, color: brown
        # Prefab.plant entity_manager: entity_manager,
        #   x: 20 + c * 25, y: 20 + r * 25, color: PLANT_COLORS.sample
      end
    end
  end

  def self.plant(entity_manager:, x:,y:,color:)
    plant = entity_manager.create
    entity_manager.add_component ColorComponent.new(color), to: plant
    entity_manager.add_component BoxedComponent.new(1, 1), to: plant
    entity_manager.add_component PositionComponent.new(x, y), to: plant
    entity_manager.add_component GrowthComponent.new(1..5, 1_000, 2), to: plant
    entity_manager.add_component TimerComponent.new(:aged, 1_000, false, AgedEvent), to: plant
    plant
  end

  def self.plot(entity_manager:, x:,y:,color:)
    plot = entity_manager.create
    entity_manager.add_component ColorComponent.new(color), to: plot
    entity_manager.add_component BoxedComponent.new(11, 11), to: plot
    entity_manager.add_component PositionComponent.new(x, y), to: plot
    entity_manager.add_component ClickableComponent.new, to: plot
    entity_manager.add_component PlantableComponent.new, to: plot
    plot
  end

end

class JoyGarden < Gosu::Window
  MAX_UPDATE_SIZE_IN_MILLIS = 500
  def initialize
    super(400,400,false)

    @entity_manager = EntityManager.new 
    @input_cacher = InputCacher.new
    build_systems

    Prefab.garden @entity_manager
    # Prefab.plant_dispensor @entity_manager

  end

  def needs_cursor?
    true
  end

  def build_systems
    @input_mapping_system = InputMappingSystem.new
    @click_system = ClickSystem.new
    @timer_system = TimerSystem.new
    @growth_system = GrowthSystem.new
    @planter_system = PlanterSystem.new
    @render_system = RenderSystem.new
  end

  def update
    self.caption = Gosu.fps

    millis = Gosu::milliseconds.to_f

    # ignore the first update
    if @last_millis
      delta = millis
      delta -= @last_millis if millis > @last_millis
      delta = MAX_UPDATE_SIZE_IN_MILLIS if delta > MAX_UPDATE_SIZE_IN_MILLIS

      @input_cacher.mouse_pos = {x: mouse_x, y: mouse_y}
      input_snapshot = @input_cacher.snapshot
      @input_mapping_system.update @entity_manager, delta, input_snapshot
      @click_system.update @entity_manager, delta, input_snapshot
      @timer_system.update @entity_manager, delta, input_snapshot
      @growth_system.update @entity_manager, delta, input_snapshot
      @planter_system.update @entity_manager, delta, input_snapshot

      @entity_manager.clear_events
    end

    @last_millis = millis
  end

  def draw
    @render_system.draw self, @entity_manager
  end

  def button_down(id)
    if id == Gosu::KbP
      ap @entity_manager.component_store
    end
    @input_cacher.button_down id
  end

  def button_up(id)
    @input_cacher.button_up id
  end

end

JoyGarden.new.show
