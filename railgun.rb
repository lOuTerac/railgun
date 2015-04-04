require 'matrix'
require 'pry'

G           = 9.806           # 重力加速度
MAX_ERROR   = 1.0             # 着弹误差1米
TARGET_SIZE = 20.0            # 目标半径
SONIC       = 340.3           # 马赫公制速度转换
RAILGUN_V   = 1e4 * SONIC # 电磁炮最大初速

def zero
  Vector[0.0, 0.0, 0.0].dup
end

def rand_vector
  Vector[rand, rand, rand].normalize.dup
end

class Particle
  attr_accessor :r, :v, :history

  def initialize(*_args)
    @t       = 0.0
    @history = []
  end

  def acceleration
    forcefield(@r, @v, @t)
  end

  def nextstep(delta_t)
    # 四阶Runge-Kutta法
    # 单步计算，返回下一步各状态
    a_1 = forcefield(@r, @v, @t)
    v_2 = @v + a_1 * delta_t * 0.5
    a_2 = forcefield(@r + @v * delta_t * 0.5, v_2, @t + 0.5 * delta_t)
    v_3 = @v + a_2 * delta_t * 0.5
    a_3 = forcefield(@r + v_2 * delta_t * 0.5, v_3, @t + 0.5 * delta_t)
    v_4 = @v + a_3 * delta_t
    a_4 = forcefield(@r + v_3 * delta_t, v_4, @t + delta_t)
    v = @v + (a_1 + a_2 * 2 + a_3 * 2 + a_4) * (delta_t / 6.0)
    r = @r + (v + v_2 * 2 + v_3 * 2 + v_4) * (delta_t / 6.0)
    t = @t + delta_t
    return r, v, t
  end

  def nextstep!(delta_t)
    # 保存并返回下一步状态
    @r, @v, @t = nextstep(delta_t)
    @history << [@r, @v, @t]
    return @r, @v, @t
  end
end

class Target < Particle
  MAX_ACCELERATION = 7.0 * G

  def collision_radius
    # 碰撞半径
    20.0
  end

  def initialize(r = zero, v = zero, a = MAX_ACCELERATION)
    @r, @v, @a_magnitude = r, v, a
    vv = @v.max < 1e-3 ? rand_vector : @v
    @a = vv.cross_product(rand_vector).cross_product(vv).normalize * a
    super
  end

  def forcefield(_r, v, t)
    return zero if @a_magnitude < 1e-5 || t < 1.0
    # 设检测到导弹发射到作出规避动作有1秒延时
    vv = v.max < 1e-5 ? rand_vector : v
    vv.cross_product(@a).cross_product(vv).normalize * @a_magnitude
  end
end

class Projectile < Particle
  def initialize(target, speed = RAILGUN_V)
    @target, @speed = target, speed
    @r = zero
    aim_target
    super
    set_timestep
  end

  def fire
    while !maxtime? && !hit?
      nextstep!(@timestep)
      @target.nextstep!(@timestep)
    end
    hit? ? :hit : :miss
  end

  private

  def hit?
    (@target.r - @r).magnitude < @target.collision_radius
  end

  def maxtime?
    @t >= @max_time
  end

  def forcefield(*_args)
    # 弹丸出膛后为匀速直线运动
    zero
  end

  def aim_target
    # 简单地按目标直线运动提前量瞄准
    v   = @target.v
    v_q = v.r * v.r
    s   = @target.r
    s_q = s.r * s.r
    dot = v.dot s
    k   = @speed * @speed
    # 此为解析解
    t = (2 * s_q) / (Math.sqrt(4 * dot * dot - 4 * s_q * (v_q - k)) - 2 * dot)
    @v = v + s / t
    @max_time = t * 1.01
  end

  def set_timestep
    # 根据给定误差，步长自适应
    # 初始时间步长 0.1 毫秒
    @timestep = 1e-4
    halfstep = @timestep / 2
    r1, v1, t1 = nextstep(@timestep)
    r2, v2, t2 = nextstep(halfstep)

    if (r2 - r1).magnitude <= MAX_ERROR
      while (r2 - r1).magnitude  <= MAX_ERROR
        # 增大步长至所需精度
        @timestep = 2 * @timestep
        r2, _v2, _t2 = r1, v1, t1
        r1, v1, t1 = nextstep(@timestep)
      end
      @timestep /= 2
    else
      while (r2 - r1).magnitude > MAX_ERROR
        # 减小步长至所需精度
        @timestep /= 2
        halfstep  = @timestep / 2
        r1, _v1, _t1 = r2, v2, t2
        r2, v2, t2 = nextstep(halfstep)
      end
    end
  end
end

class Railgun
  MAX_RANGE = 5e4
  MIN_RANGE = 1e3
  STEP      = 1e2

  def initialize(gun_speed, target_speed)
    @gun_speed, @target_speed = gun_speed, target_speed
  end

  def test_fire(target_distance)
    r      = rand_vector * target_distance
    v      = rand_vector * @target_speed
    target = Target.new r, v
    projectile = Projectile.new target, @gun_speed
    projectile.fire
  end

  def range
    min = (MIN_RANGE / STEP).round
    max = (MAX_RANGE / STEP).round
    (min..max).to_a.reverse!.map! { |i| i * STEP }.bsearch do |r|
      check_range(r)
    end
  end

  def check_range(r)
    puts "\n射程：#{r} 米，测试中..."
    result = []
    fire_count = 8 # 试射次数
    hit_cont   = 7 # 通过标准
    fire_count.times do
      Thread.new { result << test_fire(r) }
    end
    sleep 0.1 while result.length < fire_count
    hit = result.reject { |i| i == :miss }.length
    puts "#{fire_count} 发，#{hit} 中"
    puts result.map { |i| i  == :miss ? 'o' : 'x' }.join
    result.reject { |i| i == :miss }.length >= hit_cont
  end
end
