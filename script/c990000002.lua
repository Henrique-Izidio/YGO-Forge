-- Argostars - Beastslaying
local s, id = GetID()
local SETS = {
    Argostars = 0x1ba
}

function s.initial_effect(c)
  -- activate
  local e1 = Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
  e1:SetCountLimit(1, id)
  e1:SetCost(s.applyCost)
  e1:SetOperation(s.applyOp)
  c:RegisterEffect(e1)

  -- Return Continuous Traps from GY/Banishment to field
  local e2 = Effect.CreateEffect(c)
  e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_FIELD)
  e2:SetCode(EVENT_LEAVE_FIELD)
  e2:SetProperty(EFFECT_FLAG_DELAY)
  e2:SetRange(LOCATION_GRAVE)
  e2:SetCountLimit(1, id)
  e2:SetCondition(s.gyCon)
  e2:SetCost(Cost.SelfBanish)
  e2:SetTarget(s.gyTg)
  e2:SetOperation(s.gyOp)
  c:RegisterEffect(e2)
end

function s.applyCostFilter(c)
  return c:IsType(TYPE_MONSTER) and
    c:IsSetCard(SETS.Argostars) and
    c:IsAbleToRemoveAsCost()
end

function s.applyCost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	if Duel.CheckReleaseGroupCost(tp, s.applyCostFilter, 1, true, nil, nil) and
    Duel.SelectYesNo(tp, aux.Stringid(id, 0))
  then
		local g = Duel.SelectReleaseGroupCost(tp, s.applyCostFilter, 1, 1, true, nil, nil)
		Duel.Remove(g, POS_FACEUP, REASON_COST)
		e:SetLabel(1)
	else
		e:SetLabel(0)
	end
end

function s.applySetFilter(c)
  return c:IsContinuousTrap() and c:IsTrapMonster() and c:IsSSetable()
end

function s.applyPlaceFilter(c)
  return c:IsSetCard(SETS.Argostars) and
    c:IsContinuousTrap() and
    c:IsTrapMonster() and not
    c:IsForbidden()
end

function s.applyOp(e,tp,eg,ep,ev,re,r,rp)
	local set = Duel.IsExistingMatchingCard(s.applySetFilter,tp,LOCATION_DECK,0,1,nil)
	local place = Duel.IsExistingMatchingCard(s.applyPlaceFilter,tp,LOCATION_DECK,0,1,nil)
  local both = set and place and e:GetLabel() == 1

	local op = Duel.SelectEffect(tp,
		{set,   aux.Stringid(id,1)},
		{place, aux.Stringid(id,2)},
		{both,  aux.Stringid(id,3)}
  )
	local breakeffect = false

	if op == 1 or op==3 then
		-- Set 1 Continuous Trap that can Special Summon itself
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.applySetFilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
      Duel.SSet(tp,g)
    end
    local c=e:GetHandler()
	end

	if op==2 or op==3 then
		-- Seleciona do Deck
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
    local dg = Duel.SelectMatchingCard(tp, s.applyPlaceFilter, tp, LOCATION_DECK, 0, 1, 1, e:GetHandler())

    if #dg > 0 then
        local tc = dg:GetFirst()

        -- Move ambos para a SZONE com a face para cima
        Duel.MoveToField(tc, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
    end
	end
end

function s.gyConFilter(c)
  return c:IsPreviousLocation(LOCATION_ONFIELD) and
    c:IsType(TYPE_TRAP) and
    c:IsType(TYPE_CONTINUOUS)
end

function s.gyCon(e,tp,eg,ep,ev,re,r,rp)
  return re ~= tp and eg:IsExists(s.gyConFilter,1,nil)
end

function s.gyTg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk == 0 then 
    return Duel.GetLocationCount(tp, LOCATION_SZONE) and 
      Duel.IsExistingMatchingCard(s.applyPlaceFilter, tp, LOCATION_GRAVE|LOCATION_REMOVED, 0, 1, nil)
  end
  Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,0)
end

function s.gyOp(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	if ft <= 0 then return end
	ft=math.min(ft,2)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.applyPlaceFilter,tp,LOCATION_GRAVE,0,1,ft,nil)
	if #g>0 then
		for sc in g:Iter() do
			Duel.MoveToField(sc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		end
	end
end