
max.chord = (function() {
  var bundle, diagramRotation, div, drawChord, filterPackageName, getShortName, inObject, line, model, mouseDownEdge, mouseDownNode, mouseout, mouseover, packageNameMap, splines, svg, updateBreadCrumbs, updateNodes;
  model = null;
  diagramRotation = 0;
  splines = [];
  bundle = null;
  line = null;
  div = null;
  svg = null;
  /*Draw chord draws the diagram in the div. It uses D3.js to add and manipulate elements on the DOM
  
  often we want a certain part of the diagram to stay stationary, for example if a node is selected that node
  should stay in the same location, this is what the argument stationaryNode is for.
  */

  drawChord = function(stationaryNode) {
    var arrowWidth, changeInAngle, edges, labels, node, nodes, path, _i, _j, _len, _len1;
    nodes = model.getNodes();
    edges = model.getEdges();
    if (stationaryNode != null) {
      changeInAngle = 0;
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        node = nodes[_i];
        if (node.name === stationaryNode.name) {
          changeInAngle = stationaryNode.x - node.x;
          if (changeInAngle < 0) {
            changeInAngle += 360;
          }
          break;
        }
      }
      if (changeInAngle !== 0) {
        for (_j = 0, _len1 = nodes.length; _j < _len1; _j++) {
          node = nodes[_j];
          node.x = (node.x + changeInAngle) % 360;
        }
      }
    }
    splines = bundle(edges);
    /*we removed everything then redraw it, this could be improved for efficency
    */

    svg.selectAll("path.edge").remove();
    svg.selectAll("g.node").remove();
    /*add all the path elecments (edges)
    
    the .selectAll("path.edge") works similar to a jQuery selector.
    .data(edges) loops over each item in edges
    .enter() appends the item if it doesn't exist yet, this is kinda where because we 'selected' with .selectALL
    */

    path = svg.selectAll("path.edge").data(edges).enter().append("svg:path").attr("class", function(d) {
      return "edge                                     source-" + (d.source.name.split('@@').pop().split('$').join('\\$')) + "                                     target-" + (d.target.name.split('@@').pop().split('$').join('\\$')) + "                                     " + (d.selected ? 'selected' : '') + "                                    ";
    }).attr("d", function(d, i) {
      return line(splines[i]);
    }).on("mousedown", mouseDownEdge);
    /*add all the nodes, or names
    works similar to adding all the edges,
    
    this doesn't add the text, just adds the svg g container and rotates is around the circle to 
    the right place, this is what transform rotate and translate does
            
    also attaches the mouse events
    */

    labels = svg.selectAll("g.node").data(nodes.filter(function(n) {
      return !n.expanded;
    })).enter().append("svg:g").attr("class", function(d) {
      return "node " + d.type + (d.selected ? " selected" : "");
    }).attr("id", function(d) {
      d.id = "node-" + d.name.split('@@').pop().replace('$', '$');
      return d.id;
    }).attr("transform", function(d) {
      return "rotate(" + ((d.x - 90) % 360) + ")translate(" + d.y + ")";
    }).on("mouseover", mouseover).on("mouseout", mouseout);
    arrowWidth = 30;
    /*put the text labels in each node
    */

    labels.append("svg:text").attr("dx", function(d) {
      if (d.x < 180) {
        if (d.collapsible) {
          return 6 + arrowWidth;
        } else {
          return 6;
        }
      } else {
        if (d.collapsible) {
          return -6 - arrowWidth;
        } else {
          return -6;
        }
      }
    }).attr("dy", ".31em").attr("text-anchor", function(d) {
      if (d.x < 180) {
        return "start";
      } else {
        return "end";
      }
    }).attr("transform", function(d) {
      if (d.x < 180) {
        return null;
      } else {
        return "rotate(180)";
      }
    }).text(function(d) {
      if (d.type === 'package') {
        return filterPackageName(d.name.split('@@').pop());
      } else {
        return d.name.split('@@').pop();
      }
    }).on("mousedown", mouseDownNode);
    /*attach the expand and collapse images, the .filter allows us to only do it if its needed
    */

    labels.filter(function(d) {
      return d.collapsible;
    }).append("svg:image").attr("x", "-1").attr("y", "-10").attr("width", arrowWidth).attr("height", "20").attr("xlink:href", "images/collapse.png").on("mousedown", function(node) {
      console.time('collapseNode Execution');
      model.collapseNode(node);
      stationaryNode = {
        name: node.parent.name,
        x: node.x
      };
      drawChord(stationaryNode);
      console.timeEnd('collapseNode Execution');
    });
    labels.filter(function(d) {
      return d.expandable;
    }).append("svg:image").attr("x", function(d) {
      var x;
      x = $("#" + (d.id.split('.').join('\\.')) + " text").width() + 10;
      if (d.collapsible) {
        x = x + arrowWidth;
      }
      return x;
    }).attr("y", "-10").attr("width", "20").attr("height", "20").attr("xlink:href", "images/expand.png").on("mousedown", function(node) {
      console.time('expandNode Execution');
      model.expandNode(node);
      stationaryNode = {
        name: node.name,
        x: node.x
      };
      drawChord(stationaryNode);
      console.timeEnd('expandNode Execution');
    });
    updateBreadCrumbs();
  };
  mouseover = function(d) {
    var nameArray, names, nodeName;
    nameArray = d.name.split('@@');
    names = "<b id='breadcrumbseperator'></b>" + max.dataset;
    if (nameArray[0] != null) {
      names += " <b id='breadcrumbseperator'>&gt;</b> " + nameArray[0];
    }
    if (nameArray[1] != null) {
      names += " <b id='breadcrumbseperator'>&gt;</b> " + nameArray[1];
    }
    if (nameArray[2] != null) {
      names += " <b id='breadcrumbseperator'>&gt;</b> " + nameArray[2];
    }
    $("#hoverBreadCrumbs").html(names);
    nodeName = nameArray.pop();
    nodeName = nodeName.split('$').join('\\\\\\$');
    nodeName = nodeName.split('.').join('\\.');
    svg.selectAll("path.edge.target-" + nodeName).classed("target", true).each(updateNodes("source", true));
    svg.selectAll("path.edge.source-" + nodeName).classed("source", true).each(updateNodes("target", true));
  };
  mouseout = function(d) {
    var nodeName;
    $("#hoverBreadCrumbs").html('');
    nodeName = d.name.split('@@').pop();
    nodeName = nodeName.split('$').join('\\\\\\$');
    nodeName = nodeName.split('.').join('\\.');
    svg.selectAll("path.edge.source-" + nodeName).classed("source", false).each(updateNodes("target", false));
    svg.selectAll("path.edge.target-" + nodeName).classed("target", false).each(updateNodes("source", false));
  };
  updateNodes = function(name, value) {
    return function(d) {
      if (value) {
        this.parentNode.appendChild(this);
      }
      return svg.select("#node-" + (d[name].name.split('@@').pop().split('$').join('\\\\\\$')).split('.').join('\\.')).classed(name, value);
    };
  };
  mouseDownNode = function(node) {
    var e, stationaryNode;
    console.time('mouseDownNode Execution');
    e = d3.event;
    if (e.which === 1) {
      if (e.ctrlKey) {
        model.toggleNodeSelection(node);
      } else {
        model.toggleNodeSelection(node, true);
      }
      stationaryNode = {
        name: node.name,
        x: node.x
      };
      drawChord(stationaryNode);
    }
    updateBreadCrumbs();
    console.timeEnd('mouseDownNode Execution');
    return false;
  };
  mouseDownEdge = function(edge) {
    var e;
    e = d3.event;
    if (e.which === 1) {
      if (e.ctrlKey) {
        model.toggleEdgeSelection(edge);
      } else {
        model.toggleEdgeSelection(edge, true);
      }
      return drawChord();
    }
  };
  updateBreadCrumbs = function() {
    var breakAppended, clas, classes, datasetWidth, edge, jar, jarWidth, node, node1, node2, packag, packageWidth, packages, selectedEdges, selectedNodes, selectionTree, split, splitName;
    selectedNodes = max.selection.getSelectedNodes();
    selectedEdges = max.selection.getSelectedEdges();
    for (edge in selectedEdges) {
      split = edge.split(" ");
      node1 = split[0];
      node2 = split[2];
      selectedNodes[node1] = true;
      selectedNodes[node2] = true;
    }
    selectionTree = {};
    for (node in selectedNodes) {
      splitName = node.split("@@");
      if (!(selectionTree[splitName[0]] != null)) {
        selectionTree[splitName[0]] = {};
      }
      if (splitName.length > 1) {
        if (!(selectionTree[splitName[0]][splitName[1]] != null)) {
          selectionTree[splitName[0]][splitName[1]] = {};
        }
      }
      if (splitName.length > 2) {
        if (!(selectionTree[splitName[0]][splitName[1]][splitName[2]] != null)) {
          selectionTree[splitName[0]][splitName[1]][splitName[2]] = {};
        }
      }
    }
    $("#breadCrumbs").html('');
    $("#breadCrumbs").append("<span class='bcSpan' id='bc" + max.dataset + "' onclick='max.chord.selectSingleNode()'  >" + max.dataset + "</span>");
    datasetWidth = $("#bc" + max.dataset.split('.').join('\\.')).width();
    for (jar in selectionTree) {
      packages = selectionTree[jar];
      breakAppended = false;
      $("#breadCrumbs").append("<span class='bcSpan' id='bc" + jar + "' onclick='max.chord.selectSingleNode(\"" + jar + "\")' style='left:" + datasetWidth + "px'>&nbsp;&gt;&nbsp;" + jar + "</span>");
      jarWidth = $("#bc" + (jar.split('.').join('\\.'))).width();
      for (packag in packages) {
        classes = packages[packag];
        $("#breadCrumbs").append("<span class='bcSpan' id='bc" + packag + "' onclick='max.chord.selectSingleNode(\"" + jar + "@@" + packag + "\")' style='left:" + (datasetWidth + jarWidth) + "px' >&nbsp;&gt;&nbsp;" + packag + "</span>");
        packageWidth = $("#bc" + packag.split('.').join('\\.')).width();
        breakAppended = false;
        for (clas in classes) {
          $("#breadCrumbs").append("<span class='bcSpan' id='bc" + clas + "' onclick='max.chord.selectSingleNode(\"" + jar + "@@" + packag + "@@" + clas + "\")' style='left:" + (datasetWidth + jarWidth + packageWidth) + "px;Font-Weight:Bold' >&nbsp;&gt;&nbsp;" + clas + "</span>");
          $("#breadCrumbs").append("<br>");
          breakAppended = true;
        }
        if (!breakAppended) {
          $("#breadCrumbs").append("<br>");
          $("#bc" + packag.split('.').join('\\.')).css({
            'font-weight': 'bold'
          });
          breakAppended = true;
        }
      }
      if (!breakAppended) {
        $("#breadCrumbs").append("<br>");
        $("#bc" + (jar.replace('.', '\\.'))).css({
          'font-weight': 'bold'
        });
      }
    }
    return $("#breadCrumbs").css("z-index", "50");
  };
  packageNameMap = {};
  getShortName = function(name) {
    var i, item, lastItem, nameArray, newName, _i, _j, _len, _ref;
    if (packageNameMap[name] != null) {
      return packageNameMap[name];
    } else {
      nameArray = name.split('.');
      lastItem = nameArray[nameArray.length - 1];
      for (i = _i = 0, _ref = lastItem.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        newName = '$';
        for (_j = 0, _len = nameArray.length; _j < _len; _j++) {
          item = nameArray[_j];
          if (item !== lastItem) {
            newName += item.charAt(0);
          } else {
            newName += item.substring(0, i + 1);
          }
        }
        if (!inObject(newName, packageNameMap)) {
          packageNameMap[name] = newName;
          return newName;
        }
      }
      return false;
    }
  };
  inObject = function(valueToCheck, object) {
    var key, value;
    for (key in object) {
      value = object[key];
      if (valueToCheck === value) {
        return true;
      }
    }
    return false;
  };
  filterPackageName = function(packageName) {
    var filterOrder, firstBit, lastBit, n, postitionOfNthPeriod;
    filterOrder = 2;
    console.log(packageName);
    while (filterOrder !== 0) {
      postitionOfNthPeriod = packageName.indexOf(".");
      n = filterOrder;
      while (n-- > 0 && postitionOfNthPeriod !== -1) {
        postitionOfNthPeriod = packageName.indexOf(".", postitionOfNthPeriod + 1);
      }
      firstBit = packageName.substring(0, postitionOfNthPeriod);
      lastBit = packageName.substring(postitionOfNthPeriod + 1, packageName.length);
      firstBit = getShortName(firstBit);
      if (firstBit) {
        return "" + firstBit + "." + lastBit;
      } else {
        filterOrder--;
      }
    }
    return packageName;
  };
  return {
    setModel: function(m) {
      model = m;
      bundle = d3.layout.bundle();
      line = d3.svg.line.radial().interpolate("bundle").tension(.85).radius(function(d) {
        return d.y;
      }).angle(function(d) {
        return d.x / 180 * Math.PI;
      });
      div = d3.select("#chordDiv");
      return svg = div.append("svg:svg").attr("width", max.diagramWidth).attr("height", max.diagramHeight).append("svg:g").attr("transform", "translate(" + (max.diagramWidth / 2) + "," + (max.diagramHeight / 2) + ")");
    },
    drawChord: function() {
      return drawChord();
    },
    selectSingleNode: function(nodeName) {
      if (nodeName != null) {
        model.selectSingleNode(nodeName);
      } else {
        model.resetSelections();
      }
      drawChord();
      return updateBreadCrumbs();
    }
  };
})();
