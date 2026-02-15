extends RefCounted
class_name WeatherSystem

## Weather effects system — zone-to-weather mapping and particle creation.

enum WeatherType { CLEAR, RAIN, SNOW, SANDSTORM, LEAVES }

# Zone name -> {weather: WeatherType, chance: float}
const ZONE_WEATHER := {
	"Water Coast":  {weather = WeatherType.RAIN, chance = 0.6},
	"Sky Peaks":    {weather = WeatherType.SNOW, chance = 0.5},
	"Earth Caves":  {weather = WeatherType.SANDSTORM, chance = 0.4},
	"Forest Grove": {weather = WeatherType.LEAVES, chance = 0.7},
}

static func get_zone_weather(zone_name: String) -> WeatherType:
	if not ZONE_WEATHER.has(zone_name):
		return WeatherType.CLEAR
	var entry: Dictionary = ZONE_WEATHER[zone_name]
	if randf() <= entry.chance:
		return entry.weather
	return WeatherType.CLEAR

static func get_weather_name(weather: WeatherType) -> String:
	match weather:
		WeatherType.RAIN:      return "Rain"
		WeatherType.SNOW:      return "Snow"
		WeatherType.SANDSTORM: return "Sandstorm"
		WeatherType.LEAVES:    return "Leaves"
	return "Clear"

static func create_weather_particles(parent: Node2D, weather: WeatherType) -> GPUParticles2D:
	if weather == WeatherType.CLEAR:
		return null

	var particles := GPUParticles2D.new()
	particles.amount = 60
	particles.lifetime = 3.0
	particles.z_index = 10

	var mat := ParticleProcessMaterial.new()
	particles.process_material = mat

	# Position at top of viewport, spread across width
	particles.position = Vector2(0, -200)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(350, 10, 0)

	match weather:
		WeatherType.RAIN:
			particles.amount = 80
			particles.lifetime = 1.5
			mat.direction = Vector3(0.1, 1.0, 0)
			mat.initial_velocity_min = 200.0
			mat.initial_velocity_max = 300.0
			mat.scale_min = 0.5
			mat.scale_max = 1.5
			mat.color = Color(0.5, 0.6, 0.9, 0.6)

		WeatherType.SNOW:
			particles.amount = 40
			particles.lifetime = 4.0
			mat.direction = Vector3(0.2, 1.0, 0)
			mat.initial_velocity_min = 30.0
			mat.initial_velocity_max = 60.0
			mat.gravity = Vector3(0, 20, 0)
			mat.scale_min = 1.0
			mat.scale_max = 3.0
			mat.color = Color(1.0, 1.0, 1.0, 0.7)

		WeatherType.SANDSTORM:
			particles.amount = 50
			particles.lifetime = 2.0
			mat.direction = Vector3(1.0, 0.3, 0)
			mat.initial_velocity_min = 150.0
			mat.initial_velocity_max = 250.0
			mat.gravity = Vector3(0, 30, 0)
			mat.scale_min = 0.5
			mat.scale_max = 2.0
			mat.color = Color(0.8, 0.7, 0.4, 0.5)

		WeatherType.LEAVES:
			particles.amount = 25
			particles.lifetime = 5.0
			mat.direction = Vector3(0.3, 1.0, 0)
			mat.initial_velocity_min = 20.0
			mat.initial_velocity_max = 50.0
			mat.gravity = Vector3(0, 15, 0)
			mat.angular_velocity_min = -90.0
			mat.angular_velocity_max = 90.0
			mat.scale_min = 1.0
			mat.scale_max = 3.0
			mat.color = Color(0.4, 0.6, 0.2, 0.6)

	parent.add_child(particles)
	return particles
