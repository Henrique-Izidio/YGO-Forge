-- Argostars – Brave Amphi
local s, id = GetID()
local SETS = {
    Argostars = 0x1ba
}

s.listed_names = {id}
s.listed_series = {SETS.Argostars}

function s.initial_effect(c)
    -- effects
    -- Place Argostars Continuous Traps
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetRange(LOCATION_HAND)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1, {id, 1})
    e1:SetCost(Cost.SelfBanish)
    e1:SetTarget(s.pltg)
    e1:SetOperation(s.plop)
    c:RegisterEffect(e1)

    -- extra summon
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetOperation(s.sumop)
    c:RegisterEffect(e2)

    -- recicle from GY/Ban
    local e3 = Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_TODECK + CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1, {id, 3})
    e3:SetCost(Cost.SelfBanish)
    e3:SetTarget(s.tdtg)
    e3:SetOperation(s.tdop)
    c:RegisterEffect(e3)
end

function s.isArgoTrap(c)
    return c:IsSetCard(SETS.Argostars) and c:IsType(TYPE_TRAP) and c:IsType(TYPE_CONTINUOUS) and not c:IsForbidden()
end

function s.pltg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_SZONE) >= 2 and
                   Duel.IsExistingMatchingCard(s.isArgoTrap, tp, LOCATION_HAND, 0, 1, nil) and
                   Duel.IsExistingMatchingCard(s.isArgoTrap, tp, LOCATION_DECK, 0, 1, nil)
    end
end

function s.plop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetLocationCount(tp, LOCATION_SZONE) < 2 then
        return
    end

    -- Seleciona da Mão
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
    local hg = Duel.SelectMatchingCard(tp, s.isArgoTrap, tp, LOCATION_HAND, 0, 1, 1, e:GetHandler())

    -- Seleciona do Deck
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
    local dg = Duel.SelectMatchingCard(tp, s.isArgoTrap, tp, LOCATION_DECK, 0, 1, 1, e:GetHandler())

    if #hg > 0 and #dg > 0 then
        local tc1 = hg:GetFirst()
        local tc2 = dg:GetFirst()

        -- Move ambos para a SZONE com a face para cima
        Duel.MoveToField(tc1, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
        Duel.MoveToField(tc2, tp, tp, LOCATION_SZONE, POS_FACEUP, true)
    end
end

function s.sumop(e, tp, eg, ep, ev, re, r, rp)
    if Duel.GetFlagEffect(tp, id) ~= 0 then
        return
    end
    local e2 = Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetTargetRange(LOCATION_HAND | LOCATION_MZONE, 0)
    e2:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
    e2:SetDescription(aux.Stringid(id, 0))
    e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard, SETS.Argostars))
    e2:SetReset(RESET_PHASE | PHASE_END)
    Duel.RegisterEffect(e2, tp)
    Duel.RegisterFlagEffect(tp, id, RESET_PHASE | PHASE_END, 0, 1)
end

function s.tdfilter(c)
    return c:IsFaceup()
		and c:IsAbleToDeck() 
		and (
			c:IsSetCard(SETS.Argostars)
			or (
				c:IsType(TYPE_CONTINUOUS)
				and c:IsType(TYPE_TRAP)
			)
		) and not c:IsCode(id)
end

function s.tdtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsPlayerCanDraw(tp) and
                   Duel.IsExistingMatchingCard(s.tdfilter, tp, LOCATION_GRAVE | LOCATION_REMOVED, 0, 3, nil)
    end
    Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_GRAVE | LOCATION_REMOVED)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.tdop(e, tp, eg, ep, ev, re, r, rp)
    if not Duel.IsExistingMatchingCard(
		aux.NecroValleyFilter(s.tdfilter),
		tp, LOCATION_GRAVE | LOCATION_REMOVED, 0, 3, nil
	) then return end

    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)

    local g = Duel.SelectMatchingCard(
		tp, aux.NecroValleyFilter(s.tdfilter),
		tp, LOCATION_GRAVE | LOCATION_REMOVED, 0, 3, 3, nil
	)
    if #g == 0 then return end

    Duel.HintSelection(g)

    if Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then
        if g:IsExists(Card.IsLocation, 1, nil, LOCATION_DECK) then
            Duel.ShuffleDeck(tp)
        end
        if Duel.IsPlayerCanDraw(tp) then
            Duel.BreakEffect()
            Duel.Draw(tp, 1, REASON_EFFECT)
        end
    end
end
