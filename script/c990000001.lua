local s, id = GetID()
local SETS = {
    Argostars = 0x1ba
}

function s.initial_effect(c)
    -- Materiais: 2 LIGHT Warrior
    c:EnableReviveLimit()
    Fusion.AddProcMixN(c, true, true, aux.FilterBoolFunctionEx(Card.IsAttribute, ATTRIBUTE_LIGHT), 2)

    -- Invocação por Contato (Special Summon sem Poly)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.contactcon)
    e1:SetTarget(s.contacttg)
    e1:SetOperation(s.contactop)
    c:RegisterEffect(e1)
    
    -- Limite de Invocação Especial
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e2:SetCode(EFFECT_SPSUMMON_CONDITION)
    e2:SetValue(s.splimit)
    c:RegisterEffect(e2)

    -- Efeito 1: Busca ao ser Invocado
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCountLimit(1, id)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)

    -- Efeito 2: Standby Phase (Troca por Trap Monster)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOEXTRA)
    e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_PHASE + PHASE_STANDBY)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1, {id, 1})
    e4:SetTarget(s.stbytg)
    e4:SetOperation(s.stbyop)
    c:RegisterEffect(e4)
end

-- Filtros de Invocação
function s.contactfilter(c, tp)
    return c:IsAbleToRemoveAsCost() and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
        and (
            (c:IsSetCard(SETS.Argostars) and c:IsType(TYPE_MONSTER)) or
            (c:IsContinuousTrap() and c:IsTrapMonster())
        )
end

function s.contactcon(e, c)
    if c == nil then return true end
    local tp = c:GetControler()
    return Duel.IsExistingMatchingCard(s.contactfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, 2, nil, tp)
end

function s.contacttg(e, tp, eg, ep, ev, re, r, rp, chk, c)
    local g = Duel.GetMatchingGroup(s.contactfilter, tp, LOCATION_HAND + LOCATION_MZONE, 0, nil, tp)
    local sg = aux.SelectUnselectGroup(g, e, tp, 2, 2, aux.dncheck, 1, tp, HINTMSG_REMOVE)
    if sg then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    end
    return false
end

function s.contactop(e, tp, eg, ep, ev, re, r, rp, c)
    local g = e:GetLabelObject()
    Duel.Remove(g, POS_FACEUP, REASON_COST)
    g:DeleteGroup()
end

function s.splimit(e, se, sp, st)
    return (st & SUMMON_TYPE_FUSION) == SUMMON_TYPE_FUSION or (se:GetHandler() == e:GetHandler())
end

-- Lógica de Busca
function s.thfilter(c)
    return c:IsSetCard(SETS.Argostars) and c:IsMonster() and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, g)
    end
end

-- Lógica Standby Phase
function s.trapfilter(c)
    return c:IsType(TYPE_CONTINUOUS) and c:IsType(TYPE_TRAP)
end

function s.stbytg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsAbleToExtra() 
        and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.trapfilter, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, nil) end
    Duel.SetOperationInfo(0, CATEGORY_TOEXTRA, e:GetHandler(), 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE + LOCATION_REMOVED)
end

function s.stbyop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SendtoDeck(c, nil, SEQ_DECKTOP, REASON_EFFECT) > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local sc = Duel.SelectMatchingCard(tp, aux.NecroValleyFilter(s.trapfilter), tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, 1, 1, nil):GetFirst()
        if sc then
            -- Configura a Trap como Monstro
            sc:AddMonsterAttribute(TYPE_EFFECT + TYPE_TRAP + TYPE_MONSTER)
            if Duel.SpecialSummon(sc, SUMMON_TYPE_SPECIAL, tp, tp, true, false, POS_FACEUP) > 0 then
                -- Concede o efeito de Book of Moon Duplo

                local e1 = Effect.CreateEffect(c)
                e1:SetDescription(aux.Stringid(id, 2))
                e1:SetCategory(CATEGORY_POSITION)
                e1:SetType(EFFECT_TYPE_QUICK_O)
                e1:SetCode(EVENT_FREE_CHAIN)
                e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
                e1:SetRange(LOCATION_MZONE)
                e1:SetCountLimit(1)
                e1:SetTarget(s.postg)
                e1:SetOperation(s.posop)
                e1:SetReset(RESET_EVENT + RESETS_STANDARD)
                sc:RegisterEffect(e1, true)

                local e2=Effect.CreateEffect(e:GetHandler())
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_LEAVE)
                e2:SetCode(EFFECT_SET_BASE_DEFENSE)
                e2:SetValue(0)
                sc:RegisterEffect(e2,true)

                local e3=Effect.CreateEffect(e:GetHandler())
                e3:SetType(EFFECT_TYPE_SINGLE)
                e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e3:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_LEAVE)
                e3:SetCode(EFFECT_SET_BASE_ATTACK)
                e3:SetValue(0)
                sc:RegisterEffect(e3,true)

                local e4=Effect.CreateEffect(e:GetHandler())
                e4:SetType(EFFECT_TYPE_SINGLE)
                e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e4:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_LEAVE)
                e4:SetCode(EFFECT_CHANGE_ATTRIBUTE)
                e4:SetValue(ATTRIBUTE_LIGHT)
                sc:RegisterEffect(e4,true)

                local e5=Effect.CreateEffect(e:GetHandler())
                e5:SetType(EFFECT_TYPE_SINGLE)
                e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e5:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_LEAVE)
                e5:SetCode(EFFECT_CHANGE_RACE)
                e5:SetValue(RACE_WARRIOR)
                sc:RegisterEffect(e5,true)

                local e6=Effect.CreateEffect(e:GetHandler())
                e6:SetType(EFFECT_TYPE_SINGLE)
                e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e6:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_LEAVE)
                e6:SetCode(EFFECT_CHANGE_LEVEL)
                e6:SetValue(4)
                sc:RegisterEffect(e6,true)
            end
        end
    end
end

-- Efeito Concedido: Dual Book of Moon
function s.postg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return false end
    if chk == 0 then return Duel.IsExistingTarget(Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, 2, nil)
        and Duel.IsExistingTarget(Card.IsControler, tp, LOCATION_MZONE, 0, 1, nil, tp) end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
    local g1 = Duel.SelectTarget(tp, Card.IsControler, tp, LOCATION_MZONE, 0, 1, 1, nil, tp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_FACEUP)
    local g2 = Duel.SelectTarget(tp, Card.IsFaceup, tp, LOCATION_MZONE, LOCATION_MZONE, 1, 1, g1:GetFirst())
    g1:Merge(g2)
    Duel.SetOperationInfo(0, CATEGORY_POSITION, g1, 2, 0, 0)
end

function s.posop(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetTargetCards(e)
    if #g > 0 then
        Duel.ChangePosition(g, POS_FACEDOWN_DEFENSE)
    end
end