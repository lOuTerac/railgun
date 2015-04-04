require File.expand_path('railgun.rb')

describe Railgun do
  let(:target) { Target.new }
  let(:gun_speed) { rand * 1e6 }
  let(:projectile) { Projectile.new target, gun_speed }

  describe 'projectile' do
    describe 'initialize' do
      it 'is a flying object' do
        expect(projectile).to be_a(Particle)
      end

      it '炮口位置为原点' do
        expect(projectile.r.magnitude).to eq 0.0
      end

      it '匀速运动' do
        expect(projectile.acceleration.magnitude).to eq 0.0
      end

    end

    context '静止目标' do
      describe 'x 轴上静止目标' do
        let(:target) { Target.new Vector[2e3, 0.0, 0.0], zero, 0}
        it '瞄准正确方向' do
          expect(projectile.v.normalize).to eq(Vector[1.0, 0.0, 0.0])
        end

        it '炮口初速为正确值' do
          expect((projectile.v.r - gun_speed).round 12).to eq 0.0
        end

        it 'fire' do
          expect(projectile.fire).to eq :hit
        end
      end
    end

    context '运动目标' do
      describe 'x轴上 y方向运动' do
        let(:v) { Vector[0.0, Math.sqrt(0.5) * gun_speed, 0.0] }
        let(:target) { Target.new Vector[1e3, 0.0, 0.0], v, 0.0}

        it '瞄准正确方向' do
          sqrt  = Math.sqrt(0.5)
          a     = Vector[sqrt, -sqrt, 0.0]
          round = projectile.v.normalize.dot(a).round 12
          expect(round).to eq(0.0)
        end

        it '炮口初速为正确值' do
          expect((projectile.v.r - gun_speed).round 12).to eq 0.0
        end

        it 'fire' do
          expect(projectile.fire).to eq :hit
        end
      end

      describe 'nextstep' do
        let(:target) { Target.new Vector[1e5, 0.0, 0.0]}
        it 'run without error' do
          projectile.nextstep!(1.0)
        end
      end
    end
  end

  describe 'target' do
    let(:target) { Target.new Vector[1e5, 0.0, 0.0], rand_vector }
    describe 'initialize' do
      it 'fire' do
        target.t = 2.0
        error = target.acceleration.r - Target::MAX_ACCELERATION
        expect(error.round 12).to eq 0.0
      end
    end

    describe 'nextstep' do
      let(:target) { Target.new Vector[1e5, 0.0, 0.0]}
      it 'run without error' do
        target.nextstep!(0.01)
      end
    end
  end

  describe '轨道炮试射' do
    let(:target_speed) { 1 * SONIC }
    let(:gun_speed) { 10 * SONIC }
    let(:gun) { Railgun.new gun_speed, target_speed }
    it 'test_fire' do
      gun.range
    end
  end
end
