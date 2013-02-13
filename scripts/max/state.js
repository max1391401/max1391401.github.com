
max.state = (function() {
  var state, stateChangedListeners;
  state = {};
  stateChangedListeners = {};
  return {
    applyState: function() {
      var changes, currentValue, diffedKeys, i, key, keys, newState, notifyStateChangeListeners, selectionChanged, value;
      notifyStateChangeListeners = function(key, currentValue, value) {
        var listener;
        console.log("resetting state of " + key + " from " + currentValue + " to " + value);
        listener = stateChangedListeners[key];
        if (listener) {
          return listener.call(undefined, key, currentValue, value);
        } else {
          return console.log("warning, no state change event listener found for " + key);
        }
      };
      newState = $.bbq.getState();
      diffedKeys = [];
      changes = [];
      selectionChanged = (newState["s.e"] !== state["s.e"]) || (newState["s.v"] !== state["s.v"]);
      if (selectionChanged) {
        max.selection.resetSelection(true);
      }
      keys = ["p"];
      for (i in keys) {
        key = keys[i];
        value = newState[key];
        currentValue = state[key];
        if (value !== currentValue) {
          diffedKeys.push(key);
          state[key] = value;
          changes.push({
            key: key,
            oldValue: currentValue,
            newValue: value
          });
        }
      }
      for (key in state) {
        value = newState[key];
        currentValue = state[key];
        if (value !== currentValue) {
          diffedKeys.push(key);
          state[key] = value;
          changes.push({
            key: key,
            oldValue: currentValue,
            newValue: value
          });
        }
      }
      for (key in state) {
        value = newState[key];
        currentValue = state[key];
        if (value !== currentValue && diffedKeys.indexOf(key) === -1) {
          diffedKeys.push(key);
          state[key] = value;
          changes.push({
            key: key,
            oldValue: currentValue,
            newValue: value
          });
        }
      }
      if (diffedKeys.length > 0) {
        for (i in changes) {
          notifyStateChangeListeners(changes[i].key, changes[i].oldValue, changes[i].newValue);
        }
        max.model.recalculate();
        max.chord.drawChord();
      }
    },
    initState: function() {
      var s;
      state = {
        "e.v": "",
        "s.e": "",
        "s.v": ""
      };
      s = $.bbq.getState();
      if (s["e.v"]) {
        console.log("Setting application state from URL");
        max.state.applyState();
        return true;
      } else {
        console.log("No application state found in URL - starting with default state");
        return false;
      }
    },
    setState: function(k, v) {
      if (state[k] !== v) {
        state[k] = v;
        return console.log("setting state " + k + " to " + v);
      }
    },
    saveState: function() {
      $.bbq.pushState(state);
      return console.log("saving state");
    },
    onStateChanged: function(attr, callback) {
      return stateChangedListeners[attr] = callback;
    },
    getStateForTesting: function() {
      return state;
    }
  };
})();
