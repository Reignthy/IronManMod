function init()
  data.ranOut = false
  data.lastBoost = nil
end

function jetpackConditions(args)
  if args.moves['jump'] and not tech.jumping() and not tech.canJump() and (data.lastBoost=='jetpack' or data.lastBoost==nil) then
    return true
  else
    return false
  end
end

function boostConditions(args)
  if not tech.onGround() and args.moves['down'] and (args.moves['left'] or args.moves['right']) then
    return true
  else
    return false
  end
end

function hoverConditions(args)
  if not tech.onGround() and args.moves['down'] and args.moves['jump'] then
    return true
  else
    return false
  end
end

function input(args)
  local currentBoost = nil
  if jetpackConditions(args) then
    currentBoost = 'jetpack'
  end
  if boostConditions(args) then
    if args.moves['left'] and (data.lastBoost==nil or  data.lastBoost=='boostLeft') then
      currentBoost = 'boostLeft'
    elseif args.moves['right'] and (data.lastBoost==nil or  data.lastBoost=='boostRight') then
      currentBoost = 'boostRight'
    end
  end
  if hoverConditions(args) then
    currentBoost = 'hover'
  end
  data.lastBoost = currentBoost
  return currentBoost
end

function update(args)
  local boostControlForce = tech.parameter("boostControlForce")
  local boostSpeed = tech.parameter("boostSpeed")
  local jetpackSpeed = tech.parameter("jetpackSpeed")
  local jetpackControlForce = tech.parameter("jetpackControlForce")
  local energyUsagePerSecond = tech.parameter("energyUsagePerSecond")
  local energyUsage = energyUsagePerSecond * args.dt

  local diff = world.distance(args.aimPosition, tech.position())
  local aimAngle = math.atan2(diff[2], diff[1])
  local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2

  if args.availableEnergy < energyUsage then
    data.ranOut = true
  elseif tech.onGround() or tech.inLiquid() then
    data.ranOut = false
  end

  local boosting = false

  tech.setParentOffset({0, 0})

  if flip then
    tech.setParentFacingDirection(-1)
    tech.setFlipped(true)
  else 
    tech.setParentFacingDirection(1)
    tech.setFlipped(false)
  end

  if not data.ranOut then
    if args.actions["boostRight"] then
      boosting = true
      tech.control({boostSpeed, 0}, boostControlForce, true, true)
      tech.setParentFacingDirection(1)
      tech.setFlipped(false)
      tech.setAnimationState("boosting", "on")
      tech.setAnimationState("hover", "off")
      tech.setAnimationState("jetpack", "off")
    elseif args.actions["boostLeft"] then
      boosting = true
      tech.control({-boostSpeed, 0}, boostControlForce, true, true)
      tech.setParentFacingDirection(-1)
      tech.setFlipped(true)
      tech.setAnimationState("boosting", "on")
      tech.setAnimationState("hover", "off")
      tech.setAnimationState("jetpack", "off")
    elseif args.actions["jetpack"] then
      boosting = true
      tech.yControl(jetpackSpeed, jetpackControlForce, true)
      tech.setAnimationState("jetpack", "on")
      tech.setAnimationState("hover", "off")
      -- energyUsage = energyUsage+energyUsage*0.2
    elseif args.actions["hover"] then
      boosting = true
      jetpackSpeed = 0
      jetpackControlForce = 100
      tech.yControl(jetpackSpeed, jetpackControlForce, true)
      tech.setAnimationState("hover", "on")
      tech.setAnimationState("jetpack", "off")
      -- energyUsage = energyUsage/2
    end
  end

  if boosting then
    return energyUsage
  else
    tech.setAnimationState("boosting", "off")
    tech.setAnimationState("hover", "off")
    tech.setAnimationState("jetpack", "off")
    return 0
  end
end

