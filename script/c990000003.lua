-- Purrely Friends
local s, id = GetID()
local SETS = {
    Purrely = 0x18d
}

function s.initial_effect(c)
    -- Xyz summon 1 rank 2 "Purrely" using this card
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O) -- Trigger de quando esta carta entra
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1, {id, 1})
    e1:SetTarget(s.sumTg)
    e1:SetOperation(s.sumOp)
    c:RegisterEffect(e1)

    -- Shuffle up to 3 "Purrely" cards from GY into the Deck
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1, {id, 2}) -- ID diferente do primeiro efeito
    e2:SetCondition(s.tdCon)
    e2:SetTarget(s.tdTg)
    e2:SetOperation(s.tdOp)
    c:RegisterEffect(e2)
end

-- Filtro para o Monstro Xyz no Extra Deck
function s.spfilter(c, e, tp, mc)
    return c:IsSetCard(SETS.Purrely) and c:IsType(TYPE_XYZ) and c:IsRank(2) and
           mc:IsCanBeXyzMaterial(c, tp) and
           Duel.GetLocationCountFromEx(tp, tp, mc, c) > 0 and
           c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_XYZ, tp, false, false)
end

-- Filtro para a Magia de Jogo Rápido (Material Adicional)
function s.matfilter(c)
    return c:IsSetCard(SETS.Purrely) and c:IsType(TYPE_QUICKPLAY)
end

function s.sumTg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, c)
        -- Nota: A verificação da magia na mão/GY pode ser opcional ou obrigatória. 
        -- Aqui assumimos que você quer invocar mesmo que não tenha a magia no momento (opcional).
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.sumOp(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Checagens de validade do material em campo
    if c:IsFacedown() or not c:IsRelateToEffect(e) or c:IsControler(1 - tp) or c:IsImmuneToEffect(e) then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp, c)
    local sc = g:GetFirst()
    
    if sc then
        sc:SetMaterial(Group.FromCards(c))
        Duel.Overlay(sc, c) -- Coloca esta carta como material antes do Summon
        if Duel.SpecialSummon(sc, SUMMON_TYPE_XYZ, tp, tp, false, false, POS_FACEUP) > 0 then
            sc:CompleteProcedure()
            
            -- Tenta anexar a Magia de Jogo Rápido da mão ou cemitério
            Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_XMATERIAL)
            local mat = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.matfilter), tp, LOCATION_HAND+LOCATION_GRAVE, 1, 1, 1, nil)
            if #mat > 0 then
                Duel.BreakEffect()
                Duel.Overlay(sc, mat)
            end
        end
    end
end

-- Condição: Enviado para o GY, exceto do campo
function s.tdCon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousLocation(LOCATION_HAND + LOCATION_DECK) or (not c:IsPreviousLocation(LOCATION_MZONE + LOCATION_SZONE))
end

-- Filtro: Cartas "Purrely", exceto "Purrely Friends"
function s.tdFilter(c)
    return c:IsSetCard(SETS.Purrely) and not c:IsCode(id) and c:IsAbleToDeck()
end

function s.tdTg(e, tp, eg, ep, ev, re, r, rp, chk, chknum)
    if chk == 0 then 
        return Duel.IsExistingTarget(s.tdFilter, tp, LOCATION_GRAVE, 0, 1, nil) 
    end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
    local g = Duel.SelectTarget(tp, s.tdFilter, tp, LOCATION_GRAVE, 0, 1, 3, nil)
    
    Duel.SetOperationInfo(0, CATEGORY_TODECK, g, #g, 0, 0)
end

function s.tdOp(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetTargetCards(e)
    if #g > 0 then
        Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
    end
end