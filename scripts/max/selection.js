
max.state.onStateChanged("s.v", function(property, oldValue, newValue) {
  var node, nodes, _i, _len;
  console.log("state changed callback: change value of " + property + ": " + oldValue + " -> " + newValue);
  newValue = newValue || "";
  max.selection.resetSelection(true);
  if (newValue.length > 0) {
    nodes = newValue.split(",");
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      max.selection.selectNode(node, true);
    }
  }
});

max.state.onStateChanged("s.e", function(property, oldValue, newValue) {
  var edge, edges, _i, _len;
  console.log("state changed callback: change value of " + property + ": " + oldValue + " -> " + newValue);
  newValue = newValue || "";
  max.selection.resetSelection(true);
  if (newValue.length > 0) {
    edges = newValue.split(",");
    for (_i = 0, _len = edges.length; _i < _len; _i++) {
      edge = edges[_i];
      max.selection.selectEdge(edge, true);
    }
  }
});

max.state.onStateChanged("e.v", function(property, oldValue, newValue) {
  var node, nodes, _i, _len;
  console.log("state changed callback: change value of " + property + ": " + oldValue + " -> " + newValue);
  newValue = newValue || "";
  max.selection.resetExpansion(true);
  if (newValue.length > 0) {
    nodes = newValue.split(",");
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      max.selection.expandNode(node);
    }
  }
});

max.selection = (function() {
  var deSelectEdge, deSelectNode, expandNode, expandedNodes, resetExpansion, resetSelection, selectEdge, selectNode, selectedEdges, selectedNodes, stateChanged;
  selectedNodes = {};
  selectedEdges = {};
  expandedNodes = {
    "root": true
  };
  selectNode = function(nodeName, resetFirst) {
    if (resetFirst) {
      resetSelection(true);
    }
    selectedNodes[nodeName] = true;
    return stateChanged();
  };
  deSelectNode = function(nodeName, resetFirst) {
    if (resetFirst) {
      resetSelection(true);
    } else {
      delete selectedNodes[nodeName];
    }
    return stateChanged();
  };
  selectEdge = function(edgeName, resetFirst) {
    if (resetFirst) {
      resetSelection(true);
    }
    selectedEdges[edgeName] = true;
    return stateChanged();
  };
  deSelectEdge = function(edgeName, resetFirst) {
    if (resetFirst) {
      resetSelection(true);
    } else {
      delete selectedEdges[edgeName];
    }
    return stateChanged();
  };
  expandNode = function(node) {
    if (expandedNodes[node] && node !== "root") {
      delete expandedNodes[node];
    } else {
      expandedNodes[node] = true;
    }
    return stateChanged();
  };
  resetSelection = function(preventNotification) {
    selectedNodes = {};
    selectedEdges = {};
    if (!preventNotification) {
      return stateChanged();
    }
  };
  resetExpansion = function(preventNotification) {
    expandedNodes = {
      "root": true
    };
    if (!preventNotification) {
      return stateChanged();
    }
  };
  stateChanged = function() {
    var b, key, name, selection, val;
    selection = [];
    for (name in selectedNodes) {
      b = selectedNodes[name];
      selection.push(name);
    }
    max.state.setState("s.v", selection.join(","));
    selection = [];
    for (key in selectedEdges) {
      val = selectedEdges[key];
      selection.push(key);
    }
    max.state.setState("s.e", selection.join(","));
    selection = [];
    for (key in expandedNodes) {
      val = expandedNodes[key];
      selection.push(key);
    }
    return max.state.setState("e.v", selection.join(","));
  };
  return {
    init: function() {
      var arr, i, node, nodes, selectedEdgeList, selectedNodeList, selectionDone;
      selectionDone = false;
      selectedNodeList = ax.commons.getRequestParameter("selectedNodes");
      if (selectedNodeList !== undefined && (selectedNodeList != null) && selectedNodeList.length > 0) {
        nodes = selectedNodeList.split(",");
        for (node in nodes) {
          max.selection.selectNode(node, true);
        }
        selectionDone = true;
      }
      selectedEdgeList = ax.commons.getRequestParameter("selectedEdges");
      if (selectedEdgeList !== undefined && (selectedEdgeList != null) && selectedEdgeList.length > 0) {
        arr = selectedEdgeList.split(",");
        for (i in arr) {
          ax.select.selectEdge(ax.commons.perspective.edges.get(arr[i]), true);
        }
        selectionDone = true;
      }
      if (selectionDone) {
        return true;
      } else {
        return false;
      }
    },
    isEmpty: function() {
      return $.isEmptyObject(selectedNodes) && $.isEmptyObject(selectedEdges);
    },
    selectNode: function(nodeName, resetFirst) {
      return selectNode(nodeName, resetFirst);
    },
    deSelectNode: function(nodeName, resetFirst) {
      return deSelectNode(nodeName, resetFirst);
    },
    deSelectEdge: function(edgeName, resetFirst) {
      return deSelectEdge(edgeName, resetFirst);
    },
    selectEdge: function(edge, multiSelectionMode) {
      return selectEdge(edge, multiSelectionMode);
    },
    expandNode: function(node) {
      return expandNode(node);
    },
    stateChanged: function() {
      return stateChanged();
    },
    isSelectedNode: function(node, returnTrueIfNoSelectedNodes) {
      if (returnTrueIfNoSelectedNodes) {
        return selectedNodes[node] || $.isEmptyObject(selectedNodes);
      } else {
        return selectedNodes[node];
      }
    },
    getSelectedNodes: function() {
      return selectedNodes;
    },
    getSelectedEdges: function() {
      return selectedEdges;
    },
    isSelectedEdge: function(edge, returnTrueIfNoSelectedEdges) {
      if (returnTrueIfNoSelectedEdges) {
        return selectedEdges[edge] || $.isEmptyObject(selectedEdges);
      } else {
        return selectedEdges[edge];
      }
    },
    isExpandedNode: function(node) {
      return expandedNodes[node];
    },
    reset: function(preventNotification) {
      resetSelection(preventNotification);
      return resetExpansion(preventNotification);
    },
    resetSelection: function(preventNotification) {
      return resetSelection(preventNotification);
    },
    resetExpansion: function(preventNotification) {
      return resetExpansion(preventNotification);
    },
    viewExpandedNodesForTesting: function() {
      return expandedNodes;
    }
  };
})();
