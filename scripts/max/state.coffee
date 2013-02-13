max.state = do ->
    
    #PRIVATE PROPERTIES########################################################################################
    state = {}
    stateChangedListeners = {}

    #PUBLIC METHODS############################################################################################
    applyState : () ->

        notifyStateChangeListeners = (key, currentValue, value) ->
            console.log "resetting state of " + key + " from " + currentValue + " to " + value
            listener = stateChangedListeners[key]
            if listener
                listener.call `undefined`, key, currentValue, value
            else
                console.log "warning, no state change event listener found for " + key

        newState = $.bbq.getState()

        #to diff we iterate in both directions, and we use a set to keep track of already registered diffs
        diffedKeys = []

        changes = []

        # reset selection - we cannot do this inside the handlers for selection as 
        # edges and nodes are handled separatly
        # ax.select.reset(true);
        selectionChanged = (newState["s.e"] isnt state["s.e"]) or (newState["s.v"] isnt state["s.v"])

        if selectionChanged 
            max.selection.resetSelection(true)

        # fixed part - check state in predefined order to account for dependencies
        keys = [ "p" ]
        for i of keys
            key = keys[i]
            value = newState[key]
            currentValue = state[key]
            unless value is currentValue
                diffedKeys.push key
                state[key] = value
                changes.push
                    key: key
                    oldValue: currentValue
                    newValue: value

        # generic part
        # diff old state and current state, notify listeners
        for key of state
            value = newState[key]
            currentValue = state[key]
            # bind is built-in property - ignore
            unless value is currentValue
                diffedKeys.push key
                state[key] = value
                changes.push
                    key: key
                    oldValue: currentValue
                    newValue: value

        for key of state
            value = newState[key]
            currentValue = state[key]
            # bind is built-in property - ignore
            if value isnt currentValue and diffedKeys.indexOf(key) is -1
                diffedKeys.push key
                state[key] = value
                changes.push
                    key: key
                    oldValue: currentValue
                    newValue: value

        if diffedKeys.length > 0
            # apply changes
            for i of changes
                notifyStateChangeListeners changes[i].key, changes[i].oldValue, changes[i].newValue

            # update ui
            #ax.filter.apply()
            max.model.recalculate()
            max.chord.drawChord()
            
        return #from applyState()

    initState : () ->
        
        state = 
            "e.v": ""
            "s.e": ""
            "s.v": ""
            
        
        s = $.bbq.getState()
        
        #LATER THIS SHOULD CHANGE TO SOMETHING PROPER!!!
        if s["e.v"]        
            console.log "Setting application state from URL"
            max.state.applyState()
            true
        else
            console.log "No application state found in URL - starting with default state"
            false

    setState : (k, v) ->
        unless state[k] is v
            state[k] = v
            console.log "setting state " + k + " to " + v

    saveState : () ->
        $.bbq.pushState state
        console.log "saving state"

    onStateChanged : (attr, callback) ->
        stateChangedListeners[attr] = callback
        
        
    getStateForTesting : () ->
        state