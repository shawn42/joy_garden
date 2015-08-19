require 'gosu'
require 'awesome_print'
require 'pry'

require_relative 'components'
require_relative 'prefab'
require_relative 'systems'
require_relative 'entity_manager'
require_relative 'input_cacher'

class JoyGarden < Gosu::Window
  MAX_UPDATE_SIZE_IN_MILLIS = 500
  def initialize
    super(400,400,false)

    @entity_manager = EntityManager.new 
    @input_cacher = InputCacher.new
    build_systems

    Prefab.garden entity_manager: @entity_manager, x: 5, y: 50
    Prefab.seed_generator entity_manager: @entity_manager, x: 200, y: 100
    Prefab.score entity_manager: @entity_manager, color: Gosu::Color::WHITE, x: 5, y: 10
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
    @harvest_system = HarvestSystem.new
    @sound_system = SoundSystem.new
    @seed_generator_system = SeedGeneratorSystem.new
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
      @harvest_system.update @entity_manager, delta, input_snapshot
      @sound_system.update @entity_manager, delta, input_snapshot
      @seed_generator_system.update @entity_manager, delta, input_snapshot

      # @entity_manager.clear_events
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
