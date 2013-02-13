max.state.onStateChanged "s.v", (property, oldValue, newValue) ->
    console.log "state changed callback: change value of " + property + ": " + oldValue + " -> " + newValue
    newValue = newValue or ""
    max.selection.resetSelection true
    if newValue.length > 0
        nodes = newValue.split(",")
        for node in nodes
            #n = ax.commons.perspective.nodes.get(selection[i])
            max.selection.selectNode node, true
    return

max.state.onStateChanged "s.e", (property, oldValue, newValue) ->
    console.log "state changed callback: change value of " + property + ": " + oldValue + " -> " + newValue
    newValue = newValue or ""
    max.selection.resetSelection true
    if newValue.length > 0
        edges = newValue.split(",")
        for edge in edges
            #e = ax.commons.perspective.edges.get(selection[i])
            max.selection.selectEdge edge, true
    return
            
            
max.state.onStateChanged "e.v", (property, oldValue, newValue) ->
    console.log "state changed callback: change value of " + property + ": " + oldValue + " -> " + newValue
    newValue = newValue or ""
    max.selection.resetExpansion true
    if newValue.length > 0
        nodes = newValue.split(",")
        for node in nodes
            max.selection.expandNode node    
    return
            
           

max.selection = do ->
    
    #PRIVATE PROPERTIES########################################################################################
    
    selectedNodes = {}
    selectedEdges = {}
    expandedNodes = {"root":true}
    
    #PRIVATE METHODS###########################################################################################
    
    selectNode = (nodeName, resetFirst) ->
        if resetFirst
            resetSelection(true)
        
        selectedNodes[nodeName] = true
        stateChanged() #might be bad and need to be removed later
        
    deSelectNode = (nodeName, resetFirst) ->
        if resetFirst
            resetSelection(true)
        else
            delete selectedNodes[nodeName]
        
        stateChanged() #might be bad and need to be removed later

    selectEdge = (edgeName, resetFirst) ->
        if resetFirst
            resetSelection(true)
        
        selectedEdges[edgeName] = true
        stateChanged() #might be bad and need to be removed later
    
    deSelectEdge = (edgeName, resetFirst) ->
        if resetFirst
            resetSelection(true)
        else
            delete selectedEdges[edgeName]
        
        stateChanged() #might be bad and need to be removed later
    
    expandNode = (node) ->
        if expandedNodes[node] and node isnt "root" #leave root expanded always
            delete expandedNodes[node]
        else
            expandedNodes[node] = true
            
        stateChanged() #might be bad and need to be removed later

    resetSelection = (preventNotification) ->
        selectedNodes = {}
        selectedEdges = {}
        if not preventNotification
            stateChanged()
    
    resetExpansion = (preventNotification) ->
        expandedNodes = {"root":true}
        if not preventNotification
            stateChanged()
    
    stateChanged = () ->
        selection = []
        for name, b of selectedNodes
            selection.push name
        max.state.setState "s.v", selection.join(",")
        
        selection = []
        for key, val of selectedEdges
            selection.push key
        max.state.setState "s.e", selection.join(",")
        
        selection = []
        for key, val of expandedNodes
            selection.push key
        max.state.setState "e.v", selection.join(",")
        
    
    #PUBLIC METHODS############################################################################################
    
    init: () ->
        selectionDone = false
        selectedNodeList = ax.commons.getRequestParameter("selectedNodes")
        if selectedNodeList isnt `undefined` and selectedNodeList? and selectedNodeList.length > 0
            nodes = selectedNodeList.split(",")
            for node of nodes
                max.selection.selectNode node, true
            selectionDone = true
        selectedEdgeList = ax.commons.getRequestParameter("selectedEdges")
        if selectedEdgeList isnt `undefined` and selectedEdgeList? and selectedEdgeList.length > 0
            arr = selectedEdgeList.split(",")
            for i of arr
                ax.select.selectEdge ax.commons.perspective.edges.get(arr[i]), true
            selectionDone = true
        if selectionDone
            true
        else
            false

    isEmpty: () ->
        $.isEmptyObject(selectedNodes) and $.isEmptyObject(selectedEdges)

    #public wrapper
    selectNode: (nodeName, resetFirst) ->
        selectNode(nodeName, resetFirst)
    
    #public wrapper    
    deSelectNode: (nodeName, resetFirst) ->
        deSelectNode(nodeName, resetFirst)
        
    deSelectEdge: (edgeName, resetFirst) ->
        deSelectEdge(edgeName, resetFirst)
        
    
    #public wrapper
    selectEdge: (edge, multiSelectionMode) ->
        selectEdge(edge, multiSelectionMode)
    
    #public wrapper    
    expandNode: (node) ->
        expandNode(node)
    
    #public wrapper
    stateChanged: () ->
        stateChanged()

    isSelectedNode: (node, returnTrueIfNoSelectedNodes) ->
        if returnTrueIfNoSelectedNodes
            selectedNodes[node] or $.isEmptyObject(selectedNodes)
        else
            selectedNodes[node]
        
    getSelectedNodes: () ->
        selectedNodes
    getSelectedEdges: () ->
        selectedEdges
        
    isSelectedEdge: (edge, returnTrueIfNoSelectedEdges) ->
        if returnTrueIfNoSelectedEdges
            selectedEdges[edge] or $.isEmptyObject(selectedEdges)
        else
            selectedEdges[edge]
        
    isExpandedNode: (node) ->
        expandedNodes[node]
        
    #public wrapper
    reset: (preventNotification) ->
        resetSelection(preventNotification)
        resetExpansion(preventNotification)
    
    #public wrapper
    resetSelection: (preventNotification) ->
        resetSelection(preventNotification)
    
    #public wrapper
    resetExpansion: (preventNotification) ->
        resetExpansion(preventNotification)
    
    viewExpandedNodesForTesting: () ->
        expandedNodes
        
    
    
    

#    set: () ->
#        selectIdx = document.getElementById("selectDD").selectedIndex
#        if selectIdx >= 0
#            f = ax.commons.perspective.filters[selectIdx]
#            ax.filter.configureFilter f, ->
#                ax.select.reset()
#                if f.nodeFilter isnt `undefined`
#                    goog.iter.forEach ax.commons.perspective.nodes, (ndata) ->
#                        ax.select.selectNode ndata, true    if f.nodeFilter(ndata)
#                if f.edgeFilter isnt `undefined`
#                    goog.iter.forEach ax.commons.perspective.edges, (edata) ->
#                        ax.select.selectEdge edata, true    if f.edgeFilter(edata)
#                ax.filter.apply()
#
#    displayDetailsOfSelectedNode: (node, point) ->
#        if node?
#            position = [ point.x, point.y ]
#            details = ax.commons.perspective.getNodeDetails(node)
#            content = "<table>"
#            i = 0
#            while i < details.length
#                content = content + "<tr><td align='right'><i>" + details[i][0] + ":</i></td><td>" + details[i][1] + "</td></tr>"
#                i++
#            content = content + "</table>"
#            document.getElementById("detailsDlg").innerHTML = content
#            $("#detailsDlg").dialog
#                resizable: "false"
#                width: ax.select.computeDialogSize(details)
#                closeText: "hide"
#                position: position
#                buttons: @createDetailsViewButtons()
#
#    createDetailsViewButtons: () ->
#        buttons = []
#        if ax.perspectives.util.perspectiveSwitchingEnabled and ax.commons.perspective.drillDowns.length > 0
#            buttons.push
#                text: "drill down"
#                click: ->
#                    ax.perspectives.util.drillDown()
#                    $(this).dialog "close"
#        if ax.perspectives.util.perspectiveSwitchingEnabled and ax.commons.perspective.rollUps.length > 0
#            buttons.push
#                text: "rollUp"
#                click: ->
#                    ax.perspectives.util.rollUp()
#                    $(this).dialog "close"
#        buttons.push
#            text: "close"
#            click: ->
#                $(this).dialog "close"
#
#        buttons
#
#    displayDetailsOfSelectedEdges: (edges, point) ->
#        if edges? and edges.length > 0
#            position = [ point.x, point.y ]
#            content = ""
#            for i of edges
#                content = content + "<hr/>"    if i > 0
#                content = content + "<table>"
#                details = ax.commons.perspective.getEdgeDetails(edges[i])
#                content = content + "<table>"
#                j = 0
#                while j < details.length
#                    content = content + "<tr><td align='right'><i>" + details[j][0] + ":</i></td><td>" + details[j][1] + "</td></tr>"
#                    j++
#                content = content + "</table>"
#            document.getElementById("detailsDlg").innerHTML = content
#            $("#detailsDlg").dialog
#                resizable: "false"
#                width: ax.select.computeDialogSize(details)
#                closeText: "hide"
#                position: position
#                buttons: @createDetailsViewButtons()
#
#    computeDialogSize: (keysAndValues) ->
#        longest = ""
#        for i of keysAndValues
#            assoc = keysAndValues[i]
#            t = assoc[0] + assoc[1]
#            longest = t    if longest.length < t.length
#        w = Math.max(250, (longest.length + 10) * 8)
#        w = Math.min(600, w)
#        w