
max.model = (function() {
  var calculateNodesToBeIncluded, cluster, createLink, edges, generateEdges, generateNodeTree, generateNodes, nodeJars, nodeTree, nodes, nodesToBeIncluded, rawJSON, recalculate, selectedEdgeEnds;
  nodes = null;
  edges = null;
  rawJSON = {};
  nodeTree = {};
  nodeJars = {};
  selectedEdgeEnds = {};
  nodesToBeIncluded = {};
  cluster = d3.layout.cluster().size([360, (max.diagramHeight / 2) - max.diagramTextSpace].sort(function(a, b) {
    return d3.ascending(a.name, b.name);
  }));
  /*this method populates three things, 
  Primarly the nodeTree,
  secondly the nodeJars, which maps key=[node.package+node.name] to node.jar
  third counts the number of jars
  */

  generateNodeTree = function() {
    var className, edge, edgeNameToNodeObject, jarName, node, packageName, srcClass, srcJar, srcPackage, tarClass, tarJar, tarPackage, _i, _j, _len, _len1, _ref, _ref1;
    edgeNameToNodeObject = {};
    console.time("generateNodeTree rawJson.nodes");
    nodeTree.root = {
      name: "root",
      children: []
    };
    _ref = rawJSON.nodes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      jarName = node.container;
      packageName = jarName + "@@" + node.namespace;
      className = packageName + "@@" + node.name;
      if (!(nodeTree[jarName] != null)) {
        nodeTree[jarName] = {
          name: jarName,
          type: "jar",
          children: [],
          edgesOut: {},
          edgesIn: {}
        };
        nodeTree.root.children.push(nodeTree[jarName]);
      }
      if (!(nodeTree[packageName] != null)) {
        nodeTree[packageName] = {
          name: packageName,
          type: "package",
          parent: nodeTree[jarName],
          children: [],
          edgesOut: {},
          edgesIn: {}
        };
        nodeTree[jarName].children.push(nodeTree[packageName]);
      }
      nodeTree[className] = {
        name: className,
        type: node.type,
        parent: nodeTree[packageName],
        edgesOut: {},
        edgesIn: {}
      };
      nodeTree[packageName].children.push(nodeTree[className]);
      edgeNameToNodeObject[node.namespace + "." + node.name] = nodeTree[className];
    }
    console.timeEnd("generateNodeTree rawJson.nodes");
    console.time("generateNodeTree rawJson.edges");
    _ref1 = rawJSON.edges;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      edge = _ref1[_j];
      srcClass = edgeNameToNodeObject[edge.src];
      srcPackage = srcClass.parent;
      srcJar = srcPackage.parent;
      tarClass = edgeNameToNodeObject[edge.tar];
      tarPackage = tarClass.parent;
      tarJar = tarPackage.parent;
      if (srcJar !== tarJar) {
        createLink(srcJar, tarJar, "j2j", edge);
        createLink(srcJar, tarPackage, "j2p", edge);
        createLink(srcJar, tarClass, "j2c", edge);
        createLink(srcPackage, tarJar, "p2j", edge);
        createLink(srcClass, tarJar, "c2j", edge);
      }
      if (srcPackage !== tarPackage) {
        createLink(srcPackage, tarPackage, "p2p", edge);
        createLink(srcPackage, tarClass, "p2c", edge);
        createLink(srcClass, tarPackage, "c2p", edge);
      }
      createLink(srcClass, tarClass, "c2c", edge);
    }
    console.timeEnd("generateNodeTree rawJson.edges");
    /*for many systems there is only one jar
    if there is only one jar, we dont want to display it on its own
    we want to display the packages within, which is the same as selecting it
    */

    if (nodeTree.root.children.length === 1) {
      max.selection.expandNode(nodeTree.root.children[0].name);
    }
  };
  createLink = function(src, tar, type, edge) {
    var edgeType, srcName, tarName;
    tarName = tar.name;
    srcName = src.name;
    edgeType = edge.type;
    if (!src.edgesOut[tarName]) {
      src.edgesOut[tarName] = tar.edgesIn[srcName] = {
        source: src,
        target: tar,
        uses: edgeType === "uses" ? 1 : 0,
        "extends": edgeType === "extends" ? 1 : 0,
        "implements": edgeType === "implements" ? 1 : 0,
        type: type
      };
    } else {
      src.edgesOut[tarName][edgeType]++;
      tar.edgesIn[srcName][edgeType]++;
    }
  };
  calculateNodesToBeIncluded = function() {
    var edgeName, includeNode, node, nodeName, srcNode, srcTarArray, tarNode;
    console.time('nodesToBeIncluded timer');
    nodesToBeIncluded = {};
    includeNode = function(node) {
      var srcName, tarName, _results;
      nodesToBeIncluded[node.name] = true;
      if (node.type !== "jar") {
        nodesToBeIncluded[node.parent.name] = true;
        if (node.type !== "package") {
          nodesToBeIncluded[node.parent.parent.name] = true;
        }
      }
      for (tarName in node.edgesOut) {
        nodesToBeIncluded[tarName] = true;
      }
      _results = [];
      for (srcName in node.edgesIn) {
        _results.push(nodesToBeIncluded[srcName] = true);
      }
      return _results;
    };
    for (nodeName in max.selection.getSelectedNodes()) {
      node = nodeTree[nodeName];
      includeNode(node);
    }
    selectedEdgeEnds = {};
    for (edgeName in max.selection.getSelectedEdges()) {
      srcTarArray = edgeName.split(" ");
      srcNode = nodeTree[srcTarArray[0]];
      tarNode = nodeTree[srcTarArray[2]];
      selectedEdgeEnds[srcNode.name] = true;
      selectedEdgeEnds[tarNode.name] = true;
      includeNode(srcNode);
      includeNode(tarNode);
    }
    console.timeEnd('nodesToBeIncluded timer');
  };
  /*returns a hierarchial layout with all the nodes and their children
  each node has a name, and if it has children an array of children
  see https://github.com/mbostock/d3/wiki/Cluster-Layout
  */

  generateNodes = function() {
    var Class, Package, classCopy, jar, jarChildren, jarCopy, packageChildren, packageCopy, rootNode, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
    console.time('generateNodes timer');
    rootNode = {
      name: "root",
      children: [],
      expanded: true
    };
    _ref = nodeTree.root.children;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      jar = _ref[_i];
      if ($.isEmptyObject(nodesToBeIncluded) || nodesToBeIncluded[jar.name]) {
        jarChildren = [];
        jarCopy = {
          name: jar.name,
          type: "jar",
          edgesOut: jar.edgesOut,
          edgesIn: jar.edgesIn,
          expandable: true
        };
        if (max.selection.isExpandedNode(jar.name)) {
          _ref1 = jar.children;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            Package = _ref1[_j];
            if ($.isEmptyObject(nodesToBeIncluded) || nodesToBeIncluded[Package.name]) {
              packageChildren = [];
              packageCopy = {
                name: Package.name,
                type: "package",
                parent: jarCopy,
                edgesOut: Package.edgesOut,
                edgesIn: Package.edgesIn,
                expandable: true
              };
              if (max.selection.isExpandedNode(Package.name)) {
                _ref2 = Package.children;
                for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
                  Class = _ref2[_k];
                  if ($.isEmptyObject(nodesToBeIncluded) || nodesToBeIncluded[Class.name]) {
                    classCopy = {
                      name: Class.name,
                      type: Class.type,
                      parent: packageCopy,
                      edgesOut: Class.edgesOut,
                      edgesIn: Class.edgesIn,
                      collapsible: true,
                      selected: max.selection.isSelectedNode(Class.name) ? true : void 0
                    };
                    packageChildren.push(classCopy);
                  }
                }
              }
              if (nodeTree.root.children.length !== 1) {
                packageCopy.collapsible = true;
              }
              if (max.selection.isExpandedNode(Package.name)) {
                packageCopy.expanded = true;
              }
              if (max.selection.isSelectedNode(Package.name)) {
                packageCopy.selected = true;
              }
              if (packageChildren.length !== 0) {
                packageCopy.children = packageChildren;
              }
              jarChildren.push(packageCopy);
            }
          }
        }
        if (max.selection.isSelectedNode(jar.name)) {
          jarCopy.selected = true;
        }
        if (max.selection.isExpandedNode(jar.name)) {
          jarCopy.expanded = true;
        }
        if (jarChildren.length !== 0) {
          jarCopy.children = jarChildren;
        }
        rootNode.children.push(jarCopy);
      }
    }
    nodes = cluster.nodes(rootNode);
    console.timeEnd('generateNodes timer');
    return nodes;
  };
  /*this returns an array of edges
  each edge has a source and a target
  it is important that both source and target have a parent object
  this method returns data that can go into bundle(edges)
  see https://github.com/mbostock/d3/wiki/Bundle-Layout
  */

  generateEdges = function() {
    var countOfNodesForPerformanceTestingPurposes, e, edge, node, nodeMap, tarNodeName, _i, _j, _len, _len1, _ref;
    console.time('generateEdges timer');
    nodeMap = {};
    /*Create a map of nodes so that they can be looked up when populating all the edges in the array
    */

    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      nodeMap[node.name] = node;
    }
    countOfNodesForPerformanceTestingPurposes = 0;
    edges = [];
    for (_j = 0, _len1 = nodes.length; _j < _len1; _j++) {
      node = nodes[_j];
      if (node.name === "root" || node.expanded) {
        continue;
      }
      countOfNodesForPerformanceTestingPurposes++;
      _ref = node.edgesOut;
      for (tarNodeName in _ref) {
        edge = _ref[tarNodeName];
        if ((nodeMap[tarNodeName] != null) && !nodeMap[tarNodeName].expanded && (max.selection.isSelectedNode(node.name, true) || max.selection.isSelectedNode(tarNodeName, true)) && (selectedEdgeEnds[node.name] || selectedEdgeEnds[tarNodeName] || $.isEmptyObject(selectedEdgeEnds))) {
          e = {
            source: node,
            target: nodeMap[tarNodeName],
            strength: 1,
            type: edge.type,
            uses: edge.uses,
            "extends": edge["extends"],
            "implements": edge["implements"]
          };
          if (max.selection.isSelectedEdge("" + edge.source.name + " " + edge.type + " " + edge.target.name)) {
            e.selected = true;
          }
          edges.push(e);
        }
      }
    }
    console.log('total number of nodes:' + countOfNodesForPerformanceTestingPurposes);
    console.timeEnd('generateEdges timer');
  };
  recalculate = function() {
    calculateNodesToBeIncluded();
    generateNodes();
    generateEdges();
  };
  return {
    setJSON: function(json) {
      rawJSON = json;
      generateNodeTree();
      return recalculate();
    },
    recalculate: function() {
      return recalculate();
    },
    getEdges: function() {
      return edges;
    },
    getNodes: function() {
      return nodes;
    },
    expandNode: function(node) {
      var child, _i, _len, _ref;
      max.selection.expandNode(node.name);
      if (max.selection.isSelectedNode(node.name)) {
        max.selection.deSelectNode(node.name);
        node = nodeTree[node.name];
        _ref = node.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          max.selection.selectNode(child.name);
        }
      }
      recalculate();
      return max.state.saveState();
    },
    collapseNode: function(node) {
      var childIsSelected, childNode, _i, _len, _ref;
      max.selection.expandNode(node.parent.name);
      node = nodeTree[node.name];
      if (node.parent.name !== "root") {
        childIsSelected = false;
        _ref = node.parent.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          childNode = _ref[_i];
          if (max.selection.isSelectedNode(childNode.name)) {
            childIsSelected = true;
            max.selection.deSelectNode(childNode.name);
          }
        }
        if (childIsSelected) {
          max.selection.selectNode(node.parent.name);
        }
      }
      recalculate();
      return max.state.saveState();
    },
    /*This funciton takes a list of nodes that are selected
    It allows horizontal navigation throughout the view
    It will change the current nodes and edges values
    */

    toggleNodeSelection: function(node, resetFirst) {
      var nodeName;
      nodeName = node.name;
      if (max.selection.isSelectedNode(nodeName)) {
        max.selection.deSelectNode(nodeName, resetFirst);
      } else {
        max.selection.selectNode(nodeName, resetFirst);
      }
      recalculate();
      max.state.saveState();
    },
    toggleEdgeSelection: function(edge, resetFirst) {
      var edgeName;
      edgeName = edge.source.name + (" " + edge.type + " ") + edge.target.name;
      if (max.selection.isSelectedEdge(edgeName)) {
        max.selection.deSelectEdge(edgeName, resetFirst);
      } else {
        max.selection.selectEdge(edgeName, resetFirst);
      }
      recalculate();
      max.state.saveState();
    },
    resetSelections: function() {
      max.selection.resetSelection();
      max.selection.resetExpansion();
      recalculate();
      return max.state.saveState();
    },
    selectSingleNode: function(nodeName) {
      if (max.selection.isExpandedNode(nodeName)) {
        max.selection.expandNode(nodeName);
      }
      max.selection.selectNode(nodeName, true);
      recalculate();
      return max.state.saveState();
    }
  };
})();
